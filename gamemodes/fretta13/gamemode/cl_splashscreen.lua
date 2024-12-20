local SplashScreen = {}

local function PanelDoClick(panel)
	RunConsoleCommand("seensplash")
	panel:Remove()
end

--[[---------------------------------------------------------
   Init
---------------------------------------------------------]]--
function SplashScreen:Init()
	self:SetText("")
	self.DoClick = PanelDoClick

	self:SetSkin(GAMEMODE.HudSkin)

	local lblGamemodeName = vgui.Create("DLabel",self)
	self.lblGamemodeName = lblGamemodeName
	lblGamemodeName:SetText(GAMEMODE.Name)
	lblGamemodeName:SetFont("FRETTA_LARGE")
	lblGamemodeName:SetColor(color_white)

	local lblGamemodeAuthor = vgui.Create("DLabel",self)
	self.lblGamemodeAuthor = lblGamemodeAuthor
	lblGamemodeAuthor:SetText("by " .. GAMEMODE.Author)
	lblGamemodeAuthor:SetFont("FRETTA_MEDIUM")
	lblGamemodeAuthor:SetColor(color_white)

	local lblServerName = vgui.Create("DLabel",self)
	self.lblServerName = lblServerName
	lblServerName:SetText(GetHostName())
	lblServerName:SetFont("FRETTA_MEDIUM")
	lblServerName:SetColor(color_white)

	local lblIP = vgui.Create("DLabel",self)
	self.lblIP = lblIP
	lblIP:SetText("0.0.0.0")
	lblIP:SetFont("FRETTA_MEDIUM")
	lblIP:SetColor(color_white)

	self:PerformLayout()
	self.FadeInTime = RealTime()
end

local cvIP = GetConVar("ip")

--[[---------------------------------------------------------
   PerformLayout
---------------------------------------------------------]]--
function SplashScreen:PerformLayout()
	local lblGamemodeName = self.lblGamemodeName
	local lblGamemodeAuthor = self.lblGamemodeAuthor
	local lblServerName = self.lblServerName
	local lblIP = self.lblIP

	local scrW,scrH = ScrW(),ScrH()
	local centerX = scrW * 0.5
	local centerY = scrH * 0.5
	local lblGamemodeAuthorTall = lblGamemodeAuthor:GetTall()

	self:SetSize(scrW,scrH)

	lblGamemodeName:SizeToContents()
	lblGamemodeName:SetPos(
		centerX - lblGamemodeName:GetWide() * 0.5,
		centerY - 200 - lblGamemodeName:GetTall() - lblGamemodeAuthorTall
	)

	lblGamemodeAuthor:SizeToContents()
	lblGamemodeAuthor:SetPos(
		centerX - lblGamemodeAuthor:GetWide() * 0.5,
		centerY - 200 - lblGamemodeAuthorTall
	)

	lblServerName:SizeToContents()
	lblServerName:SetPos(
		100,
		centerY + 200
	)

	lblIP:SetText(cvIP:GetString())
	lblIP:SizeToContents()
	lblIP:SetPos(
		self:GetWide() - 100 - lblIP:GetWide(),
		centerY + 200
	)
end

--[[---------------------------------------------------------
   Paint
---------------------------------------------------------]]--
function SplashScreen:Paint()
	local centerY = ScrH() * 0.5
	local wide,tall = self:GetWide(),self:GetTall()
	local fadeTime = RealTime() - self.FadeInTime

	Derma_DrawBackgroundBlur(self)

	if fadeTime < 3 then
		fadeTime = 1 - fadeTime / 3

		surface.SetDrawColor(0,0,0,fadeTime * 255)
		surface.DrawRect(0,0,wide,tall)
	end

	surface.SetDrawColor(0,0,0,200)
	surface.DrawRect(
		0,
		0,
		wide,
		centerY - 180
	)

	local centerYBump = centerY + 180
	surface.DrawRect(
		0,
		centerYBump,
		wide,
		tall - centerYBump
	)

	GAMEMODE:PaintSplashScreen(wide,tall)
end

vgui_Splash = vgui.RegisterTable(SplashScreen,"DButton")

function GM:ShowSplash()
	local pnl = vgui.CreateFromTable(vgui_Splash)
	pnl:MakePopup()
end

-- Customised splashscreen render here (The center bit!)
function GM:PaintSplashScreen()
end
