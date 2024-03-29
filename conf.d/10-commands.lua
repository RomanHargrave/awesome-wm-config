-- Runtime commands
-- (C) 2020- Roman Hargrave

local wm = require('awful')
local util = require('gears')
local rh = require('lib/rh')

local function remove_verb(command)
   return command:gsub('^[^%s]+%s*', '')
end

-- Convert a screen table to NxN coords
local function screen_to_coords(screen)
   local wa = screen.workarea
   return wa.x .. 'x' .. wa.y
end

-- Convert NxN to {n, n} or N to {n, 0}
local function coords_to_table(coordstr)
   local c = util.string.split(coordstr, 'x')
   return tonumber(c[1]), tonumber(c[2] or '0') 
end

-- Suggest matching tag names
local function suggest_tags(filter)
   local suggestions = {}
   for _, gbl in ipairs(rh_data.global_tags) do
      if string.find(gbl, filter) then
         table.insert(suggestions, { text = gbl,
                                     description = 'on all screens' })
      end
   end

   for _, output in ipairs(rh_data.specific_tags) do
      for _, tag in ipairs(output.tags) do
         if string.find(tag.name, filter) then
            table.insert(suggestions, { text = tag.name,
                                        description = 'on screen +' .. output.x .. 'x' .. output.y })
         end
      end
   end
   return suggestions
end

-- Suggest screens that might contain the exact tag name
local function suggest_screens_for_tag(tag_name, filter)
   local tag_info = rh_data.tag_index[tag_name]
   if not tag_info then return {} end

   local suggestions = {}
   
   if tag_info.kind == 'global' then
      for screen in screen do
         table.insert(suggestions, { text = screen_to_coords(screen),
                                     description = 'screen #' .. screen.index })
      end
   else
      local screen = tag_info.data.impl.screen
      table.insert(suggestions, { text = screen_to_coords(screen),
                                  description = 'screen #' .. screen.index })
   end

   return suggestions
end

-- Suggest client matches given criteria
local function suggest_clients(criteria)
   -- collect all matching clients
   local suggestions = {}

   -- matching window IDs or titles?
   if criteria:sub(1,1) == '#' then
      local wid = criteria:sub(2, #criteria)
      for _, client in ipairs(_G.client.get()) do
         if string.match(tostring(client.window), '^' .. wid) then
            table.insert(suggestions, { text = '#' .. client.window,
                                        description = client.name })
         end
      end
   else
      for _, client in ipairs(_G.client.get()) do
      if string.match(client.name, criteria) then
            table.insert(suggestions, { text = client.name,
                                        description = 'client #' .. client.window })
         end
      end
   end

   return suggestions
end

-- Select a matching client for criteria
local function find_client(criteria)
   local client = nil

   if criteria:sub(1,1) == '#' then
      local wid = tonumber(criteria:sub(2, #criteria))

      for _, c in ipairs(_G.client.get()) do
         if c.window == wid then
            client = c
            break
         end
      end
   else
      -- do exact matches first
      for _, c in ipairs(_G.client.get()) do
         if c.name == criteria then
            client = c
            break
         end
      end

      -- if no client was an exact match, pick the first with a prefix match
      if not client then
         for _, c in ipairs(_G.client.get()) do
            if string.match(c.name, '^' .. criteria) then
               client = c
               break
            end
         end
      end
   end

   return client
end

local base_commands = {
   {
      verb = 'st',
      description = 'switch tag',
      help = 'sw <tag> [screen = focused()]',
      completion_fn = function(data)
         local query = data.query
         local suggestions = {}
         local tok = util.string.split(query, ' ')
         local tag_tok = tok[2] or ''
         local scr_tok = tok[3] or ''

         -- We're completing tag names
         if #tok <= 2 then
            suggestions = suggest_tags(tag_tok)
         elseif #tok <= 3 then -- now we're completing screen indices
            suggestions = suggest_screens_for_tag(tag_tok, scr_tok)
         end

         
         return suggestions
      end,
      exec_fn = function(argv)
         if #argv >= 2 then
            local tag_info = rh_data.tag_index[argv[2]]
            local screen = wm.screen.focused()

            if #argv >= 3 then
               local cx, cy = coords_to_table(argv[3])
               screen = _G.screen[wm.screen.getbycoord(cx, cy)] -- this is stupid
            end

            if tag_info then
               if tag_info.kind == 'global' and screen then
                  local scr_tag = wm.tag.find_by_name(screen, tag_info.data.name)
                  scr_tag:view_only()
               elseif tag_info.kind == 'screen' then
                  tag_info.data.impl:view_only()
               end
            end
         end
      end
   },
   {
      verb = 'sc',
      description = 'switch to client',
      help = 'sc <client name>',
      completion_fn = function(data)
         -- remove sc from begining
         local nw = data.syn.head:next_word()

         if nw then
            return suggest_clients(nw:join_raw())
         else
            return suggest_clients('')
         end
      end,
      exec_fn = function(argv)
         if #argv > 1 then
            -- remove sc from begining
            local client = find_client(argv[2])

            if client then
               client:jump_to(false)
            end
         end
      end
   },
   {
      verb = 'mc',
      description = 'move client',
      help = 'mc <tag> [screen = current]',
      completion_fn = function(data)
         local tokens = data.syn.head:collect_plain_words()
         local count = data.syn.head:count() -- this will include whitespace
         local tag = tokens[2] or ''
         local screen = tokens[3] or ''
         local client = tokens[4] or ''

         if count <= 3 then
            return suggest_tags(tag)
         elseif count <= 5 then
            return suggest_screens_for_tag(tag, screen)
         elseif count <= 6 then
            return suggest_clients(client)
         end

         return {}
      end,
      exec_fn = function(argv)
         local tag_name = argv[2]
         local screen_name = argv[3]
         local client_name = argv[4]
         local screen = wm.screen.focused()
         local client = _G.client.focus

         if tag_name then
            if client_name then
               client = find_client(client_name)
            end

            if screen_name then
               local cx, cy = coords_to_table(screen_name[3])
               screen = _G.screen[wm.screen.getbycoord(cx, cy)]
            end

            local tag = wm.tag.find_by_name(screen, tag_name)

            if tag then
               client:move_to_tag(tag)
            end
         end
      end
   },
   {
      verb = 'l',
      description = 'run lua',
      help = 'l [lua*]',
      exec_fn = function(argv)
         -- remove 'l' from argv
         local cmd = remove_verb(argv.raw)
         local fn = loadstring(cmd)
         local e, r = pcall(fn)

         if not e then
            util.debug.print_warning(
               'Error while evaluating lua «' .. cmd .. '»: ' .. r
            )
         end
      end
   },
   {
      verb = 'rc',
      description = 'reload config (fragment)',
      completion_fn = function(data)
         local nw = data.syn.head:next_word()
         local suggestions = {'*'}
         local filter = ''
         if nw then
            filter = nw:join_raw()
         end
         for _, frag in ipairs(_G.rh_data.frags) do
            if frag:match(filter) then
               table.insert(suggestions, frag)
            end
         end
         return suggestions
      end,
      exec_fn = function(argv)
      end
   },
}

return function(state, full)
   util.table.merge(state.commands, base_commands)
end
