local ADDON_NAME, ns = ...

-- Tunables ------------------------------------------------------------------

local GROUND_TIMEOUT = 0.3 -- seconds without IsFalling() before a jump is dropped
local MAX_AIRTIME    = 30  -- seconds; safety cap on a single tracked jump
local TIER_STEP      = 180 -- degrees per scoring tier
local MIN_TIER       = 180 -- smallest tier that gets announced
local TEST_MAX_STEPS = 6   -- /sicktrick test picks a tier in 180..TEST_MAX_STEPS*180
local SILENCE_SECONDS = 60 * 60 -- /sicktrick silence duration

local DEFAULTS = {
	enabled   = true,
	chat      = true,
	announce  = false, -- also post tricks as a public emote
	popup     = true,  -- phase 2
	sound     = false, -- phase 3
	direction = true,  -- Frontside/Backside prefix
	slack     = 25,    -- degrees
	debug     = false,
	best      = 0,     -- highest tier landed (phase 3)
	silencedUntil = 0, -- time() when /sicktrick silence ends; survives /reload
}

BINDING_HEADER_SICKTRICK      = "SickTrick"
BINDING_NAME_SICKTRICK_TOGGLE = "Toggle SickTrick"

------------------------------------------------------------------------------

local TWO_PI = 2 * math.pi

-- Wrap a facing delta so crossing north never counts as a full turn.
local function wrapDelta(d)
	return (d + math.pi) % TWO_PI - math.pi -- Lua % is floored: result in [-pi, pi)
end

-- GetPlayerFacing() is nil in instances. Also bail if a future patch makes it
-- a Midnight secret value, so arithmetic on it can never throw.
local function readFacing()
	local f = GetPlayerFacing()
	if f == nil or (issecretvalue and issecretvalue(f)) then
		return nil
	end
	return f
end

local function isSilenced()
	return ns.db.silencedUntil > time()
end

-- Jump state ----------------------------------------------------------------

local tracker = CreateFrame("Frame") -- no size or textures, so never visible
local tracking = false
local last, total, elapsed, sawFall = 0, 0, 0, false

local function stopTracking(reason)
	if not tracking then return end
	tracking = false
	tracker:SetScript("OnUpdate", nil)
	if reason then
		ns.Debug("abort: %s (%.0f° so far)", reason, math.abs(math.deg(total)))
	end
end

local function score(totalRad)
	local deg = math.abs(math.deg(totalRad))
	local tier = math.floor((deg + ns.db.slack) / TIER_STEP) * TIER_STEP
	ns.Debug("landed: %.1f° -> tier %d", deg, tier)
	if tier >= MIN_TIER then
		ns.Announce(tier, totalRad > 0)
	end
end

local function onUpdate(_, dt)
	local f = readFacing()
	if not f then return stopTracking("facing unavailable") end
	if IsFlying() then return stopTracking("started flying") end
	if IsSwimming() then return stopTracking("entered water") end

	total = total + wrapDelta(f - last)
	last = f
	elapsed = elapsed + dt

	local falling = IsFalling()
	if falling then sawFall = true end

	if not sawFall then
		if elapsed > GROUND_TIMEOUT then
			stopTracking("never left the ground")
		end
		return
	end

	if not falling then
		local landedTotal = total
		stopTracking()
		score(landedTotal)
		return
	end

	if elapsed > MAX_AIRTIME then
		stopTracking("airtime cap")
	end
end

local function onJump()
	local db = ns.db
	if not db or not db.enabled or tracking or isSilenced() then return end
	if IsFlying() or IsSwimming() then return end
	local f = readFacing()
	if not f then return end

	tracking = true
	last, total, elapsed, sawFall = f, 0, 0, false
	tracker:SetScript("OnUpdate", onUpdate)
	ns.Debug("jump start (facing %.2f rad)", f)
end

-- Post-hook only; JumpOrAscendStart is protected and is never called here.
hooksecurefunc("JumpOrAscendStart", onJump)

-- Toggling ------------------------------------------------------------------

-- Turning on also ends any silence, so "on" always means "talking again".
local function setEnabled(on)
	ns.db.enabled = on
	if on then
		ns.db.silencedUntil = 0
	else
		stopTracking()
	end
	ns.Print(on and "enabled." or "disabled.")
end

-- A silenced addon counts as off, so toggling it turns it back on.
function ns.Toggle()
	if not ns.db then return end
	setEnabled(not ns.db.enabled or isSilenced())
end

local function toggleSilence()
	if isSilenced() then
		ns.db.silencedUntil = 0
		ns.Print("silence lifted.")
		return
	end
	ns.db.silencedUntil = time() + SILENCE_SECONDS
	stopTracking()
	ns.Print(("silenced for %d minutes (until %s). Run /sicktrick silence again to undo.")
		:format(SILENCE_SECONDS / 60, date("%H:%M", ns.db.silencedUntil)))
end

local ON_WORDS  = { on = true, ["1"] = true }
local OFF_WORDS = { off = true, ["0"] = true }

-- No argument toggles; on/1 and off/0 set it explicitly.
local function setAnnounce(arg)
	local on
	if arg == "" then
		on = not ns.db.announce
	elseif ON_WORDS[arg] then
		on = true
	elseif OFF_WORDS[arg] then
		on = false
	else
		ns.Print("usage: /sicktrick announce [on | off]")
		return
	end
	ns.db.announce = on
	ns.Print(on and "announce on: tricks are also posted as an emote nearby players can see."
		or "announce off: tricks are only shown to you.")
end

-- Addon compartment click; also called by the Bindings.xml keybind.
function SickTrick_OnCompartmentClick()
	ns.Toggle()
end

-- Slash commands ------------------------------------------------------------

local HELP = {
	"Commands:",
	"/sicktrick - toggle on/off",
	"/sicktrick on | off - turn on or off (on also ends a silence)",
	("/sicktrick silence - mute callouts for %d minutes (run again to unmute)"):format(SILENCE_SECONDS / 60),
	"/sicktrick announce [on | off] - also post tricks as an emote nearby players see",
	"/sicktrick test - preview a random trick callout",
	"/sicktrick debug - toggle debug prints",
	"/sicktrick help - list these commands",
}

local function printHelp()
	for _, line in ipairs(HELP) do
		ns.Print(line)
	end
end

SLASH_SICKTRICK1 = "/sicktrick"
SlashCmdList.SICKTRICK = function(msg)
	if not ns.db then return end
	local cmd, arg = strtrim(msg or ""):lower():match("^(%S*)%s*(.-)$")

	if cmd == "" then
		ns.Toggle()
	elseif cmd == "on" then
		setEnabled(true)
	elseif cmd == "off" then
		setEnabled(false)
	elseif cmd == "silence" then
		toggleSilence()
	elseif cmd == "announce" then
		setAnnounce(arg)
	elseif cmd == "test" then
		ns.Announce(math.random(1, TEST_MAX_STEPS) * TIER_STEP, math.random(2) == 1, true)
	elseif cmd == "debug" then
		ns.db.debug = not ns.db.debug
		ns.Print("debug " .. (ns.db.debug and "on." or "off."))
	elseif cmd == "help" then
		printHelp()
	else
		ns.Print(("unknown command '%s'."):format(cmd))
		printHelp()
	end
end

-- Events --------------------------------------------------------------------

tracker:RegisterEvent("ADDON_LOADED")
tracker:RegisterEvent("PLAYER_ENTERING_WORLD")
tracker:RegisterEvent("PLAYER_DEAD")
tracker:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 ~= ADDON_NAME then return end
		SickTrickDB = SickTrickDB or {}
		for k, v in pairs(DEFAULTS) do
			if SickTrickDB[k] == nil then SickTrickDB[k] = v end
		end
		ns.db = SickTrickDB
		self:UnregisterEvent("ADDON_LOADED")
	elseif event == "PLAYER_ENTERING_WORLD" then
		stopTracking("zoned")
	elseif event == "PLAYER_DEAD" then
		stopTracking("died")
	end
end)
