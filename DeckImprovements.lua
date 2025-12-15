-- DeckImprovements: Steam Deck QoL chat tweaks

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("CHAT_MSG_WHISPER")

local function HideChatButtons()
	if ChatFrameChannelButton then
		ChatFrameChannelButton:Hide()
	end
	if FriendsMicroButton then
		FriendsMicroButton:Hide()
	end
    if ChatFrameMenuButton then
        ChatFrameMenuButton:Hide()
    end
    if TextToSpeechButtonFrame then
        TextToSpeechButtonFrame:Hide()
    end
end

local function ScaleChatButtonFrame()
	if ChatFrame1ButtonFrame then
		ChatFrame1ButtonFrame:SetScale(1.5)
	end
end

local function ReplaceButtonIcons()
	local addonPath = "Interface\\AddOns\\DeckImprovements\\"

	-- Replace bottom button icon
	if ChatFrame1ButtonFrameBottomButton then
		ChatFrame1ButtonFrameBottomButton:SetNormalTexture(addonPath .. "images\\bottom_button")
		ChatFrame1ButtonFrameBottomButton:SetPushedTexture(addonPath .. "images\\bottom_button")
		ChatFrame1ButtonFrameBottomButton:SetHighlightTexture(addonPath .. "images\\bottom_button")
	end

	-- Replace down button icon
	if ChatFrame1ButtonFrameDownButton then
		ChatFrame1ButtonFrameDownButton:SetNormalTexture(addonPath .. "images\\down_button")
		ChatFrame1ButtonFrameDownButton:SetPushedTexture(addonPath .. "images\\down_button")
		ChatFrame1ButtonFrameDownButton:SetHighlightTexture(addonPath .. "images\\down_button")
	end

	-- Replace up button icon
	if ChatFrame1ButtonFrameUpButton then
		ChatFrame1ButtonFrameUpButton:SetNormalTexture(addonPath .. "images\\up_button")
		ChatFrame1ButtonFrameUpButton:SetPushedTexture(addonPath .. "images\\up_button")
		ChatFrame1ButtonFrameUpButton:SetHighlightTexture(addonPath .. "images\\up_button")
	end
end

-- recent whisper tracking
local MAX_RECENTS = 5

local function AddRecentWhisper(name, message)
	if not name or name == "" then return end
	-- strip realm if present
	local short = name:gsub("%-.+$", "")
	message = message or ""

	-- Remove existing entry for this person
	for i = 1, #NoxxDeckImprovementsWhispers do
		if NoxxDeckImprovementsWhispers[i].name == short then
			table.remove(NoxxDeckImprovementsWhispers, i)
			break
		end
	end

	-- Add new entry with name and message
	table.insert(NoxxDeckImprovementsWhispers, 1, {name = short, message = message})
	while #NoxxDeckImprovementsWhispers > MAX_RECENTS do
		table.remove(NoxxDeckImprovementsWhispers)
	end

	if DeckImprovementsReplyFrame and DeckImprovementsReplyFrame:IsShown() and DeckImprovementsReplyFrame.Update then
		DeckImprovementsReplyFrame:Update()
	end
end

-- Create chat channel selection UI (idempotent)
local function CreateChatChannelUI()
	if DeckImprovementsChatChannelFrame then return end

	local frame = CreateFrame("Frame", "DeckImprovementsChatChannelFrame", UIParent, "BasicFrameTemplateWithInset")
	frame:SetSize(380, 550)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	frame:Hide()
	frame:SetFrameStrata("DIALOG")
	table.insert(UISpecialFrames, "DeckImprovementsChatChannelFrame")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

	frame.title = frame.TitleText or frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	if frame.TitleText then
		frame.TitleText:SetText("|cFF65D6E7NoxxDI:|r New Chat")
	else
		frame.title:SetPoint("TOP", frame, "TOP", 0, -6)
		frame.title:SetText("|cFF65D6E7NoxxDI:|r New Chat")
	end

	local channels = {
		{name = "Say", command = "/say ", backdropColor = {1, 1, 1, 0.15}, borderColor = {1, 1, 1, 0.5}, textColor = {1, 1, 1, 1}},
		{name = "Party", command = "/party ", backdropColor = {0.67, 0.67, 1, 0.15}, borderColor = {0.67, 0.67, 1, 0.5}, textColor = {0.67, 0.67, 1, 1}},
		{name = "Raid", command = "/raid ", backdropColor = {1, 0.5, 0, 0.15}, borderColor = {1, 0.5, 0, 0.5}, textColor = {1, 0.5, 0, 1}},
		{name = "General", command = "/1 ", backdropColor = {1, 0.75, 0.75, 0.15}, borderColor = {1, 0.75, 0.75, 0.5}, textColor = {1, 0.75, 0.75, 1}},
		{name = "Trade", command = "/2 ", backdropColor = {1, 0.75, 0.75, 0.15}, borderColor = {1, 0.75, 0.75, 0.5}, textColor = {1, 0.75, 0.75, 1}},
		{name = "Guild", command = "/guild ", backdropColor = {0.25, 1, 0.25, 0.15}, borderColor = {0.25, 1, 0.25, 0.5}, textColor = {0.25, 1 , .25 , .8}},
		{name = "Officer", command = "/officer ", backdropColor = {0.25, 0.75, 0.25, 0.15}, borderColor = {0.25, 0.75, 0.25, 0.5}, textColor = {0.25, 0.75, 0.25, 1}},
		{name = "New Whisper", command = "/w ", backdropColor = {1, 0.5, 1, 0.15}, borderColor = {1, 0.5, 1, 0.5}, textColor = {1, 0.5, 1, 1}}
	}

	local btnW, btnH = 340, 40
	local startY = -40

	for i, channel in ipairs(channels) do
		local btn = CreateFrame("Frame", "DeckImpChatChannelBtn" .. i, frame, "BackdropTemplate")
		btn:SetSize(btnW, btnH)
		btn:SetPoint("TOP", frame, "TOP", 0, startY - (i - 1) * (btnH + 8))
		btn:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 12,
			insets = {left = 3, right = 3, top = 3, bottom = 3}
		})
		btn:SetBackdropColor(unpack(channel.backdropColor))
		btn:SetBackdropBorderColor(unpack(channel.borderColor))
		btn:EnableMouse(true)

		-- Create channel name text
		local nameText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		nameText:SetPoint("CENTER", btn, "CENTER", 0, 0)
		nameText:SetTextColor(1, 0.82, 0)
		nameText:SetText(channel.name)
		nameText:SetTextColor(unpack(channel.textColor))

		-- Store original colors for hover effect
		btn.originalBackdropColor = channel.backdropColor
		btn.originalBorderColor = channel.borderColor

		-- Hover effect - brighten the colors
		btn:SetScript("OnEnter", function(self)
			local bc = self.originalBackdropColor
			self:SetBackdropColor(bc[1], bc[2], bc[3], 0.4)
			self:SetBackdropBorderColor(bc[1], bc[2], bc[3], 1)
		end)
		btn:SetScript("OnLeave", function(self)
			self:SetBackdropColor(unpack(self.originalBackdropColor))
			self:SetBackdropBorderColor(unpack(self.originalBorderColor))
		end)

		-- Click handler
		local chatCommand = channel.command
		btn:SetScript("OnMouseDown", function()
			ChatFrame_OpenChat(chatCommand)
			frame:Hide()
		end)
	end

	-- Close button at the bottom
	local closeBtn = CreateFrame("Frame", "DeckImpChatChannelCloseBtn", frame, "BackdropTemplate")
	closeBtn:SetSize(btnW, 40)
	closeBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 15)
	closeBtn:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 12,
		insets = {left = 3, right = 3, top = 3, bottom = 3}
	})
	closeBtn:SetBackdropColor(0.15, 0.05, 0.05, 0.9)
	closeBtn:SetBackdropBorderColor(0.5, 0.3, 0.3, 1)
	closeBtn:EnableMouse(true)

	local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	closeText:SetPoint("CENTER", closeBtn, "CENTER", 0, 0)
	closeText:SetText("Cancel New Chat")
	closeText:SetTextColor(1, 0.3, 0.3)

	closeBtn:SetScript("OnEnter", function(self)
		self:SetBackdropColor(0.3, 0.1, 0.1, 1)
		self:SetBackdropBorderColor(0.9, 0.5, 0.5, 1)
	end)
	closeBtn:SetScript("OnLeave", function(self)
		self:SetBackdropColor(0.15, 0.05, 0.05, 0.9)
		self:SetBackdropBorderColor(0.5, 0.3, 0.3, 1)
	end)
	closeBtn:SetScript("OnMouseDown", function()
		frame:Hide()
	end)

	_G.DeckImprovementsChatChannelFrame = frame
end

-- Create reply UI and toggle button (idempotent)
local function CreateReplyUI()
	if DeckImprovementsReplyFrame then return end

	local frame = CreateFrame("Frame", "DeckImprovementsReplyFrame", UIParent, "BasicFrameTemplateWithInset")
	frame:SetSize(380, 450)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	frame:Hide()
	frame:SetFrameStrata("DIALOG")
	table.insert(UISpecialFrames, "DeckImprovementsReplyFrame")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

	frame.title = frame.TitleText or frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	if frame.TitleText then
		frame.TitleText:SetText("|cFF65D6E7NoxxDI:|r Recent Whispers")
	else
		frame.title:SetPoint("TOP", frame, "TOP", 0, -6)
		frame.title:SetText("|cFF65D6E7NoxxDI:|r Recent Whispers")
	end

	local visibleCount = 5
	frame.buttons = {}
	local btnW, btnH = 340, 50
	local startY = -40

	for i = 1, visibleCount do
		local btn = CreateFrame("Frame", "DeckImpReplyBtn" .. i, frame, "BackdropTemplate")
		btn:SetSize(btnW, btnH)
		btn:SetPoint("TOP", frame, "TOP", 0, startY - (i - 1) * (btnH + 8))
		btn:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 12,
			insets = {left = 3, right = 3, top = 3, bottom = 3}
		})
		btn:SetBackdropColor(0.1, 0.1, 0.15, 0.9)
		btn:SetBackdropBorderColor(0.4, 0.4, 0.5, 1)
		btn:EnableMouse(true)

		-- Create name text (bold, larger)
		local nameText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		nameText:SetPoint("TOPLEFT", btn, "TOPLEFT", 12, -10)
		nameText:SetTextColor(1, 0.82, 0) -- Gold color
		btn.nameText = nameText

		-- Create message preview text (smaller, gray)
		local msgText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		msgText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -4)
		msgText:SetPoint("RIGHT", btn, "RIGHT", -12, 0)
		msgText:SetTextColor(0.9, 0.9, 0.9) -- Light gray
		msgText:SetJustifyH("LEFT")
		msgText:SetWordWrap(false)
		btn.msgText = msgText

		-- Hover effect
		btn:SetScript("OnEnter", function(self)
			self:SetBackdropColor(0.2, 0.2, 0.3, 1)
			self:SetBackdropBorderColor(0.8, 0.8, 0.9, 1)
		end)
		btn:SetScript("OnLeave", function(self)
			self:SetBackdropColor(0.1, 0.1, 0.15, 0.9)
			self:SetBackdropBorderColor(0.4, 0.4, 0.5, 1)
		end)

		-- Click handler
		btn:SetScript("OnMouseDown", function(self)
			local name = self.whisperName
			if name and name ~= "" then
				ChatFrame_OpenChat("/w " .. name .. " ")
			end
			frame:Hide()
		end)

		frame.buttons[i] = btn
	end

	-- Close button at the bottom
	local closeBtn = CreateFrame("Frame", "DeckImpReplyCloseBtn", frame, "BackdropTemplate")
	closeBtn:SetSize(btnW, 40)
	closeBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 15)
	closeBtn:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 12,
		insets = {left = 3, right = 3, top = 3, bottom = 3}
	})
	closeBtn:SetBackdropColor(0.15, 0.05, 0.05, 0.9)
	closeBtn:SetBackdropBorderColor(0.5, 0.3, 0.3, 1)
	closeBtn:EnableMouse(true)

	local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	closeText:SetPoint("CENTER", closeBtn, "CENTER", 0, 0)
	closeText:SetText("Cancel Reply")
	closeText:SetTextColor(1, 0.3, 0.3)

	closeBtn:SetScript("OnEnter", function(self)
		self:SetBackdropColor(0.3, 0.1, 0.1, 1)
		self:SetBackdropBorderColor(0.9, 0.5, 0.5, 1)
	end)
	closeBtn:SetScript("OnLeave", function(self)
		self:SetBackdropColor(0.15, 0.05, 0.05, 0.9)
		self:SetBackdropBorderColor(0.5, 0.3, 0.3, 1)
	end)
	closeBtn:SetScript("OnMouseDown", function()
		frame:Hide()
	end)

	frame.closeButton = closeBtn

	function frame:Update()
		for i = 1, visibleCount do
			local whisperData = NoxxDeckImprovementsWhispers[i]
			local btn = self.buttons[i]
			if whisperData and whisperData.name then
				btn.whisperName = whisperData.name
				btn.nameText:SetText("Reply to " .. whisperData.name)

				-- Truncate message if too long
				local msg = whisperData.message or ""
				if msg:len() > 45 then
					msg = msg:sub(1, 45) .. "..."
				end
				btn.msgText:SetText(msg)
				btn:Show()
			else
				btn:Hide()
			end
		end
	end

	local toggleParent = ChatFrame1ButtonFrame or ChatFrame1
	local toggle = CreateFrame("Frame", "DeckImprovementsReplyToggle", toggleParent)
	toggle:SetSize(33, 33)
	toggle:SetPoint("LEFT", toggleParent, "LEFT", -2, 60)
	toggle:EnableMouse(true)

	-- Use custom reply button image
	local addonPath = "Interface\\AddOns\\DeckImprovements\\"

	-- Create normal texture
	local normalTex = toggle:CreateTexture(nil, "BACKGROUND")
	normalTex:SetTexture(addonPath .. "images\\reply_button")
	normalTex:SetAllPoints(toggle)

	-- Create hover texture
	local hoverTex = toggle:CreateTexture(nil, "ARTWORK")
	hoverTex:SetTexture(addonPath .. "images\\reply_button_hover")
	hoverTex:SetAllPoints(toggle)
	hoverTex:Hide()

	-- Show/hide hover texture on mouse enter/leave
	toggle:SetScript("OnEnter", function()
		hoverTex:Show()
	end)
	toggle:SetScript("OnLeave", function()
		hoverTex:Hide()
	end)

	toggle:SetScript("OnMouseDown", function()
		if frame:IsShown() then
			frame:Hide()
			PlaySound(808)  -- Close sound
		else
			PlaySound(808)  -- Open sound
			-- Close new chat interface if it's open
			if DeckImprovementsChatChannelFrame and DeckImprovementsChatChannelFrame:IsShown() then
				DeckImprovementsChatChannelFrame:Hide()
			end
			frame:Show()
			frame:Update()
		end
	end)

	-- Create new chat button above the toggle
	local newChatBtn = CreateFrame("Frame", "DeckImprovementsNewChatToggle", toggleParent)
	newChatBtn:SetSize(33, 33)
	newChatBtn:SetPoint("LEFT", toggleParent, "LEFT", -2, 90)
	newChatBtn:EnableMouse(true)

	-- Create normal texture
	local chatNormalTex = newChatBtn:CreateTexture(nil, "BACKGROUND")
	chatNormalTex:SetTexture(addonPath .. "images\\new_chat_button")
	chatNormalTex:SetAllPoints(newChatBtn)

	-- Create hover texture
	local chatHoverTex = newChatBtn:CreateTexture(nil, "ARTWORK")
	chatHoverTex:SetTexture(addonPath .. "images\\new_chat_button_hover")
	chatHoverTex:SetAllPoints(newChatBtn)
	chatHoverTex:Hide()

	-- Show/hide hover texture on mouse enter/leave
	newChatBtn:SetScript("OnEnter", function()
		chatHoverTex:Show()
	end)
	newChatBtn:SetScript("OnLeave", function()
		chatHoverTex:Hide()
	end)

	newChatBtn:SetScript("OnMouseDown", function()
		local chatFrame = DeckImprovementsChatChannelFrame
		if chatFrame and chatFrame:IsShown() then
			chatFrame:Hide()
			PlaySound(808)
		else
			PlaySound(808)
			-- Close reply interface if it's open
			if DeckImprovementsReplyFrame and DeckImprovementsReplyFrame:IsShown() then
				DeckImprovementsReplyFrame:Hide()
			end
			if chatFrame then
				chatFrame:Show()
			end
		end
	end)

	_G.DeckImprovementsReplyFrame = frame
end

f:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		local addonName = ...
		if addonName ~= "DeckImprovements" then
			return
		end
		-- Initialize saved variable
		if not NoxxDeckImprovementsWhispers then
			NoxxDeckImprovementsWhispers = {}
		end
		HideChatButtons()
		ScaleChatButtonFrame()
		ReplaceButtonIcons()
		CreateChatChannelUI()
		CreateReplyUI()
		self:UnregisterEvent("ADDON_LOADED")
	elseif event == "PLAYER_LOGIN" then
		HideChatButtons()
		ScaleChatButtonFrame()
		ReplaceButtonIcons()
		CreateChatChannelUI()
		CreateReplyUI()
		self:UnregisterEvent("PLAYER_LOGIN")
	elseif event == "CHAT_MSG_WHISPER" then
		local msg, sender = ...
		AddRecentWhisper(sender, msg)
	end
end)