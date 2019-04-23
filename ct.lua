local _, rct = ...
local C, L = unpack(rct)

local _G = _G
local C_Timer_After, CombatLogGetCurrentEventInfo, format, unpack, GetSpellTexture, UnitGUID, pairs = C_Timer.After, CombatLogGetCurrentEventInfo, format, unpack, GetSpellTexture, UnitGUID, pairs

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
setmetatable(dmgcolor,{__index=function() return "ffffff" end})

local environmentalTypeText = {
	Drowning = ACTION_ENVIRONMENTAL_DAMAGE_DROWNING,
	Falling = ACTION_ENVIRONMENTAL_DAMAGE_FALLING,
	Fatigue = ACTION_ENVIRONMENTAL_DAMAGE_FATIGUE,
	Fire = ACTION_ENVIRONMENTAL_DAMAGE_FIRE,
	Lava = ACTION_ENVIRONMENTAL_DAMAGE_LAVA,
	Slime = ACTION_ENVIRONMENTAL_DAMAGE_SLIME,
}

-- Mover
local function moverLock(_,button)
	if button == "RightButton" then
		for f,m in pairs(C.mover) do
			m:Hide()
			C.db.mover[f:GetName()]={"BOTTOMLEFT", m:GetLeft(), m:GetBottom()}
		end
	end
end

local function CreateCTFrame(frameName,name,...)
	local mover = CreateFrame("Frame", nil, UIParent)
	mover:Hide()
	mover:SetSize(...)
	mover:RegisterForDrag("LeftButton")
	mover:SetScript("OnDragStart", mover.StartMoving)
	mover:SetScript("OnDragStop", mover.StopMovingOrSizing)
	mover:SetScript("OnMouseDown",moverLock)
	mover:SetMovable(true)
	mover:EnableMouse(true)
	local texture = mover:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(1, 1, 0, 0.5)
	texture:SetAllPoints(true)
	local text = mover:CreateFontString(nil,"ARTWORK","GameFontHighlightLarge")
	text:SetPoint("CENTER", mover, "CENTER")
	text:SetText(name)

	local frame = CreateFrame("ScrollingMessageFrame", frameName, UIParent)
	frame:SetSpacing(3)
	frame:SetMaxLines(20)
	frame:SetFadeDuration(0.2)
	frame:SetTimeVisible(3)
	frame:SetJustifyH("CENTER")
	frame:SetSize(...)
	frame:SetAllPoints(mover)

	C.mover[frame] = mover

	return frame
end

local OutFrame = CreateCTFrame("RgsCTOut",L["Out"],120,150)
local InFrame = CreateCTFrame("RgsCTIn",L["In"],120,150)
local InfoFrame = CreateCTFrame("RgsCTInfo",L["Info"],400,80)

function C:SetFrames()
	local font, fontSize = LibStub("LibSharedMedia-3.0"):Fetch("font",self.db.font), self.db.fontSize
	for frame,mover in pairs(self.mover) do
		frame:SetFont(font, fontSize, "OUTLINE")
		mover:ClearAllPoints()
		mover:SetPoint(unpack(self.db.mover[frame:GetName()]))
	end
end

-- CT functions
local function DamageHealingString(isIn,isHealing,spellID,amount,school,isCritical,Hits)
	local frame = isIn and InFrame or OutFrame
	local symbol = isHealing and "+" or (isIn and "-" or "")
	if Hits and Hits > 1 then
		frame:AddMessage(format(isCritical and "|T%s:0:0:0:-5|t|cff%s%s*%s* x%d|r" or "|T%s:0:0:0:-5|t|cff%s%s%s x%d|r",GetSpellTexture(spellID) or "",dmgcolor[school],symbol,L["NumUnitFormat"](amount/Hits),Hits))
	else
		frame:AddMessage(format(isCritical and "|T%s:0:0:0:-5|t|cff%s%s*%s*|r" or "|T%s:0:0:0:-5|t|cff%s%s%s|r",GetSpellTexture(spellID) or "",dmgcolor[school],symbol,L["NumUnitFormat"](amount)))
	end
end

local function MissString(isIn,spellID,missType,amountMissed)
	local frame = isIn and InFrame or OutFrame
	if missType == "ABSORB" then
		frame:AddMessage(format("|T%s:0:0:0:-5|t%s(%s)",GetSpellTexture(spellID) or "",_G[missType],L["NumUnitFormat"](amountMissed)))
	else
		frame:AddMessage(format("|T%s:0:0:0:-5|t%s",GetSpellTexture(spellID) or "",_G[missType]))
	end
end

-- Merge --
local merge
local mergeData = {
	[true] = {[true] = {}, [false] = {}},
	[false] = {[true] = {}, [false] = {}},
}

local function dmgMerge(isIn,isHealing,spellID,amount,school,critical)
	local tbl = mergeData[isIn][isHealing]
	if not tbl[spellID] then
		tbl[spellID] = {0,school,0,0}
		tbl[spellID].func = function()
			local tbl = tbl
			DamageHealingString(isIn,isHealing,spellID,tbl[1],tbl[2],tbl[3]==tbl[4],tbl[4])
			tbl[1], tbl[3], tbl[4] = 0, 0, 0
		end
	end
	tbl = tbl[spellID]
	tbl[1], tbl[3], tbl[4] = tbl[1] + amount, tbl[3] + (critical and 1 or 0), tbl[4] + 1
	if tbl[4] == 1 then C_Timer_After(0.05,tbl.func) end
end

function C:SetMerge()
	merge = self.db.merge and dmgMerge or DamageHealingString
end

-- Role check
local f, role = CreateFrame("Frame"), nil
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
f:SetScript("OnEvent", function() role = GetSpecializationRole(GetSpecialization()) end)

-- CLEU: https://wow.gamepedia.com/COMBAT_LOG_EVENT
local MY_PET_FLAGS = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_REACTION_FRIENDLY, COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_TYPE_PET)
local MY_GUARDIAN_FLAGS = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_REACTION_FRIENDLY, COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_TYPE_GUARDIAN)
local spellInfo = {SPELL_INTERRUPT = true, SPELL_DISPEL = true, SPELL_STOLEN = true}

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function()
	local _, Event, _, sourceGUID, _, sourceFlags, _, destGUID, destName, _, _, arg1, arg2, arg3, arg4, arg5, arg6, arg7, _, _, arg10 = CombatLogGetCurrentEventInfo()
	local db = C.db
	local vehicleGUID, playerGUID = UnitGUID("vehicle"), UnitGUID("player")
	local fromMe = sourceGUID == playerGUID
	local fromMine = fromMe or (db.showMyPet and (sourceFlags == MY_PET_FLAGS or sourceFlags == MY_GUARDIAN_FLAGS)) or sourceGUID == vehicleGUID
	local toMe = destGUID == playerGUID or destGUID == vehicleGUID
	if Event == "SWING_DAMAGE" then
		if fromMine then merge(false,false,5586,arg1,arg3,arg7) end
		if toMe then merge(true,false,5586,arg1,arg3,arg7) end
	elseif (Event == "SPELL_DAMAGE" or Event == "RANGE_DAMAGE") or (db.periodic and Event == "SPELL_PERIODIC_DAMAGE") then
		if toMe then merge(true,false,arg1,arg4,arg6,arg10)
		-- use elseif to block self damage, e.g. stagger
		elseif fromMine then merge(false,false,arg1,arg4,arg6,arg10) end
	elseif Event == "SWING_MISSED" then
		if fromMe then MissString(false,5586,arg1,arg3) end
		if toMe then MissString(true,5586,arg1,arg3) end
	elseif (Event == "SPELL_MISSED" or Event == "RANGE_MISSED") then
		if fromMe then MissString(false,arg1,arg4,arg6) end
		if toMe then MissString(true,arg1,arg4,arg6) end
	elseif Event == "SPELL_HEAL" or (db.periodic and Event == "SPELL_PERIODIC_HEAL") then
		-- block leech and full-overhealing
		if arg1 == 143924 or arg4 == arg5 then return end
		-- Show healing in OutFrame for healers, InFrame for tank/dps
		if fromMine and role == "HEALER" then merge(false,true,arg1,arg4,arg3,arg7)
		elseif toMe then merge(true,true,arg1,arg4,arg3,arg7)
		elseif fromMine then merge(false,true,arg1,arg4,arg3,arg7) end
	elseif Event == "ENVIRONMENTAL_DAMAGE" then
		if toMe then InFrame:AddMessage(format("|cff%s%s-%s|r",dmgcolor[arg4],environmentalTypeText[arg1],L["NumUnitFormat"](arg2))) end
	elseif db.info and fromMe and spellInfo[Event] then
		InfoFrame:AddMessage(format(L[Event], destName, arg5))
	end
end)

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
	C:SetMerge()
	eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end)
