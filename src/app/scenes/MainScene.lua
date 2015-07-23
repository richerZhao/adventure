
local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

function MainScene:ctor()
	self.layer = cc.LayerColor:create(cc.c4b(0,0,0,255),display.width,display.height):pos(0, 0):addTo(self)
    self.contentList = cc.ui.UIListView.new {
	        bgScale9 = true,
	        viewRect = cc.rect(10, 10, display.width - 20, display.height / 4),
	        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
        }
        -- :onTouch(handler(self, self.touchListener))
        :addTo(self.layer)

    self.contentList:setAlignment(display.LEFT_TO_RIGHT)

	local item = self.contentList:newItem()
    local content = cc.ui.UILabel.new(
         	{text = "好奇心驱使着冒险者们探索这里好奇心驱使着冒险者们探索这里你建立了一个小镇为这些冒险者们提供帮助",
            size = 20,
            align = cc.ui.TEXT_ALIGN_LEFT,
            color = display.COLOR_WHITE,
            dimensions = cc.size(display.width - 20, 0)})
    item:addContent(content)
    item:setItemSize(display.width - 20, (display.height / 4)/6 )
    self.contentList:addItem(item)
    self.contentList:reload()
	
 --    self:performWithDelay(function ()
    	
 --    end, 1)

	-- self.lvH = cc.ui.UIListView.new {
 --        -- bgColor = cc.c4b(200, 200, 200, 120),
 --        -- bg = "sunset.png",
 --        bgScale9 = true,
 --        viewRect = cc.rect(10, 10, display.width - 20, display.height / 4),
 --        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL}
 --        :onTouch(handler(self, self.touchListener))
 --        :addTo(self)
 --    self.lvH:setAlignment(display.LEFT_TO_RIGHT)
 --    -- add items
 --    for i=1,1 do
 --        local item = self.lvH:newItem()
 --        local content
 --        if 1 == i then
 --            content = cc.ui.UILabel.new(
 --                    {text = "item"..i,
 --                    size = 20,
 --                    align = cc.ui.TEXT_ALIGN_CENTER,
 --                    color = display.COLOR_WHITE})
 --        elseif 3 == i then
 --            content = cc.ui.UILabel.new(
 --                    {text = "点击删除它"..i,
 --                    size = 20,
 --                    align = cc.ui.TEXT_ALIGN_CENTER,
 --                    color = display.COLOR_WHITE})
 --        elseif 4 == i then
 --            content = cc.ui.UILabel.new(
 --                    {text = "有背景图"..i,
 --                    size = 20,
 --                    align = cc.ui.TEXT_ALIGN_CENTER,
 --                    color = display.COLOR_WHITE})
 --            item:setBg("YellowBlock.png")
 --        else
 --            content = cc.ui.UILabel.new(
 --                    {text = "item"..i,
 --                    size = 20,
 --                    align = cc.ui.TEXT_ALIGN_CENTER,
 --                    color = display.COLOR_WHITE})
 --        end
 --        item:addContent(content)
 --        item:setItemSize(120, 80)

 --        self.lvH:addItem(item)
 --    end
 --    self.lvH:reload()
    

end

function MainScene:onEnter()

end

function MainScene:onExit()

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

-- function addStringContentWithDelay(contents,callback,1)
-- 	local i = 1
-- 	while i > #contents do
-- 		contents[i]

-- 	end
-- end


return MainScene
