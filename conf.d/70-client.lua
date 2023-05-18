-- Window decorations config fragment
-- (C) 2020- Roman Hargrave

local wm = require('awful')
local util = require('gears')
local wibox = require('wibox')
local theme = require('beautiful')

-- TODO - this
require('awful.permissions._common')._deprecated_autofocus_in_use()

return function(state, full)
   util.table.merge(state.client.keys, {
                       wm.key({ state.modkey }, 'f', function(client)
                             client.fullscreen = not client.fullscreen
                             client:raise()
                       end, { description = 'toggle fullscreen', group = 'client' })
   })

   util.table.merge(state.client.buttons, {
                       wm.button({}, 1, function(client)
                             client:emit_signal('request::activate', 'mouse_click', { raise = true })
                       end),
                       wm.button({ state.modkey }, 1, function(client)
                             client:emit_signal('request::activate', 'mouse_click', { raise = true })
                             wm.mouse.client.move(client)
                       end),
                       wm.button({ state.modkey }, 3, function(client)
                             client:emit_signal('request::activate', 'mouse_click', { raise = true })
                             wm.mouse.client.resize(client)
                       end)
   })

   -- Base window rules
   wm.rules.rules = {
      { -- Base rule
         rule = {},
         properties = {
            border_width = theme.border_width,
            border_color = theme.border_color,
            raise        = true,
            keys         = state.client.keys,
            buttons      = state.client.buttons,
            screen       = wm.screen.preferred,
            placement    = wm.placement.no_overlap + wm.placement.no_offscreen
         }
      },
      { -- Common floating types
         rule_any = {
            instance = { 'pinentry' },
            name = { 'Event Tester' },
            role = { 'pop-up' }
         },
         properties = { floating = true }
      },
      { -- Yakuake
         rule = { class = 'yakuake' },
         properties = {
            floating = true,
            sticky = true,
            maximized_horizontal = true,
            maximized_vertical = false,
            titlebars_enabled = false,
            size_hints_honor = true,
            placement = wm.placement.no_offscreen,
            border_width = 0
         }
      },
      { -- Steam (disable SSD)
         rule = { class = 'Steam' },
         properties = {
            titlebars_enabled = false,
            border_width = 0
         }
      },
      { -- Flameshot (prevent tiling of any popups)
         rule = { class = 'flameshot' },
         properties = { floating = true }
      },
      {
         rule_any = {
            type = { 'normal', 'dialog' }
         },
         properties = { titlebars_enabled = true }
      }
   }

   state.client.titlebar_fn = function(client)
      local buttons = util.table.join(
         wm.button({}, 1, function()
               _G.client.focus = client
               client:raise()
               wm.mouse.client.move(client)
         end),
         wm.button({}, 3, function()
               _G.client.focus = client
               client:raise()
               wm.mouse.client.resize(client)
         end)
      ) -- util.table.join

      local titlebar_layout = {
         { -- Left
            wm.titlebar.widget.iconwidget(client),
            buttons = buttons,
            layout = wibox.layout.fixed.horizontal
         },
         { -- Middle
            { -- Title
               align = 'center',
               widget = wm.titlebar.widget.titlewidget(client)
            },
            buttons = buttons,
            layout = wibox.layout.flex.horizontal
         },
         { -- Right
            wm.titlebar.widget.floatingbutton(client),
            wm.titlebar.widget.maximizedbutton(client),
            wm.titlebar.widget.stickybutton(client),
            wm.titlebar.widget.ontopbutton(client),
            wm.titlebar.widget.closebutton(client),
            layout = wibox.layout.fixed.horizontal
         },
         layout = wibox.layout.align.horizontal
      }

      wm.titlebar(client):setup(titlebar_layout)
   end

   -- Called when mouse enters or exits
   state.client.mouse_fn = function(client, over_client)
      if over_client then
         client:activate { context = 'mouse_enter',
                           raise   = false }
      end
   end

   -- Called when focus changes
   state.client.focus_change_fn = function(client, focused)
      local border_color = theme.border_normal
      if focused then
         border_color = theme.border_focus
      end

      client.border_color = border_color
   end

   state.client.manage_fn = function(client)
      if _G.awesome.startup
         and not client.size_hints.user_position
         and not client.size_hints.program_position then

         wm.placement.no_offscreen(client)
      end
   end

   if not state.client.signals_connected then
      _G.client.connect_signal('request::titlebars', function(c) state.client.titlebar_fn(c) end)
      _G.client.connect_signal('mouse::enter', function(c) state.client.mouse_fn(c, true) end)
      _G.client.connect_signal('mouse::leave', function(c) state.client.mouse_fn(c, false) end)
      _G.client.connect_signal('focus', function(c) state.client.focus_change_fn(c, true) end)
      _G.client.connect_signal('unfocus', function(c) state.client.focus_change_fn(c, false) end)
      _G.client.connect_signal('manage', function(c) state.client.manage_fn(c) end)

      state.client.signals_connected = true
   end
end
