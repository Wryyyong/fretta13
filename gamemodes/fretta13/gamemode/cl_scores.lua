include("vgui/vgui_scoreboard.lua")


function GM:GetScoreboard()
	if IsValid(g_VGUI_Scoreboard) then
		g_VGUI_Scoreboard:Remove()
	end

	g_VGUI_Scoreboard = vgui.Create("FrettaScoreboard")
	self:CreateScoreboard(g_VGUI_Scoreboard)

	return g_VGUI_Scoreboard
end

function GM:ScoreboardShow()
	g_VGUI_Scoreboard:SetVisible(true)
	self:PositionScoreboard(g_VGUI_Scoreboard)
end

function GM:ScoreboardHide()
	g_VGUI_Scoreboard:SetVisible(false)
end

function GM:ScoreboardPlayerPressed()
end

local function PlyGetAvatar(ply)
	local avatar = vgui.Create("AvatarImage",g_VGUI_Scoreboard)

	avatar:SetSize(32,32)
	avatar:SetPlayer(ply)

	return avatar
end

function GM:AddScoreboardAvatar()
	g_VGUI_Scoreboard:AddColumn("",32,PlyGetAvatar,360) -- Avatar
end

function GM:AddScoreboardSpacer()
	g_VGUI_Scoreboard:AddColumn("",16) -- Gap
end

local function PlyGetName(ply)
	return ply:GetName()
end

function GM:AddScoreboardName()
	g_VGUI_Scoreboard:AddColumn("Name",nil,PlyGetName,10,nil,4,4)
end

local function PlyGetFrags(ply)
	return ply:Frags()
end

function GM:AddScoreboardKills()
	g_VGUI_Scoreboard:AddColumn("Kills",80,PlyGetFrags,0.5,nil,6,6)
end

local function PlyGetDeaths(ply)
	return ply:Deaths()
end

function GM:AddScoreboardDeaths()
	g_VGUI_Scoreboard:AddColumn("Deaths",80,PlyGetDeaths,0.5,nil,6,6)
end

local function PlyGetPing(ply)
	return ply:Ping()
end

function GM:AddScoreboardPing()
	g_VGUI_Scoreboard:AddColumn("Ping",80,PlyGetPing,0.1,nil,6,6)
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

	local board = g_VGUI_Scoreboard
	board:SetSize(w,ScrH() - h)
	board:SetPos((scrW - board:GetWide()) * 0.5,y)
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
	g_VGUI_Scoreboard:AddColumn("",16,PlyGetWantsVote,2,nil,6,6)
end

local SortedColumns = {4,true,5,false,3,false}

function GM:CreateScoreboard()
	local teamBased = self.TeamBased

	-- This makes it so that it's behind chat & hides when you're in the menu
	-- Disable this if you want to be able to click on stuff on your scoreboard
	local board = g_VGUI_Scoreboard
	board:ParentToHUD()
	board:SetRowHeight(32)
	board:SetAsBullshitTeam(TEAM_SPECTATOR)
	board:SetAsBullshitTeam(TEAM_CONNECTING)
	board:SetShowScoreboardHeaders(teamBased)

	if teamBased then
		board:SetAsBullshitTeam(TEAM_UNASSIGNED)
		board:SetHorizontal(true)
	end

	board:SetSkin(self.HudSkin)
	self:AddScoreboardAvatar(board) -- 1
	self:AddScoreboardWantsChange(board) -- 2
	self:AddScoreboardName(board) -- 3
	self:AddScoreboardKills(board) -- 4
	self:AddScoreboardDeaths(board) -- 5
	self:AddScoreboardPing(board) -- 6

	-- Here we sort by these columns (and descending), in this order. You can define up to 4
	board:SetSortColumns(SortedColumns)
end
