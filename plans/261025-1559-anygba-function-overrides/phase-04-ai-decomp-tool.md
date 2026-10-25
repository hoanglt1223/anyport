---
phase: 4
title: "AI-assisted decomp tool (Ghidra + LLM)"
status: completed
effort: 1.5-2w
dependsOn: [3]
---

# Phase 04: AI-assisted decomp tool (Ghidra + LLM)

## Context

Writing overrides by hand from disassembly is slow. Ghidra's headless analyzer gives pseudo-C, types
and cross-references; an LLM can turn that into readable C++ against the guest API; the phase 03
difftest decides whether the result is accepted.

## Requirements

1. `anygba decomp <rom> --func <addr|symbol> [--symbols file] [--engine claude|none]`:
   - Ghidra headless project per ROM (cached), ARMv4T/Thumb loader with the GBA memory map; export
     the function's pseudo-C, callees, globals touched, and known symbol names.
   - Prompt the LLM with the export, the guest API header, naming hints and an example override;
     receive one C++ function.
   - Compile it into a scratch override module, run `anygba difftest`; on failure feed the minimal
     diff back and retry (bounded attempts); keep the transcript.
   - `--engine none`: export and scaffold only, for hand writing.
2. Batch mode over a list of functions (dependency order, callees first) with a summary table.
3. Everything ROM-derived (Ghidra project, exports, generated overrides for a commercial game) is
   written to the per-user data folder or a scratch path, never inside the repo.
4. Document setup (Ghidra path, Java, API key) in `docs/dev/OVERRIDES.md`.

## Files

- New `tools/decomp/` (Ghidra scripts, prompt templates, driver); CLI entry in the `anygba` tool
- `docs/dev/OVERRIDES.md`

## Steps

1. Ghidra headless import + export script; verify on a tonc demo ROM.
2. Prompt template and LLM call; compile + difftest loop with retries.
3. Batch mode and summary report.

## Validation

- On the corpus ROM, at least 5 of 8 chosen functions reach a passing difftest automatically;
  results (attempts, failure classes) recorded in this file.
- Without an API key the tool still exports and scaffolds.

## Risks and rollback

- LLM cost per function; cap attempts and tokens, report spend.
- Ghidra version drift; pin the tested version in the docs.

### Results (2026-10-25, worktree `repos/anygba-overrides`, branch `feat/function-overrides`, uncommitted on 4ae6e1f)

Design, setup and output layout: `docs/dev/OVERRIDES.md` ("AI-assisted decompilation"). Gate per the phase 03 update:
ABI comparison plus at least 95% of states returning normally (`insufficient` otherwise).

- `anygba decomp <rom> --func NAME|0xADDR[:thumb|arm] [--funcs FILE] [--symbols F] [--engine claude-cli|anthropic-api|none]
  [--model M] [--attempts N] [--load-state F] [--recorded F] [--spec F] [--miss-log F] [--difftest-timeout S]`: the C++
  entry (`tools/anygba/decomp.cpp`) runs `tools/decomp/decomp.py` (Python 3.11+, installed to `share/anygba/decomp`)
  with its install prefix.
- Ghidra 12.2 + JDK 25 (`--ghidra`/`ANYGBA_GHIDRA`, `--java-home`/`ANYGBA_JAVA_HOME`): `ghidra/AnygbaExport.java`, one
  project per ROM without auto-analysis (import and export of a few functions: 7-13 s), GBA memory map, ROM
  read-only; exports pseudo-C, disassembly, callees with the `g.call` arguments, globals (literal-pool values
  included) and known names. `pop {rN}; bx rN` is marked as a return (flow override) before decompiling.
  `analyzeHeadless.bat` cannot take paths with parentheses, so the ROM is copied into the project folder.
- Block costs: the generated `f_X_orig` gives one `g.block(next_pc, insns, extra)` per `AG_SPEND`/`AG_TICK`; the table
  goes into the prompt and the scaffold.
- Engines: `claude-cli` = `claude -p --safe-mode --model opus --tools "" --output-format json` with the prompt on stdin
  (without `--safe-mode` the user's CLAUDE.md, skills and MCP instructions added ~306k cache tokens per call; with it,
  634); `anthropic-api` with `ANTHROPIC_API_KEY` (not run: no key on this PC); `none`. The `opus` alias answered as
  `claude-opus-5-5`.
- Loop: the first answer holds the C++ and the argument spec; build = one source file plus link (2-3 s); difftest
  `--json`; feedback = compiler errors, the summarised report with the minimised failing state, a rejected spec, an
  insufficient run, or a timeout. Candidates that call `g.run_original()` are rejected. Transcripts (export, prompts,
  replies, candidates, build logs, reports, `attempts.json`, `summary.{md,json}`) and the module (passing overrides
  `verified = true` with the result, others scaffolds with `enabled = false`) stay under
  `%APPDATA%/anyport/anygba/decomp/<game>-<hash>/`; a `--work` inside the source tree is refused unless git-ignored.
- Batch: callees first (cycles keep the given order), summary table with attempts, outcomes, tokens, time, cost.

Validation:

- `ctest -LE slow`: 24/24 (new `decomp-tool`: 18 Python unit tests incl. the attempt loop with a stub model and game;
  new SRAM store test in `anygba-tests`). `decomp-scaffold` (slow, needs `ANYGBA_GHIDRA` at configure time) passes:
  `--engine none` writes export, prompt and a scaffold with the block table.
- Corpus, tonc `tte_demo.gba` (homebrew, open), 8 functions picked from `anygba-recomp --list` (no symbols): a struct
  init, a byte-store setter, a 4-halfword setter, strlen, newlib's `_Bfree` list push, a palette helper with branches,
  libtonc's `irq_init` (calls through `__call_via_r3` into IWRAM) and an ARM libgcc compare veneer. Final run
  (claude-cli/opus, 4 attempts, 10,000 states, base state = machine at `irq_init`'s first call):
  **7/8 passed automatically** (6 on the first answer, `0x08002464` on the second after a compile error), 8/8 after one
  guest API fix (below; `_Bfree` then passed on its second answer). Every pass is 10,000/10,000 at the ABI level with
  100% normal returns and all blocks covered. Cost of the run: 187 s of model time, 17.8k output + 105k cache tokens,
  1.06 USD reported (list price; billed to the subscription).
- Failure classes seen across the development runs: compile errors (an unqualified `Flags`; fixed on the next answer);
  ABI differences (`memory`, `writes`, `io-writes`; fixed from the minimised diff in one retry); argument specs as
  `[[key]]` instead of `[key]` and negative ranges (tool fixes: skeleton and unsigned rule in the prompt, rejected
  specs go back to the model); runaway difftests from the reset state when a callee lives in IWRAM that crt0 has not
  filled yet (tool fixes: `--difftest-timeout`, a short `tick_limit` in the prompt, and a boot base state); and one
  real API bug: `Guest::write` aligned 16/32-bit stores before the bus, so an unaligned store to SRAM (8-bit bus) hit a
  different byte lane than the translated `str`. Stores now reach the bus unaligned, like translated code (test in
  `tests/runtime/save_tests.cpp`).
- Emerald (BPEE, `state.ss2` base, phase 01 miss logs, names from pret's `pokeemerald.sym` in a scratch symbols table):
  StringCopy, StringLength, StringAppend, StringCompare and the text-printer helper IsTextPrinterActive: **5/5 on the
  first answer**, each identical in full state on every state (10,000 random; StringCopy also the 72 recorded Bag-menu
  states), normal returns 96.7% / 100% / 99.8% / 100% / 100%, all blocks covered (4, 3, 4, 7, 1). 70 s of model time,
  6.9k output + 41k cache tokens, 0.47 USD reported. The model wrote the specs for the four new functions.
- Phase 01 measurement redone for StringCopy with the real model and the hand-written override's spec and recorded
  states: pass on the first answer, 10,072/10,072 at the ABI level and in full state (the phase 01 stand-in: 0/10,020
  full state, 7,215/10,020 ABI), 4/4 blocks, 14 s, 1,304 output tokens, 0.08 USD reported.
- Not run: the 41 compat checkpoints and other slow tests (generated code is unchanged; the guest API change affects
  override sources only), and `--engine anthropic-api` (no key).
