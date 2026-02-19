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
	-- https://warcraft.wiki.gg/wiki/UI_escape_sequences

	local issecretvalue = issecretvalue

	local function Unescape(msg)
		-- Secret strings (12.0.0+) cannot be indexed; skip pattern stripping.
		-- string.format %s converts secrets to their display representation.
		if issecretvalue and issecretvalue(msg) then
			return string.format("%s", msg)
		end

		-- Remove textures, icons, and atlases
		msg = msg:gsub("{.-}", "")
		msg = msg:gsub("|T.-|t", "")
		msg = msg:gsub("|A.-|a", "")

		-- Remove embedded Kstrings (BNet names within larger messages)
		msg = msg:gsub("|K.-|k", "")

		-- Extract link display text: |Hdata|htext|h → text
		msg = msg:gsub("|H.-|h(.-)|h", "%1")

		-- Strip color codes separately for robust nested/sequential handling
		msg = msg:gsub("|cn[^:]+:", "")             -- Named colors (10.0+)
		msg = msg:gsub("|c%x%x%x%x%x%x%x%x", "")  -- Hex colors
		msg = msg:gsub("|r", "")                    -- Color reset

		-- Other escape sequences
		msg = msg:gsub("|W(.-)|w", "%1")            -- Word wrap hints
		msg = msg:gsub("|n", "\n")                  -- Newlines

		-- Clean up any remaining escape sequences
		msg = msg:gsub("|", "")

		msg = msg:trim()
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

                if msg then
                    msg = Unescape(msg)

					if msg and msg ~= "" then
                        return msg
                    end
                end
                i = i + 1
            end
        end
    end

	local function SetupButtons(chatFrame, isCombatLog)
        local anchorFrame = CreateFrame("Frame", nil, chatFrame)
        anchorFrame:SetPoint("TOPRIGHT", -10, 0)
        anchorFrame:SetSize(200, 28)
        anchorFrame:Show()

		local lastButton

		if not isCombatLog then
			local copyButton = CreateFrame("Button", nil, anchorFrame, "UIPanelButtonTemplate")
			copyButton:SetPoint("TOPRIGHT")
			copyButton:SetSize(70, 28)
			copyButton:SetText("Copy")

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

			lastButton = copyButton
		end

        local clearButton = CreateFrame("Button", nil, anchorFrame, "UIPanelButtonTemplate")
		clearButton:SetSize(70, 28)
		clearButton:SetText("Clear")

		if lastButton then
			clearButton:SetPoint("TOPRIGHT", lastButton, "TOPLEFT")
		else
			clearButton:SetPoint("TOPRIGHT")
		end

        clearButton:SetScript("OnClick", function()
			chatFrame:Clear()
		end)
	end

	local combatLog = COMBATLOG or ChatFrame2

	for i = 1, NUM_CHAT_WINDOWS do
		local chatFrame = _G["ChatFrame" .. i]
		if chatFrame then
			SetupButtons(chatFrame, chatFrame == combatLog)
		end
	end
end