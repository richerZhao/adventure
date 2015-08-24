local MapEventHandler = require("app.MapEventHandler")
local MapEvent = require("app.MapEvent")
local NinjaEvnetHandler = class("NinjaEvnetHandler",MapEventHandler)
function NinjaEvnetHandler:ctor(runtime,map)
	NinjaEvnetHandler.super.ctor(self,runtime,map)
	self.ninjas_ = {}
end

function NinjaEvnetHandler:addListener()
	--TODO 监听怪物被消灭事件
	g_eventManager:addEventListener(MapEvent.EVENT_MONSTER_DEAD,function(sender,target)


			end,object)
end

function NinjaEvnetHandler:addNinja(ninja)
	self.ninjas_[ninja] = ninja
end

function NinjaEvnetHandler:removeNinja(ninja)
	self.ninjas_[ninja] = nil
	self.map_:removeObject(ninja)
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

function NinjaEvnetHandler:enemyDead()
	
end


return NinjaEvnetHandler