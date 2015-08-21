local BehaviorBase = require("app.behaviors.BehaviorBase")
local MapConstants  = require("app.MapConstants")
local LifeBehavior = class("LifeBehavior",BehaviorBase)


LifeBehavior.LIFE_STATE_DEAD = 0
LifeBehavior.LIFE_STATE_LIVE = 1
LifeBehavior.LIFE_STATE_INJURED = 2

function LifeBehavior:ctor()
	LifeBehavior.super.ctor(self,"LifeBehavior",nil, 1)
end

function LifeBehavior:bind(object)
	self:reset(object)

	local function isLive(object)
		return object.lifeState_ == LifeBehavior.LIFE_STATE_LIVE
	end
	object:bindMethod(self, "isLive", isLive)

	local function getMaxHp(object)
        return object.maxHp_
    end
    object:bindMethod(self, "getMaxHp", getMaxHp)

    local function setMaxHp(object, maxHp)
        maxHp = checkint(maxHp)
        assert(maxHp > 0, string.format("LifeBehavior.setMaxHp() - invalid maxHp %s", tostring(maxHp)))
        object.maxHp_ = maxHp
    end
    object:bindMethod(self, "setMaxHp", setMaxHp)

    local function getHp(object)
        return object.hp_
    end
    object:bindMethod(self, "getHp", getHp)

    local function setHp(object, hp)
        hp = checknumber(hp)
        assert(hp >= 0 and hp <= object.maxHp_,
               string.format("LifeBehavior.setHp() - invalid hp %s", tostring(hp)))
        object.hp_ = hp
        object:checkLifeState()
    end
    object:bindMethod(self, "setHp", setHp)

    local function decreaseHp(object, amount)
        amount = checknumber(amount)
        assert(amount >= 0, string.format("DestroyedBehavior.decreaseHp() - invalid amount %s", tostring(amount)))
        object.hp_ = object.hp_ - amount
        if object.hp_ <= 0 then
            object.hp_ = 0
        end
        object:checkLifeState()
    end
    object:bindMethod(self, "decreaseHp", decreaseHp)

    local function increaseHp(object, amount)
        amount = checknumber(amount)
        assert(amount >= 0, string.format("DestroyedBehavior.increaseHp() - invalid amount %s", tostring(amount)))
        object.hp_ = object.hp_ + amount
        if object.hp_ >= object.maxHp_ then
            object.hp_ = object.maxHp_
        end
        object:checkLifeState()
    end
    object:bindMethod(self, "increaseHp", increaseHp)

    local function checkLifeState(object)
    	if object.preLifeState_ == object.lifeState_ then return end
    	if object.hp_ <= 0 then
    		if object.campId_ == PLAYER_CAMP then
    			object.lifeState_ = LifeBehavior.LIFE_STATE_INJURED
    			--TODO 发送XX受伤事件
    		elseif object.campId_ == PLAYER_CAMP then
    			object.lifeState_ = LifeBehavior.LIFE_STATE_DEAD
    			--TODO 发送XX死亡事件
    		end
        else
        	if object.campId_ == PLAYER_CAMP then
        		object.lifeState_ = LifeBehavior.LIFE_STATE_LIVE
        		--TODO 发送XX伤愈事件
        	end
        end
    end
    object:bindMethod(self, "checkLifeState", checkLifeState)

    local function createView(object, batch, marksLayer, debugLayer)
        object.hpOutlineSprite_ = display.newSprite(string.format("#ObjectHpOutline.png"))
        object.hpOutlineSprite_:align(display.LEFT_CENTER, 0, 0)
        batch:addChild(object.hpOutlineSprite_, MapConstants.HP_BAR_ZORDER)

        if object:getCampId() == MapConstants.PLAYER_CAMP then
            object.hpSprite_ = display.newSprite("#FriendlyHp.png")
        else
            object.hpSprite_ = display.newSprite("#EnemyHp.png")
        end
        object.hpSprite_:align(display.LEFT_CENTER, 0, 0)
        batch:addChild(object.hpSprite_, MapConstants.HP_BAR_ZORDER + 1)
    end
    object:bindMethod(self, "createView", createView)

    local function removeView(object)
        object.hpOutlineSprite_:removeSelf()
        object.hpOutlineSprite_ = nil
        object.hpSprite_:removeSelf()
        object.hpSprite_ = nil
    end
    object:bindMethod(self, "removeView", removeView, true)

    local function updateView(object)
        object.hp__ = object.hp_
        if object.hp_ > 0 then
            local x, y = object.x_, object.y_
            local x2 = x - object.hpOutlineSprite_:getContentSize().width/2
            -- local y2 = y + object.sprite_:getContentSize().height/2 + object.hpSpriteOffsetY_
            local y2 = y + object.hpSpriteOffsetY_
            -- print("x="..x .. ",y="..y.."x2="..x2.."y2="..y2)
            -- print("object.sprite_:getContentSize().height="..object.sprite_:getContentSize().height)
            object.hpSprite_:setPosition(x2, y2)
            object.hpSprite_:setScaleX(object.hp_ / object.maxHp_)
            object.hpOutlineSprite_:setPosition(x2, y2)
            object:setHpVisible(true)
        else
            object:setHpVisible(false)
        end
    end
    object:bindMethod(self, "updateView", updateView)

    local function fastUpdateView(object)
        if not object.updated__ and object.hp__ == object.hp_ then return end
        updateView(object)
    end
    object:bindMethod(self, "fastUpdateView", fastUpdateView)

    local function setHpVisible(object,visible)
    	object.hpSprite_:setVisible(visible)
        object.hpOutlineSprite_:setVisible(visible)
    end
    object:bindMethod(self, "setHpVisible", setHpVisible)
end

function LifeBehavior:unbind(object)
	object:unbindMethod(self, "isLive")
	object:unbindMethod(self, "getMaxHp")
	object:unbindMethod(self, "setMaxHp")
	object:unbindMethod(self, "getHp")
	object:unbindMethod(self, "setHp")
	object:unbindMethod(self, "decreaseHp")
	object:unbindMethod(self, "increaseHp")
	object:unbindMethod(self, "checkLifeState")
	object:unbindMethod(self, "createView")
	object:unbindMethod(self, "removeView")
	object:unbindMethod(self, "updateView")
	object:unbindMethod(self, "fastUpdateView")
	object:unbindMethod(self, "setHpVisible")

	
	self:reset(object)
end

function LifeBehavior:reset(object)
    object.hpSpriteOffsetY_ = checkint(object.state_.hpSpriteOffsetY)
    object.maxHp_      		= checkint(object.state_.maxHp)


    if object.maxHp_ < 1 then object.maxHp_ = 1 end
    object.hp_        = object.maxHp_
    object.lifeState_  = LifeBehavior.LIFE_STATE_LIVE
    object.preLifeState_  = LifeBehavior.LIFE_STATE_DEAD
    object.hp__       = nil
end

return LifeBehavior