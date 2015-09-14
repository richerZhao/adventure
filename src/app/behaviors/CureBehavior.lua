local BehaviorBase = require("app.behaviors.BehaviorBase")
local MapEvent = require("app.MapEvent")
local LifeBehavior = require("app.behaviors.LifeBehavior")
local CureBehavior = class("CureBehavior",BehaviorBase)

function CureBehavior:ctor()
	CureBehavior.super.ctor(self,"CureBehavior",{"LifeBehavior"},2)
end

function CureBehavior:bind(object)
	object.cureAction_				 	= nil	--自愈动作
	object.cureFrames_					= nil	--动画
	object.cureTime_					= checkint(object.state_.cureTime)	--治愈时间

	--初始化自愈动作
	object.cureFrames_ = {}
	local cureFrames = display.newFrames(object.modelName_ .. "_dance_a_2_%02d.png",1,8)
	for i=1,4 do
    	table.insert(object.cureFrames_,cureFrames)
    end

    local function startCure(object)
        print(object.id_ .. " startCure")
    	local animation = display.newAnimation(object.cureFrames_[object.direction_],1/8)
    	object.cureAction_ = object.sprite_:playAnimationForever(animation)
    end
    object:bindMethod(self, "startCure", startCure)

    local function stopCure(object)
        print(object.id_ .. " stopCure")
    	if object.cureAction_ then 
    		transition.removeAction(object.cureAction_)
    		object.cureAction_ = nil
    	end
    end
    object:bindMethod(self, "stopCure", stopCure)

    local function tick(object,dt)
    	if not object:isInjured() then return end
    	local maxHp = object:getMaxHp()
    	local cureVal = maxHp/object.cureTime_ * dt
    	object:increaseHp(cureVal)
    end
    object:bindMethod(self, "tick", tick)

    local function addListener(object)
		--玩家被治愈
		g_eventManager:addEventListener(MapEvent.EVENT_NINJA_CURE,function(sender)
			sender.lifeState_ = LifeBehavior.LIFE_STATE_LIVE
			sender:stopCure()
			end,object)
	end
	object:bindMethod(self, "addListener", addListener)
    self:reset(object)
end

function CureBehavior:unbind(object)
	object:unbindMethod(self, "startCure")
	object:unbindMethod(self, "stopCure")
	object:unbindMethod(self, "tick")
	object:unbindMethod(self, "addListener")
end

function CureBehavior:reset(object)
	object.cureAction_ = nil
	object.cureTime_ = checkint(object.state_.cureTime)	--治愈时间
	if object.cureTime_ <= 0 then
		object.cureTime_ = 20
	end
end

return CureBehavior