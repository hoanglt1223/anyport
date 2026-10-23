---
phase: 2
title: "Loader and analysis: PRX, relocations, NIDs, function discovery"
status: completed
effort: 4-6w
dependsOn: [1]
---

# Phase 02: Loader and analysis

## Context

PSP executables are ELF/PRX files with relocations and imports identified by NID (hashed function names) per system library. Games often ship extra PRX modules on the disc.

## Requirements

- Parse `EBOOT.BIN` and all PRX modules from the user's extracted disc (decrypted input only).
- Apply relocations for a fixed host load layout; resolve imports by library name and NID; record exports between game modules.
- NID database with names (from PPSSPP and public NID lists) for readable logs and coverage reports.
- Function discovery: entry points, exports, `jal` targets, jump tables, function pointers in data, thread entry points passed to `sceKernelCreateThread`; trace-feedback from the runtime as in AnyGBA.
- Delay-slot handling in the CFG.

## Files (create)

- `recomp/loader/elf_prx.*`, `relocs.*`, `nid_db.*`
- `recomp/analysis/cfg.*`, `functions.*`, `jumptables.*`
- `data/nids.toml`

## Steps

1. Loader and relocations, tested on homebrew PRX files.
2. NID resolution and the database.
3. Function discovery and trace-feedback ingestion.

## Validation

- Homebrew builds with symbols: 100% of functions found after one feedback pass.
- A commercial title's modules all load with every import resolved to a known NID or reported.

## Risks

- Encrypted or compressed inputs. Accept only decrypted files; say clearly how users can decrypt their own dumps with existing tools.

## Rollback

Module-scoped; revert.
