---
phase: 2
title: "Override layer: config, codegen, guest API"
status: completed
effort: 1.5-2w
dependsOn: [1]
---

# Phase 02: Override layer, config, codegen and guest API

## Context

Turn the spike into a supported feature that any game can use, chosen by the phase 01 decision.

## Requirements

1. Config: `[[overrides]]` entries in the game TOML / symbols file (`addr` or `symbol`, `thumb`,
   `impl` name, `enabled`, optional `engine` tag) documented in `docs/dev/GAME-CONFIG.md`.
2. Codegen: call sites whose target is overridden go through the override registry; all other call
   sites stay direct (no cost for games without overrides). Recompile is needed only when the
   override set changes.
3. Runtime registry: name → host function, registered by override modules; unknown `impl` names fail
   at startup with a clear message (HLE strictness rule).
4. Guest API (C++ header, documented): registers in/out, typed guest memory read/write helpers,
   calling a guest function (recompiled or interpreted), and host services (window text layer, HD
   sprite lookup, OSD). No access to emulator internals beyond this API.
5. Packaging: override sources live in a module folder (`overrides/<engine-or-game>/`) compiled into
   the game by `anygba build --overrides <dir>`; per-user modules allowed outside the repo.
6. Menu/CLI: list active overrides; `--overrides off` for A/B comparison.

## Files

- Recompiler code generator and its config parser; `runtime/src/dispatch.cpp`, `runtime/src/system.*`
- New `runtime/include/anygba/override.hpp` (guest API), `runtime/src/overrides/` (registry)
- `docs/dev/GAME-CONFIG.md`, new `docs/dev/OVERRIDES.md`; tests under `tests/`

## Steps

1. Config parsing and validation with unit tests.
2. Codegen routing for overridden targets; unit test on a corpus ROM with a fake override.
3. Registry, guest API, `anygba build --overrides`.
4. End-to-end test: a jsmolka/tonc corpus ROM with one overridden function, frame hashes equal.

## Validation

- `ctest -LE slow` green; compat checkpoints unchanged with no overrides configured.
- New tests: config errors, routing from direct/indirect/interpreted calls, `--overrides off`.

## Risks and rollback

- Feature is off unless configured; revert the codegen routing commit to restore previous output.

### Results (2026-10-25, worktree `repos/anygba-overrides`, uncommitted on top of the spike commit aec3eb9)

Built on `[[replace]]` as the gate decided; no trampoline. Schema, guest API and rules: `docs/dev/OVERRIDES.md`.

- Config: `[[override]]` (`addr`+`mode` or `symbol`, `impl`, `enabled`, `engine`) in game configs and in module
  `overrides.toml`; `[functions]` tables (game config, `--symbols FILE`, and with `anygba build` the shipped
  `share/anygba/symbols/<code>.toml`; `compat/symbols/BPEE.toml` now names `StringCopy`). Errors name file and line.
- Codegen: an overridden function keeps its translation as `f_X_orig`; `f_X` checks `ag_override_on[k]` and calls
  `anygba_override_run`. Games without overrides get unchanged generated code (no `.cpp` glob, no table).
- Runtime: name registry (`ANYGBA_OVERRIDE`), startup check that fails on unknown or duplicate implementations,
  `--overrides on|off|all`, active list printed at start (`override: ...`), OSD sink. Guest API in
  `runtime/include/anygba/override.hpp`: registers, flags, typed memory, `block()` cycle accounting, `call()`,
  `run_original()`, `ret()`/`ret_to()`, `osd()`, `from_recompiled_code()`.
- Packaging: `anygba build --overrides DIR` and `anygba-recomp --overrides DIR --symbols FILE` (repeatable); C++20
  sources compiled into the game (also the Android build); modules installed to `share/anygba/overrides/`.
- Example module `overrides/pokemon-gen3/` (StringCopy ported to the guest API, no ROM data).
- Not done: a window text layer hook (no text layer exists on this branch yet; phase 05 adds it with the hook)
  and HD sprite lookup; the menu does not list overrides (would touch the menu model, view and tests).

Validation:

- `ctest -LE slow`: 22/22 pass, including the new unit tests (`tests/recomp/override_config_tests.cpp`,
  `tests/runtime/override_tests.cpp`) and `override-e2e`: tonc irq_demo with `tests/overrides/call-paths` reaches
  one override by `bl` from recompiled code, one by `bx` from recompiled isr_master (indirect) and one by `bl` from
  interpreted code; `--overrides off` reaches none; frame 600 hash identical on and off.
- Compat checkpoints with no overrides: all 41 compat/*.toml checkpoints with corpus ROMs pass (full set, -DANYGBA_COMPAT_TESTS=ON); the slow driver-build test passes.
- Emerald (save state copy, Bag-menu key script, `--no-save`, scratch data dir): frame hashes at 164095, 164245,
  164395 and 164545 identical with `--overrides on` and `off`, EWRAM and VRAM at 164545 identical; a counting copy of
  the module (scratch only) saw 9 calls, all from recompiled code. Evidence: `%TEMP%/ovr-emerald/ab.log`.
