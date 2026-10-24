# AnyGBA: Pokemon Emerald to playable (+ merges and player requests)

**RTC first (as asked):** `49b0fd7 feat(runtime): cartridge real-time clock`. It was verified headless before anything else: "The internal battery has run dry" appears with `--rtc off` and is gone by default, and the in-game wall clock shows the configured time.

All work is committed locally on `main` in `repos/anygba`; nothing is pushed by me. The lead tagged v0.2.0 on `1afd26e`.

## Outcome

| Task | Result | Commit |
|---|---|---|
| 1. RTC | S-3511 on GPIO 0x080000C4-C9, host local time (`--rtc-start T` gives a fixed clock that advances with emulated time). On by game code (Ruby/Sapphire/Emerald, Boktai 1-3, Rockman EXE 4.5, Sennen Kazoku), `[game] rtc` and `--rtc on/off` override it. Part of save states (format version 2). | 49b0fd7 |
| 2. Stale RAM code | Each generated RAM function records the ROM source of its bytes (`code_src`). `AG_ENTER_RAM` and the dispatcher compare RAM with that source on every entry; if it differs, the code is interpreted. Feedback is safe again for Emerald: interpreted entry points went 2910 → 1832 → 5 over boot to the first wild encounter, about 375 → 610-670 frames/s unpaced. | a05d6bc, 12862ff (docs) |
| Long work dirs | `anygba build` puts the CMake tree in `%TEMP%\anygba-<crc32>` when its path is over 80 characters. The MSBuild 260-character failure reproduced without the fix and passed with it. | 7c90097 |
| 3. mGBA comparison | An mGBA 0.10.5 libretro core was built at `D:\t\mo\Release\mgba_libretro.dll` and fed one scripted input list from boot to the first battle. The truck (frame 10000) and Route 101 (frame 30807) are pixel-identical. The naming screen, Littleroot and the battle differ only in animation phase, typed letters, a walking NPC and the random gender of both Pokemon; mGBA runs a few frames behind. No rendering mismatch was found, so no fix was needed. | – |
| 4. Wild species picker | Raw codes at `08xxxxxx` are now ROM patches (16/32-bit, as in VBA). `Wild Pokemon/Wild Pokemon species of your choice` rewrites `CreateWildMon`'s species with `movs r6,#a; adds r6,#b`; the list has 386 species. Checked headless on Route 101: at the same step the encounter was Ralts (392) and Pikachu (25) instead of Zigzagoon. | 95fc11e |
| 5. Compat | `compat/pokemon-emerald.toml`: stage `playable` (schema: pictures match mGBA where checked), no blockers, misses 5. | 03a32b6 |

## Merges done for the lead

- `4d50825` feat/video-filters. `76356cf` keeps the user's data folder out of player tests: `ANYGBA_DATA_DIR` replaces the data folder, which fixes the `player-menu` failure caused by the user's own remapped `anygba-input.ini`.
- `664041e` feat/android. Both branches defined a platform `Overlay` and `Rect`, so the touch-controls ones are now `ScreenOverlay` and `FRect`, and the touch layer also draws on the filtered `present_rgba` path. `9099d92` fixes the NDK build (it has no floating-point `from_chars`). The arm64 runtime and an armwrestler APK build.
- `322932d` feat/agent-control. The menu has both Video and Settings pages, and rows now act on their id; this also fixed a merge fall-through. F10/F11 do not collide with any video hotkey. `46c8bfe`: compat titles link only when their source is a URL, so `site/build.py --check` is clean.
- `ccc6242` feat/hd-graphics. Build copies cheats, symbols and widescreen rules; the HD frame path is kept next to the stats overlay counting. `cd0ad01` fixes the HD code for Android: `strtod` instead of `from_chars`, and no `posix_spawn` before API 28.
- Full ctest after the last merge and again at the end (HEAD `3b031e0`): 65/65, including the slow tests.

## Coordinator requests

- `6bec09a` VisualBoyAdvance default keys: Z=A, X=B. Tests, USAGE, INPUT_MAPPING and the site guides are updated; the site table's stale Q/W/Tab keys are fixed too.
- Player features, done by a subagent:
  - `1e3d976` fast-forward at a set speed (150-800% or unlimited, default 300%) with resampled sound.
  - `25ff850` Ctrl+F stats overlay.
  - `7f1a859` normal-speed MP2K music while fast-forwarding. Emerald's measured tempo ratio is 1.000 at 300%; other games get time-stretch.
  - `d3b7cc5` save folder setting, retrying writes on sharing violations.
  - `fc0707c` `.sav` import/export. Windowed parts (overlay drawing, SDL file dialogs, audible time-stretch quality) are untested on this PC. The user's OneDrive folder is not set yet: copy the saves there, then set Options > Save folder.
- Emerald cheat database, done by a subagent (commits `21391d3`, `1b6c137`, `717c4e8`, `7711db6`, `0b3ab82`, `992a831`, `c590b87`). Each cheat was checked against the same run without it:
  - EXP x2/x3/x5/x10/x255, infinite HP, infinite PP, one-hit KO, every ball catches.
  - Wild level picker, encounter rate never/always, shiny.
  - All badges (new raw `TARGET|VALUE` bit-set), walk through walls, field moves without badges, complete Pokedex.
  - Perfect IVs, max EVs, max friendship, fast hatching, all berries, infinite Safari Balls and steps.
  - Dropped: a separate instant level-100 cheat, because the game caps a single EXP award at 32767. x255 and Rare Candy cover it.
- HD follow-ups (ONNX download OSD and cancel, wider Emerald battles, edge pop-in): done by a subagent.
  - `6dd25b0`: the ONNX download shows progress on the OSD and is cancelled when AI is turned off. The game keeps running; a cancelled or failed download leaves no partial file and the game keeps drawing without AI. Tests use `ANYGBA_AI_MIRROR` with file:// and a stalled socket.
  - `216a82d`: Emerald battles widen at 16:9 and 16:10 (BattleMainCB2 rule; BG0 text-box edge repeated), shown in screenshots in `out/em/ws/`. The battle transition and setup screens stay pillarboxed, and full-screen move-animation backgrounds were not seen.
  - `3b031e0`: the edge pop-in (Emerald hides objects 16 px past its screen, 16:9 shows 22 px) is documented, not fixed. A culling patch showed no measurable difference in the headless walks, so it was not shipped.

## Tests added

- `tests/runtime/rtc_tests.cpp` covers the BCD date/time, status writes and reset, the port reading back only when enabled, clock-cartridge detection, save state, and host local time.
- `codegen_tests` checks `AG_ENTER_RAM`, and `config_tests` checks the `rtc` field in `dispatch.c`.
- `cheat_tests` covers raw ROM patches (16/32-bit, odd address and 8-bit refused).

## Concerns

- AnyGBA and mGBA drift by up to about 30 frames mid-intro and resynchronise at input waits. AnyGBA and its feedback build also diverge from each other in exact frames, because compiled and interpreted code count cycles differently. Pictures match; exact timing does not.
- `ram_code_valid` runs a binary search and a `memcmp` on every RAM-function entry. Emerald is still faster after feedback, but a game that calls large RAM functions very often would pay for it.
- The title screen was not matched against mGBA (it animates continuously and the offset is larger than the ±12-frame window), so it was only checked visually.
- `unit-tests` once failed under `ctest -j8` and passed alone. It could not be reproduced afterwards and may be a timing-sensitive test under load.

## Resume from here

- Scratch (git-ignored; holds ROM-derived files, never commit): `repos/anygba/out/em`.
  - `em5.exe`: current runtime, feedback logs `all2.log`.
  - `full.py` / `full-script.txt` / `full-mgba.txt`: boot to first battle, for AnyGBA and the mGBA oracle.
  - `seq.py`: runs a step list from a state.
  - States: `st1`..`st51.ss`. `st40` is the first battle and `st51` is Route 101 grass.
- mGBA oracle core: `D:\t\mo\Release\mgba_libretro.dll`. pokeemerald symbols: `D:\t\pe.sym`.
- Next: push and confirm CI on all platforms. Try the windowed parts (stats overlay, file dialogs, fast-forward sound) on a machine with a display. Check the HD follow-up results above.

Status: DONE_WITH_CONCERNS
Summary: Emerald is playable. It has the RTC and safe feedback passes (5 interpreted entry points left), pictures that match mGBA from boot to the first battle, and a verified wild-species picker. All four branches are merged, and the requested player and cheat features are in. Concerns: the windowed paths are untested on this headless PC, the Emerald edge pop-in is documented but not fixed, and AnyGBA's frame timing differs from mGBA by a few to about 30 frames.
