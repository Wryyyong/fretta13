include("vgui/vgui_vote.lua")

g_PlayableGamemodes = g_PlayableGamemodes or {}

net.Receive("PlayableGamemodes",function()
	g_PlayableGamemodes = net.ReadTable()
	g_bGotGamemodesTable = true
end)

local function GetVoteScreen()
	LocalPlayer():ConCommand("-score")

	if IsValid(g_VGUI_VoteScreen) then
		return g_VGUI_VoteScreen
	end

	g_VGUI_VoteScreen = vgui.Create("VoteScreen")

	return g_VGUI_VoteScreen
end

function GM:ShowGamemodeChooser()
	local voteScreen = GetVoteScreen()

	voteScreen:ChooseGamemode()
end

function GM:GamemodeWon(mode)
	local voteScreen = GetVoteScreen()

	voteScreen:FlashItem(mode)
end

function GM:ChangingGamemode(_,map)
	local voteScreen = GetVoteScreen()

	voteScreen:FlashItem(map)
end

function GM:ShowMapChooserForGamemode(gmName)
	local voteScreen = GetVoteScreen()

	voteScreen:ChooseMap(gmName)
end

local cvClassSuicide = CreateConVar("cl_classsuicide",0,FCVAR_ARCHIVE,nil,0,1)

function GM:ShowClassChooser(teamID)
	if not self.SelectClass then return end

	if g_VGUI_ClassChooser then
		g_VGUI_ClassChooser:Remove()
	end

	local classChooser = vgui.CreateFromTable(g_VGUI_Select)
	g_VGUI_ClassChooser = classChooser
	classChooser:SetHeaderText("Choose Class")
	classChooser:SetHoverText("What class do you want to be?")

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

		local btn = classChooser:AddSelectButton(displayname,function()
			if cvClassSuicide:GetBool() then
				RunConsoleCommand("kill")
			end

			RunConsoleCommand("changeclass",idx)
		end,description)

		btn.m_colBackground = team.GetColor(teamID)
	end

	classChooser:AddCancelButton()
	classChooser:MakePopup()
	classChooser:NoFadeIn()
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
