local VoteScreen = {}

function VoteScreen:Init()
	self:SetSkin(GAMEMODE.HudSkin)
	self:ParentToHUD()

	local ctrlCanvas = vgui.Create("Panel",self)
	self.ControlCanvas = ctrlCanvas
	ctrlCanvas:MakePopup()
	ctrlCanvas:SetKeyboardInputEnabled(false)

	self.lblCountDown = vgui.Create("DLabel",ctrlCanvas)
	self.lblCountDown:SetText("60")

	self.lblActionName = vgui.Create("DLabel",ctrlCanvas)

	local ctrlList = vgui.Create("DPanelList",ctrlCanvas)
	self.ctrlList = ctrlList
	ctrlList:SetPaintBackground(false)
	ctrlList:SetSpacing(2)
	ctrlList:SetPadding(2)
	ctrlList:EnableHorizontal(true)
	ctrlList:EnableVerticalScrollbar()

	self.Peeps = {}

	local canvas = ctrlList:GetCanvas()

	for idx = 1,game.MaxPlayers() do
		local peep = vgui.Create("DImage",canvas)
		self.Peeps[idx] = peep

		peep:SetSize(16,16)
		peep:SetZPos(1000)
		peep:SetVisible(false)
		peep:SetImage("icon16/emoticon_smile.png")
	end
end

function VoteScreen:PerformLayout()
	local _,cy = chat.GetChatBoxPos()

	self:SetPos(0,0)
	self:SetSize(ScrW(),ScrH())

	local ctrlCanvas = self.ControlCanvas
	ctrlCanvas:StretchToParent(0,0,0,0)
	ctrlCanvas:SetWide(550)
	ctrlCanvas:SetTall(cy - 30)
	ctrlCanvas:SetPos(0,30)
	ctrlCanvas:CenterHorizontal()
	ctrlCanvas:SetZPos(0)

	local countdown = self.lblCountDown
	countdown:SetFont("FRETTA_MEDIUM_SHADOW")
	countdown:AlignRight()
	countdown:SetTextColor(color_white)
	countdown:SetContentAlignment(6)
	countdown:SetWidth(500)

	local actionName = self.lblActionName
	actionName:SetFont("FRETTA_LARGE_SHADOW")
	actionName:AlignLeft()
	actionName:SetTextColor(color_white)
	actionName:SizeToContents()
	actionName:SetWidth(500)

	self.ctrlList:StretchToParent(0,60,0,0)
end

function VoteScreen:ChooseGamemode()
	local ctrlList = self.ctrlList

	self.lblActionName:SetText("Which Gamemode Next?")
	ctrlList:Clear()

	for name,tbl in RandomPairs(g_PlayableGamemodes) do
		local lbl = vgui.Create("DButton",ctrlList)
		lbl:SetText(tbl.label or name)
		Derma_Hook(lbl,"Paint","Paint","GamemodeButton")
		Derma_Hook(lbl,"ApplySchemeSettings","Scheme","GamemodeButton")
		Derma_Hook(lbl,"PerformLayout","Layout","GamemodeButton")
		lbl:SetTall(24)
		lbl:SetWide(240)

		local desc = tostring(tbl.description)

		if tbl.author then
			desc = desc .. "\n\nBy: " .. tostring(tbl.author)
		end

		if tbl.authorurl then
			desc = desc .. "\n" .. tostring(tbl.authorurl)
		end

		lbl:SetTooltip(desc)
		lbl.WantName = name
		lbl.NumVotes = 0

		lbl.DoClick = function()
			if GetGlobalFloat("VoteEndTime",0) - CurTime() <= 0 then return end

			RunConsoleCommand("votegamemode",name)
		end

		ctrlList:AddItem(lbl)
	end
end

function VoteScreen:ChooseMap(gm)
	local ctrlList = self.ctrlList

	self.lblActionName:SetText("Which Map?")
	self:ResetPeeps()
	ctrlList:Clear()

	local gmTbl = g_PlayableGamemodes[gm]

	if not gmTbl then
		MsgN("GAMEMODE MISSING, COULDN'T VOTE FOR MAP ",gm)

		return
	end

	for _,mapName in RandomPairs(gmTbl.maps) do
		local lbl = vgui.Create("DButton",ctrlList)
		lbl:SetText(mapName)
		Derma_Hook(lbl,"Paint","Paint","GamemodeButton")
		Derma_Hook(lbl,"ApplySchemeSettings","Scheme","GamemodeButton")
		Derma_Hook(lbl,"PerformLayout","Layout","GamemodeButton")
		lbl:SetTall(24)
		lbl:SetWide(240)
		lbl.WantName = mapName
		lbl.NumVotes = 0

		lbl.DoClick = function()
			if GetGlobalFloat("VoteEndTime",0) - CurTime() <= 0 then return end

			RunConsoleCommand("votemap",mapName)
		end

		ctrlList:AddItem(lbl)
	end
end

function VoteScreen:ResetPeeps()
	for idx = 1,game.MaxPlayers() do
		local peep = self.Peeps[idx]

		peep:SetPos(math.random(0,600),-16)
		peep:SetVisible(false)
		peep.strVote = nil
	end
end

function VoteScreen:FindWantBar(name)
	for _,item in ipairs(self.ctrlList:GetItems()) do
		if item.WantName ~= name then continue end

		return item
	end
end

function VoteScreen:PeepThink(peep,ent)
	if not IsValid(ent) then
		peep:SetVisible(false)

		return
	end

	peep:SetTooltip(ent:GetName())
	peep:SetMouseInputEnabled(true)

	if not peep.strVote then
		peep:SetVisible(true)
		peep:SetPos(math.random(0,600),-16)

		if ent == LocalPlayer() then
			peep:SetImage("icon16/star.png")
		end
	end

	peep.strVote = ent:GetNWString("Wants","")

	local bar = self:FindWantBar(peep.strVote)
	if not IsValid(bar) then return end

	bar.NumVotes = bar.NumVotes + 1
	--local vCurrentPos = Vector(peep.x,peep.y,0)
	local vNewPos = Vector((bar.x + bar:GetWide()) - 15 * bar.NumVotes - 4,bar.y + (bar:GetTall() * 0.5 - 8),0)

	if peep.CurPos and peep.CurPos == vNewPos then return end
	peep:MoveTo(vNewPos[1],vNewPos[2],0.2)
	peep.CurPos = vNewPos
end

function VoteScreen:Think()
	local seconds = GetGlobalFloat("VoteEndTime",0) - CurTime()

	if seconds < 0 then
		seconds = 0
	end

	self.lblCountDown:SetText(Format("%i",seconds))

	for _,item in ipairs(self.ctrlList:GetItems()) do
		item.NumVotes = 0
	end

	for idx = 1,game.MaxPlayers() do
		self:PeepThink(self.Peeps[idx],Entity(idx))
	end
end

function VoteScreen:Paint()
	Derma_DrawBackgroundBlur(self)

	surface.SetDrawColor(0,0,0,200)
	surface.DrawRect(0,0,ScrW(),ScrH())
end

local ColorFlashOn = Color(0,255,255)
local ColorFlashOff = Color(100,100,100)

function VoteScreen:FlashItem(itemname)
	local bar = self:FindWantBar(itemname)
	if not IsValid(bar) then return end

	local function flashOn()
		bar.bgColor = ColorFlashOn

		surface.PlaySound("hl1/fvox/blip.wav")
	end

	local function flashOff()
		bar.bgColor = nil
	end

	timer.Simple(0,flashOn)
	timer.Simple(0.2,flashOff)
	timer.Simple(0.4,flashOn)
	timer.Simple(0.6,flashOff)
	timer.Simple(0.8,flashOn)

	timer.Simple(1.0,function()
		bar.bgColor = ColorFlashOff
	end)
end

derma.DefineControl("VoteScreen","",VoteScreen,"DPanel")
