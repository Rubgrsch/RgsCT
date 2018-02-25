local _, rct = ...
local C, L = unpack(rct)

local _G = _G
local format, unpack, GetSpellTexture, UnitGUID, pairs = format, unpack, GetSpellTexture, UnitGUID, pairs
local C_Timer_After = C_Timer.After
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

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

local function CreateCTFrame(frameName,name,...)
	local mover = CreateFrame("Frame", nil, UIParent)
	mover:Hide()
	mover:SetSize(...)
	mover:RegisterForDrag("LeftButton")
	mover:SetScript("OnDragStart", mover.StartMoving)
	mover:SetScript("OnDragStop", mover.StopMovingOrSizing)
	mover:SetMovable(true)
	mover:EnableMouse(true)
	mover.texture = mover:CreateTexture(nil, "BACKGROUND")
	mover.texture:SetColorTexture(1, 1, 0.0, 0.5)
	mover.texture:SetAllPoints(true)
	mover.text = mover:CreateFontString(nil,"ARTWORK","GameFontHighlightLarge")
	mover.text:SetPoint("CENTER", mover, "CENTER", 0, 0)
	mover.text:SetText(name)
	mover:SetScript("OnMouseDown",function(_,button)
		if button == "RightButton" then
			for f,m in pairs(C.mover) do
				m:Hide()
				C.db.mover[f:GetName()]={"BOTTOMLEFT", m:GetLeft(), m:GetBottom()}
			end
		end
	end)

	local frame = CreateFrame("ScrollingMessageFrame", frameName, UIParent)

	frame:SetSpacing(3)
	frame:SetMaxLines(20)
	frame:SetSize(...)
	frame:SetFadeDuration(0.2)
	frame:SetTimeVisible(3)
	frame:SetJustifyH("CENTER")
	frame:SetAllPoints(mover)

	C.mover[frame] = mover

	return frame
end
function C:SetFrames()
	for frame,mover in pairs(C.mover) do
		frame:SetFont(STANDARD_TEXT_FONT, C.db.fontSize, "OUTLINE")
		mover:SetPoint(unpack(C.db.mover[frame:GetName()]))
	end
end

local OutFrame = CreateCTFrame("RgsCTOut",L["Out"],120,150)
local InFrame = CreateCTFrame("RgsCTIn",L["In"],120,150)
local InfoFrame = CreateCTFrame("RgsCTInfo",L["Info"],400,80)

local function DamageHealingString(isIn,spellID,amount,school,isCritical,isHealing,Hits)
	if Hits and Hits > 1 then -- isIn == false
		OutFrame:AddMessage(format("|T%s:0:0:0:-5|t|cff%s%s x%d|r",GetSpellTexture(spellID) or "",dmgcolor[school] or "ffffff",L["NumUnitFormat"](amount/Hits),Hits))
	else
		(isIn and InFrame or OutFrame):AddMessage(format(isCritical and "|T%s:0:0:0:-5|t|cff%s%s*%s*|r" or "|T%s:0:0:0:-5|t|cff%s%s%s|r",GetSpellTexture(spellID) or "",dmgcolor[school] or "ffffff",isIn and (isHealing and "+" or "-") or "",L["NumUnitFormat"](amount)))
	end
end

local function MissString(isIn,spellID,missType)
	(isIn and InFrame or OutFrame):AddMessage(format("|T%s:0:0:0:-5|t%s",GetSpellTexture(spellID) or "",_G[missType]))
end

local function EnvironmantalString(environmentalType,amount,spellSchool)
	InFrame:AddMessage(format("|cff%s%s-%s|r",dmgcolor[spellSchool] or "ffffff",environmentalTypeText[environmentalType],L["NumUnitFormat"](amount)))
end

local tAmount, tHits = {}, {}
local function merge(spellID,amount,school,critical,isHealing)
	if C.db.merge then
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
		DamageHealingString(false,spellID,amount,school,critical,isHealing)
	end
end

local MY_PET_FLAGS = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_REACTION_FRIENDLY, COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_TYPE_PET)
local MY_GUARDIAN_FLAGS = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_REACTION_FRIENDLY, COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_TYPE_GUARDIAN)
local YouDied = format(ERR_PLAYER_DIED_S,UNIT_YOU)

local function parseCT(_,_,_, Event, _, sourceGUID, _, sourceFlags, _, destGUID, destName, _, _, ...)
	local vehicleGUID = UnitGUID("vehicle")
	local fromMe = sourceGUID == C.playerGUID
	local fromMine = fromMe or (C.db.showMyPet and (sourceFlags == MY_PET_FLAGS or sourceFlags == MY_GUARDIAN_FLAGS)) or sourceGUID == vehicleGUID
	local toMe = destGUID == C.playerGUID
	local toMine = toMe or destGUID == vehicleGUID
	if Event == "SWING_DAMAGE" then -- melee
		local amount, _, school, _, _, _, critical = ...
		if fromMine then merge(5586,amount,school,critical,false) end
		if toMine then DamageHealingString(true,5586,amount,school,critical,false) end
	elseif (Event == "SPELL_DAMAGE" or Event == "RANGE_DAMAGE") or (C.db.periodic and Event == "SPELL_PERIODIC_DAMAGE") then -- spell damage
		local spellId, _, _, amount, _, school, _, _, _, critical = ...
		if toMine then DamageHealingString(true,spellId,amount,school,critical,false)
		elseif fromMine then merge(spellId,amount,school,critical,false) end
	elseif Event == "SWING_MISSED" then -- melee miss
		local missType = ...
		if fromMe then MissString(false,5586,missType) end
		if toMine then MissString(true,5586,missType) end
	elseif (Event == "SPELL_MISSED" or Event == "RANGE_MISSED") then -- spell miss
		local spellId, _, _, missType = ...
		if fromMe then MissString(false,spellId,missType) end
		if toMine then MissString(true,spellId,missType) end
	elseif Event == "SPELL_HEAL" or (C.db.periodic and Event == "SPELL_PERIODIC_HEAL") then -- Healing
		local spellId, _, spellSchool, amount, overhealing, _, critical = ...
		if (spellId == 143924 and not C.db.leech) or amount == overhealing then return end
		if fromMine then merge(spellId,amount,spellSchool,critical,true)
		elseif toMine then DamageHealingString(true,spellId,amount,spellSchool,critical,true) end
	elseif Event == "ENVIRONMENTAL_DAMAGE" then -- environmental damage
		local environmentalType, amount, _, school = ...
		if toMine then EnvironmantalString(environmentalType,amount,school) end
	elseif C.db.info then
		if Event == "UNIT_DIED" then -- player died
			if toMe then InfoFrame:AddMessage(YouDied,1,0,0) end
		elseif Event == "SPELL_INTERRUPT" then -- player interrupts
			local _, _, _, _, extraSpellName = ...
			if fromMe then InfoFrame:AddMessage(format(L["InterruptedSpell"], destName, extraSpellName)) end
		elseif Event == "SPELL_DISPEL" then -- player dispels
			local _, _, _, _, extraSpellName = ...
			if fromMe then InfoFrame:AddMessage(format(L["Dispeled"], destName, extraSpellName)) end
		elseif Event == "SPELL_STOLEN" then -- player stolen
			local _, _, _, _, extraSpellName = ...
			if fromMe then InfoFrame:AddMessage(format(L["Stole"], destName, extraSpellName)) end
		end
	end
end

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", C.isBfA and function() parseCT(nil,nil,CombatLogGetCurrentEventInfo()) end or parseCT)

local combatF = CreateFrame("Frame")
combatF:RegisterEvent("PLAYER_REGEN_ENABLED")
combatF:RegisterEvent("PLAYER_REGEN_DISABLED")
combatF:SetScript("OnEvent", function(_,event)
	if not C.db.info then return end
	if event == "PLAYER_REGEN_ENABLED" then
		InfoFrame:AddMessage(LEAVING_COMBAT,0,1,0)
	else
		InfoFrame:AddMessage(ENTERING_COMBAT,1,0,0)
	end
end)

rct:AddInitFunc(function()
	C:SetFrames()
	eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end)
