local MapEventHandler = require("app.MapEventHandler")
local MapEvent = require("app.MapEvent")
local MonsterEventHandler = class("MonsterEventHandler",MapEventHandler)

MONSTER_GEN_DURATION = 10  --多久生成一个怪物
MONSTER_RATE 		 = 2   --玩家的数量的倍数      


function MonsterEventHandler:ctor(runtime,map)
	MonsterEventHandler.super.ctor(self,runtime,map)
	self.monsters_ = {}
end

function MonsterEventHandler:addListener()
	--TODO 监听怪物被消灭事件
	g_eventManager:addEventListener(MapEvent.EVENT_MONSTER_DEAD,function(sender,target)
			target:fadeOut(1)
			sender:removeMonster(target)
			end,object)
end

function MonsterEventHandler:addMonster(monster)
	self.monsters_[monster] = monster
end

function MonsterEventHandler:removeMonster(monster)
	self.monsters_[monster] = nil
	self.map_:removeObject(monster)
end

-- 准备开始游戏
function MapEventHandler:preparePlay()
end

-- 开始游戏
function MapEventHandler:startPlay()
     self:addListener()
end

-- 停止游戏
function MapEventHandler:stopPlay()
    g_eventManager:removeListenerWithTarget(self)
end

return MonsterEventHandler