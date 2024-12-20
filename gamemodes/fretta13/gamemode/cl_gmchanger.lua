include("vgui/vgui_vote.lua")

g_PlayableGamemodes = g_PlayableGamemodes or {}
g_bGotGamemodesTable = false

net.Receive("PlayableGamemodes",function()
	g_PlayableGamemodes = net.ReadTable()
	g_bGotGamemodesTable = true
end)

local GMChooser = nil
local function GetVoteScreen()
	LocalPlayer():ConCommand("-score")
	if IsValid(GMChooser) then return GMChooser end

	GMChooser = vgui.Create("VoteScreen")

	return GMChooser
end

function GM:ShowGamemodeChooser()
	local votescreen = GetVoteScreen()

	votescreen:ChooseGamemode()
end

function GM:GamemodeWon(mode)
	local votescreen = GetVoteScreen()

	votescreen:FlashItem(mode)
end

function GM:ChangingGamemode(_,map)
	local votescreen = GetVoteScreen()

	votescreen:FlashItem(map)
end

function GM:ShowMapChooserForGamemode(gmName)
	local votescreen = GetVoteScreen()

	votescreen:ChooseMap(gmName)
end

local ClassChooser = nil
local cvClassSuicide = CreateConVar("cl_classsuicide",0,FCVAR_ARCHIVE,nil,0,1)

function GM:ShowClassChooser(teamID)
	if not self.SelectClass then return end

	if ClassChooser then
		ClassChooser:Remove()
	end

	ClassChooser = vgui.CreateFromTable(vgui_Select)
	ClassChooser:SetHeaderText("Choose Class")
	ClassChooser:SetHoverText("What class do you want to be?")

	for idx,class in SortedPairs(team.GetClass(teamID)) do
		local displayname = class
		local classTbl = player_class.Get(class)

		if classTbl and classTbl.DisplayName then
			displayname = classTbl.DisplayName
		end

		local description = "Click to spawn as " .. displayname

		if classTbl and classTbl.Description then
			description = classTbl.Description
		end

		local btn = ClassChooser:AddSelectButton(displayname,function()
			if cvClassSuicide:GetBool() then
				RunConsoleCommand("kill")
			end

			RunConsoleCommand("changeclass",idx)
		end,description)

		btn.m_colBackground = team.GetColor(teamID)
	end

	ClassChooser:AddCancelButton()
	ClassChooser:MakePopup()
	ClassChooser:NoFadeIn()
end

net.Receive("ShowGamemodeChooser",function()
	if not GAMEMODE then return end

	GAMEMODE:ShowGamemodeChooser()
end)

net.Receive("ShowMapChooserForGamemode",function()
	if not GAMEMODE then return end

	GAMEMODE:ShowMapChooserForGamemode(net.ReadString())
end)

net.Receive("ShowClassChooser",function()
	if not GAMEMODE then return end

	GAMEMODE:ShowClassChooser(net.ReadUInt(TEAM_BITS))
end)

net.Receive("GamemodeWon",function()
	if not GAMEMODE then return end

	GAMEMODE:GamemodeWon(net.ReadString())
end)

net.Receive("ChangingGamemode",function()
	if not GAMEMODE then return end

	GAMEMODE:ChangingGamemode(net.ReadString(),net.ReadString())
end)
