--[[
	This is the player death panel. This should be parented to a DeathMessage_Panel. The DeathMessage_Panel that
	it's parented to controls aspects such as the position on screen. All this panel's job is to print the
	specific death it's been given and fade out before its RetireTime.
--]]

-- client cvars to control deathmsgs
--local hud_deathnotice_time = CreateConVar("hud_deathnotice_time",6,FCVAR_ARCHIVE)
--local hud_deathnotice_limit = CreateConVar("hud_deathnotice_limit",5,FCVAR_ARCHIVE)

local GameNotice = {}

Derma_Hook(GameNotice,"Paint","Paint","GameNotice")
Derma_Hook(GameNotice,"ApplySchemeSettings","Scheme","GameNotice")
Derma_Hook(GameNotice,"PerformLayout","Layout","GameNotice")

function GameNotice:Init()
	self.m_bHighlight = false
	self.Padding = 8
	self.Spacing = 8
	self.Items = {}
end

function GameNotice:AddEntityText(txt)
	local txtType = type(txt)

	if txtType == "string" then
		return false
	elseif txtType == "Player" then
		self:AddText(txt:GetName(),GAMEMODE:GetTeamColor(txt))

		if txt == LocalPlayer() then
			self.m_bHighlight = true
		end

		return true
	end

	if IsValid(txt) then
		self:AddText(txt:GetClass(),GAMEMODE.DeathNoticeDefaultColor)
	else
		self:AddText(tostring(txt))
	end
end

function GameNotice:AddItem(item)
	local items = self.Items

	items[#items + 1] = item
	self:InvalidateLayout(true)
end

function GameNotice:AddText(txt,color)
	if self:AddEntityText(txt) then return end

	local lbl = vgui.Create("DLabel",self)
	txt = tostring(txt)

	Derma_Hook(lbl,"ApplySchemeSettings","Scheme","GameNoticeLabel")
	lbl:ApplySchemeSettings()
	lbl:SetText(txt)

	-- localised ent death
	if not color and string.Left(txt,1) == "#" then
		color = GAMEMODE.DeathNoticeDefaultColor
	end

	-- something else
	if not color and GAMEMODE.DeathNoticeTextColor then
		color = GAMEMODE.DeathNoticeTextColor
	end

	if not color then
		color = color_white
	end

	lbl:SetTextColor(color)
	self:AddItem(lbl)
end

function GameNotice:AddIcon(txt)
	if killicon.Exists(txt) then
		local icon = vgui.Create("DKillIcon",self)

		icon:SetName(txt)
		icon:SizeToContents()
		self:AddItem(icon)
	else
		self:AddText("killed")
	end
end

function GameNotice:PerformLayout()
	local x = self.Padding
	local height = self.Padding * 0.5

	for _,item in pairs(self.Items) do
		item:SetPos(x,self.Padding * 0.5)
		item:SizeToContents()

		x = x + item:GetWide() + self.Spacing
		height = math.max(height,item:GetTall() + self.Padding)
	end

	self:SetSize(x + self.Padding,height)
end

derma.DefineControl("GameNotice","",GameNotice,"DPanel")
