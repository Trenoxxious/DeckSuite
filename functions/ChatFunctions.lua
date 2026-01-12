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