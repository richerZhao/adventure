local BehaviorBase = require("app.behaviors.BehaviorBase")
local MapEvent = require("app.MapEvent")
local MonsterBehavior = class("MonsterBehavior",BehaviorBase)

MonsterBehavior.AI_STATE_STOP	= 0
MonsterBehavior.AI_STATE_RUN	= 1

function MonsterBehavior:ctor()
	MonsterBehavior.super.ctor(self,"MonsterBehavior",{"AttackBehavior","MoveableBehavior","SearchPathBehavior"},3)
end

function MonsterBehavior:bind(object)
	object.genPoint_ = nil
	object.aiState_  =  MonsterBehavior.AI_STATE_STOP
	object.activityRange = {}
	object.areaName_ = nil

	local function isAIRun(object)
		return object.aiState_ == MonsterBehavior.AI_STATE_RUN
	end
	object:bindMethod(self, "isAIRun", isAIRun)

	local function startRunAI(object)
		object.aiState_ = MonsterBehavior.AI_STATE_RUN
		local p,areaName = object.map_:getLessMonsterAreaPoint_()
		object.genPoint_ = p
		object.areaName_ = areaName
		object:setPosition(object.map_:convertTileToMapPosition(p))
		for i=p.x-3,p.x+3 do
			for k=p.y-3,p.y+3 do
				if object.map_:canReach_(cc.p(i,k)) then
					table.insert(object.activityRange,cc.p(i,k))
				end
			end
		end
		

		local target = object.activityRange[math.random(#object.activityRange)]
		while target.x == object.genPoint_.x and target.y == object.genPoint_.y do
			target = object.activityRange[math.random(#object.activityRange)]
		end
		object:setPath(object:searchPath(cc.p(object.map_:convertTileToMapPosition(target))))
		print(object.id_.." start move0")
		object:startMove()
		object.map_:addMonster(object.areaName_)
	end
	object:bindMethod(self, "startRunAI", startRunAI)

	local function stopRunAI(object)
		object.aiState_ = MonsterBehavior.AI_STATE_STOP
	end
	object:bindMethod(self, "stopRunAI", stopRunAI)

	local function tick(object,dt)
		if not object.play_ or not object:isAIRun() then return end
		if object:isAttacking() then
			return
		end
		-- 附近是否有敌人
		if not object:isMoving() then 
			if object.enemy_ then
				object:stopAllAIActions()
				local enemyPath = object:searchPath(cc.p(object.enemy_:getPosition()))
				print(object.id_.." start move1")
				object:setPath({enemyPath[1]})
				object:startMove()
				return
			end

			if not object:isIdle() then
				object:startIdle()
			end
		end

		if object:isIdle() then
			if object:getIdleTime() >= 1 then
				object:clearIdleTime()
				object:stopIdle()
				local target
				local paths
				while not paths do
					target = object.activityRange[math.random(#object.activityRange)]
					while target.x == object.genPoint_.x and target.y == object.genPoint_.y do
						target = object.activityRange[math.random(#object.activityRange)]
					end
					paths = object:searchPath(cc.p(object.map_:convertTileToMapPosition(target)))
				end
				object:setPath(paths)
				print(object.id_.." start move2")
				object:startMove()
			end
		end

		-- TODO 附近是否有受伤的同伴
		-- TODO 是否到达目的地
	end
	object:bindMethod(self, "tick", tick)
	local function addListener(object)
		--注册进入仇恨区事件
		g_eventManager:addEventListener(MapEvent.OBJECT_IN_HATRED_RANGE,function(sender,target)
			if sender.moveLocked_ > 0 or sender.fightLocked_ > 0 then
				return
			end
			print("enemy "..target.id_ .. " enter object " .. sender.id_ .. " hatred range")
			sender:addMoveLock()
			sender:setEnemy(target)
			sender:stopAllAIActions()
			local enemyPath = sender:searchPath(cc.p(target:getPosition()))
			sender:setPath({enemyPath[1]})
			print(object.id_.." start move3")
			sender:startMove()
			end,object)
		--注册进入可攻击范围事件
		g_eventManager:addEventListener(MapEvent.OBJECT_IN_ATTACK_RANGE,function(sender,target)
			if sender.fightLocked_ > 0 then
				return
			end
			sender:removeMoveLock()
			sender:addAttackLock()
			print("enemy "..target.id_ .. " enter object " .. sender.id_ .. " attack range")
			sender:stopAllAIActions()
			sender:startAttack()
			end,object)
	end
	object:bindMethod(self, "addListener", addListener)

	local function stopAllAIActions(object)
		print(object.id_ .. " stopAllAIActions")
		if object:isAttacking() then
			object:stopAttack()
		end

		if object:isIdle() then
			object:stopIdle()
		end

		if object:isMoving() then
			object:stopMove()
		end
	end
	object:bindMethod(self, "stopAllAIActions", stopAllAIActions)

	local function showDestroyedStatus(object,skipAnim)
        if skipAnim then
            object:getView():setVisible(false)
            object:destroyed()
        else
            transition.execute(object:getView(), cca.fadeOut(1), {  
                onComplete = function()
                    object:destroyed()
                end,
                time = 1,
            })  
        end
    end
    object:bindMethod(self, "showDestroyedStatus", showDestroyedStatus)
	self:reset(object)
end

function MonsterBehavior:unbind(object)
	object:unbindMethod(self, "isAIRun")
	object:unbindMethod(self, "startRunAI")
	object:unbindMethod(self, "stopRunAI")
	object:unbindMethod(self, "tick")
	object:unbindMethod(self, "addListener")
	object:unbindMethod(self, "stopAllAIActions")
	object:unbindMethod(self, "showDestroyedStatus")
end

function MonsterBehavior:reset(object)
	object.genPoint_ = nil
	object.aiState_  =  MonsterBehavior.AI_STATE_STOP
	object.activityRange = {}
end

return MonsterBehavior