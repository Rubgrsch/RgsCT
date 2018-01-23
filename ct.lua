local _, rct = ...
local C, L, G = unpack(rct)

local format, GetSpellTexture, UnitGUID = format, GetSpellTexture, UnitGUID
local C_Timer_After = C_Timer.After

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

local function CreateCTFrame(name)
	local frame = CreateFrame("ScrollingMessageFrame", name, UIParent)

	frame:SetSpacing(3)
	frame:SetMaxLines(20)
	frame:SetSize(120,150)
	frame:SetFadeDuration(0.2)
	frame:SetTimeVisible(3)

	return frame
end
local function SetFrame(frame,...)
	frame:SetFont(STANDARD_TEXT_FONT, C.db.fontSize, "OUTLINE")
	frame:SetPoint(...)
end
local OutFrame = CreateCTFrame("RgsCTOut")
local InFrame = CreateCTFrame("RgsCTIn","CENTER", UIParent, "CENTER")

local function DamageHealingString(isIn,spellID,amount,school,isCritical,isHealing,Hits)
	if Hits and Hits > 1 then -- isIn == false
		OutFrame:AddMessage(format("|T%s:0:0:0:-5|t|cff%s%s x%d|r",GetSpellTexture(spellID) or "",dmgcolor[school] or "ffffff",L.NumUnitFormat(amount/Hits),Hits))
	else
		(isIn and InFrame or OutFrame):AddMessage(format(isCritical and "|T%s:0:0:0:-5|t|cff%s%s*%s*|r" or "|T%s:0:0:0:-5|t|cff%s%s%s|r",GetSpellTexture(spellID) or "",dmgcolor[school] or "ffffff",isIn and (isHealing and "+" or "-") or "",L.NumUnitFormat(amount)))
	end
end

local function MissString(isIn,spellID,missType)
	(isIn and InFrame or OutFrame):AddMessage(format("|T%s:0:0:0:-5|t%s",GetSpellTexture(spellID) or "",_G[missType]))
end

local function EnvironmantalString(environmentalType,amount,spellSchool)
	InFrame:AddMessage(format("|cff%s%s-%s|r",dmgcolor[spellSchool] or "ffffff",environmentalTypeText[environmentalType],L.NumUnitFormat(amount)))
end

local tAmount, tHits = {}, {}
local function merge(...)
	if C.db.merge then
		local spellID,amount,school,critical,isHealing = ...
		if tAmount[spellID] then
			tAmount[spellID] = tAmount[spellID] + amount
			tHits[spellID] = tHits[spellID] + 1
		else
			tAmount[spellID] = amount
			tHits[spellID] = 1
			C_Timer_After(0.05, function()
				DamageHealingString(false,spellID,tAmount[spellID],school,critical,isHealing,tHits[spellID])
				tAmount[spellID] = nil
				tHits[spellID] = nil
			end)
		end
	else
		DamageHealingString(false,...)
	end
end

local MY_PET_FLAGS = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_REACTION_FRIENDLY, COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_TYPE_PET)
local MY_GUARDIAN_FLAGS = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_REACTION_FRIENDLY, COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_TYPE_GUARDIAN)

local function parseCT(_,_,_, event, _, sourceGUID, _, sourceFlags, _, destGUID, _, _, _, ...)
    local vehicleGUID = UnitGUID("vehicle")
	local fromMyPet = C.db.OutFrame.showMyPet and (sourceFlags == MY_PET_FLAGS or sourceFlags == MY_GUARDIAN_FLAGS)
	local fromMe = sourceGUID == G.playerGUID or sourceGUID == vehicleGUID
	local fromMine = fromMe or fromMyPet
	local toMe = destGUID == G.playerGUID or destGUID == vehicleGUID
	if EventList[event] == 1 then -- melee
		local amount, overkill, school, _, _, _, critical = ...
		if overkill > 0 then amount = amount - overkill end
		if amount > 0 then
			if fromMine then merge(6603,amount,school,critical,false) end
			if toMe then DamageHealingString(true,6603,amount,school,critical,false) end
		end
	elseif EventList[event] == 2 then -- spell damage
		local spellId, _, _, amount, overkill, school, _, _, _, critical = ...
		if overkill > 0 then amount = amount - overkill end
		if amount > 0 then
			if toMe then DamageHealingString(true,spellId,amount,school,critical,false)
			elseif fromMine then merge(spellId,amount,school,critical,false) end
		end
	elseif EventList[event] == 3 then -- melee miss
		local missType = ...
		if fromMe then MissString(false,6603,missType) end
		if toMe then MissString(true,6603,missType) end
	elseif EventList[event] == 4 then -- spell miss
		local spellId, _, _, missType = ...
		if fromMe then MissString(false,spellId,missType) end
		if toMe then MissString(true,spellId,missType) end
	elseif EventList[event] == 5 then -- Healing
		local spellId, _, spellSchool, amount, overhealing, _, critical = ...
		if overhealing > 0 then amount = amount - overhealing end
		if amount > 0 then
			if fromMine then merge(spellId,amount,spellSchool,critical,true)
			elseif toMe then DamageHealingString(true,spellId,amount,spellSchool,critical,true) end
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

rct:AddInitFunc(function()
	SetFrame(InFrame,"CENTER", UIParent, "CENTER",C.db.InFrame.xOffset,C.db.InFrame.yOffset)
	SetFrame(OutFrame,"CENTER", UIParent, "CENTER",C.db.OutFrame.xOffset,C.db.OutFrame.yOffset)
end)