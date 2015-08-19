local BehaviorBase = require("app.behaviors.BehaviorBase")
local MoveableBehavior = class("MoveableBehavior", BehaviorBase)

MoveableBehavior.MOVING_STATE_STOPPED   = 0
MoveableBehavior.MOVING_STATE_MOVED   	= 1

function MoveableBehavior:ctor()
	MoveableBehavior.super.ctor(self,"MoveableBehavior",nil,1)
end

function MoveableBehavior:onDirectionChange(object)
	if object:isMoving() then
		if object.preDirection_ == object.direction_ then return end
		transition.removeAction(object.moveAction_)
		object.moveAction_ = nil
		if object.direction_ == MOVEDOWN then
		elseif object.direction_ == MOVELEFT then
			object.sprite_:setFlippedX(false)
		elseif object.direction_ == MOVERIGHT then
			object.sprite_:setFlippedX(true)
		elseif object.direction_ == MOVEUP then
		end
		local animation = display.newAnimation(object.moveFrames_[object.direction_],1/8)
		object.moveAction_ = object.sprite_:playAnimationForever(animation)
	end
end

function MoveableBehavior:bind(object)
	object.speed_ 						= 0
	object.moveState_ 					= 0
	object.paths_				 		= nil	--寻路的路径点
	object.pathIndex_				 	= 0		--当前的路径点序号
	object.moveAction_				 	= nil	--移动动作
	object.moveFrames_					= nil	--动画

	--初始化移动动作
	object.moveFrames_ = {}
	local moveFrames = display.newFrames(object.modelName_ .. "_walk_1_%02d.png",1,8)
	for i=1,4 do
    	table.insert(object.moveFrames_,moveFrames)
    end

	local function isMoving(object)
		if not object.paths_ then return false end
		if not object.paths_[object.pathIndex_] then return false end
		if object.moveState_ == MoveableBehavior.MOVING_STATE_STOPED then return false end
		return true
	end
	object:bindMethod(self, "isMoving", isMoving)

	local function startMove(object)
		object.moveState_ = MoveableBehavior.MOVING_STATE_MOVED
		if object:getDirection() > 0 then
			local animation = display.newAnimation(object.moveFrames_[object.direction_],1/8)
			object.moveAction_ = object.sprite_:playAnimationForever(animation)
		end
		
	end
	object:bindMethod(self, "startMove", startMove)

	local function stopMove(object)
		object.moveState_ = MoveableBehavior.MOVING_STATE_STOPPED
		object.paths_ = nil
		object.pathIndex_ = 0
		if object.moveAction_ then
			transition.removeAction(object.moveAction_)
			object.moveAction_ = nil
		end
	end
	object:bindMethod(self, "stopMove", stopMove)

	local function tick(object, dt)
		if not object.play_ or not object:isMoving() then return end
		local x,y,direction,pathIndex = object:getFuturePosition(dt)
		object:setPosition(x, y)
		object:setDirection(direction)
		object:setPathIndex(pathIndex)
		if object.pathIndex_ > #object.paths_ then object:stopMove() end
	end
	object:bindMethod(self, "tick", tick)

    local function getFuturePosition(object, time)
        local x, y, direction, pathIndex = object.x_, object.y_, object.direction_, object.pathIndex_
        local path = object.paths_[pathIndex]
		if not path then return x, y, direction, pathIndex end

		local moveDis = object.speed_ * time
		local duration
		while moveDis > 0 do
			if x == path.x and y == path.y then
				pathIndex = pathIndex + 1
				path = object.paths_[pathIndex]
				if not path then return x, y, direction, pathIndex end
			else
				if x ~= path.x then
					duration = math.abs(x - path.x)
					if duration >= moveDis then
						if x < path.x then
							direction = MOVERIGHT
							x = x + moveDis
						else
							direction = MOVELEFT
							x = x - moveDis
						end
						moveDis = 0
					else
						if x < path.x then
							direction = MOVERIGHT
							x = x + duration
						else
							direction = MOVELEFT
							x = x - duration
						end
						moveDis = moveDis - duration
					end
				else
					duration = math.abs(y - path.y)
					if duration >= moveDis then
						if y < path.y then
							direction = MOVEUP
							y = y + moveDis
						else
							direction = MOVEDOWN
							y = y - moveDis
						end
						moveDis = 0
					else
						if y < path.y then
							direction = MOVEUP
							y = y + duration
						else
							direction = MOVEDOWN
							y = y - duration
						end
						moveDis = moveDis - duration
					end
					
				end
			end
		end
        return x, y, direction, pathIndex
    end
    object:bindMethod(self, "getFuturePosition", getFuturePosition)

    local function setPath(object,paths)		
		object.paths_ = paths
		object.pathIndex_ = 1
    end
    object:bindMethod(self, "setPath", setPath)

    local function setPathIndex(object,pathIndex)
    	object.pathIndex_ = pathIndex
    end
    object:bindMethod(self, "setPathIndex", setPathIndex)

    self:reset(object)
end

function MoveableBehavior:unbind(object)
	object.moveFrames_ = nil

	object:unbindMethod(self, "isMoving")
	object:unbindMethod(self, "startMove")
	object:unbindMethod(self, "stopMove")
	object:unbindMethod(self, "tick")
	object:unbindMethod(self, "getFuturePosition")
	object:unbindMethod(self, "setPath")
	object:unbindMethod(self, "setPathIndex")
end

function MoveableBehavior:reset(object)
	object.speed_ 						= SPEED
	object.moveState_ 					= MOVING_STATE_STOPPED
	object.paths_				 		= nil
	object.pathIndex_				 	= 0
	object.moveAction_					= nil
end





return MoveableBehavior