-- Primary wibar config fragment
-- (C) 2020- Roman Hargrave
-- License: GPL-3

local wm    = require('awful')
local wibox = require('wibox')
local util  = require('gears')

return function(state, full)
   local taglist_buttons = util.table.join(
      wm.button({}, 1, function(tag) tag:view_only() end),
      wm.button({state.modkey}, 1, function(tag)
            if wm.client.focus then
               wm.client.focuse:move_to_tag(tag)
            end
      end) 
   )

   local tasklist_buttons = util.table.join(
      -- Toggle client focus/visibility
      wm.button({}, 1, function(client)
            client:activate { context = 'tasklist',
                              action  = 'toggle_minimization' }
      end),

      -- Show client menu
      wm.button({}, 3, function(client)
            wm.menu.client_list { theme = { width = 250 } }
      end)
   )

   local timeFormat   = '%Y-%m-%d %H:%M %Z'
   local clockRefresh = 60 -- seconds

   if not state.utcClock then
      state.utcClock = wibox.widget.textclock(timeFormat, clockRefresh, 'UTC+00:00')
   end

   if not state.localClock then
      state.localClock = wibox.widget.textclock(timeFormat, clockRefresh)
   end

   if not state.systray then
      state.systray = wibox.widget.systray()
   end

   wm.screen.connect_for_each_screen(function(screen)
         if screen.wibar then
            screen.wibar:remove()
         end

         -- no point in ever need to hot-recreate this
         if not screen.prompt then
            screen.prompt = wm.widget.prompt()
         end

         -- nor this
         if not screen.layout_chooser then
            screen.layout_chooser = wm.widget.layoutbox(screen)
            screen.layout_chooser:buttons(util.table.join(
                                        wm.button({}, 1, function() wm.layout.inc(1) end),
                                        wm.button({}, 3, function() wm.layout.inc(-1) end)))
         end

         local taglist  = wm.widget.taglist(screen, wm.widget.taglist.filter.all, taglist_buttons)
         local tasklist = wm.widget.tasklist(screen, wm.widget.tasklist.filter.currenttags, tasklist_buttons)

         screen.wibar = wm.wibar({ position = 'bottom',
                                   screen   = screen,
                                   ontop    = true })

         screen.wibar:setup({
               layout = wibox.layout.align.horizontal,
               -- Widget group: left
               {
                  layout = wibox.layout.fixed.horizontal,
                  -- these are defined in the screens fragment
                  taglist,
                  screen.prompt,
                  screen.layout_chooser,
                  tasklist,
               },
               screen.tasklist,
               {
                  layout = wibox.layout.fixed.horizontal,
                  state.localClock,
                  wibox.widget.separator { forced_width = 10 },
                  state.utcClock,
                  state.systray,
               }
         })
   end)
end
