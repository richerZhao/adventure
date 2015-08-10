-- import("app.components.searchpath")
function executeNpcAction(npc,action,callback)
	transition.execute(npc, action, {  
	    onComplete = function(npc)
		    callback(npc)
	    end,
	    time = 1,
	})  
end

--NPC AI

function nextNpcAction(npc)
	local action = getNpcNextAction(npc)
	if action then
		executeNpcAction(npc,action,nextNpcAction)
	end
end

function getNpcNextAction(npc)
	if npc.state_ == npcstate.IDLE then
		print("getNpcNextAction npcstate.IDLE")
		-- TODO 是否有可以接取的任务

		-- TODO 是否需要整修

		-- TODO 是否需要搜索范围内的怪物
		local action = getEnemyForNpc(npc)
		if action then
			return action
		end

		print("moveToMonsterArea")
		-- TODO 移动到刷怪区域
		return moveToMonsterArea(npc)
	elseif npc.state_ == npcstate.MOVE then
		--TODO 是否有可以领取的任务,有可以领取的任务,领取任务并且将状态置为EVENT

		--TODO 是否附近有怪物
		local action = getEnemyForNpc(npc)
		if action then
			return action
		end

		local movePoint = table.remove(npc.oribt_,1)
		if movePoint then
			local position = convertTilePositionToMapPosition(npc.map_,movePoint)
			if npc:getPositionX() ~= position.x or npc:getPositionY() ~= position.y then
				return move(npc,position)
			end
		end
		npc.state_ = npcstate.IDLE
		return getNpcNextAction(npc)
	elseif npc.state_ == npcstate.FIGHT then
		print("getNpcNextAction npcstate.FIGHT")
		local action = npc:attack()
		if action then
			if npc.enemy_ then
				if npc.enemy_.attr_.hp <= 0 then
					npc.enemy_:dead()
					npc.enemy_ = nil
					npc.state_ = npcstate.IDLE
					return getNpcNextAction(npc)
				end
			end
			return action
		else
			npc.state_ = npcstate.IDLE
			return getNpcNextAction(npc)
		end
		--TODO 判断怪物是否已经死亡,死亡后将状态设置为IDLE

		--TODO 判断怪物是否超出攻击范围,超出攻击范围将重新计算路径,再行攻击

		--TODO 判断当前状态决定下一个动作 攻击前摇 ==》攻击 ==》攻击后摇 
	elseif npc.state_ == npcstate.EVENT then
		--TODO 判断任务是否已经完成,完成后将状态设置为IDLE
	elseif npc.state_ == npcstate.MOVE_FIGHT then
		print("getNpcNextAction npcstate.MOVE_FIGHT")
		--TODO 判断怪物是否已经死亡,死亡后将状态设置为IDLE
		--TODO 判断与怪物的距离是否已经到了可以攻击的距离了
		local targetTiledX = math.modf(npc.enemy_:getPositionX()/npc.map_:getTileSize().width)
		local targetTiledY = math.modf(((npc.map_:getMapSize().height * npc.map_:getTileSize().height ) - npc.enemy_:getPositionY()) / npc.map_:getTileSize().height)
		local npcTiledX = math.modf(npc:getPositionX()/npc.map_:getTileSize().width)
		local npcTiledY = math.modf(((npc.map_:getMapSize().height * npc.map_:getTileSize().height ) - npc:getPositionY()) / npc.map_:getTileSize().height)
		if math.abs(npcTiledX - targetTiledX) + math.abs(npcTiledY - targetTiledY) <= npc.attr_.distance then
			npc.state_ = npcstate.FIGHT
			return getNpcNextAction(npc)
		else
			local tiles = getCanReachTiles(npc,convertMapPositionToTilePosition(npc.map_, cc.p(npc.enemy_:getPositionX(),npc.enemy_:getPositionY())))
			local minDuration = 0
			local targetPos
			for i,v in ipairs(tiles) do
				local lengX = npcTiledX - v.x
					local lengY = npcTiledY - v.y
					local d = math.abs(lengX) + math.abs(lengY)
					if minDuration == 0 or minDuration > d then
						minDuration = d
						targetPos = v
					end
			end
			npcSearchPath_(npc,targetPos)
		end
		--TODO 向目标移动
		local movePoint = table.remove(npc.oribt_,1)
		if movePoint then
			local position = convertTilePositionToMapPosition(npc.map_,movePoint)
			if npc:getPositionX() ~= position.x or npc:getPositionY() ~= position.y then
				return move(npc,position)
			end
		end
		--TODO 移动到终点以后将状态设置为FIGHT 
		npc.state_ = npcstate.FIGHT
		return getNpcNextAction(npc)
	elseif npc.state_ == npcstate.MOVE_EVENT then
		--TODO 判断任务是否已经完成,完成后将状态设置为IDLE
		--TODO 移动到终点以后将状态设置为EVENT
	elseif npc.state_ == npcstate.MOVE_IDLE then
		--TODO 判断是否全部整备完毕,整备完毕则判断是否有任务,有任务则将状态置为EVENT,否则将状态设置为IDLE
	end
	return nil
end

--怪物AI

function nextMonsterAction(monster)
	local action = getMonsterNextAction(monster)
	if action then
		executeNpcAction(monster,action,nextMonsterAction)
	end
end

function getMonsterNextAction(monster)
	if monster.state_ == npcstate.IDLE then
		-- TODO 是否有可以接取的任务

		-- TODO 是否需要整修

		-- TODO 是否需要搜索范围内的怪物
		local action = getEnemyForNpc(monster)
		if action then
			print("IDLE getEnemyForNpc")
			return action
		end

		print("moveInMonsterArea")
		-- TODO 随机移动到可移动的区域
		return moveInMonsterArea(monster)
	elseif monster.state_ == npcstate.MOVE then
		--TODO 是否附近有NPC
		local action = getEnemyForNpc(monster)
		if action then
			print("MOVE getEnemyForNpc")
			return action
		end
		print("movePoint")
		local movePoint = table.remove(monster.oribt_,1)
		if movePoint then
			local position = convertTilePositionToMapPosition(monster.map_,movePoint)
			if monster:getPositionX() ~= position.x or monster:getPositionY() ~= position.y then
				return move(monster,position)
			end
		end
		monster.state_ = npcstate.IDLE
		return getMonsterNextAction(monster)
	elseif monster.state_ == npcstate.FIGHT then
		print("getMonsterNextAction npcstate.FIGHT")
		--TODO 判断怪物是否已经死亡,死亡后将状态设置为IDLE

		--TODO 判断怪物是否超出攻击范围,超出攻击范围将重新计算路径,再行攻击

		--TODO 判断当前状态决定下一个动作 攻击前摇 ==》攻击 ==》攻击后摇 
	elseif monster.state_ == npcstate.MOVE_FIGHT then
		print("getMonsterNextAction npcstate.MOVE_FIGHT")
		--TODO 判断NPC是否已经死亡,死亡后将状态设置为IDLE
		--TODO 判断与NPC的距离是否已经到了可以攻击的距离了
		local targetTiledX = math.modf(monster.enemy_:getPositionX()/monster.map_:getTileSize().width)
		local targetTiledY = math.modf(((monster.map_:getMapSize().height * monster.map_:getTileSize().height ) - monster.enemy_:getPositionY()) / monster.map_:getTileSize().height)
		local npcTiledX = math.modf(monster:getPositionX()/monster.map_:getTileSize().width)
		local npcTiledY = math.modf(((monster.map_:getMapSize().height * monster.map_:getTileSize().height ) - monster:getPositionY()) / monster.map_:getTileSize().height)
		if math.abs(npcTiledX - targetTiledX) + math.abs(npcTiledY - targetTiledY) <= monster.attr_.distance then
			monster.state_ = npcstate.FIGHT
			return getMonsterNextAction(monster)
		else
			local tiles = getCanReachTiles(monster,convertMapPositionToTilePosition(monster.map_,cc.p(monster.enemy_:getPositionX(),monster.enemy_:getPositionY())))
			local minDuration = 0
			local targetPos
			for i,v in ipairs(tiles) do
				if canReachForMonster(monster,v) then
					local lengX = npcTiledX - v.x
					local lengY = npcTiledY - v.y
					local d = math.abs(lengX) + math.abs(lengY)
					if minDuration == 0 or minDuration > d then
						minDuration = d
						targetPos = v
					end
				end
			end
			npcSearchPath_(monster,targetPos)
		end
		--TODO 向目标移动
		local movePoint = table.remove(monster.oribt_,1)
		if movePoint then
			local position = convertTilePositionToMapPosition(monster.map_,movePoint)
			if monster:getPositionX() ~= position.x or monster:getPositionY() ~= position.y then
				return move(monster,position)
			end
		end
		--TODO 移动到终点以后将状态设置为FIGHT 
		monster.state_ = npcstate.FIGHT
		return getMonsterNextAction(monster)
	end
	return nil



end