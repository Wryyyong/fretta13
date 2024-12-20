local SelectScreen = {}

local ColorBtnCancelFG = Color(0,0,0,200)

local function BtnCancelDoClick(btnCancel)
	btnCancel:GetParent():Remove()
end

--[[---------------------------------------------------------
   Init
---------------------------------------------------------]]--
function SelectScreen:Init()
	self:SetText("")
	self.Buttons = {}
	self.BottomButtons = {}

	self:SetSkin(GAMEMODE.HudSkin)

	local pnlButtons = vgui.Create("DPanelList",self)
	self.pnlButtons = pnlButtons
	pnlButtons:SetPadding(10)
	pnlButtons:SetSpacing(10)
	pnlButtons:SetPaintBackground(false)
	pnlButtons:EnableVerticalScrollbar()

	local lblMain = vgui.Create("DLabel",self)
	self.lblMain = lblMain
	lblMain:SetText(GAMEMODE.Name)
	lblMain:SetFont("FRETTA_HUGE")
	lblMain:SetColor(color_white)

	local pnlMain = vgui.Create("DPanelList",self)
	self.pnlMain = pnlMain
	pnlMain:SetNoSizing(true)
	pnlMain:SetPaintBackground(false)
	pnlMain:EnableVerticalScrollbar()

	local btnCancel = vgui.Create("DButton",self)
	self.btnCancel = btnCancel
	btnCancel:SetText("#Close")
	btnCancel:SetSize(100,30)
	btnCancel:SetFGColor(ColorBtnCancelFG)
	btnCancel:SetFont("FRETTA_SMALL")
	btnCancel.DoClick = BtnCancelDoClick
	btnCancel:SetVisible(false)

	Derma_Hook(btnCancel,"Paint","Paint","CancelButton")
	Derma_Hook(btnCancel,"PaintOver","PaintOver","CancelButton")
	Derma_Hook(btnCancel,"ApplySchemeSettings","Scheme","CancelButton")
	Derma_Hook(btnCancel,"PerformLayout","Layout","CancelButton")

	local lblHoverText = vgui.Create("DLabel",self)
	self.lblHoverText = lblHoverText
	lblHoverText:SetText("")
	lblHoverText:SetFont("FRETTA_MEDIUM")
	lblHoverText:SetColor(color_white)
	lblHoverText:SetContentAlignment(8)
	lblHoverText:SetWrap(true)

	local lblFooterText = vgui.Create("DLabel",self)
	self.lblFooterText = lblFooterText
	lblFooterText:SetText("")
	lblFooterText:SetFont("FRETTA_MEDIUM")
	lblFooterText:SetColor(color_white)
	lblFooterText:SetContentAlignment(8)
	lblFooterText:SetWrap(false)

	pnlMain:AddItem(lblFooterText)
	self:PerformLayout()
	self.OpenTime = SysTime()
end

function SelectScreen:NoFadeIn()
	self.OpenTime = 0
end

local function PanelBtnDoClick(btn)
	local panel = btn:GetParent()

	if not btn.pPanel then
		btn.pPanel = btn.pPanelFnc()
		btn.pPanel:SetParent(panel.pnlMain)
		btn.pPanel:SetVisible(false)
		btn.pPanelFnc = nil
	end

	-- Toggle off
	if btn.m_bSelected then
		panel:ClearSelectedPanel()

		return
	end

	panel:ClearSelectedPanel()
	btn.m_bSelected = true

	panel.pnlMain:Clear()
	btn.pPanel:SetVisible(true)
	panel.pnlMain:AddItem(btn.pPanel)
end

--[[---------------------------------------------------------
   AddPanelButton
---------------------------------------------------------]]--
function SelectScreen:AddPanelButton(icon,title,pnlfnc)
	local btn = vgui.Create("DImageButton",self)
	btn:SetImage(icon)
	btn:SetTooltip(title)
	btn:SetSize(30,30)
	btn:SetVisible(true)
	btn.pPanelFnc = pnlfnc
	btn.pPanel = nil
	btn:SetStretchToFit(false)

	Derma_Hook(btn,"Paint","Paint","PanelButton")
	Derma_Hook(btn,"PaintOver","PaintOver","PanelButton")
	--Derma_Hook(btn,"ApplySchemeSettings","Scheme","PanelButton")
	--Derma_Hook(btn,"PerformLayout","Layout","PanelButton")

	btn.DoClick = PanelBtnDoClick

	local bottomButtons = self.BottomButtons
	bottomButtons[#bottomButtons + 1] = btn

	return btn
end

function SelectScreen:ClearSelectedPanel()
	self.pnlMain:Clear()
	self.pnlMain:AddItem(self.lblHoverText)

	for _,btn in pairs(self.BottomButtons) do
		btn.m_bSelected = false

		if not IsValid(btn.pPanel) then continue end
		btn.pPanel:SetVisible(false)
	end
end

--[[---------------------------------------------------------
   SetHeaderText
---------------------------------------------------------]]--
function SelectScreen:SetHeaderText(strName)
	self.lblMain:SetText(strName)
end

--[[---------------------------------------------------------
   SetHeaderText
---------------------------------------------------------]]--
function SelectScreen:SetHoverText(strName)
	self.lblHoverText:SetText(strName or "")
end

--[[---------------------------------------------------------
   SetHeaderText
---------------------------------------------------------]]--
function SelectScreen:GetHoverText()
	return self.lblHoverText:GetValue()
end

local function SelectBtnOnCursorExited(btn)
	btn:SetHoverText(btn.OldHoverText)
	btn.OldHoverText = nil
end

--[[---------------------------------------------------------
  AddSelectButton
---------------------------------------------------------]]--
function SelectScreen:AddSelectButton(strName,ahFunc,txt)
	local btn = vgui.Create("DButton",self.pnlButtons)
	btn:SetText(strName)
	btn:SetSize(200,30)
	btn.DoClick = function()
		ahFunc()
		surface.PlaySound(Sound("buttons/lightswitch2.wav"))
		self:Remove()
	end

	Derma_Hook(btn,"Paint","Paint","SelectButton")
	Derma_Hook(btn,"PaintOver","PaintOver","SelectButton")
	Derma_Hook(btn,"ApplySchemeSettings","Scheme","SelectButton")
	Derma_Hook(btn,"PerformLayout","Layout","SelectButton")

	if txt then
		btn.OnCursorEntered = function()
			self.OldHoverText = self:GetHoverText()
			self:SetHoverText(txt)
		end

		btn.OnCursorExited = SelectBtnOnCursorExited
	end

	self.pnlButtons:AddItem(btn)

	local buttons = self.Buttons
	buttons[#buttons + 1] = btn

	return btn
end

--[[---------------------------------------------------------
   SetHeaderText
---------------------------------------------------------]]--
function SelectScreen:AddSpacer(h)
	local btn = vgui.Create("Panel",self)
	btn:SetSize(200,h)

	local buttons = self.Buttons
	buttons[#buttons + 1] = btn

	return btn
end

--[[---------------------------------------------------------
   SetHeaderText
---------------------------------------------------------]]--
function SelectScreen:AddCancelButton()
	self.btnCancel:SetVisible(true)
end

local CenterHeight = 250

--[[---------------------------------------------------------
   PerformLayout
---------------------------------------------------------]]--
function SelectScreen:PerformLayout()
	local pnlMain = self.pnlMain
	local btnCancel = self.btnCancel
	local pnlButtons = self.pnlButtons
	local lblMain = self.lblMain
	local lblHoverText = self.lblHoverText
	local lblFooterText = self.lblFooterText

	local scrW,scrH = ScrW(),ScrH()
	local centerX,centerY = scrW * 0.5,scrH * 0.5
	local innerWidth = 640
	local innerWidthHalf = innerWidth * 0.5
	local btnCancelTall = btnCancel:GetTall() - 20
	local pnlButtonsWide = pnlButtons:GetWide()

	self:SetSize(scrW,scrH)

	pnlMain:SetSize(
		innerWidth - pnlButtonsWide - 10,
		400
	)
	pnlMain:SetPos(
		pnlButtons.x + pnlButtonsWide + 10,
		pnlButtons.y
	)

	pnlButtons:SetSize(
		210,
		CenterHeight * 2 - btnCancelTall - 40
	)
	pnlButtons:SetPos(
		centerX - innerWidthHalf,
		(centerY - CenterHeight) + 20
	)

	btnCancel:SetPos(
		centerX + innerWidthHalf - btnCancel:GetWide(),
		centerY + CenterHeight - btnCancelTall
	)

	lblMain:SizeToContents()
	lblMain:SetPos(
		centerX - lblMain:GetWide() * 0.5,
		centerY - CenterHeight - lblMain:GetTall() * 1.2
	)

	lblHoverText:SetSize(
		300,
		300
	)
	lblHoverText:SetPos(
		centerX - innerWidthHalf + 50,
		centerY - 150
	)

	lblFooterText:SetSize(
		scrW,
		30
	)
	lblFooterText:SetPos(
		0,
		centerY + CenterHeight + 10
	)

	local x = pnlButtons.x

	for _,btn in ipairs(self.BottomButtons) do
		btn:SetPos(
			x,
			centerY + CenterHeight - btn:GetTall() - 20
		)

		x = x + btn:GetWide() + 8
	end
end

--[[---------------------------------------------------------
   Paint
---------------------------------------------------------]]--
function SelectScreen:Paint()
	local scrW = ScrW()
	local centerY = ScrH() * 0.5

	Derma_DrawBackgroundBlur(self,self.OpenTime)
	surface.SetDrawColor(0,0,0,200)
	surface.DrawRect(
		0,
		centerY - CenterHeight,
		scrW,
		CenterHeight * 2
	)
	surface.DrawRect(
		0,
		centerY - CenterHeight - 4,
		scrW,
		2
	)
	surface.DrawRect(
		0,
		centerY + CenterHeight + 2,
		scrW,
		2
	)

	GAMEMODE:PaintSplashScreen(self:GetWide(),self:GetTall())
end

vgui_Select = vgui.RegisterTable(SelectScreen,"DPanel")
g_TeamPanel = g_TeamPanel or nil

function GM:ShowTeam()
	if not IsValid(g_TeamPanel) then
		g_TeamPanel = vgui.CreateFromTable(vgui_Select)
		g_TeamPanel:SetHeaderText("Choose Team")

		local allTeams = team.GetAllTeams()
		for teamID,teamInfo in SortedPairs(allTeams) do
			if
				teamID == TEAM_CONNECTING
			or	teamID == TEAM_UNASSIGNED
			or	(self.AllowSpectating and teamID == TEAM_SPECTATOR)
			or	not team.Joinable(teamID)
			then continue end

			if teamID == TEAM_SPECTATOR then
				g_TeamPanel:AddSpacer(10)
			end

			local strName = teamInfo.Name

			local btn = g_TeamPanel:AddSelectButton(strName,function()
				RunConsoleCommand("changeteam",teamID)
			end)

			btn.m_colBackground = teamInfo.Color

			btn.Think = function()
				btn:SetText(Format("%s (%i)",strName,team.NumPlayers(teamID)))
				btn:SetDisabled(GAMEMODE:TeamHasEnoughPlayers(teamID))
			end

			local ply = LocalPlayer()
			if not (IsValid(ply) and ply:Team() == teamID) then continue end
			btn:SetDisabled(true)
		end

		g_TeamPanel:AddCancelButton()
	end

	g_TeamPanel:MakePopup()
end

net.Receive("ShowTeam",function()
	if not GAMEMODE then return end

	GAMEMODE:ShowTeam()
end)
