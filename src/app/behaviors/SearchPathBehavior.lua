local BehaviorBase = require("app.behaviors.BehaviorBase")
local SearchPathBehavior = class("SearchPathBehavior",BehaviorBase)

function SearchPathBehavior:ctor()
	SearchPathBehavior.super.ctor(self,"SearchPathBehavior",nil,1)
end

function SearchPathBehavior:bind(object)
	local function searchPath(object,targetPos)
		local current = object.map_:convertMapPositionToTile(cc.p(object:getPosition()))
		local target = object.map_:convertMapPositionToTile(targetPos)
		dump(target, "target", target)
		dump(current, "current", current)
		local tiles = object:searchPath_(current,target)
		if not tiles then return end
		dump(tiles, "tiles", tiles)
		local points = {}
		for i,v in ipairs(tiles) do
			table.insert(points, cc.p(object.map_:convertTileToMapPosition(v)))
		end
		return points
	end
	object:bindMethod(self, "searchPath", searchPath)

	local function searchPath_(object,currentPos,targetPos)
		if targetPos.x == currentPos.x and targetPos.y == currentPos.y then
			print("already on target tiled!")
			return
		end

		--检查终点是否可以到达
		if not object.map_:canReach_(targetPos) then
			return
		end

		local openTable_ = {}
		local closeTable_ = {}

		table.insert(openTable_, {x=currentPos.x,y=currentPos.y,g=0,h=0,f=0})
		local currentNode = table.remove(openTable_,1)
		table.insert(closeTable_, currentNode)
		local canReachTiles = object.map_:getCanReachTiles_(currentNode)
		for i,v in ipairs(canReachTiles) do
			v.parent = currentNode
			v.g = v.parent.g + getGScore()
			v.h = getHScore(currentNode, targetPos)
			inserIntoOpenTable(openTable_,v,targetPos)
		end

		while not (targetPos.x == currentNode.x and targetPos.y == currentNode.y) do
			if not isInCloseTable(closeTable_,currentNode) then
				--更新OPENTABLE的FScore
				canReachTiles = object.map_:getCanReachTiles_(currentNode)
				for i,v in ipairs(canReachTiles) do
					local index = getIndexFromOpenTable(openTable_,v)
					if index then
						if openTable_[index].g > currentNode.g + getGScore() then
							--替换
							table.remove(openTable_,index)
							inserIntoOpenTable(openTable_,currentNode,targetPos)
						end
					else
						v.parent = currentNode
						v.g = v.parent.g + getGScore()
						v.h = getHScore(currentNode, targetPos)
						inserIntoOpenTable(openTable_,v,targetPos)
					end
				end
				table.insert(closeTable_, currentNode)
			end
			local nextNode = table.remove(openTable_,1)
			if nextNode then
				currentNode = nextNode
			else
				return
			end
		end

		local points = {}
		while currentNode.parent do
			if table.getn(points) == 0 then
				table.insert(points, cc.p(currentNode.x, currentNode.y))
			else
				table.insert(points,1, cc.p(currentNode.x, currentNode.y))
			end
			currentNode = currentNode.parent
		end
		return points
	end

	object:bindMethod(self, "searchPath_", searchPath_)
end

function SearchPathBehavior:unbind(object)
	object:unbindMethod(self, "searchPath")
	object:unbindMethod(self, "searchPath_")
	self:reset(object)
end

function SearchPathBehavior:reset(object)
	
end

function inserIntoOpenTable(openTable_,currentNode,targetNode)
	local currentFScore = getFScore(currentNode,targetNode)
	for i,v in ipairs(openTable_) do
		local nextFScore = getFScore(v,targetNode)
		if currentFScore < nextFScore then
			table.insert(openTable_, i,currentNode)
			return
		end
	end
	table.insert(openTable_,currentNode)
end

function isInCloseTable(closeTable_,currentNode )
	for i,v in ipairs(closeTable_) do
		if currentNode.x == v.x and currentNode.y == v.y then
			return true
		end
	end
	return false
end

function getFScore(currentNode,targetNode)
	return currentNode.g + getHScore(currentNode,targetNode)
end

function getGScore()
	return 1
end

function getHScore(currentNode,targetNode)
	return math.abs(currentNode.x - targetNode.x) + math.abs(currentNode.y - targetNode.y)
end

function getIndexFromOpenTable(openTable_,currentNode )
	for i,v in ipairs(openTable_) do
		if currentNode.x == v.x and currentNode.y == v.y then
			return i
		end
	end
	return nil
end

return SearchPathBehavior