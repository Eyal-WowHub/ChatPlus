---@diagnostic disable: undefined-field
local tconcat = table.concat
local tinsert = table.insert
local twipe = table.wipe

local editFrame = CreateFrame("ScrollFrame", nil, UIParent, "InputScrollFrameTemplate")
editFrame:SetPoint("CENTER")
editFrame:SetSize(600, 300)
editFrame.CharCount:Hide()
editFrame:Hide()

local editBox = editFrame.EditBox
editBox:SetMultiLine(true)
editBox:SetMaxLetters(99999)
editBox:EnableMouse(true)
editBox:SetAutoFocus(false)
editBox:SetFontObject(ChatFontNormal)
editBox:SetWidth(editFrame:GetWidth())
editBox:SetTextInsets(5, 20, 30, 20)
editBox:SetAllPoints()

local closeButton = CreateFrame("Button", nil, editFrame, "UIPanelCloseButton")
closeButton:SetFrameStrata("HIGH")
closeButton:SetPoint("TOPRIGHT", -20, -5)
closeButton:SetScript("OnClick", function(self)
	editBox:SetText("")
	editBox:ClearFocus()
	editFrame:Hide()
end)

local newestOnTopButton = CreateFrame("CheckButton", nil, editFrame, "UICheckButtonTemplate")
newestOnTopButton:SetFrameStrata("HIGH")
newestOnTopButton:SetPoint("TOPLEFT")
newestOnTopButton.Text:SetText("Newest On Top")

editBox:SetScript("OnEscapePressed", function(self)
	closeButton:Click()
end)

local prevText = ""
editBox:SetScript("OnTextChanged", function(self)
	self:SetText(prevText)
	self:SetCursorPosition(0)
	self:SetFocus()
	self:HighlightText()
end)

do
	-- https://wowwiki.fandom.com/wiki/UI_escape_sequences
	
	local patterns = {
		"{.-}",                             -- Icons
		"|T.-|t",                           -- Textures
		"|c%x%x%x%x%x%x%x%x(.-)|r",         -- Colors
		"|c%x%x%x%x%x%x%x%x|H.-|h(.-)|h",   -- Links
		"|H.-|h(.-)|h",                     -- Links
		"|K.-|k",                           -- Battle.Net
		-- review: Might want to escape pipes only in debug mode but we'll see.
		"\124"                              -- Pipe
	}

	local replacements = {
		"",                                 -- Icons
		"",                                 -- Textures
		"%1",                               -- Colors
		"%1",                               -- Links
		"%1",                               -- Links
		"BNPlayer",                         -- Battle.Net
		"%0%0"                              -- Pipe
	}

	local function Unescape(msg)
		for index = 1, #patterns do
			local pattern = patterns[index]
			local replacement = replacements[index]
			msg = msg:gsub(pattern, replacement)
		end
		msg = msg:trim()
		msg = msg:trim("")
		return msg
	end

    local function IterableMessages(chatFrame, reverse)
        local n = chatFrame:GetNumMessages()
        local i, index = 0, nil
        return function()
            i = i + 1
            while i <= n do
                index = reverse and n - i + 1 or i
                local msg = chatFrame:GetMessageInfo(index)
                msg = Unescape(msg)
                if msg ~= "" then
                    return msg
                end
                i = i + 1
            end
        end
    end

	local function SetupButtons(chatFrame)
        local anchorFrame = CreateFrame("Frame", nil, chatFrame)
        anchorFrame:SetPoint("TOPRIGHT", 0, 0)
        anchorFrame:SetSize(200, 28)
        anchorFrame:Show()

		local copyButton = CreateFrame("Button", nil, anchorFrame, "UIPanelButtonTemplate")
		copyButton:SetPoint("TOPRIGHT")
		copyButton:SetSize(70, 28)
		copyButton:SetText("Copy")
        
        local clearButton = CreateFrame("Button", nil, anchorFrame, "UIPanelButtonTemplate")
		clearButton:SetPoint("TOPRIGHT", copyButton, "TOPLEFT")
		clearButton:SetSize(70, 28)
		clearButton:SetText("Clear")

		copyButton:SetScript("OnClick", function(self)
			editBox:SetText("")

			if not chatFrame.lines then
				chatFrame.lines = {}
			else
				twipe(chatFrame.lines)
			end

			local lines = chatFrame.lines

            for msg in IterableMessages(chatFrame, newestOnTopButton:GetChecked()) do
                tinsert(lines, msg)
            end
			
			prevText = tconcat(lines, "\n")

            editBox:SetText(prevText)
			editFrame:Show()
		end)

        copyButton:SetScript("OnLeave", function()
            anchorFrame:Hide()
        end)

        clearButton:SetScript("OnClick", function()
			chatFrame:Clear()
		end)

        clearButton:SetScript("OnLeave", function()
            anchorFrame:Hide()
        end)

		chatFrame:SetScript("OnEnter", function()
            anchorFrame:Show()
        end)

		chatFrame:SetScript("OnLeave", function()
            local obj = GetMouseFocus()
            if obj and obj == chatFrame then
                anchorFrame:Hide()
            end
        end)
	end

	for i = 1, NUM_CHAT_WINDOWS do
		local chatFrame = _G["ChatFrame" .. i]
		if chatFrame then
			SetupButtons(chatFrame)
		end
	end
end