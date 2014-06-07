local _, PM = ...

local frame = CreateFrame("Frame")
frame.name = "PM"
InterfaceOptions_AddCategory(frame)
PM.config = frame

local title = frame:CreateFontString(nil, nil, "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetPoint("RIGHT", -16, 0)
title:SetJustifyH("LEFT")
title:SetJustifyV("TOP")
title:SetText("PM")

local function onClick(self)
	local checked = self:GetChecked() ~= nil
	PlaySound(checked and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
	PM.db[self.setting] = checked
	if self.func then
		self:func(checked)
	end
end

local function newCheckButton(data)
	local btn = CreateFrame("CheckButton", nil, frame, "OptionsBaseCheckButtonTemplate")
	btn:SetPushedTextOffset(0, 0)
	btn:SetScript("OnClick", onClick)
	
	local text = btn:CreateFontString(nil, nil, "GameFontHighlight")
	text:SetPoint("LEFT", btn, "RIGHT", 0, 1)
	btn:SetFontString(text)
	
	return btn
end

local options = {
	{
		text = "Clear editbox focus on send",
		key = "clearEditboxFocusOnSend",
		-- tooltipText = "Shows on item tooltips which characters or guilds has the item",
	},
	{
		text = "Clear editbox on focus lost",
		key = "clearEditboxOnFocusLost",
		-- tooltipText = "Adds tooltip info only when any modifier key is pressed",
	},
	{
		text = "Editbox text per thread",
		key = "editboxTextPerThread",
		-- tooltipText = "Includes characters from other realms for Battle.net account bound items",
		func = function(self, value)
			if not value then
				for i, thread in ipairs(self.db.threads) do
					thread.editboxText = nil
				end
			end
		end,
	},
}

function PM:LoadSettings()
	for i, option in ipairs(options) do
		local button = newCheckButton()
		if i == 1 then
			button:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
		else
			button:SetPoint("TOP", options[i - 1].button, "BOTTOM", 0, -8)
		end
		button:SetText(option.text)
		button:SetChecked(self.db[option.key])
		button.setting = option.key
		button.tooltipText = option.tooltipText
		button.func = option.func
		option.button = button
	end
end

-- StaticPopupDialogs["VORTEX_DELETE_CHARACTER"] = {
	-- text = "Really delete data for |cffffd200%s - %s|r?",
	-- button1 = YES,
	-- button2 = NO,
	-- OnAccept = function(self, character)
		-- Vortex:DeleteCharacter(character)
	-- end,
	-- hideOnEscape = true,
-- }