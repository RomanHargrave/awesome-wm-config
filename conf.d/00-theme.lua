-- Theme config fragment
-- (C) 2020- Roman Hargrave
-- License: GPL-3

local wm    = require('awful')
local util  = require('gears')
local theme = require('beautiful')

return function(state, full)
   theme.init(state.cfg_dir .. 'themes/pine/theme.lua')
   theme.font = 'sans 11'
   theme.wallpaper = state.cfg_dir .. 'themes/pine/background.jpg'
end
