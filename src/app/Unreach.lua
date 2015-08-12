local ObjectBase = require("app.ObjectBase")

local Unreach = class("Unreach",ObjectBase)

function Unreach:ctor(id, state, map)
	Unreach.super.ctor(self, id, state, map)
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