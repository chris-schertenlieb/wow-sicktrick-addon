std = "lua51"
max_line_length = false

-- `local ADDON_NAME, ns = ...` is used in every file by convention.
ignore = { "211/ADDON_NAME" }

globals = {
	"SickTrickDB",
	"SickTrick_OnCompartmentClick",
	"SLASH_SICKTRICK1",
	"BINDING_HEADER_SICKTRICK",
	"BINDING_NAME_SICKTRICK_TOGGLE",
	SlashCmdList = { fields = { "SICKTRICK" } },
}

read_globals = {
	"C_ChatInfo",
	"CreateFrame",
	"date",
	"DEFAULT_CHAT_FRAME",
	"GetPlayerFacing",
	"GetTime",
	"hooksecurefunc",
	"IsFalling",
	"IsFlying",
	"IsSwimming",
	"issecretvalue",
	"SendChatMessage",
	"strtrim",
	"time",
}
