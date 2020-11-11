-- Runtime commands
-- (C) 2020- Roman Hargrave

local wm = require('awful')
local util = require('gears')

local base_commands = {
   {
      verb = 'st',
      description = 'switch tag',
      help = 'sw <tag> [screen = current]',
      completion_fn = function(query)
         local tok = util.string.split(query, ' ')
         local tag_q = table.remove(tok, #tok)
         local suggestions = {}

         for _, gbl in ipairs(rh_data.global_tags) do
            if string.find(gbl, tag_q) then
               table.insert(suggestions, { text = gbl,
                                           description = 'global' })
            end
         end

         for _, output in ipairs(rh_data.specific_tags) do
            for _, tag in ipairs(output.tags) do
               if string.find(tag.name, tag_q) then
                  table.insert(suggestions, { text = tag.name,
                                              description = 'disp. +' .. output.x .. 'x' .. output.y })
               end
            end
         end

         local filtered = {}

         
         return suggestions
      end,
      exec_fn = function(argv)
         if #argv >= 2 then
            local tag_info = rh_data.tag_index[argv[2]]

            if tag_info then
               if tag_info.kind == 'global' then
                  local screen = wm.screen.focused()
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
