# SickTrick

Tony Hawk-style trick callouts for WoW Retail. Jump, spin your character mid-air, and on landing SickTrick prints the trick to your own chat frame: `SickTrick: Frontside 720!`

Cosmetic only. It reads your facing and falling state and prints locally. It only posts publicly if you turn on `/sicktrick announce`, and it never calls protected functions or automates anything.

## Install

Copy the `SickTrick` folder to:

```
World of Warcraft/_retail_/Interface/AddOns/SickTrick
```

Then `/reload` or restart the game. If the addon shows as "out of date", check the build number with `/dump select(4, GetBuildInfo())` and update `## Interface:` in `SickTrick.toc`.

## Commands

| Command | Effect |
| --- | --- |
| `/sicktrick` | Toggle on/off (also ends a silence) |
| `/sicktrick on` / `/sicktrick off` | Turn on or off (`on` also ends a silence) |
| `/sicktrick silence` | Mute callouts for 1 hour, even across `/reload` and logout. Run it again to unmute early |
| `/sicktrick announce` | Toggle posting tricks as a public emote, e.g. "Chris lands a Frontside 720!" (off by default). `on`/`1` and `off`/`0` set it explicitly |
| `/sicktrick test` | Preview a random trick callout (only you see it, even with announce on) |
| `/sicktrick debug` | Toggle debug prints (jump start, abort reasons, final degrees) |
| `/sicktrick help` | List commands |

You can also toggle from the minimap addon compartment menu, or bind a key under Key Bindings → AddOns → SickTrick.

Settings are saved per account in `SickTrickDB`.

## Scoring

Rotation is summed frame by frame while airborne and rounded down to the nearest 180° on landing, with 25° of slack (so 340° counts as a 360). Counterclockwise spins are "Frontside", clockwise spins are "Backside".

| Rotation | Callout |
| --- | --- |
| 180° | 180! |
| 360° | 360! |
| 540° | 540! |
| 720° | 720! |
| 900° | THE 900! |
| 1080°+ | 1080! Sick trick bro!!!! |

## Known limits

- **Character facing only.** Turning with right-click drag (mouselook) or the keyboard counts. Left-click drag only orbits the camera, so it doesn't count.
- **Silent in instances.** `GetPlayerFacing()` returns nil in dungeons, raids, battlegrounds and arenas, so the addon does nothing there.
- **Announce uses emote, not `/say`.** WoW only lets addons post to Say and Yell from a key press or click, and a landing isn't one. Emotes have no such limit. To avoid spam, at most one emote goes out every 5 seconds.
- Jumps that turn into flying or Skyriding, or that end in water, are discarded. Walking off a ledge isn't a jump, so it isn't tracked.

## Development

Lint with [luacheck](https://github.com/lunarmodules/luacheck) from the repo root (config in `.luacheckrc`):

```
luacheck SickTrick
```
