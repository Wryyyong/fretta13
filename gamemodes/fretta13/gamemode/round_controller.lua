function GM:SetRoundWinner(ply,resulttext)
	SetGlobalEntity("RoundWinner",ply)
	SetGlobalString("RRText",tostring(resulttext))
end

function GM:SetRoundResult(i,resulttext)
	SetGlobalInt("RoundResult",i)
	SetGlobalString("RRText",tostring(resulttext))
end

function GM:ClearRoundResult()
	SetGlobalEntity("RoundWinner",NULL)
	SetGlobalInt("RoundResult",0)
	SetGlobalString("RRText","")
end

function GM:SetInRound(b)
	SetGlobalBool("InRound",b)
end

function GM:InRound()
	return GetGlobalBool("InRound",false)
end

function GM:OnRoundStart()
	UTIL_UnFreezeAllPlayers()
end

function GM:OnRoundEnd()
end

function GM:OnRoundResult(result)
	-- The fact that result might not be a team 
	-- shouldn't matter when calling this..
	team.AddScore(result,1)
end

function GM:OnRoundWinner(ply)
	-- Do whatever you want to do with the winner here (this is only called in Free For All gamemodes)...
	ply:AddFrags(1)
end

function GM:OnPreRoundStart()
	game.CleanUpMap()

	UTIL_StripAllPlayers()
	UTIL_SpawnAllPlayers()
	UTIL_FreezeAllPlayers()
end

function GM:CanStartRound()
	return true
end

function GM:StartRoundBasedGame()
	self:PreRoundStart(1)
end

-- Number of rounds
function GM:GetRoundLimit()
	return self.RoundLimit
end

-- Has the round limit been reached?
function GM:HasReachedRoundLimit(iNum)
	local iRoundLimit = self:GetRoundLimit()

	return iRoundLimit > 0 and iNum > iRoundLimit
end

-- This is for the timer-based game end. set this to return true if you want it to end mid-round
function GM:CanEndRoundBasedGame()
	return false
end

-- You can add round time by calling this (takes time in seconds)
function GM:AddRoundTime(fAddedTime)
	if not self:InRound() then return end-- don't add time if round is not in progress

	local newEndTime = GetGlobalFloat("RoundEndTime",CurTime()) + fAddedTime
	SetGlobalFloat("RoundEndTime",newEndTime)

	timer.Adjust("RoundEndTimer",newEndTime - GetGlobalFloat("RoundStartTime"),0,function()
		self:RoundTimerEnd()
	end)

	net.Start("RoundAddedTime")
		net.WriteFloat(fAddedTime)
	net.Broadcast()
end

-- This gets the timer for a round (you can make round number dependant round lengths, or make it cvar controlled)
function GM:GetRoundTime()
	return self.RoundLength
end

-- Internal, override OnPreRoundStart if you want to do stuff here
function GM:PreRoundStart(iNum)
	local curTime = CurTime()

	-- Should the game end?
	if curTime >= self:GetTimeLimit() or self:HasReachedRoundLimit(iNum) then
		self:EndOfGame(true)

		return
	end

	if not self:CanStartRound(iNum) then
		-- In a second, check to see if we can start
		timer.Simple(1,function()
			self:PreRoundStart(iNum)
		end)

		return
	end

	timer.Simple(self.RoundPreStartTime,function()
		self:RoundStart()
	end)

	SetGlobalInt("RoundNumber",iNum)
	SetGlobalFloat("RoundStartTime",curTime + self.RoundPreStartTime)

	self:ClearRoundResult()
	self:OnPreRoundStart(GetGlobalInt("RoundNumber"))
	self:SetInRound(true)
end

-- Internal, override OnRoundStart if you want to do stuff here
function GM:RoundStart()
	local roundNum = GetGlobalInt("RoundNumber")
	local roundDuration = self:GetRoundTime(roundNum)

	self:OnRoundStart(roundNum)

	timer.Create("RoundEndTimer",roundDuration,0,function()
		self:RoundTimerEnd()
	end)

	timer.Create("CheckRoundEnd",1,0,function()
		self:CheckRoundEnd()
	end)

	SetGlobalFloat("RoundEndTime",CurTime() + roundDuration)
end

-- Decide what text should show when a team/player wins
function GM:ProcessResultText(_,resulttext)
	if resulttext == nil then
		resulttext = ""
	end

	-- the result could either be a number or a player!
	-- for a free for all you could do... if type(result) == "Player" and IsValid( result ) then return result:Name().." is the winner" or whatever
	return resulttext
end

-- Round Ended with Result
function GM:RoundEndWithResult(result,resulttext)
	resulttext = self:ProcessResultText(result,resulttext)

	local setFunc,onFunc

	if type(result) == "number" then
		-- the result is a team ID
		setFunc = self.SetRoundResult
		onFunc = self.OnRoundResult
	else
		-- the result is a player
		setFunc = self.SetRoundWinner
		onFunc = self.OnRoundWinner
	end

	setFunc(self,result,resulttext)
	self:RoundEnd()
	onFunc(self,result,resulttext)
end

-- Internal, override OnRoundEnd if you want to do stuff here
function GM:RoundEnd()
	if not self:InRound() then
		-- if someone uses RoundEnd incorrectly then do a trace.
		MsgN("WARNING: RoundEnd being called while gamemode not in round...")
		debug.Trace()

		return
	end

	local roundNum = GetGlobalInt("RoundNumber")

	self:OnRoundEnd(roundNum)
	self:SetInRound(false)
	timer.Remove("RoundEndTimer")
	timer.Remove("CheckRoundEnd")
	SetGlobalFloat("RoundEndTime",-1)
	timer.Simple(self.RoundPostLength,function()
		self:PreRoundStart(roundNum + 1)
	end)
end

function GM:GetTeamAliveCounts()
	local teamCounter = {}

	for _,ply in player.Iterator() do
		local plyTeam = ply:Team()

		if
			not (
				ply:Alive()
			and	plyTeam > TEAM_CONNECTING
			and	plyTeam < TEAM_UNASSIGNED
		)
		then continue end

		teamCounter[plyTeam] = teamCounter[plyTeam] and teamCounter[plyTeam] + 1 or 1
	end

	return teamCounter
end

-- For round based games that end when a team is dead
function GM:CheckPlayerDeathRoundEnd()
	if not (self.RoundBased and self:InRound() and self.RoundEndsWhenOneTeamAlive) then return end

	local teams = self:GetTeamAliveCounts()
	local teamCount = table.Count(teams)

	if teamCount == 0 then
		self:RoundEndWithResult(TEAM_UNASSIGNED,"Draw, everyone loses!")
	elseif teamCount == 1 then
		self:RoundEndWithResult(1)
	end
end

local function RoundCheck()
	timer.Simple(0.2,function()
		GAMEMODE:CheckPlayerDeathRoundEnd()
	end)
end

hook.Add("PlayerDisconnected","RoundCheck_PlayerDisconnect",RoundCheck)
hook.Add("PostPlayerDeath","RoundCheck_PostPlayerDeath",RoundCheck)

-- You should use this to check any round end conditions 
function GM:CheckRoundEnd()
	-- Do checks.. 
	-- if something then call GAMEMODE:RoundEndWithResult( TEAM_BLUE, "Team Blue Ate All The Mushrooms!" )
	-- OR for a free for all you could do something like... GAMEMODE:RoundEndWithResult( SomePlayer )
end

function GM:CheckRoundEndInternal()
	if not self:InRound() then return end

	self:CheckRoundEnd()

	timer.Create("CheckRoundEnd",1,0,function()
		self:CheckRoundEndInternal()
	end)
end

-- This is called when the round time ends.
function GM:RoundTimerEnd()
	if not self:InRound() then return end

	local ply = self:SelectCurrentlyWinningPlayer()

	self:RoundEndWithResult((self.TeamBased and IsValid(ply)) and ply or -1,"Time Up")
end

-- This is called when time runs out and there is no winner chosen yet (free for all gamemodes only)
-- By default it chooses the player with the most frags but you can edit this to do what you need..
function GM:SelectCurrentlyWinningPlayer()
	local topScore,winner = 0

	for _,ply in player.Iterator() do
		local plyFrags,plyTeam = ply:Frags(),ply:Team()

		if
			plyFrags <= topScore
		or	plyTeam <= TEAM_CONNECTING
		or	plyTeam >= TEAM_UNASSIGNED
		then continue end

		winner = ply
		topScore = plyFrags
	end

	return winner
end
