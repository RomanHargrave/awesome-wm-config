-- Run command with suggestions
-- (C) 2020- Roman Hargrave

local lfs = require('lfs')
local util = require('gears')
local rh = require('lib/rh')
local wm = require('awful')

local function is_executable(attrs)
   if attrs then
      local p = attrs.permissions
      -- this disgusts me, and doesn't even understand ACLs or user context!
      return (p:sub(3,3) == 'x'
              or p:sub(6,6) == 'x'
              or p:sub(7,7) == 'x')
   end
   return false
end

local function is_dir(path)
   local attrs = lfs.attributes(path)
   if attrs then
      return attrs.mode == 'directory'
   end
   return false
end

local function collect_commands()
   local path_dirs = rh.split_path(os.getenv('PATH'))
   local r = {}

   for _, dir in ipairs(path_dirs) do
      if is_dir(dir) then
         local iter, dh = lfs.dir(dir)
         local file = iter(dh)
         while file do
            local abspath = dir .. '/' .. file
            local attrs = lfs.attributes(abspath)

            if attrs
               and attrs.mode == 'file'
               and is_executable(attrs)
            then
               table.insert(r, file)
            end

            file = iter(dh)
         end
      end
   end

   return rh.uniq(r)
end

local known_commands = collect_commands()
local suggest_limit = 10

local run_command = {
   verb = 'r',
   description = 'run command',
   help = 'r command*',
   completion_fn = function(data)
      local count = 1
      local suggestions = {}
      local nw = data.syn.head:next_word()
      local filter = ''
      if nw then
         filter = nw:join_raw()
      end

      for _, cmd in ipairs(known_commands) do
         if count > suggest_limit then
            break
         end
         if string.match(cmd, '^' .. filter) then
            table.insert(suggestions, { text = cmd,
                                        description = 'executable in path' })
            count = count + 1
         end
      end

      return suggestions
   end,
   exec_fn = function(argv)
      local nw = argv.syn.head:next_word()
      if nw then
         wm.spawn(nw:join_raw(), false)
      end
   end
}

return function(state, full)
   table.insert(state.commands, run_command)
end
