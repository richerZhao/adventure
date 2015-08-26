local MapEventHandler = require("app.MapEventHandler")
local MapEvent = require("app.MapEvent")
local MonsterEventHandler = class("MonsterEventHandler",MapEventHandler)

MONSTER_GEN_DURATION = 3  --多久生成一个怪物
MONSTER_RATE 		 = 2   --玩家的数量的倍数
MONSTER_SEQ 		 = 1      


function MonsterEventHandler:ctor(runtime,map)
	MonsterEventHandler.super.ctor(self,runtime,map)

end

-- 准备开始游戏
function MonsterEventHandler:preparePlay()
	self.time_ = 0
end

-- 开始游戏
function MonsterEventHandler:startPlay()
     -- self:addListener()
end

-- 停止游戏
function MonsterEventHandler:stopPlay()
    -- g_eventManager:removeListenerWithTarget(self)
end

function MonsterEventHandler:addMonster(classId, state, id)
	self.runtime_:newObject(classId, state, id)
end

function MonsterEventHandler:tick(dt)
	local maxMonster = self.map_:getNpcCount() * MONSTER_RATE

	if self.map_:getMonsterCount() < maxMonster then
		if self.time_ >= MONSTER_GEN_DURATION then
			self:addMonster("monster",{defineId="monster"},"monster:"..MONSTER_SEQ)
			MONSTER_SEQ = MONSTER_SEQ + 1
			self.time_ = 0
		else
			self.time_ = self.time_ + dt
		end
	else
		self.time_ = 0
	end
end

return MonsterEventHandler