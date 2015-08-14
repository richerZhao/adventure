local BehaviorFactory = require("app.behaviors.BehaviorFactory")
local ObjectBase = class("ObjectBase")

-- ObjectBase.CLASS_INDEX_UNREACH        = 1
ObjectBase.CLASS_INDEX_ORGANISM       = 1
-- ObjectBase.CLASS_INDEX_STATIC      = 3
-- ObjectBase.CLASS_INDEX_MOVE        = 4

ObjectBase.CLASS_INDEX = {
    -- unreach       = ObjectBase.CLASS_INDEX_UNREACH,
    organism      = ObjectBase.CLASS_INDEX_ORGANISM,
    -- static     = ObjectBase.CLASS_INDEX_STATIC,
    -- move       = ObjectBase.CLASS_INDEX_MOVE,
}

MOVEDOWN    = 1
MOVELEFT    = 2
MOVERIGHT   = 3
MOVEUP      = 4

function ObjectBase:ctor(id,state,map)
	assert(type(state) == "table", "ObejctBase:ctor() - invalid state")

	--设置object的基本配置
	for k, v in pairs(state) do
    	local kn = k .. "_"
        self[kn] = v
    end

    local classId, index = unpack(string.split(id, ":"))
    self.map_        = map  					--地图
    self.id_         = id                       --id
    self.classId_    = classId                  --类别
    self.classIndex_ = ObjectBase.CLASS_INDEX[classId]
    self.index_      = checkint(index)
    self.x_          = checkint(self.x_)
    self.y_          = checkint(self.y_)
    self.offsetX_    = checkint(self.offsetX_)
    self.offsetY_    = checkint(self.offsetY_)
    self.state_      = state
    self.valid_      = false
    self.play_       = false
    self.tag_        = 0
    self.sprite_     = nil

    if type(self.viewZOrdered_) ~= "boolean" then
        self.viewZOrdered_ = true
    end
end

function ObjectBase:init()
	--绑定object的行为
	if not self.behaviors_ then return end
	local behaviors

	if type(self.behaviors_) == "string" then
        behaviors = string.split(self.behaviors_, ",")
    else
        behaviors = self.behaviors_
    end

    for i,behaviorName in ipairs(behaviors) do
    	behaviorName = string.trim(behaviorName)
        if behaviorName ~= "" then self:bindBehavior(behaviorName) end
    end
end

--绑定AI行为
function ObjectBase:bindBehavior(behaviorName)
	if not self.behaviorObjects_ then self.behaviorObjects_ = {} end
	if self.behaviorObjects_[behaviorName] then return end

	--从行为工厂中创建行为
	local behavior = BehaviorFactory.createBehavior(behaviorName)
	for i,dependBehaviorName in pairs(behavior:getDepends()) do
		self:bindBehavior(dependBehaviorName)

		if not self.behaviorDepends_ then
            self.behaviorDepends_ = {}
        end
        if not self.behaviorDepends_[dependBehaviorName] then
            self.behaviorDepends_[dependBehaviorName] = {}
        end
        table.insert(self.behaviorDepends_[dependBehaviorName], behaviorName)
	end

	behavior:bind(self)
	self.behaviorObjects_[behaviorName] = behavior
	self:resetAllBehaviors()
end

--解绑AI行为
function ObjectBase:unbindBehavior(behaviorName)
    assert(self.behaviorObjects_ and self.behaviorObjects_[behaviorName] ~= nil,
           string.format("ObjectBase:unbindBehavior() - behavior %s not binding", behaviorName))
    assert(not self.behaviorDepends_ or not self.behaviorDepends_[behaviorName],
           string.format("ObjectBase:unbindBehavior() - behavior %s depends by other binding", behaviorName))

    local behavior = self.behaviorObjects_[behaviorName]
    for i, dependBehaviorName in pairs(behavior:getDepends()) do
        for j, name in ipairs(self.behaviorDepends_[dependBehaviorName]) do
            if name == behaviorName then
                table.remove(self.behaviorDepends_[dependBehaviorName], j)
                if #self.behaviorDepends_[dependBehaviorName] < 1 then
                    self.behaviorDepends_[dependBehaviorName] = nil
                end
                break
            end
        end
    end

    behavior:unbind(self)
    self.behaviorObjects_[behaviorName] = nil
end

--重置所有AI行为
function ObjectBase:resetAllBehaviors()
	if not self.behaviorObjects_ then return end 

	local behaviors = {}
	for i,v in pairs(self.behaviorObjects_) do
		behaviors[#behaviors + 1] = behavior
	end
	table.sort(behaviors,function(a,b)
		return a:getPriority() > b:getPriority()
	end)
	for i,behavior in ipairs(behaviors) do
		behavior:reset(self)
	end
end

function ObjectBase:bindMethod(behavior, methodName, method, callOriginMethodLast)
    local originMethod = self[methodName] --取出之前的方法
    if not originMethod then
        self[methodName] = method
        return
    end

    if not self.bindingMethods_ then self.bindingMethods_ = {} end
    if not self.bindingMethods_[methodName] then self.bindingMethods_[methodName] = {} end

    local chain = {behavior, originMethod}
    local newMethod
    if callOriginMethodLast then --在最后执行原先的方法
        newMethod = function(...)
            method(...)
            chain[2](...)
        end
    else 						 --在最开始执行原先的方法
        newMethod = function(...)
            local ret = chain[2](...)
            if ret then 		--原先方法的执行结果存在,将结果传递给新方法
                local args = {...}
                args[#args + 1] = ret
                return method(unpack(args))
            else 				--原先方法的执行结果不存在,直接执行新方法
                return method(...)
            end
        end
    end

    self[methodName] = newMethod --新的方面 会调用之前的同名方法
    chain[3] = newMethod
    table.insert(self.bindingMethods_[methodName], chain)

    -- print(string.format("[%s]:bindMethod(%s, %s)", tostring(self), behavior:getName(), methodName))
    -- for i, chain in ipairs(self.bindingMethods_[methodName]) do
    --     print(string.format("  index: %d, origin: %s, new: %s", i, tostring(chain[2]), tostring(chain[3])))
    -- end
    -- print(string.format("  current: %s", tostring(self[methodName])))
end

function ObjectBase:unbindMethod(behavior, methodName)
    if not self.bindingMethods_ or not self.bindingMethods_[methodName] then
        self[methodName] = nil
        return
    end

    local methods = self.bindingMethods_[methodName]
    local count = #methods
    for i = count, 1, -1 do
        local chain = methods[i]

        if chain[1] == behavior then
            -- print(string.format("[%s]:unbindMethod(%s, %s)", tostring(self), behavior:getName(), methodName))
            if i < count then
                -- 如果移除了中间的节点，则将后一个节点的 origin 指向前一个节点的 origin
                -- 并且对象的方法引用的函数不变
                -- print(string.format("  remove method from index %d", i))
                methods[i + 1][2] = chain[2]
            elseif count > 1 then
                -- 如果移除尾部的节点，则对象的方法引用的函数指向前一个节点的 new
                self[methodName] = methods[i - 1][3]
            elseif count == 1 then
                -- 如果移除了最后一个节点，则将对象的方法指向节点的 origin
                self[methodName] = chain[2]
                self.bindingMethods_[methodName] = nil
            end

            -- 移除节点
            table.remove(methods, i)

            -- if self.bindingMethods_[methodName] then
            --     for i, chain in ipairs(self.bindingMethods_[methodName]) do
            --         print(string.format("  index: %d, origin: %s, new: %s", i, tostring(chain[2]), tostring(chain[3])))
            --     end
            -- end
            -- print(string.format("  current: %s", tostring(self[methodName])))

            break
        end
    end
end

-- 验证是否合法
function ObjectBase:validate()
end

-- 验证结果
function ObjectBase:isValid()
    return self.valid_
end

function ObjectBase:getClassId()
    return self.classId_
end

function ObjectBase:getIndex()
    return self.index_
end

function ObjectBase:getPosition()
    return self.x_ ,self.y_ 
end

function ObjectBase:setPosition(x,y)
    self.x_ ,self.y_ = x,y
end

function ObjectBase:isViewCreated()
    return self.sprite_ ~= nil
end

function ObjectBase:isViewZOrdered()
    return self.viewZOrdered_
end

function ObjectBase:createView(batch, marksLayer, debugLayer)
    assert(self.batch_ == nil, "ObjectBase:createView() - view already created")
    self.batch_      = batch
    self.marksLayer_ = marksLayer
    self.debugLayer_ = debugLayer
end

function ObjectBase:removeView()
    assert(self.batch_ ~= nil, "ObjectBase:removeView() - view not exists")
    self.batch_      = nil
    self.marksLayer_ = nil
    self.debugLayer_ = nil
end

function ObjectBase:updateView()
end

-- 
function ObjectBase:preparePlay()
end

function ObjectBase:startPlay()
    self.play_ = true
end

function ObjectBase:stopPlay()
    self.play_ = false
end

function ObjectBase:isPlay()
    return self.play_
end

function ObjectBase:hasBehavior(behaviorName)
    return self.behaviorObjects_ and self.behaviorObjects_[behaviorName] ~= nil
end

function ObjectBase:getView()
    return nil
end

return ObjectBase