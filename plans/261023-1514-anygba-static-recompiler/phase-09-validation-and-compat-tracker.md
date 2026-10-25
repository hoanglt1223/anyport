---
phase: 9
title: "Validation and compatibility tracker"
status: completed
effort: 1-2w
dependsOn: [8]
---

# Phase 09: Validation and compatibility tracker

## Context

Prove the pipeline end to end and publish progress the way AnyPS5 does (badges and a per-game status page). The tracker is designed to be reused by AnySwitch.

## Requirements

- Automated suite in CI: gba-tests, armwrestler, golden-image PPU tests, a 60-second headless run of each homebrew title with a frame hash checkpoint.
- Headless mode (`--headless --frames N --dump-frame-hash`) in the runtime.
- Compatibility data in `compat/*.toml` (title, stage: boots/menus/in-game/playable/perfect, blockers, miss count), rendered by CI into a static `progress.html` and SVG badges.
- One commercial title, from the user's own dump, reaches "playable" locally. Nothing from it is committed except its TOML config (no ROM bytes, no hashes of copyrighted data beyond the ROM header ID).

## Files (create)

- `runtime/src/headless.cpp`
- `compat/schema.md`, `compat/*.toml`
- `tools/compat-site/` (static generator), `.github/workflows/pages.yml`

## Steps

1. Add headless mode and frame hashing.
2. Add CI suite jobs on all three hosts.
3. Build the compat schema and static site generator.
4. Bring up one commercial title through the trace-feedback loop; record blockers.
5. Write a short retro: what of this toolchain transfers to AnySwitch.

## Validation

- CI green on three hosts with the full suite.
- Plan acceptance criteria in `plan.md` all met.

## Risks

- Frame hashes differ across compilers because of floating point in the resampler. Hash video only, not audio.

## Rollback

CI and docs only; revert.

## Implementation status

Done: `--dump-frame-hash` in the game `main()` (no separate `headless.cpp`), `compat/` with 50 titles
and `schema.md`, checkpoint tests (`ANYGBA_COMPAT_TESTS=ON`, `ctest -L compat`),
`tools/compat-site/generate.py`, `pages.yml`, a compat job on three hosts in `ci.yml`, and
`docs/dev/RETRO.md`.

Step 4: Pokemon Emerald from the user's dump (`compat/pokemon-emerald.toml`, `rom_id` only) is
`playable`: real-time clock, trace-feedback passes that check compiled RAM code against its source
bytes, in-game Flash saves, and pictures that match mGBA from boot to the first battle.

- [x] CI green on three hosts with the full suite: CI run 40168774943 on main `93fa1f8` (2026-10-25) is green on every job: windows-msvc, windows-clang-cl, linux-gcc, linux-clang, macos-arm64, compat-windows-msvc, compat-linux-gcc, compat-macos-arm64 and android.
- [x] Linux box 2026-10-25 (branch `chore/plan-closeout`): all 41 compat checkpoints pass
  (`ctest -L compat -j4`); the full ctest, slow tests included (`mcp-e2e`, `feedback-*`, golden
  images in `unit-tests`), passes except `video-timing`, which needs an idle machine (phase 11);
  `tools/compat-site/generate.py` (50 titles) and `site/build.py --check` pass.
- [x] Plan acceptance criteria met: jsmolka gba-tests on three hosts (CI), homebrew titles at full
  speed with checkpoints (compat), Emerald boots to gameplay with saves (playable), HLE BIOS only.
