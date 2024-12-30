module("player_class",package.seeall)

local ClassTables = {}

function Register(name,classtable)
	ClassTables[name] = classtable
	ClassTables[name].m_HasBeenSetup = false
end

function Get(name)
	if not ClassTables[name] then
		return {}
	end

	-- Derive class here.
	-- I have favoured using table.Inherit over using a meta table
	-- This is to the performance hit is once, now, rather than on every usage
	if not ClassTables[name].m_HasBeenSetup then
		ClassTables[name].m_HasBeenSetup = true
		local base = ClassTables[name].Base
		local baseTbl = Get(base)

		if base and baseTbl then
			ClassTables[name] = table.Inherit(ClassTables[name],baseTbl)
			ClassTables[name].BaseClass = baseTbl
		end
	end

	return ClassTables[name]
end

function GetClassName(name)
	local class = Get(name)

	if not class then
		return name
	end

	return class.DisplayName
end
