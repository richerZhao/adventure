local BehaviorBase = require("app.behaviors.BehaviorBase")
local AttackBehavior = class("AttackBehavior",BehaviorBase)

AttackBehavior.ATTACK_STATE_START = 0
AttackBehavior.ATTACK_STATE_ATTACKDURATION = 1
AttackBehavior.ATTACK_STATE_IDLE = 2
AttackBehavior.ATTACK_STATE_STOPED = 3


function AttackBehavior:ctor()
	AttackBehavior.super.ctor(self,"AttackBehavior",{"IdleBehavior","LifeBehavior"},2)
end

function AttackBehavior:onDirectionChange(object)
	if object:isAttacking() then
		if object.preDirection_ == object.direction_ then return end
		transition.removeAction(object.attackAction_)
		object.attackAction_ = nil
		if object.direction_ == MOVEDOWN then
		elseif object.direction_ == MOVELEFT then
			object:setFlipSprite(true)
		elseif object.direction_ == MOVERIGHT then
			object:setFlipSprite(false)
		elseif object.direction_ == MOVEUP then
		end
		local animation = display.newAnimation(object.attackFrames_[object.direction_],1/8)
    	object.attackAction_ = object.sprite_:playAnimationOnce(animation,false,function ()
    		--TODO 完成攻击后切换状态,空闲或者停止
    		object.attackState_ = AttackBehavior.ATTACK_STATE_IDLE
    		object.attackAction_ = nil
    		object:startIdle()
    	end)
	end
end

function AttackBehavior:bind(object)
	object.attackState_ 					= 0
	object.attackAction_				 	= nil	--攻击动作
	object.attackFrames_					= nil	--动画
	object.enemy_							= nil	--要攻击的敌人
	object.idleTime_						= 0		--攻击空闲时间
    object.attack_                          = checkint(object.state_.attack)     --攻击力
    object.defence_                         = checkint(object.state_.defence)     --防御力

	--初始化移动动作
	object.attackFrames_ = {}
	local fightFrames = display.newFrames(object.modelName_ .. "_dance_a_1_%02d.png",1,8)
	for i=1,4 do
    	table.insert(object.attackFrames_,fightFrames)
    end

    local function isAttacking(object)
    	return object.attackState_ ~= AttackBehavior.ATTACK_STATE_STOPED
    end
    object:bindMethod(self, "isAttacking", isAttacking)

    local function startAttack(object)
        print(object.id_ .. " startAttack")
    	object.attackState_ = AttackBehavior.ATTACK_STATE_START
    	-- local animation = display.newAnimation(object.attackFrames_[object.direction_],1/8)
    	-- object.attackAction_ = object.sprite_:playAnimationOnce(animation,false,function ()
    	-- 	--TODO 完成攻击后切换状态,空闲或者停止
    	-- 	object.attackState_ = AttackBehavior.ATTACK_STATE_IDLE
    	-- 	object.attackAction_ = nil
    	-- 	object:startIdle()
    	-- end)
    end
    object:bindMethod(self, "startAttack", startAttack)

    local function stopAttack(object)
        print(object.id_ .. " stopAttack")
    	object.attackState_ = AttackBehavior.ATTACK_STATE_STOPED
    	object.enemy_ = nil
    	object.idleTime_ = 0
    	if object.attackAction_ then 
    		transition.removeAction(object.attackAction_)
    		object.attackAction_ = nil
    	end
    end
    object:bindMethod(self, "stopAttack", stopAttack)

    local function setEnemy(object,enemy)
    	object.enemy_ = enemy
    end
    object:bindMethod(self, "setEnemy", setEnemy)

    -- local function tick(object,dt)
    -- 	if object.attackState_ ~= AttackBehavior.ATTACK_STATE_IDLE then return end
    -- 	object.idleTime_ = object.idleTime_ + dt
    -- 	if object.idleTime_ >= object.idleLastTime_ then
    -- 		object.idleTime_ = 0
    -- 		object:stopIdle()
    -- 		object:startAttack()
    --         local damage = object.attack_ - object.enemy_.defence_
    --         if damage > 0 then
    --             object.enemy_:decreaseHp(damage)
    --         end
    -- 	end
    -- end
    -- object:bindMethod(self, "tick", tick)

    self:reset(object)
end

function AttackBehavior:unbind(object)
	self:reset(object)
	object.attackFrames_ = nil

	object:unbindMethod(self, "isAttacking")
	object:unbindMethod(self, "startAttack")
	object:unbindMethod(self, "stopAttack")
	object:unbindMethod(self, "setEnemy")
	-- object:unbindMethod(self, "tick")
end

function AttackBehavior:reset(object)
	object.attackState_ = AttackBehavior.ATTACK_STATE_STOPED
    object.enemy_ = nil
    object.idleTime_ = 0
    object.attackAction_ = nil
    object.attack_                          = checkint(object.state_.attack)     --攻击力
    object.defence_                         = checkint(object.state_.defence)     --防御力
end

return AttackBehavior
