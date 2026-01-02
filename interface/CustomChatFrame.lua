local CHAT_COLORS = {
    SAY = {1, 1, 1},
    YELL = {1, 0.25, 0.25},
    EMOTE = {1, 0.5, 0.25},
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
    CHANNEL1 = {1, 0.75, 0.75}, -- General
    CHANNEL2 = {1, 0.75, 0.75}, -- Trade
    CHANNEL3 = {1, 0.75, 0.75}, -- LocalDefense
    SYSTEM = {1, 1, 0},
    ACHIEVEMENT = {1, 1, 0},
    LOOT = {0, 0.67, 0}
}

local DeckSuiteCustomChat = {
    maxMessages = 500,
    messages = {},
    currentChannel = "SAY",
    currentChannelCommand = "/s "
}

function DeckSuite_CreateCustomChatFrame()
    if DeckSuiteMainChatFrame then return end

    local mainFrame = CreateFrame("Frame", "DeckSuiteMainChatFrame", UIParent, "BackdropTemplate")
    mainFrame:SetSize(500, 185)
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
    local buttonSize = 40
    local spacing = -4

    local newChatBtn = CreateFrame("Frame", "DeckSuiteCustomChatNewChatBtn", buttonPanel)
    newChatBtn:SetSize(buttonSize, buttonSize)
    newChatBtn:SetPoint("TOP", buttonPanel, "TOP", 0, 0)
    newChatBtn:EnableMouse(true)

    local chatNormalTex = newChatBtn:CreateTexture(nil, "BACKGROUND")
    chatNormalTex:SetTexture(addonPath .. "images\\new_chat_button")
    chatNormalTex:SetAllPoints(newChatBtn)

    local chatHoverTex = newChatBtn:CreateTexture(nil, "ARTWORK")
    chatHoverTex:SetTexture(addonPath .. "images\\new_chat_button_hover")
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
    replyNormalTex:SetTexture(addonPath .. "images\\reply_button")
    replyNormalTex:SetAllPoints(replyBtn)

    local replyHoverTex = replyBtn:CreateTexture(nil, "ARTWORK")
    replyHoverTex:SetTexture(addonPath .. "images\\reply_button_hover")
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

    local upBtn = CreateFrame("Button", "DeckSuiteCustomChatUpBtn", buttonPanel)
    upBtn:SetSize(buttonSize, buttonSize)
    upBtn:SetPoint("TOP", replyBtn, "BOTTOM", 0, -spacing)
    upBtn:SetNormalTexture(addonPath .. "images\\up_button")
    upBtn:SetPushedTexture(addonPath .. "images\\up_button")
    upBtn:SetHighlightTexture(addonPath .. "images\\up_button")
    upBtn:SetScript("OnClick", function()
        PlaySound(808)
        if mainFrame.messageFrame then
            mainFrame.messageFrame:ScrollUp()
            mainFrame.messageFrame:ScrollUp()
        end
    end)

    local downBtn = CreateFrame("Button", "DeckSuiteCustomChatDownBtn", buttonPanel)
    downBtn:SetSize(buttonSize, buttonSize)
    downBtn:SetPoint("TOP", upBtn, "BOTTOM", 0, -spacing)
    downBtn:SetNormalTexture(addonPath .. "images\\down_button")
    downBtn:SetPushedTexture(addonPath .. "images\\down_button")
    downBtn:SetHighlightTexture(addonPath .. "images\\down_button")
    downBtn:SetScript("OnClick", function()
        PlaySound(808)
        if mainFrame.messageFrame then
            mainFrame.messageFrame:ScrollDown()
            mainFrame.messageFrame:ScrollDown()
        end
    end)

    local bottomBtn = CreateFrame("Button", "DeckSuiteCustomChatBottomBtn", buttonPanel)
    bottomBtn:SetSize(buttonSize, buttonSize)
    bottomBtn:SetPoint("TOP", downBtn, "BOTTOM", 0, -spacing)
    bottomBtn:SetNormalTexture(addonPath .. "images\\bottom_button")
    bottomBtn:SetPushedTexture(addonPath .. "images\\bottom_button")
    bottomBtn:SetHighlightTexture(addonPath .. "images\\bottom_button")
    bottomBtn:SetScript("OnClick", function()
        PlaySound(808)
        if mainFrame.messageFrame then
            mainFrame.messageFrame:ScrollToBottom()
        end
    end)

    mainFrame.buttonPanel = buttonPanel

    local messageFrame = CreateFrame("ScrollingMessageFrame", "DeckSuiteChatMessageFrame", mainFrame)
    messageFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 8, -8)
    messageFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -8, 35)
    messageFrame:SetFontObject(GameFontNormalLarge)
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
        editBox:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 5, 8)
        editBox:SetSize(490, 25)
        editBox:EnableMouse(true)
    end

    mainFrame.messageFrame = messageFrame
    mainFrame.editBox = editBox
    _G.DeckSuiteMainChatFrame = mainFrame

    DeckSuite_UpdateChatDisplay()

    DeckSuite_RegisterChatEvents()
end

function DeckSuite_AddChatMessage(message, r, g, b)
    table.insert(DeckSuiteCustomChat.messages, {
        text = message,
        r = r or 1,
        g = g or 1,
        b = b or 1
    })

    while #DeckSuiteCustomChat.messages > DeckSuiteCustomChat.maxMessages do
        table.remove(DeckSuiteCustomChat.messages, 1)
    end

    DeckSuite_UpdateChatDisplay()
end

function DeckSuite_UpdateChatDisplay()
    if not DeckSuiteMainChatFrame then return end

    local messageFrame = DeckSuiteMainChatFrame.messageFrame

    if not DeckSuiteCustomChat.lastDisplayedCount then
        DeckSuiteCustomChat.lastDisplayedCount = 0
    end

    for i = DeckSuiteCustomChat.lastDisplayedCount + 1, #DeckSuiteCustomChat.messages do
        local msg = DeckSuiteCustomChat.messages[i]
        messageFrame:AddMessage(msg.text, msg.r, msg.g, msg.b)
    end

    DeckSuiteCustomChat.lastDisplayedCount = #DeckSuiteCustomChat.messages
end

function DeckSuite_SetChatChannel(channelName, channelCommand, r, g, b, displayName)
    DeckSuiteCustomChat.currentChannel = channelName
    DeckSuiteCustomChat.currentChannelCommand = channelCommand or ("/" .. string.lower(channelName) .. " ")

    if DeckSuiteMainChatFrame and DeckSuiteMainChatFrame.editBox then
        local newPrefix = "[" .. (displayName or channelName) .. "] "
        DeckSuiteCustomChat.currentPrefix = newPrefix

        DeckSuiteMainChatFrame.editBox:SetText(newPrefix)
        DeckSuiteMainChatFrame.editBox:SetCursorPosition(DeckSuiteMainChatFrame.editBox:GetNumLetters())
    end
end

function DeckSuite_RegisterChatEvents()
    local chatEventFrame = CreateFrame("Frame")

    local chatEvents = {
        "CHAT_MSG_SAY",
        "CHAT_MSG_YELL",
        "CHAT_MSG_EMOTE",
        "CHAT_MSG_TEXT_EMOTE",
        "CHAT_MSG_PARTY",
        "CHAT_MSG_PARTY_LEADER",
        "CHAT_MSG_RAID",
        "CHAT_MSG_RAID_LEADER",
        "CHAT_MSG_RAID_WARNING",
        "CHAT_MSG_GUILD",
        "CHAT_MSG_OFFICER",
        "CHAT_MSG_WHISPER",
        "CHAT_MSG_WHISPER_INFORM",
        "CHAT_MSG_CHANNEL",
        "CHAT_MSG_SYSTEM",
        "CHAT_MSG_ACHIEVEMENT",
        "CHAT_MSG_LOOT"
    }

    for _, event in ipairs(chatEvents) do
        chatEventFrame:RegisterEvent(event)
    end

    chatEventFrame:SetScript("OnEvent", function(self, event, ...)
        DeckSuite_HandleChatEvent(event, ...)
    end)

    _G.DeckSuiteChatEventFrame = chatEventFrame
end

function DeckSuite_HandleChatEvent(event, ...)
    local args = {...}
    local message = args[1]
    local sender = args[2]
    local chatType = event:gsub("CHAT_MSG_", "")

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

    local playerLink = sender
    if sender and sender ~= "" then
        playerLink = "|Hplayer:" .. sender .. "|h" .. sender .. "|h"
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
    elseif chatType == "TEXT_EMOTE" then
        formattedMessage = message
    elseif chatType == "PARTY" or chatType == "PARTY_LEADER" then
        formattedMessage = string.format("[Party][%s]: %s", playerLink, message)
    elseif chatType == "RAID" or chatType == "RAID_LEADER" then
        formattedMessage = string.format("[Raid][%s]: %s", playerLink, message)
    elseif chatType == "GUILD" then
        formattedMessage = string.format("[Guild][%s]: %s", playerLink, message)
    elseif chatType == "OFFICER" then
        formattedMessage = string.format("[Officer][%s]: %s", playerLink, message)
    elseif chatType == "WHISPER" then
        formattedMessage = string.format("[%s] whispers: %s", playerLink, message)
    elseif chatType == "WHISPER_INFORM" then
        formattedMessage = string.format("To [%s]: %s", playerLink, message)
    elseif chatType:match("^CHANNEL") then
        formattedMessage = string.format("[%s][%s]: %s", channelName or "Channel", playerLink, message)
    elseif chatType == "SYSTEM" then
        formattedMessage = message
    elseif chatType == "ACHIEVEMENT" then
        formattedMessage = message
    elseif chatType == "LOOT" then
        formattedMessage = message
    else
        formattedMessage = string.format("[%s]: %s", sender or "System", message)
    end

    DeckSuite_AddChatMessage(formattedMessage, r, g, b)
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

function DeckSuite_DetectChannelFromMessage(msg)
    if not msg then return end

    if msg:match("^/s ") or msg:match("^/say ") then
        DeckSuite_SetChatChannel("SAY", "/s ", 1, 1, 1)
    elseif msg:match("^/p ") or msg:match("^/party ") then
        DeckSuite_SetChatChannel("PARTY", "/p ", 0.67, 0.67, 1)
    elseif msg:match("^/raid ") then
        DeckSuite_SetChatChannel("RAID", "/raid ", 1, 0.5, 0)
    elseif msg:match("^/g ") or msg:match("^/guild ") then
        DeckSuite_SetChatChannel("GUILD", "/g ", 0.25, 1, 0.25)
    elseif msg:match("^/o ") or msg:match("^/officer ") then
        DeckSuite_SetChatChannel("OFFICER", "/o ", 0.25, 0.75, 0.25)
    elseif msg:match("^/w ") or msg:match("^/whisper ") then
        DeckSuite_SetChatChannel("WHISPER", "/w ", 1, 0.5, 1)
    elseif msg:match("^/y ") or msg:match("^/yell ") then
        DeckSuite_SetChatChannel("YELL", "/y ", 1, 0.25, 0.25)
    elseif msg:match("^/%d+") then
        -- Handle numbered channels (/1, /2, /3, etc.)
        local channelNum = msg:match("^/(%d+)")
        if channelNum then
            channelNum = tonumber(channelNum)

            local id, name = GetChannelName(channelNum)
            local displayName = name or ("Channel " .. channelNum)
            local fullChannelName = channelNum .. ". " .. displayName

            DeckSuiteCustomChat.currentChannelNum = channelNum
            DeckSuite_SetChatChannel("CHANNEL", "/" .. channelNum .. " ", 1, 0.75, 0.75, fullChannelName)
        end
    end
end

function DeckSuite_SetupChatKeyBindings()
end
