local _, rct = ...
local C, L, G = unpack(rct)

local format = string.format

L["fontSize"] = "FontSize"
L["mover"] = "Mover"
L["moverTooltip"] = "Check to move frames. Uncheck to lock them."
L["leech"] = "ShowLeech"
L["leechTooltip"] = "Show healing from leech."
L["merge"] = "Merge"
L["mergeTooltip"] = "Try yo merge multi-hits damage/healing."
L["showMyPet"] = "ShowMyPet"
L["showMyPetTooltip"] = "Show damage/healing from player's pet"
L.NumUnitFormat = function(value)
	if value > 1e9 then
		return format("%.1fB",value/1e9)
	elseif value > 1e6 then
		return format("%.1fM",value/1e6)
	elseif value > 1e3 then
		return format("%.1fK",value/1e3)
	else
		return format("%.0f",value)
	end
end

setmetatable(L, {__index=function(_, key) return key end})
