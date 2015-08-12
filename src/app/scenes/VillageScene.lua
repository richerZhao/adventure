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
end

function VillageScene:onEnter()
	self.touchLayer_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        return self:onTouch(event.name, event.x, event.y)
    end)
    self.touchLayer_:setTouchEnabled(true)
    -- self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, handler(self, self.tick))
    -- self:scheduleUpdate()
end

function VillageScene:playMap()
    CCDirector:sharedDirector():setDisplayStats(true)

    local camera = self.map_:getCamera()
    camera:setMargin(0, 0, 0, 0)
    camera:setOffset(0, 0)

    -- 强制垃圾回收
    collectgarbage()
    collectgarbage()

end

function VillageScene:onExit()

end

function VillageScene:tick(dt)

end

function VillageScene:onTouch(event, x, y)

	return true
end





return VillageScene