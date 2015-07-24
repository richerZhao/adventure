
local LeftScene = class("LeftScene", function()
    return display.newScene("LeftScene")
end)

local FadeInListView = require("app.components.FadeInListView")

function LeftScene:ctor()
end

function LeftScene:onEnter()
	self.layer = cc.LayerColor:create(cc.c4b(0,0,0,255),display.width,display.height):pos(0, 0):addTo(self)
	cc.ui.UILabel.new({text="冒险者列表",size=30,color=display.COLOR_WHITE}):align(display.CENTER, display.cx, display.top - 40):addTo(self.layer)
    self.contentList = FadeInListView.new {
	        bgScale9 = true,
	        viewRect = cc.rect(10, 10, display.width - 20, display.height / 4),
	        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
        }
        -- :onTouch(handler(self, self.touchListener))
        :addTo(self.layer)
    self.contentList:setAlignment(display.LEFT_TO_RIGHT)
    for i,v in ipairs(GameData.showLabelStrings) do
    	addListViewContent(v,self.contentList)
    end
    self.contentList:reload()
end

function LeftScene:onExit()

end

function LeftScene:touchListener(event)
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

function LeftScene:initSence()


end

return LeftScene
