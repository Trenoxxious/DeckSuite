local FRAME_WIDTH = 250
local FRAME_HEIGHT = 70
local PORTRAIT_SIZE = 60
local BAR_WIDTH = 180
local BAR_HEIGHT = PORTRAIT_SIZE / 2
local BUFF_SIZE = 24
local BUFFS_PER_ROW = 6
local BUFF_SPACING = 2

local playerFrameRef = nil
local targetFrameRef = nil
local comboFrameRef = nil
local updateFrameRef = nil
local updateTargetRef = nil

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

local function CreateAuraButton(parent)
	local button = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	button:SetSize(BUFF_SIZE, BUFF_SIZE)
	button:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = false, edgeSize = 8,
		insets = {left = 1, right = 1, top = 1, bottom = 1}
	})
	button:SetBackdropColor(0, 0, 0, 0.8)
	button:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints(button)
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	button.icon = icon

	local count = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
	count:SetTextColor(1, 1, 1, 1)
	button.count = count

	local duration = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	duration:SetPoint("TOP", button, "BOTTOM", 0, -2)
	duration:SetTextColor(1, 1, 1, 1)
	button.duration = duration

	button:Hide()
	return button
end

local function UpdateAuras(frame, unit)
	if not frame.buffButtons then
		frame.buffButtons = {}
		for i = 1, 12 do
			frame.buffButtons[i] = CreateAuraButton(frame)
		end
	end

	if not frame.debuffButtons then
		frame.debuffButtons = {}
		for i = 1, 6 do
			frame.debuffButtons[i] = CreateAuraButton(frame)
		end
	end

	if not UnitExists(unit) then
		for i = 1, #frame.buffButtons do
			frame.buffButtons[i]:Hide()
		end
		for i = 1, #frame.debuffButtons do
			frame.debuffButtons[i]:Hide()
		end
		return
	end

	local buffIndex = 1
	for i = 1, 40 do
		local name, icon, count, _, duration, expirationTime = UnitBuff(unit, i)
		if not name then break end

		if buffIndex <= #frame.buffButtons then
			local button = frame.buffButtons[buffIndex]
			button.icon:SetTexture(icon)
			button.count:SetText(count > 1 and count or "")

			if duration and duration > 0 then
				local timeLeft = expirationTime - GetTime()
				if timeLeft > 60 then
					button.duration:SetText(string.format("%dm", math.floor(timeLeft / 60)))
				else
					button.duration:SetText(string.format("%ds", math.floor(timeLeft)))
				end
			else
				button.duration:SetText("")
			end

			local col = (buffIndex - 1) % BUFFS_PER_ROW
			local row = math.floor((buffIndex - 1) / BUFFS_PER_ROW)
			button:ClearAllPoints()
			button:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5 + col * (BUFF_SIZE + BUFF_SPACING), -5 - row * (BUFF_SIZE + BUFF_SPACING + 10))
			button:SetBackdropBorderColor(0.2, 0.6, 1, 1)
			button:Show()

			buffIndex = buffIndex + 1
		end
	end

	for i = buffIndex, #frame.buffButtons do
		frame.buffButtons[i]:Hide()
	end

	local debuffIndex = 1
	for i = 1, 40 do
		local name, icon, count, debuffType, duration, expirationTime = UnitDebuff(unit, i)
		if not name then break end

		if debuffIndex <= #frame.debuffButtons then
			local button = frame.debuffButtons[debuffIndex]
			button.icon:SetTexture(icon)
			button.count:SetText(count > 1 and count or "")

			if duration and duration > 0 then
				local timeLeft = expirationTime - GetTime()
				if timeLeft > 60 then
					button.duration:SetText(string.format("%dm", math.floor(timeLeft / 60)))
				else
					button.duration:SetText(string.format("%ds", math.floor(timeLeft)))
				end
			else
				button.duration:SetText("")
			end

			local totalBuffRows = math.ceil(buffIndex / BUFFS_PER_ROW)
			local col = (debuffIndex - 1) % BUFFS_PER_ROW
			local row = math.floor((debuffIndex - 1) / BUFFS_PER_ROW)
			button:ClearAllPoints()
			button:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5 + col * (BUFF_SIZE + BUFF_SPACING), -5 - (totalBuffRows + row) * (BUFF_SIZE + BUFF_SPACING + 10))

			local r, g, b = 1, 0, 0
			if debuffType == "Magic" then
				r, g, b = 0.2, 0.6, 1
			elseif debuffType == "Curse" then
				r, g, b = 0.6, 0, 1
			elseif debuffType == "Disease" then
				r, g, b = 0.6, 0.4, 0
			elseif debuffType == "Poison" then
				r, g, b = 0, 0.6, 0
			end
			button:SetBackdropBorderColor(r, g, b, 1)
			button:Show()

			debuffIndex = debuffIndex + 1
		end
	end

	for i = debuffIndex, #frame.debuffButtons do
		frame.debuffButtons[i]:Hide()
	end
end

function DeckSuite_UpdateUnitFramePositions()
	if not DeckSuite or not DeckSuite.db then
		return
	end

	local offset = DeckSuite.db.profile.unitFrames.horizontalOffset or 0
	local v_offset = DeckSuite.db.profile.unitFrames.verticalOffset or 0

	if playerFrameRef and playerFrameRef:IsShown() then
		playerFrameRef:ClearAllPoints()
		playerFrameRef:SetPoint("CENTER", UIParent, "CENTER", -260 + offset, -100 + v_offset)
	end

	if targetFrameRef then
		targetFrameRef:ClearAllPoints()
		targetFrameRef:SetPoint("CENTER", UIParent, "CENTER", 260 - offset, -100 + v_offset)
	end

    if updateFrameRef then
		updateFrameRef()
	end
	if updateTargetRef then
		updateTargetRef()
	end
end

function DeckSuite_UpdateComboFramePosition()
	if not DeckSuite or not DeckSuite.db then
		return
	end

	local cp_v_offset = DeckSuite.db.profile.unitFrames.comboPointVerticalOffset or 0
	local cp_scale = DeckSuite.db.profile.unitFrames.comboPointFrameScale or 0

	if comboFrameRef and comboFrameRef:IsShown() then
		comboFrameRef:ClearAllPoints()
		comboFrameRef:SetPoint("CENTER", UIParent, "CENTER", 0, -150 + cp_v_offset)
        comboFrameRef:SetScale(1.0 * cp_scale)
	end
end

function DeckSuite_UpdateUnitFrameBars()
	if not DeckSuite or not DeckSuite.db then
		return
	end

	local ultraHardcore = DeckSuite.db.profile.unitFrames.ultraHardcoreMode or false

	if playerFrameRef then
		if playerFrameRef.healthBar then
			if ultraHardcore then
				playerFrameRef.healthBar:Hide()
			else
				playerFrameRef.healthBar:Show()
			end
		end
		if playerFrameRef.powerBar then
			if ultraHardcore then
				playerFrameRef.powerBar:Hide()
			else
				playerFrameRef.powerBar:Show()
			end
		end
	end

	if targetFrameRef then
		if targetFrameRef.healthBar then
			if ultraHardcore then
				targetFrameRef.healthBar:Hide()
			else
				targetFrameRef.healthBar:Show()
			end
		end
		if targetFrameRef.powerBar then
			if ultraHardcore then
				targetFrameRef.powerBar:Hide()
			else
				targetFrameRef.powerBar:Show()
			end
		end
	end

	if updateFrameRef then
		updateFrameRef()
	end
	if updateTargetRef then
		updateTargetRef()
	end
end

function DeckSuite_CreatePlayerFrame()
	if DeckSuitePlayerFrame then return end

	if PlayerFrame then
		PlayerFrame:UnregisterAllEvents()
		PlayerFrame:Hide()
		PlayerFrame:SetScript("OnShow", function(self)
			self:Hide()
		end)
	end

	local portraitFrame = CreateFrame("Button", "DeckSuitePlayerFrame", UIParent, "SecureUnitButtonTemplate,BackdropTemplate")
	portraitFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)

	playerFrameRef = portraitFrame

	local offset = 0
    local v_offset = 0
	if DeckSuite and DeckSuite.db then
		offset = DeckSuite.db.profile.unitFrames.horizontalOffset or 0
        v_offset = DeckSuite.db.profile.unitFrames.verticalOffset or 0
	end
	portraitFrame:SetPoint("CENTER", UIParent, "CENTER", -260 + offset, -100 + v_offset)
    portraitFrame:SetFrameStrata("LOW")
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

	local combatGlow = CreateFrame("Frame", nil, portraitFrame, "BackdropTemplate")
	combatGlow:SetPoint("TOPLEFT", -5, 5)
	combatGlow:SetPoint("BOTTOMRIGHT", 5, -5)
	combatGlow:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
	})
    combatGlow:SetBackdropColor(1, 0.8, 0, 0.4)
	combatGlow:SetBackdropBorderColor(1, 0.8, 0, 0.75)
	combatGlow:Hide()
	portraitFrame.combatGlow = combatGlow

	local portrait = CreateFrame("PlayerModel", "DeckSuitePortraitFrame", portraitFrame)
	portrait:SetSize(PORTRAIT_SIZE, PORTRAIT_SIZE)
	portrait:SetPoint("LEFT", portraitFrame, "LEFT", 5, 0)
	portrait:SetUnit("player")
	portrait:SetPortraitZoom(1)
	portrait:SetCamera(0)
	portraitFrame.portrait = portrait

	C_Timer.After(10.0, function()
		if portrait then
			portrait:SetUnit("player")
			portrait:SetCamera(0)
		end
	end)

	local nameText = portraitFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	nameText:SetPoint("BOTTOMLEFT", portrait, "TOP", -32, 7)
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
        local level = UnitLevel("player")

		local ultraHardcore = DeckSuite and DeckSuite.db and DeckSuite.db.profile.unitFrames.ultraHardcoreMode or false

		if ultraHardcore then
			portraitFrame.nameText:SetText(name or "Player")
		else
			portraitFrame.nameText:SetText((name .. " (Lvl " .. level .. ")") or "Player")
		end

		if not ultraHardcore then
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
	end

	updateFrameRef = UpdatePlayerFrame

	portraitFrame:RegisterEvent("UNIT_HEALTH")
	portraitFrame:RegisterEvent("UNIT_MAXHEALTH")
	portraitFrame:RegisterEvent("UNIT_POWER_UPDATE")
	portraitFrame:RegisterEvent("UNIT_MAXPOWER")
	portraitFrame:RegisterEvent("UNIT_DISPLAYPOWER")
    portraitFrame:RegisterEvent("PLAYER_LEVEL_UP")
    portraitFrame:RegisterEvent("PLAYER_LEVEL_CHANGED")
	portraitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	portraitFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
	portraitFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
	portraitFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

	portraitFrame:SetScript("OnEvent", function(self, event, unit)
		if event == "PLAYER_ENTERING_WORLD" then
			UpdatePlayerFrame()
			if UnitAffectingCombat("player") then
				self:SetBackdropBorderColor(1, 0.6, 0, 1)
				self.combatGlow:Show()
			else
				self:SetBackdropBorderColor(1, 1, 1, 0.8)
				self.combatGlow:Hide()
			end
			C_Timer.After(10.0, function()
				if portrait then
					portrait:SetUnit("player")
					portrait:SetCamera(0)
				end
			end)
		elseif event == "PLAYER_REGEN_DISABLED" then
			self:SetBackdropBorderColor(1, 0.6, 0, 1)
			self.combatGlow:Show()
		elseif event == "PLAYER_REGEN_ENABLED" then
			self:SetBackdropBorderColor(1, 1, 1, 0.8)
			self.combatGlow:Hide()
		elseif unit and unit == "player" then
			UpdatePlayerFrame()
		end
	end)

	UpdatePlayerFrame()
	DeckSuite_UpdateUnitFrameBars()

	_G.DeckSuitePlayerFrame = portraitFrame
end

function DeckSuite_CreateTargetFrame()
	if DeckSuiteTargetFrame then return end

	if TargetFrame then
		TargetFrame:UnregisterAllEvents()
		TargetFrame:Hide()
		TargetFrame:SetScript("OnShow", function(self)
			self:Hide()
		end)
	end

	if ComboFrame then
		ComboFrame:UnregisterAllEvents()
		ComboFrame:Hide()
		ComboFrame:SetScript("OnShow", function(self)
			self:Hide()
		end)
	end

	local frame = CreateFrame("Button", "DeckSuiteTargetFrame", UIParent, "SecureUnitButtonTemplate,BackdropTemplate")
	frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)

	targetFrameRef = frame

	local offset = 0
	local v_offset = 0
	if DeckSuite and DeckSuite.db then
		offset = DeckSuite.db.profile.unitFrames.horizontalOffset or 0
		v_offset = DeckSuite.db.profile.unitFrames.verticalOffset or 0
	end
	frame:SetPoint("CENTER", UIParent, "CENTER", 260 - offset, -100 + v_offset)
	frame:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 12,
		insets = {left = 2, right = 2, top = 2, bottom = 2}
	})
	frame:SetBackdropColor(0, 0, 0, 0.9)
	frame:SetBackdropBorderColor(1, 1, 1, 0.8)
	frame:RegisterForClicks("AnyUp")
    frame:SetFrameStrata("LOW")
	frame:SetAttribute("unit", "target")
	frame:SetAttribute("*type1", "target")
	frame:SetAttribute("*type2", "togglemenu")
	frame.mainFrame = frame
	RegisterUnitWatch(frame)

	local portrait = CreateFrame("PlayerModel", nil, frame)
	portrait:SetSize(PORTRAIT_SIZE, PORTRAIT_SIZE)
	portrait:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
	portrait:SetCamera(0)
	frame.portrait = portrait

	local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	nameText:SetPoint("BOTTOMRIGHT", portrait, "TOP", 32, 7)
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
	healthBg:SetVertexColor(1, 1, 1, 0.15)

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

	local addonPath = "Interface\\AddOns\\DeckSuite\\"
	local whisperButton = CreateFrame("Frame", "DeckSuiteTargetWhisperButton", frame)
	whisperButton:SetSize(38, 38)
	whisperButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 37)
	whisperButton:EnableMouse(true)
	whisperButton:SetFrameStrata("MEDIUM")

	local normalTex = whisperButton:CreateTexture(nil, "BACKGROUND")
	normalTex:SetTexture(addonPath .. "images\\whisper_button_new")
	normalTex:SetAllPoints(whisperButton)

	local hoverTex = whisperButton:CreateTexture(nil, "ARTWORK")
	hoverTex:SetTexture(addonPath .. "images\\whisper_button_hover_new")
	hoverTex:SetAllPoints(whisperButton)
	hoverTex:Hide()

	whisperButton:SetScript("OnEnter", function()
		hoverTex:Show()
	end)
	whisperButton:SetScript("OnLeave", function()
		hoverTex:Hide()
	end)

	whisperButton:SetScript("OnMouseDown", function()
		local targetName = UnitName("target")
		if targetName and targetName ~= "" then
			ChatFrame_OpenChat("/w " .. targetName .. " ")
			PlaySound(808)
		end
	end)

	whisperButton:Hide()
	frame.whisperButton = whisperButton

	local partyInviteButton = CreateFrame("Frame", "DeckSuiteTargetPartyInviteButton", frame)
	partyInviteButton:SetSize(38, 38)
	partyInviteButton:SetPoint("LEFT", whisperButton, "RIGHT", -1, 0)
	partyInviteButton:EnableMouse(true)
	partyInviteButton:SetFrameStrata("MEDIUM")

	local partyNormalTex = partyInviteButton:CreateTexture(nil, "BACKGROUND")
	partyNormalTex:SetTexture(addonPath .. "images\\party_invite_new")
	partyNormalTex:SetAllPoints(partyInviteButton)

	local partyHoverTex = partyInviteButton:CreateTexture(nil, "ARTWORK")
	partyHoverTex:SetTexture(addonPath .. "images\\party_invite_hover_new")
	partyHoverTex:SetAllPoints(partyInviteButton)
	partyHoverTex:Hide()

	partyInviteButton:SetScript("OnEnter", function()
		partyHoverTex:Show()
	end)
	partyInviteButton:SetScript("OnLeave", function()
		partyHoverTex:Hide()
	end)

	partyInviteButton:SetScript("OnMouseDown", function()
		local targetName = UnitName("target")
		if targetName and targetName ~= "" then
			InviteUnit(targetName)
			PlaySound(808)
		end
	end)

	partyInviteButton:Hide()
	frame.partyInviteButton = partyInviteButton

	local thankYouButton = CreateFrame("Frame", "DeckSuiteTargetThankYouButton", frame)
	thankYouButton:SetSize(38, 38)
	thankYouButton:SetPoint("LEFT", partyInviteButton, "RIGHT", -1, 0)
	thankYouButton:EnableMouse(true)
	thankYouButton:SetFrameStrata("MEDIUM")

	local thankYouNormalTex = thankYouButton:CreateTexture(nil, "BACKGROUND")
	thankYouNormalTex:SetTexture(addonPath .. "images\\thank_you_new")
	thankYouNormalTex:SetAllPoints(thankYouButton)

	local thankYouHoverTex = thankYouButton:CreateTexture(nil, "ARTWORK")
	thankYouHoverTex:SetTexture(addonPath .. "images\\thank_you_hover_new")
	thankYouHoverTex:SetAllPoints(thankYouButton)
	thankYouHoverTex:Hide()

	thankYouButton:SetScript("OnEnter", function()
		thankYouHoverTex:Show()
	end)
	thankYouButton:SetScript("OnLeave", function()
		thankYouHoverTex:Hide()
	end)

	thankYouButton:SetScript("OnMouseDown", function()
		DoEmote("thank", "target")
		PlaySound(808)
	end)

	thankYouButton:Hide()
	frame.thankYouButton = thankYouButton

	local questMarker = CreateFrame("Frame", nil, frame)
	questMarker:SetSize(32, 32)
	questMarker:SetPoint("TOPRIGHT", portrait, "TOPRIGHT", 16, -42)
	questMarker:SetFrameStrata("LOW")
	questMarker:SetFrameLevel(50)
	questMarker:Hide()

	local questTexture = questMarker:CreateTexture(nil, "ARTWORK")
	questTexture:SetAllPoints(questMarker)

	frame.questMarker = questMarker
	frame.questMarkerTexture = questTexture

	local function UpdateTargetFrame()
		if not UnitExists("target") then
			return
		end

		if Questie and Questie.API and Questie.API.isReady then
			local questIcon = Questie.API.GetQuestObjectiveIconForUnit(UnitGUID("target"))

			if questIcon then
				frame.questMarkerTexture:SetTexture(questIcon)
				frame.questMarker:Show()
			else
				frame.questMarker:Hide()
			end
		end

		local health = UnitHealth("target")
		local healthMax = UnitHealthMax("target")
		local power = UnitPower("target")
		local powerMax = UnitPowerMax("target")
		local powerType = UnitPowerType("target")
		local name = UnitName("target")
        local level = tostring(UnitLevel("target"))
        local specialty = UnitClassification("target")
        local trivial = UnitIsTrivial("target")
        local specialtyText = ""

        if specialty == "rare" then
            specialtyText = " Rare"
        elseif specialty == "rareelite" then
            specialtyText = " Rare Elite"
        elseif specialty == "elite" then
            specialtyText = " Elite"
        end

        if level == "-1" or specialty == "worldboss" then
            level = "??"
        end

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

        if not UnitIsPlayer("target") and (trivial or health == 0) then
            r, g, b = 1, 1, 1
        end

		if frame.SetBackdropBorderColor then
			frame:SetBackdropBorderColor(r, g, b, 1)
		end

        if trivial and not UnitIsPlayer("target") then
            frame:SetAlpha(0.8)
        else
            frame:SetAlpha(1)
        end

		local ultraHardcore = DeckSuite and DeckSuite.db and DeckSuite.db.profile.unitFrames.ultraHardcoreMode or false

		if ultraHardcore then
			frame.nameText:SetText(name or "Target")
		else
			frame.nameText:SetText((name .. " (Lvl " .. level .. specialtyText .. ")") or "Target")
		end

		if not ultraHardcore then
			frame.healthBar:SetMinMaxValues(0, healthMax)
			frame.healthBar:SetValue(health)
			if health > 0 then
				frame.healthText:SetText(FormatValue(health, healthMax) .. " / " .. FormatValue(healthMax, healthMax))
			else
				frame.healthText:SetText("Dead")
			end

			local healthPercent = health / healthMax
			if healthPercent > 0.6 then
				frame.healthBar:SetStatusBarColor(0, 1, 0, 1)
			elseif healthPercent > 0.2 then
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

		UpdateAuras(frame, "target")

		if UnitExists("target") and
		   UnitIsPlayer("target") and
		   not UnitIsUnit("player", "target") and
		   UnitIsFriend("player", "target") then
			frame.whisperButton:Show()
			frame.partyInviteButton:Show()
			frame.thankYouButton:Show()
		else
			frame.whisperButton:Hide()
			frame.partyInviteButton:Hide()
			frame.thankYouButton:Hide()
		end
	end

	updateTargetRef = UpdateTargetFrame
	frame:RegisterEvent("PLAYER_TARGET_CHANGED")
	frame:RegisterUnitEvent("UNIT_HEALTH", "target")
	frame:RegisterUnitEvent("UNIT_MAXHEALTH", "target")
	frame:RegisterUnitEvent("UNIT_POWER_UPDATE", "target")
	frame:RegisterUnitEvent("UNIT_MAXPOWER", "target")
	frame:RegisterUnitEvent("UNIT_DISPLAYPOWER", "target")
	frame:RegisterUnitEvent("UNIT_AURA", "target")

	frame:SetScript("OnEvent", function(self, event, unit)
		if event == "PLAYER_TARGET_CHANGED" then
			UpdateTargetFrame()
            frame.portrait:SetUnit("target")
            frame.portrait:SetPortraitZoom(1)
            frame.portrait:SetCamera(0)
        end

        if (unit and unit == "target") then
            UpdateTargetFrame()
        end
	end)

	frame:SetScript("OnShow", function()
        UpdateTargetFrame()
        frame.portrait:SetUnit("target")
		frame.portrait:SetPortraitZoom(1)
		frame.portrait:SetCamera(0)
    end)

	DeckSuite_UpdateUnitFrameBars()

	_G.DeckSuiteTargetFrame = frame
end

function DeckSuite_CreateComboPointDisplay()
	if DeckSuiteComboPointFrame then return end

    local cp_v_offset = 0
    local cp_scale = 0
	if DeckSuite and DeckSuite.db then
        cp_v_offset = DeckSuite.db.profile.unitFrames.comboPointVerticalOffset or 0
        cp_scale = DeckSuite.db.profile.unitFrames.comboPointFrameScale or 0
	end

	local comboFrame = CreateFrame("Frame", "DeckSuiteComboPointFrame", UIParent)
	comboFrame:SetSize(150, 20)
    comboFrame:SetScale(1.0 * cp_scale)
	comboFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -150 + cp_v_offset)
	comboFrame:SetFrameStrata("LOW")

    comboFrameRef = comboFrame

	comboFrame.dots = {}
	local addonPath = "Interface\\AddOns\\DeckSuite\\"
	local dotSize = 20
	local dotSpacing = 8
	local totalWidth = (dotSize * 5) + (dotSpacing * 4)
	local startX = -(totalWidth / 2) + (dotSize / 2)

	for i = 1, 5 do
		local dot = CreateFrame("Frame", nil, comboFrame)
		dot:SetSize(dotSize, dotSize)
		dot:SetPoint("CENTER", comboFrame, "CENTER", startX + ((i - 1) * (dotSize + dotSpacing)), 0)

		local inactiveTex = dot:CreateTexture(nil, "BACKGROUND")
		inactiveTex:SetTexture(addonPath .. "images\\combo_point_inactive")
		inactiveTex:SetAllPoints(dot)
		dot.inactiveTex = inactiveTex

		local activeTex = dot:CreateTexture(nil, "ARTWORK")
		activeTex:SetTexture(addonPath .. "images\\combo_point_active")
		activeTex:SetAllPoints(dot)
		activeTex:Hide()
		dot.activeTex = activeTex

		local allTex = dot:CreateTexture(nil, "OVERLAY")
		allTex:SetTexture(addonPath .. "images\\combo_point_all")
		allTex:SetAllPoints(dot)
		allTex:Hide()
		dot.allTex = allTex

		comboFrame.dots[i] = dot
	end

	local function UpdateComboPoints()
        if (UnitClass("player") == "Rogue" or UnitClass("player") == "Druid") then
            local comboPoints = GetComboPoints("player", "target")

            comboFrame:Show()

            if comboPoints == 5 then
                -- All 5 combo points - show special "all" texture
                for i = 1, 5 do
                    comboFrame.dots[i].activeTex:Hide()
                    comboFrame.dots[i].allTex:Show()
                end
            else
                -- Normal combo point display
                for i = 1, 5 do
                    comboFrame.dots[i].allTex:Hide()
                    if i <= comboPoints then
                        comboFrame.dots[i].activeTex:Show()
                    else
                        comboFrame.dots[i].activeTex:Hide()
                    end
                end
            end
        end
	end

	comboFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
	comboFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	comboFrame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")

	comboFrame:SetScript("OnEvent", function(self, event, unit)
		if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TARGET_CHANGED" or (event == "UNIT_POWER_FREQUENT" and unit == "player") then
			UpdateComboPoints()
		end
	end)

	comboFrame:Hide()
	UpdateComboPoints()

	_G.DeckSuiteComboPointFrame = comboFrame
end

function DeckSuite_RepositionRaidAndPartyFrames()
	if CompactRaidFrameManager then
		if IsInRaid() then
			CompactRaidFrameManager:ClearAllPoints()
			CompactRaidFrameManager:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -280)
			CompactRaidFrameManager:Show()
		else
			CompactRaidFrameManager:Hide()
		end
	end

	for i = 1, 5 do
		local partyFrame = _G["PartyMemberFrame" .. i]
		if partyFrame then
			partyFrame:ClearAllPoints()
			if i == 1 then
				partyFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -200)
			else
				partyFrame:SetPoint("TOPLEFT", _G["PartyMemberFrame" .. (i - 1)], "BOTTOMLEFT", 0, -10)
			end
		end
	end
end

function DeckSuite_InitializeUnitFrames()
	DeckSuite_CreatePlayerFrame()
	DeckSuite_CreateTargetFrame()
	DeckSuite_CreateComboPointDisplay()

	C_Timer.After(1, function()
		DeckSuite_RepositionRaidAndPartyFrames()
	end)

	C_Timer.After(0.5, function()
		if BuffFrame then
			BuffFrame:Show()
			BuffFrame_Update()
		end
	end)

	local groupUpdateFrame = CreateFrame("Frame")
	groupUpdateFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
	groupUpdateFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	groupUpdateFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
	groupUpdateFrame:RegisterEvent("UI_SCALE_CHANGED")
	groupUpdateFrame:RegisterEvent("COMPACT_UNIT_FRAME_PROFILES_LOADED")
	groupUpdateFrame:SetScript("OnEvent", function()
		DeckSuite_RepositionRaidAndPartyFrames()
	end)
end