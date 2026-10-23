---
phase: 8
title: "Saves, input, packaging, per-game config"
status: pending
effort: 1w
dependsOn: [5, 6, 7]
---

# Phase 08: Saves, input, packaging, per-game config

## Context

This phase turns a working recompile into a usable native game: persistent saves, configurable controls, and a single command that goes from ROM to executable.

## Requirements

- Save type detection from ROM strings (`SRAM_V`, `FLASH_V`, `FLASH512_V`, `FLASH1M_V`, `EEPROM_V`) with config override.
- SRAM (32 KB), Flash 64/128 KB (command state machine, bank switch, chip IDs), EEPROM 512 B / 8 KB (serial protocol over DMA 3, size inferred from DMA length).
- Saves written to the per-user data directory (`SDL_GetPrefPath`), flushed on change after a short debounce and on exit.
- Input mapping file `anygba-input.ini` (keyboard and SDL gamepad), modelled on AnyPS5's input mapping.
- `anygba build game.gba` runs recomp, configures CMake, compiles, and outputs `GameTitle.exe` / `GameTitle` / `GameTitle.app`. ROM data sections (graphics, audio) are embedded in the binary from the user's ROM at build time.
- Per-game TOML: entry points, RAM code regions, save type, patches (address → replacement C function) for hacks.

## Files (create)

- `runtime/src/save/sram.cpp`, `save/flash.cpp`, `save/eeprom.cpp`, `save/detect.cpp`
- `runtime/src/input_map.cpp`
- `tools/anygba/main.cpp` (driver CLI), `tools/anygba/build.cpp`
- `docs/user/USAGE.md`, `docs/user/INPUT_MAPPING.md`

## Steps

1. Implement save types and detection; persist through the platform layer.
2. Implement input mapping file loading.
3. Implement the `anygba build` driver and the macOS `.app` bundle with ad-hoc signing.
4. Write user docs.

## Validation

- A homebrew title using each save type keeps its save across restarts.
- `anygba build` produces a runnable exe from a clean checkout on each host.

## Risks

- EEPROM size misdetection corrupts saves. Back up the previous save file before every write.

## Rollback

Revert modules; saves are user files and never deleted by the tool.
