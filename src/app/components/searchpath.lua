import("app.components.constant")
import("app.components.commonaction")
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
	dump(selfNode, "selfNode", selfNode)
	--检查终点是否可以到达
	if not canReach(npc,targetNode) then
		return
	end
	table.insert(npc.openTable_, {x=selfTiledX,y=selfTiledY,g=0,h=0,f=0})
	local currentNode = table.remove(npc.openTable_,1)
	table.insert(npc.closeTable_, currentNode)
	local canReachTiles = getCanReachTiles(npc,currentNode)
	-- dump(canReachTiles, "canReachTiles", canReachTiles)
	for i,v in ipairs(canReachTiles) do
		v.parent = currentNode
		v.g = v.parent.g + getGScore()
		v.h = getHScore(currentNode, targetNode)
		inserIntoOpenTable(npc,v,targetNode)
	end

	while not (targetNode.x == currentNode.x and targetNode.y == currentNode.y) do
		if not isInCloseTable(npc,currentNode) then
			--更新OPENTABLE的FScore
			canReachTiles = getCanReachTiles(npc,currentNode)
			for i,v in ipairs(canReachTiles) do
				local index = getIndexFromOpenTable(npc,v)
				if index then
					if npc.openTable_[index].g > currentNode.g + getGScore() then
						--替换
						table.remove(npc.openTable_,index)
						inserIntoOpenTable(npc,currentNode,targetNode)
					end
				else
					v.parent = currentNode
					v.g = v.parent.g + getGScore()
					v.h = getHScore(currentNode, targetNode)
					inserIntoOpenTable(npc,v,targetNode)
				end
			end
			table.insert(npc.closeTable_, currentNode)
		end
		currentNode = table.remove(npc.openTable_,1)
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

function moveToMonsterPoint(npc)
	local areaIndex = math.random(table.getn(npc.map_.monsterGenerateAreas_))
	local tileIndex = math.random(table.getn(npc.map_.monsterGenerateAreas_[areaIndex].tiles))
	npcSearchPath_(npc,npc.map_.monsterGenerateAreas_[areaIndex].tiles[tileIndex])
	npc.state_ = npcstate.MOVE
	return getNpcNextAction(npc)
end

function getEnemy(npc)
	if not npc.enemy_ then
		local enemy = searchEnemy(npc)
		if enemy then
			local target = npc.map_:convertToNodeSpace(cc.p(enemy:getPositionX(),enemy:getPositionY()))
			local targetTiledX = math.modf(target.x/npc.map_:getTileSize().width)
			local targetTiledY = math.modf(((npc.map_:getMapSize().height * npc.map_:getTileSize().height ) - target.y) / npc.map_:getTileSize().height)
			local npcPos = npc.map_:convertToNodeSpace(cc.p(npc:getPositionX(),npc:getPositionY()))
			local npcTiledX = math.modf(npcPos.x/npc.map_:getTileSize().width)
			local npcTiledY = math.modf(((npc.map_:getMapSize().height * npc.map_:getTileSize().height ) - npcPos.y) / npc.map_:getTileSize().height)
			local tiles = getCanReachTiles(enemy,cc.p(targetTiledX,targetTiledY))
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
				if targetPos.x == npcTiledX and targetPos.y == npcTiledY then
					return nil
				end
				npcSearchPath_(npc,targetPos)
				local movePoint = table.remove(npc.oribt_,1)
				if movePoint then
					local position = convertTilePositionToMapPosition(npc.map_,movePoint)
					if npc:getPositionX() ~= position.x or npc:getPositionY() ~= position.y then
						npc.enemy_ = enemy
						npc.state_ = npcstate.MOVE_FIGHT
						return move(npc,position)
					end
				end
			end
		end
	end
	return nil
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

function canReach(npc,tmpPos)
	local gid = npc.map_:getLayer("obstacleLayer"):getTileGIDAt(cc.p(tmpPos.x,tmpPos.y))
	if not gid then
		return false
	end
	if gid > 0 then
		local propertites = npc.map_:getPropertiesForGID(gid)
		if propertites.canMoveOn == "0" then
			return false
		end
	end
	return true
end

function getCanReachTiles(npc,tmpPos)
	local maxX = npc.map_:getMapSize().width - 1
	local maxY = npc.map_:getMapSize().height - 1
	local tiles = {}
	if tmpPos.x + 1 <= maxX then
		--右边
		if canReach(npc,{x=tmpPos.x + 1, y=tmpPos.y}) then
			table.insert(tiles, {x=tmpPos.x + 1, y=tmpPos.y})
		end
	end
	
	if tmpPos.x - 1 >= 0 then
		--左边
		if canReach(npc,{x=tmpPos.x - 1, y=tmpPos.y}) then
			table.insert(tiles, {x=tmpPos.x - 1, y=tmpPos.y})
		end
	end

	if tmpPos.y - 1 >= 0 then
		--上边
		if canReach(npc,{x=tmpPos.x, y=tmpPos.y - 1}) then
			table.insert(tiles, {x=tmpPos.x, y=tmpPos.y - 1})
		end
	end

	if tmpPos.y + 1 <= maxY then
		--下边
		if canReach(npc,{x=tmpPos.x, y=tmpPos.y + 1}) then
			table.insert(tiles, {x=tmpPos.x, y=tmpPos.y + 1})
		end
	end
	return tiles
end

function inserIntoOpenTable(npc,currentNode,targetNode)
	local currentFScore = getFScore(currentNode,targetNode)
	for i,v in ipairs(npc.openTable_) do
		local nextFScore = getFScore(v,targetNode)
		if currentFScore < nextFScore then
			table.insert(npc.openTable_, i,currentNode)
			return
		end
	end
	table.insert(npc.openTable_,currentNode)
end

function isInCloseTable( npc,currentNode )
	for i,v in ipairs(npc.closeTable_) do
		if currentNode.x == v.x and currentNode.y == v.y then
			return true
		end
	end
	return false
end

function getIndexFromOpenTable(npc,currentNode )
	for i,v in ipairs(npc.openTable_) do
		if currentNode.x == v.x and currentNode.y == v.y then
			return i
		end
	end
	return nil
end