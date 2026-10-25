---
phase: 2
title: "Override layer: config, codegen, guest API"
status: pending
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
