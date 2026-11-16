local ADDON_NAME, ns = ...

-- Tunables ------------------------------------------------------------------

local PREFIX       = "|cffffcc00SickTrick:|r "
local DEBUG_PREFIX = "|cff999999SickTrick debug:|r "

local DIR_CCW = "Frontside " -- counterclockwise (turning left)
local DIR_CW  = "Backside "  -- clockwise (turning right)

-- %s is the direction prefix ("" when the direction setting is off).
local CALLOUTS = {
	[180] = "%s180!",
	[360] = "%s360!",
	[540] = "%s540!",
	[720] = "%s720!",
	[900] = "THE %s900!",
}
-- Anything above the table: %s = direction, %d = tier.
local CALLOUT_BEYOND = "%s%d! Sick trick bro!!!!"

-- /sicktrick announce: public emote, shown as "<Name> lands a Frontside 720!".
-- Emote rather than /say: addons may only /say from a key press or click, and
-- a landing isn't one.
local EMOTE_TEMPLATE     = "lands a %s"
local EMOTE_TEMPLATE_THE = "lands %s" -- callouts that already start with "THE"
local EMOTE_COOLDOWN     = 5          -- seconds between public emotes

------------------------------------------------------------------------------

function ns.Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. msg)
end

function ns.Debug(fmt, ...)
	if ns.db and ns.db.debug then
		DEFAULT_CHAT_FRAME:AddMessage(DEBUG_PREFIX .. fmt:format(...))
	end
end

function ns.Callout(tier, counterclockwise)
	local dir = ""
	if ns.db and ns.db.direction then
		dir = counterclockwise and DIR_CCW or DIR_CW
	end
	local template = CALLOUTS[tier]
	if template then
		return template:format(dir)
	end
	return CALLOUT_BEYOND:format(dir, tier)
end

-- SendChatMessage is deprecated since 11.2 in favour of C_ChatInfo's version.
local SendChat = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
local lastEmote = -math.huge

local function emote(callout)
	local now = GetTime()
	if now - lastEmote < EMOTE_COOLDOWN then
		ns.Debug("emote skipped: cooldown")
		return
	end
	lastEmote = now
	local template = callout:find("^THE ") and EMOTE_TEMPLATE_THE or EMOTE_TEMPLATE
	SendChat(template:format(callout), "EMOTE")
end

-- Popup (phase 2) and sound (phase 3) hook in here. A preview (/sicktrick test)
-- is never sent publicly.
function ns.Announce(tier, counterclockwise, preview)
	if not ns.db then return end
	local callout = ns.Callout(tier, counterclockwise)
	if ns.db.chat then
		ns.Print(callout)
	end
	if ns.db.announce and not preview then
		emote(callout)
	end
end
