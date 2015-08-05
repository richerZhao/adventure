local Monster = class("Monster",function (params)
	local frame = display.newSpriteFrame(params.textureName)
	return cc.Sprite:createWithSpriteFrame(frame)
end)

function Monster.create(params)
	local monster = Monster.new(params)
	return monster
end

function Monster:ctor( params )
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

	self.type_ = npctype.MONSTER
	self.openTable_ = {}
	self.closeTable_ = {}
	self.state_ = npcstate.IDLE
	self.oribt_ = {}
	self.canReachTiles = {}	--怪物只能在出生地附近X范围内游荡
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
    self.fightFrames_ = display.newFrames(params.playerName.."_stand_1_%02d.png",1,4)
    self.idleFrames_ = display.newFrames(params.playerName.."_dance_a_1_%02d.png",1,8)
end

function Monster:runAI(map)
	self.map_ = map
	nextMonsterAction(self)
end

--设置方向
function Monster:setDirection(direction)
	self.direction_ = direction
	if direction == npcdirect.DIRECTION_RIGHT then
		self:setFlippedX(true)
	elseif direction == npcdirect.DIRECTION_LEFT then
		self:setFlippedX(false)
	end
end

return Monster