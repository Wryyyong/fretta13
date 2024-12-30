--[[---------------------------------------------------------
   Name: UTIL_SpawnAllPlayers
   Desc: Respawn all non-spectators, providing they are allowed to spawn.
---------------------------------------------------------]]--
function UTIL_SpawnAllPlayers()
	for _,ply in player.Iterator() do
		local plyTeam = ply:Team()

		if
			not ply:CanRespawn()
		or	plyTeam == TEAM_SPECTATOR
		or	plyTeam == TEAM_CONNECTING
		then continue end

		ply:Spawn()
	end
end

--[[---------------------------------------------------------
   Name: UTIL_StripAllPlayers
   Desc: Clears all weapons and ammo from all players.
---------------------------------------------------------]]--
function UTIL_StripAllPlayers()
	for _,ply in player.Iterator() do
		local plyTeam = ply:Team()

		if
			plyTeam == TEAM_SPECTATOR
		or	plyTeam == TEAM_CONNECTING
		then continue end

		ply:StripWeapons()
		ply:StripAmmo()
	end
end

--[[---------------------------------------------------------
   Name: UTIL_FreezeAllPlayers
   Desc: Freeze all non-spectators.
---------------------------------------------------------]]--
function UTIL_FreezeAllPlayers()
	for _,ply in player.Iterator() do
		local plyTeam = ply:Team()

		if
			plyTeam == TEAM_SPECTATOR
		or	plyTeam == TEAM_CONNECTING
		then continue end

		ply:Freeze(true)
	end
end

--[[---------------------------------------------------------
   Name: UTIL_UnFreezeAllPlayers
   Desc: Removes frozen flag from all players.
---------------------------------------------------------]]--
function UTIL_UnFreezeAllPlayers()
	for _,ply in player.Iterator() do
		local plyTeam = ply:Team()

		if
			plyTeam == TEAM_SPECTATOR
		or	plyTeam == TEAM_CONNECTING
		then continue end

		ply:Freeze(false)
	end
end
