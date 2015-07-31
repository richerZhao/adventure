
local Npc = class("Npc",function (params)
	local frame = display.newSpriteFrame(params.textureName)
	return cc.Sprite:createWithSpriteFrame(frame)
end)

Npc.DIRECTION_UP = 1
Npc.DIRECTION_DOWN = 2
Npc.DIRECTION_LEFT = 3
Npc.DIRECTION_RIGHT = 4

function Npc.create(params)
	local npc = Npc.new(params)
	return npc
end

function Npc:ctor(params)
	if params.scale then
		self:setScale(params.scale)
	end
	if params.flippedX then
		self:setFlippedX(true)
	end
	if params.speed then
		self.speed_ = params.speed
	else
		self.speed_ = 32
	end

	self.openTable_ = {}
	self.opencloseTable_ = {}

end

function Npc:setMap(map)
	self.map_ = map
end

function Npc:registActionFrame(actionName,frames)
	if actionName == "walk" then
		self.walkFrames_ = frames
	elseif actionName == "fight" then
		self.fightFrames_ = frames
	end
end

function Npc:walk(direction)
	local animation = display.newAnimation(self.walkFrames_, 1/8)
	-- animation:setRestoreOriginalFrame(true)	--动画执行完成后还原到初始状态
	local action =cc.Animate:create(animation)   
	self:runAction(cc.RepeatForever:create(action))  
end

--设置方向
function Npc:setDirection(direction)
	if direction == Npc.DIRECTION_RIGHT then
		self:setFlippedX(true)
	elseif direction == Npc.DIRECTION_LEFT then
		self:setFlippedX(false)
	end
end

--向某个方向移动一定距离
function Npc:moveForward(direction,point)
	if self.direction_ ~= direction then
		self:stopAllActions()
		self:setDirection(direction)
		self:walk(direction)
	end
	
	local x,y = 0
	if direction == Npc.DIRECTION_RIGHT then
		x = 32
	elseif direction == Npc.DIRECTION_LEFT then
		x = -32
	elseif direction == Npc.DIRECTION_UP then
		y = 32
	elseif direction == Npc.DIRECTION_DOWN then
		y = -32
	end
	local moveTime = duration / self.speed_
	self:moveBy(moveTime, x, y)
end

function Npc:moveToward(targetPos)
	local target = self.map_:convertToNodeSpace(targetPos)
	local targetTiledX = math.modf(target.x/self.map_:getTileSize().width)
	local targetTiledY = math.modf(((self.map_:getMapSize().height * self.map_:getTileSize().height ) - target.y) / self.map_:getTileSize().height)
	local selfTiledX  = math.modf(self:getPositionX()/self.map_:getTileSize().width)
	local selfTiledY = math.modf(((self.map_:getMapSize().height * self.map_:getTileSize().height ) - self:getPositionY()) / self.map_:getTileSize().height)
	if targetTiledX == selfTiledX and targetTiledY == selfTiledY then
		print("already on target tiled!")
		return
	end

	local targerNode = cc.p(targetTiledX,targetTiledY)
	--检查终点是否可以到达
	if not self:canReach(targerNode) then
		print("hit wall")
		return
	end
	table.insert(self.openTable_, {x=selfTiledX,y=selfTiledY,g=0,h=0,f=0})
	local currentNode = table.remove(self.openTable_,1)
	table.insert(self.closeTable_, currentNode)
	local canReachTiles = self:getCanReachTiles(currentNode)
	for i,v in ipairs(canReachTiles) do
		v.parent = currentNode
		v.g = v.parent.g + getGScore()
		self:inserIntoOpenTable(v,targerNode)
	end

	while not (targetTiledX == currentNode.x and targetTiledY == currentNode.y) do
		if not self:isInCloseTable(currentNode) then
			--更新OPENTABLE的FScore
			
		end

		currentNode = table.remove(self.openTable_,1)
		table.insert(self.closeTable_, currentNode)
		canReachTiles = self:getCanReachTiles(currentNode)
		for i,v in ipairs(canReachTiles) do
			local index = self:getIndexFromOpenTable(currentNode)
			if index then
				if self.openTable_[index].g > currentNode.g then
					--替换
				end
			end
			v.parent = currentNode
			v.g = v.parent.g + getGScore()
			self:inserIntoOpenTable(v,targerNode)
		end
		
	end

end

function Npc:inserIntoOpenTable(currentNode,targetNode)
	local currentFScore = getFScore(currentNode,targetNode)
	for i,v in ipairs(self.openTable_) do
		local nextFScore = getFScore(v,targetNode)
		if currentFScore < nextFScore then
			table.insert(self.openTable_, i,currentNode)
		end
	end
	table.insert(self.openTable_,currentNode)
end

function Npc:isInCloseTable( currentNode )
	for i,v in ipairs(self.closeTable_) do
		if currentNode.x == v.x and currentNode.y == v.y then
			return true
		end
	end
	return false
end

function Npc:getIndexFromOpenTable( currentNode )
	for i,v in ipairs(self.openTable_) do
		if currentNode.x == v.x and currentNode.y == v.y then
			return i
		end
	end
	return nil
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


function Npc:getCanReachTiles(tmpPos)
	local tiles = {}
	--右边
	if self:canReach({x=tmpPos.x + 1, y=tmpPos.y}) then
		table.insert(tiles, {x=tmpPos.x + 1, y=tmpPos.y})
	end
	--左边
	if self:canReach({x=tmpPos.x - 1, tmpPos.y}) then
		table.insert(tiles, {x=tmpPos.x - 1, tmpPos.y})
	end
	--上边
	if self:canReach({x=tmpPos.x, tmpPos.y - 1}) then
		table.insert(tiles, {x=tmpPos.x, tmpPos.y - 1})
	end
	--下边
	if self:canReach({x=tmpPos.x, tmpPos.y + 1}) then
		table.insert(tiles, {x=tmpPos.x, tmpPos.y + 1})
	end

	return tiles
end

function Npc:canReach(tmpPos)
	local gid = self.map_:getLayer("obstacleLayer"):getTileGIDAt(cc.p(tmpPos.x,tmpPos.y))
	if gid > 0 then
		local propertites = self.map_:getPropertiesForGID(gid)
		if propertites.canMoveOn == "0" then
			return false
		end
	end
	return true
end

function Npc:getFScore()

end

-- function Player:moveBy(background,moveX,moveY)
-- 	local moveToX = self:getPositionX() - background:getPositionX() + moveX
-- 	local moveToY = self:getPositionY() - background:getPositionY() + moveY
-- 	local tiledX = math.modf(moveToX/background:getTileSize().width)
-- 	local tiledY = math.modf(((background:getMapSize().height * background:getTileSize().height ) - moveToY) / background:getTileSize().height) 
-- 	local gid = background:getLayer("obstacleLayer"):getTileGIDAt(cc.p(tiledX,tiledY))
-- 	if gid > 0 then
-- 		local propertites = background:getPropertiesForGID(gid)
-- 		if propertites.canMoveOn ~= "0" then
-- 			if self:isMove() then
				
-- 			elseif conditions then
-- 				--todo
-- 			end
-- 		else
-- 		    --播放阻挡音乐
-- 		    return false
-- 		end
-- 	else
-- 		self:playerMoveOn(self.sprite, self.map, moveX, moveY)
-- 	end
-- 	return true
-- end

-- function Player:move_(mapSize)
-- 	local isSelfMove = true
-- 	if (self:getPositionX() >= display.width / 2) and (self:getPositionX() <= mapSize.width - display.width / 2) then
-- 		return false
-- 	end
-- 	if player:getPositionY() >= display.height / 2 and (self:getPositionY() <= mapSize.height - display.height / 2)  then
-- 		return false
-- 	end
-- 	if isSelfMove then
-- 		self:moveBy(1, moveX, moveY)
-- 	else
-- 	 	self:moveBy(1, moveX, moveY)
-- 	end
-- 	return true
-- end

-- function Player:moveOnGround(mapSize)
-- 	local isSelfMove = true
-- 	if (self:getPositionX() >= display.width / 2) and (self:getPositionX() <= mapSize.width - display.width / 2) then
-- 		return false
-- 	end
-- 	if player:getPositionY() >= display.height / 2 and (self:getPositionY() <= mapSize.height - display.height / 2)  then
-- 		return false
-- 	end
-- 	if isSelfMove then
-- 		self:moveBy(1, moveX, moveY)
-- 	else
-- 	 	self:moveBy(1, moveX, moveY)
-- 	end
-- 	return true
-- end



return Npc