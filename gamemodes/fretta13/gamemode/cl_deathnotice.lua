-- Start of the death message stuff.
include("vgui/vgui_gamenotice.lua")

hook.Add("InitPostEntity","CreateDeathNotify",function()
	local deathNotify = vgui.Create("DNotify")
	g_VGUI_DeathNotify = deathNotify
	deathNotify:SetPos(0,25)
	deathNotify:SetSize(ScrW() - 25,ScrH())
	deathNotify:SetAlignment(9)
	deathNotify:SetSkin(GAMEMODE.HudSkin)
	deathNotify:SetLife(4)
	deathNotify:ParentToHUD()
end)

net.Receive("PlayerKilledByPlayer",function()
	local victim,inflictor,attacker = net.ReadEntity(),net.ReadString(),net.ReadEntity()
	if not (IsValid(victim) and IsValid(attacker)) then return end

	GAMEMODE:AddDeathNotice(victim,inflictor,attacker)
end)

net.Receive("PlayerKilledSelf",function()
	local victim = net.ReadEntity()
	if not IsValid(victim) then return end

	GAMEMODE:AddPlayerAction(victim,GAMEMODE.SuicideString)
end)

net.Receive("PlayerKilled",function()
	local victim,inflictor,attacker = net.ReadEntity(),net.ReadString(),"#" .. net.ReadString()
	if not IsValid(victim) then return end

	GAMEMODE:AddDeathNotice(victim,inflictor,attacker)
end)

net.Receive("PlayerKilledNPC",function()
	local victim,inflictor,attacker = "#" .. net.ReadString(),net.ReadString(),net.ReadEntity()
	if not IsValid(attacker) then return end

	GAMEMODE:AddDeathNotice(victim,inflictor,attacker)
end)

net.Receive("NPCKilledNPC",function()
	local victim,inflictor = "#" .. net.ReadString(),net.ReadString()

	GAMEMODE:AddDeathNotice(victim,inflictor)
end)

--[[---------------------------------------------------------
   Name: gamemode:AddDeathNotice(Victim, Weapon, Attacker)
   Desc: Adds an death notice entry
---------------------------------------------------------]]--
function GM:AddDeathNotice(victim,inflictor,attacker)
	if not IsValid(g_VGUI_DeathNotify) then return end

	local pnl = vgui.Create("GameNotice",g_VGUI_DeathNotify)
	pnl:AddText(attacker)
	pnl:AddIcon(inflictor)
	pnl:AddText(victim)

	g_VGUI_DeathNotify:AddItem(pnl)
end

function GM:AddPlayerAction(...)
	if not IsValid(g_VGUI_DeathNotify) then return end

	local pnl = vgui.Create("GameNotice",g_VGUI_DeathNotify)

	for _,txt in ipairs({...}) do
		pnl:AddText(txt)
	end

	-- The rest of the arguments should be re-thought.
	-- Just create the notify and add them instead of trying to fit everything into this function!???
	g_VGUI_DeathNotify:AddItem(pnl)
end
