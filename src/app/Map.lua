local ObjectFactory = require("app.ObjectFactory")
local MapConstants  = require("app.MapConstants")
local MapCamera  = require("app.MapCamera")
local Map = class("Map")

function Map:ctor(id)
	self.id_  			   = id
	self.ready_            = false
    self.mapModuleName_    = string.format("maps.Map%sData", id)
    self.eventModuleName_  = string.format("maps.Map%sEvents", id)

    -- TODO 从配置文件中读取
    local data = {
            size    = {width = 1600, height = 1600},
            objects = {},
        }

    data.objects["organism:1"] = {defineId="organism"}

    self.data_ = clone(data)
end

function Map:init()
	--TODO 
	self.width_             = self.data_.size.width
    self.height_            = self.data_.size.height
    self.mapName_ 			= self.data_.mapName
    if not self.mapName_ then
    	-- self.mapName_ = string.format("map%s.tmx", self.id_)
        self.mapName_ = "map2.tmx"
    end

    self.bgSprite_          = nil
    self.batch_             = nil
    self.uiLayer_       	= nil
    self.marksLayer_        = nil
    self.promptLayer_       = nil
    self.debugLayer_        = nil
    self.objects_ 			= {}
    self.objectsByClass_ 	= {}
    self.unreach_           = {}
    self.npcGenArea_        = {}
    
    display.addSpriteFrames("player.plist", "player.png")
    -- 添加地图数据中的对象
    for id, state in pairs(self.data_.objects) do
        local classId = unpack(string.split(id, ":"))
        self:newObject(classId, state, id)
    end

    -- -- 验证不可到达的路径
    -- for i, unreach in pairs(self:getObjectsByClassId("unreach")) do
    --     unreach:validate()
    --     if not unreach:isValid() then
    --         echoInfo(string.format("Map:init() - invalid unreach %s", unreach:getId()))
    --         self:removeObject(unreach)
    --     end
    -- end

    -- -- 验证其他对象
    -- for id, object in pairs(self.objects_) do
    --     local classId = object:getClassId()
    --     if classId ~= "unreach" then
    --         object:validate()
    --         if not object:isValid() then
    --             echoInfo(string.format("Map:init() - invalid object %s", object:getId()))
    --             self:removeObject(object)
    --         end
    --     end
    -- end

    self.unreach_ = require("app.Unreach").new()


    -- 计算地图位移限定值
    self.camera_ = MapCamera.new(self)
    self.camera_:resetOffsetLimit()

	self.ready_ = true
end

function Map:newObject(classId,state,id)
	local object = ObjectFactory.newObject(classId, id, state,self)
	object:resetAllBehaviors()

	self.objects_[id] = object
    if not self.objectsByClass_[classId] then
        self.objectsByClass_[classId] = {}
    end
    self.objectsByClass_[classId][id] = object

    -- validate object
    if self.ready_ then
        object:validate()
        if not object:isValid() then
            echoInfo(string.format("Map:newObject() - invalid object %s", id))
            self:removeObject(object)
            return nil
        end

        -- create view
        if self:isViewCreated() then
            -- if object.isMoveObject == true then
            --     object:createView(self.marksLayer_, self.marksLayer_, self.debugLayer_)
            -- else
            --     object:createView(self.batch_, self.marksLayer_, self.debugLayer_)
            -- end
            object:createView(self.batch_, self.marksLayer_, self.debugLayer_)
            object:updateView()
            
        end

        -- if object:hasBehavior("TowerBehavior") then
        --     if self:checkTowerPos(object.x_,object.y_) then
        --         -- print("d12: ",object.x_, object.y_)
        --         local pos = self:getTowerPos(object.x_, object.y_)
        --         -- print("d13: ",pos.x, pos.y)
        --         object.x_ = pos.x;
        --         object.y_ = pos.y;
        --         object:updateView();
        --     else
        --         self:removeObject(object);
        --         return nil;
        --     end
            
        -- end
    end

    return object

end

function Map:removeObject(object)
	local id = object:getId()
    assert(self.objects_[id] ~= nil, string.format("Map:removeObject() - object %s not exists", tostring(id)))

    self.objects_[id] = nil
    self.objectsByClass_[object:getClassId()][id] = nil
    if object:isViewCreated() then
        object:removeView()
    end
end

function Map:getObject(id)
	assert(self:isObjectExists(id), string.format("Map:getObject() - object %s not exists", tostring(id)))
    return self.objects_[id]
end

function Map:removeObjectById(id)
	self:removeObject(self:getObject(id))
end

function Map:isObjectExists(id)
    return self.objects_[id] ~= nil
end

function Map:getObjectsByClassId(classId)
	return self.objectsByClass_[classId] or {}
end

function Map:getCamera()
    return self.camera_
end

function Map:getBackgroundLayer()
    return self.bgSprite_
end

function Map:getBatchLayer()
    return self.batch_
end

function Map:getMarksLayer()
    return self.marksLayer_
end

function Map:createView(parent)
	assert(self.batch_ == nil, "Map:createView() - view already created")
	-- 此处设置纹理为16位,为了缩小地图所占内存
	-- CCTexture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGB565)
    -- 此处设置纹理为32位,为了以后加载的图片不失真
    -- CCTexture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGBA8888)
    local  map = cc.TMXTiledMap:create(self.mapName_)
    parent:addChild(map, 0, 100)

    self.bgSprite_ = map

    self.batch_ = display.newNode()
    parent:addChild(self.batch_)

    self.marksLayer_ = display.newNode()
    parent:addChild(self.marksLayer_)

    --初始化不可用的tiles
    local obstacleLayer = map:getLayer("obstacleLayer")
    local width = map:getMapSize().width - 1
    local height = map:getMapSize().height - 1
    local tile
    for x=0,width do
        for y=0,height do
            tile = cc.p(x,y)
            local gid = obstacleLayer:getTileGIDAt(tile)
            if gid and gid > 0 then
                self.unreach_:addUnreachTile(tile)
            end
        end
    end

    --初始化NPC诞生区域
    local objectLayer = map:getObjectGroup("npcgenerateLayer")
    for i=1,1 do
        local area = {}
        area.areaName = "npc_gen_point_"..i
        area.tiles = {}
        local prop = objectLayer:getObject(area.areaName)
        local minTileX = math.modf(prop.x/map:getTileSize().width) 
        local maxTileY = math.modf((map:getMapSize().height * map:getTileSize().height - prop.y)/map:getTileSize().height)
        local maxTileX = math.modf((prop.x + prop.width)/map:getTileSize().width) 
        local minTileY = math.modf((map:getMapSize().height * map:getTileSize().height - (prop.y + prop.height))/map:getTileSize().height)
        for x=minTileX,maxTileX do
            for y=minTileY,maxTileY do
                if not self.unreach_:isUnreachTile(cc.p(x,y)) then
                    table.insert(area.tiles, cc.p(x,y))
                end
                
            end
        end
        self.npcGenArea_[area.areaName] = area
    end

    for id, object in pairs(self.objects_) do
        object:createView(self.batch_, self.marksLayer_, self.debugLayer_)
        local tile = self.npcGenArea_["npc_gen_point_1"].tiles[math.random(table.getn(self.npcGenArea_["npc_gen_point_1"].tiles))]
        -- local x,y = self:convertTileToMapPosition(tile)
        object:setPosition(self:convertTileToMapPosition(tile))
        object:updateView()
    end
    self:setAllObjectsZOrder()
end

function Map:removeView()
    assert(self.batch_ ~= nil, "Map:removeView() - view not exists")

    for id, object in pairs(self.objects_) do
        if object:isViewCreated() then object:removeView() end
    end

    self.bgSprite_:removeSelf()
    self.batch_:removeSelf()
    self.marksLayer_:removeSelf()
    if self.debugLayer_ then self.debugLayer_:removeSelf() end

    self.bgSprite_   = nil
    self.batch_      = nil
    self.marksLayer_ = nil
    self.debugLayer_ = nil
end

function Map:updateView()
    assert(self.batch_ ~= nil, "Map:removeView() - view not exists")

    for id, object in pairs(self.objects_) do
        object:updateView()
    end
end

function Map:setAllObjectsZOrder()
    local batch = self.batch_
    for id, object in pairs(self.objects_) do
        local view = object:getView()
        if view then
            if object.viewZOrdered_ then
                batch:reorderChild(view, MapConstants.MAX_OBJECT_ZORDER - object.y_)
            elseif type(object.zorder_) == "number" then
                batch:reorderChild(view, object.zorder_)
            else
                batch:reorderChild(view, MapConstants.DEFAULT_OBJECT_ZORDER)
            end
            object:updateView()
        end
    end
end

function Map:getSize()
    return self.width_,self.height_
end

function Map:getAllObjects()
    return self.objects_
end

function Map:getUnreach()
    return self.unreach_
end

--[[--

确认地图是否已经创建了视图

]]
function Map:isViewCreated()
    return self.batch_ ~= nil
end

function Map:convertTileToMapPosition(tile)
    local map = self:getBackgroundLayer()
    local x = tile.x * map:getTileSize().width + map:getTileSize().height / 2
    local y = map:getMapSize().height * map:getTileSize().height - tile.y * map:getTileSize().height - map:getTileSize().height / 2
    return x,y
end

return Map
