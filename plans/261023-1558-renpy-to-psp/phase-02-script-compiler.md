---
phase: 2
title: "Script reader and bytecode compiler"
status: completed
effort: 3w
dependsOn: [1]
---

# Phase 02: Script reader and bytecode compiler

## Context

The PSP engine runs a compact bytecode, so all parsing and validation happens on PC.

## Requirements

- Read scripts from `.rpy` (preferred) or decode `.rpyc` (pickled AST) through a sandboxed decoder that never executes game code; unpack `.rpa` archives.
- Statements: `label`, `jump`, `call`/`return`, `say` (with character definitions, name colors), `menu` (with conditions), `if/elif/else`, `while`, `$` assignments, `default`/`define`, `scene`/`show`/`hide` with tags and attributes, `with` transitions (dissolve, fade, pixellate, move, slide subsets), `play`/`stop`/`queue` music and sound, `pause`, `nvl` mode, `window`, `centered`, text tags (`{b}`, `{i}`, `{color}`, `{w}`, `{p}`, `{nw}`, `{fast}`).
- ATL subset: positions, `xalign/yalign`, `linear/ease` on position, zoom, alpha; `repeat`.
- Expression compiler for the safe Python subset from phase 01; anything else becomes a build error with source location.
- Output: bytecode file, string table (UTF-8), symbol table for saves.
- Translations: honor Ren'Py `translate` blocks; select language at build time.

## Files (create)

- `rpy2psp/compiler/` (Python, run on PC: `reader.py`, `rpyc_decode.py`, `rpa.py`, `compile.py`, `expr.py`, `atl.py`, `bytecode.py`)
- `rpy2psp/docs/dev/bytecode.md`
- `rpy2psp/tests/compiler/*`

## Steps

1. Readers for `.rpy`, `.rpyc`, `.rpa`.
2. Statement compiler and expression subset.
3. ATL subset and translations.

## Validation

- The three target games compile with zero unsupported constructs; golden bytecode tests for each statement type.

## Risks

- Games that compute image names at runtime. Resolve statically where possible; otherwise report.

## Rollback

Module-scoped; revert.

## Result (2026-10-23)

- Code is in `rpy2psp/rpy2psp/compiler/`; `translate.py` was added for dialogue IDs. The format is in `docs/dev/bytecode.md`. Commit: `affea80`.
- The three targets compile with zero errors. Every menu path plays in the reference interpreter. All 70 dialogue translations of The Question (ja, ko, zh-Hans, zh-Hant) match by ID.
- Corpus coverage: 5 of 15 compile with zero errors (the same five that the census predicted).
- Arcance's Ren'Py 6.99 `.rpyc` files compile to the same code as its `.rpy` files.
