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

return rh
