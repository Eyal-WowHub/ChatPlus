local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self)
    ChatPlusDB = ChatPlusDB or {}

    self:UnregisterEvent("PLAYER_LOGIN")
end)