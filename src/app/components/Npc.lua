-- import("app.components.ai")
local Npc = class("Npc",function (params)
	local frame = display.newSpriteFrame(params.textureName)
	return cc.Sprite:createWithSpriteFrame(frame)
end)

function Npc.create(params)
	local npc = Npc.new(params)
	return npc
end

function Npc:ctor(params)
	if params.scale then
		self:setScale(params.scale)
	end
	if params.flippedX then
		self:setFlippedX(true)
	end
	if params.speed then
		self.speed_ = params.speed
	else
		self.speed_ = 32
	end

	self.type_ = npctype.NPC
	self.openTable_ = {}
	self.closeTable_ = {}
	self.state_ = npcstate.IDLE
	self.status_ = npcstatus.IDLE
	self.oribt_ = {}
	self.event_ = nil
	self.enemy_ = nil
	self.attr_ = {
		hp = 100,
		attack = 10,
		magic = 0,
		defence = 2,
		dodge = 0,
		distance = 1,
	}
	self.direction_ = npcdirect.DIRECTION_RIGHT
	self:setFlippedX(true)

	self.walkFrames_ = display.newFrames(params.playerName.."_walk_1_%02d.png",1,8)
    self.idleFrames_ = display.newFrames(params.playerName.."_stand_1_%02d.png",1,4)
    self.fightFrames_ = display.newFrames(params.playerName.."_dance_a_1_%02d.png",1,8)
end

function Npc:runAI(map)
	self.map_ = map
	nextNpcAction(self)
end

--设置方向
function Npc:setDirection(direction)
	self.direction_ = direction
	if direction == npcdirect.DIRECTION_RIGHT then
		self:setFlippedX(true)
	elseif direction == npcdirect.DIRECTION_LEFT then
		self:setFlippedX(false)
	end
end

function Npc:attack()
	--敌人是否死亡,或者自己是否死亡
	local action
	if  not self.enemy_ or self.enemy_.attr_.hp <= 0 then
		self.enemy_ = nil
		return action 
	end
	if  not self.enemy_ or self.attr_.hp <= 0 then
		self.enemy_ = nil
		return action 
	end

	if self.state_ == npcstate.FIGHT and (self.status_ == npcstatus.IDLE or self.status_ == npcstatus.FIGHT_START  or self.status_ == npcstatus.FIGHT_MOVE) then
		fight(self)
		self.status_ = npcstatus.FIGHT_ACT
		action = cca.delay(1)
	elseif self.state_ == npcstate.FIGHT and self.status_ == npcstatus.FIGHT_ACT then
		--TODO 播放后摇
		idle(self)
		self.status_ = npcstatus.FIGHT_END
		action = cca.delay(1)
	elseif self.state_ == npcstate.FIGHT and self.status_ == npcstatus.FIGHT_END then
		--TODO 播放前摇
		self.status_ = npcstatus.FIGHT_START
		action = cca.delay(1)
	end
	self.enemy_.attr_.hp = self.enemy_.attr_.hp - (self.attr_.attack - self.attr_.defence)
	return action
end

return Npc