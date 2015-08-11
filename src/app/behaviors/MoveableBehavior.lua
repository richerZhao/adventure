local BehaviorBase = require("app.behaviors.BehaviorBase")
local MoveableBehavior = class("MoveableBehavior", BehaviorBase)

function MoveableBehavior:ctor()
	MoveableBehavior.super.ctor(self,"MoveableBehavior",nil,1)
end

function MoveableBehavior:bind(object)
	
	
end

function MoveableBehavior:unbind(object)

end

function MoveableBehavior:reset(object)

end





return MoveableBehavior