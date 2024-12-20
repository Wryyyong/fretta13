local HudElement = {}

function HudElement:Init()
end

function HudElement:SetLabel(text)
	local labelPanel = vgui.Create("DLabel",self)
	self.LabelPanel = labelPanel
	labelPanel:SetText(text)
	labelPanel:SetTextColor(self:GetTextLabelColor())
	labelPanel:SetFont(self:GetTextLabelFont())
end

function HudElement:PerformLayout()
	self:SetContentAlignment(5)

	local padding = self:GetPadding()
	local labelPanel = self.LabelPanel

	if labelPanel then
		local wide = labelPanel:GetWide()

		labelPanel:SetPos(padding,padding)
		labelPanel:SizeToContents()
		labelPanel:SetSize(wide + padding * 0.5,labelPanel:GetTall() + padding * 0.5)
		self:SetTextInset(wide + padding,0)
		self:SetContentAlignment(4)
	end

	self:SizeToContents()
	self:SetSize(self:GetWide() + padding,self:GetTall() + padding)
end

derma.DefineControl("DHudElement","A HUD Element",HudElement,"HudBase")
