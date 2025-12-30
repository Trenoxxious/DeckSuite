local FRAME_WIDTH = 250
local FRAME_HEIGHT = 70
local PORTRAIT_SIZE = 60
local BAR_WIDTH = 180
local BAR_HEIGHT = PORTRAIT_SIZE / 2

local function FormatValue(current, max)
	if current >= 1000000 then
		return string.format("%.1fM", current / 1000000)
	elseif current >= 1000 then
		return string.format("%.1fK", current / 1000)
	else
		return tostring(current)
	end
end

local function GetPowerColor(powerType)
	local colors = {
		[0] = {0, 0.5, 1},
		[1] = {1, 0, 0},
		[2] = {1, 0.5, 0},
		[3] = {1, 1, 0},
		[6] = {0.5, 1, 1},
	}
	return colors[powerType] or {0.5, 0.5, 0.5}
end

function DeckSuite_CreatePlayerFrame()
    if (PlayerFrame) then
        PlayerFrame:Hide()
    end

	if DeckSuitePlayerFrame then return end

	local portraitFrame = CreateFrame("Button", "DeckSuitePlayerFrame", UIParent, "SecureUnitButtonTemplate,BackdropTemplate")
	portraitFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
	portraitFrame:SetPoint("CENTER", UIParent, "CENTER", -260, -100)
	portraitFrame:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 12,
		insets = {left = 2, right = 2, top = 2, bottom = 2}
	})
	portraitFrame:SetBackdropColor(0, 0, 0, 0.9)
	portraitFrame:SetBackdropBorderColor(1, 1, 1, 0.8)
	portraitFrame:RegisterForClicks("AnyUp")
	portraitFrame:SetAttribute("unit", "player")
	portraitFrame:SetAttribute("*type1", "target")
	portraitFrame:SetAttribute("*type2", "togglemenu")

	local portrait = CreateFrame("PlayerModel", "DeckSuitePortraitFrame", portraitFrame)
	portrait:SetSize(PORTRAIT_SIZE, PORTRAIT_SIZE)
	portrait:SetPoint("LEFT", portraitFrame, "LEFT", 5, 0)
	portrait:SetUnit("player")
	portrait:SetPortraitZoom(1)
	portrait:SetCamera(0)
	portraitFrame.portrait = portrait


	local nameText = portraitFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	nameText:SetPoint("BOTTOMLEFT", portrait, "TOP", -30, 5)
	nameText:SetJustifyH("LEFT")
	nameText:SetTextColor(1, 1, 1, 1)
	portraitFrame.nameText = nameText

	local healthBar = CreateFrame("StatusBar", nil, portraitFrame)
	healthBar:SetSize(BAR_WIDTH, BAR_HEIGHT)
	healthBar:SetPoint("TOPLEFT", portrait, "TOPRIGHT", 0, 0)
	healthBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
	healthBar:SetStatusBarColor(0, 1, 0, 1)
	healthBar:SetMinMaxValues(0, 100)
	healthBar:SetValue(100)
	portraitFrame.healthBar = healthBar

	local healthBg = healthBar:CreateTexture(nil, "BACKGROUND")
	healthBg:SetAllPoints(healthBar)
	healthBg:SetTexture("Interface/TargetingFrame/UI-StatusBar")
	healthBg:SetVertexColor(0, 0.3, 0, 0.5)

	local healthText = healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	healthText:SetPoint("CENTER", healthBar, "CENTER", 0, 0)
	healthText:SetTextColor(1, 1, 1, 1)
	portraitFrame.healthText = healthText

	local powerBar = CreateFrame("StatusBar", nil, portraitFrame)
	powerBar:SetSize(BAR_WIDTH, BAR_HEIGHT)
	powerBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, 0)
	powerBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
	powerBar:SetStatusBarColor(0, 0.5, 1, 1)
	powerBar:SetMinMaxValues(0, 100)
	powerBar:SetValue(100)
	portraitFrame.powerBar = powerBar

	local powerBg = powerBar:CreateTexture(nil, "BACKGROUND")
	powerBg:SetAllPoints(powerBar)
	powerBg:SetTexture("Interface/TargetingFrame/UI-StatusBar")
	powerBg:SetVertexColor(0, 0.15, 0.3, 0.5)

	local powerText = powerBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	powerText:SetPoint("CENTER", powerBar, "CENTER", 0, 0)
	powerText:SetTextColor(1, 1, 1, 1)
	portraitFrame.powerText = powerText

	local function UpdatePlayerFrame()
		local health = UnitHealth("player")
		local healthMax = UnitHealthMax("player")
		local power = UnitPower("player")
		local powerMax = UnitPowerMax("player")
		local powerType = UnitPowerType("player")
		local name = UnitName("player")

		portraitFrame.nameText:SetText(name or "Player")

		portraitFrame.healthBar:SetMinMaxValues(0, healthMax)
		portraitFrame.healthBar:SetValue(health)
		portraitFrame.healthText:SetText(FormatValue(health, healthMax) .. " / " .. FormatValue(healthMax, healthMax))

		local healthPercent = health / healthMax
		if healthPercent > 0.5 then
			portraitFrame.healthBar:SetStatusBarColor(0, 1, 0, 1)
		elseif healthPercent > 0.25 then
			portraitFrame.healthBar:SetStatusBarColor(1, 1, 0, 1)
		else
			portraitFrame.healthBar:SetStatusBarColor(1, 0, 0, 1)
		end

		portraitFrame.powerBar:SetMinMaxValues(0, powerMax)
		portraitFrame.powerBar:SetValue(power)
		portraitFrame.powerText:SetText(FormatValue(power, powerMax) .. " / " .. FormatValue(powerMax, powerMax))

		local r, g, b = unpack(GetPowerColor(powerType))
		portraitFrame.powerBar:SetStatusBarColor(r, g, b, 1)
	end

	portraitFrame:RegisterEvent("UNIT_HEALTH")
	portraitFrame:RegisterEvent("UNIT_MAXHEALTH")
	portraitFrame:RegisterEvent("UNIT_POWER_UPDATE")
	portraitFrame:RegisterEvent("UNIT_MAXPOWER")
	portraitFrame:RegisterEvent("UNIT_DISPLAYPOWER")
	portraitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	portraitFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

	portraitFrame:SetScript("OnEvent", function(self, event, unit)
		if event == "PLAYER_ENTERING_WORLD" or (unit and unit == "player") then
			UpdatePlayerFrame()
		end
	end)

	UpdatePlayerFrame()

	_G.DeckSuitePlayerFrame = portraitFrame
end

function DeckSuite_CreateTargetFrame()
	if DeckSuiteTargetFrame then return end

	local frame = CreateFrame("Button", "DeckSuiteTargetFrame", UIParent, "SecureUnitButtonTemplate,BackdropTemplate")
	frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
	frame:SetPoint("CENTER", UIParent, "CENTER", 260, -100)
	frame:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 12,
		insets = {left = 2, right = 2, top = 2, bottom = 2}
	})
	frame:SetBackdropColor(0, 0, 0, 0.9)
	frame:SetBackdropBorderColor(1, 1, 1, 0.8)
	frame:RegisterForClicks("AnyUp")
	frame:SetAttribute("unit", "target")
	frame:SetAttribute("*type1", "target")
	frame:SetAttribute("*type2", "togglemenu")
	frame.mainFrame = frame

	local portrait = CreateFrame("PlayerModel", nil, frame)
	portrait:SetSize(PORTRAIT_SIZE, PORTRAIT_SIZE)
	portrait:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
	portrait:SetCamera(0)
	frame.portrait = portrait


	local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	nameText:SetPoint("BOTTOMRIGHT", portrait, "TOP", 30, 5)
	nameText:SetJustifyH("RIGHT")
	nameText:SetTextColor(1, 1, 1, 1)
	frame.nameText = nameText

	local healthBar = CreateFrame("StatusBar", nil, frame)
	healthBar:SetSize(BAR_WIDTH, BAR_HEIGHT)
	healthBar:SetPoint("TOPRIGHT", portrait, "TOPLEFT", 0, 0)
	healthBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
	healthBar:SetStatusBarColor(0, 1, 0, 1)
	healthBar:SetMinMaxValues(0, 100)
	healthBar:SetValue(100)
	frame.healthBar = healthBar

	local healthBg = healthBar:CreateTexture(nil, "BACKGROUND")
	healthBg:SetAllPoints(healthBar)
	healthBg:SetTexture("Interface/TargetingFrame/UI-StatusBar")
	healthBg:SetVertexColor(0, 0.3, 0, 0.5)

	local healthText = healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	healthText:SetPoint("CENTER", healthBar, "CENTER", 0, 0)
	healthText:SetTextColor(1, 1, 1, 1)
	frame.healthText = healthText

	local powerBar = CreateFrame("StatusBar", nil, frame)
	powerBar:SetSize(BAR_WIDTH, BAR_HEIGHT)
	powerBar:SetPoint("TOPRIGHT", healthBar, "BOTTOMRIGHT", 0, 0)
	powerBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
	powerBar:SetStatusBarColor(0, 0.5, 1, 1)
	powerBar:SetMinMaxValues(0, 100)
	powerBar:SetValue(100)
	frame.powerBar = powerBar

	local powerBg = powerBar:CreateTexture(nil, "BACKGROUND")
	powerBg:SetAllPoints(powerBar)
	powerBg:SetTexture("Interface/TargetingFrame/UI-StatusBar")
	powerBg:SetVertexColor(0, 0.15, 0.3, 0.5)

	local powerText = powerBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	powerText:SetPoint("CENTER", powerBar, "CENTER", 0, 0)
	powerText:SetTextColor(1, 1, 1, 1)
	frame.powerText = powerText

	local function UpdateTargetFrame()
        if (TargetFrame) then
            TargetFrame:Hide()
        end

		if not UnitExists("target") then
			frame:Hide()
			return
		end

		frame:Show()

		local health = UnitHealth("target")
		local healthMax = UnitHealthMax("target")
		local power = UnitPower("target")
		local powerMax = UnitPowerMax("target")
		local powerType = UnitPowerType("target")
		local name = UnitName("target")

		frame.portrait:SetUnit("target")
		frame.portrait:SetPortraitZoom(1)

		local r, g, b = 0.9, 0.3, 0.3
		if UnitIsPlayer("target") then
			if UnitIsFriend("player", "target") then
				r, g, b = 0.3, 0.6, 0.9
			elseif UnitIsEnemy("player", "target") then
				r, g, b = 0.9, 0.3, 0.3
			end
		elseif UnitReaction("target", "player") then
			local reaction = UnitReaction("target", "player")
			if reaction >= 5 then
				r, g, b = 0.3, 0.9, 0.3
			elseif reaction == 4 then
				r, g, b = 0.9, 0.9, 0.3
			else
				r, g, b = 0.9, 0.3, 0.3
			end
		end

		if frame.SetBackdropBorderColor then
			frame:SetBackdropBorderColor(r, g, b, 1)
		end

		frame.nameText:SetText(name or "Target")

		frame.healthBar:SetMinMaxValues(0, healthMax)
		frame.healthBar:SetValue(health)
		frame.healthText:SetText(FormatValue(health, healthMax) .. " / " .. FormatValue(healthMax, healthMax))

		local healthPercent = health / healthMax
		if healthPercent > 0.5 then
			frame.healthBar:SetStatusBarColor(0, 1, 0, 1)
		elseif healthPercent > 0.25 then
			frame.healthBar:SetStatusBarColor(1, 1, 0, 1)
		else
			frame.healthBar:SetStatusBarColor(1, 0, 0, 1)
		end

		if powerMax > 0 then
			frame.powerBar:Show()
			frame.powerBar:SetMinMaxValues(0, powerMax)
			frame.powerBar:SetValue(power)
			frame.powerText:SetText(FormatValue(power, powerMax) .. " / " .. FormatValue(powerMax, powerMax))

			local pr, pg, pb = unpack(GetPowerColor(powerType))
			frame.powerBar:SetStatusBarColor(pr, pg, pb, 1)
		else
			frame.powerBar:Hide()
		end
	end

	frame:RegisterEvent("PLAYER_TARGET_CHANGED")
	frame:RegisterEvent("UNIT_HEALTH")
	frame:RegisterEvent("UNIT_MAXHEALTH")
	frame:RegisterEvent("UNIT_POWER_UPDATE")
	frame:RegisterEvent("UNIT_MAXPOWER")
	frame:RegisterEvent("UNIT_DISPLAYPOWER")

	frame:SetScript("OnEvent", function(self, event, unit)
		if event == "PLAYER_TARGET_CHANGED" or (unit and unit == "target") then
			UpdateTargetFrame()
		end
	end)

	frame:Hide()

	_G.DeckSuiteTargetFrame = frame
end


function DeckSuite_InitializeUnitFrames()
	DeckSuite_CreatePlayerFrame()
	DeckSuite_CreateTargetFrame()
end
