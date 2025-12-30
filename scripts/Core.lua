local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("CHAT_MSG_WHISPER")

local function InitializeUI()
	DeckSuite_HideChatButtons()
	DeckSuite_ScaleChatButtonFrame()
	DeckSuite_ReplaceButtonIcons()
	DeckSuite_CreateChatChannelUI()
	DeckSuite_CreateReplyUI()
	DeckSuite_InitializeUnitFrames()

	hooksecurefunc("FCF_UpdateButtonSide", function()
		DeckSuite_ScaleChatButtonFrame()
		DeckSuite_ReplaceButtonIcons()
	end)

	for i = 1, NUM_CHAT_WINDOWS do
		local frame = _G["ChatFrame" .. i]
		if frame then
			frame:HookScript("OnShow", function()
				DeckSuite_ScaleChatButtonFrame()
				DeckSuite_ReplaceButtonIcons()
			end)
		end
	end
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		local addonName = ...
		if addonName ~= "DeckSuite" then
			return
		end

		if not NoxxDeckSuiteWhispers then
			NoxxDeckSuiteWhispers = {}
		end

		InitializeUI()

		self:UnregisterEvent("ADDON_LOADED")

	elseif event == "PLAYER_LOGIN" then
		InitializeUI()

		self:UnregisterEvent("PLAYER_LOGIN")

	elseif event == "CHAT_MSG_WHISPER" then
		local msg, sender = ...
		DeckSuite_AddRecentWhisper(sender, msg)
	end
end)
