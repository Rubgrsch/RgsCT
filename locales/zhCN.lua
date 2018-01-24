local _, rct = ...
local C, L, G = unpack(rct)

local format = string.format

if GetLocale() ~= "zhCN" then return end

L["fontSize"] = "字体大小"
L["mover"] = "调整位置"
L["moverTooltip"] = "勾选后可以左键拖动调整各个框体的位置。取消勾选后锁定位置。"
L["leech"] = "显示吸血"
L["leechTooltip"] = "显示吸血造成的治疗"
L["merge"] = "合并显示"
L["mergeTooltip"] = "尝试合并显示多目标伤害/治疗。"
L["showMyPet"] = "显示玩家宠物"
L["showMyPetTooltip"] = "显示玩家的宠物造成的伤害/治疗"
L["NumUnitFormat"] = function(value)
	if value > 1e8 then
		return format("%.1fY",value/1e8)
	elseif value > 1e4 then
		return format("%.1fW",value/1e4)
	else
		return format("%.0f",value)
	end
end

setmetatable(L, {__index=function(_, key) return key end})
