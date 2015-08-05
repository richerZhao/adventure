function walk(npc)
	if npc.status_ ~= npcstatus.STATUS_MOVE then
		npc:stopAllActions()
	end
	local animation = display.newAnimation(npc.walkFrames_, 1/8)
	-- animation:setRestoreOriginalFrame(true)	--动画执行完成后还原到初始状态
	local action =cc.Animate:create(animation)   
	npc:runAction(cc.RepeatForever:create(action))  
end

function idle(npc)
	if npc.status_ ~= npcstatus.STATUS_IDLE then
		npc:stopAllActions()
	end
	local animation = display.newAnimation(npc.idleFrames_, 1/8)
	-- animation:setRestoreOriginalFrame(true)	--动画执行完成后还原到初始状态
	local action =cc.Animate:create(animation)   
	npc:runAction(cc.RepeatForever:create(action))  
end

function move(npc,position)
	local mapPoint = npc.map_:convertToNodeSpace(position)
	local selfPoint = npc.map_:convertToNodeSpace(cc.p(npc:getPositionX(),npc:getPositionY()))
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
	npc:setDirection(direction)
	walk(npc)
	return cca.moveTo(1,position.x,position.y)
end