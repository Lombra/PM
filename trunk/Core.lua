local Libra = LibStub("Libra")

local PM = Libra:NewAddon(...)
_G.PM = PM
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

local whisperColor = ChatTypeInfo["WHISPER"]
local bnetWhisperColor = ChatTypeInfo["BN_WHISPER"]

local defaults = {
	width = 512,
	height = 256,
	point = "RIGHT",
	x = -128,
	y = 0,
	threadListWidth = 128,
	
	activeThreads = {},
	threads = {},
	
	font = "Arial Narrow",
	fontSize = 12,
	
	autoCleanArchive = {
		WHISPER = true,
		BN_WHISPER = true,
	},
	archiveKeep = {
		WHISPER = 0,
		BN_WHISPER = 7 * 24 * 3600,
	},
	
	threadListWoWFriends = true,
	threadListBNetFriends = true,
	threadListShowOffline = false,
	useDefaultColor = {
		WHISPER = true,
		BN_WHISPER = true,
	},
	color = {
		WHISPER = {r = whisperColor.r, g = whisperColor.g, b = whisperColor.b},
		BN_WHISPER = {r = bnetWhisperColor.r, g = bnetWhisperColor.g, b = bnetWhisperColor.b},
	},
	
	clearEditboxFocusOnSend = true,
	clearEditboxOnFocusLost = true,
	editboxTextPerThread = true,
	
	defaultHandlerWhileSuppressed = true,
	suppress = {
		combat = false,
		dnd = false,
		encounter = false,
	},
}

function PM:OnInitialize()
	PMDB = copyDefaults(defaults, PMDB)
	self.db = PMDB
	
	PMFrame:SetSize(self.db.width, self.db.height)
	PMFrame:ClearAllPoints()
	PMFrame:SetPoint(self.db.point, self.db.x, self.db.y)
	PMFrame:SetShown(self.db.shown)
	
	PM.threadListInset:SetWidth(self.db.threadListWidth)
	
	local activeThreads = self.db.activeThreads
	for i = #activeThreads, 1, -1 do
		local thread = activeThreads[i]
		if thread.type == "BN_WHISPER" and not thread.battleTag then
			tremove(activeThreads, i)
		end
	end
	
	local threads = self.db.threads
	for i = #threads, 1, -1 do
		local thread = threads[i]
		if thread.type == "BN_WHISPER" and not thread.battleTag then
			tremove(threads, i)
		end
	end
	
	self:CreateScrollButtons()
	self:UpdateThreads()
	
	self:UpdatePresences()
	self:LoadSettings()
	
	-- print("BNIsSelf:", BNIsSelf(BNGetInfo()))
	
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_LOGOUT")
	self:RegisterEvent("UPDATE_CHAT_COLOR")
	self:RegisterEvent("FRIENDLIST_UPDATE")
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
	self:RegisterEvent("CHAT_MSG_SYSTEM")
	-- self:RegisterEvent("CHAT_MSG_BN_WHISPER_PLAYER_OFFLINE")
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
	-- print("PLAYER_LOGOUT")
	-- print("IsLoggingOut:", IsLoggingOut())
	local now = time()
	local threads = self.db.threads
	for i = #threads, 1, -1 do
		local thread = threads[i]
		local messages = thread.messages
		if self.db.autoCleanArchive[thread.type] then
			local threshold = self.db.archiveKeep[thread.type]
			for i = #messages, 1, -1 do
				if not message.active and (now - messages.timestamp) > threshold then
					tremove(messages, i)
				end
			end
			if #messages == 0 and not self:IsThreadActive(thread.target, thread.type) then
				-- self:CloseChat(thread.target, thread.type)
				self:DeleteThread(thread.target, thread.type)
			end
		end
	end
end

function PM:GetFriendInfo(name)
	for i = 1, GetNumFriends() do
		local name2, level, class, area, connected, status = GetFriendInfo(i)
		if name2 == name then
			return true, connected, status, level, class, area
		end
	end
end

function PM:FRIENDLIST_UPDATE()
	if self:GetSelectedChat() then
		self:UpdateInfo()
	end
	self:UpdateThreads()
end

function PM:BN_FRIEND_LIST_SIZE_CHANGED()
	self:UpdatePresences()
end

function PM:BN_FRIEND_INFO_CHANGED(index)
	if index and self:GetSelectedChat() and (BNGetFriendInfo(index) == self:GetSelectedChat().targetID) then
		self:UpdateInfo()
	end
	-- print("IsLoggingOut:", IsLoggingOut())
	self:UpdateThreads()
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

function PM:CHAT_MSG_BN_WHISPER_PLAYER_OFFLINE(message, sender, language, channelString, target, flags, _, _, channelName, _, _, guid, presenceID)
	local chat = self:GetChat(sender, "BN_WHISPER", true)
	if chat then
		self:SaveMessage(sender, "BN_WHISPER", nil, message)
	end
end

function PM:UpdatePresences()
	self.presencesReady = true
	
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
				self.presencesReady = false
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
				self.presencesReady = false
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
	
	if self.db.selectedType == "BN_WHISPER" then
		local selectedTarget = getPresenceByTag(self.db.selectedBattleTag)
		self.db.selectedTarget = selectedTarget
		if selectedTarget and self.db.shown then
			PM:SelectChat(selectedTarget, self.db.selectedType)
		end
	end
end

function PM:CreateThread(target, chatType, isGM)
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
	self:ActivateThread(target, chatType)
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

function PM:ActivateThread(target, chatType)
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
	self:UpdateThreads()
	return chat
end

function PM:CloseChat(target, chatType)
	local activeThreads = self.db.activeThreads
	for i, thread in ipairs(activeThreads) do
		if thread.target == target and thread.type == chatType then
			local lastTold, lastToldType = ChatEdit_GetLastToldTarget()
			if lastTold == target and lastToldType == chatType then
				ChatEdit_SetLastToldTarget(nil, nil)
			end
			tremove(activeThreads, i)
			local chat = self:GetChat(target, chatType)
			if #activeThreads == 0 then
				PMFrame:Hide()
			elseif chat == self:GetSelectedChat() then
				local tab = activeThreads[i] or activeThreads[i - 1]
				self:SelectChat(tab.target, tab.type)
			end
			for i = #chat.messages, 1, -1 do
				local message = chat.messages[i]
				if not message.messageType then
					tremove(chat.messages, i)
				end
			end
			-- if this thread type is set to instantly delete, then do that here, or if no messages were sent
			if #chat.messages == 0 or (self.db.autoCleanArchive[thread.type] and self.db.archiveKeep[thread.type] == 0) then
				self:DeleteThread(target, chatType)
			else
				-- these messages are no longer part of the active thread session
				for i = #chat.messages, 1, -1 do
					local message = chat.messages[i]
					if not message.active then break end
					message.active = nil
				end
			end
			self:UpdateThreads()
			break
		end
	end
end

function PM:GetSelectedChat()
	return self.selectedChat
end