local BehaviorFactory = {}

local behaviorsClass = {
    MoveableBehavior          = require("app.behaviors.MoveableBehavior"),
    AttackBehavior            = require("app.behaviors.AttackBehavior"),
    IdleBehavior              = require("app.behaviors.IdleBehavior"),
    LifeBehavior              = require("app.behaviors.LifeBehavior"),
    SearchPathBehavior        = require("app.behaviors.SearchPathBehavior"),
    NpcBehavior               = require("app.behaviors.NpcBehavior"),
    MonsterBehavior           = require("app.behaviors.MonsterBehavior"),
    CureBehavior              = require("app.behaviors.CureBehavior"),
    -- CampBehavior               = require("game.map.behaviors.CampBehavior"),
    -- DecorateBehavior           = require("game.map.behaviors.DecorateBehavior"),
    -- BuildingBehavior           = require("game.map.behaviors.BuildingBehavior"),
    -- FireBehavior               = require("game.map.behaviors.FireBehavior"),
    -- MovableBehavior            = require("game.map.behaviors.MovableBehavior"),
    -- DestroyedBehavior          = require("game.map.behaviors.DestroyedBehavior"),
    -- TowerBehavior              = require("game.map.behaviors.TowerBehavior"),
    -- NPCBehavior                = require("game.map.behaviors.NPCBehavior"),

    -- PathEditorBehavior         = require("game.map.behaviors.PathEditorBehavior"),
    -- RangeEditorBehavior        = require("game.map.behaviors.RangeEditorBehavior"),
    -- StaticObjectEditorBehavior = require("game.map.behaviors.StaticObjectEditorBehavior"),

    -- ----------------------myc
    -- BloodBehavior              = require("game.map.behaviors.BloodBehavior"),
    -- RapidBehavior              = require("game.map.behaviors.RapidBehavior"),
    -- TowerDecorateBehavior      = require("game.map.behaviors.TowerDecorateBehavior"),
    
}

function BehaviorFactory.createBehavior(behaviorName)
	local class = behaviorsClass[behaviorName]
	assert(class ~= nil, string.format("BehaviorFactory.createBehavior() - Invalid behavior name \"%s\"", tostring(behaviorName)))
	return class.new()
end



return BehaviorFactory