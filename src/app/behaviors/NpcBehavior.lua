local BehaviorBase = require("app.behaviors.BehaviorBase")
local MapEvent = require("app.MapEvent")
local NpcBehavior = class("NpcBehavior",BehaviorBase)

NpcBehavior.AI_STATE_STOP = 0
NpcBehavior.AI_STATE_RUN = 1

function NpcBehavior:ctor()
	NpcBehavior.super.ctor(self,"NpcBehavior",{"AttackBehavior","MoveableBehavior","SearchPathBehavior","CureBehavior"},3)
end

function NpcBehavior:bind(object)

	object.genAreaName_ = object.state_.genAreaName
	object.aiState_ =  NpcBehavior.AI_STATE_STOP

	local function isAIRun(object)
		return object.aiState_ == NpcBehavior.AI_STATE_RUN
	end
	object:bindMethod(self, "isAIRun", isAIRun)

	local function startRunAI(object)
		object.aiState_ = NpcBehavior.AI_STATE_RUN
		local p = object.map_:getNpcGenPoint(object.genAreaName_)
		object:setPosition(p.x,p.y)
		local target = object.map_:getMostMonsterAreaPoint()
		object:setPath(object:searchPath(target))
		object:startMove()
		object.map_:addNpc()
	end
	object:bindMethod(self, "startRunAI", startRunAI)

	local function stopRunAI(object)
		object.aiState_ = NpcBehavior.AI_STATE_STOP
	end
	object:bindMethod(self, "stopRunAI", stopRunAI)

	local function tick(object,dt)
		if not object.play_ or not object:isAIRun() then return end
		if object:isAttacking() then
			return
		end

		if object:isInjured() then
			return
		end

		-- 附近是否有敌人
		if not object:isMoving() then 
			if object.enemy_ then
				object:setPath(object:searchPath(cc.p(object.enemy_:getPosition())))
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
					target = object.map_:getMostMonsterAreaPoint()
					paths = object:searchPath(target)
				end
				object:setPath(paths)
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
			sender:addMoveLock()
			print("enemy "..target.id_ .. " enter object " .. sender.id_ .. " hatred range")
			sender:stopAllAIActions()
			sender:setEnemy(target)
			sender:setPath(sender:searchPath(cc.p(target:getPosition())))
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
            object:
            callback(object)
        else
            transition.execute(object:getView(), cca.fadeOut(1), {  
                onComplete = function(object)
                    callback(object)
                end,
                time = 1,
            })  
        end
    end
    object:bindMethod(self, "showDestroyedStatus", showDestroyedStatus)
	self:reset(object)
end

function NpcBehavior:unbind(object)
	object:unbindMethod(self, "isAIRun")
	object:unbindMethod(self, "tick")
	object:unbindMethod(self, "startRunAI")
	object:unbindMethod(self, "stopRunAI")
	object:unbindMethod(self, "addListener")
	object:unbindMethod(self, "stopAllAIActions")
	object:unbindMethod(self, "showDestroyedStatus")
end

function NpcBehavior:reset(object)
	object.genAreaName_ = object.state_.genAreaName
	object.aiState_ =  NpcBehavior.AI_STATE_STOP
end

return NpcBehavior