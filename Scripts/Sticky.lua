local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

local function getChatWindowByName(name)
    for i = 1, NUM_CHAT_WINDOWS do
        local chatName = GetChatWindowInfo(i)
        if chatName == name then
            return _G["ChatFrame" .. i]
        end
    end
    return ChatFrame1
end

frame:SetScript("OnEvent", function(self, eventName, ...)
    if eventName == "PLAYER_LOGIN" then
        ChatPlusDB["StickyChatWindow"] = ChatPlusDB["StickyChatWindow"] or {
            ["LastWindow"] = GENERAL
        }
        for _, chatFrameName in pairs(CHAT_FRAMES) do
            local chatFrame = _G[chatFrameName]
            local chatFrameTab = _G[chatFrameName .. "Tab"]
            chatFrameTab:HookScript("OnClick", function()
                ChatPlusDB.StickyChatWindow.LastWindow = chatFrame.name
            end)
        end
    elseif eventName == "PLAYER_ENTERING_WORLD" then
        local chatFrame = getChatWindowByName(ChatPlusDB.StickyChatWindow.LastWindow)
        FCFDock_SelectWindow(GENERAL_CHAT_DOCK, chatFrame)
        FCF_DockUpdate()
    end
end)