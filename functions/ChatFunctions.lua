function DeckSuite_HideChatButtons()
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

function DeckSuite_ScaleChatButtonFrame()
	for i = 1, NUM_CHAT_WINDOWS do
		local buttonFrame = _G["ChatFrame" .. i .. "ButtonFrame"]
		local chatFrame = _G["ChatFrame" .. i]

		if buttonFrame then
			buttonFrame:SetScale(1.25)
		end

        if chatFrame then
            chatFrame:SetSize(300, 180)
            chatFrame:ClearAllPoints()
            chatFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 35, -10)
            chatFrame:SetUserPlaced(true)
        end
	end
end

function DeckSuite_ReplaceButtonIcons()
	local addonPath = "Interface\\AddOns\\DeckSuite\\"

	for i = 1, NUM_CHAT_WINDOWS do
		local frameName = "ChatFrame" .. i .. "ButtonFrame"

		local bottomButton = _G[frameName .. "BottomButton"]
		if bottomButton then
			bottomButton:SetNormalTexture(addonPath .. "images\\bottom_button")
			bottomButton:SetPushedTexture(addonPath .. "images\\bottom_button")
			bottomButton:SetHighlightTexture(addonPath .. "images\\bottom_button")
		end

		local downButton = _G[frameName .. "DownButton"]
		if downButton then
			downButton:SetNormalTexture(addonPath .. "images\\down_button")
			downButton:SetPushedTexture(addonPath .. "images\\down_button")
			downButton:SetHighlightTexture(addonPath .. "images\\down_button")
		end

		local upButton = _G[frameName .. "UpButton"]
		if upButton then
			upButton:SetNormalTexture(addonPath .. "images\\up_button")
			upButton:SetPushedTexture(addonPath .. "images\\up_button")
			upButton:SetHighlightTexture(addonPath .. "images\\up_button")
		end
	end
end
