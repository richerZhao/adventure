local OrganismProperties = require("app.OrganismProperties")
local ObjectBase = require("app.ObjectBase")

local Organism = class("Organism",ObjectBase)

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
    self.visible_       = true
    self.valid_         = true
    self.sprite_        = nil
    self.spriteSize_    = nil
    -- self.framesTime_    =0.8
    -- if self.direction_ == nil then
        -- self.direction_ = MOVEDOWN;
    -- end
    self.isMoveObject = true
    self.actions_ = {}

end

function Organism:createOrganismSprite(modelName)
    self:release()
   
    local moveFrames = display.newFrames(modelName .. "_walk_1_%02d.png",1,8)
    local firstFrame = moveFrames[1]
    return display.newSprite(firstFrame)

end

-- function Organism:setDirection(direction)
--     self.direction_ = direction
--     if self.behaviorObjects_ then 
--         for i,behavior in ipairs(self.behaviorObjects_) do
--             if behavior.onDirectionChange then
--                 behavior.onDirectionChange(self)
--             end
--         end
--     end
--     self.preDirection_ = self.direction_
-- end

function Organism:createView(batch, marksLayer, debugLayer)
	Organism.super.createView(self, batch, marksLayer, debugLayer)

    local modelName = self.modelName_
    if type(modelName) == "table" then
            modelName = modelName[1]
    end
    self.sprite_ = self:createOrganismSprite(modelName);
    local size = self.sprite_:getContentSize()
    self.spriteSize_ = {size.width, size.height}

    if self.scale_ then
        self.sprite_:setScale(self.scale_)
    end

    -- self.offsetY_ = self.spriteSize_[2]/2;
    self.sprite_:addNodeEventListener(cc.NODE_EVENT, function(event)
        if event.name == "exit" then
            self:release()
        end
    end)
    batch:addChild(self.sprite_)
    self:setDirection(MOVEDOWN)
end

function Organism:release()

end

function Organism:updateView()
    local sprite = self.sprite_
    sprite:setPosition(math.floor(self.x_ + self.offsetX_), math.floor(self.y_ + self.offsetY_))
    sprite:setFlippedX(self.flipSprite_)
end

function Organism:fastUpdateView()
    if not self.updated__ then return end
    local sprite = self.sprite_
    sprite:setPosition(self.x_ + self.offsetX_, self.y_ + self.offsetY_)
    sprite:setFlippedX(self.flipSprite_)
end

function Organism:isVisible()
    return self.visible_
end

function Organism:setVisible(visible)
    self.sprite_:setVisible(visible)
    self.visible_ = visible
end

function Organism:playAnimationForever(animationType,animID)
    self:stopAnimation()
    local action
    if animationType == "move" then
    	action = self.sprite_:playAnimationForever(self.moveAnimations_[animID])
    elseif animationType == "idle" then
    	action = self.sprite_:playAnimationForever(self.idleAnimations_[animID])
    elseif animationType == "fight" then
    	action = self.sprite_:playAnimationForever(self.fightAnimations_[animID])
    end
    self.actions_[#self.actions_ + 1] = action
end

function Organism:playAnimationOnce(animID)
    self:stopAnimation()
    local action = self.sprite_:playAnimationOnce(self.moveAnimations_[animID], true)()
    self.actions_[#self.actions_ + 1] = action
end

function Organism:stopAnimation()
    for i, action in ipairs(self.actions_) do
        if not tolua.isnull(action) then transition.removeAction(action) end
    end
    self.actions_ = {}
end

function Organism:preparePlay()
end

-- function Organism:onDirectionChange()
-- 	if self.direction_ ~= MOVELEFT then
-- 		self:setFlipSprite(true)
-- 	else
-- 		self:setFlipSprite(false)
-- 	end

-- end

function Organism:getDirection(direction)
    return self.direction_
end

function Organism:getDefineId()
    return self.defineId_
end

function Organism:getRadius()
    return self.radius_
end

function Organism:isFlipSprite()
    return self.flipSprite_
end

function Organism:setFlipSprite(flipSprite)
    self.flipSprite_ = flipSprite
end

function Organism:getView()
    return self.sprite_
end

return Organism