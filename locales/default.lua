local _, rct = ...
local _, L = unpack(rct)

local format = string.format

if next(L) then return end

L["In"] = "Incoming"
L["Out"] = "Outgoing"
L["Info"] = "CombatInfo"

L["font"] = "Font"
L["fontSize"] = "Font Size"
L["mover"] = "Mover"
L["moverTooltip"] = "Click to enable movers."
L["moverMsg"] = "Left Drag to move frames; Right click to lock them."
L["merge"] = "Merge AoE"
L["mergeTooltip"] = "Try to merge multi-hits damage/healing."
L["showMyPet"] = "Show Pet"
L["showMyPetTooltip"] = "Show damage/healing from player's pet."
L["periodic"] = "Periodic Effect"
L["periodicTooltip"] = "Show periodic damage/healing."
L["showOut"] = "Show Outgoing"
L["showOutTooltip"] = "Show damage/healing dealt."
L["showIn"] = "Show Incoming"
L["showInTooltip"] = "Show damage/healing taken."
L["showInfo"] = "Combat Info"
L["showInfoTooltip"] = "Show some of your combat info, e.g. combat/interrupted"
L["SPELL_INTERRUPT"] = "Interrupted [%s]"
L["SPELL_DISPEL"] = "Dispeled [%s]"
L["SPELL_STOLEN"] = "Stole [%s]"
L["NumUnitFormat"] = function(value)
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
