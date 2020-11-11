-- Personal Awesome (WM) configuration
-- (C) 2020- Roman Hargrave
-- License: GPL-3

require('luarocks.loader')

local fs     = require('lfs')
local util   = require('gears')
local wm     = require('awful')
local theme  = require('beautiful')
local notify = require('naughty')
local menu   = require('menubar')

local MediaControl = require('lib/media_control')
local DDCUtil      = require('lib/ddcutil')

-- Table that tracks configuration state across reloads
local wm_state = {
   media           = MediaControl:new({"cantata"}),
   ddc             = DDCUtil:new({"HTPM400169", "HTPM400178"}),
   keys            = {},
   default_layouts = {},
   modkey          = "Mod4",
}

-- Collects fragments to load
function collect_frags(dir)
   local sorted = {}
   for file in fs.dir(dir) do
      if string.match(file, '.lua$') then
         --table.insert(sorted, dir .. '/' .. string.gsub(file, '.lua$', ''))
         table.insert(sorted, dir .. '/' .. file)
      end
   end

   table.sort(sorted)

   return sorted
end

-- iterate through fragment files and loads them
-- order of loading depends on both the system sorting results
-- as well as frags being named in order to take advantage
-- (e.g. 00-first.lua, ZZ-last.lua)
function load_frags(state, full)
   local frag_dir = util.filesystem.get_configuration_dir() .. "conf.d"
   print('Loading fragments from ' .. frag_dir)

   for _i, frag_name in ipairs(collect_frags(frag_dir)) do
      print('Loading fragment ' .. frag_name)
      local frag = dofile(frag_name)
      frag(state, full)
   end
end

-- load fragments, update any values controlled by state table
function load_config(state, full)
   -- run state through frags
   load_frags(state, full)

   -- re-set keybinds to populated keybindings
   root.keys(state.keys)

   -- re-load default layout list
   -- this is done in the following fashion to be "nice" to the layout handler
   for _i, layout in ipairs(wm.layout.layouts) do wm.layout.remove_default_layout(layout) end
   for _i, layout in ipairs(state.default_layouts) do wm.layout.append_default_layout(layout) end
end


----------------------------
-- Load the configuration

load_config(wm_state, true)
