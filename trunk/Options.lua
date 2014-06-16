local _, PM = ...
local LSM = LibStub("LibSharedMedia-3.0")

local frame = PM:CreateOptionsFrame("PM")

SlashCmdList["PM"] = function(msg)
	InterfaceOptionsFrame_OpenToCategory(frame)
	InterfaceOptionsFrame_OpenToCategory(frame)
end
SLASH_PM1 = "/pm"

local optionsAppearance = frame:AddSubCategory("Appearance")
optionsAppearance:CreateOptions({
	{
		type = "Dropdown",
		label = "Font",
		tooltipText = "Sets the font used by the chat log.",
		key = "font",
		initialize = function(self)
			for i, v in ipairs(LSM:List("font")) do
				local info = UIDropDownMenu_CreateInfo()
				info.text = v
				info.func = self.set
				info.arg1 = v
				info.checked = (v == PM.db.font)
				self:AddButton(info)
			end
		end,
		set = function(self, font)
			PM.db.font = font
			PM.chatLog:SetFont(LSM:Fetch("font", font), PM.db.fontSize)
			self.owner:SetText(font)
		end,
	},
	{
		type = "Slider",
		label = "Font size",
		tooltipText = "Sets the font size of the chat log.",
		key = "fontSize",
		min = 8,
		max = 32,
		step = 1,
		func = function(self, value)
			PM.chatLog:SetFont(LSM:Fetch("font", PM.db.font), value)
		end,
	},
	{
		type = "CheckButton",
		label = "Show Battle.net friends in thread list",
		tooltipText = "If enabled, will include all Battle.net friends in the thread list that hasn't got an active thread.",
		key = "threadListBNetFriends",
		func = function()
			PM:UpdateThreads()
		end,
	},
	{
		type = "CheckButton",
		label = "Show WoW friends in thread list",
		tooltipText = "If enabled, will include all WoW friends in the thread list that hasn't got an active thread.",
		key = "threadListWoWFriends",
		func = function()
			PM:UpdateThreads()
		end,
	},
	{
		type = "CheckButton",
		label = "Include offline friends in thread list",
		tooltipText = "If enabled, will also include offline friends in the thread list.",
		key = "threadListShowOffline",
		func = function()
			PM:UpdateThreads()
		end,
	},
	{
		newColumn = true,
		type = "CheckButton",
		label = "Use default color for Battle.net whispers",
		tooltipText = "If enabled, will use default color for Battle.net whispers.",
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
		label = "Battle.net whisper color",
		tooltipText = "Sets the color used for Battle.net whisper messages.",
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
		label = "Use default color for WoW whispers",
		tooltipText = "If enabled, will use default color for WoW whispers.",
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
		label = "WoW whisper color",
		tooltipText = "Sets the color used for WoW whisper messages.",
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
		label = "Frame width",
		tooltipText = "Sets the width of the main frame.",
		key = "width",
		min = 256,
		max = 1024,
		step = 1,
		func = function(self, value)
			PMFrame:SetWidth(value)
		end,
	},
	{
		type = "Slider",
		label = "Frame height",
		tooltipText = "Sets the height of the main frame.",
		key = "height",
		min = 160,
		max = 1024,
		step = 1,
		func = function(self, value)
			PMFrame:SetHeight(value)
			PM:CreateScrollButtons()
			PM:UpdateThreadList()
		end,
	},
	{
		type = "Slider",
		label = "Thread list width",
		tooltipText = "Sets the width of the thread list.",
		key = "threadListWidth",
		min = 64,
		max = 256,
		step = 1,
		func = function(self, value)
			PM.threadListInset:SetWidth(value)
		end,
	},
})

local suppressOptions = {
	"combat",
	"dnd",
	"encounter",
}

local optionsBehaviour = frame:AddSubCategory("Behaviour")
optionsBehaviour:CreateOptions({
	{
		type = "CheckButton",
		label = "Clear editbox focus on send",
		tooltipText = "If enabled, will clear the editbox focus after sending a message.",
		key = "clearEditboxFocusOnSend",
	},
	{
		type = "CheckButton",
		label = "Clear editbox on focus lost",
		tooltipText = "If enabled, will clear editbox text when editbox focus is lost.",
		key = "clearEditboxOnFocusLost",
	},
	{
		type = "CheckButton",
		label = "Editbox text per thread",
		tooltipText = "If enabled, will keep editbox text individually per thread.",
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
		label = "Suppress chat frame during:",
		tooltipText = "Select conditions for which to prevent addon from appearing when receiving a message.",
		key = "defaultHandlerWhileSuppressed",
		initialize = function(self)
			for i, v in ipairs(suppressOptions) do
				local info = UIDropDownMenu_CreateInfo()
				info.text = v
				info.func = onClick
				info.arg1 = v
				info.checked = PM.db.suppress[v]
				info.isNotRadio = true
				info.keepShownOnClick = true
				self:AddButton(info)
			end
		end,
		set = function(self, arg, arg2, checked)
			PM.db.suppress[arg] = not checked
		end,
	},
	{
		type = "CheckButton",
		label = "Default handler while suppressed",
		tooltipText = "If enabled, messages will be sent and received using the default chat frame during suppression.",
		key = "defaultHandlerWhileSuppressed",
	},
})

frame:AddSubCategory("Archive"):CreateOptions({
	{
		type = "CheckButton",
		label = "Auto delete Battle.net messages",
		tooltipText = "If enabled, archived Battle.net messages will be automatically deleted.",
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
		label = "Delete Battle.net messages after:",
		tooltipText = "Specifies for how long Battle.net messages will remain archived.",
		initialize = function(self)
			local DAY = 24 * 3600
			for i = 0, 7 do
				local time = DAY * i
				local info = UIDropDownMenu_CreateInfo()
				info.text = (i == 0) and "Immediately" or SecondsToTime(time)
				info.func = self.set
				info.arg1 = time
				info.checked = (time == PM.db.archiveKeep.BN_WHISPER)
				self:AddButton(info)
			end
		end,
		set = function(self, time) PM.db.archiveKeep.BN_WHISPER = time self.owner:func(time) end,
		get = function() return PM.db.archiveKeep.BN_WHISPER end,
		func = function(self, value) self:SetText((value == 0) and "Immediately" or SecondsToTime(value)) end,
		disabled = function() return not PM.db.autoCleanArchive.BN_WHISPER end,
	},
	{
		type = "CheckButton",
		label = "Auto delete WoW messages",
		tooltipText = "If enabled, archived WoW messages will be automatically deleted.",
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
		label = "Delete WoW messages after:",
		tooltipText = "Specifies for how long WoW messages will remain archived.",
		initialize = function(self)
			local DAY = 24 * 3600
			for i = 0, 7 do
				local time = DAY * i
				local info = UIDropDownMenu_CreateInfo()
				info.text = (i == 0) and "Immediately" or SecondsToTime(time)
				info.func = self.set
				info.arg1 = time
				info.checked = (time == PM.db.archiveKeep.WHISPER)
				self:AddButton(info)
			end
		end,
		set = function(self, time) PM.db.archiveKeep.WHISPER = time self.owner:func(time) end,
		get = function() return PM.db.archiveKeep.WHISPER end,
		func = function(self, value) self:SetText((value == 0) and "Immediately" or SecondsToTime(value)) end,
		disabled = function() return not PM.db.autoCleanArchive.WHISPER end,
	},
})

function PM:LoadSettings()
	frame:SetDatabase(self.db)
	frame:SetupControls()
end
