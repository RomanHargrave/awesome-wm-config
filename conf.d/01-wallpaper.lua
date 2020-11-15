-- Set wallpaper(s)
-- (C) 2020- Roman H

local fs = require('minifs')
local ini = require('inifile')
local util = require('gears')
local theme = require('beautiful')
local wm = require('awful')

local function set_wallpaper(screen, cfg)
   local coords = screen.workarea.x .. 'x' .. screen.workarea.y
   local params = cfg[coords] or cfg.default

   if not params then
      util.debug.warn('no wallpaper params available!')
      return
   end
   
   local format = params.format or 'maximized'
   local file = params.file
   local off_x, off_y = util.string.split(params.offset or '0x0', 'x')
   local offset = { x = tonumber(off_x), y = tonumber(off_y) }
   local ignore_aspect = params.ignore_aspect
   local scale = params.scale or 1
   local fill_color = params.fill_color or theme.bg_normal or '#000000'

   if format == 'centered' then
      util.wallpaper.centered(file, screen, fill_color, scale)
   elseif format == 'tiled' then
      util.wallpaper.tiled(file, screen, offset)
   elseif format == 'maximized' then
      util.wallpaper.maximized(file, screen, ignore_aspect, offset)
   elseif format == 'fit' then
      util.wallpaper.fit(file, screen, fill_color)
   else
      util.debug.print_warning('invalid wallpaper format «' .. format .. '»')
   end
end

return function(state, full)
   local wallpaper_ini = state.cfg_dir .. 'wallpaper.ini'
   if fs.exists(wallpaper_ini) then
      state.wallpaper_cfg = ini.parse(wallpaper_ini)

      for screen in _G.screen do
         set_wallpaper(screen, state.wallpaper_cfg)
      end
   end

   if not state.wallpaper_connected then
      _G.screen.connect_signal('request::wallpaper',
                               function(screen)
                                  set_wallpaper(screen, state.wallpaper_cfg)
                               end
      ) -- _G.screen.connect_signal
      state.wallpaper_connected = true
   end
end
