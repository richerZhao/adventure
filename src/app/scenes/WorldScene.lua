local WorldScene = class("WorldScene", function()
    return display.newScene("MainScene")
end)

function WorldScene:ctor()
	self.map = display.newTilesSprite("bgTile.png",cc.rect(0, 0, display.width * 2, display.height * 2))
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
        return self:onTouch(event, event.x, event.y)
    end)
    self.touchLayer:setTouchEnabled(true)

    -- 创建player批渲染结点
    self.playerNode = display.newBatchNode("player.png", 100000)
    self:addChild(self.playerNode)

    display.addSpriteFrames("player.plist", "player.png")

    local frames = display.newFrames("player_f0006_walk_1_%02d.png",1,8)
    self.sprite = display.newSprite(frames[1], display.cx, display.cy)
    self.sprite:setFlippedX(true)
    self.playerNode:addChild(self.sprite, 100)
end

function WorldScene:onEnter()

end

function WorldScene:onExit()

end

function WorldScene:onTouch(event,x,y)
	-- event.name 是触摸事件的状态：began, moved, ended, cancelled
    -- event.x, event.y 是触摸点当前位置
    -- event.prevX, event.prevY 是触摸点之前的位置
	if event.name == "moved" then
		self.isMoved_ = true
		print("x="..x..",y="..y..",event.prevX="..event.prevX..",event.prevY="..event.prevY)
		local nowX = self.map:getPositionX() + event.prevX - x
		local nowY = self.map:getPositionY() + event.prevY - y
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
    	else
    		-- 创建动画
    		local frames = display.newFrames("player_f0006_walk_1_%02d.png",1,8)
		    local animation = display.newAnimation(frames, 1 / 8)
		    -- 播放动画
		    self.sprite:playAnimationForever(animation)
    		self.sprite:moveTo(5, event.x, event.y)
    	end
	end

	return true
end

return WorldScene

