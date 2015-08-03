import(".searchpath")
local Npc = class("Npc",function (params)
	local frame = display.newSpriteFrame(params.textureName)
	return cc.Sprite:createWithSpriteFrame(frame)
end)

Npc.STATUS_IDLE = 1
Npc.STATUS_MOVE = 2

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
	self.closeTable_ = {}
	self.state_ = npcstate.IDLE
	self.oribt_ = {}
	-- self.fighttarget_ = {}
	self.event_ = {}
	self.status_ = Npc.STATUS_IDLE
	self.enemy_ = nil
	self.direction_ = npcdirect.DIRECTION_RIGHT
	self:setFlippedX(true)

	local walkFrames = display.newFrames(params.playerName.."_walk_1_%02d.png",1,8)
    self:registActionFrame("walk", walkFrames)
    local idleFrames = display.newFrames(params.playerName.."_stand_1_%02d.png",1,4)
    self:registActionFrame("idle", idleFrames)
    local fightFrames = display.newFrames(params.playerName.."_dance_a_1_%02d.png",1,8)
    self:registActionFrame("fight", fightFrames)
end

function Npc:runAI(map)
	self.map_ = map
	local action = getNpcNextAction(self)
	if action then
		executeNpcAction(self,action,nextNpcAction)
	end
end

function Npc:registActionFrame(actionName,frames)
	if actionName == "walk" then
		self.walkFrames_ = frames
	elseif actionName == "fight" then
		self.fightFrames_ = frames
	elseif actionName == "idle" then
		self.idleFrames_ = frames
	end
end

function Npc:walk()
	if self.status_ ~= Npc.STATUS_MOVE then
		self:stopAllActions()
	end
	local animation = display.newAnimation(self.walkFrames_, 1/8)
	-- animation:setRestoreOriginalFrame(true)	--动画执行完成后还原到初始状态
	local action =cc.Animate:create(animation)   
	self:runAction(cc.RepeatForever:create(action))  
end

function Npc:idle()
	if self.status_ ~= Npc.STATUS_IDLE then
		self:stopAllActions()
	end
	local animation = display.newAnimation(self.idleFrames_, 1/8)
	-- animation:setRestoreOriginalFrame(true)	--动画执行完成后还原到初始状态
	local action =cc.Animate:create(animation)   
	self:runAction(cc.RepeatForever:create(action))  
end

--设置方向
function Npc:setDirection(direction)
	self.direction_ = direction
	if direction == npcdirect.DIRECTION_RIGHT then
		self:setFlippedX(true)
	elseif direction == npcdirect.DIRECTION_LEFT then
		self:setFlippedX(false)
	end
end

function Npc:move(position)
	local mapPoint = self.map_:convertToNodeSpace(position)
	local selfPoint = self.map_:convertToNodeSpace(cc.p(self:getPositionX(),self:getPositionY()))
	local lengthX = mapPoint.x - selfPoint.x
	local lengthY = mapPoint.y - selfPoint.y
	if math.abs(lengthX) >= math.abs(lengthY) then
		if lengthX < 0 then
		   	--向左移动一格
		    direction = npcdirect.DIRECTION_LEFT
		elseif lengthX > 0 then
		    --向右移动一格
		    direction = npcdirect.DIRECTION_RIGHT
		end
	else
		if lengthY < 0 then
		   	--向下移动一格
		    direction = npcdirect.DIRECTION_DOWN
		elseif lengthY > 0 then
		   	--向上移动一格
		    direction = npcdirect.DIRECTION_UP
		end
	end
	self:setDirection(direction)
	self:walk()
	return cca.moveTo(1,position.x,position.y)
end

-- --向某个方向移动一定距离
-- function Npc:moveForward(direction,point)
-- 	if self.direction_ ~= direction then
-- 		self:stopAllActions()
-- 		self:setDirection(direction)
-- 		self:walk(direction)
-- 	end
	
-- 	local x,y = 0
-- 	if direction == npcdirect.DIRECTION_RIGHT then
-- 		x = 32
-- 	elseif direction == npcdirect.DIRECTION_LEFT then
-- 		x = -32
-- 	elseif direction == npcdirect.DIRECTION_UP then
-- 		y = 32
-- 	elseif direction == npcdirect.DIRECTION_DOWN then
-- 		y = -32
-- 	end
-- 	local moveTime = duration / self.speed_
-- 	self:moveBy(moveTime, x, y)
-- end

function Npc:moveToward(targetPos)
	-- local target = self.map_:convertToNodeSpace(targetPos)
	-- local targetTiledX = math.modf(target.x/self.map_:getTileSize().width)
	-- local targetTiledY = math.modf(((self.map_:getMapSize().height * self.map_:getTileSize().height ) - target.y) / self.map_:getTileSize().height)
	-- local selfTiledX  = math.modf(self:getPositionX()/self.map_:getTileSize().width)
	-- local selfTiledY = math.modf(((self.map_:getMapSize().height * self.map_:getTileSize().height ) - self:getPositionY()) / self.map_:getTileSize().height)
	-- if targetTiledX == selfTiledX and targetTiledY == selfTiledY then
	-- 	print("already on target tiled!")
	-- 	return
	-- end

	-- local targetNode = cc.p(selfTiledX,selfTiledY)
	-- local selfNode = cc.p(selfTiledX,selfTiledY)
	-- -- local selfNode = cc.p(targetTiledX,targetTiledY)

	-- dump(targetNode, "targetNode", targetNode)
	-- dump(selfNode, "selfNode", selfNode)
	-- dump(self.openTable_, "self.openTable_", self.openTable_)
	-- dump(self.closeTable_, "self.openTable_", self.closeTable_)
	-- --检查终点是否可以到达
	-- if not self:canReach(targetNode) then
	-- 	print("hit wall")
	-- 	return
	-- end
	-- table.insert(self.openTable_, {x=targetTiledX,y=targetTiledY,g=0,h=0,f=0})
	-- -- table.insert(self.openTable_, {x=selfTiledX,y=targetTiledY,g=0,h=0,f=0})
	-- local currentNode = table.remove(self.openTable_,1)
	-- -- dump(currentNode, "currentNode", currentNode)
	-- table.insert(self.closeTable_, currentNode)
	-- local canReachTiles = self:getCanReachTiles(currentNode)
	-- -- dump(canReachTiles, "canReachTiles", canReachTiles)
	-- for i,v in ipairs(canReachTiles) do
	-- 	v.parent = currentNode
	-- 	v.g = v.parent.g + getGScore()
	-- 	v.h = getHScore(currentNode, targetNode)
	-- 	self:inserIntoOpenTable(v,targetNode)
	-- end
	-- -- dump(self.openTable_, "self.openTable_", self.openTable_)
	-- -- dump(self.closeTable_, "self.closeTable_", self.closeTable_)

	-- while not (targetNode.x == currentNode.x and targetNode.y == currentNode.y) do
	-- 	if not self:isInCloseTable(currentNode) then
	-- 		--更新OPENTABLE的FScore
	-- 		canReachTiles = self:getCanReachTiles(currentNode)
	-- 		if currentNode.y == 65 then
	-- 			dump(currentNode, "currentNode", currentNode)
	-- 			dump(canReachTiles, "canReachTiles", canReachTiles)
	-- 		end
			
	-- 		for i,v in ipairs(canReachTiles) do
	-- 			local index = self:getIndexFromOpenTable(currentNode)
	-- 			if index then
	-- 				if self.openTable_[index].g > currentNode.g + getGScore() then
	-- 					--替换
	-- 					table.remove(self.openTable_,index)
	-- 					self:inserIntoOpenTable(currentNode,targetNode)
	-- 				end
	-- 			else
	-- 				v.parent = currentNode
	-- 				v.g = v.parent.g + getGScore()
	-- 				v.h = getHScore(currentNode, targetNode)
	-- 				self:inserIntoOpenTable(v,targetNode)
	-- 			end
	-- 		end
	-- 		table.insert(self.closeTable_, currentNode)
	-- 		-- dump(self.closeTable_, "self.closeTable_", self.closeTable_)
	-- 	end
	-- 	currentNode = table.remove(self.openTable_,1)
	-- 	-- dump(currentNode, "currentNode", currentNode)
	-- 	-- dump(currentNode, "currentNode", currentNode)
	-- 	-- dump(self.openTable_, "self.openTable_", self.openTable_)
		
	-- end

	-- local points = {}
	-- while currentNode.parent do
	-- 	if table.getn(points) == 0 then
	-- 		table.insert(points, cc.p(currentNode.x, currentNode.y))
	-- 	else
	-- 		table.insert(points,1, cc.p(currentNode.x, currentNode.y))
	-- 	end
	-- 	currentNode = currentNode.parent
	-- end
	-- self.openTable_ = {}
	-- self.closeTable_ = {}
	-- dump(points, "points", points)
	npcSearchPath(self,targetPos)
	local action = getNpcNextAction(self)
	if action then
		executeNpcAction(self,action,nextNpcAction)
	end
end



function Npc:inserIntoOpenTable(currentNode,targetNode)
	local currentFScore = getFScore(currentNode,targetNode)
	for i,v in ipairs(self.openTable_) do
		local nextFScore = getFScore(v,targetNode)
		if currentFScore < nextFScore then
			table.insert(self.openTable_, i,currentNode)
			return
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

function Npc:getCanReachTiles(tmpPos)
	local maxX = self.map_:getMapSize().width - 1
	local maxY = self.map_:getMapSize().height - 1
	local tiles = {}
	if tmpPos.x + 1 <= maxX then
		--右边
		if self:canReach({x=tmpPos.x + 1, y=tmpPos.y}) then
			table.insert(tiles, {x=tmpPos.x + 1, y=tmpPos.y})
		end
	end
	
	if tmpPos.x - 1 >= 0 then
		--左边
		if self:canReach({x=tmpPos.x - 1, y=tmpPos.y}) then
			table.insert(tiles, {x=tmpPos.x - 1, y=tmpPos.y})
		end
	end

	if tmpPos.y - 1 >= 0 then
		--上边
		if self:canReach({x=tmpPos.x, y=tmpPos.y - 1}) then
			table.insert(tiles, {x=tmpPos.x, y=tmpPos.y - 1})
		end
	end

	if tmpPos.y + 1 <= maxY then
		--下边
		if self:canReach({x=tmpPos.x, y=tmpPos.y + 1}) then
			table.insert(tiles, {x=tmpPos.x, y=tmpPos.y + 1})
		end
	end
	return tiles
end

function Npc:canReach(tmpPos)
	-- print("tmpPos.x="..tmpPos.x..",tmpPos.y="..tmpPos.y)
	local gid = self.map_:getLayer("obstacleLayer"):getTileGIDAt(cc.p(tmpPos.x,tmpPos.y))
	if gid > 0 then
		local propertites = self.map_:getPropertiesForGID(gid)
		if propertites.canMoveOn == "0" then
			return false
		end
	end
	return true
end



return Npc