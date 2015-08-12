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
            size    = {width = CONFIG_SCREEN_WIDTH, height = CONFIG_SCREEN_HEIGHT},
            objects = {},
        }

    self.data_ = clone(data)
end

function Map:init()
	--TODO 
	self.width_             = self.data_.size.width
    self.height_            = self.data_.size.height
    self.mapName_ 			= self.data_.mapName
    if not self.mapName_ then
    	self.mapName_ = string.format("map%s.tmx", self.id_)
    end

    self.bgSprite_          = nil
    self.batch_             = nil
    self.uiLayer_       	= nil
    self.marksLayer_        = nil
    self.promptLayer_       = nil
    self.debugLayer_        = nil
    self.objects_ 			= {}
    self.objectsByClass_ 		= {}
    -- 添加地图数据中的对象
    for id, state in pairs(self.data_.objects) do
        local classId = unpack(string.split(id, ":"))
        self:newObject(classId, state, id)
    end

    -- 验证不可到达的路径
    for i, unreach in pairs(self:getObjectsByClassId("unreach")) do
        unreach:validate()
        if not path:isValid() then
            echoInfo(string.format("Map:init() - invalid unreach %s", path:getId()))
            self:removeObject(path)
        end
    end

    -- 验证其他对象
    for id, object in pairs(self.objects_) do
        local classId = object:getClassId()
        if classId ~= "unreach" then
            object:validate()
            if not object:isValid() then
                echoInfo(string.format("Map:init() - invalid object %s", object:getId()))
                self:removeObject(object)
            end
        end
    end

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
        print("Map:removeObject") 
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
    local  map = CCTMXTiledMap:create(self.mapName_)
    parent:addChild(map, 0, 100)


    self.bgSprite_ = map

    self.batch_ = display.newNode()
    parent:addChild(self.batch_)

    self.marksLayer_ = display.newNode()
    parent:addChild(self.marksLayer_)

    for id, object in pairs(self.objects_) do
        object:createView(self.batch_, self.marksLayer_, self.debugLayer_)
        object:updateView()

        --初始化不可用的tiles
        if object:getClassId() == "unreach" then
        	local obstacleLayer = map:getLayer("obstacleLayer")
        	local width = map:getMapSize().width - 1
        	local height = map:getMapSize().height - 1
        	local tile
        	for x=0,width do
        		for y=0,height do
        			tile = cc.p(x,y)
        			local gid = obstacleLayer:getTileGIDAt(tile)
					if gid and gid > 0 then
						object:addUnreachTile(tile)
					end
        		end
        	end
        end
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

return Map
