-- Theme config fragment
-- (C) 2020- Roman Hargrave
-- License: GPL-3

local wm    = require('awful')
local util  = require('gears')
local theme = require('beautiful')

return function(state, full)
   theme.init(util.filesystem.get_themes_dir() .. 'default/theme.lua')
   --theme.init({ font = 'sans 10' })
   theme.font = 'sans 12'
end
