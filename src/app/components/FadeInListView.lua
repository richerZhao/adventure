-- start --

--------------------------------
-- 此列表用于
-- @function [parent=#FadeInListVeiw] addItemFront
-- @param node listItem 要添加的项
-- @return UIListView#UIListView 

-- end --

local FadeInListVeiw = class("FadeInListVeiw", cc.ui.UIListView)

-- start --

--------------------------------
-- 在列表最前端添加一项
-- @function [parent=#FadeInListVeiw] addItemFront
-- @param node listItem 要添加的项
-- @return FadeInListVeiw#FadeInListVeiw 

-- end --

function FadeInListVeiw:addItemFront(listItem)
	self:modifyItemSizeIf_(listItem)
	for i=#self.items_,1,-1 do
		self.items_[i + 1] = self.items_[i]	
	end
	
	self.items_[1] = listItem
	self.container:addChild(listItem)
	self:reload(true)
	return self
end

-- start --

--------------------------------
-- 加载列表
-- @function [parent=#FadeInListVeiw] reload
-- @param bool lastFadeIn 是否需要最后一个元素淡入动画
-- @return FadeInListVeiw#FadeInListVeiw 

-- end --

function FadeInListVeiw:reload(lastFadeIn)
	self:layout_(lastFadeIn)
	return self
end


-- start --

--------------------------------
-- 列表布局
-- @function [parent=#FadeInListVeiw] layout_
-- @param bool lastFadeIn 是否需要最后一个元素淡入动画
-- @return FadeInListVeiw#FadeInListVeiw 

-- end --

function FadeInListVeiw:layout_(lastFadeIn)
	local width, height = 0, 0
	local itemW, itemH = 0, 0
	local margin

	-- calcate whole width height
	width = self.viewRect_.width

	for i,v in ipairs(self.items_) do
		itemW, itemH = v:getItemSize()
		itemW = itemW or 0
		itemH = itemH or 0
		height = height + itemH
	end

	self:setActualRect({x = self.viewRect_.x,
		y = self.viewRect_.y,
		width = width,
		height = height})
	self.size.width = width
	self.size.height = height

	local tempWidth, tempHeight = width, height
	itemW, itemH = 0, 0

	local content
	for i,v in ipairs(self.items_) do
		itemW, itemH = v:getItemSize()
		itemW = itemW or 0
		itemH = itemH or 0
			
		content = v:getContent()
		content:setAnchorPoint(0.5, 0.5)
		self:setPositionByAlignment_(content, itemW, itemH, v:getMargin())

		if not lastFadeIn then 
			tempHeight = tempHeight - itemH
			v:setPosition(self.viewRect_.x,
				self.viewRect_.y + tempHeight)
		else
			v:setPosition(self.viewRect_.x,
				self.viewRect_.y + tempHeight)
			if i == 1 then
				content:setOpacity(0)
				content:fadeIn(1)
				v:setPosition(self.viewRect_.x,
					self.viewRect_.y + height)
			end
			tempHeight = tempHeight - itemH
			v:moveTo(1, self.viewRect_.x,
				self.viewRect_.y + tempHeight)
		end
		

		
	end
	self.container:setPosition(0, self.viewRect_.height - self.size.height)
end

return FadeInListVeiw