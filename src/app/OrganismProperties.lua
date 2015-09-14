
--[[--

定义了所有的静态对象

]]

local MapConstants = require("app.MapConstants")

local OrganismProperties = {}

local defines = {}


----------------------------------------

local npc = {
    classId       = "npc",
    modelName     = "player_f0006",
    radius        = 40,
    radiusOffsetY = 30,
    framesTime    = 0.25,
    scale         = 0.4,
    idleLastTime  = 1.5,
    hpSpriteOffsetY  = 32,
    maxHp         = 20,
    campId        = 1,
    flipSprite    = true,
    genAreaName   = "npc_gen_point_1",
    hatredRange   = 96,
    attackRange   = 32,
    attack        = 2,
    defence       = 1,
    cureTime      = 10,
    behaviors     = {"NpcBehavior"},
}

defines["npc"] = npc

local monster = {
    classId       = "monster",
    modelName     = "player_f0015",
    radius        = 40,
    radiusOffsetY = 30,
    framesTime    = 0.25,
    scale         = 0.4,
    idleLastTime  = 1.5,
    hpSpriteOffsetY  = 32,
    maxHp         = 10,
    campId        = 2,
    flipSprite    = true,
    hatredRange   = 64,
    attackRange   = 32,
    attack        = 5,
    defence       = 1,
    behaviors     = {"MonsterBehavior"},
}

defines["monster"] = monster

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