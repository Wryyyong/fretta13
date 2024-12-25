--[[
	init.lua - Server Component
	-----------------------------------------------------
	The entire server side bit of Fretta starts here.
--]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("skin.lua")
AddCSLuaFile("player_class.lua")
AddCSLuaFile("class_default.lua")
AddCSLuaFile("cl_splashscreen.lua")
AddCSLuaFile("cl_selectscreen.lua")
AddCSLuaFile("cl_gmchanger.lua")
AddCSLuaFile("cl_help.lua")
AddCSLuaFile("player_extension.lua")
AddCSLuaFile("vgui/vgui_hudlayout.lua")
AddCSLuaFile("vgui/vgui_hudelement.lua")
AddCSLuaFile("vgui/vgui_hudbase.lua")
AddCSLuaFile("vgui/vgui_hudcommon.lua")
AddCSLuaFile("vgui/vgui_gamenotice.lua")
AddCSLuaFile("vgui/vgui_scoreboard.lua")
AddCSLuaFile("vgui/vgui_scoreboard_team.lua")
AddCSLuaFile("vgui/vgui_scoreboard_small.lua")
AddCSLuaFile("vgui/vgui_vote.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_deathnotice.lua")
AddCSLuaFile("cl_scores.lua")
AddCSLuaFile("cl_notify.lua")
AddCSLuaFile("player_colours.lua")

util.AddNetworkString("PlayableGamemodes")
util.AddNetworkString("RoundAddedTime")
util.AddNetworkString("fretta_teamchange")
util.AddNetworkString("ShowHelp")
util.AddNetworkString("ShowTeam")
util.AddNetworkString("ShowGamemodeChooser")
util.AddNetworkString("ShowMapChooserForGamemode")
util.AddNetworkString("ShowClassChooser")
util.AddNetworkString("GamemodeWon")
util.AddNetworkString("ChangingGamemode")
util.AddNetworkString("PlayerChatPrint")

include("shared.lua")
include("sv_gmchanger.lua")
include("sv_spectator.lua")
include("round_controller.lua")
include("utility.lua")

GM.ReconnectedPlayers = GM.ReconnectedPlayers or {}

function GM:Initialize()
	-- If we're round based, wait 3 seconds before the first round starts
	if self.RoundBased then
		timer.Simple(3,function()
			self:StartRoundBasedGame()
		end)
	end

	if self.AutomaticTeamBalance then
		timer.Create("CheckTeamBalance",30,0,function()
			self:CheckTeamBalance()
		end)
	end
end

function GM:Think()
	self.BaseClass:Think()

	for _,ply in player.Iterator() do
		if not ply:GetPlayerClass() then continue end

		ply:CallClassFunction("Think")
	end

	-- Game time related
	--		not self.IsEndOfGame
	--	and	(not self.RoundBased or self.RoundBased and self:CanEndRoundBasedGame())
	--	and	CurTime() >= self:GetTimeLimit()

	if
		self.IsEndOfGame
	or	not (self.RoundBased and self:CanEndRoundBasedGame())
	or	self.RoundBased
	or	self:GetTimeLimit() > CurTime()
	then return end

	self:EndOfGame(true)
end

--[[---------------------------------------------------------
   Name: gamemode:CanPlayerSuicide( Player ply )
   Desc: Is the player allowed to commit suicide?
---------------------------------------------------------]]--
function GM:CanPlayerSuicide(ply)
	local plyTeam = ply:Team()

	-- no suicide in spectator mode
	if
		plyTeam == TEAM_UNASSIGNED
	or	plyTeam == TEAM_SPECTATOR
	then
		return false
	end

	return not self.NoPlayerSuicide
end

--[[---------------------------------------------------------
   Name: gamemode:PlayerSwitchFlashlight( Player ply, Bool on )
   Desc: Can we turn our flashlight on or off?
---------------------------------------------------------]]--
function GM:PlayerSwitchFlashlight(ply,isOn)
	local plyTeam = ply:Team()

	if
		plyTeam == TEAM_SPECTATOR
	or	plyTeam == TEAM_UNASSIGNED
	or	plyTeam == TEAM_CONNECTING
	then
		return not isOn
	end

	return ply:CanUseFlashlight()
end

--[[---------------------------------------------------------
   Name: gamemode:PlayerInitialSpawn( Player ply )
   Desc: Our very first spawn in the game.
---------------------------------------------------------]]--
function GM:PlayerInitialSpawn(ply)
	ply:SetTeam(TEAM_UNASSIGNED)
	ply:SetPlayerClass("Spectator")
	ply:UpdateNameColor()

	ply.m_bFirstSpawn = true

	self:CheckPlayerReconnected(ply)
end

function GM:CheckPlayerReconnected(ply)
	if not self.ReconnectedPlayers[ply:SteamID64()] then return end

	self:PlayerReconnected(ply)
end

--[[---------------------------------------------------------
   Name: gamemode:PlayerReconnected( Player ply )
   Desc: Called if the player has appeared to have reconnected.
---------------------------------------------------------]]--
function GM:PlayerReconnected()
	-- Use this hook to do stuff when a player rejoins and has been in the server previously
end

function GM:PlayerDisconnected(ply)
	self.ReconnectedPlayers[ply:SteamID64()] = true

	self.BaseClass:PlayerDisconnected(ply)
end

function GM:ShowHelp(ply)
	net.Start("ShowHelp")
	net.Send(ply)
end

function GM:PlayerSpawn(ply)
	ply:UpdateNameColor()

	-- The player never spawns straight into the game in Fretta
	-- They spawn as a spectator first (during the splash screen and team picking screens)
	if ply.m_bFirstSpawn then
		ply.m_bFirstSpawn = nil

		if ply:IsBot() then
			self:AutoTeam(ply)

			-- The bot doesn't send back the 'seen splash' command, so fake it.
			if not (self.TeamBased or self.NoAutomaticSpawning) then
				ply:Spawn()
			end
		else
			ply:StripWeapons()
			self:PlayerSpawnAsSpectator(ply)
			-- Follow a random player until we join a team

			local plyCount = player.GetCount()
			if plyCount > 1 then
				ply:Spectate(OBS_MODE_CHASE)
				ply:SpectateEntity(math.random(plyCount))
			end
		end

		return
	end

	ply:CheckPlayerClassOnSpawn()

	local plyTeam = ply:Team()

	if
		self.TeamBased
	and	(plyTeam == TEAM_SPECTATOR or plyTeam == TEAM_UNASSIGNED)
	then
		self:PlayerSpawnAsSpectator(ply)

		return
	end

	-- Stop observer mode
	ply:UnSpectate()

	-- Call item loadout function
	hook.Run("PlayerLoadout",ply)

	-- Set player model
	hook.Run("PlayerSetModel",ply)
	ply:SetupHands()

	-- Call class function
	ply:OnSpawn()
end

function GM:PlayerLoadout(ply)
	ply:CheckPlayerClassOnSpawn()
	ply:OnLoadout()

	-- Switch to prefered weapon if they have it
	local cl_defaultweapon = ply:GetInfo("cl_defaultweapon")

	if not ply:HasWeapon(cl_defaultweapon) then return end
	ply:SelectWeapon(cl_defaultweapon)
end

function GM:PlayerSetModel(ply)
	ply:OnPlayerModel()
end

function GM:AutoTeam(ply)
	if not (self.AllowAutoTeam and self.TeamBased) then return end

	self:PlayerRequestTeam(ply,team.BestAutoJoinTeam())
end

concommand.Add("autoteam",function(ply)
	hook.Run("AutoTeam",ply)
end)

function GM:PlayerRequestClass(ply,class,disableMessage)
	local classes = team.GetClass(ply:Team())
	if not classes then return end

	local requestedClass = classes[class]
	if not requestedClass then return end

	if ply:Alive() then
		if ply.m_SpawnAsClass and ply.m_SpawnAsClass == requestedClass then return end

		ply.m_SpawnAsClass = requestedClass

		if not disableMessage then
			ply:ChatPrint("Your class will change to '" .. player_class.GetClassName(requestedClass) .. "' when you respawn")
		end
	else
		self:PlayerJoinClass(ply,requestedClass)

		ply.m_SpawnAsClass = nil
	end
end

concommand.Add("changeclass",function(ply,_,args)
	hook.Run("PlayerRequestClass",ply,tonumber(args[1]))
end)

concommand.Add("seensplash",function(ply)
	if ply.m_bSeenSplashScreen then return end

	ply.m_bSeenSplashScreen = true

	if not (GAMEMODE.TeamBased or GAMEMODE.NoAutomaticSpawning) then return end
	ply:KillSilent()
end)

function GM:PlayerJoinTeam(ply,teamID)
	local oldTeam = ply:Team()

	if ply:Alive() then
		if self.TeamBased and (oldTeam == TEAM_SPECTATOR or oldTeam == TEAM_UNASSIGNED) then
			ply:KillSilent()
		else
			ply:Kill()
		end
	end

	ply:SetTeam(teamID)
	ply.LastTeamSwitch = RealTime()

	local classes = team.GetClass(teamID)
	local classCount = #classes

	-- Needs to choose class
	if classes and classCount > 1 then
		if ply:IsBot() or not self.SelectClass then
			self:PlayerRequestClass(ply,math.random(classCount))
		else
			ply.m_fnCallAfterClassChoose = function()
				ply.DeathTime = CurTime()
				self:OnPlayerChangedTeam(ply,oldTeam,teamID)
				ply:EnableRespawn()
			end

			net.Start("ShowClassChooser")
				net.WriteUInt(teamID,TEAM_BITS)
			net.Send(ply)

			ply:DisableRespawn()
			ply:SetRandomClass() -- put the player in a VALID class in case they don't choose and get spawned

			return
		end
	end

	-- No class, use default
	if not classes or classCount == 0 then
		ply:SetPlayerClass("Default")
	end

	-- Only one class, use that
	if classes and classCount == 1 then
		self:PlayerRequestClass(ply,1)
	end

	gamemode.Call("OnPlayerChangedTeam",ply,oldTeam,teamID)
end

function GM:PlayerJoinClass(ply,classname)
	ply.m_SpawnAsClass = nil
	ply:SetPlayerClass(classname)

	if not ply.m_fnCallAfterClassChoose then return end

	ply.m_fnCallAfterClassChoose()
	ply.m_fnCallAfterClassChoose = nil
end

function GM:OnPlayerChangedTeam(ply,oldTeam,newTeam)
	-- Here's an immediate respawn thing by default. If you want to 
	-- re-create something more like CS or some shit you could probably
	-- change to a spectator or something while dead.
	if newTeam == TEAM_SPECTATOR then -- If we changed to spectator mode, respawn where we are
		ply:Spawn()
		ply:SetPos(ply:EyePos())
	elseif oldTeam == TEAM_SPECTATOR then -- If we're changing from spectator, join the game
		if not self.NoAutomaticSpawning then
			ply:Spawn()
		end
	elseif oldTeam ~= TEAM_SPECTATOR then
		ply.LastTeamChange = CurTime()
	--else
		-- If we're straight up changing teams just hang
		-- around until we're ready to respawn onto the 
		-- team that we chose
	end

	-- PrintMessage(HUD_PRINTTALK,Format("%s joined '%s'",ply:GetName(),team.GetName(newteam)))
	-- Send net msg for team change
	net.Start("fretta_teamchange")
		net.WriteEntity(ply)
		net.WriteUInt(oldTeam,TEAM_BITS)
		net.WriteUInt(newTeam,TEAM_BITS)
	net.Broadcast()
end

function GM:CheckTeamBalance()
	local highestID

	for teamID in pairs(team.GetAllTeams()) do
		if
			not	(
				teamID > TEAM_CONNECTING
			and	teamID < TEAM_UNASSIGNED
			and	team.Joinable(teamID)
			and	(not highest or team.NumPlayers(teamID) > team.NumPlayers(highest))
			)
		then continue end

		highestID = teamID
	end

	if not highest then return end

	for teamID in pairs(team.GetAllTeams()) do
		if
			teamID == highestID
		or	teamID <= TEAM_CONNECTING
		or	teamID >= TEAM_UNASSIGNED
		or	not team.Joinable(teamID)
		or	team.NumPlayers(teamID) >= team.NumPlayers(highestID)
		then continue end

		while team.NumPlayers(teamID) < team.NumPlayers(highestID) - 1 do
			local ply,reason = self:FindLeastCommittedPlayerOnTeam(highestID)

			ply:Kill()
			ply:SetTeam(teamID)

			-- Todo: Notify player 'you have been swapped'
			-- This is a placeholder
			PrintMessage(HUD_PRINTTALK,ply:GetName() .. " has been changed to " .. team.GetName(teamID) .. " for team balance. (" .. reason .. ")")
		end
	end
end

function GM:FindLeastCommittedPlayerOnTeam(teamID)
	local worst,worstTeamSwapper

	for _,ply in ipairs(team.GetPlayers(teamID)) do
		if
			ply.LastTeamChange
		and	CurTime() < ply.LastTeamChange + 180
		and	(
				not worstTeamSwapper
			or	worstTeamSwapper.LastTeamChange < ply.LastTeamChange
		)
		then
			worstTeamSwapper = ply
		end

		if
			not worst
		or	ply:Frags() < worst:Frags()
		then
			worst = ply
		end
	end

	if worstTeamSwapper then
		return worstTeamSwapper,"They changed teams recently"
	end

	return worst,"Least points on their team"
end

function GM:OnEndOfGame()
	for _,ply in player.Iterator() do
		ply:Freeze(true)
		ply:ConCommand("+showscores")
	end
end

-- Override OnEndOfGame to do any other stuff. like winning music.
function GM:EndOfGame(bGamemodeVote)
	if self.IsEndOfGame then return end
	self.IsEndOfGame = true

	SetGlobalBool("IsEndOfGame",true)
	gamemode.Call("OnEndOfGame",bGamemodeVote)

	if not bGamemodeVote then return end
	MsgN("Starting gamemode voting...")
	PrintMessage(HUD_PRINTTALK,"Starting gamemode voting...")
	timer.Simple(self.VotingDelay,function()
		self:StartGamemodeVote()
	end)
end

function GM:GetWinningFraction()
	if not self.GMVoteResults then return end

	return self.GMVoteResults.Fraction
end

function GM:PlayerShouldTakeDamage(ply,attacker)
	if not IsValid(attacker) then return end
	local attackerIsPlayer = attacker:IsPlayer()

	return
		not (
			self.NoPlayerDamage
		or
				self.NoPlayerSelfDamage
			and	ply == attacker
		or
				self.NoPlayerTeamDamage
			and	attacker.Team
			and	ply:Team() == attacker:Team()
			and	ply ~= attacker
		or
				self.NoPlayerPlayerDamage
			and	attackerIsPlayer
		or
				self.NoNonPlayerPlayerDamage
			and	not attackerIsPlayer
	)
end

function GM:PlayerDeathThink(ply)
	local curTime = CurTime()

	ply.DeathTime = ply.DeathTime or curTime
	local timeDead = curTime - ply.DeathTime

	-- If we're in deathcam mode, promote to a generic spectator mode
	local plyObsMode = ply:GetObserverMode()

	if
		self.DeathLingerTime > 0
	and	timeDead > self.DeathLingerTime
	and	(plyObsMode == OBS_MODE_FREEZECAM or plyObsMode == OBS_MODE_DEATHCAM)
	then
		self:BecomeObserver(ply)
	end

	-- If we're in a round based game, player NEVER spawns in death think
	if self.NoAutomaticSpawning then return end

	-- The gamemode is holding the player from respawning.
	-- Probably because they have to choose a class..
	if not ply:CanRespawn() then return end

	-- Don't respawn yet - wait for minimum time...
	if self.MinimumDeathLength then
		ply:SetNWFloat("RespawnTime",ply.DeathTime + self.MinimumDeathLength)

		if timeDead < ply:GetRespawnTime() then return end
	end

	-- Force respawn
	if ply:GetRespawnTime() ~= 0 and self.MaximumDeathLength ~= 0 and timeDead > self.MaximumDeathLength then
		ply:Spawn()

		return
	end

	-- We're between min and max death length, player can press a key to spawn.
	if not (ply:KeyPressed(IN_ATTACK) or ply:KeyPressed(IN_ATTACK2) or ply:KeyPressed(IN_JUMP)) then return end
	ply:Spawn()
end

function GM:GetFallDamage(_,flFallSpeed)
	if self.RealisticFallDamage then
		return flFallSpeed * 0.125
	end

	return 10
end

function GM:PostPlayerDeath(ply)
	-- Note, this gets called AFTER DoPlayerDeath.. AND it gets called
	-- for KillSilent too. So if Freezecam isn't set by DoPlayerDeath, we
	-- pick up the slack by setting DEATHCAM here.
	if ply:GetObserverMode() == OBS_MODE_NONE then
		ply:Spectate(OBS_MODE_DEATHCAM)
	end

	ply:OnDeath()
end

function GM:DoPlayerDeath(ply,attacker,dmginfo)
	if not IsValid(attacker) then return end

	ply:CallClassFunction("OnDeath",attacker,dmginfo)
	ply:CreateRagdoll()
	ply:AddDeaths(1)

	if attacker:IsPlayer() then
		local fragValue = attacker == ply and -1 or 1

		attacker:AddFrags(fragValue)

		if self.TeamBased and self.AddFragsToTeamScore then
			team.AddScore(attacker:Team(),fragValue)
		end
	end

	if not (self.EnableFreezeCam and attacker ~= ply) then return end
	ply:SpectateEntity(attacker)
	ply:Spectate(OBS_MODE_FREEZECAM)
end

function GM:StartSpectating(ply)
	if not self:PlayerCanJoinTeam(ply) then return end

	ply:StripWeapons()
	self:PlayerJoinTeam(ply,TEAM_SPECTATOR)
	self:BecomeObserver(ply)
end

function GM:EndSpectating(ply)
	if not self:PlayerCanJoinTeam(ply) then return end

	self:PlayerJoinTeam(ply,TEAM_UNASSIGNED)
	ply:KillSilent()
end

--[[---------------------------------------------------------
   Name: gamemode:PlayerRequestTeam()
		Player wants to change team
---------------------------------------------------------]]--
function GM:PlayerRequestTeam(ply,teamID)
	if not self.TeamBased and self.AllowSpectating then
		if teamID == TEAM_SPECTATOR then
			self:StartSpectating(ply)
		else
			self:EndSpectating(ply)
		end

		return
	end

	return self.BaseClass:PlayerRequestTeam(ply,teamID)
end

local function TimeLeft(ply)
	local timeLeft = GAMEMODE:GetGameTimeLeft()
	if timeLeft == -1 then return end

	local time = util.ToMinutesSeconds(timeLeft)

	if IsValid(ply) then
		ply:PrintMessage(HUD_PRINTCONSOLE,time)
	else
		MsgN(time)
	end
end

concommand.Add("timeleft",TimeLeft)
