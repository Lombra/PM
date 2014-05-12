local addonName, PM = ...

local CONVERSATION_LIST_WIDTH = 128

local frame = CreateFrame("Frame", "PMFrame", UIParent, "BasicFrameTemplate")
frame.TitleText:SetText("PM")
frame:SetToplevel(true)
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	PM.db.point, PM.db.x, PM.db.y = select(3, self:GetPoint())
end)
frame:SetScript("OnHide", function(self)
	self:StopMovingOrSizing()
	PM.db.point, PM.db.x, PM.db.y = select(3, self:GetPoint())
	PM.db.shown = nil
end)
frame:SetDontSavePosition(true)

local insetLeft = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
insetLeft:SetPoint("TOPLEFT", PANEL_INSET_LEFT_OFFSET, PANEL_INSET_TOP_OFFSET)
insetLeft:SetPoint("BOTTOM", 0, PANEL_INSET_BOTTOM_OFFSET + 2)
insetLeft:SetWidth(CONVERSATION_LIST_WIDTH)

-- local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
-- close:SetPoint("TOPRIGHT")
-- close:SetHitRectInsets()

-- local close = CreateFrame("Button", nil, f)
-- close:SetSize(10, 10)
-- close:SetPoint("TOPRIGHT", -3, -3)
-- close:SetScript("OnClick", function()
	-- f:Hide()
-- end)

-- local n = close:CreateTexture()
-- n:SetAllPoints()
-- n:SetTexture([[Interface\FriendsFrame\UI-Toast-CloseButton-Up]])
-- n:SetTexCoord(5 / 16, 15 / 16, 1 / 16, 11 / 16)
-- close:SetNormalTexture(n)

local function onClick(self)
	PM:SelectChat(self.target, self.type)
end

local function onEnter(self)
	self.icon:Hide()
	self.close:Show()
end

local function onLeave(self)
	if not self.close:IsMouseOver() then
		self.close:Hide()
		-- self.icon:Show()
	end
end

local NUM_BUTTONS = 12
local BUTTON_HEIGHT = 16

local scrollFrame = CreateFrame("ScrollFrame", "PMConversationList", insetLeft, "FauxScrollFrameTemplate")
scrollFrame:SetPoint("TOPRIGHT", -4, -4)
scrollFrame:SetPoint("BOTTOMLEFT", 4, 4)
scrollFrame:SetScript("OnVerticalScroll", function(self, value)
	self.ScrollBar:SetValue(value)
	self.offset = floor((value / BUTTON_HEIGHT) + 0.5)
	self:Update()
end)
scrollFrame.buttons = {}
scrollFrame.Update = function(self)
	local size = #PM.db.chats
	FauxScrollFrame_Update(self, size, NUM_BUTTONS, BUTTON_HEIGHT)
	
	local offset = self.offset
	
	for line = 1, NUM_BUTTONS do
		local button = self.buttons[line]
		local lineplusoffset = line + offset
		local chat = PM.db.chats[lineplusoffset]
		if chat then
			button.text:SetText(chat.target and Ambiguate(chat.target, "none") or UNKNOWN)
			local presenceID = chat.target and BNet_GetPresenceID(chat.target)
			if chat == PM:GetSelectedChat() then
				button:LockHighlight()
			else
				button:UnlockHighlight()
			end
			if presenceID then
				if not chat.targetID then
					chat.targetID = presenceID
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
			button.status:SetShown(presenceID ~= nil)
			button.shadow:SetShown(presenceID ~= nil)
			button.icon:SetShown(presenceID ~= nil)
			button.target = chat.target
			button.type = chat.type
			if button:IsMouseOver() or button.close:IsMouseOver() then
				button.icon:Hide()
			end
		end
		button:SetShown(chat ~= nil)
	end
end
for i = 1, NUM_BUTTONS do
	local tab = CreateFrame("Button", nil, frame)
	tab:SetHeight(BUTTON_HEIGHT)
	if i == 1 then
		tab:SetPoint("TOP", scrollFrame, 0, 0)
	else
		tab:SetPoint("TOP", scrollFrame.buttons[i - 1], "BOTTOM")
	end
	tab:SetPoint("LEFT", scrollFrame)
	tab:SetPoint("RIGHT", scrollFrame)
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
	tab.close:SetID(i)
	
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
	
	scrollFrame.buttons[i] = tab
end

local chatPanel = CreateFrame("Frame", nil, frame)
chatPanel:SetPoint("LEFT", scrollFrame, "RIGHT")
chatPanel:SetPoint("TOPRIGHT")
chatPanel:SetPoint("BOTTOMRIGHT")

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
	for toonIndex = 2, BNGetNumFriendToons(BNGetFriendIndex(chat.targetID)) do
		for i = 2, select("#", BNGetFriendToonInfo(BNGetFriendIndex(chat.targetID), toonIndex)) do
			GameTooltip:AddLine(i..": "..tostring(select(i, BNGetFriendToonInfo(BNGetFriendIndex(chat.targetID), toonIndex))))
		end
	end
	
	GameTooltip:Show()
end)
infoPanel:SetScript("OnLeave", GameTooltip_Hide)

infoPanel.icon = infoPanel:CreateTexture()
infoPanel.icon:SetSize(24, 24)
infoPanel.icon:SetPoint("LEFT", 4, 0)

infoPanel.target = infoPanel:CreateFontString(nil, nil, "GameFontHighlightLarge")
infoPanel.target:SetPoint("LEFT", infoPanel.icon, "RIGHT", 8, 1)

infoPanel.toon = infoPanel:CreateFontString(nil, nil, "GameFontHighlightSmallRight")
infoPanel.toon:SetPoint("RIGHT", -32, 0)

local inviteButton = CreateFrame("Button", nil, infoPanel)
inviteButton:SetSize(24, 32)
inviteButton:SetPoint("RIGHT")
inviteButton:SetNormalTexture([[Interface\FriendsFrame\TravelPass-Invite]])
inviteButton:GetNormalTexture():SetTexCoord(0.01562500, 0.39062500, 0.27343750, 0.52343750)
inviteButton:SetPushedTexture([[Interface\FriendsFrame\TravelPass-Invite]])
inviteButton:GetPushedTexture():SetTexCoord(0.42187500, 0.79687500, 0.27343750, 0.52343750)
inviteButton:SetDisabledTexture([[Interface\FriendsFrame\TravelPass-Invite]])
inviteButton:GetDisabledTexture():SetTexCoord(0.01562500, 0.39062500, 0.00781250, 0.25781250)
inviteButton:SetHighlightTexture([[Interface\FriendsFrame\TravelPass-Invite]])
inviteButton:GetHighlightTexture():SetTexCoord(0.42187500, 0.79687500, 0.00781250, 0.25781250)
inviteButton:SetScript("OnClick", function(self)
	-- LE_PARTY_CATEGORY_HOME
	local chat = PM:GetSelectedChat()
	if chat.type == "WHISPER" then
		InviteUnit(chat.target)
	else
		local index = BNGetFriendIndex(chat.targetID)
		local numToons = BNGetNumFriendToons(index)
		if numToons > 1 then
			local numValidToons = 0
			local lastToonID
			for i = 1, numToons do
				local _, _, client, _, realmID, faction, race, class, _, _, level, _, _, _, _, toonID = BNGetFriendToonInfo(index, i)
				if client == BNET_CLIENT_WOW and faction == playerFactionGroup and realmID ~= 0 then
					numValidToons = numValidToons + 1
					lastToonID = toonID
				end
			end
			if numValidToons == 1 then
				BNInviteFriend(lastToonID)
				return
			end

			PlaySound("igMainMenuOptionCheckBoxOn")
			local dropdown = TravelPassDropDown
			if dropdown.index ~= index then
				CloseDropDownMenus()
			end
			dropdown.index = index
			ToggleDropDownMenu(1, nil, dropdown, self, 20, 34)
		else
			local presenceID, presenceName, battleTag, isBattleTagPresence, toonName, toonID = BNGetFriendInfo(index)
			if toonID then
				BNInviteFriend(toonID)
			end
		end	
	end
end)

local editbox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
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
	self:ClearFocus()
end)
editbox:SetScript("OnEscapePressed", editbox.ClearFocus)
editbox:SetScript("OnTabPressed", function(self)
	local nextTell, nextTellType = ChatEdit_GetNextTellTarget(self:GetAttribute("tellTarget"), self:GetAttribute("chatType"))
	PM:SelectChat(nextTell, nextTellType)
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
	self:SetText("")
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
chatLog:SetFontObject("ChatFontSmall")
chatLog:SetMaxLines(256)
chatLog:SetJustifyH("LEFT")
chatLog:SetFading(false)
chatLog:SetIndentedWordWrap(true)
-- chatLog:SetToplevel(true)
frame:SetScript("OnShow", function(self)
	chatLog:SetFrameLevel(self:GetFrameLevel() + 1)
	PM.db.shown = true
end)
chatLog:SetScript("OnHyperlinkClick", ChatFrame_OnHyperlinkShow)
chatLog:SetScript("OnMouseWheel", function(self, delta)
	if delta > 0 then
		self:ScrollUp()
	else
		self:ScrollDown()
	end
end)

local linkTypes = {
	achievement = true,
	enchant = true,
	glyph = true,
	item = true,
	quest = true,
	spell = true,
	talent = true,
	instancelock = true,
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

local function openChat(target, chatType)
	if not chatType then
		if BNet_GetPresenceID(target) then
			chatType = "BN_WHISPER"
		else
			chatType = "WHISPER"
		end
	end
	PM:SelectChat(target, chatType)
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


function PM:SelectChat(target, chatType)
	local tab = self:GetChat(target, chatType)
	if tab == self:GetSelectedChat() then return end
	self.selectedChat = tab
	chatLog:Clear()
	tab.lastTarget = nil
	for i, message in ipairs(tab.messages) do
		self:PrintMessage(tab, message.messageType, message.text, message.timestamp)
	end
	editbox:SetAttribute("chatType", chatType)
	editbox:SetAttribute("tellTarget", target)
	self:UpdateInfo()
	self.db.selectedTarget = target
	self.db.selectedType = chatType
	if not frame:IsShown() then
		frame:Show()
	end
	scrollFrame:Update()
end

local SENDER = "|cffffffff%s"

function PM:PrintMessage(tab, messageType, message, timestamp)
	local darken = 0.2
	local color = ChatTypeInfo[tab.type]
	local r, g, b = color.r, color.g, color.b
	if messageType then
		if messageType ~= tab.lastTarget then
			local color = HIGHLIGHT_FONT_COLOR
			local r, g, b = color.r, color.g, color.b
			if messageType == "out" then
				r, g, b = r - darken, g - darken, b - darken
			end
			local message2
			if messageType == "out" then
				message2 = format(SENDER, "You")
			else
				local name = tab.target
				if tab.type == "BN_WHISPER" then
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
					if tab.targetID then
						local localizedClass, englishClass, localizedRace, englishRace, sex = GetPlayerInfoByGUID(tab.targetID)
						if englishClass then
							local color = RAID_CLASS_COLORS[englishClass]
							if color then
								name = format("|cff%.2x%.2x%.2x%s|r", color.r * 255, color.g * 255, color.b * 255, name)
							end
						end
					end
					message2 = format(SENDER, format("|Hplayer:%s|h%s|h", tab.target, name))
				end
			end
			message = message2..":|r "..message
			-- chatLog:AddMessage(message, r, g, b)
		else
			message = "  "..message
		end
		if messageType == "out" then
			r, g, b = r - darken, g - darken, b - darken
		end
	else
		local color = ChatTypeInfo["SYSTEM"]
		r, g, b = color.r, color.g, color.b
		message = format(message, tab.target)
	end
	tab.lastTarget = messageType
	local t = date("*t", timestamp)
	chatLog:AddMessage(format("|cffd0d0d0%02d:%02d|r %s", t.hour, t.min, message), r, g, b)
end

function PM:NewChat(target, chatType, isGM)
	local chat = {}
	chat.target = target
	chat.type = chatType
	chat.isGM = isGM
	if chatType == "BN_WHISPER" then
		local presenceID = BNet_GetPresenceID(target)
		local presenceID, presenceName, battleTag, isBattleTagPresence = BNGetFriendInfoByID(presenceID)
		chat.battleTag = battleTag
	end
	chat.messages = {}
	tinsert(self.db.chats, chat)
	scrollFrame:Update()
	return chat
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
		if selectedTab.targetID then
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
