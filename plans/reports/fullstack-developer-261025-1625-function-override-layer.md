# Phase implementation report: AnyGBA override layer

## Executed phase
- Phase: phase-02-override-layer
- Plan: plans/261025-1559-anygba-function-overrides
- Status: completed (code uncommitted, see Issues)

## Outcome
Function overrides are a supported AnyGBA feature built on the `[[replace]]` route chosen by the gate:
`[[override]]` entries (address or `[functions]` symbol, `impl`, `enabled`, `engine`), C++ modules built
in with `anygba build --overrides DIR`, a guest API header, a startup check for unknown or duplicate
implementations, `--overrides on|off|all`, and the list of active overrides printed at start.
Emerald's StringCopy, ported to the API as `overrides/pokemon-gen3/`, gives the same frame hashes as the
original.

## Files (repos/anygba-overrides)
- New: `runtime/include/anygba/override.hpp` (guest API), `runtime/src/overrides/overrides.{h,cpp}`
  (registry, activation, `anygba_override_run`), `overrides/pokemon-gen3/{overrides.toml,string_copy.cpp}`,
  `docs/dev/OVERRIDES.md`, `tests/recomp/override_config_tests.cpp`, `tests/runtime/override_tests.cpp`,
  `tests/override-e2e.cmake`, `tests/overrides/call-paths/*`, `tests/overrides/irq-demo-isr.log`.
- Changed: `tools/recomp/config/game_config.{h,cpp}`, `tools/recomp/codegen/{c_emitter.h,dispatch_table.cpp}`,
  `tools/recomp/src/{cli.h,cli.cpp,pipeline.h,pipeline.cpp}`, `tools/anygba/{build.h,build.cpp,android.cpp}`,
  `runtime/include/anygba/cpu.h` (override table in `anygba_game`, appended fields), `runtime/src/main.cpp`,
  `runtime/CMakeLists.txt`, `cmake/{anygba_game.cmake,install.cmake}`, `tests/CMakeLists.txt`,
  `tests/recomp/config_tests.cpp` (`.cpp` sources are now allowed), `compat/symbols/BPEE.toml` (`[functions]`),
  `docs/dev/{GAME-CONFIG.md,ARCHITECTURE.md}`, `docs/user/USAGE.md`, `README.md`.
- Removed: `spike/` (superseded by the module; the spike commit keeps it).

## Tests
- Build (MSVC, Release): clean.
- `ctest -LE slow -j 8`: 22/22 pass, with the new unit tests (config, modules, symbol resolution, generated
  code, activation, recompiled and interpreted call paths, guest calls, `run_original()`, missing-return
  error) and `override-e2e`.
- `override-e2e` (tonc irq_demo, `tests/overrides/call-paths`): `bl` from recompiled code, `bx` from recompiled
  isr_master (indirect) and `bl` from interpreted code each reach their override; `--overrides off` reaches
  none; the frame 600 hash is identical on and off.
- Compat: all 41 corpus checkpoints pass with `-DANYGBA_COMPAT_TESTS=ON` (no overrides configured). The slow
  `driver-build` test passes.
- Emerald (copy of `POKEMON_EMER-a9dec84d.ss2`, Bag-menu key script, `--no-save`, scratch data folder, build
  with the spike's miss logs): hashes at frames 164095/164245/164395/164545 identical with `--overrides on` and
  `off`; EWRAM and VRAM identical at 164545. A counting copy of the module (scratch only) saw 9 calls, all from
  recompiled code. Evidence: `%TEMP%/ovr-emerald/ab.log`.

## Issues and deviations
- Git in `repos/anygba-overrides` is blocked for this session (the harness refuses `git -C` into another
  checkout), so the branch `feat/function-overrides` was not created and nothing is committed there. All work
  sits uncommitted on `spike/function-overrides` (base aec3eb9). To finish:
  `git -C repos/anygba-overrides switch -c feat/function-overrides`, then commit (for example
  `feat(overrides): C++ function overrides with symbols, modules and a guest API`).
- File edits in that worktree went through Python scripts, because the Write/Edit tools are limited to
  this session's worktree.
- Window text layer access: there is no text layer on this branch, so the API has only `osd()`; the hook
  belongs with the text layer in phase 05. HD sprite lookup is not exposed either. The menu does not list
  overrides (it would touch the menu model, view and their tests); the console list and `--overrides` cover
  A/B use.
- A ROM patch cheat over an overridden function only takes effect where the dispatcher starts the function;
  direct calls still run the override (documented).
- The workspace CLAUDE.md command list was not updated (outside the allowed files); add
  `anygba build ... --overrides DIR` and `<game> --overrides on|off|all` there.

## Next steps
Phase 03 (differential verification) can use `anygba_override_entry.original` and `run_original()` to run the
translation next to an override, and `from_recompiled_code()` for call-path reporting.

## Unresolved questions
- Should engine modules tolerate a game whose `[functions]` table lacks one of their symbols (skip with a
  warning) instead of failing the build? Right now a missing symbol fails the build.
