-- Runtime commands
-- (C) 2020- Roman Hargrave

local wm = require('awful')
local util = require('gears')

local function screen_to_coords(screen)
   local wa = screen.workarea
   return wa.x .. 'x' .. wa.y
end

local function coords_to_table(coordstr)
   local c = util.string.split(coordstr, 'x')
   return tonumber(c[1]), tonumber(c[2] or '0') 
end

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

local base_commands = {
   {
      verb = 'st',
      description = 'switch tag',
      help = 'sw <tag> [screen = focused()]',
      completion_fn = function(query)
         local suggestions = {}
         local tok = util.string.split(query, ' ')
         local tag_tok = tok[2] or ''
         local scr_tok = tok[3] or ''

         -- We're completing tag names
         if #tok <= 2 then
            for _, gbl in ipairs(rh_data.global_tags) do
               if string.find(gbl, tag_tok) then
                  table.insert(suggestions, { text = gbl,
                                              description = 'on all screens' })
               end
            end

            for _, output in ipairs(rh_data.specific_tags) do
               for _, tag in ipairs(output.tags) do
                  if string.find(tag.name, tag_tok) then
                     table.insert(suggestions, { text = tag.name,
                                                 description = 'on screen +' .. output.x .. 'x' .. output.y })
                  end
               end
            end
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
      verb = 'mc',
      description = 'move focused client',
      help = 'mc <tag> [screen = current]'
   },
   {
      verb = 'reconfigure',
      description = 'reload configuration',
      help = 'reconfigure [full?]'
   },
   {
      verb = 'sl',
      description = 'set layout for focused tag',
      help = 'sl [layout]'
   },
   {
      verb = 'l',
      description = 'run lua',
      help = 'l [lua*]'
   }
}

return function(state, full)
   util.table.merge(state.commands, base_commands)
end
