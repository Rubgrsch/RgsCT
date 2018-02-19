local _, rct = ...
local _, L = unpack(rct)

local format = string.format

if GetLocale() ~= "zhTW" then return end

L["In"] = "承受"
L["Out"] = "輸出"
L["Info"] = "訊息"

L["fontSize"] = "字型大小"
L["mover"] = "調整位置"
L["moverTooltip"] = "點擊後調整框體位置。|n左鍵拖動：調整框體位置；右鍵：鎖定位置" --<<
L["leech"] = "顯示吸血"
L["leechTooltip"] = "顯示吸血造成的治療。"
L["merge"] = "合併顯示"
L["mergeTooltip"] = "嘗試合併顯示多目標傷害與治療。"
L["showMyPet"] = "顯示玩家寵物"
L["showMyPetTooltip"] = "顯示玩家的寵物造成的傷害與治療。"
L["periodicTooltip"] = "顯示周期性傷害與治療"
L["showInfo"] = "戰鬥訊息"
L["showInfoTooltip"] = "顯示部分與你有關的戰鬥訊息，比如進入戰鬥、成功打斷。"
L["InterruptedSpell"] = "已打斷%s的[%s]"
L["Dispeled"] = "已驅散%s的[%s]"
L["Stole"] = "已偷取%s的[%s]"
L["NumUnitFormat"] = function(value)
	if value > 1e8 then
		return format("%.1f億",value/1e8)
	elseif value > 1e4 then
		return format("%.1f萬",value/1e4)
	else
		return format("%.0f",value)
	end
end
