local addonName, rct = ...
local C, L = unpack(rct)

local _G = _G
local floor, type, next, unpack, pairs, ipairs = math.floor, type, next, unpack, pairs, ipairs
local PlaySound = PlaySound

local defaults = {
	fontSize = 14,
	font = LibStub("LibSharedMedia-3.0"):List("font")[1],
	mover = {
		RgsCTIn = {"CENTER",-300,0},
		RgsCTOut = {"CENTER",300,0},
		RgsCTInfo = {"CENTER",0,0},
	},
	showMyPet = true,
	merge = true,
	periodic = true,
	info = false,
	["in"] = true,
}

rct:AddInitFunc(function()
	if type(rgsctDB) ~= "table" or next(rgsctDB) == nil then rgsctDB = defaults end
	C.db = rgsctDB
	-- fallback to defaults
	for k,v in pairs(defaults) do
		if C.db[k] == nil then C.db[k] = v end
		if type(v) == "table" then
			for k1,v1 in pairs(v) do
				if C.db[k][k1] == nil then C.db[k][k1] = v1 end
			end
		end
	end
	-- Start of DB Conversion
	-- End of DB conversion
	for k in pairs(C.db) do if defaults[k] == nil then C.db[k] = nil end end -- remove old keys
end)

-- GUI Template --
-- Table for DB initialize
local options = {check={}, slider={}, dropdown={}}

local configFrame = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
configFrame.name = addonName
InterfaceOptions_AddCategory(configFrame)
local idx, first, previous = 1, configFrame, configFrame

local function SetFramePoint(frame, pos)
	if type(pos) == "table" then -- Set custom position
		frame:SetPoint(unpack(pos))
		idx, first = 1, frame
	else
		if pos > 0 and idx <= 3 - pos then -- same line
			frame:SetPoint("LEFT", previous, "LEFT", 170, 0)
			idx = idx + 1
		else -- next line
			frame:SetPoint("TOPLEFT", first, "TOPLEFT", 0, -40)
			idx, first = 1, frame
		end
	end
	previous = frame
end

local function newCheckBox(label, name, desc, pos, get, set)
	local Name = "RgsCTConfig"..label
	local check = CreateFrame("CheckButton", Name, configFrame, "InterfaceOptionsCheckButtonTemplate")
	check:SetScript("OnClick", function(self)
		local checked = self:GetChecked()
		if set then set(checked) else C.db[label] = checked end
		PlaySound(checked and 856 or 857)
	end)
	check.getfunc = get or function() return C.db[label] end
	_G[Name.."Text"]:SetText(name)
	check.tooltipText = name
	check.tooltipRequirement = desc
	SetFramePoint(check, pos)
	options.check[label] = check
end

local function newSlider(label, name, desc, min, max, step, pos, get, set)
	local Name = "RgsCTConfig"..label
	local slider = CreateFrame("Slider",Name,configFrame,"OptionsSliderTemplate")
	local text = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	text:SetPoint("BOTTOM",0,-10)
	slider.tooltipText = name
	slider.tooltipRequirement = desc
	slider:SetMinMaxValues(min, max)
	_G[Name.."Low"]:SetText(min)
	_G[Name.."High"]:SetText(max)
	_G[Name.."Text"]:SetText(name)
	slider:SetValueStep(step)
	slider.getfunc = get or function() return C.db[label] end
	slider:SetScript("OnValueChanged", function(_,value)
		value = min + floor((value - min) / step + 0.5) * step
		if set then set(value) else C.db[label]=value end
		text:SetText(value)
	end)
	SetFramePoint(slider, pos)
	options.slider[label] = slider
end

local function newButton(name, desc, pos, func)
	local button = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
	button:SetText(name)
	button.tooltipText = desc
	button:SetSize(150, 25)
	button:SetScript("OnClick", func)
	SetFramePoint(button,pos)
end

local listBackdrop = {
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	edgeSize = 16,
	tileSize = 16,
	tile = true,
	insets = {left = 3, right = 3, top = 3, bottom = 3},
}
local optBackdrop = {bgFile = "Interface\\ChatFrame\\ChatFrameBackground"}

local function newDropdown(label, name, pos, tbl, get, set, isFont)
	local f = CreateFrame("Button", nil, configFrame)
	f:SetSize(150,25)
	f:SetBackdrop(listBackdrop)
	f:SetBackdropColor(0,0,0,0)
	f.offset = 0
	local list = CreateFrame("Frame",nil,f)
	list:SetPoint("TOP",f,"BOTTOM")
	list:SetBackdrop(listBackdrop)
	list:SetBackdropColor(0,0,0,1)
	list:Hide()
	local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	title:SetText(name)
	title:SetPoint("TOPLEFT",f,"TOPLEFT",0,14)
	local downTexture = f:CreateTexture(nil, "BACKGROUND")
	downTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
	downTexture:SetPoint("RIGHT",f,"RIGHT")
	downTexture:SetSize(25,25)
	local text = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	local _,fontSize = text:GetFont()
	text:SetPoint("LEFT",f,"LEFT",5,0)
	f:SetScript("OnClick",function()
		PlaySound(856)
		ToggleFrame(list)
	end)

	local opts = {}
	local function SetHighlight()
		local offset, chosen = f.offset, f.chosen
		for i, opt in ipairs(opts) do
			if chosen == tbl[i+offset] then
				opt:SetBackdropColor(0.8,0.8,0.3,0.5)
			else
				opt:SetBackdropColor(0, 0, 0, 0.5)
			end
		end
	end
	function f:Init()
		local chosen = get and get() or C.db[label]
		f.chosen = chosen
		SetHighlight()
		text:SetText(chosen)
		if isFont then text:SetFont(LibStub("LibSharedMedia-3.0"):Fetch("font",chosen),fontSize) end
	end

	local function OnClick(self)
		PlaySound(856)
		local chosen = self.value
		f.chosen = chosen
		SetHighlight()
		text:SetText(chosen)
		if set then set(chosen) else C.db[label] = chosen end
		if isFont then text:SetFont(LibStub("LibSharedMedia-3.0"):Fetch("font",chosen),fontSize) end
		list:Hide()
	end
	local function OnEnter(self) if f.chosen ~= self.value then self:SetBackdropColor(1,1,1,0.8) end end
	local function OnLeave(self) if f.chosen ~= self.value then self:SetBackdropColor(0,0,0,0.5) end end
	local function SetListValue()
		local offset = f.offset
		for i, opt in ipairs(opts) do
			local value = tbl[i+offset]
			opt.value = value
			opt.text:SetText(value)
			if isFont then opt.text:SetFont(LibStub("LibSharedMedia-3.0"):Fetch("font",value),fontSize) end
		end
	end
	local Len = #tbl
	local listLen = min(Len,10)
	local function OnMouseWheel(_,direction)
		local offset = f.offset - direction
		if offset < 0 then offset = 0
		elseif offset > Len-10 then offset = max(Len-10, 0) end
		f.offset = offset
		SetHighlight()
		SetListValue()
	end
	for i=1, listLen do
		local opt = CreateFrame("Button", nil, list)
		opt:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 4, -4-(i-1)*20)
		opt:SetSize(150-8,20)
		opt:SetBackdrop(optBackdrop)
		opt:SetBackdropColor(0,0,0,0.5)
		opt.text = opt:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		opt.text:SetPoint("LEFT",opt,"LEFT",5,0)
		opt:SetScript("OnClick", OnClick)
		opt:SetScript("OnEnter", OnEnter)
		opt:SetScript("OnLeave", OnLeave)
		opt:EnableMouseWheel(true)
		opt:SetScript("OnMouseWheel",OnMouseWheel)
		opts[i] = opt
	end
	list:SetSize(150, listLen*20+8)
	SetListValue()
	SetFramePoint(f,pos)
	options.dropdown[label] = f
end
-- End of GUI template --

C.mover = {}

local titleText = configFrame:CreateFontString(nil,"ARTWORK","GameFontNormalLarge")
titleText:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 200, -20)
titleText:SetText(addonName.." "..GetAddOnMetadata(addonName, "Version"))

rct:AddInitFunc(function()
	newDropdown("font",L["font"],{"TOPLEFT", configFrame, "TOPLEFT", 16, -60},LibStub("LibSharedMedia-3.0"):List("font"),
		nil,
		function(chosen)
			C.db.font = chosen
			C:SetFrames()
		end,true)
	newSlider("fontSize", L["fontSize"], nil, 9, 30, 1, 1,
		nil,
		function(value)
			C.db.fontSize = value
			C:SetFrames()
		end)
	newButton(L["mover"], L["moverTooltip"], 1,
		function()
			InterfaceOptionsFrame:Hide()
			HideUIPanel(GameMenuFrame)
			for _,mover in pairs(C.mover) do mover:Show() end
		end)
	newCheckBox("info", L["showInfo"], L["showInfoTooltip"], -1)
	newCheckBox("in", L["showIn"], L["showInTooltip"], 1,
		nil,
		function(checked) if checked then RgsCTIn:Show() else RgsCTIn:Hide() end; C.db["in"] = checked end)
	newCheckBox("merge", L["merge"], L["mergeTooltip"], -1,
		nil,
		function(checked)
			C.db.merge = checked
			C:SetMerge()
		end)
	newCheckBox("showMyPet", L["showMyPet"], L["showMyPetTooltip"], 1)
	newCheckBox("periodic", L["periodic"], L["periodicTooltip"], 1)
	-- Set values in config
	for _,v in pairs(options.check) do
		v:SetChecked(v.getfunc())
	end
	for _,v in pairs(options.slider) do
		v:SetValue(v.getfunc(),true)
	end
	for _,v in pairs(options.dropdown) do
		v:Init()
	end
end)
