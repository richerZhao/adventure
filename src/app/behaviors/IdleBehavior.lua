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
			object:setFlipSprite(true)
		elseif object.direction_ == MOVERIGHT then
			object:setFlipSprite(false)
		elseif object.direction_ == MOVEUP then
		end
		local idleAnimation = display.newAnimation(object.idleFrames_[object.direction_],1/4)
		object.idleAction_ = object.sprite_:playAnimationForever(idleAnimation)
	end
end

function IdleBehavior:bind(object)
	object.idleState_ 						= 0
	object.idleAction_				 		= nil	--攻击动作
	object.idleFrames_						= nil	--动画
	object.idleTime_						= 0		--空闲时间

	object.idleFrames_ = {}
	local idleFrames = display.newFrames(object.modelName_ .. "_stand_1_%02d.png",1,4)
    for i=1,4 do
    	table.insert(object.idleFrames_, idleFrames)
    end

    local function isIdle(object)
    	return object.idleState_ == IdleBehavior.IDLE_STATE_START
    end
    object:bindMethod(self, "isIdle", isIdle)

    local function startIdle(object)
    	object.idleState_ = IdleBehavior.IDLE_STATE_START
    	local idleAnimation = display.newAnimation(object.idleFrames_[object.direction_],1/4)
		object.idleAction_ = object.sprite_:playAnimationForever(idleAnimation)
    end
    object:bindMethod(self, "startIdle", startIdle)

    local function stopIdle(object)
    	object.idleState_ = IdleBehavior.IDLE_STATE_STOPED
    	if object.idleAction_ then
    		object.sprite_:stopAction(object.idleAction_)
    		object.idleAction_ = nil
    		object.idleTime_ = 0
    	end
    end
    object:bindMethod(self, "stopIdle", stopIdle)

    local function clearIdleTime(object)
    	object.idleTime_ = 0
    end
    object:bindMethod(self, "clearIdleTime", clearIdleTime)

    local function getIdleTime(object)
    	return object.idleTime_
    end
    object:bindMethod(self, "getIdleTime", getIdleTime)

    local function tick(object,dt)
    	if object.idleState_ == IdleBehavior.IDLE_STATE_START then 
    		object.idleTime_ = object.idleTime_ + dt
    	end
    end
    object:bindMethod(self, "tick", tick)

    self:reset(object)
end

function IdleBehavior:unbind(object)
	object.idleFrames_ = nil

	object:unbindMethod(self, "isIdle")
	object:unbindMethod(self, "startIdle")
	object:unbindMethod(self, "stopIdle")
	object:unbindMethod(self, "clearIdleTime")
	object:unbindMethod(self, "getIdleTime")
	object:unbindMethod(self, "tick")
end

function IdleBehavior:reset(object)
	object.idleState_ = IdleBehavior.IDLE_STATE_STOPED
	object.idleAction_	= nil
	object.idleTime_ = 0
end

return IdleBehavior