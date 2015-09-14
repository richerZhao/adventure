local MapEventHandler = require("app.MapEventHandler")
local MapEvent = require("app.MapEvent")
local AttackBehavior = require("app.behaviors.AttackBehavior")
local FightEventHandler = class("FightEventHandler",MapEventHandler)


function FightEventHandler:ctor(runtime,map)
	FightEventHandler.super.ctor(self,runtime,map)
end

function FightEventHandler:addListener()
	--监听怪物被消灭事件
	g_eventManager:addEventListener(MapEvent.EVENT_MONSTER_DEAD,function(sender,attacker,target)
		print("attacker ".. attacker.id_.." kill monster ".. target.id_)
		target:stopAllAIActions()
		target:showDestroyedStatus(false)
			end,self)

	--监听忍者对怪物造成的伤害
	g_eventManager:addEventListener(MapEvent.EVENT_NINJA_TRUEDAMAGE,function(sender,attacker,target,damage)
		print("attacker ".. attacker.id_.." hit enemy ".. target.id_ .. " " .. damage .. " damage")

			end,self)

	--监听NPC受伤事件
	g_eventManager:addEventListener(MapEvent.EVENT_NINJA_HURT,function(sender,attacker,target)
		print("attacker ".. attacker.id_.." kill monster ".. target.id_)
		target:stopAllAIActions()
		target:removeAttackLock()
		target:startCure()
			end,self)
end

-- 轮询
function FightEventHandler:tick(dt)
	for id, object in pairs(self.map_:getAllObjects()) do
		if object:hasBehavior("AttackBehavior") then
			if object:isAttacking() then
				if not object.enemy_ or not object.enemy_:isLive() then
					--停止攻击
					object:stopAttack()
				else
					if object.attackState_ == AttackBehavior.ATTACK_STATE_START then
						local animation = display.newAnimation(object.attackFrames_[object.direction_],1/8)
				    	object.attackAction_ = object.sprite_:playAnimationOnce(animation,false,function ()
				    		local damage = object.attack_ - object.enemy_.defence_
				            local trueDamage
				            if damage > 0 then
				                trueDamage = object.enemy_:decreaseHp(damage)
				                --对敌人造成了真实伤害并且敌人死亡
				                g_eventManager:dispatchEvent(MapEvent.EVENT_NINJA_TRUEDAMAGE, self, object,object.enemy_,trueDamage)
				                if trueDamage > 0 then
				                	--TODO 记录伤害值(用于计算努力程度)
				                	if not object.enemy_:isLive() then
				                		if object:getCampId() == PLAYER_CAMP then
				                			--TODO 发送XX击杀了XXmonster
				                			g_eventManager:dispatchEvent(MapEvent.EVENT_MONSTER_DEAD, self, object,object.enemy_)
				                			object:removeAttackLock()
				                			object.enemy_:removeAttackLock()
				                		elseif object:getCampId() == MONSTER_CAMP then
				                			g_eventManager:dispatchEvent(MapEvent.EVENT_NINJA_HURT, self, object,object.enemy_)
				                			object:removeAttackLock()
				                		end
				                		print("object ".. object.id_ .. " kill enemy " .. object.enemy_.id_)
				                		object:stopAttack()
				                		return
				                	end
				                end
				            end
				    		--完成攻击后切换状态,空闲或者停止
				    		-- object:stopAttack()
				    		object.attackState_ = AttackBehavior.ATTACK_STATE_IDLE
				    		object.attackAction_ = nil
				    		object:startIdle()
			    		end)
				    	--切换攻击状态到攻击间隔
				    	object.attackState_ = AttackBehavior.ATTACK_STATE_ATTACKDURATION
				    elseif object.attackState_ == AttackBehavior.ATTACK_STATE_IDLE then
				    	object.idleTime_ = object.idleTime_ + dt
				    	if object.idleTime_ >= object.idleLastTime_ then
				    		object.idleTime_ = 0
				    		object:stopIdle()
				    		object:startAttack()
				    	end
					end
				end
			end
		end
    end
end

return FightEventHandler
