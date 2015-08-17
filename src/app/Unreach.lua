local ObjectBase = require("app.ObjectBase")

local Unreach = class("Unreach")

function Unreach:ctor()
	self.valid_            = true
	self.unreachTiles_ 	   = {}
end

function Unreach:addUnreachTile(tile)
	local key = string.format("%s:%s", tile.x,tile.y)
	self.unreachTiles_[key]  =  tile
end

function Unreach:removeUnreachTile(tile)
	local key = string.format("%s:%s", tile.x,tile.y)
	self.unreachTiles_[key]  =  nil
end

function Unreach:isUnreachTile(tile)
	local key = string.format("%s:%s", tile.x,tile.y)
	return self.unreachTiles_[key] ~= nil
end

return Unreach