local _, rct = ...
rct[1] = {} -- Config
rct[2] = {} -- Locales
rct[3] = {} -- Globals
rct.init = {}
local _, _, G = unpack(rct)

function rct:AddInitFunc(func)
	self.init[#self.init+1] = func
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
	SetCVar("floatingCombatTextCombatDamage", 0)
	SetCVar("floatingCombatTextCombatHealing", 0)
	SetCVar("enableFloatingCombatText", 0)
	for _,v in ipairs(rct.init) do v() end

	G.playerGUID = UnitGUID("player")
end)
