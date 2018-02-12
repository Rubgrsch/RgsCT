local _, rct = ...
rct[1] = {} -- Config
rct[2] = {} -- Locales
local C, L = unpack(rct)

C.isBfA = strmatch((GetBuildInfo()),"^%d+") == "8"
setmetatable(L, {__index=function(_, key) return key end})

local init = {}
function rct:AddInitFunc(func)
    init[#init+1] = func
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
	SetCVar("floatingCombatTextCombatDamage", 0)
	SetCVar("floatingCombatTextCombatHealing", 0)
	SetCVar("enableFloatingCombatText", 0)

    for _,v in ipairs(init) do v() end
    init = nil

	C.playerGUID = UnitGUID("player")
end)
