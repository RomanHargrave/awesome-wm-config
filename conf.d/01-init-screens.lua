-- Screen config fragment
-- Sets up basic per-screen items like tasklist
-- (C) 2020- Roman Hargrave
-- License: GPL-3

local wm = require('awful')
local util = require('gears')

return function(state, full)
   state.default_layouts = {
      wm.layout.suit.floating,
      wm.layout.suit.tile,
      wm.layout.suit.fair,
      wm.layout.suit.fair.horizontal,
      wm.layout.suit.fullscreen
   }

   state.global_tags = {'1', '2', '3', '4'}

   state.specific_tags = {
      -- Output 1
      {
         x = 0, y = 0,
         tags = {
            {
               name = 'web',
               view = { state.modkey, 'space' },
               move = { 'Shift', state.modkey, 'KP_1' }
            },
            {
               name = 'emacs',
               view = { state.modkey, 'KP_2' },
               move = { 'Shift', state.modkey, 'KP_2' }
            }
         }
      },

      -- Output 2
      {
         x = 2560, y = 0,
         tags = {
            {
               name = 'comm',
               view = { state.modkey, 'KP_3' },
               move = { 'Shift', state.modkey, 'KP_3' }
            },
            {
               name = 'music',
               view = { state.modkey, 'KP_4' },
               move = { 'Shift', state.modkey, 'KP_4' }
            }
         }
      }
   }

   state.tag_index = {}

   -- Set up keybindings for global tags (up to 9)
   for n, tag_name in ipairs(state.global_tags) do
      if n > 9 then
         break
      end
      
      table.insert(state.keys,
                   wm.key({ state.modkey }, n, function()
                         local screen = wm.screen.focused()
                         local tag    = wm.tag.find_by_name(screen, tag_name)

                         tag:view_only()
                   end)
      ) -- table.insert

      table.insert(state.keys,
                   wm.key({ 'Shift', state.modkey }, n, function()
                         local screen = wm.screen.focused()
                         local tag    = wm.tag.find_by_name(screen, tag_name)

                         if wm.client.focus then
                            wm.client.focus:move_to_tag(tag)
                         end
                   end)
      ) -- table.insert
   end

   -- Set up tags for display
   wm.screen.connect_for_each_screen(function(screen)
         -- only set the tag list for a display if full reload is set
         if full then
            -- TODO use lower-level tag management API to preserve layouts
            wm.tag(state.global_tags, screen, wm.layout.layouts[1])
         end
   end)

   -- if doing a full reload, also add specific tags (they will have been cleared)
   if state.specific_tags then
      for _i, group in ipairs(state.specific_tags) do
         local screen = wm.screen.getbycoord(group.x, group.y)

         for _i, tag in ipairs(group.tags) do
            if full then
               local tag_impl = wm.tag.add(tag.name, { layout = wm.layout.layouts[1],
                                                       screen = screen })

               tag.impl = tag_impl
            end


            -- add keybinding to key list
            local view_key = table.remove(tag.view, #tag.view)
            local move_key = table.remove(tag.move, #tag.move)

            table.insert(state.keys, wm.key(tag.view, view_key, function() tag.impl:view_only() end))
            
            table.insert(state.keys,
                         wm.key(tag.move, move_key,
                                function ()
                                   if wm.client.focus then
                                      wm.client.focuse.move_to_tag(tag.impl)
                                   end
                         end)
            ) -- table.insert

            state.tag_index[tag.name] = {
               kind = 'screen',
               data = tag
            }
         end
      end -- for _i, group in ipairs(...) do
   end -- if state.specific_tags then

   for _, gbl in ipairs(state.global_tags) do
      state.tag_index[gbl] = { kind = 'global', data = { name = gbl } }
   end
end
