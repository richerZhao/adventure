local BehaviorBase = require("app.behaviors.BehaviorBase")
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

	local function isAIRun(object)
		return object.aiState_ == MonsterBehavior.AI_STATE_RUN
	end
	object:bindMethod(self, "isAIRun", isAIRun)

	local function startRunAI(object)
		object.aiState_ = MonsterBehavior.AI_STATE_RUN
		local p = object.map_:getMostMonsterAreaPoint_()
		object.genPoint_ = p
		object:setPosition(object.map_:convertTileToMapPosition(p))
		for i=p.x-3,p.x+3 do
			for k=p.y-3,p.y+3 do
				if object.map_:canReach_(cc.p(i,k)) then
					table.insert(object.activityRange,cc.p(i,k))
				end
			end
		end
		
		local target = object.activityRange[math.random(#object.activityRange)]
		object:setPath(object:searchPath(cc.p(object.map_:convertTileToMapPosition(target))))
		object:startMove()
	end
	object:bindMethod(self, "startRunAI", startRunAI)

	local function stopRunAI(object)
		object.aiState_ = MonsterBehavior.AI_STATE_STOP
	end
	object:bindMethod(self, "stopRunAI", stopRunAI)

	local function tick(object,dt)
		if not object.play_ or not object:isAIRun() then return end
		-- TODO 附近是否有敌人
		if not object:isMoving() then 
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
					paths = object:searchPath(cc.p(object.map_:convertTileToMapPosition(target)))
				end
				object:setPath(paths)
				object:startMove()
			end
		end

		-- TODO 附近是否有受伤的同伴
		-- TODO 是否到达目的地
	end
	object:bindMethod(self, "tick", tick)
	self:reset(object)
end

function MonsterBehavior:unbind(object)
end

function MonsterBehavior:reset(object)
	object.genPoint_ = nil
	object.aiState_  =  MonsterBehavior.AI_STATE_STOP
	object.activityRange = {}
end

return MonsterBehavior