local _, rct = ...
local B, L, C = unpack(rct)

local _G = _G
local band, C_Timer_After, CombatLogGetCurrentEventInfo, format, unpack, GetSpellTexture, UnitGUID, pairs = bit.band, C_Timer.After, CombatLogGetCurrentEventInfo, format, unpack, GetSpellTexture, UnitGUID, pairs

-- Stolen from AbuCombattext, converted to hex.
-- Thanks to Sticklord!
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
C.mover = {}
local function MoverLock(_,button)
	if button == "RightButton" then
		for f,m in pairs(C.mover) do
			m:Hide()
			C.db.mover[f:GetName()]={"BOTTOMLEFT", m:GetLeft(), m:GetBottom()}
		end
	end
end

local function CreateCTFrame(frameName,name,frameWidth,moverWidth,height)
	-- Drag and drop mover. Only shown in mover configuring mode.
	local mover = CreateFrame("Frame", nil, UIParent)
	mover:Hide()
	mover:SetSize(moverWidth,height)
	mover:RegisterForDrag("LeftButton")
	mover:SetScript("OnDragStart", mover.StartMoving)
	mover:SetScript("OnDragStop", mover.StopMovingOrSizing)
	mover:SetScript("OnMouseDown",MoverLock)
	mover:SetMovable(true)
	mover:EnableMouse(true)
	local texture = mover:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(1, 1, 0, 0.5)
	texture:SetAllPoints(true)
	local text = mover:CreateFontString(nil,"ARTWORK","GameFontHighlightLarge")
	text:SetPoint("CENTER", mover, "CENTER")
	text:SetText(name)

	-- Actual CT frame
	local frame = CreateFrame("ScrollingMessageFrame", frameName, UIParent)
	frame:SetSpacing(3)
	frame:SetMaxLines(20)
	frame:SetFadeDuration(0.2)
	frame:SetTimeVisible(3)
	frame:SetJustifyH("CENTER")
	frame:SetSize(frameWidth,height)
	frame:SetPoint("CENTER", mover) -- anchor to mover

	C.mover[frame] = mover

	return frame
end

local OutFrame = CreateCTFrame("RgsCTOut",L["Out"],600,120,200)
local InFrame = CreateCTFrame("RgsCTIn",L["In"],600,120,200)
local InfoFrame = CreateCTFrame("RgsCTInfo",L["Info"],800,400,80)

function C:SetFont()
	local font, fontSize = LibStub("LibSharedMedia-3.0"):Fetch("font",self.db.font), self.db.fontSize
	for frame,mover in pairs(self.mover) do
		frame:SetFont(font, fontSize, "OUTLINE")
		mover:ClearAllPoints()
		mover:SetPoint(unpack(self.db.mover[frame:GetName()]))
	end
end

-- CT functions
local blacklist = {
	[201633] = true, -- Earthen Wall
	[143924] = true, -- Leech
}

local function DmgString(isIn,isHealing,spellID,amount,school,isCritical,Hits)
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
local DmgFunc
local mergeData = {
	-- [isIn] -> [isHealing]
	[true] = {[true] = {}, [false] = {}},
	[false] = {[true] = {}, [false] = {}},
}

-- Show merged msg every 0.05s
local function DmgMerge(isIn,isHealing,spellID,amount,school,critical)
	local tbl = mergeData[isIn][isHealing]
	if not tbl[spellID] then
		tbl[spellID] = {0,school,0,0}
		tbl[spellID].func = function()
			local tbl = tbl
			DmgString(isIn,isHealing,spellID,tbl[1],tbl[2],tbl[3]==tbl[4],tbl[4])
			tbl[1], tbl[3], tbl[4] = 0, 0, 0
		end
	end
	tbl = tbl[spellID]
	tbl[1], tbl[3], tbl[4] = tbl[1] + amount, tbl[3] + (critical and 1 or 0), tbl[4] + 1
	if tbl[4] == 1 then C_Timer_After(0.05,tbl.func) end
end

function C:SetMerge()
	DmgFunc = self.db.merge and DmgMerge or DmgString
end

-- Role check
-- Show healing in OutFrame for healers, InFrame for tanks/dps
local role = nil
local function RoleCheck() role = GetSpecializationRole(GetSpecialization()) end
B:AddEventScript("PLAYER_LOGIN", RoleCheck)
B:AddEventScript("PLAYER_SPECIALIZATION_CHANGED", RoleCheck)

local spellInfo = {SPELL_INTERRUPT = true, SPELL_DISPEL = true, SPELL_STOLEN = true}
-- Bit thingy for player's pets or guardians. Necessary since target/focus gives additional bits to flags.
local mask_mine_friendly_player = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MASK,COMBATLOG_OBJECT_REACTION_MASK,COMBATLOG_OBJECT_CONTROL_MASK)
local flag_mine_friendly_player = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE,COMBATLOG_OBJECT_REACTION_FRIENDLY,COMBATLOG_OBJECT_CONTROL_PLAYER)

-- CLEU: https://wow.gamepedia.com/COMBAT_LOG_EVENT
local CLEUFrame = CreateFrame("Frame")
CLEUFrame:SetScript("OnEvent", function(self)
	local _, Event, _, sourceGUID, _, sourceFlags, _, destGUID, _, _, _, arg1, arg2, arg3, arg4, arg5, arg6, arg7, _, _, arg10 = CombatLogGetCurrentEventInfo()
	local db = C.db
	local vehicleGUID, playerGUID = self.vehicleGUID, self.playerGUID
	local fromMe = sourceGUID == playerGUID
	local fromPet = band(sourceFlags, mask_mine_friendly_player) == flag_mine_friendly_player and band(sourceFlags, COMBATLOG_OBJECT_TYPE_PET) > 0
	local fromGuardian = band(sourceFlags, mask_mine_friendly_player) == flag_mine_friendly_player and band(sourceFlags, COMBATLOG_OBJECT_TYPE_GUARDIAN) > 0
	local fromMine = fromMe or (db.showMyPet and (fromPet or fromGuardian)) or sourceGUID == vehicleGUID
	local toMe = destGUID == playerGUID or destGUID == vehicleGUID
	if Event == "SWING_DAMAGE" then
		if fromMine then DmgFunc(false,false,5586,arg1,arg3,arg7) end
		if toMe then DmgFunc(true,false,5586,arg1,arg3,arg7) end
	elseif (Event == "SPELL_DAMAGE" or Event == "RANGE_DAMAGE") or (db.periodic and Event == "SPELL_PERIODIC_DAMAGE") then
		if blacklist[arg1] then return end
		if toMe then DmgFunc(true,false,arg1,arg4,arg6,arg10)
		-- use elseif to block self damage, e.g. stagger
		elseif fromMine then DmgFunc(false,false,arg1,arg4,arg6,arg10) end
	elseif Event == "SWING_MISSED" then
		if fromMe then MissString(false,5586,arg1,arg3) end
		if toMe then MissString(true,5586,arg1,arg3) end
	elseif (Event == "SPELL_MISSED" or Event == "RANGE_MISSED") then
		if blacklist[arg1] then return end
		if toMe then MissString(true,arg1,arg4,arg6)
		-- use elseif to block self damage, e.g. stagger
		-- also block guardians miss for shamman
		elseif fromMe or (db.showMyPet and fromPet) or sourceGUID == vehicleGUID then MissString(false,arg1,arg4,arg6) end
	elseif Event == "SPELL_HEAL" or (db.periodic and Event == "SPELL_PERIODIC_HEAL") then
		-- block full-overhealing
		if blacklist[arg1] or arg4 == arg5 then return end
		-- Show healing in OutFrame for healers, InFrame for tanks/dps
		if fromMine and role == "HEALER" then DmgFunc(false,true,arg1,arg4,arg3,arg7)
		elseif toMe then DmgFunc(true,true,arg1,arg4,arg3,arg7)
		elseif fromMine then DmgFunc(false,true,arg1,arg4,arg3,arg7) end
	elseif Event == "ENVIRONMENTAL_DAMAGE" then
		if toMe then InFrame:AddMessage(format("|cff%s%s-%s|r",dmgcolor[arg4],environmentalTypeText[arg1],L["NumUnitFormat"](arg2))) end
	elseif db.info and fromMine and spellInfo[Event] then
		InfoFrame:AddMessage(format(L[Event], arg5))
	end
end)

local function VehicleChanged(_, _, unit, _, _, _, guid) if unit == "player" then CLEUFrame.vehicleGUID = guid end end
B:AddEventScript("UNIT_ENTERED_VEHICLE", VehicleChanged)
B:AddEventScript("UNIT_EXITING_VEHICLE", VehicleChanged)

local function PlayerRegenChanged(_, event)
	if not C.db.info then return end
	if event == "PLAYER_REGEN_ENABLED" then
		InfoFrame:AddMessage(LEAVING_COMBAT,0,1,0)
	else
		InfoFrame:AddMessage(ENTERING_COMBAT,1,0,0)
	end
end
B:AddEventScript("PLAYER_REGEN_ENABLED", PlayerRegenChanged)
B:AddEventScript("PLAYER_REGEN_DISABLED", PlayerRegenChanged)

B:AddInitScript(function()
	C:SetFont()
	C:SetMerge()
	CLEUFrame.playerGUID = UnitGUID("player")
	CLEUFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	-- show/hide ct frame
	if C.db["out"] then OutFrame:Show() else OutFrame:Hide() end
	if C.db["in"] then InFrame:Show() else InFrame:Hide() end
end)
