local ObjectBase = require("app.ObjectBase")


local Building = class("Building",ObjectBase)

function Organism:ctor(id,state,map)
	assert(state.defineId ~= nil, "Organism:ctor() - invalid state.defineId")
	local define = OrganismProperties.get(state.defineId)
    for k, v in pairs(define) do
        if state[k] == nil then
            state[k] = v
        end
    end

    Organism.super.ctor(self, id, state, map)

    self.radiusOffsetX_ = checkint(self.radiusOffsetX_)
    self.radiusOffsetY_ = checkint(self.radiusOffsetY_)
    self.radius_        = checkint(self.radius_)
    self.flipSprite_    = checkbool(self.flipSprite_)
    self.campId_        = checkint(self.campId_)
    self.visible_       = true
    self.valid_         = true
    self.sprite_        = nil
    self.spriteSize_    = nil
    self.moveLocked_    = 0  --移动向敌人/任务地点的锁
    self.fightLocked_   = 0  --攻击敌人的锁


    self.isMoveObject = true
    self.actions_ = {}

end






return Building