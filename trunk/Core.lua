local addonName, PM = ...

local chatCache = {}

local tabs = {}

local function getPresenceByTag(battleTagQuery)
	if not battleTagQuery then return end
	for i = 1, BNGetNumFriends() do
		local presenceID, presenceName, battleTag, isBattleTagPresence = BNGetFriendInfo(i)
		if battleTag == battleTagQuery then
			return presenceName, presenceID
		end
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("BN_CONNECTED")
f:RegisterEvent("BN_DISCONNECTED")
f:RegisterEvent("BN_SELF_ONLINE")
f:RegisterEvent("BN_SELF_OFFLINE")
f:RegisterEvent("BN_INFO_CHANGED")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("BN_FRIEND_INFO_CHANGED")
f:RegisterEvent("BN_FRIEND_LIST_SIZE_CHANGED")
-- f:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE")
-- f:RegisterEvent("BN_FRIEND_ACCOUNT_OFFLINE")
f:RegisterEvent("CHAT_MSG_AFK")
f:RegisterEvent("CHAT_MSG_DND")
f:RegisterEvent("CHAT_MSG_BN_WHISPER_PLAYER_OFFLINE")
f:SetScript("OnEvent", function(self, event, ...)
	self[event](PM, ...)
end)

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
	chats = {},
}

function f:ADDON_LOADED(addon)
	if addon ~= addonName then return end
	PMDB = copyDefaults(defaults, PMDB)
	local self = PM
	self.db = PMDB
	local selectedTarget = self.db.selectedTarget
	tabs = self.db.chats
	if self.db.shown then
		PM:SelectChat(selectedTarget, self.db.selectedType)
	end
	PMFrame:SetSize(self.db.width, self.db.height)
	PMFrame:ClearAllPoints()
	PMFrame:SetPoint(self.db.point or "RIGHT", self.db.x, self.db.y)
	PMFrame:SetShown(self.db.shown)
	self:UpdatePresences()
	-- print("BNIsSelf:", BNIsSelf(BNGetInfo()))
end

function f:PLAYER_LOGIN()
	-- print("BNConnected:", BNConnected())
	-- print("BNFeaturesEnabled:", BNFeaturesEnabled())
	-- print("BNFeaturesEnabledAndConnected:", BNFeaturesEnabledAndConnected())
	-- print("BNIsSelf:", BNIsSelf(BNGetInfo()))
	-- do this here so it won't get hidden every time
	tinsert(UISpecialFrames, "PMFrame")
end

function f:BN_FRIEND_LIST_SIZE_CHANGED()
	-- print(BNGetNumFriends())
	self:UpdatePresences()
end

function f:BN_CONNECTED(...)
	-- print("BN_CONNECTED", ...)
	-- presence IDs will have changed once Battle.net connection is reestablished
	self:UpdatePresences()
end

function f:BN_DISCONNECTED(...)
	-- print("BN_DISCONNECTED", ...)
end

function f:BN_SELF_ONLINE(...)
	-- print("BN_SELF_ONLINE", ...)
	-- self:UpdatePresences()
end

function f:BN_SELF_OFFLINE(...)
	-- print("BN_SELF_OFFLINE", ...)
end

function f:BN_INFO_CHANGED(...)
	-- print("BN_INFO_CHANGED", ...)
end

function PM:UpdatePresences()
	for i, chat in ipairs(self.db.chats) do
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

function f:BN_FRIEND_INFO_CHANGED(index)
	if index and self:GetSelectedChat() and (BNGetFriendInfo(index) == self:GetSelectedChat().targetID) then
		self:UpdateInfo()
	end
	PMConversationList:Update()
end

function f:BN_FRIEND_ACCOUNT_ONLINE(presenceID)
	local chat = self:GetChat(select(2, BNGetFriendInfoByID(presenceID)), "BN_WHISPER", true)
	if chat then
		self:SaveMessage(chat, nil, "%s has come online.")
	end
end

function f:BN_FRIEND_ACCOUNT_OFFLINE(presenceID)
	if not BNConnected() then return end
	local chat = self:GetChat(select(2, BNGetFriendInfoByID(presenceID)), "BN_WHISPER", true)
	if chat then
		self:SaveMessage(chat, nil, "%s has gone offline.")
	end
end

function f:BN_TOON_NAME_UPDATED(id, toonName, dunno)
end

function f:CHAT_MSG_AFK(message, sender)
	local chat = self:GetChat(sender, "WHISPER", true)
	if chat then
		self:SaveMessage(chat, nil, CHAT_AFK_GET..message)
	end
end

function f:CHAT_MSG_DND(message, sender)
	local chat = self:GetChat(sender, "WHISPER", true)
	if chat then
		self:SaveMessage(chat, nil, CHAT_DND_GET..message)
	end
end

function f:CHAT_MSG_BN_WHISPER_PLAYER_OFFLINE(message, sender, language, channelString, target, flags, _, _, channelName, _, _, guid, presenceID)
	local chat = self:GetChat(sender, "BN_WHISPER", true)
	if chat then
		self:SaveMessage(chat, nil, message)
	end
end

function PM:GetChat(target, chatType, checkOnly, isGM)
	for i, tab in ipairs(tabs) do
		if tab.target == target and tab.type == chatType then
			return tab
		end
	end
	return not checkOnly and self:NewChat(target, chatType, isGM)
end

function PM:CloseChat(target, chatType)
	for i, tab in ipairs(tabs) do
		if tab.target == target and tab.type == chatType then
			local lastTold, lastToldType = ChatEdit_GetLastToldTarget()
			if lastTold == target and lastToldType == chatType then
				ChatEdit_SetLastToldTarget(nil, nil)
			end
			tremove(tabs, i)
			if #tabs == 0 then
				f:Hide()
			elseif tab == self:GetSelectedChat() then
				local tab = tabs[i] or tabs[i - 1]
				self:SelectChat(tab.target, tab.type)
			end
			PMConversationList:Update()
			break
		end
	end
end

function PM:GetSelectedChat()
	return self.selectedChat
end