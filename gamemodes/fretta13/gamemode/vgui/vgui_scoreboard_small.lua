local TeamBoardSmall = {}
Derma_Hook(TeamBoardSmall,"Paint","Paint","SpectatorInfo")
Derma_Hook(TeamBoardSmall,"ApplySchemeSettings","Scheme","SpectatorInfo")
Derma_Hook(TeamBoardSmall,"PerformLayout","Layout","SpectatorInfo")

function TeamBoardSmall:Init()
	self.LastThink = 0
end

function TeamBoardSmall:Setup(iTeam)
	self.iTeam = iTeam
end

function TeamBoardSmall:GetPlayers()
	return team.GetPlayers(self.iTeam)
end

function TeamBoardSmall:ShouldShow()
	local players = team.GetPlayers(self.iTeam)

	return players and #players > 0
end

function TeamBoardSmall:UpdateText(newText)
	if self:GetValue() == newText then return end

	self:SetText(newText)
	self:SizeToContents()
	self:InvalidateLayout()
	self:GetParent():InvalidateLayout()
end

function TeamBoardSmall:Think()
	local realTime = RealTime()
	if self.LastThink > realTime then return end

	self.LastThink = realTime + 1
	local players = team.GetPlayers(self.iTeam)

	if not players or #players == 0 then
		self:UpdateText("")

		return
	end

	local str = team.GetName(self.iTeam) .. ": "

	for _,ply in ipairs(players) do
		str = str .. ply:Name() .. ", "
	end

	str = str:sub(0,-3)
	self:UpdateText(str)
end

derma.DefineControl("TeamBoardSmall","",TeamBoardSmall,"DLabel")
