-- Initialize addon table
DeckSuite = DeckSuite or {}

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("CHAT_MSG_WHISPER")

local function InitializeUI()
	DeckSuite_CreateCustomChatFrame()
	DeckSuite_SetupChatKeyBindings()
	DeckSuite_HideDefaultChat()
	DeckSuite_CreateChatChannelUI()
	DeckSuite_CreateReplyUI()
	DeckSuite_InitializeUnitFrames()
end

SLASH_DECKSUITEDEBUG1 = "/dsdebug"
SlashCmdList["DECKSUITEDEBUG"] = function(msg)
	local args = {}
	for word in string.gmatch(msg, "%S+") do
		table.insert(args, word)
	end

	-- Handle /dsdebug party command
	if args[1] == "party" then
		if not DeckSuite_TogglePartyDebugMode then
			UIErrorsFrame:AddMessage("DeckSuite: Party frames not initialized!", 1, 0, 0, 1, 5)
			return
		end

		local enabled = DeckSuite_TogglePartyDebugMode()
		if enabled then
			UIErrorsFrame:AddMessage("DeckSuite: Party frame debug mode ENABLED - All 4 party frames now visible", 0, 1, 0, 1, 5)
		else
			UIErrorsFrame:AddMessage("DeckSuite: Party frame debug mode DISABLED - Party frames will only show when in party", 1, 1, 0, 1, 5)
		end
		return
	end

	-- Default debug behavior (chat frame debug)
	if not DeckSuiteMainChatFrame or not DeckSuiteMainChatFrame.messageFrame then
		UIErrorsFrame:AddMessage("DeckSuite: Chat frame not initialized!", 1, 0, 0, 1, 5)
		return
	end

	if not DeckSuite_GetTabDebugData then
		UIErrorsFrame:AddMessage("DeckSuite: Debug function not available!", 1, 0, 0, 1, 5)
		return
	end

	local debugText = DeckSuite_GetTabDebugData()

	if not DeckSuiteDebugFrame then
		local frame = CreateFrame("Frame", "DeckSuiteDebugFrame", UIParent, "BackdropTemplate")
		frame:SetSize(500, 400)
		frame:SetPoint("CENTER")
		frame:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 16,
			insets = {left = 4, right = 4, top = 4, bottom = 4}
		})
		frame:SetBackdropColor(0, 0, 0, 0.9)
		frame:SetMovable(true)
		frame:EnableMouse(true)
		frame:RegisterForDrag("LeftButton")
		frame:SetScript("OnDragStart", frame.StartMoving)
		frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

		local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		title:SetPoint("TOP", 0, -10)
		title:SetText("DeckSuite Debug (Ctrl+C to copy)")

		local scroll = CreateFrame("ScrollFrame", "DeckSuiteDebugScroll", frame, "UIPanelScrollFrameTemplate")
		scroll:SetPoint("TOPLEFT", 10, -35)
		scroll:SetPoint("BOTTOMRIGHT", -30, 40)

		local editBox = CreateFrame("EditBox", nil, scroll)
		editBox:SetMultiLine(true)
		editBox:SetFontObject(GameFontHighlight)
		editBox:SetWidth(460)
		editBox:SetAutoFocus(false)
		scroll:SetScrollChild(editBox)
		frame.editBox = editBox

		local closeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		closeBtn:SetSize(100, 25)
		closeBtn:SetPoint("BOTTOM", 0, 10)
		closeBtn:SetText("Close")
		closeBtn:SetScript("OnClick", function() frame:Hide() end)

		DeckSuiteDebugFrame = frame
	end

	DeckSuiteDebugFrame.editBox:SetText(debugText)
	DeckSuiteDebugFrame.editBox:HighlightText()
	DeckSuiteDebugFrame:Show()

	UIErrorsFrame:AddMessage("DeckSuite: Debug window opened - Ctrl+A then Ctrl+C to copy", 0, 1, 0, 1, 3)
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		local addonName = ...
		if addonName ~= "DeckSuite" then
			return
		end

		DeckSuite_InitializeSettings()

		if NoxxDeckSuiteWhispers then
			DeckSuiteWhispers = NoxxDeckSuiteWhispers
			NoxxDeckSuiteWhispers = nil
		end

		if not DeckSuiteWhispers then
			DeckSuiteWhispers = {}
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
