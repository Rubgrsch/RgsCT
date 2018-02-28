local addonName, rct = ...
local C, L = unpack(rct)

local _G = _G
local floor, type, next, unpack, pairs = math.floor, type, next, unpack, pairs
local PlaySound = PlaySound

local defaults = {
	fontSize = 14,
	mover = {
		RgsCTIn = {"CENTER",-300,0},
		RgsCTOut = {"CENTER",300,0},
		RgsCTInfo = {"CENTER",0,0},
	},
	showMyPet = true,
	merge = true,
	leech = false,
	periodic = true,
	info = false,
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
local options = {check={}, slider={}}
rct:AddInitFunc(function()
	-- Set values in config
	for _,v in pairs(options.check) do
		v:SetChecked(v.getfunc())
	end
	for _,v in pairs(options.slider) do
		v:SetValue(v.getfunc(),true)
	end
end)

local configFrame = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
configFrame.name = addonName
InterfaceOptions_AddCategory(configFrame)
local optionsPerLine = 3
local idx, first, previous = 1, configFrame, configFrame

local function SetFramePoint(frame, pos)
	if type(pos) == "table" then -- Set custom position
		frame:SetPoint(unpack(pos))
		idx, first = 1, frame
	else
		if pos > 0 and idx <= optionsPerLine - pos then -- same line
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
	local check = CreateFrame("CheckButton", "RgsCTConfig"..label, configFrame, "InterfaceOptionsCheckButtonTemplate")
	check:SetScript("OnClick", function(self)
		local checked = self:GetChecked()
		if set then set(checked) else C.db[label] = checked end
		PlaySound(checked and 856 or 857)
	end)
	check.getfunc = get or function() return C.db[label] end
	_G[check:GetName().."Text"]:SetText(name)
	check.tooltipText = name
	check.tooltipRequirement = desc
	SetFramePoint(check, pos)
	options.check[label] = check
end

local function newSlider(label, name, desc, min, max, step, pos, get, set)
	local slider = CreateFrame("Slider","RgsCTConfig"..label,configFrame,"OptionsSliderTemplate")
	slider.Value = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	slider.Value:SetPoint("BOTTOM",0,-10)
	slider.tooltipText = name
	slider.tooltipRequirement = desc
	slider:SetMinMaxValues(min, max)
	_G[slider:GetName().."Low"]:SetText(min)
	_G[slider:GetName().."High"]:SetText(max)
	_G[slider:GetName().."Text"]:SetText(name)
	slider:SetValueStep(step)
	slider.getfunc = get or function() return C.db[label] end
	slider:SetScript("OnValueChanged", function(self,value)
		value = min + floor((value - min) / step + 0.5) * step
		if set then set(value) else C.db[label]=value end
		self.Value:SetText(value)
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
-- End of GUI template --

C.mover = {}

local titleText = configFrame:CreateFontString(nil,"ARTWORK","GameFontNormalLarge")
titleText:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 200, -20)
titleText:SetText(addonName.." "..GetAddOnMetadata(addonName, "Version"))

newSlider(
	"fontSize", L["fontSize"], nil, 9, 30, 1,
	{"TOPLEFT", configFrame, "TOPLEFT", 16, -60},
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
newCheckBox("merge", L["merge"], L["mergeTooltip"], -1)
newCheckBox("leech", L["leech"], L["leechTooltip"], 1)
newCheckBox("showMyPet", L["showMyPet"], L["showMyPetTooltip"], 1)
newCheckBox("periodic", LOG_PERIODIC_EFFECTS, L["periodicTooltip"], 1)
newCheckBox("info", L["showInfo"], L["showInfoTooltip"], 1)
