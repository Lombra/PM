local addonName, PM = ...

-- this function deterrmines whether chat messages should be sent to the addon or the default chat frame (true for send to chat frame)
function PM:ShouldSuppress()
	if PMFrame:IsShown() then
		-- always send to addon if it's already shown
		return false
	end
	return
		UnitAffectingCombat("player")
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
	if chatEvents[event] then
		PM:HandleChatEvent(event, ...)
		return
	end
	
	self[event](self, ...)
end)

local function filter(frame)
	return frame ~= PMFrame and not PM:ShouldSuppress()
end

for event in pairs(chatEvents) do
	ChatFrame_AddMessageEventFilter(event, filter)
	f:RegisterEvent(event)
end

local getID = {
	WHISPER = function(...)
		return select(12, ...)
	end,
	BN_WHISPER = function(...)
		return select(13, ...)
	end,
}

function PM:HandleChatEvent(event, ...)
	local filter, message, sender, language, channelString, target, flags, _, _, channelName, _, _, guid, presenceID = messageEventFilter(event, ...)
	if filter then
		return
	end
	local chatType = event:sub(10)
	local chatCategory = Chat_GetChatCategory(chatType)
	sender = Ambiguate(sender, "none")
	local tab = self:GetChat(sender, chatCategory, nil, flags == "GM" or nil)
	tab.targetID = getID[chatCategory](...)
	local messageType = chatEvents[event]
	local hours, minutes = GetGameTime()
	self:SaveMessage(tab, messageType, message)
	if PM:ShouldSuppress() then
		return
	end
	-- if the target of the currently selected tab is not the sender of this PM, then select their tab
	if self:GetSelectedChat() ~= tab and not self.editbox:HasFocus() then
		self:SelectChat(sender, chatCategory)
	end
	self:Show()
	if messageType == "in" then
		ChatEdit_SetLastTellTarget(sender, chatType)
		PlaySound("TellMessage", "MASTER")
		-- PlaySoundFile([[Interface\AddOns\PM\Whisper.ogg]], "MASTER")
	end
end

function PM:SaveMessage(chat, messageType, message)
	tinsert(chat.messages, {
		messageType = messageType,
		text = message,
		timestamp = time(),
		-- from = sender,
		-- fromGUID = guid,
	})
	local cTab = self:GetSelectedChat()
	if cTab == chat then
		self:PrintMessage(chat, messageType, message, time())
	end
end

