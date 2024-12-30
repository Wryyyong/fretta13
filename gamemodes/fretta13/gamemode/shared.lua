--[[
	shared.lua - Shared Component
	-----------------------------------------------------
	This is the shared component of your gamemode, a lot of the game variables
	can be changed from here.
--]]

include("player_class.lua")
include("player_extension.lua")
include("class_default.lua")
include("player_colours.lua")

fretta_voting = CreateConVar("fretta_voting",1,FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED,"Allow/Dissallow voting")

GM.Name = "Simple Game Base"
GM.Author = "Anonymous"
GM.Email = ""
GM.Website = "www.garry.tv"
GM.Help = "No Help Available"
GM.TeamBased = true -- Team based game or a Free For All game?
GM.AllowAutoTeam = true -- Allow auto-assign?
GM.AllowSpectating = true -- Allow people to spectate during the game?
GM.SecondsBetweenTeamSwitches = 10 -- The minimum time between each team change?
GM.GameLength = 15 -- The overall length of the game
GM.RoundLimit = -1 -- Maximum amount of rounds to be played in round based games
GM.VotingDelay = 5 -- Delay between end of game, and vote. if you want to display any extra screens before the vote pops up
GM.ShowTeamName = true -- Show the team name on the HUD
GM.NoPlayerSuicide = false -- Set to true if players should not be allowed to commit suicide.
GM.NoPlayerDamage = false -- Set to true if players should not be able to damage each other.
GM.NoPlayerSelfDamage = false -- Allow players to hurt themselves?
GM.NoPlayerTeamDamage = true -- Allow team-members to hurt each other?
GM.NoPlayerPlayerDamage = false -- Allow players to hurt each other?
GM.NoNonPlayerPlayerDamage = false -- Allow damage from non players (physics, fire etc)
GM.NoPlayerFootsteps = false -- When true, all players have silent footsteps
GM.PlayerCanNoClip = false -- When true, players can use noclip without sv_cheats
GM.TakeFragOnSuicide = true -- -1 frag on suicide
GM.MaximumDeathLength = 0 -- Player will repspawn if death length > this (can be 0 to disable)
GM.MinimumDeathLength = 2 -- Player has to be dead for at least this long
GM.AutomaticTeamBalance = false -- Teams will be periodically balanced
GM.ForceJoinBalancedTeams = true -- Players won't be allowed to join a team if it has more players than another team
GM.RealisticFallDamage = false -- Set to true if you want realistic fall damage instead of the fix 10 damage.
GM.AddFragsToTeamScore = false -- Adds player's individual kills to team score (must be team based)
GM.NoAutomaticSpawning = false -- Players don't spawn automatically when they die, some other system spawns them
GM.RoundBased = false -- Round based, like CS
GM.RoundLength = 30 -- Round length, in seconds
GM.RoundPreStartTime = 5 -- Preperation time before a round starts
GM.RoundPostLength = 8 -- Seconds to show the 'x team won!' screen at the end of a round
GM.RoundEndsWhenOneTeamAlive = true -- CS Style rules
GM.EnableFreezeCam = false -- TF2 Style Freezecam
GM.DeathLingerTime = 4 -- The time between you dying and it going into spectator mode, 0 disables
GM.SelectModel = true -- Can players use the playermodel picker in the F1 menu?
GM.SelectColor = false -- Can players modify the colour of their name? (ie.. no teams)
GM.PlayerRingSize = 48 -- How big are the colored rings under the player's feet (if they are enabled) ?
GM.HudSkin = "SimpleSkin" -- The Derma skin to use for the HUD components
GM.SuicideString = "died" -- The string to append to the player's name when they commit suicide.
GM.DeathNoticeDefaultColor = Color(255,127,0) -- Default colour for entity kills
GM.DeathNoticeTextColor = color_white -- colour for text ie. "died", "killed"
GM.CanOnlySpectateOwnTeam = true -- you can only spectate players on your own team

-- The spectator modes that are allowed
GM.ValidSpectatorModes = {
	OBS_MODE_CHASE,
	OBS_MODE_IN_EYE,
	OBS_MODE_ROAMING,
}

-- Entities we can spectate, players being the obvious default choice.
GM.ValidSpectatorEntities = {
	"player",
}

DeriveGamemode("base")

TEAM_GREEN = 1
TEAM_ORANGE = 2
TEAM_BLUE = 3
TEAM_RED = 4

local TeamData = {
	[TEAM_GREEN] = {
		["name"] = "Green Team",
		["color"] = Color(70,230,70),
	},
	[TEAM_ORANGE] = {
		["name"] = "Orange Team",
		["color"] = Color(255,200,50),
	},
	[TEAM_BLUE] = {
		["name"] = "Blue Team",
		["color"] = Color(80,150,255),
	},
	[TEAM_RED] = {
		["name"] = "Red Team",
		["color"] = Color(255,80,80),
	},
	[TEAM_SPECTATOR] = {
		["name"] = "Spectators",
		["color"] = Color(200,200,200),
	},
}

--[[---------------------------------------------------------
   Name: gamemode:CreateTeams()
   Desc: Set up all your teams here. Note - HAS to be shared.
---------------------------------------------------------]]--
function GM:CreateTeams()
	if not GAMEMODE.TeamBased then return end

	-- The list of entities can be a table
	for teamID,teamData in pairs(TeamData) do
		team.SetUp(teamID,teamData.name,teamData.color,true)
		team.SetSpawnPoint(teamID,"info_player_start")
	end

	team.SetClass(TEAM_SPECTATOR,{"Spectator"})
end

TEAM_BITS = 32

hook.Add("PostGamemodeLoaded","Fretta_CalculateTeamBits",function()
	TEAM_BITS = math.ceil(math.log(table.maxn(team.GetAllTeams()) + 1,2))
end)

function GM:InGamemodeVote()
	return GetGlobalBool("InGamemodeVote",false)
end

--[[---------------------------------------------------------
   Name: gamemode:TeamHasEnoughPlayers( Number teamid )
   Desc: Return true if the team has too many players.
		 Useful for when forced auto-assign is on.
---------------------------------------------------------]]--
function GM:TeamHasEnoughPlayers(teamID)
	if
		self.ForceJoinBalancedTeams
	or	newTeamID == TEAM_SPECTATOR
	then
		return false
	end

	local plyCount = team.NumPlayers(teamID)

	-- Don't let them join a team if it has more players than another team
	for otherTeamID in pairs(team.GetAllTeams()) do
		if
			otherTeamID == teamID
		or	otherTeamID <= TEAM_CONNECTING
		or	otherTeamID >= TEAM_UNASSIGNED
		or	not team.Joinable(otherTeamID)
		or	team.NumPlayers(otherTeamID) >= plyCount
		then continue end

		return true
	end

	return false
end

--[[---------------------------------------------------------
   Name: gamemode:PlayerCanJoinTeam( Player ply, Number teamid )
   Desc: Are we allowed to join a team? Return true if so.
---------------------------------------------------------]]--
function GM:PlayerCanJoinTeam(ply,teamID)
	if SERVER and not self.BaseClass:PlayerCanJoinTeam(ply,teamID) then
		return false
	end

	if self:TeamHasEnoughPlayers(teamID) then
		ply:ChatPrint("That team is full!")
		net.Start("ShowTeam")
		net.Send(ply)

		return false
	end

	return true
end

--[[---------------------------------------------------------
   Name: gamemode:Move( Player ply, CMoveData mv )
   Desc: Setup Move, this also calls the player's class move
		 function.
---------------------------------------------------------]]--
function GM:Move(ply,mv)
	return ply:CallClassFunction("Move",mv) ~= nil
end

--[[---------------------------------------------------------
   Name: gamemode:KeyPress( Player ply, Number key )
   Desc: Player presses a key, this also calls the player's class
		 OnKeyPress function.
---------------------------------------------------------]]--
function GM:KeyPress(ply,key)
	local result = ply:CallClassFunction("OnKeyPress",key)
	if not result then return end

	return true
end

--[[---------------------------------------------------------
   Name: gamemode:KeyRelease( Player ply, Number key )
   Desc: Player releases a key, this also calls the player's class
		 OnKeyRelease function.
---------------------------------------------------------]]--
function GM:KeyRelease(ply,key)
	local result = ply:CallClassFunction("OnKeyRelease",key)
	if not result then return end

	return true
end

--[[---------------------------------------------------------
   Name: gamemode:PlayerFootstep( Player ply, Vector pos, Number foot, String snd, Float volume, CReceipientFilter rf )
   Desc: Player's feet makes a sound, this also calls the player's class Footstep function.
		 If you want to disable all footsteps set GM.NoPlayerFootsteps to true.
		 If you want to disable footsteps on a class, set Class.DisableFootsteps to true.
---------------------------------------------------------]]--
function GM:PlayerFootstep(ply,pos,foot,snd,volume,rf)
	if
		self.NoPlayerFootsteps
	or	not ply:Alive()
	or	ply:Team() == TEAM_SPECTATOR
	or	ply:IsObserver()
	then
		return true
	end

	local class = ply:GetPlayerClass()
	if not class then return end

	-- rather than using a hook, we can just do this to override the function instead.
	if class.DisableFootsteps then
		return true
	end

	if not class.Footstep then return end

	-- Call footstep function in class, you can use this to make custom footstep sounds
	return class:Footstep(ply,pos,foot,snd,volume,rf)
end

--[[---------------------------------------------------------
   Name: gamemode:CalcView( Player ply, Vector origin, Angles angles, Number fov )
   Desc: Calculates the players view. Also calls the players class
		 CalcView function, as well as GetViewModelPosition and CalcView
		 on the current weapon. Returns a table.
---------------------------------------------------------]]--
function GM:CalcView(ply,origin,angles,fov)
	local view = ply:CallClassFunction("CalcView",origin,angles,fov) or {
		["origin"] = origin,
		["angles"] = angles,
		["fov"] = fov,
	}

	origin = view.origin or origin
	angles = view.angles or angles
	fov = view.fov or fov

	local wep = ply:GetActiveWeapon()

	if IsValid(wep) then
		local getViewModelPos = wep.GetViewModelPosition

		if getViewModelPos then
			view.vm_origin,view.vm_angles = getViewModelPos(wep,origin * 1,angles * 1)
		end

		local calcView = wep.CalcView

		if calcView then
			view.origin,view.angles,view.fov = calcView(wep,ply,origin * 1,angles * 1,fov)
		end
	end

	return view
end

--[[---------------------------------------------------------
   Name: gamemode:GetTimeLimit()
   Desc: Returns the time limit of a game in seconds, so you could
		 make it use a cvar instead. Return -1 for unlimited.
		 Unlimited length games can be changed using vote for
		 change.
---------------------------------------------------------]]--
function GM:GetTimeLimit()
	return self.GameLength > 0 and self.GameLength * 60 or -1
end

--[[---------------------------------------------------------
   Name: gamemode:GetGameTimeLeft()
   Desc: Get the remaining time in seconds.
---------------------------------------------------------]]--
function GM:GetGameTimeLeft()
	local endTime = self:GetTimeLimit()

	return endTime == -1 and endTime or endTime - CurTime()
end

local cvCheats = GetConVar("sv_cheats")

--[[---------------------------------------------------------
   Name: gamemode:PlayerNoClip( player, bool )
   Desc: Player pressed the noclip key, return true if
		  the player is allowed to noclip, false to block
---------------------------------------------------------]]--
function GM:PlayerNoClip()
	-- Allow noclip if we're in single player or have cheats enabled
	-- Don't if it's not.
	return
		self.PlayerCanNoClip
	or	game.SinglePlayer()
	or	cvCheats:GetBool()
end

-- This function includes /yourgamemode/player_class/*.lua
-- And AddCSLuaFile's each of those files.
-- You need to call it in your derived shared.lua IF you have files in that folder
-- and want to include them!
function IncludePlayerClasses()
	local folder = string.Replace(GM.Folder,"gamemodes/","")

	for _,script in ipairs(file.Find(folder .. "/gamemode/player_class/*.lua","LUA")) do
		local path = folder .. "/gamemode/player_class/" .. script

		include(path)
		AddCSLuaFile(path)
	end
end

IncludePlayerClasses()

function util.ToMinutesSeconds(seconds)
	local minutes = math.floor(seconds / 60)
	seconds = seconds - minutes * 60

	return string.format("%02d:%02d",minutes,math.floor(seconds))
end

function util.ToMinutesSecondsMilliseconds(inputSeconds)
	local minutes = math.floor(inputSeconds / 60)
	local seconds = inputSeconds - minutes * 60
	local milliseconds = math.floor(seconds % 1 * 100)

	return string.format("%02d:%02d.%02d",minutes,math.floor(seconds),milliseconds)
end

function timer.SimpleEx(delay,action,...)
	if ... == nil then
		timer.Simple(delay,action)
	else
		local a,b,c,d,e,f,g,h,i,j,k = ...

		timer.Simple(delay,function()
			action(a,b,c,d,e,f,g,h,i,j,k)
		end)
	end
end

function timer.CreateEx(timername,delay,repeats,action,...)
	if ... == nil then
		timer.Create(timername,delay,repeats,action)
	else
		local a,b,c,d,e,f,g,h,i,j,k = ...

		timer.Create(timername,delay,repeats,function()
			action(a,b,c,d,e,f,g,h,i,j,k)
		end)
	end
end
