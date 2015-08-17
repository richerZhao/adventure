local BehaviorBase = require("app.behaviors.BehaviorBase")
local IdleBehavior = class("IdleBehavior",BehaviorBase)

IdleBehavior.IDLE_STATE_START = 0
IdleBehavior.IDLE_STATE_STOPED = 1


function IdleBehavior:ctor()
	IdleBehavior.super.ctor(self,"AttackBehavior",nil,1)
end

function IdleBehavior:onDirectionChange(object)
	if object:isIdle() then
		if object.preDirection_ == object.direction_ then return end
		transition.removeAction(object.idleAction_)
		object.idleAction_ = nil
		if object.direction_ == MOVEDOWN then
		elseif object.direction_ == MOVELEFT then
			object.sprite_:setFlippedX(true)
		elseif object.direction_ == MOVERIGHT then
			object.sprite_:setFlippedX(false)
		elseif object.direction_ == MOVEUP then
		end
		object.idleAction_ = object.sprite_:playAnimationForever(object.idleAnimations_[object.direction_])
	end
end

function IdleBehavior:bind(object)
	object.idleState_ 						= 0
	object.idleAction_				 		= nil	--攻击动作
	object.idleAnimations_					= nil	--动画

	object.idleAnimations_ = {}
	local idleFrames = display.newFrames(object.modelName_ .. "_stand_1_%02d.png",1,4)
    local idleAnimation = display.newAnimation(idleFrames,1/4)
    for i=1,4 do
    	idleAnimation:retain()
    	table.insert(object.idleAnimations_, idleAnimation)
    end

    local function isIdle(object)
    	return object.idleState_ == IdleBehavior.IDLE_STATE_START
    end
    object:bindMethod(self, "isIdle", isIdle)

    local function startIdle(object)
    	print("startIdle")
    	object.idleState_ = IdleBehavior.IDLE_STATE_START
    	object.idleAction_ = object.sprite_:playAnimationForever(object.idleAnimations_[object.direction_])
    end
    object:bindMethod(self, "startIdle", startIdle)

    local function stopIdle(object)
    	print("stopIdle")
    	object.idleState_ = IdleBehavior.IDLE_STATE_STOPED
    	if object.idleAction_ then
    		transition.removeAction(action)
    		object.idleAction_ = nil
    	end
    end
    object:bindMethod(self, "stopIdle", stopIdle)

    self:reset(object)
end

function IdleBehavior:unbind(object)
	for i,v in ipairs(object.idleAnimations_) do
		v:release()
	end
	object.idleAnimations_ = nil

	object:unbindMethod(self, "isIdle")
	object:unbindMethod(self, "startIdle")
	object:unbindMethod(self, "stopIdle")
end

function IdleBehavior:reset(object)
	object.idleState_ = IdleBehavior.IDLE_STATE_STOPED
	object.idleAction_	= nil
end

return IdleBehavior