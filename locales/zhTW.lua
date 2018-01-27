local _, rct = ...
local C, L, G = unpack(rct)

local format = string.format

if GetLocale() ~= "zhTW" then return end

L["In"] = "承受"
L["Out"] = "輸出"

L["fontSize"] = "字型大小"
L["mover"] = "調整位置"
L["moverTooltip"] = "勾選後可以左鍵拖動調整各個框體的位置。取消勾選後鎖定位置。"
L["leech"] = "顯示吸血"
L["leechTooltip"] = "顯示吸血造成的治療。"
L["merge"] = "合併顯示"
L["mergeTooltip"] = "嘗試合併顯示多目標傷害與治療。"
L["showMyPet"] = "顯示玩家寵物"
L["showMyPetTooltip"] = "顯示玩家的寵物造成的傷害與治療。"
L["periodicTooltip"] = "显示周期性伤害/治疗" --<<
L["NumUnitFormat"] = function(value)
	if value > 1e8 then
		return format("%.1f億",value/1e8)
	elseif value > 1e4 then
		return format("%.1f萬",value/1e4)
	else
		return format("%.0f",value)
	end
end

setmetatable(L, {__index=function(_, key) return key end})
