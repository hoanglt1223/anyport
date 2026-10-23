---
phase: 1
title: "Prior-art check and shared PSP layer"
status: in-progress
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
