-- Custom Chat Frame for DeckSuite
-- Positioned at top-left corner with full chat functionality

local CHAT_COLORS = {
    SAY = {1, 1, 1},
    YELL = {1, 0.25, 0.25},
    EMOTE = {1, 0.5, 0.25},
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

    -- Main chat container frame
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

    -- Use ScrollingMessageFrame for message display (handles its own scrolling)
    local messageFrame = CreateFrame("ScrollingMessageFrame", "DeckSuiteChatMessageFrame", mainFrame)
    messageFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 8, -8)
    messageFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -8, 35)
    messageFrame:SetFontObject(GameFontNormalLarge)
    messageFrame:SetJustifyH("LEFT")
    messageFrame:SetMaxLines(500)
    messageFrame:SetFading(false)
    messageFrame:SetInsertMode("BOTTOM")

    -- Enable hyperlink support
    messageFrame:SetHyperlinksEnabled(true)
    messageFrame:SetScript("OnHyperlinkClick", function(self, link, text, button)
        SetItemRef(link, text, button)
    end)
    messageFrame:SetScript("OnHyperlinkEnter", function(self, link, text)
        -- Only show tooltips for non-player links (items, achievements, etc.)
        if link and not link:match("^player:") then
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:SetHyperlink(link)
            GameTooltip:Show()
        end
    end)
    messageFrame:SetScript("OnHyperlinkLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Use the default chat edit box instead of creating a custom one
    local editBox = ChatFrame1EditBox
    if editBox then
        editBox:SetParent(mainFrame)
        editBox:ClearAllPoints()
        editBox:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 5, 8)
        editBox:SetSize(490, 25)
        editBox:EnableMouse(true)
    end

    -- Store references
    mainFrame.messageFrame = messageFrame
    mainFrame.editBox = editBox
    _G.DeckSuiteMainChatFrame = mainFrame

    -- Initialize message display
    DeckSuite_UpdateChatDisplay()

    -- Register chat events
    DeckSuite_RegisterChatEvents()
end

function DeckSuite_AddChatMessage(message, r, g, b)
    -- Add message to history
    table.insert(DeckSuiteCustomChat.messages, {
        text = message,
        r = r or 1,
        g = g or 1,
        b = b or 1
    })

    -- Limit message history
    while #DeckSuiteCustomChat.messages > DeckSuiteCustomChat.maxMessages do
        table.remove(DeckSuiteCustomChat.messages, 1)
    end

    -- Update display
    DeckSuite_UpdateChatDisplay()
end

function DeckSuite_UpdateChatDisplay()
    if not DeckSuiteMainChatFrame then return end

    local messageFrame = DeckSuiteMainChatFrame.messageFrame

    -- Clear existing messages and add all messages fresh
    -- ScrollingMessageFrame doesn't have a Clear method in Classic, so we'll track what's been added
    if not DeckSuiteCustomChat.lastDisplayedCount then
        DeckSuiteCustomChat.lastDisplayedCount = 0
    end

    -- Only add new messages since last update
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
        -- Use displayName if provided, otherwise use channelName
        local newPrefix = "[" .. (displayName or channelName) .. "] "
        DeckSuiteCustomChat.currentPrefix = newPrefix

        -- Update the edit box text with the new prefix
        DeckSuiteMainChatFrame.editBox:SetText(newPrefix)
        DeckSuiteMainChatFrame.editBox:SetCursorPosition(DeckSuiteMainChatFrame.editBox:GetNumLetters())
    end
end

function DeckSuite_RegisterChatEvents()
    local chatEventFrame = CreateFrame("Frame")

    -- Register all chat message events
    local chatEvents = {
        "CHAT_MSG_SAY",
        "CHAT_MSG_YELL",
        "CHAT_MSG_EMOTE",
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
    -- Store all arguments for later access
    local args = {...}
    local message = args[1]
    local sender = args[2]
    local chatType = event:gsub("CHAT_MSG_", "")

    -- For channel messages, get channel info
    local channelNum, channelName
    if chatType == "CHANNEL" then
        -- Different args positions: channelString, target, flags, unknown, channelNumber, channelName
        local channelString = args[4]  -- "1. General" format
        channelNum = args[8]           -- Channel number
        channelName = args[9]          -- Channel name

        -- Fallback: extract channel number from channelString if args[8] is nil
        if not channelNum and channelString then
            channelNum = tonumber(channelString:match("^(%d+)%."))
        end

        -- Fallback: extract channel name from channelString if args[9] is nil
        if not channelName and channelString then
            channelName = channelString:match("^%d+%.%s*(.+)") or channelString
        end

        -- Use channel number to get the right color
        if channelNum then
            chatType = "CHANNEL" .. channelNum
        end
    end

    -- Get color for this chat type
    local color = CHAT_COLORS[chatType] or {1, 1, 1}
    local r, g, b = unpack(color)

    -- Create clickable player name hyperlink
    local playerLink = sender
    if sender and sender ~= "" then
        playerLink = "|Hplayer:" .. sender .. "|h" .. sender .. "|h"
    else
        playerLink = "Unknown"
    end

    -- Format the message based on type
    local formattedMessage = ""

    if chatType == "SAY" then
        formattedMessage = string.format("[%s]: %s", playerLink, message)
    elseif chatType == "YELL" then
        formattedMessage = string.format("[%s] yells: %s", playerLink, message)
    elseif chatType == "EMOTE" then
        formattedMessage = string.format("%s %s", playerLink, message)
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

    -- Add to chat display
    DeckSuite_AddChatMessage(formattedMessage, r, g, b)
end

function DeckSuite_HideDefaultChat()
    -- Completely disable and hide the default chat frames
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            chatFrame:SetAlpha(0)
            chatFrame:Hide()
            chatFrame:EnableMouse(false)
            chatFrame:SetMovable(false)
            -- Don't unregister events - we need them for our custom chat
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

        -- Don't hide ChatFrame1's edit box - we're using it!
        if i ~= 1 then
            local editBox = _G["ChatFrame" .. i .. "EditBox"]
            if editBox then
                editBox:SetAlpha(0)
                editBox:Hide()
                editBox:EnableMouse(false)
            end
        end
    end

    -- Hide other chat UI elements
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

    -- Hide the GeneralDockManager (chat tab dock)
    if _G.GeneralDockManager then
        _G.GeneralDockManager:SetAlpha(0)
        _G.GeneralDockManager:Hide()
    end
end

-- Hook into default chat opening to redirect to custom chat
function DeckSuite_HookChatOpening()
    -- Hook the ChatEdit_OnShow function to redirect to our custom chat
    local function RedirectToCustomChat(editBox, ...)
        if DeckSuiteMainChatFrame and DeckSuiteMainChatFrame.editBox then
            -- Get text before hiding (if any)
            local text = editBox:GetText()

            -- Hide the default edit box
            editBox:Hide()
            editBox:ClearFocus()
            editBox:SetText("")

            -- Clear our custom edit box first
            DeckSuiteMainChatFrame.editBox:SetText("")

            -- Focus our custom edit box
            DeckSuiteMainChatFrame.editBox:Show()
            DeckSuiteMainChatFrame.editBox:SetFocus()

            -- If there's text being passed (like for /reply), set it after a tiny delay
            if text and text ~= "" then
                C_Timer.After(0.01, function()
                    if DeckSuiteMainChatFrame and DeckSuiteMainChatFrame.editBox then
                        DeckSuiteMainChatFrame.editBox:SetText(text)
                    end
                end)
            end
        end
    end

    -- Hook all chat frame edit boxes
    for i = 1, NUM_CHAT_WINDOWS do
        local editBox = _G["ChatFrame" .. i .. "EditBox"]
        if editBox then
            editBox:HookScript("OnShow", RedirectToCustomChat)
            -- Make sure it starts hidden
            editBox:Hide()
        end
    end

    -- Override the ChatFrame_OpenChat function
    if ChatFrame_OpenChat then
        hooksecurefunc("ChatFrame_OpenChat", function(msg, chatFrame)
            if DeckSuiteMainChatFrame and DeckSuiteMainChatFrame.editBox then
                -- Hide all default edit boxes
                for i = 1, NUM_CHAT_WINDOWS do
                    local eb = _G["ChatFrame" .. i .. "EditBox"]
                    if eb then
                        eb:Hide()
                        eb:ClearFocus()
                    end
                end

                -- Clear our edit box first to prevent double input
                DeckSuiteMainChatFrame.editBox:SetText("")

                -- Focus our custom edit box
                DeckSuiteMainChatFrame.editBox:SetFocus()

                -- Handle the message if provided (use a small delay to ensure clear happens first)
                if msg and msg ~= "" then
                    C_Timer.After(0.01, function()
                        if DeckSuiteMainChatFrame and DeckSuiteMainChatFrame.editBox then
                            DeckSuiteMainChatFrame.editBox:SetText(msg)
                            -- Detect channel from the message prefix
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

            -- Get channel name from WoW
            local id, name = GetChannelName(channelNum)
            local displayName = name or ("Channel " .. channelNum)

            -- Create full display like "1. General"
            local fullChannelName = channelNum .. ". " .. displayName

            -- Store the channel number for sending
            DeckSuiteCustomChat.currentChannelNum = channelNum
            DeckSuite_SetChatChannel("CHANNEL", "/" .. channelNum .. " ", 1, 0.75, 0.75, fullChannelName)
        end
    end
end

-- Key bindings for channel switching
function DeckSuite_SetupChatKeyBindings()
    -- Using default WoW chat edit box - no custom setup needed!
    -- The default edit box handles all channel switching, slash commands, etc.
end
