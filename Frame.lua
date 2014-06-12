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

local BUTTON_HEIGHT = 16
local SEPARATOR_HEIGHT = 9

local all = {}

local function onClick(self)
	if not PM:IsThreadActive(self.target, self.type) then
		PM:CreateThread(self.target, self.type)
	end
	PM:SelectChat(self.target, self.type)
end

local function onEnter(self)
	if PM:IsThreadActive(self.target, self.type) then
		self.close:Show()
		self.flash:Stop()
	end
end

local function onLeave(self)
	if PM:IsThreadActive(self.target, self.type) and not self.close:IsMouseOver() then
		self.close:Hide()
		-- self.icon:Show()
		local thread = PM:GetChat(self.target, self.type)
		if thread ~= PM:GetSelectedChat() and thread.unread then
			self.flash:Play()
		end
	end
end

local scrollFrame = PM:CreateScrollFrame("Hybrid", insetLeft)
scrollFrame:SetPoint("TOPRIGHT", -4, -4)
scrollFrame:SetPoint("BOTTOMLEFT", 4, 4)
scrollFrame.buttons = {}
local separator = scrollFrame:CreateTexture()
separator:SetTexture([[Interface\FriendsFrame\UI-FriendsFrame-OnlineDivider]])
separator:SetTexCoord(0, 1, 3/16, 0.75)
scrollFrame.Update = function(self)
	separator:Hide()
	
	local offset = self:GetOffset()
	
	for line = 1, #self.buttons do
		local button = self.buttons[line]
		local lineplusoffset = line + offset
		local object = all[lineplusoffset]
		if object then
			if object.separator then
				button:SetHeight(SEPARATOR_HEIGHT)
				button.text:SetText(nil)
				button.close:Hide()
				button.icon:Hide()
				button.status:Hide()
				button.shadow:Hide()
				button.flash:Stop()
				separator:SetAllPoints(button)
				separator:Show()
			else
				button:SetHeight(BUTTON_HEIGHT)
			end
			button:SetEnabled(not object.separator)
			
			if not object.separator then
				local thread = PM:GetChat(object.target, object.type)
				
				if thread == PM:GetSelectedChat() then
					button:LockHighlight()
				else
					button:UnlockHighlight()
				end
				
				if PM:IsThreadActive(object.target, object.type) then
					if (thread.unread and thread ~= PM:GetSelectedChat()) and not (button:IsMouseOver() or button.close:IsMouseOver()) then
						if not button.flash:IsPlaying() then
							button.flash:Play()
						end
					elseif button.flash:IsPlaying() then
						button.flash:Stop()
					end
				else
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
					local presenceID = BNet_GetPresenceID(object.target)
					if presenceID then
						button.text:SetText(object.target or UNKNOWN)
						button.status:Show()
						button.shadow:Show()
						button.icon:Show()
						if not thread.targetID then
							thread.targetID = presenceID
						end
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
				-- if button:IsMouseOver() or button.close:IsMouseOver() then
					-- button.icon:Hide()
				-- end
			end
		end
		button:SetShown(object ~= nil)
	end
	
	HybridScrollFrame_Update(self, (#all - 1) * BUTTON_HEIGHT + SEPARATOR_HEIGHT, #self.buttons * BUTTON_HEIGHT)
end
scrollFrame.createButton = function(self)
	local tab = CreateFrame("Button", nil, self.scrollChild)
	tab:SetHeight(BUTTON_HEIGHT)
	tab:SetPoint("LEFT", self)
	tab:SetPoint("RIGHT", self)
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
	
	tab.icon = tab:CreateTexture()
	tab.icon:SetSize(16, 16)
	tab.icon:SetPoint("RIGHT", -2, 0)
	
	tab.text = tab:CreateFontString(nil, nil, "GameFontHighlightSmall")
	tab.text:SetPoint("LEFT", tab.status, "RIGHT")
	tab.text:SetPoint("RIGHT", tab.icon, "LEFT", -2, 0)
	tab.text:SetJustifyH("LEFT")
	
	tab.close = CreateFrame("Button", nil, tab)
	tab.close:SetSize(16, 16)
	tab.close:SetPoint("RIGHT", -2, 0)
	tab.close:SetAlpha(0.5)
	tab.close:Hide()
	
	tab.close.texture = tab.close:CreateTexture()
	tab.close.texture:SetSize(16, 16)
	tab.close.texture:SetPoint("CENTER")
	tab.close.texture:SetTexture([[Interface\FriendsFrame\ClearBroadcastIcon]])
	
	local closeScripts = {
		OnShow = function(self)
			tab.icon:Hide()
			-- self:SetAlpha(1.0)
		end,
		OnHide = function(self)
			tab.icon:Show()
			-- self:SetAlpha(1.0)
		end,
		OnEnter = function(self)
			self:SetAlpha(1.0)
		end,
		OnLeave = function(self)
			self:SetAlpha(0.5)
			if not tab:IsMouseOver() then
				self:Hide()
			end
		end,
		OnClick = function(self)
			PM:CloseChat(tab.target, tab.type)
		end,
		OnMouseDown = function(self)
			self.texture:SetPoint("CENTER", 1, -1)
		end,
		OnMouseUp = function(self)
			self.texture:SetPoint("CENTER", 0, 0)
		end,
	}
	
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

function PM:CreateScrollButtons()
	local numButtons = ceil(scrollFrame:GetHeight() / BUTTON_HEIGHT) + 1
	for i = #scrollFrame.buttons + 1, numButtons do
		local button = scrollFrame:createButton()
		if i == 1 then
			button:SetPoint("TOP", scrollFrame)
		else
			button:SetPoint("TOP", scrollFrame.buttons[i - 1], "BOTTOM")
		end
		scrollFrame.buttons[i] = button
	end
	HybridScrollFrame_CreateButtons(scrollFrame)
end

function PM:UpdateThreads()
	wipe(all)
	
	for i, thread in ipairs(self.db.activeThreads) do
		tinsert(all, thread)
	end
	
	local numBNetTotal, numBNetOnline = BNGetNumFriends()
	local numBNetOffline = numBNetTotal - numBNetOnline
	local numWoWTotal, numWoWOnline = GetNumFriends()
	local numWoWOffline = numWoWTotal - numWoWOnline
	
	if self.db.threadListBNetFriends then
		for i = 1, numBNetOnline do
			local presenceID, presenceName = BNGetFriendInfo(i)
			if not self:IsThreadActive(presenceName, "BN_WHISPER") then
				tinsert(all, {
					target = presenceName,
					type = "BN_WHISPER",
				})
			end
		end
	end
	
	if self.db.threadListWoWFriends then
		for i = 1, numWoWOnline do
			local name = GetFriendInfo(i)
			if not name:match("%-") then
				name = name.."-"..gsub(GetRealmName(), " ", "")
			end
			if not self:IsThreadActive(name, "WHISPER") then
				tinsert(all, {
					target = name,
					type = "WHISPER",
				})
			end
		end
	end
	
	if self.db.threadListShowOffline then
		if self.db.threadListBNetFriends then
			for i = numBNetOnline + 1, numBNetTotal do
				local presenceID, presenceName = BNGetFriendInfo(i)
				if not self:IsThreadActive(presenceName, "BN_WHISPER") then
					tinsert(all, {
						target = presenceName,
						type = "BN_WHISPER",
					})
				end
			end
		end
		
		if self.db.threadListWoWFriends then
			for i = numWoWOnline + 1, numWoWTotal do
				local name, level, class, area, connected = GetFriendInfo(i)
				if not name:match("%-") then
					name = name.."-"..gsub(GetRealmName(), " ", "")
				end
				if not self:IsThreadActive(name, "WHISPER") then
					tinsert(all, {
						target = name,
						type = "WHISPER",
					})
				end
			end
		end
	end
	
	local size = #PM.db.activeThreads
	
	if (size > 0) and (#all > size) then
		tinsert(all, size + 1, {separator = true})
		HybridScrollFrame_ExpandButton(scrollFrame, size * BUTTON_HEIGHT, SEPARATOR_HEIGHT)
	else
		HybridScrollFrame_CollapseButton(scrollFrame)
	end
end

-- local chatPanel = CreateFrame("Frame", nil, frame)
-- chatPanel:SetPoint("LEFT", scrollFrame, "RIGHT")
-- chatPanel:SetPoint("TOPRIGHT")
-- chatPanel:SetPoint("BOTTOMRIGHT")

local infoPanel = CreateFrame("Frame", nil, frame)
infoPanel:SetPoint("LEFT", insetLeft, "RIGHT", PANEL_INSET_LEFT_OFFSET, 0)
infoPanel:SetPoint("TOPRIGHT", PANEL_INSET_RIGHT_OFFSET, PANEL_INSET_TOP_OFFSET)
infoPanel:SetHeight(32)

infoPanel:EnableMouse(true)
infoPanel:SetScript("OnEnter", function(self)
	local chat = PM:GetSelectedChat()
	if chat.type ~= "BN_WHISPER" then return end
	
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	local presenceID, presenceName, battleTag, isBattleTagPresence, toonName, _, client, isOnline, lastOnline, isAFK, isDND, messageText, noteText, _, broadcastTime = BNGetFriendInfoByID(chat.targetID)
	GameTooltip:AddLine(presenceName, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
	GameTooltip:AddLine(battleTag)
	GameTooltip:AddLine(messageText, nil, nil, nil, true)
	GameTooltip:AddLine(noteText)
	
	local _, toonName, client, realmName, realmID, faction, race, class, _, zoneName, level, gameText = BNGetToonInfo(chat.targetID)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(client)
	GameTooltip:AddLine(toonName)
	if client == BNET_CLIENT_WOW then
		GameTooltip:AddLine(format(TOOLTIP_UNIT_LEVEL_RACE_CLASS, level, race, class))
		GameTooltip:AddLine(realmName)
		GameTooltip:AddLine(faction)
		GameTooltip:AddLine(zoneName)
	else
		GameTooltip:AddLine(gameText)
	end
	local friendIndex = BNGetFriendIndex(chat.targetID)
	for toonIndex = 2, BNGetNumFriendToons(friendIndex) do
		for i = 2, select("#", BNGetFriendToonInfo(friendIndex, toonIndex)) do
			GameTooltip:AddLine(i..": "..tostring(select(i, BNGetFriendToonInfo(friendIndex, toonIndex))))
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

local function openArchive(self, target, chatType)
	PM:SelectArchive(target, chatType)
	PMArchiveFrame:Show()
end

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
				local presenceID, presenceName, _, _, toonName, toonID = BNGetFriendInfo(index)
				if toonID then
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
	end
	if level == 2 then
		-- LE_PARTY_CATEGORY_HOME
		-- list all invitable toons
		local index = BNGetFriendIndex(UIDROPDOWNMENU_MENU_VALUE)
		for i = 1, BNGetNumFriendToons(index) do
			local _, _, client, _, realmID, faction, _, _, _, _, _, _, _, _, _, toonID = BNGetFriendToonInfo(index, i)
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
editbox:SetScript("OnUpdate", function(self)
	if self.setText then
		self:SetText("")
		self.setText = nil
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

local chatLogInset = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
chatLogInset:SetPoint("TOP", infoPanel, "BOTTOM", 0, 0)
chatLogInset:SetPoint("RIGHT", PANEL_INSET_RIGHT_OFFSET, 0)
chatLogInset:SetPoint("LEFT", insetLeft, "RIGHT", PANEL_INSET_LEFT_OFFSET, 0)
chatLogInset:SetPoint("BOTTOM", editbox, "TOP", 0, 4)

-- local stripe = addon:CreateStripe(chatPanel, "horizontal")
-- stripe:SetPoint("LEFT", 2, 0)
-- stripe:SetPoint("RIGHT", -2, 0)
-- stripe:SetPoint("BOTTOM", editbox, "TOP")

local chatLog = CreateFrame("ScrollingMessageFrame", nil, chatLogInset)
chatLog:SetPoint("TOPRIGHT", -6, -6)
chatLog:SetPoint("BOTTOMLEFT", 6, 5)
chatLog:SetMaxLines(256)
chatLog:SetJustifyH("LEFT")
chatLog:SetFading(false)
chatLog:SetIndentedWordWrap(true)
-- chatLog:SetToplevel(true)
chatLog:SetScript("OnHyperlinkClick", ChatFrame_OnHyperlinkShow)
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
PM.chatLog = chatLog

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

chatLog:SetScript("OnHyperlinkEnter", function(self, link, ...)
	if linkTypes[link:match("^([^:]+)")] then
		ShowUIPanel(GameTooltip)
		GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
		GameTooltip:SetHyperlink(link)
		GameTooltip:Show()
	end
end)

chatLog:SetScript("OnHyperlinkLeave", GameTooltip_Hide)

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


local function openChat(target, chatType)
	-- ChatFrame_SendSmartTell does not come with a chat type; figures out from target string
	if not chatType then
		if BNet_GetPresenceID(target) then
			chatType = "BN_WHISPER"
		else
			chatType = "WHISPER"
		end
	end
	if chatType == "WHISPER" and not target:match("%-") then
		target = gsub(strlower(target), ".", strupper, 1).."-"..gsub(GetRealmName(), " ", "")
	end
	if PM:IsThreadActive(target, chatType) then
		-- PM:OpenChat(target, chatType)
	else
		PM:CreateThread(target, chatType)
	end
	PM:SelectChat(target, chatType)
	PM:Show()
	editbox:SetFocus()
end

local hooks = {
	ChatFrame_ReplyTell = function(chatFrame)
		local lastTell, lastTellType = ChatEdit_GetLastTellTarget()
		if lastTell then
			editbox.setText = true
			openChat(lastTell, lastTellType)
		end
	end,
	ChatFrame_ReplyTell2 = function(chatFrame)
		local lastTold, lastToldType = ChatEdit_GetLastToldTarget()
		if lastTold then
			editbox.setText = true
			openChat(lastTold, lastToldType)
		end
	end,
	ChatFrame_SendTell = function(name)
		openChat(name, "WHISPER")
	end,
	ChatFrame_SendSmartTell = function(name)
		openChat(name)
	end,
}

for functionName, hook in pairs(hooks) do
	local originalFunction = _G[functionName]
	_G[functionName] = function(...)
		if PM:ShouldSuppress() then
			originalFunction(...)
			return
		end
		
		hook(...)
	end
end


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
	scrollFrame:Update()
end

local function printThrottler(self, elapsed)
	local message = self.currentTab.messages[self.messageThrottleIndex]
	self:PrintMessage(self.currentTab, message.messageType, message.text, message.timestamp, message.active, true)
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
			local message = tab.messages[i]
			self:PrintMessage(tab, message.messageType, message.text, message.timestamp, message.active)
		end
		self.currentTab = tab
		self.messageThrottleIndex = numMessages - MAX_INSTANT_MESSAGES
		self:SetOnUpdate(printThrottler)
	else
		for i, message in ipairs(tab.messages) do
			self:PrintMessage(tab, message.messageType, message.text, message.timestamp, message.active)
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
	chatLog:AddMessage(format("|cffd0d0d0%02d:%02d|r %s", t.hour, t.min, message), r, g, b, GetChatTypeIndex(thread.type), addToTop)
	if not addToTop and not chatLog:AtBottom() and not scrollToBottomButton.flash:IsPlaying() then
		scrollToBottomButton.flash:Play()
	end
end

function PM:UpdateInfo()
	local selectedTab = self:GetSelectedChat()
	local presenceID = BNet_GetPresenceID(selectedTab.target)
	local name, info, texture
	infoPanel.icon:SetHeight(24)
	if presenceID then
		if not selectedTab.targetID then
			selectedTab.targetID = presenceID
		end
		local _, presenceName, battleTag, isBattleTagPresence, toonName, _, client, isOnline, lastOnline, isAFK, isDND = BNGetFriendInfoByID(presenceID)
		local _, toonName, client, realmName, _, faction, race, class, _, zoneName, level, gameText = BNGetToonInfo(presenceID)
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
					info = info.."\n "..zoneName
				end
			else
				info = info.."\n "..gameText
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
