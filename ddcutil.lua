-- quick and dirty interface to ddcutil

local awful = require("awful")

local DDCUtil = {}

function DDCUtil:new(display_sns)
   local tbl = { displays = display_sns }

   setmetatable(tbl, self)
   self.__index = self

   return tbl
end

function ddcutil(...)
   print("ddcutil " .. table.concat({...}, " "))
   awful.spawn("ddcutil " .. table.concat({...}, " "))
end

function DDCUtil:for_all(...)
   for _i, sn in pairs(self.displays) do
      ddcutil("-n " .. sn, ...)
   end
end

-- decrease FEATURE by INCREMENT on all devices
function DDCUtil:dec(feature, incr)
   incr = incr or 1
   self:for_all("setvcp", feature, "-", incr)
end

function DDCUtil:inc(feature, incr)
   incr = incr or 1
   self:for_all("setvcp", feature, "+", incr)
end

function DDCUtil:set(feature, value)
   self:for_all("setvcp --verify", feature, value)
end

return DDCUtil
