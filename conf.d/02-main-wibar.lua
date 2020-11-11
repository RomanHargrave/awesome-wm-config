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
      wm.button({}, 1, function(client)
            if wm.client.focus == client then
               client.minimized = true
            else
               client.minimized = false

               -- of limited use since I do not intend to include tag peek
               if not client:isvisible() and client.first_tag then
                  client.first_tag:view_only()
               end

               wm.client.focus = client
               client:raise()
            end
      end),

      wm.button({}, 3, function(client)
            if state.client_menu and state.client_menu.visible then
               state.client_menu:hide()
               state.client_menu = nil
            else
               state.client_menu = wm.menu.clients({ theme = { width = 250 } })
            end
      end)
   )

   local timeFormat   = '%Y-%m-%d %H:%M %Z'
   local clockRefresh = 60 -- seconds

   if not state.utcClock then
      state.utcClock = wibox.widget.textclock(timeFormat, clockRefresh, "UTC+00:00")
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

         screen.wibar = wm.wibar({ position = "top",
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
                  tasklist
               },
               screen.tasklist,
               {
                  layout = wibox.layout.fixed.horizontal,
                  state.localClock,
                  wibox.widget.separator { forced_width = 10 },
                  state.utcClock,
                  state.systray,
                  screen.layout_chooser
               }
         })
   end)
end
