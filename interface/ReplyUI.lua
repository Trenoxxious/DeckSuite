function DeckSuite_CreateReplyUI()
	if DeckSuiteReplyFrame then return end

	local frame = CreateFrame("Frame", "DeckSuiteReplyFrame", UIParent, "BasicFrameTemplateWithInset")
	frame:SetSize(380, 450)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	frame:Hide()
	frame:SetFrameStrata("DIALOG")
	table.insert(UISpecialFrames, "DeckSuiteReplyFrame")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

	frame.title = frame.TitleText or frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	if frame.TitleText then
		frame.TitleText:SetText("|cFF65D6E7DeckSuite:|r Recent Whispers")
	else
		frame.title:SetPoint("TOP", frame, "TOP", 0, -6)
		frame.title:SetText("|cFF65D6E7DeckSuite:|r Recent Whispers")
	end

	local visibleCount = 5
	frame.buttons = {}
	local btnW, btnH = 340, 50
	local startY = -40

	for i = 1, visibleCount do
		local btn = CreateFrame("Frame", "DeckSuiteReplyBtn" .. i, frame, "BackdropTemplate")
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

		local nameText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		nameText:SetPoint("TOPLEFT", btn, "TOPLEFT", 12, -10)
		nameText:SetTextColor(1, 0.82, 0)
		btn.nameText = nameText

		local msgText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		msgText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -4)
		msgText:SetPoint("RIGHT", btn, "RIGHT", -12, 0)
		msgText:SetTextColor(0.9, 0.9, 0.9)
		msgText:SetJustifyH("LEFT")
		msgText:SetWordWrap(false)
		btn.msgText = msgText

		btn:SetScript("OnEnter", function(self)
			self:SetBackdropColor(0.2, 0.2, 0.3, 1)
			self:SetBackdropBorderColor(0.8, 0.8, 0.9, 1)
		end)
		btn:SetScript("OnLeave", function(self)
			self:SetBackdropColor(0.1, 0.1, 0.15, 0.9)
			self:SetBackdropBorderColor(0.4, 0.4, 0.5, 1)
		end)

		btn:SetScript("OnMouseDown", function(self)
			local name = self.whisperName
			if name and name ~= "" then
				ChatFrame_OpenChat("/w " .. name .. " ")
			end
			frame:Hide()
		end)

		frame.buttons[i] = btn
	end

	local closeBtn = CreateFrame("Frame", "DeckSuiteReplyCloseBtn", frame, "BackdropTemplate")
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
			local whisperData = NoxxDeckSuiteWhispers[i]
			local btn = self.buttons[i]
			if whisperData and whisperData.name then
				btn.whisperName = whisperData.name
				btn.nameText:SetText("Reply to " .. whisperData.name)

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
	local addonPath = "Interface\\AddOns\\DeckSuite\\"

	local toggle = CreateFrame("Frame", "DeckSuiteReplyToggle", toggleParent)
	toggle:SetSize(33, 33)
	toggle:SetPoint("LEFT", toggleParent, "LEFT", -2, 60)
	toggle:EnableMouse(true)

	local normalTex = toggle:CreateTexture(nil, "BACKGROUND")
	normalTex:SetTexture(addonPath .. "images\\reply_button")
	normalTex:SetAllPoints(toggle)

	local hoverTex = toggle:CreateTexture(nil, "ARTWORK")
	hoverTex:SetTexture(addonPath .. "images\\reply_button_hover")
	hoverTex:SetAllPoints(toggle)
	hoverTex:Hide()

	toggle:SetScript("OnEnter", function()
		hoverTex:Show()
	end)
	toggle:SetScript("OnLeave", function()
		hoverTex:Hide()
	end)

	toggle:SetScript("OnMouseDown", function()
		if frame:IsShown() then
			frame:Hide()
			PlaySound(808)
		else
			PlaySound(808)
			if DeckSuiteChatChannelFrame and DeckSuiteChatChannelFrame:IsShown() then
				DeckSuiteChatChannelFrame:Hide()
			end
			frame:Show()
			frame:Update()
		end
	end)

	local newChatBtn = CreateFrame("Frame", "DeckSuiteNewChatToggle", toggleParent)
	newChatBtn:SetSize(33, 33)
	newChatBtn:SetPoint("LEFT", toggleParent, "LEFT", -2, 90)
	newChatBtn:EnableMouse(true)

	local chatNormalTex = newChatBtn:CreateTexture(nil, "BACKGROUND")
	chatNormalTex:SetTexture(addonPath .. "images\\new_chat_button")
	chatNormalTex:SetAllPoints(newChatBtn)

	local chatHoverTex = newChatBtn:CreateTexture(nil, "ARTWORK")
	chatHoverTex:SetTexture(addonPath .. "images\\new_chat_button_hover")
	chatHoverTex:SetAllPoints(newChatBtn)
	chatHoverTex:Hide()

	newChatBtn:SetScript("OnEnter", function()
		chatHoverTex:Show()
	end)
	newChatBtn:SetScript("OnLeave", function()
		chatHoverTex:Hide()
	end)

	newChatBtn:SetScript("OnMouseDown", function()
		local chatFrame = DeckSuiteChatChannelFrame
		if chatFrame and chatFrame:IsShown() then
			chatFrame:Hide()
			PlaySound(808)
		else
			PlaySound(808)
			if DeckSuiteReplyFrame and DeckSuiteReplyFrame:IsShown() then
				DeckSuiteReplyFrame:Hide()
			end
			if chatFrame then
				chatFrame:Show()
			end
		end
	end)

	_G.DeckSuiteReplyFrame = frame
end
