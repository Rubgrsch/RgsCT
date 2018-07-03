local _, rct = ...
local _, L = unpack(rct)

local format = string.format

if next(L) then return end

L["In"] = "In"
L["Out"] = "Out"
L["Info"] = "Info"

L["font"] = "Font"
L["fontSize"] = "FontSize"
L["mover"] = "Mover"
L["moverTooltip"] = "Click to enable movers.|nLeft Drag to move frames; Right click to lock them."
L["merge"] = "Merge AoE"
L["mergeTooltip"] = "Try to merge multi-hits damage/healing."
L["showMyPet"] = "ShowMyPet"
L["showMyPetTooltip"] = "Show damage/healing from player's pet."
L["periodicTooltip"] = "Show periodic damage/healing."
L["showInfo"] = "CombatInfo"
L["showInfoTooltip"] = "Show some of your combat info, e.g. combat/interrupted"
L["showIn"] = "showTaken"
L["showInTooltip"] = "Show dmg/healing taken."
L["InterruptedSpell"] = "Interrupted %s's [%s]"
L["Dispeled"] = "Dispeled %s's [%s]"
L["Stole"] = "Stole %s's [%s]"
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
