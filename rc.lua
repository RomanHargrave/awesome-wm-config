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
_G.rh_data = {
   media           = MediaControl:new({"cantata"}),
   ddc             = DDCUtil:new({"HTPM400169", "HTPM400178"}),
   keys            = {},
   default_layouts = {},
   client          = { keys = {}, buttons = {} },
   modkey          = "Mod4",
   cfg_dir         = util.filesystem.get_configuration_dir()
}

-- Collects fragments to load
function rh_data:collect_frags()
   local dir = self.cfg_dir .. 'conf.d'
   self.frags = {}
   for file in fs.dir(dir) do
      if string.match(file, '.lua$') then
         table.insert(self.frags, dir .. '/' .. file)
      end
   end

   table.sort(self.frags)
end

function rh_data:load_frag(frag_name, full)
   local frag = dofile(frag_name)
   local s, r = pcall(frag, self, full)

   if not s then
      util.debug.print_warning('Failed to load frag «' .. frag_name .. '»: ' .. r)
   end
end

-- iterate through fragment files and loads them
-- order of loading depends on both the system sorting results
-- as well as frags being named in order to take advantage
-- (e.g. 00-first.lua, ZZ-last.lua)
function rh_data:load_frags(full)
   self:collect_frags()
   for _, frag_name in ipairs(self.frags) do
      self:load_frag(frag_name, full)
   end
end

-- load fragments, update any values controlled by state table
function rh_data:load_config(full)
   -- reset declarative stuff
   self.commands = {}
   self.keys = {}
   self.client.keys = {}
   self.client.buttons = {}

   -- run frags
   self:load_frags(full)

   -- re-set keybinds to populated keybindings
   -- TODO use new global keybinding API
   root.keys(self.keys)

   -- re-load default layout list
   -- this is done in the following fashion to be "nice" to the layout handler
   for _i, layout in ipairs(wm.layout.layouts) do wm.layout.remove_default_layout(layout) end
   for _i, layout in ipairs(self.default_layouts) do wm.layout.append_default_layout(layout) end
end

-- Load the configuration

rh_data:load_config(true)
