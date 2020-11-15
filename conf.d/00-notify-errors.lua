-- Catch error signal and show notification
-- (C) 2020- Roman Hargrave

local wm = require('awful')
local notifications = require('naughty')

return function(state, full)
   state.notifying_error = false

   if not state.notify_error_installed then
      _G.awesome.connect_signal('debug::error',
                        function(err)
                           if state.notifying_error then
                              return
                           end

                           state.notifying_error = true

                           notifications.notify({ present = notifications.config.presets.critical,
                                                  title   = 'An error occurred',
                                                  text    = tostring(err) })

                           state.notifying_error = false
                        end
      ) -- wm.connect_signal

      state.notify_error_installed = true
   end
end
