local _, PM = ...

local selectedLog
local selectedLogType

local frame = CreateFrame("Frame", "PMArchiveFrame", UIParent, "BasicFrameTemplate")
frame.TitleText:SetText("Archive")
frame:SetPoint("CENTER")
frame:SetSize(440, 424)
frame:EnableMouse(true)
frame:SetToplevel(true)
frame:Hide()

local inset = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
inset:SetPoint("TOPLEFT", PANEL_INSET_LEFT_OFFSET, -80)
inset:SetPoint("BOTTOMRIGHT", PANEL_INSET_RIGHT_OFFSET, PANEL_INSET_BOTTOM_OFFSET + 2)

local function onClick(self, target, chatType)
	PM:SelectArchive(target, chatType)
end

local menu = PM:CreateDropdown("Frame", frame)
menu:SetWidth(128)
menu:SetPoint("TOPLEFT", 0, -29)
menu:JustifyText("LEFT")
menu.initialize = function(self)
	for i, thread in ipairs(PM.db.threads) do
		if #thread.messages > 0 then
			local info = UIDropDownMenu_CreateInfo()
			info.text = Ambiguate(thread.target, "none")
			info.func = onClick
			info.arg1 = thread.target
			info.arg2 = thread.type
			info.checked = (selectedLog == thread.target)
			self:AddButton(info)
		end
	end
end

local archive = CreateFrame("ScrollFrame", "PMArchiveLog", inset, "UIPanelScrollFrameTemplate")
archive:SetPoint("TOPLEFT", 6, -6)
archive:SetPoint("BOTTOMRIGHT", -30, 6)

local archiveLog = CreateFrame("EditBox", nil, archive)
archiveLog:SetSize(archive:GetWidth(), archive:GetHeight())
archiveLog:SetFontObject(ChatFontNormal)
archiveLog:SetAutoFocus(false)
archiveLog:SetMultiLine(true)
-- archiveLog:SetIndentedWordWrap(true)
archiveLog:SetHyperlinksEnabled(true)
archiveLog:SetScript("OnHyperlinkClick", ChatFrame_OnHyperlinkShow)
archiveLog:SetScript("OnEscapePressed", archiveLog.ClearFocus)
archiveLog:SetScript("OnCursorChanged", function(self, x, y, width, height)
	if x == self.cursorX and y == self.cursorY then
		return
	end
	self.cursorX = x
	self.cursorY = y
	-- scroll to cursor
	y = abs(y)
	local scrollWindowHeight = archive:GetHeight()
	local scroll = archive:GetVerticalScroll()
	if (y + height > scroll + scrollWindowHeight) or (y < scroll) then
		archive:SetVerticalScroll(min(archive:GetVerticalScrollRange(), max(0, (y + height / 2) - (scrollWindowHeight / 2))))
	end
end)

local function printLog()
	local darken = 0.2
	local color = ChatTypeInfo[selectedLogType]
	local thread = PM:GetThread(selectedLog, selectedLogType)
	
	local target = selectedLog
	if selectedLogType == "WHISPER" then
		target = Ambiguate(target, "none")
		if thread.targetID then
			local localizedClass, englishClass, localizedRace, englishRace = GetPlayerInfoByGUID(thread.targetID)
			local color = englishClass and (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[englishClass]
			if color then
				target = format("|c%s%s|r", color.colorStr, target)
			end
		end
	end
	local text = ""
	for i, message in ipairs(thread.messages) do
		if message.messageType then
			local r, g, b = color.r, color.g, color.b
			local sender
			if message.messageType == "in" then
				sender = target
			else
				sender = "You"
				r, g, b = max(0, r - darken), max(0, g - darken), max(0, b - darken)
			end
			
			local time = date("*t", message.timestamp)
			local colorString = format("|cff%.2x%.2x%.2x", r * 255, g * 255, b * 255)
			
			text = text..format("\n|cffd0d0d0%s|r %s[%s%s]: %s|r", date("%H:%M", message.timestamp), colorString, sender, colorString, message.text)
			
			local nextMessage = thread.messages[i + 1]
			local nextTime = nextMessage and date("*t", nextMessage.timestamp)
			if nextMessage and (nextTime.yday ~= time.yday or nextTime.year ~= time.year) then
				text = text..format("\n  %s\n\n  %s", date("%Y-%m-%d", message.timestamp), date("%Y-%m-%d", nextMessage.timestamp))
			end
		end
	end
	text = text..format("\n  %s", date("%Y-%m-%d", thread.messages[#thread.messages].timestamp))
	archiveLog:SetText(strsub(text, 2))
end

archiveLog:SetScript("OnTextChanged", function(self, isUserInput)
	if isUserInput then
		printLog()
	end
end)

archive:SetScrollChild(archiveLog)



local searchPosition

local function tab(text)
	return gsub(text, ".", "\t")
end

local function search(text)
	local log = archiveLog:GetText()
	-- replace timestamp and sender names, leaving only the actual messages searchable
	log = gsub(log, "\n.-: ", tab)
	local start, stop = strfind(strlower(log), strlower(text), searchPosition, true)
	-- if match, start searching from this position next time
	if start then
		searchPosition = stop + 1
		archiveLog:HighlightText(start - 1, stop)
		archiveLog:SetCursorPosition(stop)
		return true
	end
end

local searchBox = PM:CreateEditbox(frame, true)
searchBox:SetWidth(128)
searchBox:SetPoint("TOPRIGHT", -16, -33)
searchBox:SetScript("OnTextChanged", function(self, isUserInput)
	if isUserInput then
		searchPosition = 1
		if search(self:GetText()) then
			self:SetTextColor(1, 1, 1)
		else
			self:SetTextColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
		end
	end
end)
searchBox:SetScript("OnEnterPressed", function(self)
	if not search(self:GetText()) then
		-- wrap around
		searchPosition = 1
		search(self:GetText())
	end
end)

local purgeButton = CreateFrame("Button", "PMArchivePurgeButton", frame, "UIMenuButtonStretchTemplate")
purgeButton:SetWidth(64)
purgeButton:SetPoint("LEFT", menu, "RIGHT", -4, 2)
purgeButton:SetText("Purge")
purgeButton:SetScript("OnClick", function(self)
	PM:CloseChat(selectedLog, selectedLogType)
	PM:DeleteThread(selectedLog, selectedLogType)
	archiveLog:SetText("")
	menu:SetText(nil)
end)

function PM:SelectArchive(target, chatType)
	selectedLog = target
	selectedLogType = chatType
	printLog()
	menu:SetText(Ambiguate(target, "none"))
	frame:Show()
end