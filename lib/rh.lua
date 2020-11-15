-- Odds and ends, utlity functions, etc...
-- (C) 2020- Roman Hargrave

local rh = {}

-- Recursively pretty-print the contents of a table
function rh.dump_table(tbl, depth)
   if type(tbl) ~= 'table' then
      print(tostring(tbl))
   else
      depth = depth or 1
      local padding = ''
      local padding_outer = ''
      
      for i = 1, (depth * 2)  do
         padding = padding .. ' '
      end

      for i = 1, ((depth - 1) * 2) do
         padding_outer = padding_outer .. ' '
      end

      print('{') -- padding will be handled for this by caller
      for k, v in pairs(tbl) do
         io.write(padding)
         io.write('«' .. k .. '» = ')
         if type(v) == 'table' then
            rh.dump_table(v, depth + 1)
         elseif type(v) == 'string' then
            print('«' .. v .. '»')
         else
            print(tostring(v))
         end
      end
      print(padding_outer .. '}')
   end
end

function rh.clone_tbl(tbl)
   local r = {}
   for k, v in pairs(tbl) do
      if type(v) == 'table' then
         r[k] = rh.clone_tbl(v)
      else
         r[k] = v
      end
   end
   return r
end

-- side-effecting
function rh.uniq(tbl)
   table.sort(tbl)
   local r = {tbl[1]}
   for _, e in ipairs(tbl) do
      if r[#r] ~= e then
         table.insert(r, e)
      end
   end
   return r
end

function rh.split_path(str)
   local entries = {}
   local buf = ''

   for i = 1, #str do
      local c = str:sub(i,i)
      if c == ':' then
         table.insert(entries, buf)
         buf = ''
      else
         buf = buf .. c
      end
   end
   return rh.uniq(entries)
end

function rh.collect_exec(path_entries)
   
end

return rh
