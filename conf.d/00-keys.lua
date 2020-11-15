-- Keybindings config frament
-- (C) 2020- Roman Hargrave
-- License: GPL-3

local wm  = require('awful')

return function(state, full)
   state.keys = {
      -- Toggle main wibar visibility on current screen
      wm.key({state.modkey}, 'w', function()
            local wibar = mouse.screen.wibar
            wibar.visible = not wibar.visible
      end),

      -- Media control
      wm.key({}, 'XF86AudioPlay', function() state.media:play_pause() end),
      wm.key({}, 'XF86AudioNext', function() state.media:next() end),
      wm.key({'Mod1'}, 'XF86AudioNext', function() state.media:previous() end),

      -- Activate flameshot
      wm.key({}, 'F22', function() wm.spawn('flameshot gui') end),

      -- Toggle yakuake
      wm.key({}, 'F24', function() wm.spawn('yakuake') end),

      -- Open terminal
      wm.key({state.modkey}, 'Return', function() awful.spawn('konsole') end),
   }
end
