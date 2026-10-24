# AnyGBA player features: save states, speed, cheats, menu, controls

Date: 2026-10-24 (Asia/Saigon). Repo: `repos/anygba`, 14 local commits on top of `b1ea0d5`
(`bb5c82f`..`a09374a`), not pushed or tagged. Plan: `phase-10-player-features.md` (completed), row 10 in
`plan.md`; phase 09 step 4 updated.

## Outcome

Every generated game now has VisualBoyAdvance-style save states, 100-400% speed, GameShark / Action Replay
/ CodeBreaker / raw cheats, an in-game menu (cheat tree with value pickers, typed codes, state slots,
speed, Controls page), on-screen messages, gamepad hot-plug and chords, and scripted headless input.
Pokemon Emerald from the user's dump reaches gameplay through `anygba build`, saves to its 128 KB Flash,
round-trips save states, and has a curated cheat database checked in memory and on screen.

Verification (Windows, MSVC, `out/msvc` with compat tests on): **60/60 CTest pass** including `slow`
(driver build, two feedback passes) and all 41 compat checkpoints; 107 doctest cases pass.

## Design decisions

- **Save states at safe points.** Snapshots are taken at the end of an outermost `tick()` (where `AG_TICK`
  has stored the exact next PC) or inside a BIOS Halt/IntrWait before its interrupt (resumed by running
  the SWI again). Both save and load then unwind to the dispatcher, so the saving run and every loading
  run follow the same path; frames after a load repeat the frames after the save exactly. Versioned file
  with ROM SHA-256 and CRC-32; a failed load changes nothing. `docs/dev/SAVE-STATES.md`.
- **ROM patch cheats with compiled code.** The recompiler records each function's ROM code footprint
  (instructions, folded literals, jump tables) and emits `AG_ENTER` at every ROM function. Functions whose
  footprint holds a patch are bypassed (lookup and direct calls) and run in the interpreter.
  `docs/dev/CHEATS.md`.
- **Speed.** Audio-led pacing kept; each frame's sound is resampled by the speed factor (continuous phase
  across frames), so the queue drains at the same rate. Fast-forward hold drops sound instead.
- **Raw format extension.** `[PTR]+OFF:VALUE` and `VALUE^TARGET`, because Emerald moves its save data and
  XOR-encrypts money/coins/bag quantities with a per-save key (key measured on the ROM: random, not 0).
- **libretro cheats** are CC BY-SA 4.0: not committed. `tools/cheats/import-libretro.py` fetches a pinned
  commit and converts 488 of 513 GBA lists into 910 CRC-keyed databases; 11,900 of 12,397 codes decode
  (96%), the rest are typos in the lists, skipped with warnings.

## Bugs found and fixed along the way

- `reset()` left instruction fetch costs at 0 until a game wrote WAITCNT (games that never write it ran
  for free). Found because load_state recomputed them. Three tonc checkpoints re-recorded; prio_demo and
  swi_vsync still match the interpreter, txt_se2 (timing benchmark) as before does not.
- Struct padding made state files non-deterministic; all padded structs are now written field by field.
- Codegen emitted `goto` to a label whose instruction was never decoded (Emerald, after feedback).
- Stale `funcs_NNN.c` shards from an earlier, larger run broke rebuilds.
- Delayed snapshots: games asleep in VBlankIntrWait rarely ended a tick outside their IRQ
  handler, so the BIOS-wait safe point was added.

## Pokemon Emerald (user's dump, scratch folders only)

- `anygba build`: 332 functions found statically; 240-490 frames/s unpaced. Intro, Birch, naming, truck
  scene with player control at frame ~10000 (pictures checked). Start menu, in-game save (56 KB of Flash
  written), restart shows CONTINUE with the saved player and time: **phase 09 step 4 reached `in-game`**.
- Save state at frame 10000, loaded in a new process: identical frame hash at 10100.
- `cheats/BPEE.toml`: max money, money picker, coins, Master Ball x99, ball/item/PC-item pickers, Rare
  Candy, PP Up, vitamin picker. All verified by reading SaveBlock memory (money 999999 and 123456 after
  XOR, items x99 in the right pockets); the bag screen shows ELIXIR/RARE CANDY/PP UP/ZINC x99; turning
  Master Ball x99 on through the menu with scripted keys works and is saved to the cheat file.
- `compat/pokemon-emerald.toml` committed with `rom_id` only (the schema forbids hashes for commercial
  titles; nothing from the ROM is in the repo).
- Not done: **wild encounter species picker**. Wild Pokemon are created into encrypted, checksummed party
  data, so a RAM code cannot set the species, and a code patch needs disassembly work I could not verify
  in this session. No unverified codes were added.

## Tests added

| Test | What it proves |
|---|---|
| `state_tests.cpp` | complete state, picture and sound repeat frame by frame after a load (3 demos); bad files rejected without change; identical runs give identical files |
| `cheat_tests.cpp` | TEA decryption against published Emerald and Mario & Luigi master codes; auto-detection; every op type in all formats; ROM patches; raw pointer/XOR |
| `player_tests.cpp` | resampler length and continuity at 1-4x; hotkey chords and modifiers; pad chords; scripts; rebind swap; database, slots and cheat file round trip; menu navigation; OSD; opt-in import check (`ANYGBA_CHEAT_DB_DIR`) |
| `codegen_tests.cpp` | undecoded branch target exits via r[15]; AG_ENTER and footprints |
| `player-states` | swi_vsync (animated): save at 120, `--load-state` in a new process and in-process load at 250 give the same hash at 400 |
| `player-cheats` | all formats incl. encrypted and joypad codes checked in EWRAM; ROM patch on a folded literal of compiled code moves the pixel in VRAM |
| `player-menu` | scripted keys drive the whole menu; memory, cheat file and input file checked; persistence on the next run; gamepad connect, Back+Start, stick |
| `player-speed` | 240 paced frames: 2.00 s at 200%, 1.00 s at 400%; hotkeys step and clamp |

## Concerns

- Windowed playback, real audio at 200-400%, the drawn menu and real gamepads are untested (headless-only
  PC); the same code paths run headless in the tests.
- CodeBreaker encryption has no published test vector; it is only checked for determinism.
- `DEADFACE` reseed codes are refused (their tables are not public).
- The save-state and cheat-engine commits were split from one working tree by staging partial file
  versions; only the final tree was built and tested, not each intermediate commit.
- Emerald feedback pass: the miss log contains code Emerald copies onto its stack (0x03007Dxx); compiled,
  it goes stale and the game stops with an undefined instruction. Generic risk for any game that runs
  code from RAM that changes; needs a content check for RAM functions or excluding stack addresses from
  feedback.
- No real-time clock (Emerald shows "battery has run dry"; time-based events do not run).

## Resume from here

- Push and confirm CI on Linux/macOS (new tests need the corpus; `player-speed` is RUN_SERIAL, bounds
  0.8-1.6 s / 1.6-3.0 s).
- Try the player with a window, sound and a gamepad on a machine that has them (menu drawing, OSD,
  resampled audio at 400%, hot-plug).
- Emerald to `playable`: fix RAM-code staleness in feedback (validate RAM function bytes before
  dispatch, or skip stack-region misses), add RTC (GPIO at 0x080000C4), compare pictures with mGBA.
- Wild encounter species for Emerald: find `CreateWildMon`'s species load in the ROM and design a
  verified code patch (ROM patches already run through the interpreter correctly).
- Scratch artefacts (not in the repo): Emerald build, states and frames under the session scratchpad
  `emerald/`; libretro conversions under `libretro-cheats/`.

Status: DONE_WITH_CONCERNS
Summary: Save states (exact frame repeat after load via safe points), 100-400% speed with resampled audio,
all four cheat formats with encryption and ROM patches through the interpreter, the cheat/controls menu,
gamepad support, scripted headless input, docs and 60/60 passing tests are committed; Pokemon Emerald
reaches gameplay with Flash saves, states and verified curated cheats. Concerns: windowed/audio paths are
untested on this PC, no Emerald wild-species picker, Emerald's feedback pass and RTC remain blockers.
