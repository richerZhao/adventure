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

    data.objects["npc:1"] = {defineId="npc"}
    data.objects["monster:1"] = {defineId="monster"}

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
    self.monsterGenArea_    = {}
    self.monsterGenAreaArr_ = {}
    self.npcCount_          = 0
    
    display.addSpriteFrames("player.plist", "player.png")
    display.addSpriteFrames("SheetMapBattle.plist", "SheetMapBattle.png")
    
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
    if classId == "organism" then 
        if object:getCampId() == MapConstants.PLAYER_CAMP then
            self:addNpc()
        else
            self:addMonster()
        end
    end
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
    if object:getCampId() == MapConstants.PLAYER_CAMP then
        self:removeNpc()
    else
        self:removeMonster()
    end
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
    local objects = objectLayer:getObjects()
    for i,prop in ipairs(objects) do
        local area = {}
        area.areaName = prop.name
        area.tiles = {}
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

    --初始化MONSTER诞生区域
    objectLayer = map:getObjectGroup("monstergenerateLayer")
    objects = objectLayer:getObjects()
    for i,prop in ipairs(objects) do
        local area = {}
        area.areaName = prop.name
        area.tiles = {}
        area.count = 0
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
        self.monsterGenArea_[area.areaName] = area
        table.insert(self.monsterGenAreaArr_, area)
    end
    self:sortMonsterArea()

    for id, object in pairs(self.objects_) do
        object:createView(self.batch_, self.marksLayer_, self.debugLayer_)
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

function Map:convertMapPositionToTile(mapPosition)
    local map = self:getBackgroundLayer()
    local x  = math.modf(mapPosition.x/map:getTileSize().width)
    local y = math.modf(((map:getMapSize().height * map:getTileSize().height ) - mapPosition.y) / map:getTileSize().height)
    return cc.p(x,y)
end

function Map:getCanReachTiles(targetPosition)
    return self:getCanReachTiles_(self:convertMapPositionToTile(targetPosition))
end

function Map:getCanReachTiles_(targetPosition)
    local map = self:getBackgroundLayer()
    local maxX = map:getMapSize().width - 1
    local maxY = map:getMapSize().height - 1
    local tiles = {}
    if targetPosition.x + 1 <= maxX then
        --右边
        if self:canReach_({x=targetPosition.x + 1, y=targetPosition.y}) then
            table.insert(tiles, {x=targetPosition.x + 1, y=targetPosition.y})
        end
    end
    
    if targetPosition.x - 1 >= 0 then
        --左边
        if self:canReach_({x=targetPosition.x - 1, y=targetPosition.y}) then
            table.insert(tiles, {x=targetPosition.x - 1, y=targetPosition.y})
        end
    end

    if targetPosition.y - 1 >= 0 then
        --上边
        if self:canReach_({x=targetPosition.x, y=targetPosition.y - 1}) then
            table.insert(tiles, {x=targetPosition.x, y=targetPosition.y - 1})
        end
    end

    if targetPosition.y + 1 <= maxY then
        --下边
        if self:canReach_({x=targetPosition.x, y=targetPosition.y + 1}) then
            table.insert(tiles, {x=targetPosition.x, y=targetPosition.y + 1})
        end
    end
    return tiles
end

function Map:canReach(targetPosition)
    return self:canReach_(self:convertMapPositionToTile(targetPosition))
end

function Map:canReach_(targetPosition)
    if self.unreach_:isUnreachTile(targetPosition) then return false end
    return true
end

function Map:getNpcGenPoint(araeName)
    local area = self.npcGenArea_[araeName]
    if not area then return end
    local tile = area.tiles[math.random(table.getn(area.tiles))]
    if not tile then return end
    return cc.p(self:convertTileToMapPosition(tile))
end

function Map:addMonster(araeName)
    local area = self.monsterGenArea_[araeName]
    if not area then return false end
    area.count = area.count + 1
    self:sortMonsterArea()
    return true
end

function Map:removeMonster(araeName)
    local area = self.monsterGenArea_[araeName]
    if not area then return end
    area.count = area.count - 1
    if area.count < 0 then area.count = 0 end
    self:sortMonsterArea()
end

function Map:sortMonsterArea()
    table.sort(self.monsterGenAreaArr_,function (a,b)
        return a.count < b.count
    end)
end

function Map:getMostMonsterAreaPoint()
    local tile = self:getMostMonsterAreaPoint_()
    if tile then 
        return cc.p(self:convertTileToMapPosition(tile))
    end
    return
end

function Map:getMostMonsterAreaPoint_()
    local area = self.monsterGenAreaArr_[1]
    if not area then return end
    local tile
    while not tile do
        tile = area.tiles[math.random(table.getn(area.tiles))]
        if tile then
            if self:canReach_(tile) then
                return tile
            end
        end
    end
    return
end

function Map:getMonsterCount()
    local count = 0
    for i,v in ipairs(self.monsterGenAreaArr_) do
        if v.count <= 0 then
            break
        end
        count = count + v.count
    end
    return count
end

function Map:addNpc()
    self.npcCount_ = self.npcCount_ + 1
end

function Map:removeNpc()
    self.npcCount_ = self.npcCount_ - 1
    if self.npcCount_ < 0 then self.npcCount_ = 0 end
end

function Map:getNpcCount()
    return self.npcCount_
end

return Map
