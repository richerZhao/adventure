local MapEventHandler = require("app.MapEventHandler")
local MapEvent = require("app.MapEvent")
local NinjaEvnetHandler = class("NinjaEvnetHandler",MapEventHandler)
function NinjaEvnetHandler:ctor(runtime,map)
	NinjaEvnetHandler.super.ctor(self,runtime,map)
end

function NinjaEvnetHandler:addListener()
	--监听怪物被消灭事件
	g_eventManager:addEventListener(MapEvent.EVENT_MONSTER_DEAD,function(sender,attacker,target)

			end,object)

	--监听忍者对怪物造成的伤害
	g_eventManager:addEventListener(MapEvent.EVENT_NINJA_TRUEDAMAGE,function(sender,attacker,target,damage)


			end,object)
end

-- 准备开始游戏
function NinjaEvnetHandler:preparePlay()
end

-- 开始游戏
function NinjaEvnetHandler:startPlay()
     self:addListener()
end

-- 停止游戏
function NinjaEvnetHandler:stopPlay()
    g_eventManager:removeListenerWithTarget(self)
end

-- 敌人死亡
function NinjaEvnetHandler:enemyDead()

end

-- 轮询
function NinjaEvnetHandler:tick(dt)
	for id, object in pairs(self.map_:getAllObjects()) do
		if object:hasBehavior("AttackBehavior") then
			if object:isAttacking() then
				if not object.enemy_:isLive() then
					--停止攻击
					object:stopAttack()
				else
					if object.attackState_ == AttackBehavior.ATTACK_STATE_START then
						local animation = display.newAnimation(object.attackFrames_[object.direction_],1/8)
				    		object.attackAction_ = object.sprite_:playAnimationOnce(animation,false,function ()
				    		--TODO 完成攻击后切换状态,空闲或者停止
				    		object.attackState_ = AttackBehavior.ATTACK_STATE_IDLE
				    		object.attackAction_ = nil
				    		object:startIdle()
			    		end)
				    elseif object.attackState_ == AttackBehavior.ATTACK_STATE_IDLE then
				    	object.idleTime_ = object.idleTime_ + dt
				    	if object.idleTime_ >= object.idleLastTime_ then
				    		object.idleTime_ = 0
				    		object:stopIdle()
				    		object:startAttack()
				            local damage = object.attack_ - object.enemy_.defence_
				            local trueDamage
				            if damage > 0 then
				                trueDamage = object.enemy_:decreaseHp(damage)
				                --对敌人造成了真实伤害并且敌人死亡
				                if trueDamage > 0 then
				                	--TODO 记录伤害值(用于计算努力程度)
				                	if not object.enemy_:isLive() then
				                		if object:getCampId() == PLAYER_CAMP then
				                			--TODO 发送XX击杀了XXmonster
				                		end
				                		object:stopAttack()
				                	end
				                end
				            end
				    	end
					end
				end
			end
		end
    end
end


return NinjaEvnetHandler