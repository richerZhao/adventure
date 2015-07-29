local WorldScene = class("WorldScene", function()
    return display.newScene("MainScene")
end)

function WorldScene:ctor()
	-- self.map = display.newTilesSprite("bgTile.png",cc.rect(0, 0, display.width * 2, display.height * 2))
	self.map = cc.TMXTiledMap:create("map.tmx")
	self.backGround_ = self.map:getLayer("backgroundLayer")
	self:addChild(self.map)
	self.touchLayer = display.newLayer()
	self:addChild(self.touchLayer)

	-- 注册touch事件处理函数
    self.touchLayer:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
    	-- if event.name == "began" then
     --    	self.touchBagenX = event.x
     --    elseif event.name == "ended" then
     --    	if event.x - self.touchBagenX > display.width / 5 then
     --    		app:enterScene("LeftScene")
     --    	end
     --    end
     	print("touch,event.name="..event.name)
        return self:onTouch(event)
    end)
    self.touchLayer:setTouchEnabled(true)


    --添加主角
    -- self.roleLayer = display.newLayer():addTo(self,10)
    self.sprite = display.newSprite("Player2.png",16,208)
	
    self:addChild(self.sprite)


    for i=0,99 do
    	for j=0,99 do
    		local gid = self.backGround_:getTileAt({i,j})
    		if gid then
    			print("x="..i..",y="..j.."gid="..gid)
    		end
    	end
    end


    -- 创建player批渲染结点
    -- self.playerNode = display.newBatchNode("player.png", 100000)
    -- self:addChild(self.playerNode)

    -- display.addSpriteFrames("player.plist", "player.png")

    -- local frames = display.newFrames("player_f0006_walk_1_%02d.png",1,8)
    -- self.sprite = display.newSprite(frames[1], display.cx, display.cy)
    -- self.sprite:setFlippedX(true)
    -- self.playerNode:addChild(self.sprite, 100)
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
		print("x="..event.x..",y="..event.y..",event.prevX="..event.prevX..",event.prevY="..event.prevY)
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

		print("nowX="..nowX..",nowY="..nowY)
		self.map:setPosition(nowX,nowY)
    elseif event.name == "ended" then
    	if self.isMoved_ then
    		self.isMoved_ = false
    	-- elseif self.isRoleMoved_ then

    	else
		    --如果触点在主角左边,则主角往左移,如果触点在主角右边,则主角往右移动
		    local lengthX = event.x - self.sprite:getPositionX()
		    local lengthY = event.y - self.sprite:getPositionY()
		    local moveX,moveY = 0,0
		    if math.abs(lengthX) >= math.abs(lengthY) then
		    	if lengthX < 0 then
		    		--向左移动一格
		    		moveX = -32
		    	elseif lengthX > 0 then
		    		--向右移动一格
		    		moveX = 32
		    	end
		    else
		    	if lengthY < 0 then
		    		--向下移动一格
		    		moveY = -32
		    	elseif lengthY > 0 then
		    		--向上移动一格
		    		moveY = 32
		    	end
		    end

		    local moveToX = self.sprite:getPositionX() + moveX
		    local moveToY = self.sprite:getPositionY() + moveY
		    local tiledX = math.modf(moveToX/self.map:getTileSize().width)
		    local tiledY = math.modf(((self.map:getMapSize().height * self.map:getTileSize().height ) - moveToY) / self.map:getTileSize().height) 
		    print("tiledX="..tiledX.."tiledY="..tiledY)
		    local gid = self.backGround_:getTileAt({tiledX,tiledY})
		    dump(gid,"gid",gid)

		    self:playerMoveOn(self.sprite, self.map, moveX, moveY)
		    
    	end
	end

	return true
end

function WorldScene:playerMoveOn(player,background,x,y)
	local isMoveRole = true
	if x ~= 0 then
		if player:getPositionX() >= display.width / 2 then
			isMoveRole = false
		end
	elseif y ~= 0 then
		if player:getPositionY() >= display.height / 2 then
			isMoveRole = false
		end
	end

	if isMoveRole then
		player:moveBy(1, x, y)
	else
		background:moveBy(1, -x, -y)
	end
end


return WorldScene

