local TeamScoreboardHeader = {}
Derma_Hook(TeamScoreboardHeader,"Paint","Paint","TeamScoreboardHeader")
Derma_Hook(TeamScoreboardHeader,"ApplySchemeSettings","Scheme","TeamScoreboardHeader")
Derma_Hook(TeamScoreboardHeader,"PerformLayout","Layout","TeamScoreboardHeader")

function TeamScoreboardHeader:Init()
	self.Columns = {}
	self.iTeamID = 0
	self.PlayerCount = 0
	self.TeamName = vgui.Create("DLabel",self)
	self.TeamScore = vgui.Create("DLabel",self)
end

function TeamScoreboardHeader:Setup(iTeam)
	self.TeamName:SetText(team.GetName(iTeam))
	self.iTeamID = iTeam
end

function TeamScoreboardHeader:Think()
	local count = #team.GetPlayers(self.iTeamID)

	if self.PlayerCount ~= count then
		self.PlayerCount = count
		self.TeamName:SetText(team.GetName(self.iTeamID) .. " (" .. count .. " Players)")
	end

	self.TeamScore:SetText(team.GetScore(self.iTeamID))
end

derma.DefineControl("TeamScoreboardHeader","",TeamScoreboardHeader,"Panel")

local TeamScoreboard = {}

function TeamScoreboard:Init()
	self.Columns = {}

	local boardList = vgui.Create("DListView",self)
	self.List = boardList
	boardList:SetSortable(false)
	boardList:DisableScrollbar()
	boardList:SetMultiSelect(false)

	self.Header = vgui.Create("TeamScoreboardHeader",self)
end

function TeamScoreboard:Setup(iTeam,pMainScoreboard)
	self.iTeam = iTeam
	self.pMain = pMainScoreboard
	self.Header:Setup(iTeam,pMainScoreboard)
end

function TeamScoreboard:SizeToContents()
	local boardList = self.List

	boardList:SizeToContents()
	self:SetTall(boardList:GetTall() + self.Header:GetTall())
end

function TeamScoreboard:PerformLayout()
	local main,header,boardList = self.pMain,self.Header,self.List

	if main:GetShowScoreboardHeaders() then
		header:SetPos(0,0)
		header:CopyWidth(self)
	else
		header:SetTall(0)
		header:SetVisible(false)
	end

	self:SizeToContents()
	boardList:StretchToParent(0,header:GetTall(),0,0)
	boardList:SetDataHeight(main:GetRowHeight())
	boardList:SetHeaderHeight(16)
end

function TeamScoreboard:AddColumn(col)
	local columns = self.Columns
	columns[#columns + 1] = col

	local pnlCol = self.List:AddColumn(col.Name)
	if col.iFixedSize then
		pnlCol:SetMinWidth(col.iFixedSize)
		pnlCol:SetMaxWidth(col.iFixedSize)
	end

	local header = pnlCol.Header
	if col.HeaderAlign then
		header:SetContentAlignment(col.HeaderAlign)
	end

	Derma_Hook(pnlCol,"Paint","Paint","ScorePanelHeader")
	pnlCol.cTeamColor = team.GetColor(self.iTeam)

	Derma_Hook(header,"Paint","Paint","ScorePanelHeaderLabel")
	Derma_Hook(header,"ApplySchemeSettings","Scheme","ScorePanelHeaderLabel")
	Derma_Hook(header,"PerformLayout","Layout","ScorePanelHeaderLabel")
	header:ApplySchemeSettings()
end

function TeamScoreboard:SetSortColumns(...)
	self.SortArgs = ...
end

local function LinePressed(self,mcode)
	if not (mcode == MOUSE_LEFT and IsValid(self.pPlayer)) then return end

	gamemode.Call("ScoreboardPlayerPressed",self.pPlayer)
end

function TeamScoreboard:FindPlayerLine(ply)
	local boardList = self.List

	for _,line in pairs(boardList.Lines) do
		if line.pPlayer ~= ply then continue end

		return line
	end

	local newLine = boardList:AddLine()
	newLine.pPlayer = ply
	newLine.UpdateTime = {}
	newLine.OnMousePressed = LinePressed
	Derma_Hook(newLine,"Paint","Paint","ScorePanelLine")
	Derma_Hook(newLine,"ApplySchemeSettings","Scheme","ScorePanelLine")
	Derma_Hook(newLine,"PerformLayout","Layout","ScorePanelLine")

	self.pMain:InvalidateLayout()

	return newLine
end

function TeamScoreboard:UpdateColumn(idx,col,pLine)
	if not col.fncValue then return end

	local updateTime,realTime = pLine.UpdateTime[idx],RealTime()
	pLine.UpdateTime[idx] = updateTime[idx] or 0

	-- 0 = only update once
	if
		(
			col.UpdateRate == 0
		and	updateTime[idx] ~= 0
	)
	or	updateTime[idx] > realTime
	then return end

	pLine.UpdateTime[idx] = realTime + col.UpdateRate

	local value = col.fncValue(pLine.pPlayer)
	if value == nil then return end

	local lbl = pLine:SetColumnText(idx,value)
	if not IsValid(lbl) or lbl.bScorePanelHooks then return end

	lbl.bScorePanelHooks = true

	if col.ValueAlign then
		lbl:SetContentAlignment(col.ValueAlign)
	end

	if col.Font then
		lbl:SetFont(col.Font)
	end

	lbl.pPlayer = pLine.pPlayer
	Derma_Hook(lbl,"Paint","Paint","ScorePanelLabel")
	Derma_Hook(lbl,"ApplySchemeSettings","Scheme","ScorePanelLabel")
	Derma_Hook(lbl,"PerformLayout","Layout","ScorePanelLabel")
end

function TeamScoreboard:UpdateLine(pLine)
	for idx,col in ipairs(self.Columns) do
		self:UpdateColumn(idx,col,pLine)
	end
end

function TeamScoreboard:CleanLines()
	local boardList = self.List

	for idx,line in pairs(boardList.Lines) do
		local ply = line.pPlayer

		if
			not IsValid(ply)
		or	ply:Team() == self.iTeam
		then continue end

		boardList:RemoveLine(idx)
	end
end

function TeamScoreboard:Think()
	self:CleanLines()

	for _,ply in ipairs(team.GetPlayers(self.iTeam)) do
		self:UpdateLine(self:FindPlayerLine(ply))
	end

	if not self.SortArgs then return end
	self.List:SortByColumns(unpack(self.SortArgs))
end

derma.DefineControl("TeamScoreboard","",TeamScoreboard,"Panel")
