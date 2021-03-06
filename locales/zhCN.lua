local _, rct = ...
local _, L = unpack(rct)

local format = string.format

if GetLocale() ~= "zhCN" then return end

L["In"] = "承受"
L["Out"] = "输出"
L["Info"] = "信息"

L["font"] = "字体"
L["fontSize"] = "字体大小"
L["mover"] = "调整位置"
L["moverTooltip"] = "点击后调整框体位置。"
L["moverMsg"] = "左键拖动：调整框体位置；右键：锁定位置。"
L["merge"] = "合并显示AoE"
L["mergeTooltip"] = "尝试合并显示多目标伤害/治疗。"
L["showMyPet"] = "显示玩家宠物"
L["showMyPetTooltip"] = "显示玩家的宠物造成的伤害/治疗。"
L["periodic"] = "周期性效果"
L["periodicTooltip"] = "显示周期性伤害/治疗。"
L["showOut"] = "显示输出"
L["showOutTooltip"] = "显示造成的伤害/治疗。"
L["showIn"] = "显示承受"
L["showInTooltip"] = "显示受到的伤害/治疗。"
L["showInfo"] = "显示战斗信息"
L["showInfoTooltip"] = "显示部分与你有关的战斗信息，比如进入战斗/成功打断。"
L["SPELL_INTERRUPT"] = "已打断[%s]"
L["SPELL_DISPEL"] = "已驱散[%s]"
L["SPELL_STOLEN"] = "已偷取[%s]"
L["NumUnitFormat"] = function(value)
	if value > 1e8 then
		return format("%.1f亿",value/1e8)
	elseif value > 1e4 then
		return format("%.1f万",value/1e4)
	else
		return format("%.0f",value)
	end
end
