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
    self.direction_     = nil
    -- self.framesTime_    =0.8
    -- if self.direction_ == nil then
        -- self.direction_ = MOVEDOWN;
    -- end
    self.isMoveObject = true
    self.actions_ = {}

end

function Organism:createOrganismSprite(modelName)
    local moveAnimations = {}
    local idleAnimations = {}
    local fightAnimations = {}
    self:release()
    self.moveAnimations_ = moveAnimations
    self.idleAnimations_ = idleAnimations
    self.fightAnimations_ = fightAnimations
   
    local moveFrames = display.newFrames(modelName .. "_walk_1_%02d.png",1,8)
    local firstFrame = moveFrames[1]
    local moveAnimation = display.newAnimation(moveFrames,1/8)
    local idleFrames = display.newFrames(modelName .. "_stand_1_%02d.png",1,4)
    local idleAnimation = display.newAnimation(idleFrames,1/4)
    local fightFrames = display.newFrames(modelName .. "_dance_a_1_%02d.png",1,8)
    local fightAnimation = display.newAnimation(fightFrames,1/8)
    for i=1,4 do
    	moveAnimation:retain()
    	table.insert(self.moveAnimations_,moveAnimation)
    	idleAnimation:retain()
    	table.insert(self.idleAnimations_,idleAnimation)
    	fightAnimation:retain()
    	table.insert(self.fightAnimations_,fightAnimation)
    end

    return display.newSprite(firstFrame)

end

function Organism:setDirection(direction)
    if direction ~= self.direction_ and direction <=4 and direction>=1 then
        -- if self.sprite_ then
        --    self:playAnimationForever(direction);
        --    -- self.sprite_:stopAllActions();
        --    -- self.sprite_:playAnimationForever(self.moveAnimations_[direction]);
        -- end 
        self:onDirectionChange(direction,self.direction_);
        self.direction_ = direction;
    end
end

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
    batch:addChild(self.sprite_);
    self:setDirection(MOVEDOWN);
end

function Organism:release()
    if self.moveAnimations_ then
        for i,v in ipairs(self.moveAnimations_) do
            if v then
                v:release();
            end
        end
        self.moveAnimations_ = nil;
    end
    if self.idleAnimation_ then
        for i,v in ipairs(self.idleAnimation_) do
            if v then
                v:release();
            end
        end
        self.idleAnimation_ = nil;
    end
    if self.fightAnimation_ then
        for i,v in ipairs(self.fightAnimation_) do
            if v then
                v:release();
            end
        end
        self.fightAnimation_ = nil;
    end
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

function Organism:onDirectionChange()
	if self.direction_ ~= MOVELEFT then
		self:setFlipSprite(true)
	else
		self:setFlipSprite(false)
	end

end

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