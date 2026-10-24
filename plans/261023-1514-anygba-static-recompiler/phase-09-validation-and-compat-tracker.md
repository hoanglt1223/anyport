---
phase: 9
title: "Validation and compatibility tracker"
status: in-progress
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

Done: `--dump-frame-hash` in the game `main()` (no separate `headless.cpp`), `compat/` with 49 titles and
`schema.md`, checkpoint tests (`ANYGBA_COMPAT_TESTS=ON`, `ctest -L compat`), `tools/compat-site/generate.py`,
`pages.yml`, a compat job on three hosts in `ci.yml`, and `docs/dev/RETRO.md`. All 41 checkpoints pass
on Windows (repo commits `eab35b6`, `e407071`). The interpreter-only run (`anygba-shot`) gives the
same checkpoint picture for 40 of 41 titles; tonc `txt_se2` prints its own timing measurements.

Open: step 4 needs the user's own commercial dump (no title is tracked yet); CI on Linux and macOS has
not run because nothing is pushed.
