---
phase: 1
title: "Prior-art check and shared PSP layer"
status: completed
effort: 1w
dependsOn: []
---

# Phase 01: Prior-art check and shared PSP layer

## Context

Avoid duplicating existing PSP ports, and avoid four copies of the same PSP setup code.

## Requirements

- Search for existing PSP ports of TIC-80, fake-08/PICO-8, LÖVE 11, and OpenGMK/GM8 runners. Drop or switch to contributing for any that exist and are maintained.
- Package the AnySWF PSP platform layer (window/GU init, input, audio, files, clock) as `psp-platform`, a tiny static library with a stable header, consumable by each fork.
- Common game browser screen (list folder, show cart/game name and icon) reused by every runner.

## Files (create)

- `docs/dev/prior-art.md` (in the first fork or a small meta repo)
- `psp-platform/` (library extracted from `anyswf/platform/psp`)

## Steps

1. Prior-art search and decisions per runner.
2. Extract `psp-platform` and the game browser.

## Exit criteria (gate)

- Per-runner go/contribute/skip decision recorded.

## Rollback

Research and library extraction only.

## Status notes (2026-10-24)

- Gate met: per-runner decisions are in `plans/reports/researcher-261023-1741-engine-runners-prior-art.md`
  (TIC-80 go, fake-08 go, LövePotion go as a long-lived fork, GM8 no-go).
- `psp-platform` is not a separate library repo. Each fork vendors the AnySWF layer unmodified with a
  `VENDORED.md` that records the AnySWF commit (`src/system/psp/platform/` in TIC-80,
  `platform/psp/psp-platform/` in fake-08), the same way rpy2psp does. A fork has to build on its own for
  an upstream PR, which rules out a cross-repo dependency.
- No shared game browser: TIC-80 uses a browser written as a TIC-80 cart, fake-08 keeps its own BIOS
  menu, and LövePotion has its own no-game screen. A common C browser would need a font and UI that
  every runner already has.
- `docs/dev/prior-art.md` was not created: the research report holds it, and an extra docs file would
  have to be dropped from each upstream PR. Details: `plans/reports/fullstack-developer-261024-1741-engine-runners.md`.
