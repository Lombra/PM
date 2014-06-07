local Libra = LibStub("Libra")

local PM = Libra:NewAddon(...)
-- _G.PM = PM
Libra:EmbedWidgets(PM)

local function getPresenceByTag(battleTagQuery)
	if not battleTagQuery then return end
	for i = 1, BNGetNumFriends() do
		local presenceID, presenceName, battleTag, isBattleTagPresence = BNGetFriendInfo(i)
		if battleTag == battleTagQuery then
			return presenceName, presenceID
		end
	end
end

local function copyDefaults(src, dst)
	if not src then return {} end
	if not dst then dst = {} end
	for k, v in pairs(src) do
		if type(v) == "table" then
			dst[k] = copyDefaults(v, dst[k])
		elseif type(v) ~= type(dst[k]) then
			dst[k] = v
		end
	end
	return dst
end

local defaults = {
	width = 512,
	height = 256,
	point = "RIGHT",
	x = -128,
	y = 0,
	activeThreads = {},
	threads = {},
	
	clearEditboxFocusOnSend = true,
	clearEditboxOnFocusLost = true,
	editboxTextPerThread = true,
}

function PM:OnInitialize()
	PMDB = copyDefaults(defaults, PMDB)
	self.db = PMDB
	
	PMFrame:SetSize(self.db.width, self.db.height)
	PMFrame:ClearAllPoints()
	PMFrame:SetPoint(self.db.point or "RIGHT", self.db.x, self.db.y)
	PMFrame:SetShown(self.db.shown)
	
	self:UpdatePresences()
	self:LoadSettings()
	
	-- print("BNIsSelf:", BNIsSelf(BNGetInfo()))
	
	-- self:RegisterEvent("PLAYER_LOGIN")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	-- self:RegisterEvent("PLAYER_LOGOUT")
	self:RegisterEvent("UPDATE_CHAT_COLOR")
	-- self:RegisterEvent("BN_INFO_CHANGED")
	self:RegisterEvent("BN_FRIEND_INFO_CHANGED")
	self:RegisterEvent("BN_FRIEND_LIST_SIZE_CHANGED")
	self:RegisterEvent("BN_CONNECTED")
	-- self:RegisterEvent("BN_DISCONNECTED")
	-- self:RegisterEvent("BN_SELF_ONLINE")
	-- self:RegisterEvent("BN_SELF_OFFLINE")
	-- self:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE")
	-- self:RegisterEvent("BN_FRIEND_ACCOUNT_OFFLINE")
	self:RegisterEvent("CHAT_MSG_AFK")
	self:RegisterEvent("CHAT_MSG_DND")
	self:RegisterEvent("CHAT_MSG_BN_WHISPER_PLAYER_OFFLINE")
end

function PM:PLAYER_ENTERING_WORLD()
	-- print("BNConnected:", BNConnected())
	-- print("BNFeaturesEnabled:", BNFeaturesEnabled())
	-- print("BNFeaturesEnabledAndConnected:", BNFeaturesEnabledAndConnected())
	-- print("BNIsSelf:", BNIsSelf(BNGetInfo()))
	
	-- do this here so it won't get hidden every time
	tinsert(UISpecialFrames, "PMFrame")
	if self.db.shown then
		PM:SelectChat(self.db.selectedTarget, self.db.selectedType)
	end
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function PM:PLAYER_LOGOUT()
	local now = time()
	for i, thread in ipairs(self.db.threads) do
		local messages = thread.messages
		for i = #messages, 1, -1 do
			if (now - messages.timestamp) < self.db.archiveAgeThreshold[thread.type] then
				tremove(messages, i)
			end
		end
	end
end

function PM:BN_FRIEND_LIST_SIZE_CHANGED()
	self:UpdatePresences()
end

function PM:BN_INFO_CHANGED(...)
	-- print("BN_INFO_CHANGED", ...)
end

function PM:BN_FRIEND_INFO_CHANGED(index)
	if index and self:GetSelectedChat() and (BNGetFriendInfo(index) == self:GetSelectedChat().targetID) then
		self:UpdateInfo()
	end
	self:UpdateConversationList()
end

function PM:BN_CONNECTED(...)
	-- print("BN_CONNECTED", ...)
	-- presence IDs will have changed once Battle.net connection is reestablished
	self:UpdatePresences()
end

function PM:BN_DISCONNECTED(...)
	-- print("BN_DISCONNECTED", ...)
end

function PM:BN_SELF_ONLINE(...)
	-- print("BN_SELF_ONLINE", ...)
	-- self:UpdatePresences()
end

function PM:BN_SELF_OFFLINE(...)
	-- print("BN_SELF_OFFLINE", ...)
end

function PM:BN_FRIEND_ACCOUNT_ONLINE(presenceID)
	local chat = self:GetChat(select(2, BNGetFriendInfoByID(presenceID)), "BN_WHISPER", true)
	if chat then
		self:SaveMessage(chat, nil, "%s has come online.")
	end
end

function PM:BN_FRIEND_ACCOUNT_OFFLINE(presenceID)
	if not BNConnected() then return end
	local chat = self:GetChat(select(2, BNGetFriendInfoByID(presenceID)), "BN_WHISPER", true)
	if chat then
		self:SaveMessage(chat, nil, "%s has gone offline.")
	end
end

function PM:BN_TOON_NAME_UPDATED(id, toonName, dunno)
end

function PM:CHAT_MSG_AFK(message, sender)
	local chat = self:GetChat(sender, "WHISPER", true)
	if chat then
		self:SaveMessage(chat, nil, CHAT_AFK_GET..message)
	end
end

function PM:CHAT_MSG_DND(message, sender)
	local chat = self:GetChat(sender, "WHISPER", true)
	if chat then
		self:SaveMessage(chat, nil, CHAT_DND_GET..message)
	end
end

function PM:CHAT_MSG_BN_WHISPER_PLAYER_OFFLINE(message, sender, language, channelString, target, flags, _, _, channelName, _, _, guid, presenceID)
	local chat = self:GetChat(sender, "BN_WHISPER", true)
	if chat then
		self:SaveMessage(sender, "BN_WHISPER", nil, message)
	end
end

function PM:UpdatePresences()
	for i, chat in ipairs(self.db.activeThreads) do
		if chat.type == "BN_WHISPER" then
			local target, targetID = getPresenceByTag(chat.battleTag)
			if selectedTarget == chat.target then
				selectedTarget = target
			end
			chat.target = target
			chat.targetID = targetID
			if not target then
				-- print("Unable to resolve BattleTag", chat.battleTag)
			end
		end
	end
	for i, chat in ipairs(self.db.threads) do
		if chat.type == "BN_WHISPER" then
			local target, targetID = getPresenceByTag(chat.battleTag)
			if selectedTarget == chat.target then
				selectedTarget = target
			end
			chat.target = target
			chat.targetID = targetID
			if not target then
				-- print("Unable to resolve BattleTag", chat.battleTag)
			end
		end
	end
	local lastTell = self.db.lastTell
	local lastTold = self.db.lastTold
	if self.db.lastTellType == "BN_WHISPER" then
		lastTell = getPresenceByTag(lastTell)
	end
	if self.db.lastToldType == "BN_WHISPER" then
		lastTold = getPresenceByTag(lastTold)
	end
	if lastTell then ChatEdit_SetLastTellTarget(lastTell, self.db.lastTellType) end
	if lastTold then ChatEdit_SetLastToldTarget(lastTold, self.db.lastToldType) end
end

local _, CHAT_REALM = UnitFullName("player")

function PM:CreateThread(target, chatType, isGM)
	if chatType == "WHISPER" and not target:match("%-") then
		target = gsub(strlower(target), ".", strupper, 1).."-"..CHAT_REALM
	end
	local chat = {
		target = target,
		type = chatType,
		isGM = isGM,
		messages = {},
	}
	if chatType == "BN_WHISPER" then
		local presenceID = BNet_GetPresenceID(target)
		local presenceID, presenceName, battleTag, isBattleTagPresence = BNGetFriendInfoByID(presenceID)
		chat.battleTag = battleTag
	end
	if not self:GetChat(target, chatType) then
		tinsert(self.db.threads, chat)
	end
	self:OpenChat(target, chatType)
	return chat
end

function PM:DeleteThread(target, chatType)
	for i, thread in ipairs(self.db.threads) do
		if thread.target == target and thread.type == chatType then
			tremove(self.db.threads, i)
			break
		end
	end
end

function PM:GetChat(target, chatType)
	for i, tab in ipairs(self.db.threads) do
		if tab.target == target and tab.type == chatType then
			return tab
		end
	end
end

function PM:IsThreadActive(target, chatType)
	for i, thread in ipairs(self.db.activeThreads) do
		if thread.target == target and thread.type == chatType then
			return true
		end
	end
end

function PM:OpenChat(target, chatType)
	if chatType == "WHISPER" and not target:match("%-") then
		target = gsub(strlower(target), ".", strupper, 1).."-"..gsub(GetRealmName(), " ", "")
	end
	if not self:GetChat(target, chatType) then return end
	local chat = {
		target = target,
		type = chatType,
	}
	if chatType == "BN_WHISPER" then
		local presenceID = BNet_GetPresenceID(target)
		local presenceID, presenceName, battleTag, isBattleTagPresence = BNGetFriendInfoByID(presenceID)
		chat.battleTag = battleTag
	end
	tinsert(self.db.activeThreads, chat)
	return chat
end

function PM:CloseChat(target, chatType)
	local tabs = self.db.activeThreads
	for i, thread in ipairs(tabs) do
		if thread.target == target and thread.type == chatType then
			local lastTold, lastToldType = ChatEdit_GetLastToldTarget()
			if lastTold == target and lastToldType == chatType then
				ChatEdit_SetLastToldTarget(nil, nil)
			end
			tremove(tabs, i)
			local chat = self:GetChat(target, chatType)
			if #tabs == 0 then
				PMFrame:Hide()
			elseif chat == self:GetSelectedChat() then
				local tab = tabs[i] or tabs[i - 1]
				self:SelectChat(tab.target, tab.type)
			end
			-- archive all messages
			for i = #chat.messages, 1, -1 do
				local message = chat.messages[i]
				if not message.active then break end
				message.active = nil
			end
			self:UpdateConversationList()
			break
		end
	end
end

function PM:GetSelectedChat()
	return self.selectedChat
end