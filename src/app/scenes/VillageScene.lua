LEVEL_ID = "10000"

local VillageScene = class("VillageScene",function()
	return display.newScene("VillageScene")
end)

function VillageScene:ctor()
	-- mapLayer 包含地图的整个视图
    self.mapLayer_ = display.newNode()
    self.mapLayer_:align(display.LEFT_BOTTOM, 0, 0)
    self:addChild(self.mapLayer_)

    -- touchLayer 用于接收触摸事件
    self.touchLayer_ = display.newLayer()
    self:addChild(self.touchLayer_)

    -- uiLayer 用于显示操作菜单
    self.uiLayer_ = display.newNode()
    self.uiLayer_:setPosition(0, 0)
    self:addChild(self.uiLayer_)
        -- 创建地图对象
    self.map_ = require("app.Map").new(LEVEL_ID) -- 参数：地图ID, 是否是编辑器模式
    self.map_:init()
    self.map_:createView(self.mapLayer_)
    self:playMap()
end

function VillageScene:onEnter()
	self.touchLayer_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        return self:onTouch(event.name, event.x, event.y)
    end)
    self.touchLayer_:setTouchEnabled(true)
    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, handler(self, self.tick))
    self:scheduleUpdate()
end

function VillageScene:playMap()
    cc.Director:getInstance():setDisplayStats(true)
    -- cc.Director:sharedDirector()

    local camera = self.map_:getCamera()
    camera:setMargin(0, 0, 0, 0)
    camera:setOffset(0, 0)

    -- 强制垃圾回收
    collectgarbage()
    collectgarbage()

        -- 开始执行地图
    self.mapRuntime_ = require("app.MapRuntime").new(self.map_)
    self.mapRuntime_:preparePlay()
    self.mapRuntime_:startPlay()
    self:addChild(self.mapRuntime_)
end

function VillageScene:onExit()

end

function VillageScene:tick(dt)
    if self.mapRuntime_ then
        for i=1,1 do
            self.mapRuntime_:tick(dt)
        end
    end
end

function VillageScene:onTouch(event, x, y)
    -- if self.mapRuntime_ then
        -- 如果正在运行地图，将触摸事件传递到地图
        -- if self.mapRuntime_:onTouch(event, x, y, map) == true then
        --     return true
        -- end

        if event == "began" then
            self.drag = {
                startX  = x,
                startY  = y,
                lastX   = x,
                lastY   = y,
                offsetX = 0,
                offsetY = 0,
            }
            return true
        end

        if event == "moved" then
            self.drag.offsetX = x - self.drag.lastX
            self.drag.offsetY = y - self.drag.lastY
            self.drag.lastX = x
            self.drag.lastY = y
            self.map_:getCamera():moveOffset(self.drag.offsetX, self.drag.offsetY)

        else -- "ended" or CCTOUCHCANCELLED
            self.drag = nil
        end

        return
    -- end
end

return VillageScene