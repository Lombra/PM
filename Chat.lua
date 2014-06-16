local addonName, PM = ...


hooksecurefunc("ChatEdit_SetLastTellTarget", function(target, chatType)
	if chatType == "BN_WHISPER" then
		local presenceID = BNet_GetPresenceID(target)
		local presenceID, presenceName, battleTag, isBattleTagPresence = BNGetFriendInfoByID(presenceID)
		target = battleTag
	end
	PM.db.lastTell, PM.db.lastTellType = target, chatType
end)

hooksecurefunc("ChatEdit_SetLastToldTarget", function(target, chatType)
	if chatType == "BN_WHISPER" then
		local presenceID = BNet_GetPresenceID(target)
		local presenceID, presenceName, battleTag, isBattleTagPresence = BNGetFriendInfoByID(presenceID)
		target = battleTag
	end
	PM.db.lastTold, PM.db.lastToldType = target, chatType
end)


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
	if not PM:IsThreadActive(target, chatType) then
		PM:CreateThread(target, chatType)
	end
	PM:SelectChat(target, chatType)
	PM:Show()
	PM.editbox:SetFocus()
end

local hooks = {
	ChatFrame_ReplyTell = function(chatFrame)
		local lastTell, lastTellType = ChatEdit_GetLastTellTarget()
		if lastTell then
			PM.editbox.setText = true
			openChat(lastTell, lastTellType)
		end
	end,
	ChatFrame_ReplyTell2 = function(chatFrame)
		local lastTold, lastToldType = ChatEdit_GetLastToldTarget()
		if lastTold then
			PM.editbox.setText = true
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


local function messageEventFilter(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14)
	local chatFilters = ChatFrame_GetMessageEventFilters(event)
	if chatFilters then
		for _, filterFunc in pairs(chatFilters) do
			local filter, newarg1, newarg2, newarg3, newarg4, newarg5, newarg6, newarg7, newarg8, newarg9, newarg10, newarg11, newarg12, newarg13, newarg14 =
				filterFunc(PMFrame, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14)
			if filter then
				return true
			elseif newarg1 then
				arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14 =
					newarg1, newarg2, newarg3, newarg4, newarg5, newarg6, newarg7, newarg8, newarg9, newarg10, newarg11, newarg12, newarg13, newarg14
			end
		end
	end
	return false, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14
end


-- local orig_ChatEdit_InsertLink = ChatEdit_InsertLink

-- function ChatEdit_InsertLink(text)
	-- if not text then
		-- return false;
	-- end
	
	-- if editbox:HasFocus() then
		-- editbox:Insert(text)
		-- return true
	-- end
	
	-- return orig_ChatEdit_InsertLink(text)
-- end

local chatEvents = {
	CHAT_MSG_WHISPER = "in",
	CHAT_MSG_WHISPER_INFORM = "out",
	CHAT_MSG_BN_WHISPER = "in",
	CHAT_MSG_BN_WHISPER_INFORM = "out",
}

local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(self, event, ...)
	PM:HandleChatEvent(event, ...)
end)

local function filter(frame)
	return frame ~= PMFrame and not (PM:ShouldSuppress() and PM.db.defaultHandlerWhileSuppressed)
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_AFK", filter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_DND", filter)

for event in pairs(chatEvents) do
	ChatFrame_AddMessageEventFilter(event, filter)
	f:RegisterEvent(event)
end

function PM:HandleChatEvent(event, ...)
	local filter, message, sender, language, channelString, target, flags, _, _, channelName, _, _, guid, presenceID = messageEventFilter(event, ...)
	if filter then
		return
	end
	local chatType = Chat_GetChatCategory(event:sub(10))
	if chatType == "WHISPER" and not sender:match("%-") then
		sender = sender.."-"..gsub(GetRealmName(), " ", "")
	end
	if not PM:IsThreadActive(sender, chatType) then
		PM:CreateThread(sender, chatType, flags == "GM" or nil)
	end
	local thread = self:GetChat(sender, chatType) or self:CreateThread(sender, chatType, flags == "GM" or nil)
	if chatType == "WHISPER" then
		thread.targetID = guid
	end
	if chatType == "BN_WHISPER" then
		thread.targetID = presenceID
	end
	local messageType = chatEvents[event]
	if messageType == "in" and not (PMFrame:IsShown() and thread == self:GetSelectedChat()) then
		thread.unread = true
		self:UpdateThreadList()
	end
	self:SaveMessage(sender, chatType, messageType, message)
	if PM:ShouldSuppress() then
		return
	end
	-- if the target of the currently selected thread is not the sender of this PM, then select their thread
	if self:GetSelectedChat() ~= thread and not self.editbox:HasFocus() then
		self:SelectChat(sender, chatType)
	end
	self:Show()
	if messageType == "in" then
		ChatEdit_SetLastTellTarget(sender, chatType)
		PlaySound("TellMessage", "MASTER")
		-- PlaySoundFile([[Interface\AddOns\PM\Whisper.ogg]], "MASTER")
	end
end

function PM:CHAT_MSG_AFK(...)
	local filter, message, sender = messageEventFilter("CHAT_MSG_AFK", ...)
	if filter then
		return
	end
	if not sender:match("%-") then
		sender = sender.."-"..gsub(GetRealmName(), " ", "")
	end
	-- if thread then
		self:SaveMessage(sender, "WHISPER", nil, CHAT_AFK_GET..message)
	-- end
end

function PM:CHAT_MSG_DND(...)
	local filter, message, sender = messageEventFilter("CHAT_MSG_DND", ...)
	if filter then
		return
	end
	if sender:match("%-") then
		sender = sender.."-"..gsub(GetRealmName(), " ", "")
	end
	-- if thread then
		self:SaveMessage(sender, "WHISPER", nil, CHAT_DND_GET..message)
	-- end
end

-- local ERR_CHAT_PLAYER_NOT_FOUND_S = "No player named '%s' is currently playing."
local ERR_CHAT_PLAYER_NOT_FOUND_S = gsub(ERR_CHAT_PLAYER_NOT_FOUND_S, "%.", "%."):format("(.+)")

function PM:CHAT_MSG_SYSTEM(...)
	local filter, message = messageEventFilter("CHAT_MSG_SYSTEM", ...)
	if filter then
		return
	end
	local sender = strmatch(message, ERR_CHAT_PLAYER_NOT_FOUND_S)
	if not sender then return end
	if not sender:match("%-") then
		sender = sender.."-"..gsub(GetRealmName(), " ", "")
	end
	-- if thread then
		self:SaveMessage(sender, "WHISPER", nil, _G.ERR_CHAT_PLAYER_NOT_FOUND_S)
	-- end
end

-- this function deterrmines whether chat messages should be sent to the addon or the default chat frame (true for send to chat frame)
function PM:ShouldSuppress()
	if PMFrame:IsShown() then
		-- always send to addon if it's already shown
		return false
	end
	return
		(self.db.suppress.combat and UnitAffectingCombat("player")) or
		(self.db.suppress.dnd and IsChatDND()) or
		(self.db.suppress.encounter and IsEncounterInProgress())
end

function PM:SaveMessage(target, chatType, messageType, message)
	local thread = self:GetChat(target, chatType)
	tinsert(thread.messages, {
		messageType = messageType,
		text = message,
		timestamp = time(),
		-- from = sender,
		active = true,
		unread = true,
	})
	if thread == self:GetSelectedChat() then
		self:PrintMessage(thread, messageType, message, time(), true)
	end
end
