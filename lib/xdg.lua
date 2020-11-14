-- Some XDG stuff
-- (C) 2020- Roman Hargrave

local fs = require('minifs')
local ini = require('inifile')

local xdg = {}

function xdg.run_entry(entry_path, exec_fn)
   local cfg = ini.parse(entry_path)
   local cmd = cfg['Desktop Entry']['Exec']

   if cmd then
      exec_fn(cmd)
   end
end

-- Given a function that can start an application, this will call that
-- function with the command for each desktop file in $XDG_HOME/autostart
function xdg.autostart(exec_fn)
   local cfg_dir =
      os.getenv('XDG_CONFIG_HOME')
      or (os.getenv('HOME') .. '/.config')

   local as_dir = cfg_dir .. '/autostart'

   for file in fs.files(as_dir, true) do
      if file:match('.desktop$') then
         xdg.run_entry(file, exec_fn)
      end
   end
end

return xdg
