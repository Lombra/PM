local addonName, PM = ...

local selectedLog
local selectedLogType

local f = CreateFrame("Frame", "PMArchiveFrame", UIParent, "ButtonFrameTemplate")
f.TitleText:SetText("Archive")
f:SetPoint("CENTER")
f:SetWidth(440)
f:Hide()
ButtonFrameTemplate_HideButtonBar(f)
ButtonFrameTemplate_HidePortrait(f)

local function onClick(self, target, chatType)
	PM:SelectArchive(target, chatType)
end

local menu = PM:CreateDropdown("Frame", f)
-- menu:SetWidth(128)
menu:SetPoint("TOPLEFT", 0, -29)
menu:JustifyText("LEFT")
menu.initialize = function(self)
	for i, thread in ipairs(PM.db.threads) do
		local info = UIDropDownMenu_CreateInfo()
		info.text = Ambiguate(thread.target, "none")
		info.func = onClick
		info.arg1 = thread.target
		info.arg2 = thread.type
		info.checked = selectedLog == thread.target
		self:AddButton(info)
	end
end

local stats = f:CreateFontString(nil, nil, "ChatFontSmall")
stats:SetPoint("BOTTOMLEFT", 8, 8)

local archive = CreateFrame("ScrollFrame", "PMArchiveLog", f, "UIPanelScrollFrameTemplate")
archive:SetPoint("TOPLEFT", f.Inset, 6, -6)
archive:SetPoint("BOTTOMRIGHT", f.Inset, -30, 6)
archive:SetPoint("CENTER")

local archiveLog = CreateFrame("EditBox", nil, archive)
archiveLog:SetSize(archive:GetWidth(), archive:GetHeight())
archiveLog:SetFontObject(ChatFontNormal)
archiveLog:SetAutoFocus(false)
archiveLog:SetMultiLine(true)
archiveLog:SetScript("OnEscapePressed", archiveLog.ClearFocus)

archiveLog:SetScript("OnCursorChanged", function(self, x, y, width, height)
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
	-- local color = HIGHLIGHT_FONT_COLOR
	-- local r, g, b = color.r, color.g, color.b
	local thread = PM:GetChat(selectedLog, selectedLogType)
	
	archiveLog:SetText("")
	for i, message in ipairs(thread.messages) do
		local r, g, b = color.r, color.g, color.b
		local sender
		if message.messageType == "in" then
			sender = selectedLog
			if selectedLogType == "WHISPER" and thread.targetID then
				local localizedClass, englishClass, localizedRace, englishRace, sex = GetPlayerInfoByGUID(thread.targetID)
				if englishClass then
					local color = RAID_CLASS_COLORS[englishClass]
					if color then
						sender = format("|c%s%s|r", color.colorStr, Ambiguate(sender, "none"))
						-- sender = Ambiguate(sender, "none")
					end
				end
			end
		else
			-- sender = "|cffffffffYou|r"
			sender = "You"
			r, g, b = r - darken, g - darken, b - darken
		end
		
		archiveLog:Insert(format("\n|cffd0d0d0%s|r |cff%.2x%.2x%.2x[%s|cff%.2x%.2x%.2x]: %s|r", date("%H:%M", message.timestamp), r * 255, g * 255, b * 255, sender, r * 255, g * 255, b * 255, message.text))
	end
end

archiveLog:SetScript("OnTextChanged", function(self, isUserInput)
	if isUserInput then
		printLog()
	end
end)

archive:SetScrollChild(archiveLog)

local searchPosition = 1

local function pipe(text)
	return gsub(text, ".", "\t")
end

local function search(text)
	local log = archiveLog:GetText()
	-- replace timestamp and sender names, leaving only the actual messages
	log = gsub(log, "\n.-: ", pipe)
	local start, stop = strfind(strlower(log), strlower(text), searchPosition, true)
	-- if match, start searching from this position next time
	if start then
		searchPosition = stop + 1
		archiveLog:HighlightText(start - 1, stop)
		archiveLog:SetCursorPosition(stop)
		return true
	end
end

local searchBox = PM:CreateEditbox(f, true)
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
		searchPosition = 1
		search(self:GetText())
	end
end)

local purgeButton = CreateFrame("Button", "PMArchivePurgeButton", f, "UIMenuButtonStretchTemplate")
purgeButton:SetWidth(64)
purgeButton:SetPoint("RIGHT", searchBox, "LEFT", -8, 0)
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
	-- archive:UpdateScrollChildRect()
	menu:SetText(Ambiguate(target, "none"))
end