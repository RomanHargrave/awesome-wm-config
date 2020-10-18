-- Helpers to control media players via awesome

local MediaPlayer = require("media_player")

local MediaControl = {}

function MediaControl:new(target_players)
   local tbl = { target_players = {} }

   for _i, player_name in pairs(target_players) do
      table.insert(tbl.target_players, MediaPlayer:new(player_name))
   end

   setmetatable(tbl, self)
   self.__index = self
   
   return tbl
end

function MediaControl:with_connected(func)
   for _i, player in pairs(self.target_players) do
      if player.is_connected then
         func(player)
      end
   end
end

function MediaControl:play_pause()
   self:with_connected(function(p) p:PlayPause() end)
end

function MediaControl:stop()
   self:with_connected(function(p) p:Stop() end)
end

function MediaControl:previous()
   self:with_connected(function(p) p:Previous() end)
end

function MediaControl:next()
   self:with_connected(function(p) p:Next() end)
end

return MediaControl
