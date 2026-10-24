---
phase: 10
title: "Player features: save states, speed, cheats, menu, controls"
status: completed
effort: 1-2w
dependsOn: [8]
---

# Phase 10: Player features: save states, speed, cheats, menu, controls

## Context

The user wants generated games to play like VisualBoyAdvance: fast-forward at 200/300/400%, save and
load states, and GameShark/Action Replay/CodeBreaker cheats, plus an in-game menu with a cheat tree,
in-game key rebinding, and gamepad support. Static recompilation makes states hard: compiled code keeps
part of the machine's progress in host call frames, so snapshots need resumable safe points.

## Requirements

- Speed 100-400% by hotkey, `--speed` and the input file; an unthrottled hold key; sound resampled, never
  piling up.
- Nine state slots (Shift+F1-F9 save, F1-F9 load) next to the save file; versioned format with the ROM's
  SHA-256; frames after a load repeat the frames after the save.
- Cheats: GameShark v1/v2, Action Replay v3, CodeBreaker, raw; encrypted forms reimplemented from
  GBATEK (MIT, no GPL code); RAM writes, conditions, button codes, ROM patches that work with compiled
  code. From the menu (database tree with value pickers, typed codes), a per-game file, the command line.
  Cheat databases keyed by game code and CRC; a libretro importer (data not shipped: CC BY-SA); a
  curated Pokemon Emerald database verified on the user's ROM.
- Menu with a Controls page (rebind with conflict swap, reset, saved to the input file); hotkeys and
  gamepad chords in the input file; gamepad hot-plug, `gamecontrollerdb.txt`, stick as d-pad; on-screen
  messages.
- Headless tests with scripted input for every feature.

## Files

- `runtime/src/state/`, `runtime/src/cheats/`, `runtime/src/player/`, `runtime/src/rom_patch.cpp`,
  `runtime/src/input_map.*`, `runtime/src/main.cpp`, `runtime/include/anygba/{cpu.h,system.hpp}`
- `tools/recomp/codegen/` (AG_ENTER, code footprints), `tools/anygba/build.cpp`, `tools/cheats/`
- `platform/` input additions, `cheats/BPEE.toml`, `compat/pokemon-emerald.toml`
- `tests/runtime/{state,cheat,player}_tests.cpp`, `tests/player-*.cmake`, `tests/player/`
- `docs/dev/{SAVE-STATES,CHEATS}.md`, `docs/user/{CHEATS,USAGE,INPUT_MAPPING}.md`, README

## Steps

- [x] Save states: serialization, safe points at tick ends and BIOS waits, unwind on save and load
- [x] Speed control with resampled sound and paced headless runs
- [x] Cheat decoding, decryption, engine; ROM patches through the interpreter (AG_ENTER, footprints)
- [x] Cheat databases, per-game cheat file, raw pointer/XOR extension, libretro importer
- [x] Menu, OSD, hotkeys, gamepad chords, rebinding, scripted input
- [x] Pokemon Emerald: anygba build, gameplay, Flash save, states, curated cheats verified in memory
- [x] Tests and docs

## Validation

- `tests/player-states.cmake`: save at a frame, load in the same run and in a new process; frame hashes
  match the saving run (tonc swi_vsync, animated). Unit test compares complete state, picture and sound
  frame by frame after a load for three demos.
- `tests/player-cheats.cmake`: every format incl. encrypted codes and joypad conditions, checked in EWRAM;
  a ROM patch on a folded literal of compiled code moves a pixel.
- `tests/player-menu.cmake`: scripted keys drive the cheat tree, picker, code entry and rebinding; cheat
  file, input file and memory checked; a scripted gamepad opens the menu with Back+Start.
- `tests/player-speed.cmake`: 240 paced frames take 2.0 s at 200% and 1.0 s at 400%.

## Risks

- Windowed audio at high speed, the drawn menu, and real devices are untested on this PC (headless only).
- CodeBreaker encryption has no published test vector.
- Pokemon Emerald: no real-time clock; a feedback pass compiles code the game copies onto its stack.

## Implementation status

Done on Windows (repo commits from `8ff13ee` to the docs commit). Save states, speed, cheats, menu and
controls work in generated games; Emerald reaches gameplay with a working Flash save. Found and fixed on
the way: zero fetch costs until a game wrote WAITCNT, a goto to an undecoded label, stale code shards.
Open: RTC, the stack-copied-code feedback problem, windowed checks on a machine with a display.
