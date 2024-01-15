local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, eventName, ...)
    if eventName == "PLAYER_LOGIN" then
        ChatPlusDB = ChatPlusDB or {}
    end
end)