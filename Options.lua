local _, PM = ...
local LSM = LibStub("LibSharedMedia-3.0")


local frame = PM:CreateOptionsFrame("PM")

SlashCmdList["PM"] = function(msg)
	InterfaceOptionsFrame_OpenToCategory(frame)
	InterfaceOptionsFrame_OpenToCategory(frame)
end
SLASH_PM1 = "/pm"

local optionsAppearance = frame:AddSubCategory("Appearance", true)
optionsAppearance:CreateOptions({
	{
		type = "Dropdown",
		text = "Font",
		tooltip = "Sets the font used by the chat log.",
		key = "font",
		func = function(self, font)
			PM.chatLog:SetFont(LSM:Fetch("font", font), PM.db.fontSize)
		end,
		menuList = function(self)
			return LSM:List("font")
		end,
	},
	{
		type = "Slider",
		text = "Font size",
		tooltip = "Sets the font size of the chat log.",
		key = "fontSize",
		func = function(self, value)
			PM.chatLog:SetFont(LSM:Fetch("font", PM.db.font), value)
		end,
		min = 8,
		max = 32,
		step = 1,
	},
	{
		type = "CheckButton",
		text = "Show Battle.net friends in thread list",
		tooltip = "If enabled, will include all Battle.net friends in the thread list that hasn't got an active thread.",
		key = "threadListBNetFriends",
		func = "UpdateThreads",
	},
	{
		type = "CheckButton",
		text = "Show WoW friends in thread list",
		tooltip = "If enabled, will include all WoW friends in the thread list that hasn't got an active thread.",
		key = "threadListWoWFriends",
		func = "UpdateThreads",
	},
	{
		type = "CheckButton",
		text = "Include offline friends in thread list",
		tooltip = "If enabled, will also include offline friends in the thread list.",
		key = "threadListShowOffline",
		func = "UpdateThreads",
	},
	{
		newColumn = true,
		type = "CheckButton",
		text = "Use default color for Battle.net whispers",
		tooltip = "If enabled, will use default color for Battle.net whispers.",
		-- key = "threadListBNetFriends",
		set = function(self, value)
			PM.db.useDefaultColor.BN_WHISPER = value
		end,
		get = function(self) return PM.db.useDefaultColor.BN_WHISPER end,
		func = function(self, value)
			local info = value and ChatTypeInfo["WHISPER"] or PM.db.color.BN_WHISPER
			PM:UPDATE_CHAT_COLOR("BN_WHISPER", info.r, info.g, info.b)
		end,
	},
	{
		type = "ColorButton",
		text = "Battle.net whisper color",
		tooltip = "Sets the color used for Battle.net whisper messages.",
		-- key = "threadListBNetFriends",
		set = function(self, value) PM.db.color.BN_WHISPER = value end,
		get = function(self) return PM.db.color.BN_WHISPER end,
		func = function(self, value)
			if not PM.db.useDefaultColor.BN_WHISPER then
				PM:UPDATE_CHAT_COLOR("BN_WHISPER", value.r, value.g, value.b)
			end
		end,
		disabled = function() return PM.db.useDefaultColor.BN_WHISPER end,
	},
	{
		type = "CheckButton",
		text = "Use default color for WoW whispers",
		tooltip = "If enabled, will use default color for WoW whispers.",
		-- key = "threadListBNetFriends",
		set = function(self, value)
			PM.db.useDefaultColor.WHISPER = value
		end,
		get = function(self) return PM.db.useDefaultColor.WHISPER end,
		func = function(self, value)
			local info = value and ChatTypeInfo["WHISPER"] or PM.db.color.WHISPER
			PM:UPDATE_CHAT_COLOR("WHISPER", info.r, info.g, info.b)
		end,
	},
	{
		type = "ColorButton",
		text = "WoW whisper color",
		tooltip = "Sets the color used for WoW whisper messages.",
		-- key = "threadListBNetFriends",
		set = function(self, value) PM.db.color.WHISPER = value end,
		get = function(self) return PM.db.color.WHISPER end,
		func = function(self, value)
			if not PM.db.useDefaultColor.WHISPER then
				PM:UPDATE_CHAT_COLOR("WHISPER", value.r, value.g, value.b)
			end
		end,
		disabled = function() return PM.db.useDefaultColor.WHISPER end,
	},
	{
		type = "Slider",
		text = "Frame width",
		tooltip = "Sets the width of the main frame.",
		key = "width",
		func = function(self, value)
			PMFrame:SetWidth(value)
		end,
		min = 256,
		max = 1024,
		step = 1,
	},
	{
		type = "Slider",
		text = "Frame height",
		tooltip = "Sets the height of the main frame.",
		key = "height",
		func = function(self, value)
			PMFrame:SetHeight(value)
			PM:CreateScrollButtons()
			PM:UpdateThreadList()
		end,
		min = 160,
		max = 1024,
		step = 1,
	},
	{
		type = "Slider",
		text = "Thread list width",
		tooltip = "Sets the width of the thread list.",
		key = "threadListWidth",
		func = function(self, value)
			PM.threadListInset:SetWidth(value)
		end,
		min = 64,
		max = 256,
		step = 1,
	},
})

local optionsBehaviour = frame:AddSubCategory("Behaviour", true)
optionsBehaviour:CreateOptions({
	{
		type = "CheckButton",
		text = "Clear editbox focus on send",
		tooltip = "If enabled, will clear the editbox focus after sending a message.",
		key = "clearEditboxFocusOnSend",
	},
	{
		type = "CheckButton",
		text = "Clear editbox on focus lost",
		tooltip = "If enabled, will clear editbox text when editbox focus is lost.",
		key = "clearEditboxOnFocusLost",
	},
	{
		type = "CheckButton",
		text = "Editbox text per thread",
		tooltip = "If enabled, will keep editbox text individually per thread.",
		key = "editboxTextPerThread",
		func = function(self, value)
			if not value then
				for i, thread in ipairs(PM.db.threads) do
					thread.editboxText = nil
				end
			end
		end,
	},
	{
		type = "Dropdown",
		text = "Suppress chat frame during:",
		tooltip = "Select conditions for which to prevent addon from appearing when receiving a message.",
		set = function(self, arg, checked)
			PM.db.suppress[arg] = checked
		end,
		get = function(self, arg)
			return PM.db.suppress[arg]
		end,
		multiSelect = true,
		properties = {
			text = {
				combat = "During combat",
				encounter = "During boss encounters",
				dnd = "While flagged DND",
			},
			keepShownOnClick = true,
		},
		menuList = {
			"combat",
			"encounter",
			"dnd",
		},
	},
	{
		type = "CheckButton",
		text = "Default handler while suppressed",
		tooltip = "If enabled, messages will be sent and received using the default chat frame during suppression.",
		key = "defaultHandlerWhileSuppressed",
	},
})

frame:AddSubCategory("Archive", true):CreateOptions({
	{
		type = "CheckButton",
		text = "Auto delete Battle.net messages",
		tooltip = "If enabled, archived Battle.net messages will be automatically deleted.",
		key = "autoDeleteArchiveBNet",
		set = function(self, value)
			PM.db.autoCleanArchive.BN_WHISPER = value
		end,
		get = function(self)
			return PM.db.autoCleanArchive.BN_WHISPER
		end,
	},
	{
		type = "Dropdown",
		text = "Delete Battle.net messages after:",
		tooltip = "Specifies for how long Battle.net messages will remain archived.",
		set = function(self, time) PM.db.archiveKeep.BN_WHISPER = time end,
		get = function() return PM.db.archiveKeep.BN_WHISPER end,
		-- func = function(self, value) self:SetText((value == 0) and "Immediately" or SecondsToTime(value)) end,
		disabled = function() return not PM.db.autoCleanArchive.BN_WHISPER end,
		properties = {
			text = function(value)
				return (value == 0) and "Immediately" or SecondsToTime(value)
			end,
		},
		menuList = (function()
			local DAY = 24 * 3600
			local t = {}
			for i = 0, 7 do
				tinsert(t, i * DAY)
			end
			return t
		end)(),
	},
	{
		type = "CheckButton",
		text = "Auto delete WoW messages",
		tooltip = "If enabled, archived WoW messages will be automatically deleted.",
		key = "autoDeleteArchiveWoW",
		set = function(self, value)
			PM.db.autoCleanArchive.WHISPER = value
		end,
		get = function(self)
			return PM.db.autoCleanArchive.WHISPER
		end,
	},
	{
		type = "Dropdown",
		text = "Delete WoW messages after:",
		tooltip = "Specifies for how long WoW messages will remain archived.",
		set = function(self, time) PM.db.archiveKeep.WHISPER = time end,
		get = function() return PM.db.archiveKeep.WHISPER end,
		-- func = function(self, value) self:SetText((value == 0) and "Immediately" or SecondsToTime(value)) end,
		disabled = function() return not PM.db.autoCleanArchive.WHISPER end,
		properties = {
			text = function(value)
				return (value == 0) and "Immediately" or SecondsToTime(value)
			end,
		},
		menuList = (function()
			local DAY = 24 * 3600
			local t = {}
			for i = 0, 7 do
				tinsert(t, i * DAY)
			end
			return t
		end)(),
	},
})

function PM:LoadSettings()
	frame:SetDatabase(self.db)
	frame:SetHandler(self)
	frame:SetupControls()
end
