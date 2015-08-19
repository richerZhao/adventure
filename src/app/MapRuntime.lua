 local MapConstants = require("app.MapConstants")

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

    --TODO 用于事件监控
    -- local eventHandlerModuleName = string.format("maps.Map%sEvents", map:getId())
    -- local eventHandlerModule = require(eventHandlerModuleName)
    -- self.handler_ = eventHandlerModule.new(self, map)



end

function MapRuntime:onExit()

end

function MapRuntime:preparePlay()
    -- self.handler_:preparePlay()
    -- self:dispatchEvent({name = MapEvent.MAP_PREPARE_PLAY})

    for id, object in pairs(self.map_:getAllObjects()) do
        object:validate()
        object:preparePlay()
        object:updateView()
    end

    self.camera_:setOffset(0, 0)

    self.time_          = 0
    self.lastSecond_    = 0
end

function MapRuntime:startPlay()

    self.starting_    = true
    self.over_        = false
    self.paused_      = false

    for id, object in pairs(self.map_:getAllObjects()) do
        object:startPlay()
        object:startRunAI()
        -- object:setPath({{x=48,y=1008},{x=48,y=976},{x=80,y=976},{x=112,y=976},{x=144,y=976},{x=176,y=976}})
        object.updated__ = true

        -- if object.classIndex_ == CLASS_INDEX_STATIC and object:hasBehavior("TowerBehavior") then
        --     self.towers_[id] = {
        --         object.x_ + object.radiusOffsetX_,
        --         object.y_ + object.radiusOffsetY_,
        --         object.radius_ + 20,
        --     }
        -- end
    end

    -- self.handler_:startPlay(state)
    -- self:dispatchEvent({name = MapEvent.MAP_START_PLAY})

    -- self:start() -- start physics world
end

function MapRuntime:stopPlay()
	for id, object in pairs(self.map_:getAllObjects()) do
        object:stopPlay()
    end

    -- self.handler_:stopPlay()
    -- self:dispatchEvent({name = MapEvent.MAP_STOP_PLAY})
    -- self:removeAllEventListeners()

    self.starting_ = false
end

function MapRuntime:onTouch(event, x, y)
	--TODO 点中建筑物,人物的操作
end

function MapRuntime:tick(dt)
	if not self.starting_ or self.paused_ then return end

	-- local handler = self.handler_

	self.time_ = self.time_ + dt
    local secondsDelta = self.time_ - self.lastSecond_

    -- if secondsDelta >= 1.0 then
    --     self.lastSecond_ = self.lastSecond_ + secondsDelta
    --     if not self.over_ then
    --         handler:time(self.time_, secondsDelta)
    --     end
    -- end

    -- 更新所有对象后
    local maxZOrder = MapConstants.MAX_OBJECT_ZORDER
    for i, object in pairs(self.map_.objects_) do
        if object.tick then
            local lx, ly = object.x_, object.y_
            object:tick(dt)
            object.updated__ = lx ~= object.x_ or ly ~= object.y_

            -- 只有当对象的位置发生变化时才调整对象的 ZOrder
            if object.updated__ and object.sprite_ and object.viewZOrdered_ then
                -- if object.isMoveObject then
                --     self.marksLayer_:reorderChild(object.sprite_, maxZOrder - (object.y_ + object.offsetY_))
                -- else
                --     self.batch_:reorderChild(object.sprite_, maxZOrder - (object.y_ + object.offsetY_))
                -- end
                self.batch_:reorderChild(object.sprite_, maxZOrder - (object.y_ + object.offsetY_))
            end
        end

        if object.fastUpdateView then
            object:fastUpdateView()
        end
    end

    -- -- 通过碰撞引擎获得事件
    -- local events = self:tickCollider(self.map_.objects_, self.colls_, dt)
    -- if self.over_ then
    --     events = {}
    -- end

    -- if events and #events > 0 then
    --     for i, t in ipairs(events) do
    --         local event, object1, object2 = t[1], t[2], t[3]
    --         if event == MAP_EVENT_COLLISION_BEGAN then
    --             if object2.classIndex_ == CLASS_INDEX_RANGE then
    --                 handler:objectEnterRange(object1, object2)
    --                 self:dispatchEvent({name = MapEvent.OBJECT_ENTER_RANGE, object = object1, range = object2})
    --             else
    --                 handler:objectCollisionBegan(object1, object2)
    --                 self:dispatchEvent({
    --                     name = MapEvent.OBJECT_COLLISION_BEGAN,
    --                     object1 = object1,
    --                     object2 = object2,
    --                 })
    --             end
    --         elseif event == MAP_EVENT_COLLISION_ENDED then
    --             if object2.classIndex_ == CLASS_INDEX_RANGE then
    --                 handler:objectExitRange(object1, object2)
    --                 self:dispatchEvent({name = MapEvent.OBJECT_EXIT_RANGE, object = object1, range = object2})
    --             else
    --                 handler:objectCollisionEnded(object1, object2)
    --                 self:dispatchEvent({
    --                     name = MapEvent.OBJECT_COLLISION_ENDED,
    --                     object1 = object1,
    --                     object2 = object2,
    --                 })
    --             end
    --         elseif event == MAP_EVENT_FIRE then
    --             allfireTarget = t[4];
    --             handler:fire(object1, object2,allfireTarget)
    --         elseif event == MAP_EVENT_NO_FIRE_TARGET then
    --             handler:noTarget(object1)
    --         end
    --     end
    -- end



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
    if self.starting_ then object:startPlay() end

    if object.sprite_ and object.viewZOrdered_ then
        -- if object.isMoveObject == true then
        --     --todo
        -- else
        --     self.batch_:reorderChild(object.sprite_, MapConstants.MAX_OBJECT_ZORDER - (object.y_ + object.offsetY_))
        -- end
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
        print("MapRuntime:removeObject " .. delay)
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

-- function MapRuntime:tickCollider(objects, colls, dt)
--     local dists = {}
--     local sqrt = math.sqrt

--     -- 遍历所有对象，计算静态对象与其他静态对象或 Range 对象之间的距离
--     for id1, obj1 in pairs(objects) do
--         while true do
--             if not checkStiaticObjectCollisionEnabled(obj1) then
--                 break
--             end

--             local x1, y1 = obj1.x_ + checknumber(obj1.radiusOffsetX_), obj1.y_ + checknumber(obj1.radiusOffsetY_)
--             local campId1 = checkint(obj1.campId_)
--             dists[obj1] = {}

--             for id2, obj2 in pairs(objects) do
--                 while true do
--                     if obj1 == obj2 then
--                         break 
--                     end

--                     local ci = obj2.classIndex_

--                     if ci ~= CLASS_INDEX_MOVE and ci ~= CLASS_INDEX_RANGE then
--                         break 
--                     end
--                     if ci == CLASS_INDEX_MOVE and not checkStiaticObjectCollisionEnabled(obj2) then break end
--                     if campId1 ~= 0 and campId1 == obj2.campId_ then break end

--                     local x2, y2 = obj2.x_ + checknumber(obj2.radiusOffsetX_), obj2.y_ + checknumber(obj2.radiusOffsetY_)
--                     local dx = x2 - x1
--                     local dy = y2 - y1
--                     local dist = sqrt(dx * dx + dy * dy)
--                     dists[obj1][obj2] = dist

--                     break -- stop while
--                 end
--             end -- for id2, obj2 in pairs(objects) do

--             break -- stop while
--         end
--     end -- for id1, obj1 in pairs(objects) do

--     -- 检查碰撞和开火
--     local events = {}
--     for obj1, obj1targets in pairs(dists) do
--         local fireRange1 = checknumber(obj1.fireRange_)
--         local radius1 = checknumber(obj1.radius_)
--         local checkFire1 = obj1.fireEnabled_ and checknumber(obj1.fireLock_) <= 0 and fireRange1 > 0 and checknumber(obj1.fireCooldown_) <= 0

--         -- 从 obj1 的目标中查找距离最近的
--         local minTargetDist = 999999
--         local fireTarget = nil
--         local allfireTarget = {};

--         -- 初始化碰撞目标数组
--         if not colls[obj1] then colls[obj1] = {} end
--         local obj1colls = colls[obj1]

--         -- 检查 obj1 和 obj2 的碰撞关系
--         for obj2, dist1to2 in pairs(obj1targets) do
--             local radius2 = obj2.radius_
--             local isCollision = dist1to2 - radius1 - radius2 <= 0

--             local event = 0
--             local obj2CollisionWithObj1 = obj1colls[obj2]
--             if isCollision and not obj2CollisionWithObj1 then
--                 -- obj1 和 obj2 开始碰撞
--                 event = MAP_EVENT_COLLISION_BEGAN
--                 obj1colls[obj2] = true
--             elseif not isCollision and obj2CollisionWithObj1 then
--                 -- obj1 和 obj2 结束碰撞
--                 event = MAP_EVENT_COLLISION_ENDED
--                 obj1colls[obj2] = nil
--             end

--             if event ~= 0 then
--                 -- 记录事件
--                 events[#events + 1] = {event, obj1, obj2}
--             end

--             -- 检查 obj1 是否可以对 obj2 开火
--             if checkFire1 and obj2.classIndex_ == CLASS_INDEX_MOVE then
--                 local dist = dist1to2 - fireRange1 - radius2
--                 if dist <= 0 and dist < minTargetDist then
--                     minTargetDist = dist
     
--                     fireTarget = obj2
--                     if obj1:hasBehavior("TowerBehavior") then
--                         allfireTarget[#allfireTarget + 1] = obj2;
--                     end               
--                 end
--             end
--         end

--         if fireTarget then
--             events[#events + 1] = {MAP_EVENT_FIRE, obj1, fireTarget,allfireTarget}
--         elseif checkFire1 then
--             events[#events + 1] = {MAP_EVENT_NO_FIRE_TARGET, obj1}
--         end
--     end

--     return events
-- end

return MapRuntime