--[[
	skin.lua - Fretta Derma Skin
	-----------------------------------------------------
	This is the default Fretta skin for Derma. If you want to override the look of Fretta,
	base a skin of this and change GM.HudSkin.
--]]

local surface = surface
local draw = draw
local Color = Color

local SKIN = {
	["PrintName"] = "",
	["Author"] = "",
	["DermaVersion"] = 1,

	["bg_color"] = Color(100,100,100),
	["bg_color_sleep"] = Color(70,70,70),
	["bg_color_dark"] = Color(50,50,50),
	["bg_color_bright"] = Color(220,220,220),

	["fontFrame"] = "Default",

	["control_color"] = Color(180,180,180),
	["control_color_highlight"] = Color(220,220,220),
	["control_color_active"] = Color(110,150,255),
	["control_color_bright"] = Color(255,200,100),
	["control_color_dark"] = Color(100,100,100),

	["bg_alt1"] = Color(50,50,50),
	["bg_alt2"] = Color(55,55,55),

	["listview_hover"] = Color(70,70,70),
	["listview_selected"] = Color(100,170,220),

	["text_bright"] = color_white,
	["text_normal"] = Color(180,180,180),
	["text_dark"] = Color(20,20,20),
	["text_highlight"] = Color(255,20,20),

	["texGradientUp"] = Material("gui/gradient_up"),
	["texGradientDown"] = Material("gui/gradient_down"),

	["panel_transback"] = Color(255,255,255,50),
	["tooltip"] = Color(255,245,175),
	["colPropertySheet"] = Color(170,170,170),

	["colTabInactive"] = Color(170,170,170,155),
	["colTabShadow"] = Color(60,60,60),
	["colTabText"] = color_white,
	["colTabTextInactive"] = Color(0,0,0,155),

	["fontTab"] = "Default",
	["colCollapsibleCategory"] = Color(255,255,255,20),

	["colCategoryText"] = color_white,
	["colCategoryTextInactive"] = Color(200,200,200),

	["fontCategoryHeader"] = "TabLarge",
	["colNumberWangBG"] = Color(255,240,150),

	["colTextEntryBG"] = Color(240,240,240),
	["colTextEntryBorder"] = Color(20,20,20),
	["colTextEntryText"] = Color(20,20,20),
	["colTextEntryTextHighlight"] = Color(20,200,250),
	["colTextEntryTextHighlight"] = Color(20,200,250),

	["colMenuBG"] = Color(255,255,255,200),
	["colMenuBorder"] = Color(0,0,0,200),

	["colButtonText"] = Color(0,0,0,250),
	["colButtonTextDisabled"] = Color(0,0,0,100),

	["colButtonBorder"] = Color(20,20,20),
	["colButtonBorderHighlight"] = Color(255,255,255,50),
	["colButtonBorderShadow"] = Color(0,0,0,100),

	["fontButton"] = "Default",

	-- basic deathmsg appearance settings
	["deathMessageBackgroundCol"] = Color(46,43,42,220),
	["deathMessageBackgroundLocal"] = Color(75,75,75,200), -- this is the colour that the background is when the local player is involved in the deathmsg, so it stands out.
	["deathMessageActionColor"] = Color(200,200,200),
}
SKIN.combobox_selected = SKIN.listview_selected
SKIN.colTab = SKIN.colPropertySheet

-- enum for draw order
DM_ORDER_LATESTATTOP = 1
DM_ORDER_LATESTATBOTTOM = 2

local matBlurScreen = Material("pp/blurscreen")

--[[---------------------------------------------------------
   DrawGenericBackground
---------------------------------------------------------]]--
function SKIN:DrawGenericBackground(x,y,w,h,color)
	draw.RoundedBox(4,x,y,w,h,color)
end

--[[---------------------------------------------------------
   DrawLinedButtonBorder
---------------------------------------------------------]]--
function SKIN:DrawLinedButtonBorder(x,y,w,h)
	surface.SetDrawColor(0,0,0,200)
	surface.DrawOutlinedRect(x + 1,y + 1,w - 2,h - 2)
end

--[[---------------------------------------------------------
	Button
---------------------------------------------------------]]--
function SKIN:PaintCancelButton(panel)
	if not panel.m_bBackground then return end

	local col = self.control_color
	if panel:GetDisabled() then
		col = self.control_color_dark
	elseif panel.Depressed then
		col = self.control_color_active
	elseif panel.Hovered then
		col = self.control_color_highlight
	end

	if panel.m_colBackground then
		col = table.Copy(panel.m_colBackground)

		if panel:GetDisabled() then
			col.r = math.Clamp(col.r * 0.7,0,255)
			col.g = math.Clamp(col.g * 0.7,0,255)
			col.b = math.Clamp(col.b * 0.7,0,255)
			col.a = 20
		elseif panel.Depressed then
			col.r = math.Clamp(col.r + 100,0,255)
			col.g = math.Clamp(col.g + 100,0,255)
			col.b = math.Clamp(col.b + 100,0,255)
		elseif panel.Hovered then
			col.r = math.Clamp(col.r + 30,0,255)
			col.g = math.Clamp(col.g + 30,0,255)
			col.b = math.Clamp(col.b + 30,0,255)
		end
	end

	surface.SetDrawColor(col.r,col.g,col.b,col.a)

	panel:DrawFilledRect()
end

SKIN.PaintSelectButton = SKIN.PaintCancelButton
function SKIN:PaintOverCancelButton(panel)
	local w,h = panel:GetSize()

	if not panel.m_bBorder then return end
	self:DrawLinedButtonBorder(0,0,w,h,panel.Depressed)
end

SKIN.PaintOverSelectButton = SKIN.PaintOverCancelButton

local function SchemeButton(skin,panel)
	panel:SetFontInternal("FRETTA_SMALL")
	panel:SetTextColor(panel:GetDisabled() and skin.colButtonTextDisabled or skin.colButtonText)

	DLabel.ApplySchemeSettings(panel)
end

SKIN.SchemeCancelButton = SchemeButton
SKIN.SchemeSelectButton = SchemeButton

--[[---------------------------------------------------------
	ListViewLine
---------------------------------------------------------]]--
function SKIN:PaintListViewLine()
end

--[[---------------------------------------------------------
	ListViewLine
---------------------------------------------------------]]--
function SKIN:PaintListView()
end

--[[---------------------------------------------------------
	ListViewLabel
---------------------------------------------------------]]--
function SKIN:PaintScorePanelHeader()
	--(panel)
	--surface.SetDrawColor(panel.cTeamColor)
	--panel:DrawFilledRect()
end

local BoxHeight = 21
local ColorPlyAlive = Color(60,60,60)
local ColorPlyLocal = Color(90,90,90)
local ColorPlyDefault = Color(70,70,70)
--[[---------------------------------------------------------
	ListViewLabel
---------------------------------------------------------]]--
function SKIN:PaintScorePanelLine(panel)
	local ply,tall,color = panel.pPlayer,panel:GetTall()

	if not (IsValid(ply) and ply:Alive()) then
		color = ColorPlyAlive
	end

	if ply == LocalPlayer() then
		color = ColorPlyLocal
	end

	color = color or ColorPlyDefault

	draw.RoundedBox(4,0,tall * 0.5 - BoxHeight * 0.5,panel:GetWide(),BoxHeight,color)
end

local ColorScorePanel = Color(200,200,200,150)
--[[---------------------------------------------------------
	PaintScorePanel
---------------------------------------------------------]]--
function SKIN:PaintScorePanel(panel)
	surface.SetMaterial(matBlurScreen)
	surface.SetDrawColor(255,255,255)

	local x,y = panel:LocalToScreen(0,0)
	--matBlurScreen:SetFloat("$blur",3)
	matBlurScreen:SetFloat("$blur",5)

	render.UpdateScreenEffectTexture()
	surface.DrawTexturedRect(x * -1,y * -1,ScrW(),ScrH())

	draw.RoundedBox(8,0,8,panel:GetWide(),panel:GetTall() - 8,ColorScorePanel)
end

--[[---------------------------------------------------------
	LayoutTeamScoreboardHeader
---------------------------------------------------------]]--
function SKIN:LayoutTeamScoreboardHeader(panel)
	local teamName,teamScore = panel.TeamName,panel.TeamScore

	teamName:StretchToParent(0,0,0,0)
	teamName:SetTextInset(8,0)
	teamName:SetColor(color_white)
	teamName:SetFontInternal("FRETTA_MEDIUM")

	teamScore:StretchToParent(0,0,0,0)
	teamScore:SetContentAlignment(6)
	teamScore:SetTextInset(8,0)
	teamScore:SetColor(color_white)
	teamScore:SetFontInternal("FRETTA_MEDIUM")
end

function SKIN:PaintTeamScoreboardHeader(panel)
	local color = team.GetColor(panel.iTeamID)

	draw.RoundedBox(4,0,0,panel:GetWide(),panel:GetTall() * 2,color)
end

function SKIN:SchemeScorePanelLabel(panel)
	--panel:SetTextColor(GAMEMODE:GetTeamColor(panel.pPlayer))
	panel:SetTextColor(color_white)
	panel:SetFontInternal("FRETTA_MEDIUM_SHADOW")
end

function SKIN:PaintScorePanelLabel(panel)
	panel:SetAlpha((IsValid(panel.pPlayer) and panel.pPlayer:Alive()) and 125 or 255)
end

function SKIN:SchemeScorePanelHeaderLabel(panel)
	panel:SetTextColor(ColorPlyDefault)
	panel:SetFontInternal("HudSelectionText")
end

function SKIN:SchemeSpectatorInfo(panel)
	panel:SetTextColor(color_white)
	panel:SetFontInternal("FRETTA_SMALL")
end

local ColorScoreHeader = Color(50,90,160)
--[[---------------------------------------------------------
	ScoreHeader
---------------------------------------------------------]]--
function SKIN:PaintScoreHeader(panel)
	draw.RoundedBox(8,0,0,panel:GetWide(),panel:GetTall() * 2,ColorScoreHeader)
end

function SKIN:LayoutScoreHeader(panel)
	local hostName,gamemodeName = panel.HostName,panel.GamemodeName

	hostName:SizeToContents()
	hostName:SetPos(0,0)
	hostName:CenterHorizontal()

	gamemodeName:SizeToContents()
	gamemodeName:MoveBelow(panel.HostName,0)
	gamemodeName:CenterHorizontal()

	panel:SetTall(gamemodeName.y + gamemodeName:GetTall() + 4)
end

function SKIN:SchemeScoreHeader(panel)
	local hostName,gamemodeName = panel.HostName,panel.GamemodeName

	hostName:SetTextColor(color_white)
	hostName:SetFontInternal("FRETTA_LARGE_SHADOW")

	gamemodeName:SetTextColor(color_white)
	gamemodeName:SetFontInternal("FRETTA_MEDIUM_SHADOW")
end

local ColorNoticeHighlightOn = Color(90,90,90,200)
local ColorNoticeHighlightOff = Color(20,20,20,190)
--[[---------------------------------------------------------
	DeathMessages
---------------------------------------------------------]]--
function SKIN:PaintGameNotice(panel)
	local color = panel.m_bHighlight and ColorNoticeHighlightOn or ColorNoticeHighlightOff

	draw.RoundedBox(4,0,0,panel:GetWide(),panel:GetTall(),color)
end

function SKIN:SchemeGameNoticeLabel(panel)
	panel:SetFontInternal("FRETTA_NOTIFY")
	DLabel.ApplySchemeSettings(panel)
end

local ColorGamemodeButtonDefault = Color(255,255,255,10)
local ColorGamemodeButtonDisabled = Color(0,0,0,10)
local ColorGamemodeButtonDepressed = Color(255,255,255,50)
local ColorGamemodeButtonHovered = Color(255,255,255,20)
--[[---------------------------------------------------------
	GamemodeButton
---------------------------------------------------------]]--
function SKIN:PaintGamemodeButton(panel)
	local w,h = panel:GetSize()
	local color = ColorGamemodeButtonDefault

	if panel:GetDisabled() then
		color = ColorGamemodeButtonDisabled
	elseif panel.Depressed then
		color = ColorGamemodeButtonDepressed
	elseif panel.Hovered then
		color = ColorGamemodeButtonHovered
	end

	if panel.bgColor ~= nil then
		color = panel.bgColor
	end

	draw.RoundedBox(4,0,0,w,h,color)
end

function SKIN:SchemeGamemodeButton(panel)
	panel:SetTextColor(color_white)
	panel:SetFontInternal("FRETTA_MEDIUM_SHADOW")
	panel:SetContentAlignment(4)
	panel:SetTextInset(8,0)
end

local ColorPanelButtonDefault = Color(160,160,160)
local ColorPanelButtonDisabled = Color(100,100,100)
local ColorPanelButtonDepressed = Color(150,210,255)
local ColorPanelButtonHovered = Color(200,200,200)
--[[---------------------------------------------------------
	PanelButton
---------------------------------------------------------]]--
function SKIN:PaintPanelButton(panel)
	local color = ColorPanelButtonDefault

	if panel:GetDisabled() then
		color = ColorPanelButtonDisabled
	elseif panel.Depressed then
		color = ColorPanelButtonDepressed
	elseif panel.Hovered then
		color = ColorPanelButtonHovered
	end

	if panel.bgColor ~= nil then
		color = panel.bgColor
	end

	surface.SetDrawColor(color)

	panel:DrawFilledRect()
end

function SKIN:PaintOverPanelButton(panel)
	local w,h = panel:GetSize()

	self:DrawLinedButtonBorder(0,0,w,h,panel.Depressed)
end

derma.DefineSkin("SimpleSkin","",SKIN)
