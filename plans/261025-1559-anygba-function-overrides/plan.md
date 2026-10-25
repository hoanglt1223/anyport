---
title: "AnyGBA function overrides and AI-assisted targeted decompilation"
description: "Replace chosen recompiled functions of any GBA game with hand-written or AI-decompiled C++ that is proven equivalent by differential testing, so per-game and per-engine work can go beyond filters and config (real font text, HD sprites in the draw path, true widescreen, modern UI)."
status: in-progress
priority: P2
effort: 6-9w part-time
branch: main
tags: [feature, experimental, recompiler, gba, decompilation]
blockedBy: []
blocks: []
created: 2026-10-25
---

# AnyGBA function overrides and AI-assisted targeted decompilation

## Overview

AnyGBA recompiles every function of a ROM automatically. The generated C++ is correct but not
editable: it manipulates registers, not game concepts. A full matching decompilation (like
pret/pokeemerald) takes years per game, so it cannot scale to every ROM.

This plan adds the middle route used by N64Recomp/Zelda64Recomp mods: keep 99% of a game
recompiled and replace only the functions that matter (text printer, sprite/OAM builders, HUD,
camera/culling, menus) with readable C++. Replacements are written with AI help from Ghidra's
output and accepted only when a differential test shows they behave like the recompiled original.
Work targets engines where possible (Gen 3 Pokémon engine: Ruby/Sapphire/Emerald/FireRed/LeafGreen;
MP2K sound; Fire Emblem GBA), so one rewrite serves several games.

## Outcome and acceptance criteria

- A game's config can name guest functions to override; the runtime runs the C++ replacement for
  every call path (direct `bl` calls in generated code, indirect calls, interpreter fallback).
- Overrides are C++ against a small, documented guest API (registers, memory, calls back into
  guest functions, host services such as the window text layer), built into the game exe by
  `anygba build`, with no ROM-derived data or code in the repo.
- `anygba decomp <rom> --func <addr|symbol>` produces a candidate C++ function from Ghidra headless
  output plus an LLM, compiles it, and runs the differential test automatically, retrying with the
  failure diff; the report says pass/fail with the evidence.
- Differential tests compare the override with the recompiled original on random and recorded real
  states (registers, touched memory, return value, calls made) and must pass before an override is
  enabled by default.
- Emerald: the field/battle text printer is overridden end to end and draws text through the host
  font at window resolution; the same override source runs on FireRed with only a symbols table
  change (engine reuse proven).
- Existing behaviour is unchanged when no override is configured: compat frame-hash checkpoints
  and `ctest -LE slow` stay green.

## Non-goals

- Full or byte-matching decompilation of any game.
- Shipping decompiled or recompiled game code, symbols derived from ROM data, or assets publicly.
- Live (per-frame) LLM use; the LLM is only an offline authoring aid.
- Changing the recompiler's default output for games without overrides. Exception (accepted
  2026-10-25): resolving agbcc's `cmp; bls table` switch, a correctness fix that phase 05 needed for
  RenderText; compat checkpoints and Emerald's frames are unchanged.

## Constraints

- Ghidra (Apache-2.0) runs as an external tool, not vendored; LLM access is optional (the Claude Code
  CLI with the user's login, or `ANTHROPIC_API_KEY`); without it the tool still exports Ghidra output and runs difftests on
  hand-written code.
- pret decomp projects may be read as reference for names and behaviour (as the Emerald symbols file
  already does); their code is not copied into the repo.
- Implementation happens in a git worktree of `repos/anygba` (another session edits `main`).

## Architecture

```
ROM ─► anygba-recomp ──► generated C++ ──► calls go through override check ─┐
          ▲ (config: [[overrides]])                                         ▼
game.toml ┘                                     override registry ─► C++ override (guest API)
                                                       ▲                    │ may call guest fns
anygba decomp: Ghidra headless ─► pseudo-C + types ─► LLM rewrite ─► compile ─► difftest vs recompiled
                                                                     ▲ retry with diff ◄──┘
```

## Phases

| # | Phase | Effort | Depends on | Status |
|---|---|---|---|---|
| 01 | [Spike: one override end to end (gate)](phase-01-spike-override-gate.md) | 1w | none | completed |
| 02 | [Override layer: config, codegen, guest API](phase-02-override-layer.md) | 1.5-2w | 01 | completed |
| 03 | [Differential verification harness](phase-03-differential-verification.md) | 1-1.5w | 02 | completed |
| 04 | [AI-assisted decomp tool (Ghidra + LLM)](phase-04-ai-decomp-tool.md) | 1.5-2w | 03 | completed |
| 05 | [Gen 3 text printer override, Emerald and FireRed](phase-05-gen3-text-printer.md) | 1-1.5w | 04 | in-progress |

Phase 01 is a gate: later phases start only after its exit criteria are recorded in the phase file.

## Risks

- Generated code calls many callees directly; overrides need codegen support for those call
  sites (phase 02), otherwise only indirect calls are caught.
- Guest functions with side effects outside their arguments (globals, IO, DMA) need the difftest to
  capture all touched memory, not just return values.
- LLM output may compile and pass random states yet differ on rare paths; recorded real-play states
  and coverage reporting reduce, not remove, that risk.
