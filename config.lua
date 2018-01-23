local _, rct = ...
local C, L, G = unpack(rct)

local type, next, pairs = type, next, pairs

local defaults = {
	fontSize = 14, -- font size|字体大小
	InFrame = { -- damage/healing to player|你受到的伤害/治疗
		xOffset = -300,
		yOffset = 0,
	},
	OutFrame = { -- damage/healing from player|你造成的伤害/治疗
		xOffset = 300,
		yOffset = 0,
		showMyPet = true, -- damage/healing from your pet|你宠物造成的伤害/治疗
	},
	merge = true, --Merge multiple hits|合并多次伤害/治疗
}

rct:AddInitFunc(function()
	if type(rgsctDB) ~= "table" or next(rgsctDB) == nil then rgsctDB = defaults end
	C.db = rgsctDB
	for k,v in pairs(defaults) do if C.db[k] == nil then C.db[k] = v end end -- fallback to defaults
	-- Start of DB Conversion
	-- End of DB conversion
	for k in pairs(C.db) do if defaults[k] == nil then C.db[k] = nil end end -- remove old keys
end)
