-- Theme config fragment
-- (C) 2020- Roman Hargrave
-- License: GPL-3

local wm    = require('awful')
local util  = require('gears')
local theme = require('beautiful')

return function(state, full)
   theme.init(util.filesystem.get_themes_dir() .. 'zenburn/theme.lua')
end
