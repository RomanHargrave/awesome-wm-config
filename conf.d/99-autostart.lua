-- Autostart applications
-- (C) 2020- Roman Hargrave

local xdg = require('lib/xdg')
local wm  = require('awful')

return function(state, full)
   local skip = os.getenv('SKIP_AUTOSTART')

   if not state.autostart_done and not skip then
      xdg.autostart(wm.spawn)
      state.autostart_done = true
   end
end
