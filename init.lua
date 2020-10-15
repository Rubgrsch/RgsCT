local _, rct = ...
rct[1] = {} -- Base
rct[2] = {} -- Locales
rct[3] = {} -- Config
local B, L = unpack(rct)

setmetatable(L, {__index=function(_, key) return key end})

--Event
local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self,event,...)
	for _, func in ipairs(self[event]) do func(self,event,...) end
end)

function B:AddEventScript(event, func)
	if not frame[event] then
		frame[event] = {}
		frame:RegisterEvent(event)
	end
	local t = frame[event]
	t[#t+1] = func
end

-- Init
local init = {}
function B:AddInitScript(func)
	init[#init+1] = func
end

B:AddEventScript("PLAYER_LOGIN", function()
	SetCVar("floatingCombatTextCombatDamage", 0)
	SetCVar("floatingCombatTextCombatHealing", 0)
	SetCVar("enableFloatingCombatText", 0)

	for _,v in ipairs(init) do v() end
	init = nil
end)
