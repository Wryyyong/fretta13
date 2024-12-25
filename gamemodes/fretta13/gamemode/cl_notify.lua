hook.Add("InitPostEntity","CreateLeftNotify",function()
	local _,y = chat.GetChatBoxPos()

	local leftNotify = vgui.Create("DNotify")
	g_VGUI_LeftNotify = leftNotify
	leftNotify:SetPos(32,0)
	leftNotify:SetSize(ScrW(),y - 8)
	leftNotify:SetAlignment(1)
	leftNotify:ParentToHUD()
end)

function GM:NotifyGMVote(name,newGamemode,votesNeeded)
	local label = vgui.Create("DLabel")
	label:SetFont("FRETTA_MEDIUM_SHADOW")
	label:SetTextColor(color_white)
	label:SetText(Format("%s voted for %s (need %i more)",name,newGamemode,votesNeeded))
	label:SizeToContents()

	g_VGUI_LeftNotify:AddItem(label,5)
end
