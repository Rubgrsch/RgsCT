local _, rct = ...
local C, L, G = unpack(rct)

local format = string.format

local locale = GetLocale()
if locale == "zhCN" or locale == "zhTW" then
	L.NumUnitFormat = function(value)
		if value > 1e8 then
			return format("%.1fY",value/1e8)
		elseif value > 1e4 then
			return format("%.1fW",value/1e4)
		else
			return format("%.0f",value)
		end
	end
else
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
end

setmetatable(L, {__index=function(_, key) return key end})
