local BehaviorBase = require("app.behaviors.BehaviorBase")
local MonsterBehavior = class("MonsterBehavior",BehaviorBase)

function MonsterBehavior:ctor()
	MonsterBehavior.super.ctor(self,"MonsterBehavior",{"AttackBehavior","MoveableBehavior","SearchPathBehavior"},3)
end

function MonsterBehavior:bind()
end

function MonsterBehavior:unbind()
end

function MonsterBehavior:reset()
end

return MonsterBehavior