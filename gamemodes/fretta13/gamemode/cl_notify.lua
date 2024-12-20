hook.Add("InitPostEntity","CreateLeftNotify",function()
	local _,y = chat.GetChatBoxPos()

	g_LeftNotify = vgui.Create("DNotify")
	g_LeftNotify:SetPos(32,0)
	g_LeftNotify:SetSize(ScrW(),y - 8)
	g_LeftNotify:SetAlignment(1)
	g_LeftNotify:ParentToHUD()
end)

function GM:NotifyGMVote(name,newGamemode,votesNeeded)
	local label = vgui.Create("DLabel")

	label:SetFont("FRETTA_MEDIUM_SHADOW")
	label:SetTextColor(color_white)
	label:SetText(Format("%s voted for %s (need %i more)",name,newGamemode,votesNeeded))
	label:SizeToContents()

	g_LeftNotify:AddItem(label,5)
end
