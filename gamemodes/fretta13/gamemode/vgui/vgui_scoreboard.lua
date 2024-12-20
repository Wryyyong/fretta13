include("vgui_scoreboard_team.lua")
include("vgui_scoreboard_small.lua")

local ScoreboardHeader = {}
Derma_Hook(ScoreboardHeader,"Paint","Paint","ScoreHeader")
Derma_Hook(ScoreboardHeader,"ApplySchemeSettings","Scheme","ScoreHeader")
Derma_Hook(ScoreboardHeader,"PerformLayout","Layout","ScoreHeader")

function ScoreboardHeader:Init()
	self.Columns = {}
	self.iTeamID = 0

	self.HostName = vgui.Create("DLabel",self)
	self.HostName:SetText(GetHostName())

	self.GamemodeName = vgui.Create("DLabel",self)
	self.GamemodeName:SetText(GAMEMODE.Name)

	self:SetHeight(64)
end

derma.DefineControl("ScoreboardHeader","",ScoreboardHeader,"Panel")

local FrettaScoreboard = {}
AccessorFunc(FrettaScoreboard,"m_bHorizontal","Horizontal")
AccessorFunc(FrettaScoreboard,"m_iPadding","Padding")
AccessorFunc(FrettaScoreboard,"m_iRowHeight","RowHeight")
AccessorFunc(FrettaScoreboard,"m_bShowScoreHeaders","ShowScoreboardHeaders")
Derma_Hook(FrettaScoreboard,"Paint","Paint","ScorePanel")
Derma_Hook(FrettaScoreboard,"ApplySchemeSettings","Scheme","ScorePanel")
Derma_Hook(FrettaScoreboard,"PerformLayout","Layout","ScorePanel")

function FrettaScoreboard:Init()
	self.SortDesc = true
	self.Boards = {}
	self.SmallBoards = {}
	self.Columns = {}
	self:SetRowHeight(32)
	self:SetHorizontal(false)
	self:SetPadding(10)
	self:SetShowScoreboardHeaders(true)
	self.Header = vgui.Create("ScoreboardHeader",self)

	for teamID in pairs(team.GetAllTeams()) do
		local scoreboard = vgui.Create("TeamScoreboard",self)

		scoreboard:Setup(teamID,self)
		self.Boards[teamID] = scoreboard
	end

	self:MakePopup()
end

function FrettaScoreboard:SetAsBullshitTeam(iTeamID)
	local teamBoard = self.Boards[iTeamID]

	if IsValid(teamBoard) then
		teamBoard:Remove()
		self.Boards[iTeamID] = nil
	end

	self.SmallBoards[iTeamID] = vgui.Create("TeamBoardSmall",self)
	self.SmallBoards[iTeamID]:Setup(iTeamID,self)
end

function FrettaScoreboard:SetSortColumns(...)
	for _,board in pairs(self.Boards) do
		board:SetSortColumns(...)
	end
end

function FrettaScoreboard:AddColumn(name,iFixedSize,fncValue,updateRate,teamID,headerAlign,valueAlign,font)
	local col = {
		["Name"] = name,
		["iFixedSize"] = iFixedSize,
		["fncValue"] = fncValue,
		["TeamID"] = teamID,
		["UpdateRate"] = updateRate,
		["ValueAlign"] = valueAlign,
		["HeaderAlign"] = headerAlign,
		["Font"] = font,
	}

	for _,board in pairs(self.Boards) do
		board:AddColumn(col)
	end

	return col
end

function FrettaScoreboard:Layout4By4(y)
	local boards = self.Boards
	local boardA,boardB,boardC,boardD = boards[1],boards[2],boards[3],boards[4]
	local width = (self:GetWide() - self.m_iPadding * 3) / 2

	for _,board in pairs(boards) do
		board:SizeToContents()
		board:SetWide(width)
	end

	boardA:SetPos(self.m_iPadding,y + self.m_iPadding)
	boardB:SetPos(boardA:GetPos() + boardA:GetWide() + self.m_iPadding,y + self.m_iPadding)

	local height = math.max(
		boardB:GetTall() + boardB.y,
		boardA:GetTall() + boardA.y
	) + self.m_iPadding * 2

	boardC:SetPos(self.m_iPadding,height)
	boardD:SetPos(boardC:GetPos() + boardC:GetWide() + self.m_iPadding,height)

	return math.max(
		boardC:GetTall() + boardC.y,
		boardD:GetTall() + boardD.y
	) + self.m_iPadding * 2
end

function FrettaScoreboard:LayoutHorizontal(y)
	local cols = table.Count(self.Boards)

	if cols == 4 then
		return self:Layout4By4(y)
	end

	local width = (self:GetWide() - self.m_iPadding * (cols + 1)) / cols
	local x = self.m_iPadding
	local tallest = 0

	for _,board in pairs(self.Boards) do
		board:SizeToContents()
		board:SetPos(x,y)
		board:SetWide(width)
		x = x + width + self.m_iPadding
		tallest = math.max(tallest,y + board:GetTall() + self.m_iPadding)
	end

	return tallest
end

function FrettaScoreboard:LayoutVertical(y)
	local newY = y

	for _,board in pairs(self.Boards) do
		local padding = self.m_iPadding

		board:SizeToContents()
		board:SetPos(padding,newY)
		board:SetWide(self:GetWide() - padding * 2)

		newY = newY + board:GetTall() + padding
	end

	return newY
end

function FrettaScoreboard:PerformLayout()
	local y = 0
	local header,padding = self.Header,self.m_iPadding

	if IsValid(header) then
		header:SetPos(0,0)
		header:SetWidth(self:GetWide())
		y = y + header:GetTall() + padding
	end

	if self.m_bHorizontal then
		y = self:LayoutHorizontal(y)
	else
		y = self:LayoutVertical(y)
	end

	for _,board in pairs(self.SmallBoards) do
		if not board:ShouldShow() then continue end

		board:SizeToContents()
		board:SetPos(self.m_iPadding,y)
		board:CenterHorizontal()

		y = y + board:GetTall() + padding
	end
end

derma.DefineControl("FrettaScoreboard","",FrettaScoreboard,"DPanel")
