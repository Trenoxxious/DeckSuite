function DeckSuite_CreateChatChannelUI()
	if DeckSuiteChatChannelFrame then return end

	local frame = CreateFrame("Frame", "DeckSuiteChatChannelFrame", UIParent, "BasicFrameTemplateWithInset")
	frame:SetSize(380, 550)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	frame:Hide()
	frame:SetFrameStrata("DIALOG")
	table.insert(UISpecialFrames, "DeckSuiteChatChannelFrame")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

	frame.title = frame.TitleText or frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	if frame.TitleText then
		frame.TitleText:SetText("|cFF65D6E7DeckSuite:|r New Chat")
	else
		frame.title:SetPoint("TOP", frame, "TOP", 0, -6)
		frame.title:SetText("|cFF65D6E7DeckSuite:|r New Chat")
	end

	local channels = {
		{name = "Say", command = "/say ", backdropColor = {1, 1, 1, 0.15}, borderColor = {1, 1, 1, 0.5}, textColor = {1, 1, 1, 1}},
		{name = "Party", command = "/party ", backdropColor = {0.67, 0.67, 1, 0.15}, borderColor = {0.67, 0.67, 1, 0.5}, textColor = {0.67, 0.67, 1, 1}},
		{name = "Raid", command = "/raid ", backdropColor = {1, 0.5, 0, 0.15}, borderColor = {1, 0.5, 0, 0.5}, textColor = {1, 0.5, 0, 1}},
		{name = "General", command = "/1 ", backdropColor = {1, 0.75, 0.75, 0.15}, borderColor = {1, 0.75, 0.75, 0.5}, textColor = {1, 0.75, 0.75, 1}},
		{name = "Trade", command = "/2 ", backdropColor = {1, 0.75, 0.75, 0.15}, borderColor = {1, 0.75, 0.75, 0.5}, textColor = {1, 0.75, 0.75, 1}},
		{name = "Guild", command = "/guild ", backdropColor = {0.25, 1, 0.25, 0.15}, borderColor = {0.25, 1, 0.25, 0.5}, textColor = {0.25, 1, 0.25, 0.8}},
		{name = "Officer", command = "/officer ", backdropColor = {0.25, 0.75, 0.25, 0.15}, borderColor = {0.25, 0.75, 0.25, 0.5}, textColor = {0.25, 0.75, 0.25, 1}},
		{name = "New Whisper", command = "/w ", backdropColor = {1, 0.5, 1, 0.15}, borderColor = {1, 0.5, 1, 0.5}, textColor = {1, 0.5, 1, 1}}
	}

	local btnW, btnH = 340, 40
	local startY = -40

	for i, channel in ipairs(channels) do
		local btn = CreateFrame("Frame", "DeckSuiteChatChannelBtn" .. i, frame, "BackdropTemplate")
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

		local nameText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		nameText:SetPoint("CENTER", btn, "CENTER", 0, 0)
		nameText:SetTextColor(1, 0.82, 0)
		nameText:SetText(channel.name)
		nameText:SetTextColor(unpack(channel.textColor))

		btn.originalBackdropColor = channel.backdropColor
		btn.originalBorderColor = channel.borderColor

		btn:SetScript("OnEnter", function(self)
			local bc = self.originalBackdropColor
			self:SetBackdropColor(bc[1], bc[2], bc[3], 0.4)
			self:SetBackdropBorderColor(bc[1], bc[2], bc[3], 1)
		end)
		btn:SetScript("OnLeave", function(self)
			self:SetBackdropColor(unpack(self.originalBackdropColor))
			self:SetBackdropBorderColor(unpack(self.originalBorderColor))
		end)

		local chatCommand = channel.command
		btn:SetScript("OnMouseDown", function()
			ChatFrame_OpenChat(chatCommand)
			frame:Hide()
		end)
	end

	local closeBtn = CreateFrame("Frame", "DeckSuiteChatChannelCloseBtn", frame, "BackdropTemplate")
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

	_G.DeckSuiteChatChannelFrame = frame
end
