local addonName, PM = ...


local frame = CreateFrame("Frame", "PMFrame", UIParent, "BasicFrameTemplate")
frame.TitleText:SetText("PM")
frame:SetToplevel(true)
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetDontSavePosition(true)
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	PM.db.point, PM.db.x, PM.db.y = select(3, self:GetPoint())
end)
frame:SetScript("OnShow", function(self)
	PM:GetSelectedChat().unread = nil
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


local all = {}

local function onClick(self)
	local target, type = self.target, self.type
	if not PM:IsThreadActive(target, type) then
		PM:CreateThread(target, type)
	end
	PM:SelectChat(target, type)
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
		local thread = PM:GetChat(self.target, self.type)
		if not self.selected and thread.unread then
			self.flash:Play()
		end
		if self.type == "BN_WHISPER" then
			self.icon:Show()
		else
			self.text:SetPoint("RIGHT", -2, 0)
		end
		if not self.selected then
			self:UnlockHighlight()
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
		local object = all[lineplusoffset]
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
				local thread = PM:GetChat(object.target, object.type)
				
				local selectedThread = PM:GetSelectedChat()
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
					button.status:SetShown(isFriend)
					button.shadow:SetShown(isFriend)
					button.icon:Hide()
					if isFriend then
						if status == CHAT_FLAG_AFK then
							button.status:SetVertexColor(1, 0.5, 0)
						elseif status == CHAT_FLAG_DND then
							button.status:SetVertexColor(1, 0, 0)
						elseif connected then
							button.status:SetVertexColor(0, 1, 0)
						else
							button.status:SetVertexColor(0.2, 0.2, 0.2)
						end
					end
				end
				
				if object.type == "BN_WHISPER" then
					local presenceID = object.target and BNet_GetPresenceID(object.target)
					if presenceID then
						button.text:SetText(object.target or UNKNOWN)
						button.status:Show()
						button.shadow:Show()
						button.icon:Show()
						button.text:SetPoint("RIGHT", button.icon, "LEFT", -2, 0)
						-- if not thread.targetID then
							-- thread.targetID = presenceID
						-- end
						local presenceID, presenceName, battleTag, isBattleTagPresence, toonName, _, client, isOnline, lastOnline, isAFK, isDND, messageText, noteText, _, broadcastTime = BNGetFriendInfoByID(presenceID)
						-- local _, toonName, client, realmName, _, faction, race, class, _, zoneName, level, gameText = BNGetToonInfo(presenceID)
						if isAFK then
							button.status:SetVertexColor(1, 0.5, 0)
						elseif isDND then
							button.status:SetVertexColor(1, 0, 0)
						elseif isOnline then
							button.status:SetVertexColor(0, 1, 0)
						else
							button.status:SetVertexColor(0.2, 0.2, 0.2)
						end
						button.icon:SetTexture(BNet_GetClientTexture(client))
					end
				end
				
				-- button.active = true
				button.target = object.target
				button.type = object.type
				if button:IsMouseOver() then
					if PM:IsThreadActive(object.target, object.type) then--or button.close:IsMouseOver() then
						button.icon:Hide()
						button.text:SetPoint("RIGHT", button.icon, "LEFT", -2, 0)
					else
					end
				end
			end
		end
		button:SetShown(object ~= nil)
	end
	
	HybridScrollFrame_Update(self, (#all - 1) * self.buttonHeight + self.headerHeight, #self.buttons * self.buttonHeight)
end
scrollFrame.createButton = function(self)
	local tab = CreateFrame("Button", nil, self.scrollChild)
	tab:SetPoint("RIGHT", self.scrollChild)
	tab:SetScript("OnClick", onClick)
	tab:SetScript("OnEnter", onEnter)
	tab:SetScript("OnLeave", onLeave)
	
	tab:SetHighlightTexture([[Interface\Buttons\UI-Listbox-Highlight2]])
	tab:GetHighlightTexture():SetVertexColor(0.196, 0.388, 0.8)
	
	tab.shadow = tab:CreateTexture(nil, "BACKGROUND")
	tab.shadow:SetSize(16, 16)
	tab.shadow:SetPoint("LEFT")
	tab.shadow:SetTexture([[Interface\AddOns\PM\StatusBackground]])
	tab.shadow:SetBlendMode("MOD")
	
	tab.status = tab:CreateTexture()
	tab.status:SetSize(16, 16)
	tab.status:SetPoint("LEFT")
	tab.status:SetTexture([[Interface\AddOns\PM\Untitled-2]])
	
	tab.text = tab:CreateFontString(nil, nil, "GameFontHighlightSmall")
	tab.text:SetPoint("LEFT", tab.status, "RIGHT")
	tab.text:SetJustifyH("LEFT")
	
	tab.icon = tab:CreateTexture()
	tab.icon:SetSize(16, 16)
	tab.icon:SetPoint("RIGHT", -2, 0)
	
	tab.close = CreateFrame("Button", nil, tab)
	tab.close:SetSize(16, 16)
	tab.close:SetPoint("RIGHT", -2, 0)
	tab.close:SetAlpha(0.5)
	tab.close:Hide()
	tab.close.parent = tab
	
	tab.close.texture = tab.close:CreateTexture()
	tab.close.texture:SetSize(16, 16)
	tab.close.texture:SetPoint("CENTER")
	tab.close.texture:SetTexture([[Interface\FriendsFrame\ClearBroadcastIcon]])
	
	for script, handler in pairs(closeScripts) do
		tab.close:SetScript(script, handler)
	end
	
	local flash = tab:CreateTexture()
	flash:SetAllPoints()
	flash:SetTexture([[Interface\Buttons\UI-Listbox-Highlight2]])
	flash:SetVertexColor(0.196, 0.388, 0.8)
	flash:SetAlpha(0)
	
	tab.flash = flash:CreateAnimationGroup()
	tab.flash:SetLooping("BOUNCE")
	
	local fade = tab.flash:CreateAnimation("Alpha")
	fade:SetChange(1)
	fade:SetDuration(0.8)
	fade:SetSmoothing("OUT")
	
	return tab
end


local reverseclassnames = {}
for k,v in pairs(LOCALIZED_CLASS_NAMES_MALE) do reverseclassnames[v] = k end
for k,v in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do reverseclassnames[v] = k end

local infoPanel = CreateFrame("Frame", nil, frame)
infoPanel:SetPoint("LEFT", insetLeft, "RIGHT", PANEL_INSET_LEFT_OFFSET, 0)
infoPanel:SetPoint("TOPRIGHT", PANEL_INSET_RIGHT_OFFSET, PANEL_INSET_TOP_OFFSET)
infoPanel:SetHeight(32)

infoPanel:EnableMouse(true)
infoPanel:SetScript("OnEnter", function(self)
	local thread = PM:GetSelectedChat()
	
	if thread.type ~= "BN_WHISPER" then return end
	
	local presenceID, presenceName, battleTag, isBattleTagPresence, toonName, toonID, client, isOnline, lastOnline, isAFK, isDND, broadcastText, noteText, _, broadcastTime = BNGetFriendInfoByID(thread.targetID)
	
	if not isOnline then return end
	
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:AddLine(presenceName, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
	GameTooltip:AddLine(battleTag)
	GameTooltip:AddLine(broadcastText, nil, nil, nil, true)
	GameTooltip:AddLine(noteText)
	
	local _, toonName, _, realmName, realmID, faction, race, class, _, zoneName, level, gameText = BNGetToonInfo(toonID)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(client)
	if client == BNET_CLIENT_WOW then
		local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[reverseclassnames[class]]
		GameTooltip:AddLine(toonName, color.r, color.g, color.b)
		GameTooltip:AddLine(format(TOOLTIP_UNIT_LEVEL_RACE_CLASS, level, race, class))
		GameTooltip:AddLine(realmName)
		GameTooltip:AddLine(faction)
		GameTooltip:AddLine(zoneName)
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

local function openArchive(self, target, chatType)
	PM:SelectArchive(target, chatType)
	PMArchiveFrame:Show()
end

local playerFactionGroup = UnitFactionGroup("player")

local menuButton = CreateFrame("Button", nil, infoPanel)
menuButton:SetNormalTexture([[Interface\ChatFrame\UI-ChatIcon-ScrollDown-Up]])
menuButton:SetPushedTexture([[Interface\ChatFrame\UI-ChatIcon-ScrollDown-Down]])
menuButton:SetDisabledTexture([[Interface\ChatFrame\UI-ChatIcon-ScrollDown-Disabled]])
menuButton:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]])
menuButton:SetSize(32, 32)
menuButton:SetPoint("RIGHT")
menuButton:SetScript("OnClick", function(self)
	self.menu:Toggle(PM:GetSelectedChat())
end)

menuButton.menu = PM:CreateDropdown("Menu")
menuButton.menu.relativeTo = menuButton
menuButton.menu.xOffset = 0
menuButton.menu.yOffset = 0
menuButton.menu.initialize = function(self, level)
	if level == 1 then
		local thread = UIDROPDOWNMENU_MENU_VALUE
		local info = UIDropDownMenu_CreateInfo()
		info.text = "Invite"
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
		
		local info = UIDropDownMenu_CreateInfo()
		info.text = "View archive"
		info.func = openArchive
		info.arg1 = thread.target
		info.arg2 = thread.type
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
	PM:GetSelectedChat().editboxText = nil
	if PM.db.clearEditboxFocusOnSend then
		self:ClearFocus()
	end
end)
editbox:SetScript("OnEscapePressed", editbox.ClearFocus)
editbox:SetScript("OnTabPressed", function(self)
	-- local nextTell, nextTellType = ChatEdit_GetNextTellTarget(self:GetAttribute("tellTarget"), self:GetAttribute("chatType"))
	-- PM:SelectChat(nextTell, nextTellType)
	for i, thread in ipairs(PM.db.activeThreads) do
		if thread.target == self:GetAttribute("tellTarget") and thread.type == self:GetAttribute("chatType") then
			if IsShiftKeyDown() then i = i - 2 end
			local nextThread = PM.db.activeThreads[i % #PM.db.activeThreads + 1]
			PM:SelectChat(nextThread.target, nextThread.type)
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
		PM:GetSelectedChat().editboxText = self:GetText()
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

-- local stripe = addon:CreateStripe(chatPanel, "horizontal")
-- stripe:SetPoint("LEFT", 2, 0)
-- stripe:SetPoint("RIGHT", -2, 0)
-- stripe:SetPoint("BOTTOM", editbox, "TOP")

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
	if self:AtBottom() then
		self.scrollToBottom.flash:Stop()
	end
end)


local scrollToBottomButton = CreateFrame("Button", nil, frame)
scrollToBottomButton:SetNormalTexture([[Interface\ChatFrame\UI-ChatIcon-ScrollEnd-Up]])
scrollToBottomButton:SetPushedTexture([[Interface\ChatFrame\UI-ChatIcon-ScrollEnd-Down]])
scrollToBottomButton:SetDisabledTexture([[Interface\ChatFrame\UI-ChatIcon-ScrollEnd-Disabled]])
scrollToBottomButton:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]])
scrollToBottomButton:SetSize(32, 32)
scrollToBottomButton:SetPoint("BOTTOMRIGHT", chatLogInset)
scrollToBottomButton:Hide()
scrollToBottomButton:SetScript("OnClick", function(self, button)
	chatLog:ScrollToBottom()
	self:Hide()
	self.flash:Stop()
end)
chatLog.scrollToBottom = scrollToBottomButton

scrollToBottomButton.flash = scrollToBottomButton:CreateTexture(nil, "OVERLAY")
scrollToBottomButton.flash:SetAllPoints()
scrollToBottomButton.flash:SetTexture([[Interface\ChatFrame\UI-ChatIcon-BlinkHilight]])
scrollToBottomButton.flash:SetAlpha(0)

local flash = scrollToBottomButton.flash:CreateAnimationGroup()
flash:SetLooping("BOUNCE")
scrollToBottomButton.flash = flash

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
	-- if not self.presencesReady then return end
	scrollFrame:update()
end

function PM:CreateScrollButtons()
	scrollFrame:CreateButtons()
end

local function addBNetFriend(index)
	local presenceID, presenceName = BNGetFriendInfo(index)
	if not PM:IsThreadActive(presenceName, "BN_WHISPER") then
		tinsert(all, {
			target = presenceName,
			type = "BN_WHISPER",
		})
	end
end

local function addWoWFriend(index)
	local name = GetFriendInfo(index)
	if not name then return end
	if not name:match("%-") then
		name = name.."-"..gsub(GetRealmName(), " ", "")
	end
	if not PM:IsThreadActive(name, "WHISPER") then
		tinsert(all, {
			target = name,
			type = "WHISPER",
		})
	end
end

function PM:UpdateThreads()
	wipe(all)
	
	for i, thread in ipairs(self.db.activeThreads) do
		tinsert(all, thread)
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
	
	if (numActiveThreads > 0) and (#all > numActiveThreads) then
		tinsert(all, numActiveThreads + 1, {separator = true})
		scrollFrame:ExpandButton(numActiveThreads)
	else
		scrollFrame:CollapseButton()
	end
	self:UpdateThreadList()
end

local function printMessage(thread, messageIndex, atTop)
	local message = thread.messages[messageIndex]
	local nextMessage = thread.messages[messageIndex + 1]
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

function PM:SelectChat(target, chatType)
	local tab = self:GetChat(target, chatType)
	if tab == self:GetSelectedChat() then return end
	self.selectedChat = tab
	chatLog:Clear()
	tab.lastTarget = nil
	local numMessages = #tab.messages
	-- printing too many messages at once causes a noticable screen freeze, so we apply throttling at a certain amount of messages
	if numMessages > MAX_INSTANT_MESSAGES then
		for i = numMessages - MAX_INSTANT_MESSAGES + 1, numMessages do
			printMessage(tab, i)
		end
		self.currentThread = tab
		self.messageThrottleIndex = numMessages - MAX_INSTANT_MESSAGES
		self:SetOnUpdate(printThrottler)
	else
		for i = 1, #tab.messages do
			printMessage(tab, i)
		end
		self:RemoveOnUpdate()
	end
	editbox:SetAttribute("chatType", chatType)
	editbox:SetAttribute("tellTarget", target)
	if PM.db.editboxTextPerThread then
		editbox:SetText(tab.editboxText or "")
	end
	self:UpdateInfo()
	self.db.selectedTarget = target
	self.db.selectedType = chatType
	if chatType == "BN_WHISPER" then
		local presenceID = BNet_GetPresenceID(target)
		local presenceID, presenceName, battleTag, isBattleTagPresence = BNGetFriendInfoByID(presenceID)
		self.db.selectedBattleTag = battleTag
	else
		self.db.selectedBattleTag = nil
	end
	menuButton.menu:Close()
	self:UpdateThreadList()
	if frame:IsShown() then
		tab.unread = nil
	end
	scrollToBottomButton:Hide()
	scrollToBottomButton.flash:Stop()
end

local SENDER = "|cffffffff%s"

function PM:PrintMessage(thread, messageType, message, timestamp, isActive, addToTop)
	local darken = 0.2
	local color = self.db.useDefaultColor[thread.type] and ChatTypeInfo[thread.type] or self.db.color[thread.type]
	local r, g, b = color.r, color.g, color.b
	if not isActive then
		r, g, b = 0.9, 0.9, 0.9
	end
	if messageType then
		-- if messageType ~= thread.lastTarget then
			local color = HIGHLIGHT_FONT_COLOR
			-- local r, g, b = color.r, color.g, color.b
			-- if messageType == "out" then
				-- r, g, b = r - darken, g - darken, b - darken
			-- end
			local message2
			if messageType == "out" then
				message2 = format(SENDER, "You")
			else
				local name = thread.target
				if thread.type == "BN_WHISPER" then
					local presenceID = BNet_GetPresenceID(name)
					local presenceID, presenceName = BNGetFriendInfoByID(presenceID)
					-- message = "|HBNplayer:"..arg2..":"..arg13..":"..arg11..":"..chatGroup..(chatTarget and ":"..chatTarget or "").."|h";
					-- message = format("|HBNplayer:%s:%d:"..arg11..":"..chatGroup..(chatTarget and ":"..chatTarget or "").."|h";
					if presenceName then
						message2 = format(SENDER, format("|HBNplayer:%s:%d|h%s|h", presenceName, presenceID, presenceName))
					else
						message2 = SENDER
					end
				else
					name = Ambiguate(name, "none")
					if thread.targetID then
						local localizedClass, englishClass, localizedRace, englishRace, sex = GetPlayerInfoByGUID(thread.targetID)
						if englishClass then
							local color = RAID_CLASS_COLORS[englishClass]
							if color then
								name = format("|cff%.2x%.2x%.2x%s|r", color.r * 255, color.g * 255, color.b * 255, name)
							end
						end
					end
					message2 = format(SENDER, format("|Hplayer:%s|h%s|h", Ambiguate(thread.target, "none"), name))
				end
			end
			message = message2..":|r "..message
			-- chatLog:AddMessage(message, r, g, b)
		-- else
			-- message = "  "..message
		-- end
		if messageType == "out" then
			r, g, b = r - darken, g - darken, b - darken
		end
	else
		local color = ChatTypeInfo["SYSTEM"]
		r, g, b = color.r, color.g, color.b
		message = format(message, thread.target)
	end
	thread.lastTarget = messageType
	local t = date("*t", timestamp)
	chatLog:AddMessage(format("|cffd0d0d0%02d:%02d|r %s", t.hour, t.min, message), r, g, b, isActive and GetChatTypeIndex(thread.type), addToTop)
	if not addToTop and not chatLog:AtBottom() and not scrollToBottomButton.flash:IsPlaying() then
		scrollToBottomButton.flash:Play()
	end
end

function PM:UpdateInfo()
	local selectedTab = self:GetSelectedChat()
	local name, info, texture
	infoPanel.icon:SetHeight(24)
	if selectedTab.type == "BN_WHISPER" then
		local presenceID = BNet_GetPresenceID(selectedTab.target)
		if not selectedTab.targetID then
			selectedTab.targetID = presenceID
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
		local name = Ambiguate(selectedTab.target, "none")
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
		if connected and level and level > 0 then
			info = format("Level %d %s - %s", level, class, area)
		end
		-- or GUID from chat event
		if not info and selectedTab.targetID then
			local localizedClass, englishClass, localizedRace, englishRace = GetPlayerInfoByGUID(selectedTab.targetID)
			if englishClass then
				infoPanel.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[englishClass]))
				texture = [[Interface\Glues\CharacterCreate\UI-CharacterCreate-Classes]]
				info = localizedClass
			end
		elseif selectedTab.isGM then
			infoPanel.icon:SetHeight(12)
			infoPanel.icon:SetTexCoord(0, 1, 0, 1)
			texture = [[Interface\ChatFrame\UI-ChatIcon-Blizz]]
		end
	end
	infoPanel.icon:SetTexture(texture)
	infoPanel.target:SetText(name or Ambiguate(selectedTab.target, "none"))
	infoPanel.toon:SetText(info)
end
