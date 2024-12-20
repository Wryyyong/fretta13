g_Help = g_Help or nil

local cvFrettaVoting = GetConVar("fretta_voting")
local cvPlayerModel = GetConVar("cl_playermodel")
local cvPlayerColor = GetConVar("cl_playercolor")

local ColorGreen = Color(120,255,100)
local ColorYellow = Color(255,200,100)
local ColorGray = Color(200,200,200)

local function VoteForChange()
	RunConsoleCommand("voteforchange")
end

local function ChangeTeam()
	GAMEMODE:ShowTeam()
end

local function CreateModelPanel()
	local pnl = vgui.Create("DGrid")
	pnl:SetCols(6)
	pnl:SetColWide(66)
	pnl:SetRowHeight(66)

	for name,model in SortedPairs(player_manager.AllValidModels()) do
		local icon = vgui.Create("SpawnIcon")
		local wide,tall = icon:GetWide(),icon:GetTall()

		icon.DoClick = function()
			surface.PlaySound("ui/buttonclickrelease.wav")
			RunConsoleCommand("cl_playermodel",name)
		end

		icon.PaintOver = function()
			if cvPlayerModel:GetString() ~= name then return end

			surface.SetDrawColor(255,210 + math.sin(RealTime() * 10) * 40,0)
			surface.DrawOutlinedRect(4,4,wide - 8,tall - 8)
			surface.DrawOutlinedRect(3,3,wide - 6,tall - 6)
		end

		icon:SetModel(model)
		icon:SetSize(64,64)
		icon:SetTooltip(name)
		pnl:AddItem(icon)
	end

	return pnl
end

local function CreateColorPanel()
	local pnl = vgui.Create("DGrid")
	pnl:SetCols(10)
	pnl:SetColWide(36)
	pnl:SetRowHeight(128)

	for name,color in pairs(list.Get("PlayerColours")) do
		local icon = vgui.Create("DButton")
		local wide,tall = icon:GetWide(),icon:GetTall()

		icon:SetText("")

		icon.DoClick = function()
			surface.PlaySound("ui/buttonclickrelease.wav")

			RunConsoleCommand("cl_playercolor",name)
		end

		icon.Paint = function()
			surface.SetDrawColor(color)
			icon:DrawFilledRect()
		end

		icon.PaintOver = function()
			if cvPlayerColor:GetString() ~= name then return end

			surface.SetDrawColor(255,210 + math.sin(RealTime() * 10) * 40,0)
			surface.DrawOutlinedRect(4,4,wide - 8,tall - 8)
			surface.DrawOutlinedRect(3,3,wide - 6,tall - 6)
		end

		icon:SetSize(32,128)
		icon:SetTooltip(name)
		pnl:AddItem(icon)
	end

	return pnl
end

function GM:ShowHelp()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	if not IsValid(g_Help) then
		g_Help = vgui.CreateFromTable(vgui_Select)

		g_Help:SetHeaderText(self.Name or "Untitled Gamemode")
		g_Help:SetHoverText(self.Help or "No Help Avaliable")

		g_Help.lblFooterText.Think = function(panel)
			local tl = self:GetGameTimeLeft()
			if tl == -1 then return end

			if GetGlobalBool("IsEndOfGame",false) then
				panel:SetText("Game has ended...")

				return
			end

			if self.RoundBased and CurTime() > self:GetTimeLimit() then
				panel:SetText("Game will end after this round")

				return
			end

			panel:SetText("Time Left: " .. util.ToMinutesSeconds(tl))
		end

		if cvFrettaVoting:GetBool() then
			local btn = g_Help:AddSelectButton("Vote For Change",VoteForChange)

			btn.m_colBackground = ColorYellow
			btn:SetDisabled(ply:GetNWBool("WantsVote"))
		end

		if self.TeamBased then
			local btn = g_Help:AddSelectButton("Change Team",ChangeTeam)

			btn.m_colBackground = ColorGreen
		end

		local teamID = ply:Team()

		if not self.TeamBased and self.AllowSpectating then
			local btnString,newTeam,colBackground

			if teamID == TEAM_SPECTATOR then
				btnString = "Join Game"
				newTeam = TEAM_UNASSIGNED
				colBackground = ColorGreen
			else
				btnString = "Spectate"
				newTeam = TEAM_SPECTATOR
				colBackground = ColorGray
			end

			local btn = g_Help:AddSelectButton(btnString,function()
				RunConsoleCommand("changeteam",newTeam)
			end)

			btn.m_colBackground = colBackground
		end

		local Classes = team.GetClass(teamID)

		if Classes and #Classes > 1 then
			local btn = g_Help:AddSelectButton("Change Class",function()
				self:ShowClassChooser(teamID)
			end)

			btn.m_colBackground = ColorGreen
		end

		g_Help:AddCancelButton()

		if self.SelectModel then
			g_Help:AddPanelButton("icon16/user.png","Choose Player Model",CreateModelPanel)
		end

		if self.SelectColor then
			g_Help:AddPanelButton("icon16/application_view_tile.png","Choose Player Color",CreateColorPanel)
		end
	end

	g_Help:MakePopup()
	g_Help:NoFadeIn()
end

net.Receive("ShowHelp",function()
	if not GAMEMODE then return end

	GAMEMODE:ShowHelp()
end)
