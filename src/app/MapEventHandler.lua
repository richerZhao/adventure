local MapEventHandler = class("MapEventHandler")

function MapEventHandler:ctor(runtime, map)
    self.runtime_        = runtime
    self.map_            = map
end

-- 准备开始游戏
function MapEventHandler:addListener()
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

return MapEventHandler
