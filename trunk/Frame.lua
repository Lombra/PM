local addonName, PM = ...


local playerFactionGroup = UnitFactionGroup("player")

local reverseclassnames = {}
for k,v in pairs(LOCALIZED_CLASS_NAMES_MALE) do reverseclassnames[v] = k end
for k,v in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do reverseclassnames[v] = k end

local threadListItems = {}

local frame = CreateFrame("Frame", "PMFrame", UIParent, "BasicFrameTemplate")
frame.TitleText:SetText("PM")
frame:SetToplevel(true)
frame:EnableMouse(true)
frame:SetMovable(true)
frame:SetDontSavePosition(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	PM.db.point, PM.db.x, PM.db.y = select(3, self:GetPoint())
end)
frame:SetScript("OnShow", function(self)
	PM:GetSelectedThread().unread = nil
	PM:UpdateThreadList()
	PM.db.shown = true
end)
frame:SetScript("OnHide", function(self)
	self:StopMovingOrSizing()
	PM.db.point, PM.db.x, PM.db.y = select(3, self:GetPoint())
	PM.db.shown = nil
end)


local insetLeft = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
insetLeft:SetPoint("TOPLEFT", PANEL_INSET_LEFT_OFFSET, PANEL_INSET_TOP_OFFSET)
insetLeft:SetPoint("BOTTOM", 0, PANEL_INSET_BOTTOM_OFFSET + 2)
PM.threadListInset = insetLeft


local function onClick(self)
	local target, type = self.target, self.type
	if not PM:IsThreadActive(target, type) then
		PM:CreateThread(target, type)
	end
	PM:SelectThread(target, type)
end

local function onEnter(self)
	if PM:IsThreadActive(self.target, self.type) then
		self.close:Show()
		self.icon:Hide()
		self.flash:Stop()
		self.text:SetPoint("RIGHT", self.icon, "LEFT", -2, 0)
	end
end

local function onLeave(self)
	if PM:IsThreadActive(self.target, self.type) and not self.close:IsMouseOver() then
		self.close:Hide()
		local thread = PM:GetThread(self.target, self.type)
		if not self.selected then
			self:UnlockHighlight()
			if thread.unread then
				self.flash:Play()
			end
		end
		if self.type == "BN_WHISPER" then
			self.icon:Show()
		else
			self.text:SetPoint("RIGHT", -2, 0)
		end
	end
end

local closeScripts = {
	OnEnter = function(self)
		self:SetAlpha(1.0)
		self.parent:LockHighlight()
	end,
	OnLeave = function(self)
		self:SetAlpha(0.5)
		if not self.parent:IsMouseOver() then
			onLeave(self.parent)
		end
	end,
	OnClick = function(self)
		PM:CloseChat(self.parent.target, self.parent.type)
	end,
	OnMouseDown = function(self)
		self.texture:SetPoint("CENTER", 1, -1)
	end,
	OnMouseUp = function(self)
		self.texture:SetPoint("CENTER", 0, 0)
	end,
}

local function setButtonStatus(button, showStatus, isOnline, isAFK, isDND)
	button.status:SetShown(showStatus)
	button.shadow:SetShown(showStatus)
	if showStatus then
		if isAFK then
			button.status:SetVertexColor(1, 0.5, 0)
		elseif isDND then
			button.status:SetVertexColor(1, 0, 0)
		elseif isOnline then
			button.status:SetVertexColor(0, 1, 0)
		else
			button.status:SetVertexColor(0.2, 0.2, 0.2)
		end
	end
end

local scrollFrame = PM:CreateScrollFrame("Hybrid", insetLeft)
PM.scroll = scrollFrame
local separator = scrollFrame:CreateTexture()
separator:SetTexture([[Interface\FriendsFrame\UI-FriendsFrame-OnlineDivider]])
separator:SetTexCoord(0, 1, 3/16, 0.75)
scrollFrame:SetPoint("TOPRIGHT", -4, -4)
scrollFrame:SetPoint("BOTTOMLEFT", 4, 4)
scrollFrame:SetButtonHeight(16)
scrollFrame:SetHeaderHeight(9)
scrollFrame.update = function(self)
	self = scrollFrame
	separator:Hide()
	
	local offset = self:GetOffset()
	
	for line = 1, #self.buttons do
		local button = self.buttons[line]
		local lineplusoffset = line + offset
		local object = threadListItems[lineplusoffset]
		if object then
			if object.separator then
				button:SetHeader()
				button.text:SetText(nil)
				button.close:Hide()
				button.icon:Hide()
				button.status:Hide()
				button.shadow:Hide()
				button.flash:Stop()
				separator:SetAllPoints(button)
				separator:Show()
			else
				button:ResetHeight()
			end
			button:SetEnabled(not object.separator)
			button.text:SetPoint("RIGHT", -2, 0)
			
			if not object.separator then
				local thread = PM:GetThread(object.target, object.type)
				
				local selectedThread = PM:GetSelectedThread()
				if selectedThread and thread == selectedThread then
					button:LockHighlight()
					button.selected = true
				else
					button:UnlockHighlight()
					button.selected = nil
				end
				
				if PM:IsThreadActive(object.target, object.type) then
					if (thread.unread and thread ~= selectedThread) and not (button:IsMouseOver() or button.close:IsMouseOver()) then
						if not button.flash:IsPlaying() then
							button.flash:Play()
						end
					elseif button.flash:IsPlaying() then
						button.flash:Stop()
					end
				else
					button.close:Hide()
				end
				
				if object.type == "WHISPER" then
					local name = Ambiguate(object.target, "none")
					local isFriend, connected, status = PM:GetFriendInfo(name)
					button.text:SetText(name)
					button.icon:Hide()
					setButtonStatus(button, isFriend, connected, status == CHAT_FLAG_AFK, status == CHAT_FLAG_DND)
				end
				
				if object.type == "BN_WHISPER" then
					local presenceID = object.target and BNet_GetPresenceID(object.target)
					if presenceID then
						local presenceID, presenceName, battleTag, isBattleTagPresence, _, _, client, isOnline, _, isAFK, isDND = BNGetFriendInfoByID(presenceID)
						button.text:SetText(object.target or UNKNOWN)
						button.icon:Show()
						button.icon:SetTexture(BNet_GetClientTexture(client))
						button.text:SetPoint("RIGHT", button.icon, "LEFT", -2, 0)
						setButtonStatus(button, true, isOnline, isAFK, isDND)
					end
				end
				
				-- button.active = true
				button.target = object.target
				button.type = object.type
				if button:IsMouseOver() then
					if PM:IsThreadActive(object.target, object.type) then
						button.icon:Hide()
						button.text:SetPoint("RIGHT", button.icon, "LEFT", -2, 0)
					end
				end
			end
		end
		button:SetShown(object ~= nil)
	end
	
	HybridScrollFrame_Update(self, (#threadListItems - 1) * self.buttonHeight + self.headerHeight, #self.buttons * self.buttonHeight)
end
scrollFrame.createButton = function(self)
	local button = CreateFrame("Button", nil, self.scrollChild)
	button:SetPoint("RIGHT")
	button:SetScript("OnClick", onClick)
	button:SetScript("OnEnter", onEnter)
	button:SetScript("OnLeave", onLeave)
	
	button:SetHighlightTexture([[Interface\Buttons\UI-Listbox-Highlight2]])
	button:GetHighlightTexture():SetVertexColor(0.196, 0.388, 0.8)
	
	button.shadow = button:CreateTexture(nil, "BACKGROUND")
	button.shadow:SetSize(16, 16)
	button.shadow:SetPoint("LEFT")
	button.shadow:SetTexture([[Interface\AddOns\PM\StatusBackground]])
	button.shadow:SetBlendMode("MOD")
	
	button.status = button:CreateTexture()
	button.status:SetSize(16, 16)
	button.status:SetPoint("LEFT")
	button.status:SetTexture([[Interface\AddOns\PM\Untitled-2]])
	
	button.text = button:CreateFontString(nil, nil, "GameFontHighlightSmall")
	button.text:SetPoint("LEFT", button.status, "RIGHT")
	button.text:SetJustifyH("LEFT")
	
	button.icon = button:CreateTexture()
	button.icon:SetSize(16, 16)
	button.icon:SetPoint("RIGHT", -2, 0)
	
	button.close = CreateFrame("Button", nil, button)
	button.close:SetSize(16, 16)
	button.close:SetPoint("RIGHT", -2, 0)
	button.close:SetAlpha(0.5)
	button.close:Hide()
	button.close.parent = button
	
	button.close.texture = button.close:CreateTexture()
	button.close.texture:SetSize(16, 16)
	button.close.texture:SetPoint("CENTER")
	button.close.texture:SetTexture([[Interface\FriendsFrame\ClearBroadcastIcon]])
	
	for script, handler in pairs(closeScripts) do
		button.close:SetScript(script, handler)
	end
	
	local flash = button:CreateTexture()
	flash:SetAllPoints()
	flash:SetTexture([[Interface\Buttons\UI-Listbox-Highlight2]])
	flash:SetVertexColor(0.196, 0.388, 0.8)
	flash:SetAlpha(0)
	
	button.flash = flash:CreateAnimationGroup()
	button.flash:SetLooping("BOUNCE")
	
	local fade = button.flash:CreateAnimation("Alpha")
	fade:SetChange(1)
	fade:SetDuration(0.8)
	fade:SetSmoothing("OUT")
	
	return button
end


local infoPanel = CreateFrame("Frame", nil, frame)
infoPanel:SetPoint("LEFT", insetLeft, "RIGHT", PANEL_INSET_LEFT_OFFSET, 0)
infoPanel:SetPoint("TOPRIGHT", PANEL_INSET_RIGHT_OFFSET, PANEL_INSET_TOP_OFFSET)
infoPanel:SetHeight(32)
infoPanel:EnableMouse(true)
infoPanel:SetScript("OnEnter", function(self)
	local thread = PM:GetSelectedThread()
	
	if thread.type ~= "BN_WHISPER" then return end
	
	local presenceID, presenceName, battleTag, isBattleTagPresence, toonName, toonID, client, isOnline, lastOnline, isAFK, isDND, broadcastText, noteText, _, broadcastTime = BNGetFriendInfoByID(thread.targetID)
	
	if not isOnline then return end
	
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:AddLine(presenceName, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
	-- GameTooltip:AddLine(battleTag)
	GameTooltip:AddLine(broadcastText, BATTLENET_FONT_COLOR.r, BATTLENET_FONT_COLOR.g, BATTLENET_FONT_COLOR.b, true)
	GameTooltip:AddLine(noteText)
	
	local _, toonName, _, realmName, realmID, faction, race, class, _, zoneName, level, gameText = BNGetToonInfo(toonID)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(client)
	if client == BNET_CLIENT_WOW then
		local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[reverseclassnames[class]]
		GameTooltip:AddLine(toonName, color.r, color.g, color.b)
		GameTooltip:AddLine(format(TOOLTIP_UNIT_LEVEL_RACE_CLASS, level, race, class))
		GameTooltip:AddLine(zoneName)
		GameTooltip:AddLine(realmName)
		GameTooltip:AddLine(faction)
	else
		GameTooltip:AddLine(toonName)
		GameTooltip:AddLine(gameText)
	end
	local friendIndex = BNGetFriendIndex(thread.targetID)
	for toonIndex = 1, BNGetNumFriendToons(friendIndex) do
		local hasFocus, toonName, client, realmName, realmID, faction, race, class, guild, zoneName, level, gameText = BNGetFriendToonInfo(friendIndex, toonIndex)
		if not hasFocus then
			GameTooltip:AddLine(" ")
			if client == BNET_CLIENT_WOW then
				GameTooltip:AddLine(format(TOOLTIP_UNIT_LEVEL_RACE_CLASS, level, race, class))
				GameTooltip:AddLine(realmName)
				GameTooltip:AddLine(faction)
				GameTooltip:AddLine(zoneName)
			else
				GameTooltip:AddLine(client)
				GameTooltip:AddLine(toonName)
				GameTooltip:AddLine(gameText)
			end
		end
	end
	
	GameTooltip:Show()
end)
infoPanel:SetScript("OnLeave", GameTooltip_Hide)

infoPanel.icon = infoPanel:CreateTexture()
infoPanel.icon:SetSize(24, 24)
infoPanel.icon:SetPoint("LEFT", 4, 0)

infoPanel.target = infoPanel:CreateFontString(nil, nil, "GameFontHighlightLarge")
infoPanel.target:SetPoint("TOPLEFT", infoPanel.icon, "TOPRIGHT", 8, 1)

infoPanel.toon = infoPanel:CreateFontString(nil, nil, "GameFontHighlightSmall")
infoPanel.toon:SetPoint("BOTTOMLEFT", infoPanel.icon, "BOTTOMRIGHT", 8, -1)

local function createConversation(self, target)
	BNConversationInvite_NewConversation(BNet_GetPresenceID(target))
end

local function invite(self, target)
	InviteUnit(Ambiguate(target, "none"))
end

local function inviteBNet(self, target)
	BNInviteFriend(target)
end

-- local urlFormat = "http://%s.battle.net/wow/%s/character/%s/%s/advanced"

-- local REGION = strlower(GetCVar("portal"))
-- GetLocale()

-- local function bnetProfile(self, target, chatType)
	-- local name, realm = strsplit("-", target)
	-- local url = format(urlFormat, REGION, "en", realm:gsub("(%l)(%U)", "%1-%2"):gsub(), name)
	-- StaticPopup_Show("SHOW_URL", url:match("^%l+://([^/]+)"):gsub("^www%.", ""), nil, url)
-- end

local function ignore(self, target)
	AddOrDelIgnore(Ambiguate(target, "none"))
end

local function viewFriends(self, target)
	FriendsFriendsFrame_Show(BNet_GetPresenceID(target))
end

local function openArchive(self, target, chatType)
	PM:SelectArchive(target, chatType)
end

local menuButton = CreateFrame("Button", nil, infoPanel)
menuButton:SetNormalTexture([[Interface\ChatFrame\UI-ChatIcon-ScrollDown-Up]])
menuButton:SetPushedTexture([[Interface\ChatFrame\UI-ChatIcon-ScrollDown-Down]])
menuButton:SetDisabledTexture([[Interface\ChatFrame\UI-ChatIcon-ScrollDown-Disabled]])
menuButton:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]])
menuButton:SetSize(32, 32)
menuButton:SetPoint("RIGHT")
menuButton:SetScript("OnClick", function(self)
	self.menu:Toggle(PM:GetSelectedThread())
end)

menuButton.menu = PM:CreateDropdown("Menu")
menuButton.menu.relativeTo = menuButton
menuButton.menu.xOffset = 0
menuButton.menu.yOffset = 0
menuButton.menu.initialize = function(self, level)
	if level == 1 then
		local thread = UIDROPDOWNMENU_MENU_VALUE
		
		if thread.type == "BN_WHISPER" then
			local info = UIDropDownMenu_CreateInfo()
			info.text = CREATE_CONVERSATION_WITH
			info.func = createConversation
			info.arg1 = thread.target
			info.arg2 = thread.type
			info.notCheckable = true
			self:AddButton(info, level)
		end
		
		local info = UIDropDownMenu_CreateInfo()
		info.text = INVITE
		info.value = thread.target
		if thread.type == "WHISPER" then
			info.func = invite
			info.arg1 = thread.target
		else
			-- if more than 1 invitable toon, then make a submenu here, otherwise invite directly
			local index = BNGetFriendIndex(thread.targetID)
			local numToons = BNGetNumFriendToons(index)
			if numToons > 1 then
				local numValidToons = 0
				local lastToonID
				for i = 1, numToons do
					local _, _, client, _, realmID, faction, _, _, _, _, _, _, _, _, _, toonID = BNGetFriendToonInfo(index, i)
					if client == BNET_CLIENT_WOW and faction == playerFactionGroup and realmID ~= 0 then
						numValidToons = numValidToons + 1
						lastToonID = toonID
					end
				end
				if numValidToons > 1 then
					info.hasArrow = true
				elseif numValidToons == 1 then
					info.func = inviteBNet
					info.arg1 = lastToonID
				else
					info.disabled = true
				end
			else
				local _, _, _, _, _, toonID = BNGetFriendInfo(index)
				local _, _, client, _, realmID, faction = BNGetToonInfo(thread.targetID)
				if client == BNET_CLIENT_WOW and faction == playerFactionGroup and realmID ~= 0 then
					info.func = inviteBNet
					info.arg1 = toonID
				else
					info.disabled = true
				end
			end
		end
		info.notCheckable = true
		self:AddButton(info, level)
		
		if thread.type == "WHISPER" then
			local info = UIDropDownMenu_CreateInfo()
			info.text = IGNORE
			info.func = ignore
			info.arg1 = thread.target
			info.arg2 = thread.type
			info.notCheckable = true
			self:AddButton(info, level)
		end
		
		if thread.type == "BN_WHISPER" then
			local info = UIDropDownMenu_CreateInfo()
			info.text = VIEW_FRIENDS_OF_FRIENDS
			info.func = viewFriends
			info.arg1 = thread.target
			info.arg2 = thread.type
			info.notCheckable = true
			self:AddButton(info, level)
		end
		
		local info = UIDropDownMenu_CreateInfo()
		info.text = "View archive"
		info.func = openArchive
		info.arg1 = thread.target
		info.arg2 = thread.type
		info.disabled = (#thread.messages == 0)
		info.notCheckable = true
		self:AddButton(info, level)
		
		-- if thread.type == "WHISPER" then
			-- local info = UIDropDownMenu_CreateInfo()
			-- info.text = "Battle.net profile"
			-- info.func = bnetProfile
			-- info.arg1 = thread.target
			-- info.notCheckable = true
			-- self:AddButton(info, level)
		-- end
	end
	if level == 2 then
		-- LE_PARTY_CATEGORY_HOME
		-- list all invitable toons
		local index = BNGetFriendIndex(BNet_GetPresenceID(UIDROPDOWNMENU_MENU_VALUE))
		for i = 1, BNGetNumFriendToons(index) do
			local _, toonName, client, _, realmID, faction, _, _, _, _, _, _, _, _, _, toonID = BNGetFriendToonInfo(index, i)
			if client == BNET_CLIENT_WOW and faction == playerFactionGroup and realmID ~= 0 then
				local info = UIDropDownMenu_CreateInfo()
				info.text = toonName
				info.func = inviteBNet
				info.arg1 = toonID
				info.notCheckable = true
				self:AddButton(info, level)
			end
		end
	end
end


local editbox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
PM.editbox = editbox
editbox:SetHeight(20)
editbox:SetPoint("LEFT", insetLeft, "RIGHT", 9, 0)
editbox:SetPoint("BOTTOMRIGHT", -6, 5)
editbox:SetFontObject("ChatFontSmall")
editbox:SetAutoFocus(false)
editbox:SetScript("OnEnterPressed", function(self)
	local type = self:GetAttribute("chatType")
	local text = self:GetText()
	if string.find(text, "%s*[^%s]+") then
		-- translate group tags into non localised tags
		text = SubstituteChatMessageBeforeSend(text)
		if type == "WHISPER" then
			local target = self:GetAttribute("tellTarget")
			ChatEdit_SetLastToldTarget(target, type)
			SendChatMessage(text, type, editbox.languageID, target)
		elseif type == "BN_WHISPER" then
			local target = self:GetAttribute("tellTarget")
			local presenceID = BNet_GetPresenceID(target)
			if presenceID then
				ChatEdit_SetLastToldTarget(target, type)
				BNSendWhisper(presenceID, text)
			else
				local info = ChatTypeInfo["SYSTEM"]
				self.chatFrame:AddMessage(format(BN_UNABLE_TO_RESOLVE_NAME, target), info.r, info.g, info.b)
			end
		-- elseif type == "BN_CONVERSATION" then
			-- local target = tonumber(editbox:GetAttribute("channelTarget"))
			-- BNSendConversationMessage(target, text);
		end
		if addHistory then
			editbox:AddHistoryLine(text)
		end
	end
	self:SetText("")
	PM:GetSelectedThread().editboxText = nil
	if PM.db.clearEditboxFocusOnSend then
		self:ClearFocus()
	end
end)
editbox:SetScript("OnEscapePressed", editbox.ClearFocus)
editbox:SetScript("OnTabPressed", function(self)
	-- local nextTell, nextTellType = ChatEdit_GetNextTellTarget(self:GetAttribute("tellTarget"), self:GetAttribute("chatType"))
	-- PM:SelectThread(nextTell, nextTellType)
	for i, thread in ipairs(PM.db.activeThreads) do
		if thread.target == self:GetAttribute("tellTarget") and thread.type == self:GetAttribute("chatType") then
			if IsShiftKeyDown() then i = i - 2 end
			local nextThread = PM.db.activeThreads[i % #PM.db.activeThreads + 1]
			PM:SelectThread(nextThread.target, nextThread.type)
			break
		end
	end
end)
editbox:SetScript("OnEditFocusGained", function(self)
	ACTIVE_CHAT_EDIT_BOX = self
	frame:Raise()
end)
editbox:SetScript("OnEditFocusLost", function(self)
	ACTIVE_CHAT_EDIT_BOX = nil
	if PM.db.clearEditboxOnFocusLost then
		self:SetText("")
	end
end)
editbox:SetScript("OnTextChanged", function(self, isUserInput)
	if isUserInput and PM.db.editboxTextPerThread then
		PM:GetSelectedThread().editboxText = self:GetText()
	end
end)
editbox:SetScript("OnUpdate", function(self)
	if self.setText then
		self:SetText("")
		self.setText = nil
	end
end)


local chatLogInset = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
chatLogInset:SetPoint("TOP", infoPanel, "BOTTOM", 0, 0)
chatLogInset:SetPoint("RIGHT", PANEL_INSET_RIGHT_OFFSET, 0)
chatLogInset:SetPoint("LEFT", insetLeft, "RIGHT", PANEL_INSET_LEFT_OFFSET, 0)
chatLogInset:SetPoint("BOTTOM", editbox, "TOP", 0, 4)

local linkTypes = {
	achievement = true,
	enchant = true,
	glyph = true,
	instancelock = true,
	item = true,
	quest = true,
	spell = true,
	talent = true,
}

local chatLog = CreateFrame("ScrollingMessageFrame", nil, chatLogInset)
PM.chatLog = chatLog
chatLog:SetPoint("TOPRIGHT", -6, -6)
chatLog:SetPoint("BOTTOMLEFT", 6, 5)
chatLog:SetMaxLines(256)
chatLog:SetJustifyH("LEFT")
chatLog:SetFading(false)
chatLog:SetIndentedWordWrap(true)
-- chatLog:SetToplevel(true)
chatLog:SetScript("OnHyperlinkClick", ChatFrame_OnHyperlinkShow)
chatLog:SetScript("OnHyperlinkEnter", function(self, link, ...)
	if linkTypes[link:match("^([^:]+)")] then
		ShowUIPanel(GameTooltip)
		GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
		GameTooltip:SetHyperlink(link)
		GameTooltip:Show()
	end
end)
chatLog:SetScript("OnHyperlinkLeave", GameTooltip_Hide)
chatLog:SetScript("OnMouseWheel", function(self, delta)
	if delta > 0 then
		if IsShiftKeyDown() then
			self:PageUp()
		else
			self:ScrollUp()
		end
	else
		if IsShiftKeyDown() then
			self:PageDown()
		else
			self:ScrollDown()
		end
	end
	self.scrollToBottom:SetShown(not self:AtBottom())
end)


local scrollToBottom = CreateFrame("Button", nil, frame)
scrollToBottom:SetNormalTexture([[Interface\ChatFrame\UI-ChatIcon-ScrollEnd-Up]])
scrollToBottom:SetPushedTexture([[Interface\ChatFrame\UI-ChatIcon-ScrollEnd-Down]])
scrollToBottom:SetDisabledTexture([[Interface\ChatFrame\UI-ChatIcon-ScrollEnd-Disabled]])
scrollToBottom:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]])
scrollToBottom:SetSize(32, 32)
scrollToBottom:SetPoint("BOTTOMRIGHT", chatLogInset)
scrollToBottom:Hide()
scrollToBottom:SetScript("OnClick", function(self, button)
	chatLog:ScrollToBottom()
	self:Hide()
end)
scrollToBottom:SetScript("OnHide", function(self)
	self.flash:Stop()
end)
chatLog.scrollToBottom = scrollToBottom

scrollToBottom.flash = scrollToBottom:CreateTexture(nil, "OVERLAY")
scrollToBottom.flash:SetAllPoints()
scrollToBottom.flash:SetTexture([[Interface\ChatFrame\UI-ChatIcon-BlinkHilight]])
scrollToBottom.flash:SetAlpha(0)

local flash = scrollToBottom.flash:CreateAnimationGroup()
flash:SetLooping("BOUNCE")
scrollToBottom.flash = flash

local fade = flash:CreateAnimation("Alpha")
fade:SetChange(1)
fade:SetDuration(0.8)
fade:SetSmoothing("OUT")


-- WHISPER
-- WHISPER_INFORM
-- AFK
-- DND
-- BN_WHISPER
-- BN_WHISPER_INFORM

function PM:UPDATE_CHAT_COLOR(chatType, r, g, b)
	local info = ChatTypeInfo[chatType]
	-- if not info then print(chatType) return end
	chatLog:UpdateColorByID(GetChatTypeIndex(chatType), r, g, b)
end

function PM:Show()
	frame:Show()
end

function PM:UpdateThreadList()
	scrollFrame:update()
end

function PM:CreateScrollButtons()
	scrollFrame:CreateButtons()
end

local function insert(target, chatType)
	if not PM:IsThreadActive(target, chatType) then
		tinsert(threadListItems, {
			target = target,
			type = chatType,
		})
	end
end

local function addBNetFriend(index)
	local presenceID, presenceName = BNGetFriendInfo(index)
	insert(presenceName, "BN_WHISPER")
end

local function addWoWFriend(index)
	local name = GetFriendInfo(index)
	if not name then return end
	if not name:match("%-") then
		name = name.."-"..gsub(GetRealmName(), " ", "")
	end
	insert(name, "WHISPER")
end

function PM:UpdateThreads()
	wipe(threadListItems)
	
	for i, thread in ipairs(self.db.activeThreads) do
		tinsert(threadListItems, thread)
	end
	
	local numBNetTotal, numBNetOnline = BNGetNumFriends()
	local numWoWTotal, numWoWOnline = GetNumFriends()
	
	if self.db.threadListBNetFriends then
		for i = 1, numBNetOnline do
			addBNetFriend(i)
		end
	end
	
	if self.db.threadListWoWFriends then
		for i = 1, numWoWOnline do
			addWoWFriend(i)
		end
	end
	
	if self.db.threadListShowOffline then
		if self.db.threadListBNetFriends then
			for i = numBNetOnline + 1, numBNetTotal do
				addBNetFriend(i)
			end
		end
		
		if self.db.threadListWoWFriends then
			for i = numWoWOnline + 1, numWoWTotal do
				addWoWFriend(i)
			end
		end
	end
	
	local numActiveThreads = #PM.db.activeThreads
	
	if (numActiveThreads > 0) and (#threadListItems > numActiveThreads) then
		-- insert the separator item between the active threads and the "friends list"
		tinsert(threadListItems, numActiveThreads + 1, {separator = true})
		scrollFrame:ExpandButton(numActiveThreads)
	else
		scrollFrame:CollapseButton()
	end
	self:UpdateThreadList()
end

local function printMessage(thread, messageIndex, atTop)
	local message = thread.messages[messageIndex]
	local nextMessage = thread.messages[messageIndex + 1]
	-- printing at top needs to be done in reverse order
	if atTop then
		if not message.active and (not nextMessage or nextMessage.active) then
			chatLog:AddMessage(" ", 1, 1, 1, nil, atTop)
			chatLog:AddMessage(" "..date("%Y-%m-%d", message.timestamp), 0.8, 0.8, 0.8, nil, atTop)
		end
		PM:PrintMessage(thread, message.messageType, message.text, message.timestamp, message.active, atTop)
	else
		PM:PrintMessage(thread, message.messageType, message.text, message.timestamp, message.active, atTop)
		if not message.active and (not nextMessage or nextMessage.active) then
			chatLog:AddMessage(" "..date("%Y-%m-%d", message.timestamp), 0.8, 0.8, 0.8, nil, atTop)
			chatLog:AddMessage(" ", nil, nil, nil, nil, atTop)
		end
	end
end

local function printThrottler(self, elapsed)
	printMessage(self.currentThread, self.messageThrottleIndex, true)
	self.messageThrottleIndex = self.messageThrottleIndex - 1
	if self.messageThrottleIndex == 0 then
		self:RemoveOnUpdate()
	end
end

local MAX_INSTANT_MESSAGES = 64

function PM:SelectThread(target, chatType)
	local thread = self:GetThread(target, chatType)
	if thread == self:GetSelectedThread() then return end
	self.selectedChat = thread
	self.db.selectedTarget = target
	self.db.selectedType = chatType
	if chatType == "BN_WHISPER" then
		self.db.selectedBattleTag = self:GetBattleTag(target)
	else
		self.db.selectedBattleTag = nil
	end
	editbox:SetAttribute("chatType", chatType)
	editbox:SetAttribute("tellTarget", target)
	chatLog:Clear()
	local numMessages = #thread.messages
	-- printing too many messages at once causes a noticable screen freeze, so we apply throttling at a certain amount of messages
	if numMessages > MAX_INSTANT_MESSAGES then
		for i = numMessages - MAX_INSTANT_MESSAGES + 1, numMessages do
			printMessage(thread, i)
		end
		self.currentThread = thread
		self.messageThrottleIndex = numMessages - MAX_INSTANT_MESSAGES
		self:SetOnUpdate(printThrottler)
	else
		for i = 1, #thread.messages do
			printMessage(thread, i)
		end
		self:RemoveOnUpdate()
	end
	if PM.db.editboxTextPerThread then
		editbox:SetText(thread.editboxText or "")
	end
	menuButton.menu:Close()
	scrollToBottom:Hide()
	scrollToBottom.flash:Stop()
	self:UpdateInfo()
	self:UpdateThreadList()
	if frame:IsShown() then
		thread.unread = nil
	end
end

function PM:PrintMessage(thread, messageType, message, timestamp, isActive, addToTop)
	local darken = 0.2
	local color = self.db.useDefaultColor[thread.type] and ChatTypeInfo[thread.type] or self.db.color[thread.type]
	local r, g, b = color.r, color.g, color.b
	if not isActive then
		r, g, b = 0.9, 0.9, 0.9
	end
	if messageType then
		local sender
		if messageType == "out" then
			sender = "You"
			r, g, b = r - darken, g - darken, b - darken
		else
			sender = thread.target or UNKNOWN
			if thread.type == "WHISPER" then
				sender = Ambiguate(sender, "none")
				if thread.targetID then
					local localizedClass, englishClass, localizedRace, englishRace = GetPlayerInfoByGUID(thread.targetID)
					local color = englishClass and (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[englishClass]
					if color then
						sender = format("|c%s%s|r", color.colorStr, sender)
					end
				end
			end
		end
		message = "|cffffffff"..sender.."|r: "..message
	else
		local color = ChatTypeInfo["SYSTEM"]
		r, g, b = color.r, color.g, color.b
		message = format(message, Ambiguate(thread.target, "none"))
	end
	local t = date("*t", timestamp)
	chatLog:AddMessage(format("|cffd0d0d0%02d:%02d|r %s", t.hour, t.min, message), r, g, b, isActive and GetChatTypeIndex(thread.type), addToTop)
	if not addToTop and not chatLog:AtBottom() and not scrollToBottom.flash:IsPlaying() then
		scrollToBottom.flash:Play()
	end
end

function PM:UpdateInfo()
	local selectedThread = self:GetSelectedThread()
	local name, info, texture
	infoPanel.icon:SetHeight(24)
	if selectedThread.type == "BN_WHISPER" then
		local presenceID = BNet_GetPresenceID(selectedThread.target)
		if not selectedThread.targetID then
			selectedThread.targetID = presenceID
		end
		local _, presenceName, battleTag, isBattleTagPresence, toonName, toonID, client, isOnline, lastOnline, isAFK, isDND = BNGetFriendInfoByID(presenceID)
		local _, toonName, _, realmName, _, faction, race, class, _, zoneName, level, gameText = BNGetToonInfo(toonID or presenceID)
		infoPanel.icon:SetTexCoord(0, 1, 0, 1)
		name = presenceName or UNKNOWN
		if isAFK then
			name = name.." (AFK)"
		elseif isDND then
			name = name.." (DND)"
		elseif not isOnline then
			name = name.." (Offline)"
		end
		if toonName then
			info = toonName or ""
			if client == BNET_CLIENT_WOW then
				if zoneName and zoneName ~= "" then
					info = info.." - "..zoneName
				end
			else
				info = info.." - "..gameText
			end
		end
		texture = BNet_GetClientTexture(client)
	else
		-- try various means of getting information about the target
		local name = Ambiguate(selectedThread.target, "none")
		-- Unit* API, in case they're in the group
		local level = UnitLevel(name)
		if level > 0 then
			info = format("Level %d %s", level, UnitClass(name))
			UnitIsConnected(name)
			UnitIsAFK(name)
			UnitIsDND(name)
		end
		-- friend list
		local isFriend, connected, status, level, class, area = self:GetFriendInfo(name)
		if isFriend and connected and level and level > 0 then
			info = format("Level %d %s - %s", level, class, area)
			-- if englishClass then
				infoPanel.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[reverseclassnames[class]]))
				texture = [[Interface\Glues\CharacterCreate\UI-CharacterCreate-Classes]]
			-- end
		end
		-- or GUID from chat event
		if not info and selectedThread.targetID then
			local localizedClass, englishClass, localizedRace, englishRace = GetPlayerInfoByGUID(selectedThread.targetID)
			if englishClass then
				infoPanel.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[englishClass]))
				texture = [[Interface\Glues\CharacterCreate\UI-CharacterCreate-Classes]]
				info = localizedClass
			end
		elseif selectedThread.isGM then
			infoPanel.icon:SetHeight(12)
			infoPanel.icon:SetTexCoord(0, 1, 0, 1)
			texture = [[Interface\ChatFrame\UI-ChatIcon-Blizz]]
		end
	end
	infoPanel.icon:SetTexture(texture)
	infoPanel.target:SetText(name or Ambiguate(selectedThread.target, "none"))
	infoPanel.toon:SetText(info)
end
