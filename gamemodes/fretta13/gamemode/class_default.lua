local PlayerModel = Model("models/player.mdl")

local ClassDefault = {
	["DisplayName"] = "Default Class",
	["WalkSpeed"] = 400,
	["CrouchedWalkSpeed"] = 0.2,
	["RunSpeed"] = 600,
	["DuckSpeed"] = 0.2,
	["JumpPower"] = 200,
	["PlayerModel"] = PlayerModel,
	["DrawTeamRing"] = false,
	["DrawViewModel"] = true,
	["CanUseFlashlight"] = true,
	["MaxHealth"] = 100,
	["StartHealth"] = 100,
	["StartArmor"] = 0,
	["RespawnTime"] = 0, -- 0 means use the default spawn time chosen by gamemode
	["DropWeaponOnDie"] = false,
	["TeammateNoCollide"] = true,
	["AvoidPlayers"] = true, -- Automatically avoid players that we're no colliding
	["Selectable"] = true, -- When false, this disables all the team checking
	["FullRotation"] = false, -- Allow the player's model to rotate upwards, etc etc
}

function ClassDefault:Loadout(ply)
	ply:GiveAmmo(255,"Pistol",true)
	ply:Give("weapon_pistol")
end

function ClassDefault:OnSpawn()
end

function ClassDefault:OnDeath()
end

function ClassDefault:Think()
end

function ClassDefault:Move()
end

function ClassDefault:OnKeyPress()
end

function ClassDefault:OnKeyRelease()
end

function ClassDefault:ShouldDrawLocalPlayer()
	return false
end

function ClassDefault:CalcView()
end

local ClassSpectator = {
	["DisplayName"] = "Spectator Class",
	["DrawTeamRing"] = false,
	["PlayerModel"] = PlayerModel,
}

player_class.Register("Default",ClassDefault)
player_class.Register("Spectator",ClassSpectator)
