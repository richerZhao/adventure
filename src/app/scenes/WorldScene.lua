-- import("app.components.searchpath")
-- import("app.components.monsterManager")
local WorldScene = class("WorldScene", function()
    return display.newScene("WorldScene")
end)

function WorldScene:ctor()
	self.map = cc.TMXTiledMap:create("map2.tmx")
	self.backGround_ = self.map:getLayer("backgroundLayer")
	self.obstacleLayer_ = self.map:getLayer("obstacleLayer")
	self:addChild(self.map)
	self.touchLayer = display.newLayer()
	self:addChild(self.touchLayer)
	display.addSpriteFrames("player.plist", "player.png")

	--注册怪物的出生点
	initMonsterManager(self.map)

	--注册NPC的出生点
	initNpcManager(self.map)
	
	-- 注册touch事件处理函数
    self.touchLayer:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
     	print("touch,event.name="..event.name)
        return self:onTouch(event)
    end)
    self.touchLayer:setTouchEnabled(true)

	addNpc(require("app.components.Npc").create({textureName="player_f0006_walk_1_01.png",scale=0.4,flippedX = true,playerName="player_f0006"}),"npc_gen_point_1")

	scheduler.scheduleGlobal(monsterAreaRun,10)
end

function WorldScene:onEnter()

end

function WorldScene:onExit()

end

function WorldScene:onTouch(event)
	-- event.name 是触摸事件的状态：began, moved, ended, cancelled
    -- event.x, event.y 是触摸点当前位置
    -- event.prevX, event.prevY 是触摸点之前的位置
	if event.name == "moved" then
		self.isMoved_ = true
		local nowX = self.map:getPositionX() + event.prevX - event.x
		local nowY = self.map:getPositionY() + event.prevY - event.y
		if nowX >= 0 then
			nowX = 0
		end


		if nowX <= display.width - self.map:getContentSize().width then
			nowX = display.width - self.map:getContentSize().width
		end

		if nowY >= 0 then
			nowY = 0
		end

		if nowY <= display.height - self.map:getContentSize().height  then
			nowY = display.height - self.map:getContentSize().height
		end

		self.map:setPosition(nowX,nowY)
    elseif event.name == "ended" then
    	-- if self.isMoved_ then
    	-- 	self.isMoved_ = false
    	-- -- elseif self.isRoleMoved_ then

    	-- else
		   --  --如果触点在主角左边,则主角往左移,如果触点在主角右边,则主角往右移动
		   --  print("event.x="..event.x..",event.y="..event.y)
		   --  local mapPoint = self.map:convertToNodeSpace(cc.p(event.x,event.y))
		   --  print("mapPoint.x="..mapPoint.x..",mapPoint.y="..mapPoint.y)
		   --  print("spritePoint.x="..self.sprite:getPositionX()..",spritePoint.y="..self.sprite:getPositionY())
		   --  local lengthX = mapPoint.x - self.sprite:getPositionX()
		   --  local lengthY = mapPoint.y - self.sprite:getPositionY()
		   --  local moveX,moveY = 0,0
		   --  local direction
		   --  if math.abs(lengthX) >= math.abs(lengthY) then
		   --  	if lengthX < 0 then
		   --  		--向左移动一格
		   --  		direction = 3
		   --  		moveX = -32
		   --  	elseif lengthX > 0 then
		   --  		--向右移动一格
		   --  		direction = 4
		   --  		moveX = 32
		   --  	end
		   --  else
		   --  	if lengthY < 0 then
		   --  		--向下移动一格
		   --  		direction = 2
		   --  		moveY = -32
		   --  	elseif lengthY > 0 then
		   --  		--向上移动一格
		   --  		direction = 1
		   --  		moveY = 32
		   --  	end
		   --  end

		   --  self.sprite:moveToward(cc.p(event.x,event.y))
    	-- end
	end

	return true
end




return WorldScene

