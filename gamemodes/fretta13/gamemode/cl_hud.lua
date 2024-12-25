g_ObserveMode = g_ObserveMode or OBS_MODE_NONE
g_RoundResult = g_RoundResult or TEAM_UNASSIGNED
g_Team = g_Team or TEAM_CONNECTING

function GM:AddHUDItem(item,pos,parent)
	g_VGUI_HudScreen:AddItem(item,parent,pos)
end

function GM:HUDNeedsUpdate()
	local ply = LocalPlayer()

	if not IsValid(ply) then
		return false
	end

	local plyAlive = ply:Alive()
	local plyTeam = ply:Team()

	return
		g_Class ~= ply:GetNWString("Class","Default")
	or	g_Alive ~= plyAlive
	or	g_Team ~= plyTeam
	or	g_WaitingToRespawn ~= (
			ply:GetNWFloat("RespawnTime",0) > CurTime()
		and	plyTeam ~= TEAM_SPECTATOR
		and	not plyAlive
	)
	or	g_InRound ~= GetGlobalBool("InRound",false)
	or	g_RoundResult ~= GetGlobalInt("RoundResult",TEAM_UNASSIGNED)
	or	g_RoundWinner ~= GetGlobalEntity("RoundWinner",nil)
	or	g_IsObserver ~= ply:IsObserver()
	or	g_ObserveMode ~= ply:GetObserverMode()
	or	g_ObserveTarget ~= ply:GetObserverTarget()
	or	g_InVote ~= self:InGamemodeVote()
end

function GM:OnHUDUpdated()
	local ply = LocalPlayer()

	if not IsValid(ply) then
		return false
	end

	local plyAlive = ply:Alive()
	local plyTeam = ply:Team()

	g_Class = ply:GetNWString("Class","Default")
	g_Alive = plyAlive
	g_Team = plyTeam

	g_WaitingToRespawn =
		ply:GetNWFloat("RespawnTime",0) > CurTime()
	and	plyTeam ~= TEAM_SPECTATOR
	and	not plyAlive

	g_InRound = GetGlobalBool("InRound",false)
	g_RoundResult = GetGlobalInt("RoundResult",TEAM_UNASSIGNED)
	g_RoundWinner = GetGlobalEntity("RoundWinner",nil)
	g_IsObserver = ply:IsObserver()
	g_ObserveMode = ply:GetObserverMode()
	g_ObserveTarget = ply:GetObserverTarget()
	g_InVote = self:InGamemodeVote()
end

function GM:OnHUDPaint()
end

function GM:RefreshHUD()
	if not self:HUDNeedsUpdate() then return end

	self:OnHUDUpdated()

	if IsValid(g_VGUI_HudScreen) then
		g_VGUI_HudScreen:Remove()
	end

	g_VGUI_HudScreen = vgui.Create("DHudLayout")

	if g_InVote then return end

	if
		IsValid(g_RoundWinner)
	or	g_RoundResult ~= TEAM_UNASSIGNED
	then
		self:UpdateHUD_RoundResult()
	elseif g_IsObserver then
		self:UpdateHUD_Observer(g_WaitingToRespawn,g_InRound,g_ObserveMode,g_ObserveTarget)
	elseif not g_Alive then
		self:UpdateHUD_Dead(g_WaitingToRespawn,g_InRound)
	else
		self:UpdateHUD_Alive(g_InRound)
	end
end

function GM:HUDPaint()
	self.BaseClass:HUDPaint()

	self:OnHUDPaint()
	self:RefreshHUD()
end

function GM:UpdateHUD_RoundResult()
	local txt = GetGlobalString("RRText")
	local resultType = type(g_RoundResult)

	if txt == "" then
		if resultType == "number" and (team.GetAllTeams()[g_RoundResult]) then
			local teamName = team.GetName(g_RoundResult)

			if teamName then
				txt = teamName .. " Wins!"
			end
		elseif resultType == "Player" and IsValid(g_RoundResult) then
			txt = g_RoundResult:GetName() .. " Wins!"
		end
	end

	local respawnTxt = vgui.Create("DHudElement")
	respawnTxt:SizeToContents()
	respawnTxt:SetText(txt)

	self:AddHUDItem(respawnTxt,8)
end

function GM:UpdateHUD_Observer()
	local col,lbl,txt = color_white

	if IsValid(g_ObserveTarget) and g_ObserveTarget:IsPlayer() and g_ObserveTarget ~= LocalPlayer() and g_ObserveMode ~= OBS_MODE_ROAMING then
		lbl = "SPECTATING"
		txt = g_ObserveTarget:GetName()
		col = team.GetColor(g_ObserveTarget:Team())
	end

	if g_ObserveMode == OBS_MODE_DEATHCAM or g_ObserveMode == OBS_MODE_FREEZECAM then
		txt = "You Died!" -- were killed by?
	end

	if txt then
		local txtLabel = vgui.Create("DHudElement")
		txtLabel:SetText(txt)

		if lbl then
			txtLabel:SetLabel(lbl)
		end

		txtLabel:SetTextColor(col)
		self:AddHUDItem(txtLabel,2)
	end

	self:UpdateHUD_Dead(g_WaitingToRespawn,g_InRound)
end

local function GetRespawnTimer()
	return LocalPlayer():GetNWFloat("RespawnTime",0)
end

local function GetRoundTimer()
	local roundStartTime = GetGlobalFloat("RoundStartTime",0)

	return roundStartTime > CurTime() and roundStartTime or GetGlobalFloat("RoundEndTime")
end

local function GetRoundNumber()
	return GetGlobalInt("RoundNumber",0)
end

local function GetTeamName()
	return team.GetName(LocalPlayer():Team())
end

local function GetTeamColor()
	return team.GetColor(LocalPlayer():Team())
end

function GM:UpdateHUD_Dead()
	if not g_InRound and self.RoundBased then
		local respawnTxt = vgui.Create("DHudElement")
		respawnTxt:SizeToContents()
		respawnTxt:SetText("Waiting for round start")

		self:AddHUDItem(respawnTxt,8)
	elseif g_WaitingToRespawn then
		local respawnTimer = vgui.Create("DHudCountdown")
		respawnTimer:SizeToContents()
		respawnTimer:SetLabel("SPAWN IN")
		respawnTimer:SetValueFunction(GetRespawnTimer)

		self:AddHUDItem(respawnTimer,8)
	elseif g_InRound then
		local roundTimer = vgui.Create("DHudCountdown")
		roundTimer:SizeToContents()
		roundTimer:SetValueFunction(GetRoundTimer)
		roundTimer:SetLabel("TIME")

		self:AddHUDItem(roundTimer,8)
	elseif g_Team ~= TEAM_SPECTATOR and not g_Alive then
		local respawnTxt = vgui.Create("DHudElement")
		respawnTxt:SizeToContents()
		respawnTxt:SetText("Press Fire to Spawn")

		self:AddHUDItem(respawnTxt,8)
	end
end

function GM:UpdateHUD_Alive()
	if not (self.RoundBased or self.TeamBased) then return end

	local hudBar = vgui.Create("DHudBar")
	self:AddHUDItem(hudBar,2)

	if self.TeamBased and self.ShowTeamName then
		local teamIndicator = vgui.Create("DHudUpdater")
		teamIndicator:SizeToContents()
		teamIndicator:SetValueFunction(GetTeamName)
		teamIndicator:SetColorFunction(GetTeamColor)
		teamIndicator:SetFont("HudSelectionText")

		hudBar:AddItem(teamIndicator)
	end

	if self.RoundBased then
		local roundNumber = vgui.Create("DHudUpdater")
		roundNumber:SizeToContents()
		roundNumber:SetLabel("ROUND")
		roundNumber:SetValueFunction(GetRoundNumber)

		local roundTimer = vgui.Create("DHudCountdown")
		roundTimer:SizeToContents()
		roundTimer:SetValueFunction(GetRoundTimer)
		roundTimer:SetLabel("TIME")

		hudBar:AddItem(roundNumber)
		hudBar:AddItem(roundTimer)
	end
end

-- to do or to override, your choice
function GM:UpdateHUD_AddedTime()
end

net.Receive("RoundAddedTime",function()
	if not GAMEMODE then return end

	GAMEMODE:UpdateHUD_AddedTime(net.ReadFloat())
end)
