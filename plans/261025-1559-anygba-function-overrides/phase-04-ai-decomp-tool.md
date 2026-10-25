---
phase: 4
title: "AI-assisted decomp tool (Ghidra + LLM)"
status: pending
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
