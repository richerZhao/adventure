
--[[--

定义了所有的静态对象

]]

local MapConstants = require("app.MapConstants")

local OrganismProperties = {}

local defines = {}


----------------------------------------

local object = {
    classId       = "organism",
    modelName     = "player_f0006",
    radius        = 40,
    radiusOffsetY = 30,
    framesTime    = 0.25,
    scale         = 0.4,
    idleLastTime  = 1.5,
    hpSpriteOffsetY  = 32,
    maxHp         = 100,
    campId        = 1,
    behaviors     = {"MoveableBehavior"},
}

defines["organism"] = object

----------------------------------------

function OrganismProperties.getAllIds()
    local keys = table.keys(defines)
    table.sort(keys)
    return keys
end

function OrganismProperties.get(defineId)
    assert(defines[defineId], string.format("OrganismProperties.get() - invalid defineId %s", tostring(defineId)))
    return clone(defines[defineId])
end

function OrganismProperties.isExists(defineId)
    return defines[defineId] ~= nil
end

return OrganismProperties