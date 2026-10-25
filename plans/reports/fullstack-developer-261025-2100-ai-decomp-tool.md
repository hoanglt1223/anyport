# Phase implementation report: AnyGBA difftest normal-return gate and AI decomp tool

## Executed phase
- Phases: phase-03 gate update (user decision), phase-04-ai-decomp-tool
- Plan: plans/261025-1559-anygba-function-overrides
- Status: completed (code uncommitted in `repos/anygba-overrides`, branch `feat/function-overrides`, on 4ae6e1f)

## Outcome
The difftest gate now also needs at least `min_returned` (default 0.95, per function in `difftest.toml`) of states to
return normally in both versions; below that a run is `insufficient` (exit code 3, JSON `status`), never a pass.
Emerald's StringCopy spec was retuned to mostly planted terminated strings and passes at 96.8% / 96.7% normal returns.

`anygba decomp` exports functions with Ghidra 12.2, has an LLM (Claude Code CLI by default) write overrides against the
guest API, compiles them into the game and accepts only difftest passes, feeding failures back. On tonc's tte_demo 7 of
8 functions passed automatically in the final run (8/8 after a guest API bug the tool exposed was fixed); on Emerald,
StringCopy, StringLength, StringAppend, StringCompare and IsTextPrinterActive all passed on the first answer, identical
in full state. The phase 01 StringCopy LLM measurement now passes (it failed with the stand-in).

## Files (repos/anygba-overrides)
- Gate: `runtime/src/overrides/difftest.{h,cpp}` (`min_returned`, `Status`, `classify`, `exit_code`, returned share in
  text and JSON), `runtime/src/main.cpp` (help), `tools/anygba/difftest.cpp` (passes exit code 3, share in the verified
  comment), `tests/runtime/difftest_tests.cpp`, `tests/override-difftest.cmake` (insufficient run, front end exit 3, not
  marked), `overrides/pokemon-gen3/difftest.toml` (retuned), `overrides/pokemon-gen3/overrides.toml` (new verified line).
- Decomp: new `tools/decomp/` (`decomp.py`, `engines.py`, `ghidra.py`, `generated.py`, `ghidra/AnygbaExport.java`,
  `prompts/{system,task,spec-request,retry}.md`, `examples/word_fill.{cpp,toml}`, `tests/test_decomp.py`), new
  `tools/anygba/decomp.{h,cpp}`, `tools/anygba/{main.cpp,CMakeLists.txt}`, `cmake/install.cmake`, `tests/CMakeLists.txt`
  (`decomp-tool`, `decomp-scaffold`), new `tests/decomp-scaffold.cmake`.
- Guest API fix: `runtime/include/anygba/override.hpp` (stores reach the bus unaligned, like translated code),
  `tests/runtime/save_tests.cpp` (SRAM byte-lane test).
- Docs: `docs/dev/OVERRIDES.md` (gate, AI-assisted decompilation with setup, tests), `README.md`,
  `docs/dev/ARCHITECTURE.md`.

## Tests
- MSVC Release build clean. `ctest -LE slow`: 24/24. `decomp-scaffold` (slow, Ghidra): pass. Python: 18/18.
- Emerald StringCopy gate rerun: seed 12345 ABI 10,072/10,072, returned 9,749 (96.8%); seed 777 10,072/10,072, 96.7%.
- Corpus and Emerald decomp results, cost and failure classes: phase-04 file, "Results".

## Issues and deviations
- Git cannot be run on the code worktree from this session: all changes there are uncommitted.
- Guest API change (phase 02 surface): `Guest::write` no longer aligns before the bus. Identical for every region
  except SRAM, where it now matches the translated store. Existing overrides (StringCopy, test modules) are unaffected
  (byte stores and aligned words); their difftests still pass.
- The game exits with 1 for errors as well as for a failed difftest; the decomp tool tells them apart by the JSON
  report (a verdict always writes one). `anygba difftest` itself still maps any 1 to "fail".
- `--engine anthropic-api` is implemented but not run (no key here). Its default model (`claude-opus-5-5`) is what the
  CLI's `opus` alias answered with.
- The tonc validation needed a base state after boot (crt0 fills IWRAM); made from a `--record-entry` file with a
  scratch helper. A `--load-state` that accepts a recording directly would make this one step.
- ROM-derived data stayed in `%APPDATA%/anyport/anygba/decomp/` and `%TEMP%`; pret names went to a scratch symbols
  table there, not to `compat/symbols/BPEE.toml`.

## Next steps
Phase 05 (Gen 3 text printer) can use `anygba decomp` with the BPEE names table for the printer's helpers; the
verified Emerald module in the data folder is a starting point.

## Unresolved questions
- Should `anygba difftest` (front end) also distinguish errors from failures by the report, as the decomp tool does?
- Ship a names table for Emerald text functions in `compat/symbols/BPEE.toml` (addresses from pret), or keep them local?
