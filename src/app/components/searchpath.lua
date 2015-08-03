import(".constant")
function npcSearchPath(npc,targetPos)
	local target = npc.map_:convertToNodeSpace(targetPos)
	local targetTiledX = math.modf(target.x/npc.map_:getTileSize().width)
	local targetTiledY = math.modf(((npc.map_:getMapSize().height * npc.map_:getTileSize().height ) - target.y) / npc.map_:getTileSize().height)
	npcSearchPath_(npc,cc.p(targetTiledX,targetTiledY))
end

function npcSearchPath_(npc,targetNode)
	local selfTiledX  = math.modf(npc:getPositionX()/npc.map_:getTileSize().width)
	local selfTiledY = math.modf(((npc.map_:getMapSize().height * npc.map_:getTileSize().height ) - npc:getPositionY()) / npc.map_:getTileSize().height)
	if targetTiledX == selfTiledX and targetTiledY == selfTiledY then
		print("already on target tiled!")
		return
	end

	local selfNode = cc.p(selfTiledX,selfTiledY)
	-- local selfNode = cc.p(targetTiledX,targetTiledY)

	-- dump(targetNode, "targetNode", targetNode)
	-- dump(selfNode, "selfNode", selfNode)
	-- dump(npc.openTable_, "self.openTable_", npc.openTable_)
	-- dump(npc.closeTable_, "self.openTable_", npc.closeTable_)
	--检查终点是否可以到达
	if not npc:canReach(targetNode) then
		return
	end
	table.insert(npc.openTable_, {x=selfTiledX,y=selfTiledY,g=0,h=0,f=0})
	local currentNode = table.remove(npc.openTable_,1)
	table.insert(npc.closeTable_, currentNode)
	local canReachTiles = npc:getCanReachTiles(currentNode)
	for i,v in ipairs(canReachTiles) do
		v.parent = currentNode
		v.g = v.parent.g + getGScore()
		v.h = getHScore(currentNode, targetNode)
		npc:inserIntoOpenTable(v,targetNode)
	end

	while not (targetNode.x == currentNode.x and targetNode.y == currentNode.y) do
		if not npc:isInCloseTable(currentNode) then
			--更新OPENTABLE的FScore
			canReachTiles = npc:getCanReachTiles(currentNode)
			
			for i,v in ipairs(canReachTiles) do
				local index = npc:getIndexFromOpenTable(currentNode)
				if index then
					if npc.openTable_[index].g > currentNode.g + getGScore() then
						--替换
						table.remove(npc.openTable_,index)
						npc:inserIntoOpenTable(currentNode,targetNode)
					end
				else
					v.parent = currentNode
					v.g = v.parent.g + getGScore()
					v.h = getHScore(currentNode, targetNode)
					npc:inserIntoOpenTable(v,targetNode)
				end
			end
			table.insert(npc.closeTable_, currentNode)
		end
		currentNode = table.remove(npc.openTable_,1)
		if not currentNode then 
			break
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
	npc.openTable_ = {}
	npc.closeTable_ = {}
	npc.oribt_= points
	npc.state_ = npcstate.MOVE
end

function executeNpcAction(npc,action,callback)
	transition.execute(npc, action, {  
	    onComplete = function(npc)
		    nextNpcAction(npc)
	    end,
	    time = 1,
	})  
end

function nextNpcAction(npc)
	local action = getNpcNextAction(npc)
	if action then
		executeNpcAction(npc,action,nextNpcAction)
	end
end

function getNpcNextAction(npc)
	--检查附近是否有怪物
	if not npc.enemy_ then
		local enemy = searchEnemy(npc)
		if enemy then
			local target = npc.map_:convertToNodeSpace(cc.p(enemy:getPositionX(),enemy:getPositionY()))
			local targetTiledX = math.modf(target.x/npc.map_:getTileSize().width)
			local targetTiledY = math.modf(((npc.map_:getMapSize().height * npc.map_:getTileSize().height ) - target.y) / npc.map_:getTileSize().height)
			local npcPos = npc.map_:convertToNodeSpace(cc.p(npc:getPositionX(),npc:getPositionY()))
			local npcTiledX = math.modf(npcPos.x/npc.map_:getTileSize().width)
			local npcTiledY = math.modf(((npc.map_:getMapSize().height * npc.map_:getTileSize().height ) - npcPos.y) / npc.map_:getTileSize().height)
			local tiles = enemy:getCanReachTiles(cc.p(targetTiledX,targetTiledY))
			local minDuration = 0
			local targetPos
			for i,v in ipairs(tiles) do
				local lengX = npcTiledX - targetTiledX
				local lengY = npcTiledY - targetTiledY
				local durationScore = 0
				if npcdirect.DIRECTION_ == npcdirect.DIRECTION_LEFT and lengX < 0 then
					durationScore = durationScore + 1
				elseif npcdirect.DIRECTION_ == npcdirect.DIRECTION_RIGHT and lengX > 0 then
					durationScore = durationScore + 1
				elseif npcdirect.DIRECTION_ == npcdirect.DIRECTION_UP and lengY > 0 then
					durationScore = durationScore + 1
				elseif npcdirect.DIRECTION_ == npcdirect.DIRECTION_DOWN and lengY < 0 then
					durationScore = durationScore + 1
				end
				local d = math.abs(lengX) + math.abs(lengY) + durationScore

				if minDuration == 0 or minDuration > d then
					minDuration = d
					targetPos = cc.p(targetTiledX,targetTiledY)
				end
			end

			if not targetPos then
				npcSearchPath_(npc,targetPos)
				local movePoint = table.remove(npc.oribt_,1)
				if movePoint then
					local position = convertTilePositionToMapPosition(npc.map_,movePoint)
					if npc:getPositionX() ~= position.x or npc:getPositionY() ~= position.y then
						npc.enemy_ = enemy
						npc.state_ = npcstate.MOVE
						return npc:move(position)
					end
				end
				npc.state_ = npcstate.IDLE
				npc:stopAllActions()
				return genNpcIdleEvent(npc)
			end
		end
	end
	
	if npc.state_ == npcstate.IDLE then
		return genNpcIdleEvent(npc)
	elseif npc.state_ == npcstate.MOVE then
		--todo 是否有敌人
		local movePoint = table.remove(npc.oribt_,1)
		if movePoint then
			local position = convertTilePositionToMapPosition(npc.map_,movePoint)
			if npc:getPositionX() ~= position.x or npc:getPositionY() ~= position.y then
				return npc:move(position)
			end
		end
		npc.state_ = npcstate.IDLE
		npc:stopAllActions()
		return genNpcIdleEvent(npc)
	end
	return nil
end

function genNpcIdleEvent(npc)
	if npc.state_ == npcstate.IDLE then
		--空闲动画
		if math.random(1, 2) == 1 then
			npc:idle()
			return cca.delay(1)
		--随机移动到当前位置附近的任意位置
		else
			local npcStay = npc.map_:convertToNodeSpace(cc.p(npc:getPositionY(),npc:getPositionY()))
			local npcStayTiledX = math.modf(npcStay.x/npc.map_:getTileSize().width)
			local npcStayTiledY = math.modf(((npc.map_:getMapSize().height * npc.map_:getTileSize().height ) - npcStay.y) / npc.map_:getTileSize().height)
			local moveSteps = npc:getCanReachTiles(cc.p(npcStayTiledX,npcStayTiledY))
			local targetPos = moveSteps[math.random(1, table.getn(moveSteps))]
			npcSearchPath_(npc,targetPos)
			npc.state_ = npcstate.MOVE
			return getNpcNextAction(npc)
		end
	end
end

function searchEnemy(npc)
	local npcGLPosition = cc.p(npc:getPositionX(),npc:getPositionY())
	local x = npcGLPosition.x - (npc.map_:getTileSize().width * 3 + npc.map_:getTileSize().width/2)
	local y = npcGLPosition.y - (npc.map_:getTileSize().height * 3 + npc.map_:getTileSize().height/2)
	local shape = cc.rect(x, y, npc.map_:getTileSize().width * 7, npc.map_:getTileSize().height * 7)
	local childs = npc.map_:getChildByName("playerNode"):getChildren()
	local enemy
	local minDuration = 0
	for i,v in ipairs(childs) do
		if npc ~= v then
			if cc.rectContainsPoint(shape, cc.p(v:getPositionX(),v:getPositionY())) then
				if minDuration == 0 then
					return v
					-- todo 判断最近的怪物
				end
			end
		end
	end
	return nil
end

function convertTilePositionToMapPosition(map,tilePosition)
	local x = map:getTileSize().width * tilePosition.x + map:getTileSize().width/2
	local y = map:getMapSize().height * map:getTileSize().height - map:getTileSize().height * tilePosition.y - map:getTileSize().height / 2
	return cc.p(x,y)
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