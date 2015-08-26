local MapConstants = require("app.MapConstants")
local MapEvent = require("app.MapEvent")


local MapRuntime = class("MapRuntime",function()
    return display.newNode()
end)

function MapRuntime:ctor(map)
	--注册分发事件的方法
	cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()
	self.map_ 				   = map
	self.marksLayer_           = map:getMarksLayer()
    self.batch_                = map:getBatchLayer()
    self.camera_               = map:getCamera()
    self.starting_             = false
    self.over_                 = false
    self.paused_               = false
    self.time_                 = 0 -- 地图已经运行的时间
    self.lastSecond_           = 0 -- 用于触发 OBJECT_IN_RANGE 事件
    self.colls_                = {} -- 用于跟踪碰撞状态
    self.monsterGenDuration_   = 0  -- 用于计算怪物生成时间
    self.maxMonsters_          = 10 --最大怪物数量

    --用于战斗轮询事件监控
    -- local eventHandlerModuleName = string.format("maps.Map%sEvents", map:getId())
    local eventHandlerModuleName = "app.FightEventHandler"
    local eventHandlerModule = require(eventHandlerModuleName)
    self.fightEventHandler_ = eventHandlerModule.new(self, map)

    eventHandlerModuleName = "app.MonsterEventHandler"
    eventHandlerModule = require(eventHandlerModuleName)
    self.monsterEventHandler_ = eventHandlerModule.new(self, map)
end

function MapRuntime:onExit()

end

function MapRuntime:preparePlay()
    self.fightEventHandler_:preparePlay()
    self.monsterEventHandler_:preparePlay()

    for id, object in pairs(self.map_:getAllObjects()) do
        object:validate()
        object:preparePlay()
        object:updateView()
    end

    self.camera_:setOffset(0, 0)

    self.time_                  = 0
    self.lastSecond_            = 0
    self.monsterGenDuration_    = 0
    self.maxMonsters_           = 10
end

function MapRuntime:startPlay()

    self.starting_    = true
    self.over_        = false
    self.paused_      = false

    for id, object in pairs(self.map_:getAllObjects()) do
        if object.addListener then
            object:addListener()
        end
        object:startPlay()
        object:startRunAI()
        object.updated__ = true
    end

    self.fightEventHandler_:startPlay(state)
    self.monsterEventHandler_:startPlay(state)
    -- self:dispatchEvent({name = MapEvent.MAP_START_PLAY})
end

function MapRuntime:stopPlay()
	for id, object in pairs(self.map_:getAllObjects()) do
        object:stopPlay()
    end

    self.fightEventHandler_:stopPlay()
    -- self:dispatchEvent({name = MapEvent.MAP_STOP_PLAY})

    self.starting_ = false
end

function MapRuntime:onTouch(event, x, y)
	--TODO 点中建筑物,人物的操作
end

function MapRuntime:tick(dt)
	if not self.starting_ or self.paused_ then return end

	-- local handler = self.handler_

	
    -- if secondsDelta >= 1.0 then
    --     self.lastSecond_ = self.lastSecond_ + secondsDelta
    --     if not self.over_ then
    --         handler:time(self.time_, secondsDelta)
    --     end
    -- end

    -- 更新所有对象后
    local maxZOrder = MapConstants.MAX_OBJECT_ZORDER
    for i, object in pairs(self.map_:getAllObjects()) do
        while true do
            if object:hasBehavior("LifeBehavior") and object:isDestroyed() then
                self.map_:removeObject(object)
                break
            end

            if object.tick then
                local lx, ly = object.x_, object.y_
                object:tick(dt)
                object.updated__ = lx ~= object.x_ or ly ~= object.y_

                -- 只有当对象的位置发生变化时才调整对象的 ZOrder
                if object.updated__ and object.sprite_ and object.viewZOrdered_ then
                    self.batch_:reorderChild(object.sprite_, maxZOrder - (object.y_ + object.offsetY_))
                end
            end

            if object.fastUpdateView then
                object:fastUpdateView()
            end
            break
        end
        
    end

    -- self.time_ = self.time_ + dt
    -- local secondsDelta = self.time_ - self.lastSecond_
    
    -- if self.map_:getMonsterCount() < 10 then
    --     self.monsterGenDuration_ = self.monsterGenDuration_ + dt
    --     if self.monsterGenDuration_ > 10 then
    --         --TODO 生成一个怪物
    --         self.monsterGenDuration_ = 0
    --     end
    -- end

    -- 通过碰撞引擎获得事件
    local events = self:tickCollider(self.map_.objects_, dt)

    if self.over_ then
        events = {}
    end

    if events and #events > 0 then
        for i, t in ipairs(events) do
            local event, object1, object2 = t[1], t[2], t[3]
            g_eventManager:dispatchEvent(event,object1,object2)
        end
    end

    --执行战斗计算
    self.fightEventHandler_:tick(dt)
    --执行生成怪物
    self.monsterEventHandler_:tick(dt)
end

function MapRuntime:tickCollider(objects, dt)
    local dists = {}
    local sqrt = math.sqrt

     -- 遍历所有对象计算仇恨碰撞范围
    for id1, obj1 in pairs(objects) do
        while true do
            local x1, y1 = obj1.x_ , obj1.y_
            local campId1 = obj1.campId_
            dists[obj1] = {}

            for id2, obj2 in pairs(objects) do
                while true do
                    if obj1 == obj2 then
                        break 
                    end
                    if campId1 == obj2.campId_ then
                        break 
                    end

                    if not obj2:hasBehavior("LifeBehavior") then
                        break 
                    end

                    if not obj2:isLive() then
                        break 
                    end

                    local x2, y2 = obj2.x_, obj2.y_
                    local dx = x2 - x1
                    local dy = y2 - y1
                    local dist = sqrt(dx * dx + dy * dy)
                    dists[obj1][obj2] = dist
                    break -- stop while
                end
            end 
            break -- stop while
        end
    end

    -- 检查仇恨范围和攻击范围
    local events = {}
    for obj1, obj1targets in pairs(dists) do
        if obj1:hasBehavior("AttackBehavior") then
            --该对象没有处于战斗移动/战斗中
            local hatredRange1 = obj1.hatredRange_
            local attackRange1 = obj1.attackRange_
            local target
            local mindist
            local eventName
            for obj2, dist1to2 in pairs(obj1targets) do
                while true do
                    --如果在攻击范围
                    if dist1to2 <= attackRange1 then
                        if obj1.fightLocked_ > 0 then
                            break
                        end
                        if not mindist then
                            mindist = dist1to2
                            target = obj2
                            eventName = "attack"
                        end
                    --如果在仇恨范围
                    elseif dist1to2 <= hatredRange1 then
                        if obj1.moveLocked_ > 0 then
                            break
                        end 
                        if not mindist then
                            mindist = dist1to2
                            target = obj2
                            eventName = "hatred"
                        end
                    end
                    
                    break
                end

                if target then
                    events[#events + 1] = {eventName, obj1, target}
                end
            end
            
        end
    end
    return events
end

function MapRuntime:getMap()
    return self.map_
end

function MapRuntime:getCamera()
    return self.map_:getCamera()
end

function MapRuntime:getTime()
    return self.time_
end

--[[--

用于运行时创建新对象并放入地图

]]
function MapRuntime:newObject(classId, state, id)
    local object = self.map_:newObject(classId, state, id)
    object:preparePlay()
    if self.starting_ then
        if object.addListener then
            object:addListener()
        end
        object:startPlay() 
        object:startRunAI()
        object.updated__ = true
    end

    if object.sprite_ and object.viewZOrdered_ then
        self.batch_:reorderChild(object.sprite_, MapConstants.MAX_OBJECT_ZORDER - (object.y_ + object.offsetY_))
    end
    object:updateView()

    return object
end

--[[--

删除对象及其视图

]]
function MapRuntime:removeObject(object, delay)
    if delay then
        object:getView():performWithDelay(function()
            self.map_:removeObject(object)
        end, delay)
    else
        self.map_:removeObject(object)
    end
end

function MapRuntime:pausePlay()
    if not self.paused_ then
        self:dispatchEvent({name = MapEvent.MAP_PAUSE_PLAY})
    end
    self.paused_ = true
end

function MapRuntime:resumePlay()
    if self.paused_ then
        self:dispatchEvent({name = MapEvent.MAP_RESUME_PLAY})
    end
    self.paused_ = false
end

return MapRuntime