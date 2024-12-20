local PlyMeta = FindMetaTable("Player")
if not PlyMeta then return end

function PlyMeta:SetPlayerClass(strName)
	self:SetNWString("Class",strName)
	local class = player_class.Get(strName)

	if class then return end
	MsgN("Warning: Player joined undefined class (",strName,")")
end

function PlyMeta:GetPlayerClassName()
	return self:GetNWString("Class","Default")
end

function PlyMeta:GetPlayerClass()
	-- Class that has been set using SetClass
	local class = player_class.Get(self:GetPlayerClassName())
	if class then return class end

	-- Class based on their Team
	local teamClass = player_class.Get(self:Team())
	if teamClass then return teamClass end

	-- If all else fails, use the default
	local defaultClass = player_class.Get("Default")
	if defaultClass then return defaultClass end
end

function PlyMeta:SetRandomClass()
	local classes = team.GetClass(self:Team())
	if not classes then return end

	local class = classes[math.random(#classes)]
	self:SetPlayerClass(class)
end

function PlyMeta:CheckPlayerClassOnSpawn()
	local classes = team.GetClass(self:Team())
	local classCount = #classes

	-- The player has requested to spawn as a new class
	if self.m_SpawnAsClass then
		self:SetPlayerClass(self.m_SpawnAsClass)
		self.m_SpawnAsClass = nil
	end

	if classes and classCount > 0 then
		if classCount == 1 then
			-- If the player is on a team with only one class, 
			-- make sure we're that one when we spawn.
			self:SetPlayerClass(classes[1])
		elseif not table.HasValue(classes,self:GetPlayerClassName()) then
			-- Make sure the player isn't using the wrong class
			self:SetRandomClass()
		end
	else
		-- No defined classes, use default class
		self:SetPlayerClass("Default")
	end
end

function PlyMeta:OnSpawn()
	local class = self:GetPlayerClass()
	if not class then return end

	if class.DuckSpeed then
		self:SetDuckSpeed(class.DuckSpeed)
	end

	if class.WalkSpeed then
		self:SetWalkSpeed(class.WalkSpeed)
	end

	if class.RunSpeed then
		self:SetRunSpeed(class.RunSpeed)
	end

	if class.CrouchedWalkSpeed then
		self:SetCrouchedWalkSpeed(class.CrouchedWalkSpeed)
	end

	if class.JumpPower then
		self:SetJumpPower(class.JumpPower)
	end

	if class.CanUseFlashlight ~= nil then
		self:AllowFlashlight(class.CanUseFlashlight)
	end

	if class.StartHealth then
		self:SetHealth(class.StartHealth)
	end

	if class.MaxHealth then
		self:SetMaxHealth(class.MaxHealth)
	end

	if class.StartArmor then
		self:SetArmor(class.StartArmor)
	end

	if class.RespawnTime then
		self:SetRespawnTime(class.RespawnTime)
	end

	if class.DropWeaponOnDie ~= nil then
		self:ShouldDropWeapon(class.DropWeaponOnDie)
	end

	if class.TeammateNoCollide ~= nil then
		self:SetNoCollideWithTeammates(class.TeammateNoCollide)
	end

	if class.AvoidPlayers ~= nil then
		self:SetAvoidPlayers(class.AvoidPlayers)
	end

	if class.FullRotation ~= nil then
		self:SetAllowFullRotation(class.FullRotation)
	end

	self:SetNWBool("DrawRing",tobool(class.DrawTeamRing))
	self:DrawViewModel(tobool(class.DrawViewModel))

	self:CallClassFunction("OnSpawn")
end

function PlyMeta:CallClassFunction(name,...)
	local class = self:GetPlayerClass()
	if not (class and class[name]) then return end

	return class[name](class,self,...)
end

function PlyMeta:OnLoadout()
	self:CallClassFunction("Loadout")
end

function PlyMeta:OnDeath()
end

function PlyMeta:OnPlayerModel()
	-- If the class forces a player model, use that.. 
	-- If not, use our preferred model..
	local class = self:GetPlayerClass()

	if class and class.PlayerModel then
		local mdl = class.PlayerModel

		-- table of models, set random
		if type(mdl) == "table" then
			mdl = mdl[math.random(#mdl)]
		end

		util.PrecacheModel(mdl)
		self:SetModel(mdl)

		return
	end

	local cl_playermodel = self:GetInfo("cl_playermodel")
	local modelName = player_manager.TranslatePlayerModel(cl_playermodel)

	util.PrecacheModel(modelName)
	self:SetModel(modelName)
end

function PlyMeta:AllowFlashlight(bAble)
	self.m_bFlashlight = bAble
end

function PlyMeta:CanUseFlashlight()
	-- Default to true unless modified by the player class
	return self.m_bFlashlight ~= nil and self.m_bFlashlight or true
end

function PlyMeta:SetRespawnTime(num)
	self.m_iSpawnTime = num
end

function PlyMeta:GetRespawnTime()
	return (self.m_iSpawnTime and self.m_iSpawnTime > 0) and self.m_iSpawnTime or GAMEMODE.MinimumDeathLength
end

function PlyMeta:DisableRespawn()
	self.m_bCanRespawn = false
end

function PlyMeta:EnableRespawn()
	self.m_bCanRespawn = true
end

function PlyMeta:CanRespawn()
	return self.m_bCanRespawn == nil or self.m_bCanRespawn == true
end

function PlyMeta:IsObserver()
	return self:GetObserverMode() > OBS_MODE_NONE
end

function PlyMeta:UpdateNameColor()
	if not GAMEMODE.SelectColor then return end

	self:SetNWString("NameColor",self:GetInfo("cl_playercolor"))
end

function PlyMeta:Frags()
	return self:GetDTInt(14)
end

local OldSetFrags = PlyMeta.SetFrags
function PlyMeta:SetFrags(frags)
	OldSetFrags(self,frags)
	self:SetDTInt(14,frags)
end

function PlyMeta:AddFrags(frags)
	self:SetFrags(self:Frags() + frags)
end
