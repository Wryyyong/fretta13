local HudLayout = {}
AccessorFunc(HudLayout,"Spacing","Spacing")

function HudLayout:Init()
	self.Items = {}
	self:SetSpacing(8)
	self:SetPaintBackgroundEnabled(false)
	self:SetPaintBorderEnabled(false)
	self:ParentToHUD()
end

-- This makes it so that it's behind chat & hides when you're in the menu
-- But it also removes the ability to click on it. So override it if you want to.
function HudLayout:ChooseParent()
	self:ParentToHUD()
end

function HudLayout:Clear(bDelete)
	local items = self.Items

	for idx,panel in ipairs(items) do
		if not (panel and panel:IsValid()) then continue end

		panel:SetParent(panel)
		panel:SetVisible(false)

		if not bDelete then continue end
		panel:Remove()
		items[idx] = nil
	end
end

function HudLayout:AddItem(item,relative,pos)
	if not (item and item:IsValid()) then return end

	item.HUDPos = pos
	relative = relative
	item:SetVisible(true)
	item:SetParent(self)

	local items = self.Items
	items[#items + 1] = item

	self:InvalidateLayout()
end

function HudLayout:PositionItem(item)
	if item.Positioned then return end

	local relative = item.HUDrelative
	local relativeIsValid = IsValid(relative)

	if relativeIsValid and item ~= relative then
		self:PositionItem(relative)
	end

	local spacing,pos = self:GetSpacing(),item.HUDPos
	item:InvalidateLayout(true)

	if
		pos == 9
	or	pos == 8
	or	pos == 7
	then
		if relativeIsValid then
			item:MoveAbove(relative,spacing)
		else
			item:AlignTop()
		end
	end

	if
		pos == 6
	or	pos == 5
	or	pos == 4
	then
		if relativeIsValid then
			item.y = relative.y
		else
			item:CenterVertical()
		end
	end

	if
		pos == 3
	or	pos == 2
	or	pos == 1
	then
		if relativeIsValid then
			item:MoveBelow(relative,spacing)
		else
			item:AlignBottom()
		end
	end

	if
		pos == 7
	or	pos == 4
	or	pos == 1
	then
		if relativeIsValid then
			item.x = relative.x
		else
			item:AlignLeft()
		end
	end

	if
		pos == 8
	or	pos == 5
	or	pos == 2
	then
		if relativeIsValid then
			item.x = relative.x + (relative:GetWide() - item:GetWide()) * 0.5
		else
			item:CenterHorizontal()
		end
	end

	if
		pos == 9
	or	pos == 6
	or	pos == 3
	then
		if relativeIsValid then
			item.x = relative.x + relative:GetWide() - item:GetWide()
		else
			item:AlignRight()
		end
	end

	if relativeIsValid then
		if pos == 4 then
			item:MoveLeftOf(relative,spacing)
		elseif pos == 6 then
			item:MoveRightOf(relative,spacing)
		end
	end

	item.Positioned = true
end

function HudLayout:Think()
	self:InvalidateLayout()
end

function HudLayout:PerformLayout()
	self:SetPos(32,32)
	self:SetWide(ScrW() - 64)
	self:SetTall(ScrH() - 64)

	local items = self.Items

	for _,item in ipairs(items) do
		item.Positioned = false
	end

	for _,item in ipairs(items) do
		self:PositionItem(item)
	end
end

derma.DefineControl("DHudLayout","A HUD Layout Base",HudLayout,"Panel")
