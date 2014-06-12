local _, PM = ...
local LSM = LibStub("LibSharedMedia-3.0")

-- LSM:Register("font", "Tahoma", [[Interface\AddOns\GeneralPurpose\media\tahoma.ttf]])

local frame = PM:CreateOptionsFrame("PM")

SlashCmdList["PM"] = function(msg)
	InterfaceOptionsFrame_OpenToCategory(frame)
	InterfaceOptionsFrame_OpenToCategory(frame)
end
SLASH_PM1 = "/pm"

local options = {
	{
		type = "CheckButton",
		label = "Auto delete WoW archives",
		-- tooltipText = "",
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
		label = "Keep WoW messages for:",
		-- tooltipText = "",
		initialize = function(self)
			local DAY = 24 * 3600
			for i = 0, 7 do
				local info = UIDropDownMenu_CreateInfo()
				info.text = SecondsToTime(i * DAY)
				info.func = self.set
				info.arg1 = i * DAY
				info.checked = (v == PM.db.archiveKeep.WHISPER)
				self:AddButton(info)
			end
		end,
		set = function(self, time) PM.db.archiveKeep.WHISPER = time end,
		get = function() return PM.db.archiveKeep.WHISPER end,
		func = function(self, value) self:SetText(SecondsToTime(value)) end,
		disabled = function() return not PM.db.autoCleanArchive.WHISPER end,
	},
	{
		type = "CheckButton",
		label = "Auto delete Battle.net archives",
		-- tooltipText = "",
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
		label = "Keep Battle.net messages for:",
		-- tooltipText = "",
		initialize = function(self)
			local DAY = 24 * 3600
			for i = 0, 7 do
				local info = UIDropDownMenu_CreateInfo()
				info.text = SecondsToTime(i * DAY)
				info.func = self.set
				info.arg1 = i * DAY
				info.checked = (v == PM.db.archiveKeep.BN_WHISPER)
				self:AddButton(info)
			end
		end,
		set = function(self, time) PM.db.archiveKeep.BN_WHISPER = time end,
		get = function() return PM.db.archiveKeep.BN_WHISPER end,
		func = function(self, value) self:SetText(SecondsToTime(value)) end,
		disabled = function() return not PM.db.autoCleanArchive.BN_WHISPER end,
	},
}

-- frame:SetDescription("Hello")
frame:CreateOptions(options)

local optionsAppearance = frame:AddSubCategory("Appearance")

local optionsA = {
	{
		type = "Dropdown",
		label = "Font",
		-- tooltipText = "Shows on item tooltips which characters or guilds has the item",
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
		label = "Show WoW friends in thread list",
		-- tooltipText = "",
		key = "threadListWoWFriends",
		func = function()
			PM:UpdateThreads()
			PM:UpdateThreadList()
		end,
	},
	{
		type = "CheckButton",
		label = "Show Battle.net friends in thread list",
		-- tooltipText = "",
		key = "threadListBNetFriends",
		func = function()
			PM:UpdateThreads()
			PM:UpdateThreadList()
		end,
	},
	{
		type = "CheckButton",
		label = "Show offline friends in thread list",
		-- tooltipText = "",
		key = "threadListShowOffline",
		func = function()
			PM:UpdateThreads()
			PM:UpdateThreadList()
		end,
	},
	{
		newColumn = true,
		type = "CheckButton",
		label = "Use default color for WoW whispers",
		-- tooltipText = "",
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
		-- tooltipText = "",
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
		type = "CheckButton",
		label = "Use default color for Battle.net whispers",
		-- tooltipText = "",
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
		-- tooltipText = "",
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
		type = "Slider",
		label = "Frame width",
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
		key = "height",
		min = 160,
		max = 1024,
		step = 1,
		func = function(self, value)
			PMFrame:SetHeight(value)
		end,
	},
	{
		type = "Slider",
		label = "Thread list width",
		key = "threadListWidth",
		min = 64,
		max = 256,
		step = 1,
		func = function(self, value)
			PM.threadListInset:SetWidth(value)
		end,
	},
}

optionsAppearance:CreateOptions(optionsA)

local optionsBehaviour = frame:AddSubCategory("Behaviour")

local suppressOptions = {
	"combat",
	"dnd",
	"encounter",
}

local optionsB = {
	{
		type = "CheckButton",
		label = "Clear editbox focus on send",
		-- tooltipText = "",
		key = "clearEditboxFocusOnSend",
	},
	{
		type = "CheckButton",
		label = "Clear editbox on focus lost",
		-- tooltipText = "",
		key = "clearEditboxOnFocusLost",
	},
	{
		type = "CheckButton",
		label = "Editbox text per thread",
		-- tooltipText = "",
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
		type = "CheckButton",
		label = "Default handler while suppressed",
		-- tooltipText = "",
		key = "defaultHandlerWhileSuppressed",
	},
	{
		type = "Dropdown",
		label = "Suppression",
		-- tooltipText = "",
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
}

optionsBehaviour:CreateOptions(optionsB)

function PM:LoadSettings()
	frame:SetDatabase(self.db)
	frame:SetupControls()
end
