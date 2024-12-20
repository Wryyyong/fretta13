--[[---------------------------------------------------------
   Name: gamemode:GetValidSpectatorModes( Player ply )
   Desc: Gets a table of the allowed spectator modes (OBS_MODE_INEYE, etc)
		 Player is the player object of the spectator
---------------------------------------------------------]]--
function GM:GetValidSpectatorModes()
	-- Note: Override this and return valid modes per player/team
	return self.ValidSpectatorModes
end

--[[---------------------------------------------------------
   Name: gamemode:GetValidSpectatorEntityNames( Player ply )
   Desc: Returns a table of entities that can be spectated (player etc)
---------------------------------------------------------]]--
function GM:GetValidSpectatorEntityNames()
	-- Note: Override this and return valid entity names per player/team
	return self.ValidSpectatorEntities
end

--[[---------------------------------------------------------
   Name: gamemode:IsValidSpectator( Player ply )
   Desc: Is our player spectating - and valid?
---------------------------------------------------------]]--
function GM:IsValidSpectator(ply)
	return
		IsValid(ply)
	and	(
			ply:Team() == TEAM_SPECTATOR
		or	ply:IsObserver()
	)
end

--[[---------------------------------------------------------
   Name: gamemode:IsValidSpectatorTarget( Player pl, Entity ent )
   Desc: Checks to make sure a spectated entity is valid.
		 By default, you can change GM.CanOnlySpectate own team if you want to
		 prevent players from spectating the other team.
---------------------------------------------------------]]--
function GM:IsValidSpectatorTarget(ply,ent)
	local plyTeam = ply:Team()

	return
		IsValid(ent)
	and	ent ~= ply
	and	table.HasValue(self:GetValidSpectatorEntityNames(ply),ent:GetClass())
	and	not (
			ent:IsPlayer()
		and	(
				not ent:Alive()
			or	ent:IsObserver()
			or	(
					plyTeam ~= TEAM_SPECTATOR
				and	self.CanOnlySpectateOwnTeam
				and	plyTeam ~= ent:Team()
			)
		)
	)
end

--[[---------------------------------------------------------
   Name: gamemode:GetSpectatorTargets( Player pl )
   Desc: Returns a table of entities the player can spectate.
---------------------------------------------------------]]--
function GM:GetSpectatorTargets(ply)
	local entTable = {}

	for _,ent in ipairs(self:GetValidSpectatorEntityNames(ply)) do
		entTable = table.Merge(entTable,ents.FindByClass(ent))
	end

	return entTable
end

--[[---------------------------------------------------------
   Name: gamemode:FindRandomSpectatorTarget( Player pl )
   Desc: Finds a random player/ent we can spectate.
		 This is called when a player is first put in spectate.
---------------------------------------------------------]]--
function GM:FindRandomSpectatorTarget(ply)
	local targets = self:GetSpectatorTargets(ply)

	return targets[math.random(#targets)]
end

--[[---------------------------------------------------------
   Name: gamemode:FindNextSpectatorTarget( Player pl, Entity ent )
   Desc: Finds the next entity we can spectate.
		 ent param is the current entity we are viewing.
---------------------------------------------------------]]--
function GM:FindNextSpectatorTarget(ply,ent)
	local targets,check = self:GetSpectatorTargets(ply)

	for _,target in ipairs(targets) do
		if check then
			return target
		end

		if ent ~= target then continue end
		check = true
	end

	return targets[1]
end

--[[---------------------------------------------------------
   Name: gamemode:FindPrevSpectatorTarget( Player pl, Entity ent )
   Desc: Finds the previous entity we can spectate.
		 ent param is the current entity we are viewing.
---------------------------------------------------------]]--
function GM:FindPrevSpectatorTarget(ply,ent)
	local targets = self:GetSpectatorTargets(ply)
	local last = targets[#targets]

	for _,target in ipairs(targets) do
		if ent == target then
			return last
		end

		last = target
	end

	return last
end

--[[---------------------------------------------------------
   Name: gamemode:StartEntitySpectate( Player pl )
   Desc: Called when we start spectating.
---------------------------------------------------------]]--
function GM:StartEntitySpectate(ply)
	local currentSpectateEntity = ply:GetObserverTarget()

	for _ = 1,game.MaxPlayers() do
		if self:IsValidSpectatorTarget(ply,currentSpectateEntity) then
			ply:SpectateEntity(currentSpectateEntity)

			return
		end

		currentSpectateEntity = self:FindRandomSpectatorTarget(ply)
	end
end

--[[---------------------------------------------------------
   Name: gamemode:NextEntitySpectate( Player pl )
   Desc: Called when we want to spec the next entity.
---------------------------------------------------------]]--
function GM:NextEntitySpectate(ply)
	local target = ply:GetObserverTarget()

	for _ = 1,game.MaxPlayers() do
		target = self:FindNextSpectatorTarget(ply,target)

		if not self:IsValidSpectatorTarget(ply,target) then continue end
		ply:SpectateEntity(target)

		return
	end
end

--[[---------------------------------------------------------
   Name: gamemode:PrevEntitySpectate( Player pl )
   Desc: Called when we want to spec the previous entity.
---------------------------------------------------------]]--
function GM:PrevEntitySpectate(ply)
	local target = ply:GetObserverTarget()

	for _ = 1,game.MaxPlayers() do
		target = self:FindPrevSpectatorTarget(ply,target)

		if not self:IsValidSpectatorTarget(ply,target) then continue end
		ply:SpectateEntity(target)

		return
	end
end

--[[---------------------------------------------------------
   Name: gamemode:ChangeObserverMode( Player pl, Number mode )
   Desc: Change the observer mode of a player.
---------------------------------------------------------]]--
function GM:ChangeObserverMode(ply,mode)
	if ply:GetInfoNum("cl_spec_mode",0) ~= mode then
		ply:ConCommand("cl_spec_mode " .. mode)
	end

	if
		mode == OBS_MODE_IN_EYE
	or	mode == OBS_MODE_CHASE
	then
		self:StartEntitySpectate(ply,mode)
	end

	ply:SpectateEntity(NULL)
	ply:Spectate(mode)
end

--[[---------------------------------------------------------
   Name: gamemode:BecomeObserver( Player pl )
   Desc: Called when we first become a spectator.
---------------------------------------------------------]]--
function GM:BecomeObserver(ply)
	local mode = ply:GetInfoNum("cl_spec_mode",OBS_MODE_CHASE)
	local validModes = self:GetValidSpectatorModes(ply)

	if not table.HasValue(validModes,mode) then
		mode = table.FindNext(validModes,mode)
	end

	self:ChangeObserverMode(ply,mode)
end

concommand.Add("spec_mode",function(ply)
	if not GAMEMODE:IsValidSpectator(ply) then return end

	local mode = ply:GetObserverMode()
	local nextMode = table.FindNext(GAMEMODE:GetValidSpectatorModes(ply),mode)

	GAMEMODE:ChangeObserverMode(ply,nextMode)
end)

concommand.Add("spec_next",function(ply)
	if
		not (
			GAMEMODE:IsValidSpectator(ply)
		and	table.HasValue(GAMEMODE:GetValidSpectatorModes(ply),ply:GetObserverMode())
	)
	then return end

	GAMEMODE:NextEntitySpectate(ply)
end)

concommand.Add("spec_prev",function(ply)
	if
		not (
			GAMEMODE:IsValidSpectator(ply)
		and	table.HasValue(GAMEMODE:GetValidSpectatorModes(ply),ply:GetObserverMode())
	)
	then return end

	GAMEMODE:PrevEntitySpectate(ply)
end)
