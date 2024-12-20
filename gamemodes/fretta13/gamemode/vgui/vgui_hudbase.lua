surface.CreateLegacyFont("Trebuchet MS",32,800,true,false,"FHUDElement")

local HudBase = {}
AccessorFunc(HudBase,"m_bPartOfBar","PartOfBar")

function HudBase:Init()
	self:SetText("-")
	self:SetTextColor(self:GetDefaultTextColor())
	self:SetFont("FHUDElement")
	self:ChooseParent()
end

-- This makes it so that it's behind chat & hides when you're in the menu
-- But it also removes the ability to click on it. So override it if you want to.
function HudBase:ChooseParent()
	self:ParentToHUD()
end

function HudBase:GetPadding()
	return 16
end

function HudBase:GetDefaultTextColor()
	return color_white
end

local ColorYellow = Color(255,255,0)

function HudBase:GetTextLabelColor()
	return ColorYellow
end

function HudBase:GetTextLabelFont()
	return "HudSelectionText"
end

local ColorBox = Color(0,0,0,100)
function HudBase:Paint()
	if self.m_bPartOfBar then return end

	draw.RoundedBox(4,0,0,self:GetWide(),self:GetTall(),ColorBox)
end

derma.DefineControl("HudBase","A HUD Base Element (override to change the style)",HudBase,"DLabel")
