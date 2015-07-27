
local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

local FadeInListView = require("app.components.FadeInListView")

function MainScene:ctor()
	print("MainScene:ctor()")
end

function MainScene:onEnter()
	print("MainScene:onEnter()")
	self.layer = cc.LayerColor:create(cc.c4b(0,0,0,255),display.width,display.height):pos(0, 0):addTo(self)
    self.contentList = FadeInListView.new {
	        bgScale9 = true,
	        viewRect = cc.rect(10, 10, display.width - 20, display.height / 4),
	        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
        }
        -- :onTouch(handler(self, self.touchListener))
        :addTo(self.layer)
    self.contentList:setAlignment(display.LEFT_TO_RIGHT)
    if not GameData.init then
    	local contents = {"这是剑与魔法的大陆,","大陆的边缘是未被发现的世界,","这片区域充满了危险，也存在巨大的财富,","好奇心驱使着冒险者们探索这里,","你建立了一个小镇为这些冒险者们提供帮助,","探索这未知的世界."}
    	self:addStringContentWithDelay(contents,1,self.initSence)
    else
    	for i,v in ipairs(GameData.showLabelStrings) do
    		addListViewContent(v,self.contentList)
    	end
    	self.contentList:reload()
    	self:initSence()
    end
end

function MainScene:onExit()
	print("MainScene:onExit()")
end

function MainScene:touchListener(event)
    local listView = event.listView
    if "clicked" == event.name then

    elseif "moved" == event.name then
        self.bListViewMove = true
    elseif "ended" == event.name then
        self.bListViewMove = false
    else
        print("event name:" .. event.name)
    end
end

function MainScene:addStringContentWithDelay(contents,i,callback)
	if i <= #contents then
		self:performWithDelay(function ()
				addListViewContentWithAction(contents[i],self.contentList)
				if i == #contents then
					callback(self)
				else
					i = i + 1
					self:addStringContentWithDelay(contents, i, callback)
				end 
			end, 1.0)
	end
end

function MainScene:initSence()
	-- local image = cc.ui.UIImage.new("background2.jpg", {scale9 = false}):align(display.CENTER, display.cx, display.height / 4 + 20):addTo(self.layer)
	-- image:size(display.width - 100, display.height / 4)
	local guildMallButton = cc.ui.UIPushButton.new("Button01.png",{scale9 = false})
		:setButtonSize(120, 60)
		:setButtonLabel("normal", cc.ui.UILabel.new({text="公会大厅",size=20,color=display.COLOR_BLACK}))
		:onButtonClicked(function()
			app:enterScene("WorldScene")
			end)
		:align(display.CENTER, 100 , display.top - 160)
		:addTo(self.layer)
	guildMallButton:setOpacity(0)
	guildMallButton:fadeIn(1)
	local title = cc.ui.UILabel.new({text="冒险小镇",size=30,color=display.COLOR_WHITE}):align(display.CENTER, display.cx, display.top - 40):addTo(self.layer)
	title:setOpacity(0)
	title:fadeIn(1)
	self:setTouchEnabled(true)
	self:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        -- event.name 是触摸事件的状态：began, moved, ended, cancelled
        -- event.x, event.y 是触摸点当前位置
        -- event.prevX, event.prevY 是触摸点之前的位置
        print(string.format("sprite: %s x,y: %0.2f, %0.2f", event.name, event.x, event.y))
        if event.name == "began" then
        	self.touchBagenX = event.x
        elseif event.name == "ended" then
        	if event.x - self.touchBagenX > display.width / 5 then
        		app:enterScene("LeftScene")
        	end
        end
        

        -- 返回 true 表示要响应该触摸事件，并继续接收该触摸事件的状态变化
        return true
    end)


	if not GameData.init then
		GameData.init = true
		-- saveData()
	end
end




return MainScene
