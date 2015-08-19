local BehaviorBase = require("app.behaviors.BehaviorBase")
local NpcBehavior = class("NpcBehavior",BehaviorBase)

function NpcBehavior:ctor()
	NpcBehavior.super.ctor(self,"NpcBehavior",{"AttackBehavior","MoveableBehavior","SearchPathBehavior"},3)
end

function NpcBehavior:bind(object)
	object.genAreaName_ = object.state_.genAreaName

	local function startRunAI(object)
		local p = object.map_:getNpcGenPoint(object.genAreaName_)
		object:setPosition(p.x,p.y)
		local target = object.map_:getMostMonsterAreaPoint()
		object:setPath(object:searchPath(target))
		object:startMove()
	end
	object:bindMethod(self, "startRunAI", startRunAI)

	local function tick(object,dt)
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





end

function NpcBehavior:unbind(object)
	object:unbindMethod(self, "tick")
	object:unbindMethod(self, "startRunAI")
end

function NpcBehavior:reset(object)

end

return NpcBehavior