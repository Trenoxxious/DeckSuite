local CHAT_COLORS = {
    SAY = {1, 1, 1},
    YELL = {1, 0.25, 0.25},
    EMOTE = {1, 0.5, 0.25},
    SKILL_UP = {0.2, 0.38, 0.92},
    TRADESKILLS = {0.2, 0.38, 0.92},
    PET_INFO = {1, 0.5, 0.25},
    SKILL_GAINED = {1, 1, 1},
    COMBAT_XP_GAIN = {0.2, 0.38, 0.92},
    COMBAT_HONOR_GAIN = {0.2, 0.38, 0.92},
    TEXT_EMOTE = {1, 0.5, 0.25},
    PARTY = {0.67, 0.67, 1},
    PARTY_LEADER = {0.46, 0.78, 1},
    RAID = {1, 0.5, 0},
    RAID_LEADER = {1, 0.28, 0.04},
    RAID_WARNING = {1, 0.28, 0},
    GUILD = {0.25, 1, 0.25},
    OFFICER = {0.25, 0.75, 0.25},
    WHISPER = {1, 0.5, 1},
    WHISPER_INFORM = {1, 0.5, 1},
    MONSTER_EMOTE = {1, 0.5, 0.25},
    CHANNEL1 = {1, 0.75, 0.75}, -- General
    CHANNEL2 = {1, 0.75, 0.75}, -- Trade
    CHANNEL3 = {1, 0.75, 0.75}, -- LocalDefense
    CHANNEL4 = {1, 0.75, 0.75}, -- General-like
    CHANNEL5 = {1, 0.75, 0.75}, -- General-like
    CHANNEL6 = {1, 0.75, 0.75}, -- General-like
    CHANNEL7 = {1, 0.75, 0.75}, -- General-like
    CHANNEL8 = {1, 0.75, 0.75}, -- General-like
    CHANNEL9 = {1, 0.75, 0.75}, -- General-like
    CHANNEL10 = {1, 0.75, 0.75}, -- General-like
    SYSTEM = {1, 1, 0},
    COMBAT_MISC_INFO = {1, 1, 0},
    MONEY = {1, 1, 0},
    ACHIEVEMENT = {1, 1, 0},
    LOOT = {0, 0.67, 0}
}

local DeckSuiteCustomChat = {
    maxMessages = 500,
    messages = {},
    currentChannel = "SAY",
    currentChannelCommand = "/s ",

    -- Tab system
    tabs = {},
    activeTabIndex = 1,
    tabsInitialized = false,
}


function DeckSuite_CreateDefaultTab()
    return {
        index = 1,
        chatFrameIndex = 1,
        name = "All",
        shown = true,
        messageTypes = {
            CHAT_MSG_SAY = true,
            CHAT_MSG_YELL = true,
            CHAT_MSG_EMOTE = true,
            CHAT_MSG_TEXT_EMOTE = true,
            CHAT_MSG_MONSTER_EMOTE = true,
            CHAT_MSG_PARTY = true,
            CHAT_MSG_PARTY_LEADER = true,
            CHAT_MSG_RAID = true,
            CHAT_MSG_RAID_LEADER = true,
            CHAT_MSG_RAID_WARNING = true,
            CHAT_MSG_GUILD = true,
            CHAT_MSG_OFFICER = true,
            CHAT_MSG_WHISPER = true,
            CHAT_MSG_WHISPER_INFORM = true,
            CHAT_MSG_SYSTEM = true,
            CHAT_MSG_COMBAT_XP_GAIN = true,
            CHAT_MSG_SKILL = true,
            CHAT_MSG_ACHIEVEMENT = true,
            CHAT_MSG_LOOT = true,
        },
        channels = {},  -- Empty means all channels
        messages = {},
        lastDisplayedCount = 0,
    }
end

function DeckSuite_BuildChannelSet(chatFrameIndex)
    local channels = {}
    local channelList = {GetChatWindowChannels(chatFrameIndex)}

    for i = 1, #channelList, 2 do
        local channelNum = channelList[i]
        if channelNum then
            channels[channelNum] = true
        end
    end

    return channels
end

function DeckSuite_UpdateChatFrameFontSize()
    if not DeckSuiteMainChatFrame or not DeckSuiteMainChatFrame.messageFrame then
        return
    end

    local messageFrame = DeckSuiteMainChatFrame.messageFrame
    local fontSize = DeckSuite.db.profile.chatFrame.fontSize or 14

    local fontPath, _, fontFlags = messageFrame:GetFont()

    if not fontPath then
        fontPath = "Fonts\\FRIZQT__.TTF"
    end

    messageFrame:SetFont(fontPath, fontSize, fontFlags)
end

function DeckSuite_BuildMessageTypeSet(chatFrameIndex)
    local chatFrame = _G["ChatFrame" .. chatFrameIndex]
    if not chatFrame then
        return {}
    end

    local typeSet = {}

    if chatFrame.messageTypeList then
        for _, msgType in pairs(chatFrame.messageTypeList) do
            local group = ChatTypeGroup[msgType]
            if group then
                for _, event in ipairs(group) do
                    typeSet[event] = true
                end
            else
                local fullType = "CHAT_MSG_" .. msgType
                typeSet[fullType] = true
            end
        end
    end

    return typeSet
end

function DeckSuite_ReadChatWindowConfig(chatFrameIndex)
    local name, _, _, _, _, _, shown = GetChatWindowInfo(chatFrameIndex)

    if not name or name == "" then
        return nil
    end

    if name == "Combat Log" or name == "Voice" then
        return nil
    end

    local messageTypes = DeckSuite_BuildMessageTypeSet(chatFrameIndex)
    local channels = DeckSuite_BuildChannelSet(chatFrameIndex)

    local hasConfig = next(messageTypes) ~= nil or next(channels) ~= nil
    if not shown and not hasConfig then
        return nil
    end

    local tab = {
        index = #DeckSuiteCustomChat.tabs + 1,
        chatFrameIndex = chatFrameIndex,
        name = name,
        shown = shown,
        messageTypes = messageTypes,
        channels = channels,
        messages = {},
        lastDisplayedCount = 0,
    }

    return tab
end

function DeckSuite_InitializeTabs()
    if DeckSuiteCustomChat.tabsInitialized then
        return
    end

    DeckSuiteCustomChat.tabs = {}

    for i = 1, NUM_CHAT_WINDOWS do
        local name, _, _, _, _, _, shown = GetChatWindowInfo(i)

        local tab = DeckSuite_ReadChatWindowConfig(i)
        if tab then
            table.insert(DeckSuiteCustomChat.tabs, tab)
        end
    end

    if #DeckSuiteCustomChat.tabs == 0 then
        local defaultTab = DeckSuite_CreateDefaultTab()
        table.insert(DeckSuiteCustomChat.tabs, defaultTab)
    end

    if #DeckSuiteCustomChat.messages > 0 then
        for _, msg in ipairs(DeckSuiteCustomChat.messages) do
            table.insert(DeckSuiteCustomChat.tabs[1].messages, msg)
        end
        DeckSuiteCustomChat.messages = {}
    end

    DeckSuiteCustomChat.activeTabIndex = 1
    DeckSuiteCustomChat.tabsInitialized = true
end

function DeckSuite_UpdateTabVisuals()
    if not DeckSuiteMainChatFrame or not DeckSuiteMainChatFrame.tabPanel then
        return
    end

    local tabPanel = DeckSuiteMainChatFrame.tabPanel
    if not tabPanel.tabButtons then
        return
    end

    for i, button in ipairs(tabPanel.tabButtons) do
        if i == DeckSuiteCustomChat.activeTabIndex then
            button:SetBackdropColor(0.2, 0.3, 0.4, 1.0)
            button:SetBackdropBorderColor(0.6, 0.7, 0.8, 1.0)
            if button.label then
                button.label:SetTextColor(1, 1, 1, 1)
            end
        else
            button:SetBackdropColor(0.05, 0.08, 0.1, 0.8)
            button:SetBackdropBorderColor(0.3, 0.3, 0.4, 1.0)
            if button.label then
                button.label:SetTextColor(0.7, 0.7, 0.7, 1)
            end
        end
    end
end

function DeckSuite_CreateTabButton(tabPanel, tab, tabIndex)
    local button = CreateFrame("Frame", "DeckSuiteTabButton" .. tabIndex, tabPanel, "BackdropTemplate")
    button:SetSize(28, 28)

    local yOffset = -8 - ((tabIndex - 1) * 30)
    button:SetPoint("TOP", tabPanel, "TOP", 0, yOffset)

    button:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })

    button:SetBackdropColor(0.05, 0.08, 0.1, 0.8)
    button:SetBackdropBorderColor(0.3, 0.3, 0.4, 1.0)
    button:EnableMouse(true)

    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER", button, "CENTER", 0, 0)
    label:SetText(tostring(tabIndex))
    label:SetTextColor(0.7, 0.7, 0.7, 1)
    button.label = label

    button:SetScript("OnEnter", function(self)
        if tabIndex ~= DeckSuiteCustomChat.activeTabIndex then
            self:SetBackdropColor(0.1, 0.15, 0.2, 0.9)
            self:SetBackdropBorderColor(0.4, 0.5, 0.6, 1.0)
        end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(tab.name, 1, 1, 1)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
        DeckSuite_UpdateTabVisuals()
    end)

    button:SetScript("OnMouseDown", function()
        PlaySound(808)
        DeckSuite_SwitchToTab(tabIndex)
    end)

    return button
end

function DeckSuite_CreateTabPanel(mainFrame)
    local tabPanel = CreateFrame("Frame", "DeckSuiteChatTabPanel", mainFrame, "BackdropTemplate")
    tabPanel:SetSize(30, 165)
    tabPanel:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 4, 3)
    tabPanel:SetBackdropColor(0, 0, 0, 0.5)
    tabPanel:SetFrameStrata("LOW")

    tabPanel.tabButtons = {}

    for i, tab in ipairs(DeckSuiteCustomChat.tabs) do
        local button = DeckSuite_CreateTabButton(tabPanel, tab, i)
        table.insert(tabPanel.tabButtons, button)
    end

    local newTabBtn = CreateFrame("Button", "DeckSuiteChatNewTabBtn", tabPanel, "BackdropTemplate")
    newTabBtn:SetSize(28, 28)
    newTabBtn:SetPoint("BOTTOM", tabPanel, "BOTTOM", 0, 32)
    newTabBtn:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    newTabBtn:SetBackdropColor(0.1, 0.3, 0.1, 0.9)
    newTabBtn:SetBackdropBorderColor(0.3, 0.7, 0.3, 1.0)

    local newTabIcon = newTabBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    newTabIcon:SetPoint("CENTER")
    newTabIcon:SetText("+")
    newTabIcon:SetTextColor(0.6, 1, 0.6, 1)

    newTabBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.2, 0.4, 0.2, 1.0)
        newTabIcon:SetTextColor(0.8, 1, 0.8, 1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("New Chat Tab", 1, 1, 1)
        GameTooltip:AddLine("Creates a new chat window", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)

    newTabBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.1, 0.3, 0.1, 0.9)
        newTabIcon:SetTextColor(0.6, 1, 0.6, 1)
        GameTooltip:Hide()
    end)

    newTabBtn:SetScript("OnClick", function()
        PlaySound(808)
        DeckSuite_CreateNewChatTab()
    end)

    local settingsBtn = CreateFrame("Button", "DeckSuiteChatSettingsBtn", tabPanel, "BackdropTemplate")
    settingsBtn:SetSize(28, 28)
    settingsBtn:SetPoint("BOTTOM", tabPanel, "BOTTOM", 0, 2)
    settingsBtn:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    settingsBtn:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    settingsBtn:SetBackdropBorderColor(0.5, 0.5, 0.5, 1.0)

    local settingsIcon = settingsBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    settingsIcon:SetPoint("CENTER")
    settingsIcon:SetText("S") -- ⚙
    settingsIcon:SetTextColor(0.8, 0.8, 0.8, 1)

    settingsBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.2, 0.2, 0.2, 1.0)
        settingsIcon:SetTextColor(1, 1, 1, 1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Chat Settings", 1, 1, 1)
        GameTooltip:AddLine("Opens Blizzard chat config", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)

    settingsBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        settingsIcon:SetTextColor(0.8, 0.8, 0.8, 1)
        GameTooltip:Hide()
    end)

    settingsBtn:SetScript("OnClick", function()
        PlaySound(808)
        DeckSuite_OpenChatSettings()
    end)

    DeckSuite_UpdateTabVisuals()

    return tabPanel
end

function DeckSuite_RefreshTabs()
    local preservedMessages = {}
    local activeChatFrameIndex = nil

    if DeckSuiteCustomChat.tabs then
        local activeTab = DeckSuiteCustomChat.tabs[DeckSuiteCustomChat.activeTabIndex]
        if activeTab then
            activeChatFrameIndex = activeTab.chatFrameIndex
        end

        for _, tab in ipairs(DeckSuiteCustomChat.tabs) do
            if tab.chatFrameIndex and tab.messages then
                preservedMessages[tab.chatFrameIndex] = tab.messages
            end
        end
    end

    DeckSuiteCustomChat.tabsInitialized = false
    DeckSuiteCustomChat.tabs = {}

    DeckSuite_InitializeTabs()

    for _, tab in ipairs(DeckSuiteCustomChat.tabs) do
        if tab.chatFrameIndex and preservedMessages[tab.chatFrameIndex] then
            tab.messages = preservedMessages[tab.chatFrameIndex]
        end
    end

    if DeckSuiteMainChatFrame and DeckSuiteMainChatFrame.tabPanel then
        DeckSuiteMainChatFrame.tabPanel:Hide()
        DeckSuiteMainChatFrame.tabPanel = nil

        local tabPanel = DeckSuite_CreateTabPanel(DeckSuiteMainChatFrame)
        DeckSuiteMainChatFrame.tabPanel = tabPanel

        DeckSuiteCustomChat.activeTabIndex = 1
        if activeChatFrameIndex then
            for i, tab in ipairs(DeckSuiteCustomChat.tabs) do
                if tab.chatFrameIndex == activeChatFrameIndex then
                    DeckSuiteCustomChat.activeTabIndex = i
                    break
                end
            end
        end

        DeckSuite_UpdateTabVisuals()
        DeckSuite_RefreshTabDisplay()
    end
end

StaticPopupDialogs["DECKSUITE_NEW_TAB"] = {
    text = "Enter name for new chat tab:",
    button1 = "Create",
    button2 = "Cancel",
    hasEditBox = true,
    maxLetters = 32,
    OnAccept = function(self)
        local editBox = self.editBox or self.EditBox
        local text = editBox and editBox:GetText()
        if text and text ~= "" then
            DeckSuite_DoCreateChatTab(text)
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local text = self:GetText()
        if text and text ~= "" then
            DeckSuite_DoCreateChatTab(text)
            self:GetParent():Hide()
        end
    end,
    OnShow = function(self)
        local editBox = self.editBox or self.EditBox
        if editBox then editBox:SetFocus() end
    end,
    OnHide = function(self)
        local editBox = self.editBox or self.EditBox
        if editBox then editBox:SetText("") end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function DeckSuite_DoCreateChatTab(name)
    if FCF_OpenNewWindow then
        local newChatFrame = FCF_OpenNewWindow(name)

        if newChatFrame then
            newChatFrame:Show()
            FCF_SetLocked(newChatFrame, 1)

            FCF_SetWindowName(newChatFrame, name)

            C_Timer.After(0.3, function()
                DeckSuite_RefreshTabs()
            end)
        end
    end
end

function DeckSuite_CreateNewChatTab()
    StaticPopup_Show("DECKSUITE_NEW_TAB")
end

function DeckSuite_OpenChatSettings()
    if ChatConfigFrame then
        ShowUIPanel(ChatConfigFrame)

        if not ChatConfigFrame.deckSuiteHooked then
            ChatConfigFrame:HookScript("OnHide", function()
                C_Timer.After(0.1, function()
                    DeckSuite_RefreshTabs()
                end)
            end)
            ChatConfigFrame.deckSuiteHooked = true
        end
    else
        ChatFrame_OpenChat("/chatconfig")
    end
end

function DeckSuite_RefreshTabDisplay()
    if not DeckSuiteMainChatFrame or not DeckSuiteMainChatFrame.messageFrame then
        return
    end

    local activeTab = DeckSuiteCustomChat.tabs[DeckSuiteCustomChat.activeTabIndex]
    if not activeTab then
        return
    end

    local messageFrame = DeckSuiteMainChatFrame.messageFrame

    messageFrame:Clear()

    for _, msg in ipairs(activeTab.messages) do
        messageFrame:AddMessage(msg.text, msg.r, msg.g, msg.b)
    end

    activeTab.lastDisplayedCount = #activeTab.messages

    messageFrame:ScrollToBottom()
end

function DeckSuite_SwitchToTab(tabIndex)
    if tabIndex < 1 or tabIndex > #DeckSuiteCustomChat.tabs then
        return
    end

    if DeckSuiteCustomChat.activeTabIndex == tabIndex then
        return
    end

    DeckSuiteCustomChat.activeTabIndex = tabIndex

    DeckSuite_RefreshTabDisplay()

    DeckSuite_UpdateTabVisuals()
end

function DeckSuite_GetTabDebugData()
    local debugText = "=== DeckSuite Tab Debug ===\n"
    debugText = debugText .. "Total tabs: " .. #DeckSuiteCustomChat.tabs .. "\n"
    debugText = debugText .. "Active tab: " .. DeckSuiteCustomChat.activeTabIndex .. "\n\n"

    for i, tab in ipairs(DeckSuiteCustomChat.tabs) do
        debugText = debugText .. "--- Tab " .. i .. " ---\n"
        debugText = debugText .. "  Name: " .. tab.name .. "\n"
        debugText = debugText .. "  ChatFrame: " .. tab.chatFrameIndex .. "\n"

        local chatFrame = _G["ChatFrame" .. tab.chatFrameIndex]
        if chatFrame then
            debugText = debugText .. "  ChatFrame exists: true\n"
            debugText = debugText .. "  messageTypeList exists: " .. tostring(chatFrame.messageTypeList ~= nil) .. "\n"

            if chatFrame.messageTypeList then
                local count = 0
                local sampleKeys = ""
                local samplesCollected = 0
                for k, v in pairs(chatFrame.messageTypeList) do
                    count = count + 1
                    if samplesCollected < 5 then
                        sampleKeys = sampleKeys .. tostring(k) .. "=" .. tostring(v) .. ", "
                        samplesCollected = samplesCollected + 1
                    end
                end
                debugText = debugText .. "  messageTypeList count: " .. count .. "\n"
                if sampleKeys ~= "" then
                    debugText = debugText .. "  Sample keys: " .. sampleKeys .. "\n"
                end
            end
        else
            debugText = debugText .. "  ChatFrame exists: false\n"
        end

        local msgTypeCount = 0
        local msgTypeList = ""
        for msgType, _ in pairs(tab.messageTypes) do
            msgTypeCount = msgTypeCount + 1
            msgTypeList = msgTypeList .. msgType .. ", "
        end
        debugText = debugText .. "  Tab message types: " .. msgTypeCount .. "\n"
        if msgTypeCount > 0 and msgTypeCount < 5 then
            debugText = debugText .. "    Types: " .. msgTypeList .. "\n"
        end

        local channelCount = 0
        local channelList = ""
        for chNum, _ in pairs(tab.channels) do
            channelCount = channelCount + 1
            channelList = channelList .. chNum .. ", "
        end
        debugText = debugText .. "  Channels: " .. channelCount .. " (" .. channelList .. ")\n"
        debugText = debugText .. "  Messages stored: " .. #tab.messages .. "\n\n"
    end

    return debugText
end

function DeckSuite_GetTabsForMessage(chatType, channelNum, channelName)
    local matchingTabs = {}

    local fullMessageType = "CHAT_MSG_" .. chatType

    for i, tab in ipairs(DeckSuiteCustomChat.tabs) do
        local shouldAdd = false

        if chatType == "CHANNEL" then
            if channelName and tab.channels and tab.channels[channelName] then
                shouldAdd = true
            elseif channelName and tab.channels then
                local baseName = channelName:match("^(.-)%s%-%s")
                if baseName and tab.channels[baseName] then
                    shouldAdd = true
                end
            end

            if not shouldAdd and tab.messageTypes and tab.messageTypes["CHAT_MSG_CHANNEL"] then
                if tab.channels and next(tab.channels) == nil then
                    shouldAdd = true
                end
            end
        else
            if tab.messageTypes and tab.messageTypes[fullMessageType] then
                shouldAdd = true
            end
        end

        if shouldAdd then
            table.insert(matchingTabs, i)
        end
    end

    return matchingTabs
end

function DeckSuite_AddChatMessageToTabs(message, r, g, b, chatType, channelNum, channelName)
    local matchingTabs = DeckSuite_GetTabsForMessage(chatType, channelNum, channelName)

    local activeTabMatches = false
    for _, tabIndex in ipairs(matchingTabs) do
        local tab = DeckSuiteCustomChat.tabs[tabIndex]
        if tab then
            local msg = {
                text = message,
                r = r or 1,
                g = g or 1,
                b = b or 1
            }

            table.insert(tab.messages, msg)

            while #tab.messages > DeckSuiteCustomChat.maxMessages do
                table.remove(tab.messages, 1)
            end

            if tabIndex == DeckSuiteCustomChat.activeTabIndex then
                activeTabMatches = true
            end
        end
    end

    if activeTabMatches then
        DeckSuite_UpdateChatDisplay()
    end
end

function DeckSuite_CreateCustomChatFrame()
    if DeckSuiteMainChatFrame then return end

    local mainFrame = CreateFrame("Frame", "DeckSuiteMainChatFrame", UIParent, "BackdropTemplate")
    mainFrame:SetSize(430, 165)
    mainFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
    mainFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    mainFrame:SetBackdropColor(0, 0, 0, 0.7)
    mainFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    mainFrame:SetFrameStrata("LOW")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)

    local buttonPanel = CreateFrame("Frame", "DeckSuiteChatButtonPanel", UIParent, "BackdropTemplate")
    buttonPanel:SetSize(45, 185)
    buttonPanel:SetPoint("LEFT", mainFrame, "RIGHT", -5, 0)
    buttonPanel:SetFrameStrata("LOW")

    local addonPath = "Interface\\AddOns\\DeckSuite\\"
    local buttonSize = 36
    local spacing = -4

    local newChatBtn = CreateFrame("Frame", "DeckSuiteCustomChatNewChatBtn", buttonPanel)
    newChatBtn:SetSize(buttonSize, buttonSize)
    newChatBtn:SetPoint("TOP", buttonPanel, "TOP", 0, -10)
    newChatBtn:EnableMouse(true)

    local chatNormalTex = newChatBtn:CreateTexture(nil, "BACKGROUND")
    chatNormalTex:SetTexture(addonPath .. "images\\new_chat_button_new")
    chatNormalTex:SetAllPoints(newChatBtn)

    local chatHoverTex = newChatBtn:CreateTexture(nil, "ARTWORK")
    chatHoverTex:SetTexture(addonPath .. "images\\new_chat_button_hover_new")
    chatHoverTex:SetAllPoints(newChatBtn)
    chatHoverTex:Hide()

    newChatBtn:SetScript("OnEnter", function() chatHoverTex:Show() end)
    newChatBtn:SetScript("OnLeave", function() chatHoverTex:Hide() end)
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

    local replyBtn = CreateFrame("Frame", "DeckSuiteCustomChatReplyBtn", buttonPanel)
    replyBtn:SetSize(buttonSize, buttonSize)
    replyBtn:SetPoint("TOP", newChatBtn, "BOTTOM", 0, -spacing)
    replyBtn:EnableMouse(true)

    local replyNormalTex = replyBtn:CreateTexture(nil, "BACKGROUND")
    replyNormalTex:SetTexture(addonPath .. "images\\reply_button_new")
    replyNormalTex:SetAllPoints(replyBtn)

    local replyHoverTex = replyBtn:CreateTexture(nil, "ARTWORK")
    replyHoverTex:SetTexture(addonPath .. "images\\reply_button_hover_new")
    replyHoverTex:SetAllPoints(replyBtn)
    replyHoverTex:Hide()

    replyBtn:SetScript("OnEnter", function() replyHoverTex:Show() end)
    replyBtn:SetScript("OnLeave", function() replyHoverTex:Hide() end)
    replyBtn:SetScript("OnMouseDown", function()
        local frame = DeckSuiteReplyFrame
        if frame and frame:IsShown() then
            frame:Hide()
            PlaySound(808)
        else
            PlaySound(808)
            if DeckSuiteChatChannelFrame and DeckSuiteChatChannelFrame:IsShown() then
                DeckSuiteChatChannelFrame:Hide()
            end
            if frame then
                frame:Show()
                frame:Update()
            end
        end
    end)

    local upBtn = CreateFrame("Frame", "DeckSuiteCustomChatUpBtn", buttonPanel)
    upBtn:SetSize(buttonSize, buttonSize)
    upBtn:SetPoint("TOP", replyBtn, "BOTTOM", 0, -spacing)
    upBtn:EnableMouse(true)

    local upNormalTex = upBtn:CreateTexture(nil, "BACKGROUND")
    upNormalTex:SetTexture(addonPath .. "images\\up_button_new")
    upNormalTex:SetAllPoints(upBtn)

    local upHoverTex = upBtn:CreateTexture(nil, "ARTWORK")
    upHoverTex:SetTexture(addonPath .. "images\\up_button_hover_new")
    upHoverTex:SetAllPoints(upBtn)
    upHoverTex:Hide()

    upBtn:SetScript("OnEnter", function() upHoverTex:Show() end)
    upBtn:SetScript("OnLeave", function() upHoverTex:Hide() end)
    upBtn:SetScript("OnMouseDown", function()
        PlaySound(808)
        if mainFrame.messageFrame then
            mainFrame.messageFrame:ScrollUp()
            mainFrame.messageFrame:ScrollUp()
        end
    end)

    local downBtn = CreateFrame("Frame", "DeckSuiteCustomChatDownBtn", buttonPanel)
    downBtn:SetSize(buttonSize, buttonSize)
    downBtn:SetPoint("TOP", upBtn, "BOTTOM", 0, -spacing)
    downBtn:EnableMouse(true)

    local downNormalTex = downBtn:CreateTexture(nil, "BACKGROUND")
    downNormalTex:SetTexture(addonPath .. "images\\down_button_new")
    downNormalTex:SetAllPoints(downBtn)

    local downHoverTex = downBtn:CreateTexture(nil, "ARTWORK")
    downHoverTex:SetTexture(addonPath .. "images\\down_button_hover_new")
    downHoverTex:SetAllPoints(downBtn)
    downHoverTex:Hide()

    downBtn:SetScript("OnEnter", function() downHoverTex:Show() end)
    downBtn:SetScript("OnLeave", function() downHoverTex:Hide() end)
    downBtn:SetScript("OnMouseDown", function()
        PlaySound(808)
        if mainFrame.messageFrame then
            mainFrame.messageFrame:ScrollDown()
            mainFrame.messageFrame:ScrollDown()
        end
    end)

    local bottomBtn = CreateFrame("Frame", "DeckSuiteCustomChatBottomBtn", buttonPanel)
    bottomBtn:SetSize(buttonSize, buttonSize)
    bottomBtn:SetPoint("TOP", downBtn, "BOTTOM", 0, -spacing)
    bottomBtn:EnableMouse(true)

    local bottomNormalTex = bottomBtn:CreateTexture(nil, "BACKGROUND")
    bottomNormalTex:SetTexture(addonPath .. "images\\bottom_button_new")
    bottomNormalTex:SetAllPoints(bottomBtn)

    local bottomHoverTex = bottomBtn:CreateTexture(nil, "ARTWORK")
    bottomHoverTex:SetTexture(addonPath .. "images\\bottom_button_hover_new")
    bottomHoverTex:SetAllPoints(bottomBtn)
    bottomHoverTex:Hide()

    bottomBtn:SetScript("OnEnter", function() bottomHoverTex:Show() end)
    bottomBtn:SetScript("OnLeave", function() bottomHoverTex:Hide() end)
    bottomBtn:SetScript("OnMouseDown", function()
        PlaySound(808)
        if mainFrame.messageFrame then
            mainFrame.messageFrame:ScrollToBottom()
        end
    end)

    mainFrame.buttonPanel = buttonPanel

    DeckSuite_InitializeTabs()
    local tabPanel = DeckSuite_CreateTabPanel(mainFrame)
    mainFrame.tabPanel = tabPanel

    local messageFrame = CreateFrame("ScrollingMessageFrame", "DeckSuiteChatMessageFrame", mainFrame)
    messageFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 38, -8)
    messageFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -8, 8)
    messageFrame:SetFontObject(GameFontNormal)
    messageFrame:SetJustifyH("LEFT")
    messageFrame:SetMaxLines(500)
    messageFrame:SetFading(false)
    messageFrame:SetInsertMode("BOTTOM")

    messageFrame:SetHyperlinksEnabled(true)
    messageFrame:SetScript("OnHyperlinkClick", function(self, link, text, button)
        SetItemRef(link, text, button)
    end)
    messageFrame:SetScript("OnHyperlinkEnter", function(self, link, text)
        if link and not link:match("^player:") then
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:SetHyperlink(link)
            GameTooltip:Show()
        end
    end)
    messageFrame:SetScript("OnHyperlinkLeave", function(self)
        GameTooltip:Hide()
    end)

    local editBox = ChatFrame1EditBox
    if editBox then
        editBox:SetParent(mainFrame)
        editBox:ClearAllPoints()
        editBox:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 0, -26)
        editBox:SetSize(430, 25)
        editBox:EnableMouse(true)
    end

    mainFrame.messageFrame = messageFrame
    mainFrame.editBox = editBox
    _G.DeckSuiteMainChatFrame = mainFrame

    DeckSuite_UpdateChatFrameFontSize()

    DeckSuite_UpdateChatDisplay()
    DeckSuite_RegisterChatEvents()

    C_Timer.After(1, function()
        DeckSuite_RefreshTabs()
    end)
end

function DeckSuite_UpdateChatDisplay()
    if not DeckSuiteMainChatFrame then return end
    if not DeckSuiteCustomChat.tabsInitialized then return end

    local activeTab = DeckSuiteCustomChat.tabs[DeckSuiteCustomChat.activeTabIndex]
    if not activeTab then return end

    local messageFrame = DeckSuiteMainChatFrame.messageFrame

    for i = activeTab.lastDisplayedCount + 1, #activeTab.messages do
        local msg = activeTab.messages[i]
        messageFrame:AddMessage(msg.text, msg.r, msg.g, msg.b)
    end

    activeTab.lastDisplayedCount = #activeTab.messages
end

function DeckSuite_HandleLevelUp(...)
    local args = {...}
    local newLevel = args[1]
    local healthGain = args[2] or 0
    local manaGain = args[3] or 0
    local talentPoints = args[4] or 0
    local strengthGain = args[5] or 0
    local agilityGain = args[6] or 0
    local staminaGain = args[7] or 0
    local intellectGain = args[8] or 0
    local spiritGain = args[9] or 0

    local r, g, b = 1, 1, 0

    local messages = {}
    table.insert(messages, string.format("Congratulations, you have reached level %d!", newLevel))

    if healthGain > 0 and manaGain > 0 then
        table.insert(messages, string.format("You gain %d hit points and %d mana.", healthGain, manaGain))
    end

    if healthGain > 0 and manaGain == 0 then
        table.insert(messages, string.format("You gain %d hit points.", healthGain))
    end

    if manaGain > 0 and healthGain == 0 then
        table.insert(messages, string.format("You gain %d mana.", manaGain))
    end

    if strengthGain > 0 then
        table.insert(messages, string.format("You gain %d Strength.", strengthGain))
    end
    if agilityGain > 0 then
        table.insert(messages, string.format("You gain %d Agility.", agilityGain))
    end
    if staminaGain > 0 then
        table.insert(messages, string.format("You gain %d Stamina.", staminaGain))
    end
    if intellectGain > 0 then
        table.insert(messages, string.format("You gain %d Intellect.", intellectGain))
    end
    if spiritGain > 0 then
        table.insert(messages, string.format("You gain %d Spirit.", spiritGain))
    end

    if talentPoints > 0 then
        table.insert(messages, string.format("You have %d talent point%s available.", talentPoints, talentPoints > 1 and "s" or ""))
    end

    for _, tab in ipairs(DeckSuiteCustomChat.tabs) do
        for _, messageText in ipairs(messages) do
            local msg = {
                text = messageText,
                r = r,
                g = g,
                b = b
            }
            table.insert(tab.messages, msg)
        end

        while #tab.messages > DeckSuiteCustomChat.maxMessages do
            table.remove(tab.messages, 1)
        end
    end

    DeckSuite_UpdateChatDisplay()
end

function DeckSuite_RegisterChatEvents()
    local chatEventFrame = CreateFrame("Frame")

    local chatEvents = {
        "CHAT_MSG_SAY",
        "CHAT_MSG_YELL",
        "CHAT_MSG_EMOTE",
        "CHAT_MSG_TEXT_EMOTE",
        "CHAT_MSG_MONSTER_EMOTE",
        "CHAT_MSG_PET_INFO",
        "CHAT_MSG_PARTY",
        "CHAT_MSG_PARTY_LEADER",
        "CHAT_MSG_RAID",
        "CHAT_MSG_MONEY",
        "CHAT_MSG_RAID_LEADER",
        "CHAT_MSG_RAID_WARNING",
        "CHAT_MSG_GUILD",
        "CHAT_MSG_OFFICER",
        "CHAT_MSG_WHISPER",
        "CHAT_MSG_WHISPER_INFORM",
        "CHAT_MSG_CHANNEL",
        "CHAT_MSG_SYSTEM",
        "CHAT_MSG_COMBAT_XP_GAIN",
        "CHAT_MSG_COMBAT_HONOR_GAIN",
        "CHAT_MSG_COMBAT_MISC_INFO",
        "CHAT_MSG_SKILL",
        "CHAT_MSG_TRADESKILLS",
        "CHAT_MSG_ACHIEVEMENT",
        "CHAT_MSG_LOOT"
    }

    for _, event in ipairs(chatEvents) do
        chatEventFrame:RegisterEvent(event)
    end

    chatEventFrame:RegisterEvent("PLAYER_LEVEL_UP")

    chatEventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_LEVEL_UP" then
            DeckSuite_HandleLevelUp(...)
        else
            DeckSuite_HandleChatEvent(event, ...)
        end
    end)

    _G.DeckSuiteChatEventFrame = chatEventFrame
end

function DeckSuite_HandleChatEvent(event, ...)
    local args = {...}
    local message = args[1]
    local sender = args[2]
    local chatType = event:gsub("CHAT_MSG_", "")
    local originalChatType = chatType

    if chatType == "SKILL" then
        if message:find("increased to") then
            chatType = "SKILL_UP"
        else
            chatType = "SKILL_GAINED"
        end
    end

    local channelNum, channelName
    if chatType == "CHANNEL" then
        local channelString = args[4]
        channelNum = args[8]
        channelName = args[9]

        if not channelNum and channelString then
            channelNum = tonumber(channelString:match("^(%d+)%."))
        end

        if not channelName and channelString then
            channelName = channelString:match("^%d+%.%s*(.+)") or channelString
        end

        if channelNum then
            chatType = "CHANNEL" .. channelNum
        end
    end

    local color = CHAT_COLORS[chatType] or {1, 1, 1}
    local r, g, b = unpack(color)

    local senderGUID = args[12]
    local playerLink = sender
    if sender and sender ~= "" then
        local nameText = sender
        if senderGUID and senderGUID ~= "" then
            local _, englishClass = GetPlayerInfoByGUID(senderGUID)
            if englishClass then
                local classColor = RAID_CLASS_COLORS[englishClass]
                if classColor and classColor.colorStr then
                    nameText = "|c" .. classColor.colorStr .. sender .. "|r"
                end
            end
        end
        playerLink = "|Hplayer:" .. sender .. "|h" .. nameText .. "|h"
    else
        playerLink = "Unknown"
    end

    local formattedMessage = ""

    if chatType == "SAY" then
        formattedMessage = string.format("[%s]: %s", playerLink, message)
    elseif chatType == "YELL" then
        formattedMessage = string.format("[%s] yells: %s", playerLink, message)
    elseif chatType == "EMOTE" then
        formattedMessage = string.format("%s %s", playerLink, message)
    elseif chatType == "MONSTER_EMOTE" then
        formattedMessage = message
    elseif chatType == "TEXT_EMOTE" or chatType == "SKILL_UP" or chatType == "SKILL_GAINED"
        or chatType == "COMBAT_XP_GAIN" or chatType == "MONEY" or chatType == "TRADESKILLS"
        or chatType == "PET_INFO" or chatType == "COMBAT_HONOR_GAIN" or chatType == "COMBAT_MISC_INFO" then
            formattedMessage = message
    elseif chatType == "PARTY" or chatType == "PARTY_LEADER" then
        formattedMessage = string.format("[Party] [%s]: %s", playerLink, message)
    elseif chatType == "RAID" or chatType == "RAID_LEADER" then
        formattedMessage = string.format("[Raid] [%s]: %s", playerLink, message)
    elseif chatType == "GUILD" then
        formattedMessage = string.format("[Guild] [%s]: %s", playerLink, message)
    elseif chatType == "OFFICER" then
        formattedMessage = string.format("[Officer] [%s]: %s", playerLink, message)
    elseif chatType == "WHISPER" then
        formattedMessage = string.format("[%s] whispers: %s", playerLink, message)
    elseif chatType == "WHISPER_INFORM" then
        formattedMessage = string.format("To [%s]: %s", playerLink, message)
    elseif chatType:match("^CHANNEL") then
        formattedMessage = string.format("[%s. %s] [%s]: %s", channelNum, channelName or "Channel", playerLink, message)
    elseif chatType == "SYSTEM" then
        formattedMessage = message
    elseif chatType == "ACHIEVEMENT" then
        formattedMessage = message
    elseif chatType == "LOOT" then
        formattedMessage = message
    else
        formattedMessage = string.format("[%s]: %s", sender or "System", message)
    end

    DeckSuite_AddChatMessageToTabs(formattedMessage, r, g, b, originalChatType, channelNum, channelName)
end

function DeckSuite_HideDefaultChat()
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            chatFrame:SetAlpha(0)
            chatFrame:Hide()
            chatFrame:EnableMouse(false)
            chatFrame:SetMovable(false)
        end

        local tab = _G["ChatFrame" .. i .. "Tab"]
        if tab then
            tab:SetAlpha(0)
            tab:Hide()
            tab:EnableMouse(false)
        end

        local buttonFrame = _G["ChatFrame" .. i .. "ButtonFrame"]
        if buttonFrame then
            buttonFrame:SetAlpha(0)
            buttonFrame:Hide()
            buttonFrame:EnableMouse(false)
        end

        if i ~= 1 then
            local editBox = _G["ChatFrame" .. i .. "EditBox"]
            if editBox then
                editBox:SetAlpha(0)
                editBox:Hide()
                editBox:EnableMouse(false)
            end
        end
    end

    if ChatFrameMenuButton then
        ChatFrameMenuButton:SetAlpha(0)
        ChatFrameMenuButton:Hide()
        ChatFrameMenuButton:EnableMouse(false)
    end
    if ChatFrameChannelButton then
        ChatFrameChannelButton:SetAlpha(0)
        ChatFrameChannelButton:Hide()
        ChatFrameChannelButton:EnableMouse(false)
    end
    if _G.FriendsMicroButton then
        _G.FriendsMicroButton:SetAlpha(0)
        _G.FriendsMicroButton:Hide()
    end
    if _G.QuickJoinToastButton then
        _G.QuickJoinToastButton:SetAlpha(0)
        _G.QuickJoinToastButton:Hide()
    end

    if _G.GeneralDockManager then
        _G.GeneralDockManager:SetAlpha(0)
        _G.GeneralDockManager:Hide()
    end
end

function DeckSuite_HookChatOpening()
    local function RedirectToCustomChat(editBox, ...)
        if DeckSuiteMainChatFrame and DeckSuiteMainChatFrame.editBox then
            local text = editBox:GetText()

            editBox:Hide()
            editBox:ClearFocus()
            editBox:SetText("")

            DeckSuiteMainChatFrame.editBox:SetText("")
            DeckSuiteMainChatFrame.editBox:Show()
            DeckSuiteMainChatFrame.editBox:SetFocus()

            if text and text ~= "" then
                C_Timer.After(0.01, function()
                    if DeckSuiteMainChatFrame and DeckSuiteMainChatFrame.editBox then
                        DeckSuiteMainChatFrame.editBox:SetText(text)
                    end
                end)
            end
        end
    end

    for i = 1, NUM_CHAT_WINDOWS do
        local editBox = _G["ChatFrame" .. i .. "EditBox"]
        if editBox then
            editBox:HookScript("OnShow", RedirectToCustomChat)
            editBox:Hide()
        end
    end

    if ChatFrame_OpenChat then
        hooksecurefunc("ChatFrame_OpenChat", function(msg, chatFrame)
            if DeckSuiteMainChatFrame and DeckSuiteMainChatFrame.editBox then
                for i = 1, NUM_CHAT_WINDOWS do
                    local eb = _G["ChatFrame" .. i .. "EditBox"]
                    if eb then
                        eb:Hide()
                        eb:ClearFocus()
                    end
                end

                DeckSuiteMainChatFrame.editBox:SetText("")
                DeckSuiteMainChatFrame.editBox:SetFocus()

                if msg and msg ~= "" then
                    C_Timer.After(0.01, function()
                        if DeckSuiteMainChatFrame and DeckSuiteMainChatFrame.editBox then
                            DeckSuiteMainChatFrame.editBox:SetText(msg)
                            DeckSuite_DetectChannelFromMessage(msg)
                        end
                    end)
                end
            end
        end)
    end
end

function DeckSuite_SetupChatKeyBindings()
end
