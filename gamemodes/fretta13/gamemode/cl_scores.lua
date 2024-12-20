include("vgui/vgui_scoreboard.lua")

g_Scoreboard = g_Scoreboard or nil

function GM:GetScoreboard()
	if IsValid(g_Scoreboard) then
		g_Scoreboard:Remove()
	end

	g_Scoreboard = vgui.Create("FrettaScoreboard")
	self:CreateScoreboard(g_Scoreboard)

	return g_Scoreboard
end

function GM:ScoreboardShow()
	g_Scoreboard:SetVisible(true)
	self:PositionScoreboard(g_Scoreboard)
end

function GM:ScoreboardHide()
	g_Scoreboard:SetVisible(false)
end

function GM:ScoreboardPlayerPressed()
end

local function PlyGetAvatar(ply)
	local avatar = vgui.Create("AvatarImage",g_Scoreboard)

	avatar:SetSize(32,32)
	avatar:SetPlayer(ply)

	return avatar
end

function GM:AddScoreboardAvatar()
	g_Scoreboard:AddColumn("",32,PlyGetAvatar,360) -- Avatar
end

function GM:AddScoreboardSpacer()
	g_Scoreboard:AddColumn("",16) -- Gap
end

local function PlyGetName(ply)
	return ply:GetName()
end

function GM:AddScoreboardName()
	g_Scoreboard:AddColumn("Name",nil,PlyGetName,10,nil,4,4)
end

local function PlyGetFrags(ply)
	return ply:Frags()
end

function GM:AddScoreboardKills()
	g_Scoreboard:AddColumn("Kills",80,PlyGetFrags,0.5,nil,6,6)
end

local function PlyGetDeaths(ply)
	return ply:Deaths()
end

function GM:AddScoreboardDeaths()
	g_Scoreboard:AddColumn("Deaths",80,PlyGetDeaths,0.5,nil,6,6)
end

local function PlyGetPing(ply)
	return ply:Ping()
end

function GM:AddScoreboardPing()
	g_Scoreboard:AddColumn("Ping",80,PlyGetPing,0.1,nil,6,6)
end

-- THESE SHOULD BE THE ONLY FUNCTION YOU NEED TO OVERRIDE
function GM:PositionScoreboard()
	local w,h,y

	local scrW = ScrW()

	if self.TeamBased then
		w = math.min(1024,scrW)
		h = 50
		y = 25
	else
		w = 512
		h = 64
		y = 32
	end

	g_Scoreboard:SetSize(w,ScrH() - h)
	g_Scoreboard:SetPos((scrW - g_Scoreboard:GetWide()) * 0.5,y)
end

local ColorVote = Color(100,255,0)

local function PlyGetWantsVote(ply)
	if not ply:GetNWBool("WantsVote",false) then return end

	local label = vgui.Create("DLabel")
	label:SetFont("Marlett")
	label:SetText("a")
	label:SetTextColor(ColorVote)
	label:SetContentAlignment(5)

	return label
end

function GM:AddScoreboardWantsChange()
	g_Scoreboard:AddColumn("",16,PlyGetWantsVote,2,nil,6,6)
end

local SortedColumns = {4,true,5,false,3,false}

function GM:CreateScoreboard()
	local teamBased = self.TeamBased

	-- This makes it so that it's behind chat & hides when you're in the menu
	-- Disable this if you want to be able to click on stuff on your scoreboard
	g_Scoreboard:ParentToHUD()
	g_Scoreboard:SetRowHeight(32)
	g_Scoreboard:SetAsBullshitTeam(TEAM_SPECTATOR)
	g_Scoreboard:SetAsBullshitTeam(TEAM_CONNECTING)
	g_Scoreboard:SetShowScoreboardHeaders(teamBased)

	if teamBased then
		g_Scoreboard:SetAsBullshitTeam(TEAM_UNASSIGNED)
		g_Scoreboard:SetHorizontal(true)
	end

	g_Scoreboard:SetSkin(self.HudSkin)
	self:AddScoreboardAvatar(g_Scoreboard) -- 1
	self:AddScoreboardWantsChange(g_Scoreboard) -- 2
	self:AddScoreboardName(g_Scoreboard) -- 3
	self:AddScoreboardKills(g_Scoreboard) -- 4
	self:AddScoreboardDeaths(g_Scoreboard) -- 5
	self:AddScoreboardPing(g_Scoreboard) -- 6

	-- Here we sort by these columns (and descending), in this order. You can define up to 4
	g_Scoreboard:SetSortColumns(SortedColumns)
end
