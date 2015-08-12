local Unreach = require("app.Unreach")
local ObjectFactory = {}

--创建一个对象
function ObjectFactory.newObject(classId, id, state, map)
	local object

    if classId == "unreach" then
        object = Unreach.new(id, state, map)
        object:init()
        -- if debug then
        --     object:bindBehavior("StaticObjectEditorBehavior")
        -- end
    -- elseif classId == "move" then
    --     object = MoveObject.new(id, state, map)
    --     object:init()
    --     -- if debug then
    --     --     object:bindBehavior("StaticObjectEditorBehavior")
    --     -- end
    -- elseif classId == "unreach" then
    --     object = Unreach.new(id, state, map)
    --     object:init()
    --     -- if debug then
    --     --     object:bindBehavior("PathEditorBehavior")
    --     -- end

    -- elseif classId == "range" then
    --     object = Range.new(id, state, map)
    --     object:init()
    --     -- if debug then
    --     --     object:bindBehavior("RangeEditorBehavior")
    --     -- end

    else
        assert(false, string.format("Map:newObject() - invalid classId %s", tostring(classId)))
    end

    return object
end



return ObjectFactory