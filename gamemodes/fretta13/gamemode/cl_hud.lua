local HudScreen
local Alive = false
local Class
local Team = 0
local WaitingToRespawn = false
local InRound = false
local RoundResult = 0
local RoundWinner
local IsObserver = false
local ObserveMode = 0
local ObserveTarget
local InVote = false

function GM:AddHUDItem(item,pos,parent)
	HudScreen:AddItem(item,parent,pos)
end

function GM:HUDNeedsUpdate()
	local ply = LocalPlayer()
	if not IsValid(ply) then return false end

	local plyAlive = ply:Alive()
	local plyTeam = ply:Team()

	return
		ply:GetNWString("Class","Default") ~= Class
	or	Alive ~= plyAlive
	or	Team ~= plyTeam
	or	WaitingToRespawn ~= (
			ply:GetNWFloat("RespawnTime",0) > CurTime()
		and	plyTeam ~= TEAM_SPECTATOR
		and	not plyAlive
	)
	or	InRound ~= GetGlobalBool("InRound",false)
	or	RoundResult ~= GetGlobalInt("RoundResult",0)
	or	RoundWinner ~= GetGlobalEntity("RoundWinner",nil)
	or	IsObserver ~= ply:IsObserver()
	or	ObserveMode ~= ply:GetObserverMode()
	or	ObserveTarget ~= ply:GetObserverTarget()
	or	InVote ~= self:InGamemodeVote()
end

function GM:OnHUDUpdated()
	local ply = LocalPlayer()
	if not IsValid(ply) then return false end

	local plyAlive = ply:Alive()
	local plyTeam = ply:Team()

	Class = ply:GetNWString("Class","Default")
	Alive = plyAlive
	Team = plyTeam
	WaitingToRespawn =
		ply:GetNWFloat("RespawnTime",0) > CurTime()
	and	plyTeam ~= TEAM_SPECTATOR
	and	not plyAlive
	InRound = GetGlobalBool("InRound",false)
	RoundResult = GetGlobalInt("RoundResult",0)
	RoundWinner = GetGlobalEntity("RoundWinner",nil)
	IsObserver = ply:IsObserver()
	ObserveMode = ply:GetObserverMode()
	ObserveTarget = ply:GetObserverTarget()
	InVote = self:InGamemodeVote()
end

function GM:OnHUDPaint()
end

function GM:RefreshHUD()
	if not self:HUDNeedsUpdate() then return end
	self:OnHUDUpdated()

	if IsValid(HudScreen) then HudScreen:Remove() end
	HudScreen = vgui.Create("DHudLayout")

	if InVote then return end

	if
		RoundWinner and RoundWinner ~= NULL
	or	RoundResult ~= 0
	then
		self:UpdateHUD_RoundResult()
	elseif IsObserver then
		self:UpdateHUD_Observer(WaitingToRespawn,InRound,ObserveMode,ObserveTarget)
	elseif not Alive then
		self:UpdateHUD_Dead(WaitingToRespawn,InRound)
	else
		self:UpdateHUD_Alive(InRound)
	end
end

function GM:HUDPaint()
	self.BaseClass:HUDPaint()

	self:OnHUDPaint()
	self:RefreshHUD()
end

function GM:UpdateHUD_RoundResult()
	local txt = GetGlobalString("RRText")
	local resultType = type(RoundResult)

	if resultType == "number" and (team.GetAllTeams()[RoundResult] and txt == "") then
		local TeamName = team.GetName(RoundResult)

		if TeamName then
			txt = TeamName .. " Wins!"
		end
	elseif resultType == "Player" and IsValid(RoundResult) and txt == "" then
		txt = RoundResult:Name() .. " Wins!"
	end

	local RespawnText = vgui.Create("DHudElement")
	RespawnText:SizeToContents()
	RespawnText:SetText(txt)
	self:AddHUDItem(RespawnText,8)
end

function GM:UpdateHUD_Observer()
	local col,lbl,txt = color_white

	if IsValid(ObserveTarget) and ObserveTarget:IsPlayer() and ObserveTarget ~= LocalPlayer() and ObserveMode ~= OBS_MODE_ROAMING then
		lbl = "SPECTATING"
		txt = ObserveTarget:Nick()
		col = team.GetColor(ObserveTarget:Team())
	end

	if ObserveMode == OBS_MODE_DEATHCAM or ObserveMode == OBS_MODE_FREEZECAM then
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

	self:UpdateHUD_Dead(WaitingToRespawn,InRound)
end

local function GetRoundTimer()
	local roundStartTime = GetGlobalFloat("RoundStartTime",0)

	if roundStartTime > CurTime() then
		return roundStartTime
	end

	return GetGlobalFloat("RoundEndTime")
end

function GM:UpdateHUD_Dead()
	if not InRound and self.RoundBased then
		local RespawnText = vgui.Create("DHudElement")
		RespawnText:SizeToContents()
		RespawnText:SetText("Waiting for round start")

		self:AddHUDItem(RespawnText,8)
	elseif WaitingToRespawn then
		local RespawnTimer = vgui.Create("DHudCountdown")
		RespawnTimer:SizeToContents()

		RespawnTimer:SetValueFunction(function()
			return LocalPlayer():GetNWFloat("RespawnTime",0)
		end)
		RespawnTimer:SetLabel("SPAWN IN")

		self:AddHUDItem(RespawnTimer,8)
	elseif InRound then
		local RoundTimer = vgui.Create("DHudCountdown")
		RoundTimer:SizeToContents()
		RoundTimer:SetValueFunction(GetRoundTimer)
		RoundTimer:SetLabel("TIME")

		self:AddHUDItem(RoundTimer,8)
	elseif Team ~= TEAM_SPECTATOR and not Alive then
		local RespawnText = vgui.Create("DHudElement")
		RespawnText:SizeToContents()
		RespawnText:SetText("Press Fire to Spawn")

		self:AddHUDItem(RespawnText,8)
	end
end

function GM:UpdateHUD_Alive()
	if not (self.RoundBased or self.TeamBased) then return end

	local Bar = vgui.Create("DHudBar")
	self:AddHUDItem(Bar,2)

	if self.TeamBased and self.ShowTeamName then
		local plyTeam = LocalPlayer():Team()
		local TeamIndicator = vgui.Create("DHudUpdater")
		TeamIndicator:SizeToContents()

		TeamIndicator:SetValueFunction(function()
			return team.GetName(plyTeam)
		end)

		TeamIndicator:SetColorFunction(function()
			return team.GetColor(plyTeam)
		end)

		TeamIndicator:SetFont("HudSelectionText")
		Bar:AddItem(TeamIndicator)
	end

	if self.RoundBased then
		local RoundNumber = vgui.Create("DHudUpdater")
		RoundNumber:SizeToContents()

		RoundNumber:SetValueFunction(function()
			return GetGlobalInt("RoundNumber",0)
		end)

		RoundNumber:SetLabel("ROUND")
		Bar:AddItem(RoundNumber)

		local RoundTimer = vgui.Create("DHudCountdown")
		RoundTimer:SizeToContents()
		RoundTimer:SetValueFunction(GetRoundTimer)
		RoundTimer:SetLabel("TIME")
		Bar:AddItem(RoundTimer)
	end
end

-- to do or to override, your choice
function GM:UpdateHUD_AddedTime()
end

net.Receive("RoundAddedTime",function()
	if not GAMEMODE then return end

	GAMEMODE:UpdateHUD_AddedTime(net.ReadFloat())
end)
