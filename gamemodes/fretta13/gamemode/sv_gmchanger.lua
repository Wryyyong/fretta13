--[[
	sv_gmchanger.lua - Gamemode Changer (server side)
	-----------------------------------------------------
	Most of the internal stuff for the votes is here and contains stuff you really don't
	want to override.
--]]

g_PlayableGamemodes = g_PlayableGamemodes or {}

fretta_votesneeded = CreateConVar("fretta_votesneeded",0.75,FCVAR_ARCHIVE)
fretta_votetime = CreateConVar("fretta_votetime",20,FCVAR_ARCHIVE)
fretta_votegraceperiod = CreateConVar("fretta_votegraceperiod",30,FCVAR_ARCHIVE)

local function SendAvailableGamemodes(ply)
	net.Start("PlayableGamemodes")
		net.WriteTable(g_PlayableGamemodes)
	net.Send(ply)
end

function GetRandomGamemodeName()
	local choose = g_PlayableGamemodes[math.random(#g_PlayableGamemodes)]

	return choose and choose.key or GAMEMODE.FolderName
end

function GetRandomGamemodeMap(gm)
	local gmTab = g_PlayableGamemodes[gm or GAMEMODE.FolderName]

	return gmTab and gmTab.maps[math.random(#gmTab.maps)] or game.GetMap()
end

function GetNumberOfGamemodeMaps(gm)
	local gmTab = g_PlayableGamemodes[gm or GAMEMODE.FolderName]

	return gmTab and table.Count(gmTab.maps) or 0
end

hook.Add("PlayerInitialSpawn","SendAvailableGamemodes",SendAvailableGamemodes)

local AllMaps = {}
for key,map in ipairs(file.Find("maps/*.bsp","GAME")) do
	AllMaps[key] = string.gsub(map,".bsp","")
end

for _,gm in ipairs(engine.GetGamemodes()) do
	local info = file.Read("gamemodes/" .. gm.name .. "/" .. gm.name .. ".txt","GAME")
	if not info then continue end

	local keyValues = util.KeyValuesToTable(info)
	if keyValues.selectable ~= 1 then continue end

	g_PlayableGamemodes[gm.name] = {
		["key"] = gm.name,
		["name"] = gm.title,
		["label"] = keyValues.title,
		["description"] = keyValues.description,
		["author"] = keyValues.author_name,
		["authorurl"] = keyValues.author_url,
		["maps"] = {},
	}
	local gmTbl = g_PlayableGamemodes[gm.name]

	if keyValues.fretta_maps then
		for _,mapName in ipairs(AllMaps) do
			local mapNameLower = string.lower(mapName)

			for _,map in ipairs(keyValues.fretta_maps) do
				if mapNameLower ~= map then continue end

				gmTbl.maps[#gmTbl.maps + 1] = mapNameLower
			end
		end
	else
		gmTbl.maps = AllMaps
	end

	if keyValues.fretta_maps_disallow then
		for idx,mapName in ipairs(gmTbl.maps) do
			for _,map in ipairs(keyValues.fretta_maps_disallow) do
				if string.lower(mapName) ~= map then continue end

				gmTbl.maps[idx] = nil
			end
		end
	end
end

function GM:IsValidGamemode(gm,map)
	if g_PlayableGamemodes[gm] == nil then
		return false
	end

	if map == nil then
		return true
	end

	for _,mapName in ipairs(g_PlayableGamemodes[gm].maps) do
		if mapName ~= map then continue end

		return true
	end

	return false
end

function GM:VotePlayGamemode(ply,gm)
	if
		not gm
	or	self.WinningGamemode
	or	not self:InGamemodeVote()
	or	not self:IsValidGamemode(gm)
	then return end

	ply:SetNWString("Wants",gm)
end

concommand.Add("votegamemode",function(ply,_,args)
	GAMEMODE:VotePlayGamemode(ply,args[1])
end)

function GM:VotePlayMap(ply,map)
	if
		not map
	or	self.WinningGamemode
	or	not self:InGamemodeVote()
	or	not self:IsValidGamemode(self.WinningGamemode,map)
	then return end

	ply:SetNWString("Wants",map)
end

concommand.Add("votemap",function(ply,_,args)
	GAMEMODE:VotePlayMap(ply,args[1])
end)

function GM:GetFractionOfPlayersThatWantChange()
	local humans = player.GetHumans()
	local numHumans = #humans
	local wantsChange = 0

	for _,ply in pairs(humans) do
		if ply:GetNWBool("WantsVote") then
			wantsChange = wantsChange + 1
		end

		-- Don't count players that aren't connected yet
		if ply:IsConnected() then continue end
		numHumans = numHumans - 1
	end

	return wantsChange / numHumans,numHumans,wantsChange
end

function GM:GetVotesNeededForChange()
	local _,numHumans,wantsChange = GAMEMODE:GetFractionOfPlayersThatWantChange()

	return math.ceil(fretta_votesneeded:GetFloat() * numHumans) - wantsChange
end

function GM:CountVotesForChange()
	 -- can't vote too early on
	if CurTime() >= fretta_votegraceperiod:GetFloat() then
		if self:InGamemodeVote() then return end

		if self:GetFractionOfPlayersThatWantChange() > fretta_votesneeded:GetFloat() then
			self:StartGamemodeVote()

			return false
		end
	end

	return true
end

function GM:VoteForChange(ply)
	if not fretta_voting:GetBool() or ply:GetNWBool("WantsVote") then return end
	ply:SetNWBool("WantsVote",true)

	local votesNeeded = self:GetVotesNeededForChange()
	local needTxt = ""

	if votesNeeded > 0 and CurTime() >= fretta_votegraceperiod:GetFloat() then
		needTxt = ",Color(80,255,50),[[ (need " .. votesNeeded .. " more)]]"
	end

	-- can't vote too early on
	BroadcastLua("chat.AddText(Entity(" .. ply:EntIndex() .. "),color_white,[[ voted to change the gamemode]]" .. needTxt .. ")")

	MsgN(ply:GetName() .. " voted to change the gamemode")

	timer.Simple(5,function()
		self:CountVotesForChange()
	end)
end

concommand.Add("VoteForChange",function(ply)
	GAMEMODE:VoteForChange(ply)
end)

timer.Create("VoteForChangeThink",10,0,function()
	if not GAMEMODE then return end

	GAMEMODE:CountVotesForChange()
end)

function GM:ClearPlayerWants()
	for _,ply in player.Iterator() do
		ply:SetNWString("Wants","")
	end
end

function GM:StartGamemodeVote()
	if GAMEMODE.m_bVotingStarted then return end
	SetGlobalBool("InGamemodeVote",true)

	if fretta_voting:GetBool() then
		if table.Count(g_PlayableGamemodes) >= 2 then
			self:ClearPlayerWants()

			net.Start("ShowGamemodeChooser")
			net.Broadcast()

			local voteTime = fretta_votetime:GetFloat()
			SetGlobalFloat("VoteEndTime",CurTime() + voteTime)

			timer.Simple(voteTime,function()
				self:FinishGamemodeVote()
			end)
		else
			self.WinningGamemode = self:WorkOutWinningGamemode()
			self:StartMapVote()
		end
	else
		self.WinningGamemode = self.FolderName
		self:StartMapVote()
	end

	self.m_bVotingStarted = true
end

function GM:StartMapVote()
	-- If there's only one map, let the 'random map' thing choose it
	if GetNumberOfGamemodeMaps(self.WinningGamemode) == 1 then
		return self:FinishMapVote(true)
	end

	net.Start("ShowMapChooserForGamemode")
		net.WriteString(self.WinningGamemode)
	net.Broadcast()

	local voteTime = fretta_votetime:GetFloat()
	SetGlobalFloat("VoteEndTime",CurTime() + voteTime)

	timer.Simple(voteTime,function()
		self:FinishMapVote()
	end)
end

function GM:GetWinningWant()
	local votes = {}

	for _,ply in player.Iterator() do
		local want = ply:GetNWString("Wants",nil)
		if not want or want == "" then continue end

		votes[want] = votes[want] and votes[want] + 1 or 0
	end

	return table.GetWinningKey(votes)
end

function GM:WorkOutWinningGamemode()
	if self.WinningGamemode then
		return self.WinningGamemode
	end

	-- Gamemode Voting disabled, return current gamemode
	if not fretta_voting:GetBool() then
		return self.FolderName
	end

	local winner = self:GetWinningWant()
	if not winner then
		return GetRandomGamemodeName()
	end

	return winner
end

function GM:GetWinningMap()
	if self.WinningMap then
		return self.WinningMap
	end

	local winner = self:GetWinningWant()
	if not winner then
		return GetRandomGamemodeMap(self.WinningGamemode)
	end

	return winner
end

function GM:FinishGamemodeVote()
	self.WinningGamemode = self:WorkOutWinningGamemode()
	self:ClearPlayerWants()

	-- Send bink bink notification
	net.Start("GamemodeWon")
		net.WriteString(self.WinningGamemode)
	net.Broadcast()

	-- Start map vote..
	timer.Simple(2,function()
		self:StartMapVote()
	end)
end

function GM:FinishMapVote()
	self.WinningMap = self:GetWinningMap()
	self:ClearPlayerWants()

	if self.WinningMap then
		-- Send bink bink notification
		net.Start("ChangingGamemode")
			net.WriteString(self.WinningGamemode)
			net.WriteString(self.WinningMap)
		net.Broadcast()

		-- Start map vote?
		timer.Simple(3,function()
			self:ChangeGamemode()
		end)
	else
		-- Notifies the server owner of the issue
		ErrorNoHalt("No maps for this gamemode, forcing map to gm_construct\nPlease change this as soon as you can!\n")

		--Picks gm_construct to prevent the server from halting
		self.WinningMap = "gm_construct"

		timer.Simple(3,function()
			RunConsoleCommand("gamemode",self:WorkOutWinningGamemode())
			RunConsoleCommand("changelevel",self.WinningMap)
		end)
	end
end

function GM:ChangeGamemode()
	RunConsoleCommand("gamemode",self:WorkOutWinningGamemode())
	RunConsoleCommand("changelevel",self:GetWinningMap())
end
