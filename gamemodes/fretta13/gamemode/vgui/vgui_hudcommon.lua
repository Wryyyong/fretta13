--[[---------------------------------------------------------
   Name: HudBar
---------------------------------------------------------]]--
local HudBar = {}
AccessorFunc(HudBar,"m_Items","Items")
AccessorFunc(HudBar,"m_Horizontal","Horizontal")
AccessorFunc(HudBar,"m_Spacing","Spacing")
AccessorFunc(HudBar,"m_AlignBottom","AlignBottom")
AccessorFunc(HudBar,"m_AlignCenter","AlignCenter")

function HudBar:Init()
	self.m_Items = {}
	self:SetHorizontal(true)
	self:SetText("")
	self:SetAlignCenter(true)
	self:SetSpacing(8)
end

function HudBar:AddItem(item)
	local items = self.m_Items

	item:SetParent(self)
	items[#items + 1] = item
	self:InvalidateLayout()
	item:SetPaintBackgroundEnabled(false)
	item.m_bPartOfBar = true
end

function HudBar:PerformLayout()
	if not self.m_Horizontal then return end

	local x = self.m_Spacing
	local tallest = 0

	for _,item in ipairs(self.m_Items) do
		item:SetPos(x,0)
		x = x + item:GetWide() + self.m_Spacing
		tallest = math.max(tallest,item:GetTall())

		if self.m_AlignBottom then
			item:AlignBottom()
		end

		if self.m_AlignCenter then
			item:CenterVertical()
		end
	end

	self:SetSize(x,tallest)
end

derma.DefineControl("DHudBar","",HudBar,"HudBase")

--[[---------------------------------------------------------
   Name: HudUpdater
---------------------------------------------------------]]--
local HudUpdater = {}
AccessorFunc(HudUpdater,"m_ValueFunction","ValueFunction")
AccessorFunc(HudUpdater,"m_ColorFunction","ColorFunction")

function HudUpdater:Init()
end

function HudUpdater:GetTextValueFromFunction()
	if not self.m_ValueFunction then
		return "-"
	end

	return tostring(self:m_ValueFunction())
end

function HudUpdater:GetColorFromFunction()
	if not self.m_ColorFunction then
		return self:GetDefaultTextColor()
	end

	return self:m_ColorFunction()
end

function HudUpdater:Think()
	self:SetTextColor(self:GetColorFromFunction())
	self:SetText(self:GetTextValueFromFunction())
end

derma.DefineControl("DHudUpdater","A HUD Element",HudUpdater,"DHudElement")

--[[---------------------------------------------------------
   Name: HudCountdown
---------------------------------------------------------]]--
local HudCountdown = {}
AccessorFunc(HudCountdown,"m_Function","Function")

function HudCountdown:Init()
	HudBase.Init(self)
end

function HudCountdown:Think()
	if not self.m_ValueFunction then return end

	local curTime,endTime = CurTime(),self:m_ValueFunction()
	self:SetTextColor(self:GetColorFromFunction())

	if not endTime or endTime == -1 then
		return
	elseif endTime < curTime then
		self:SetText("00:00")

		return
	end

	local time = util.ToMinutesSeconds(endTime - curTime)
	self:SetText(time)
end

derma.DefineControl("DHudCountdown","A HUD Element",HudCountdown,"DHudUpdater")
