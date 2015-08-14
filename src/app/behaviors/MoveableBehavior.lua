local BehaviorBase = require("app.behaviors.BehaviorBase")
local MoveableBehavior = class("MoveableBehavior", BehaviorBase)

MoveableBehavior.MOVING_STATE_STOPPED   = 0
MoveableBehavior.MOVING_STATE_MOVED   	= 1

function MoveableBehavior:ctor()
	MoveableBehavior.super.ctor(self,"MoveableBehavior",nil,1)
end

function MovableBehavior:getMoveDirection(object)
    local x1,y1,x2,y2 =  object.x_, object.y_, object.nextX_, object.nextY_;
    local x = math.abs(x1 - x2);
    local y = math.abs(y1 - y2);
    if x > y then
        if x1 > x2 then
            return MOVELEFT; 
        else
            return MOVERIGHT; 
        end
    else
        if y1 < y2 then
            return MOVEUP; 
        else
            return MOVEDOWN; 
        end
    end
end

function MoveableBehavior:bind(object)
	object.speed_ 						= 0
	object.moveState_ 					= 0
	object.paths_				 		= nil	--寻路的路径点
	object.pathIndex_				 	= 0		--当前的路径点序号
	object.moveAction_				 	= nil	--移动动作
	object.moveFrames_				 	= nil	--移动帧
	object.direction_					= 0


	local function isMoving(object)
		return object.moveState_ == MoveableBehavior.MOVING_STATE_MOVED
	end
	object:bindMethod(self, "isMoving", isMoving)

	local function startMove(object)
		object.moveState_ = MoveableBehavior.MOVING_STATE_MOVED
		local animation = display.newAnimation(object.moveFrames_,1/8)
		object.moveAction_ = transition.playAnimationForever(animation)
	end
	object:bindMethod(self, "startMove", startMove)

	local function stopMove(object)
		object.moveState_ = MoveableBehavior.MOVING_STATE_STOPPED
		object.paths_ = nil
		object.pathIndex_ = 0
		if object.moveAction_ then
			transition.removeAction(object.moveAction_)
		end
	end
	object:bindMethod(self, "stopMove", stopMove)

	local function onDirectionChange(object)
		transition.removeAction(object.moveAction_)
		if object.direction_ == MOVEDOWN then
		elseif object.direction_ == MOVELEFT then
		elseif object.direction_ == MOVERIGHT then
		elseif object.direction_ == MOVEUP then
		end

	end

	local function tick(object, dt)
		if object.moveState_ == MoveableBehavior.MOVING_STATE_STOPPED then return end
		if not object.paths_ then return end
		local path = object.paths_[object.pathIndex_]
		if not path then
			stopMove(object)
			return 
		end

		local moveDis = object.speed_ * dt
		local duration
		while moveDis > 0 do
			if object.x_ == path.x and object.y_ == path.y then
				object.pathIndex_ = object.pathIndex_ + 1
				path = object.pathIndex_[object.pathIndex_]
				if not path then
					stopMove(object)
					return
				end
			else
				if object.x_ ~= path.x then
					duration = math.abs(object.x_ - path.x)
					if duration >= moveDis then
						if object.x_ < path.x then
							object.direction_ == MOVERIGHT
							object.x_ = object.x_ + moveDis
						else
							object.direction_ == MOVELEFT
							object.x_ = object.x_ - moveDis
						end
					else
						
					end
				elseif object.y_ ~= path.y then
					if object.x_ < path.x then

					else

					end
				else
					--todo
				end
			end
			

		end

		









	end
	object:bindMethod(self, "tick", tick)


	
	
end

function MoveableBehavior:unbind(object)

end

function MoveableBehavior:reset(object)
	object.speed_ 						= SPEED
	object.moveState_ 					= MOVING_STATE_STOPPED
	object.paths_				 		= nil
	object.pathIndex_				 	= 0
	object.direction_					= 0
end





return MoveableBehavior