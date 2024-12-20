FRETTA_FONT_CHECK = FRETTA_FONT_CHECK or {}

function surface.CreateLegacyFont(font,size,weight,antialias,additive,name,shadow,outline,blursize)
	if FRETTA_FONT_CHECK[name] then return end

	surface.CreateFont(name,{
		font = font,
		size = size,
		weight = weight,
		antialias = antialias,
		additive = additive,
		shadow = shadow,
		outline = outline,
		blursize = blursize
	})

	FRETTA_FONT_CHECK[name] = true
end

include("shared.lua")
include("cl_splashscreen.lua")
include("cl_selectscreen.lua")
include("cl_gmchanger.lua")
include("cl_help.lua")
include("skin.lua")
include("vgui/vgui_hudlayout.lua")
include("vgui/vgui_hudelement.lua")
include("vgui/vgui_hudbase.lua")
include("vgui/vgui_hudcommon.lua")
include("cl_hud.lua")
include("cl_deathnotice.lua")
include("cl_scores.lua")
include("cl_notify.lua")

language.Add("env_laser","Laser")
language.Add("env_explosion","Explosion")
language.Add("func_door","Door")
language.Add("func_door_rotating","Door")
language.Add("trigger_hurt","Hazard")
language.Add("func_rotating","Hazard")
language.Add("worldspawn","Gravity")
language.Add("prop_physics","Prop")
language.Add("prop_physics_respawnable","Prop")
language.Add("prop_physics_multiplayer","Prop")
language.Add("entityflame","Fire")

surface.CreateLegacyFont("Trebuchet MS",69,700,true,false,"FRETTA_HUGE")
surface.CreateLegacyFont("Trebuchet MS",69,700,true,false,"FRETTA_HUGE_SHADOW",true)
surface.CreateLegacyFont("Trebuchet MS",40,700,true,false,"FRETTA_LARGE")
surface.CreateLegacyFont("Trebuchet MS",40,700,true,false,"FRETTA_LARGE_SHADOW",true)
surface.CreateLegacyFont("Trebuchet MS",19,700,true,false,"FRETTA_MEDIUM")
surface.CreateLegacyFont("Trebuchet MS",19,700,true,false,"FRETTA_MEDIUM_SHADOW",true)
surface.CreateLegacyFont("Trebuchet MS",16,700,true,false,"FRETTA_SMALL")
surface.CreateLegacyFont("Trebuchet MS",ScreenScale(10),700,true,false,"FRETTA_NOTIFY",true)
surface.CreateLegacyFont("csd",ScreenScale(30),500,true,true,"CSKillIcons")
surface.CreateLegacyFont("csd",ScreenScale(60),500,true,true,"CSSelectIcons")

CreateConVar("cl_spec_mode",5,FCVAR_ARCHIVE + FCVAR_USERINFO)

function GM:InitPostEntity()
	if self.TeamBased then
		self:ShowTeam()
	end

	self:ShowSplash()
end

local CircleMat = Material("SGM/playercircle")
local VectorStart = Vector(0,0,50)
local VectorEndPos = Vector(0,0,-300)

function GM:DrawPlayerRing(pPlayer)
	if
		not (
			IsValid(pPlayer)
		and	pPlayer:GetNWBool("DrawRing",false)
		and	pPlayer:Alive()
	)
	then return end

	local plyPos = pPlayer:GetPos()
	local trace = {}
	trace.start = plyPos + VectorStart
	trace.endpos = trace.start + VectorEndPos
	trace.filter = pPlayer

	local tr = util.TraceLine(trace)

	if not tr.HitWorld then
		tr.HitPos = plyPos
	end

	local color = table.Copy(team.GetColor(pPlayer:Team()))
	color.a = 40

	render.SetMaterial(CircleMat)
	render.DrawQuadEasy(tr.HitPos + tr.HitNormal,tr.HitNormal,self.PlayerRingSize,self.PlayerRingSize,color)
end

hook.Add("PrePlayerDraw","DrawPlayerRing",function(ply)
	GAMEMODE:DrawPlayerRing(ply)
end)

function GM:HUDShouldDraw(name)
	return not self.ScoreboardVisible or name == "CHudDamageIndicator" and LocalPlayer():Alive()
end

function GM:OnSpawnMenuOpen()
	RunConsoleCommand("lastinv") -- Fretta is derived from base and has no spawn menu, so give it a use, make it lastinv.
end

function GM:PlayerBindPress(pl,bind,down)
	-- Redirect binds to the spectate system
	if pl:IsObserver() and down then
		if bind == "+jump" then
			RunConsoleCommand("spec_mode")
		elseif bind == "+attack" then
			RunConsoleCommand("spec_next")
		elseif bind == "+attack2" then
			RunConsoleCommand("spec_prev")
		end
	end

	return false
end

--[[---------------------------------------------------------
   Name: gamemode:GetTeamColor( ent )
---------------------------------------------------------]]--
function GM:GetTeamColor(ent)
	if self.SelectColor and IsValid(ent) then
		local clr = ent:GetNWString("NameColor",-1)

		if clr and clr ~= -1 and clr ~= "" then
			clr = list.Get("PlayerColours")[clr]
			if clr then return clr end
		end
	end

	local targetTeam = TEAM_UNASSIGNED

	if ent.Team and IsValid(ent) then
		targetTeam = ent:Team()
	end

	return self:GetTeamNumColor(targetTeam)
end

--[[---------------------------------------------------------
   Name: ShouldDrawLocalPlayer
---------------------------------------------------------]]--
function GM:ShouldDrawLocalPlayer(ply)
	return ply:CallClassFunction("ShouldDrawLocalPlayer")
end

--[[---------------------------------------------------------
   Name: InputMouseApply
---------------------------------------------------------]]--
function GM:InputMouseApply(cmd,x,y,angle)
	return LocalPlayer():CallClassFunction("InputMouseApply",cmd,x,y,angle)
end

function GM:TeamChangeNotification(ply,oldTeam,newTeam)
	if not (ply and IsValid(ply)) then return end

	local plyName = ply:GetName()
	local oldTeamColor = team.GetColor(oldTeam)
	local newTeamName = team.GetName(newTeam)
	local newTeamColor = team.GetColor(newTeam)

	if newTeam == TEAM_SPECTATOR then
		chat.AddText(oldTeamColor,plyName,color_white," is now spectating")
	else
		chat.AddText(oldTeamColor,plyName,color_white," joined ",newTeamColor,newTeamName)
	end

	chat.PlaySound("buttons/button15.wav")
end

net.Receive("fretta_teamchange",function()
	if not GAMEMODE then return end

	GAMEMODE:TeamChangeNotification(net.ReadEntity(),net.ReadUInt(TEAM_BITS),net.ReadUInt(TEAM_BITS))
end)
