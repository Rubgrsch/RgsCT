local addonName, rct = ...
local C, L, G = unpack(rct)

local _G = _G
local error, floor, type, next, select, ipairs, pairs = error, math.floor, type, next, select, ipairs, pairs
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

local options = {check={}, slider={}}
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

	for _,v in pairs(options.check) do
		v:SetChecked(v.getfunc())
	end
	for _,v in pairs(options.slider) do
		v:SetValue(v.getfunc(),true)
	end
end)

-- GUI Template --
local optionsPerLine = 2
local idx, first, previous = 1

local function SetFramePoint(frame, ...)
	local pos = ...
	if type(pos) == "string" then
		frame:SetPoint(...)
		idx, first = 1, frame
	else
		if not first then error("No previous frame!") end
		if idx <= optionsPerLine - pos then
			frame:SetPoint("TOPLEFT", previous, "TOPLEFT", 170, 0)
			idx = idx + 1
		else
			frame:SetPoint("TOPLEFT", first, "TOPLEFT", 0, -40)
			idx, first = 1, frame
		end
	end
	previous = frame
end

local function newCheckBox(frame, label, name, desc, ...)
	local get, set = select(type(...) == "string" and 6 or 2, ...)

	local check = CreateFrame("CheckButton", "RCT"..label, frame, "InterfaceOptionsCheckButtonTemplate")
	check:SetScript("OnClick", function(self)
		local checked = self:GetChecked()
		if set then set(checked) else C.db[label] = checked end
		PlaySound(checked and 856 or 857)
	end)
	check.getfunc = get or function() return C.db[label] end
	check.label = _G[check:GetName().."Text"]
	check.label:SetText(name)
	check.tooltipText = name
	check.tooltipRequirement = desc
	SetFramePoint(check, ...)
	options.check[label] = check
	return check
end

local function newSlider(frame, label, name, desc, min, max, step, ...)
	local slider = CreateFrame("Slider","RCT"..label,frame,"OptionsSliderTemplate")
	slider.Value = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	slider.Value:SetPoint("BOTTOM",0,-10)
	slider.textLow = _G[slider:GetName().."Low"]
	slider.textHigh = _G[slider:GetName().."High"]
	slider.text = _G[slider:GetName().."Text"]
	slider.tooltipText = name
	slider.tooltipRequirement = desc
	slider:SetMinMaxValues(min, max)
	slider.minValue, slider.maxValue = slider:GetMinMaxValues()
	slider.textLow:SetText(slider.minValue)
	slider.textHigh:SetText(slider.maxValue)
	slider.text:SetText(name)
	slider:SetValueStep(step)
	slider.getfunc = function() return C.db[label] end
	slider:SetScript("OnValueChanged", function(self,value)
		value = min + floor((value - min) / step + 0.5) * step
		C.db[label]=value
		self.Value:SetText(value)
	end)
	SetFramePoint(slider, ...)
	options.slider[label] = slider
	return slider
end
-- End of GUI template --

local enableMover = false
G.mover = {}

local configFrame = CreateFrame("Frame","RgsCTConfig",UIParent,"BasicFrameTemplate")
configFrame:SetSize(360,300)
configFrame:SetPoint("Center",UIParent,"CENTER")
configFrame:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", tile = true, tileSize = 16, edgeSize = 16,insets = { left = 4, right = 4, top = 4, bottom = 4 }})
configFrame:SetMovable(true)
configFrame:EnableMouse(true)
configFrame:RegisterForDrag("LeftButton")
configFrame:SetScript("OnDragStart", configFrame.StartMoving)
configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)
configFrame:Hide()
tinsert(UISpecialFrames, configFrame:GetName())

local titleText = configFrame:CreateFontString(nil,"ARTWORK","GameFontNormal")
titleText:SetPoint("CENTER", configFrame, "TOP", 0, -10)
titleText:SetText(addonName.." "..GetAddOnMetadata(addonName, "Version"))

newSlider(
	configFrame, "fontSize", L["fontSize"], nil, 9, 30, 1,
	"TOPLEFT", configFrame, "TOPLEFT", 16, -40)
newCheckBox(configFrame, "mover", L["mover"], L["moverTooltip"], 1,
	function() return enableMover end,
	function()
		enableMover = not enableMover
		for _,frame in ipairs(G.mover) do
			frame:SetMovable(enableMover)
			frame:EnableMouse(enableMover)
			if enableMover then
				frame.texture:SetColorTexture(1, 1, 0.0, 0.5)
				frame.text:SetText(frame.string)
			else
				frame.texture:SetColorTexture(1, 1, 0.0, 0)
				frame.text:SetText("")
				C.db.mover[frame:GetName()]={"BOTTOMLEFT", frame:GetLeft(), frame:GetBottom()}
			end
		end
	end)
newCheckBox(configFrame, "merge", L["merge"], L["mergeTooltip"], 1)
newCheckBox(configFrame, "leech", L["leech"], L["leechTooltip"], 1)
newCheckBox(configFrame, "showMyPet", L["showMyPet"], L["showMyPetTooltip"], 1)
newCheckBox(configFrame, "periodic", LOG_PERIODIC_EFFECTS, L["periodicTooltip"], 1)
newCheckBox(configFrame, "info", L["showInfo"], L["showInfoTooltip"], 1)

-- Add button in interfaceOptions
local InterfaceFrame = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
InterfaceFrame.name = addonName
InterfaceOptions_AddCategory(InterfaceFrame)

local InterfaceButton = CreateFrame("Button", nil, InterfaceFrame, "UIPanelButtonTemplate")
InterfaceButton:SetText(addonName)
InterfaceButton:SetPoint("TOPLEFT", InterfaceFrame, "TOPLEFT", 8, -8)
InterfaceButton:SetSize(100, 25)
InterfaceButton:SetScript("OnClick", function()
	InterfaceOptionsFrame:Hide()
	HideUIPanel(GameMenuFrame)
	configFrame:Show()
end)
