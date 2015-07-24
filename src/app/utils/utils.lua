
function addListViewContentWithAction(text,listview)
	local item = listview:newItem()
    local content = cc.ui.UILabel.new(
        {text = text,
        size = 30,
        align = cc.ui.TEXT_ALIGN_LEFT,
        color = display.COLOR_WHITE,
        dimensions = cc.size(display.width - 20, 0)})
	item:addContent(content)
	item:setItemSize(display.width - 20, (display.height / 4) / 6 )
	listview:addItemFront(item)
	if not GameData.showLabelStrings then
		GameData.showLabelStrings = {}
	end
	table.insert(GameData.showLabelStrings,text)
end

function addListViewContent(text,listview)
	local item = listview:newItem()
    local content = cc.ui.UILabel.new(
        {text = text,
        size = 30,
        align = cc.ui.TEXT_ALIGN_LEFT,
        color = display.COLOR_WHITE,
        dimensions = cc.size(display.width - 20, 0)})
	item:addContent(content)
	item:setItemSize(display.width - 20, (display.height / 4) / 6 )
	listview:addItem(item)
end
