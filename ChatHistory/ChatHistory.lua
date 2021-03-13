-- maximum messages to log
local LOG_MAX = 500

-- the chat frame to print messages at login
local CHAT_FRAME = ChatFrame1

--
-- EDIT THESE ARE YOUR OWN RISK
--

local EVENTS = {
	-- "CHAT_MSG_BATTLEGROUND",
	-- "CHAT_MSG_BATTLEGROUND_LEADER",
	-- "CHAT_MSG_BN_WHISPER", -- battle.net whispers will show wrong names between sessions
	-- "CHAT_MSG_BN_WHISPER_INFORM", -- battle.net whispers will show wrong names between sessions
	"CHAT_MSG_CHANNEL", -- all channel related talk (general, trade, defense, custom channels, e.g.)
	"CHAT_MSG_EMOTE", -- only "/me text" messages, not /dance, /lol and such
	"CHAT_MSG_GUILD",
	--"CHAT_MSG_GUILD_ACHIEVEMENT",
	"CHAT_MSG_OFFICER",
	"CHAT_MSG_PARTY",
	"CHAT_MSG_PARTY_LEADER",
	"CHAT_MSG_RAID",
	"CHAT_MSG_RAID_LEADER",
	"CHAT_MSG_RAID_WARNING",
	"CHAT_MSG_SAY",
	"CHAT_MSG_WHISPER",
	"CHAT_MSG_WHISPER_INFORM",
	"CHAT_MSG_YELL",
	"CHAT_MSG_SYSTEM",
}

--
-- DO NOT EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING
--

local _G = _G
local date = date
local table = table
local time = time
local type = type
local unpack = unpack

local ADDON_NAME = ...
local PLAYER_FLAG = "CHAT_HISTORY_PLAYER_ENTRY"
local PLAYER_TEXT = "|TInterface\\GossipFrame\\WorkOrderGossipIcon.blp:0:0:1:-2:0:0:0:0:0:0:0:0:0|t "

local ENTRY_FLAG = 6
local ENTRY_GUID = 12
local ENTRY_EVENT = 30
local ENTRY_TIME = 31

ChatHistoryDB2 = {}

local addon = CreateFrame("Frame")
local Print, Save, Init, OnEvent

function Print()
	local temp

	addon.IsPrinting = true

	for i = #ChatHistoryDB2, 1, -1 do
		temp = ChatHistoryDB2[i]
		ChatFrame_MessageEventHandler(CHAT_FRAME, temp[ENTRY_EVENT], unpack(temp))
	end

	addon.IsPrinting = false
	addon.HasPrinted = true

	if temp then
		CHAT_FRAME:AddMessage("---- Last message received " .. date("%x at %X", temp[ENTRY_TIME]) .. " ----")
	end
end

function Save(event, ...)
	local temp = {...}

	if temp[1] then
		temp[ENTRY_EVENT] = event
		temp[ENTRY_TIME] = time()
		if event == "CHAT_MSG_SYSTEM" then
			temp[1] = tostring(PLAYER_TEXT..temp[1])
		end

		temp[ENTRY_FLAG] = PLAYER_FLAG

		table.insert(ChatHistoryDB2, 1, temp)

		for i = LOG_MAX, #ChatHistoryDB2 do
			table.remove(ChatHistoryDB2, LOG_MAX)
		end
	end
end

function Init()
	ChatHistoryDB2 = type(ChatHistoryDB2) == "table" and ChatHistoryDB2 or {}
	-- table.wipe(ChatHistoryDB2) -- DEBUG

	_G["CHAT_FLAG_" .. PLAYER_FLAG] = PLAYER_TEXT

	local oChatEdit_SetLastTellTarget = ChatEdit_SetLastTellTarget

	function ChatEdit_SetLastTellTarget(...)
		if addon.IsPrinting then
			return
		end

		return oChatEdit_SetLastTellTarget(...)
	end

	for i = 1, #EVENTS do
		addon:RegisterEvent(EVENTS[i])
	end

	if IsLoggedIn() then
		OnEvent(addon, "PLAYER_LOGIN")
	else
		addon:RegisterEvent("PLAYER_LOGIN")
	end
end

function OnEvent(addon, event, ...)
	if event == "ADDON_LOADED" then
		if ADDON_NAME == ... then
			addon:UnregisterEvent(event)
			Init()
		end
	elseif event == "PLAYER_LOGIN" then
		addon:UnregisterEvent(event)
		addon.PlayerGUID = UnitGUID("player")
		Print()
	elseif addon.HasPrinted then
		Save(event, ...)
	end
end

addon:RegisterEvent("ADDON_LOADED")
addon:SetScript("OnEvent", OnEvent)
