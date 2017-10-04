
local config = {
	font = STANDARD_TEXT_FONT, -- font|字体
	fontSize = 14, -- font size|字体大小
	InFrame = { -- damage/healing to player|你受到的伤害/治疗
		xOffset = -300,
		yOffset = 0,
	},
	OutFrame = { -- damage/healing from player|你造成的伤害/治疗
		xOffset = 300,
		yOffset = 0,
	},
}

local _G = _G
local format, GetSpellTexture, UnitGUID = format, GetSpellTexture, UnitGUID

local playerGUID, NumUnitFormat

-- Change CVars
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
	SetCVar("floatingCombatTextCombatDamage", 0)
	SetCVar("floatingCombatTextCombatHealing", 0)
	SetCVar("enableFloatingCombatText", 0)

	playerGUID = UnitGUID("player")
end)

local locale = GetLocale()
if locale == "zhCN" or locale == "zhTW" then
	NumUnitFormat = function(value)
		if value > 1e8 then
			return format("%.1fY",value/1e8)
		elseif value > 1e4 then
			return format("%.1fW",value/1e4)
		else
			return format("%d",value)
		end
	end
else
	NumUnitFormat = function(value)
		if value > 1e9 then
			return format("%.0fB",value/1e9)
		elseif value > 1e6 then
			return format("%.0fM",value/1e6)
		elseif value > 1e3 then
			return format("%.0fK",value/1e3)
		else
			return format("%d",value)
		end
	end
end

-- Stolen from AbuCombattext, converted to hex
local dmgcolor = {
	[1] = "ffff00",
	[2] = "ffe57f",
	[4] = "ff7f00",
	[8] = "4cff4c",
	[16] = "7fffff",
	[32] = "7f7fff",
	[64] = "ff7fff",
	[9] = "a5ff26",
	[18] = "bff2bf",
	[36] = "bf7f7f",
	[5] = "ffbf00",
	[10] = "bff2bf",
	[20] = "bfbf7f",
	[40] = "66bfa5",
	[80] = "bfbfff",
	[127] = "c1c48c",
	[126] = "b7baa3",
	[3] = "fff23f",
	[6] = "ffb23f",
	[12] = "a5bf26",
	[24] = "66ffa5",
	[48] = "7fbfff",
	[65] = "ffbf7f",
	[124] = "a8b2a8",
	[66] = "ffb2bf",
	[96] = "bf7fff",
	[72] = "a5bfa5",
	[68] = "ff7f7f",
	[28] = "99d670",
	[34] = "bfb2bf",
	[33] = "bfbf7f",
	[17] = "bfff7f",
}

local environmentalTypeText = {
    Drowning = ACTION_ENVIRONMENTAL_DAMAGE_DROWNING,
    Falling = ACTION_ENVIRONMENTAL_DAMAGE_FALLING,
    Fatigue = ACTION_ENVIRONMENTAL_DAMAGE_FATIGUE,
    Fire = ACTION_ENVIRONMENTAL_DAMAGE_FIRE,
    Lava = ACTION_ENVIRONMENTAL_DAMAGE_LAVA,
    Slime = ACTION_ENVIRONMENTAL_DAMAGE_SLIME,
}

local EventList = {
	SWING_DAMAGE = 1,
	SPELL_DAMAGE = 2,
	RANGE_DAMAGE = 2,
	SPELL_PERIODIC_DAMAGE = 2,
	SWING_MISSED = 3,
	SPELL_MISSED = 4,
	RANGE_MISSED = 4,
	SPELL_HEAL = 5,
	SPELL_PERIODIC_HEAL = 5,
	ENVIRONMENTAL_DAMAGE = 6,
}

local function CreateCTFrame(name, ...)
	local frame = CreateFrame("ScrollingMessageFrame", name, UIParent)

	frame:SetSpacing(3)
	frame:SetMaxLines(20)
	frame:SetSize(120,150)
	frame:SetFadeDuration(0.2)
	frame:SetTimeVisible(3)
	frame:SetFont(config.font, config.fontSize, "OUTLINE")
	frame:SetPoint(...)

	return frame
end
local OutFrame = CreateCTFrame("RgsCTOut","CENTER", UIParent, "CENTER",config.OutFrame.xOffset,config.OutFrame.yOffset)
local InFrame = CreateCTFrame("RgsCTIn","CENTER", UIParent, "CENTER",config.InFrame.xOffset,config.InFrame.yOffset)

local function DamageHealingString(isIn,spellID,amount,school,isCritical,isHealing)
	(isIn and InFrame or OutFrame):AddMessage(format(isCritical and "|T%s:0:0:0:-5|t|cff%s%s*%s*|r" or "|T%s:0:0:0:-5|t|cff%s%s%s|r",GetSpellTexture(spellID) or "",dmgcolor[school],isIn and (isHealing and "+" or "-") or "",NumUnitFormat(amount)))
end

local function MissString(isIn,spellID,missType)
	(isIn and InFrame or OutFrame):AddMessage(format("|T%s:0:0:0:-5|t%s",GetSpellTexture(spellID) or "",_G[missType]))
end

local function EnvironmantalString(environmentalType,amount,spellSchool)
	InFrame:AddMessage(format("|cff%s%s-%s|r",dmgcolor[spellSchool],environmentalTypeText[environmentalType],NumUnitFormat(amount)))
end

local function parseCT(_,_,_, event, _, sourceGUID, _, _, _, destGUID, _, _, _, ...)
	local vehicleGUID = UnitGUID("vehicle")
	local fromMe = sourceGUID == vehicleGUID or sourceGUID == playerGUID
	local toMe = destGUID == vehicleGUID or destGUID == playerGUID
	if EventList[event] == 1 then -- melee
		local amount, overkill, school, _, _, _, critical = ...
		if overkill > 0 then amount = amount - overkill end
		if amount > 0 then
			if fromMe then DamageHealingString(false,6603,amount,school,critical,false) end
			if toMe then DamageHealingString(true,6603,amount,school,critical,false) end
		end
	elseif EventList[event] == 2 then -- spell damage
		local spellId, _, _, amount, overkill, school, _, _, _, critical = ...
		if overkill > 0 then amount = amount - overkill end
		if amount > 0 then
			if fromMe then DamageHealingString(false,spellId,amount,school,critical,false) end
			if toMe then DamageHealingString(true,spellId,amount,school,critical,false) end
		end
	elseif EventList[event] == 3 then -- melee miss
		local missType = ...
		if fromMe then MissString(false,6603,missType) end
		if toMe then MissString(true,6603,missType) end
	elseif EventList[event] == 4 then -- spell miss
		local spellId, _, _, missType = ...
		if fromMe then MissString(false,spellId,missType) end
		if toMe then MissString(true,spellId,missType) end
	elseif EventList[event] == 5 then -- Healing accept
		local spellId, _, spellSchool, amount, overhealing, _, critical = ...
		if overhealing > 0 then amount = amount - overhealing end
		if amount > 0 then
			if toMe then DamageHealingString(true,spellId,amount,spellSchool,critical,true)
			elseif fromMe then DamageHealingString(false,spellId,amount,spellSchool,critical,true) end
		end
	elseif EventList[event] == 6 then -- environmental damage
		local environmentalType, amount, overkill, school = ...
		if overkill > 0 then amount = amount - overkill end
		if amount > 0 then
			if toMe then EnvironmantalString(environmentalType,amount,school) end
		end
	end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:SetScript("OnEvent", parseCT)
