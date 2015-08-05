import("app.components.searchpath")
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
		print("IDLE")
		-- TODO 是否有可以接取的任务

		-- TODO 是否需要整修

		-- TODO 是否需要搜索范围内的怪物
		local action = getEnemy(npc)
		if action then
			return action
		end
		print("getEnemy")

		-- TODO 移动到刷怪区域
		return moveToMonsterPoint(npc)
	elseif npc.state_ == npcstate.MOVE then
		print("MOVE")
		--TODO 是否有可以领取的任务,有可以领取的任务,领取任务并且将状态置为EVENT

		--TODO 是否附近有怪物
		local action = getEnemy(npc)
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
		--TODO 判断怪物是否已经死亡,死亡后将状态设置为IDLE

		--TODO 判断怪物是否超出攻击范围,超出攻击范围将重新计算路径,再行攻击

		--TODO 判断当前状态决定下一个动作 攻击前摇 ==》攻击 ==》攻击后摇 
	elseif npc.state_ == npcstate.EVENT then
		--TODO 判断任务是否已经完成,完成后将状态设置为IDLE
	elseif npc.state_ == npcstate.MOVE_FIGHT then
		--TODO 判断怪物是否已经死亡,死亡后将状态设置为IDLE
		--TODO 向目标移动
		--TODO 移动到终点以后将状态设置为FIGHT 
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
	local action = getMonsterNextAction(npc)
	if action then
		executeNpcAction(npc,action,nextMonsterAction)
	end
end

function getMonsterNextAction(monster)
	if monster.state_ == npcstate.IDLE then
		print("IDLE")
		-- TODO 是否有可以接取的任务

		-- TODO 是否需要整修

		-- TODO 是否需要搜索范围内的怪物
		local action = getEnemy(monster)
		if action then
			return action
		end
		print("getEnemy")

		-- TODO 随机移动到可移动的区域
		return moveToMonsterPoint(monster)
	elseif monster.state_ == npcstate.MOVE then
		print("MOVE")
		--TODO 是否有可以领取的任务,有可以领取的任务,领取任务并且将状态置为EVENT

		--TODO 是否附近有怪物
		local action = getEnemy(monster)
		if action then
			return action
		end

		local movePoint = table.remove(monster.oribt_,1)
		if movePoint then
			local position = convertTilePositionToMapPosition(monster.map_,movePoint)
			if monster:getPositionX() ~= position.x or monster:getPositionY() ~= position.y then
				return move(monster,position)
			end
		end
		monster.state_ = npcstate.IDLE
		return getNpcNextAction(monster)
	elseif monster.state_ == npcstate.FIGHT then
		--TODO 判断怪物是否已经死亡,死亡后将状态设置为IDLE

		--TODO 判断怪物是否超出攻击范围,超出攻击范围将重新计算路径,再行攻击

		--TODO 判断当前状态决定下一个动作 攻击前摇 ==》攻击 ==》攻击后摇 
	elseif monster.state_ == npcstate.MOVE_FIGHT then
		--TODO 判断怪物是否已经死亡,死亡后将状态设置为IDLE
		--TODO 向目标移动
		--TODO 移动到终点以后将状态设置为FIGHT 
	end
	return nil



end