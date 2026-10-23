---
phase: 4
title: "Native VN engine on PSP"
status: in-progress
effort: 3-4w
dependsOn: [2, 3]
---

# Phase 04: Native VN engine on PSP

## Context

`vnpsp` is a small C engine on the shared PSP platform layer. It interprets the compact bytecode (cheap compared with Python) and draws with the GE.

## Requirements

- Bytecode interpreter with call stack, variables, and deterministic state for saves and rollback.
- Scene graph for backgrounds and sprites with tags, layers, ATL subset animations, and transitions on the GE.
- Text box with typewriter effect, text tags, NVL mode, history log, auto and skip modes.
- Menus navigable with the D-pad and analog nub.
- Saves: 30 slots with thumbnails in `ms0:/PSP/SAVEDATA/`, quick save/load, rollback of at least 50 steps (snapshot ring buffer).
- Settings: text speed, volumes, auto speed.
- Streaming asset loader with LRU texture cache in RAM and VRAM.

## Files (create)

- `vnpsp/src/vm.c`, `scene.c`, `atl.c`, `transitions.c`, `text.c`, `menu.c`, `save.c`, `rollback.c`, `settings.c`, `assets.c`, `audio.c`
- Platform layer imported from AnySWF

## Steps

1. VM and text, then scenes and sprites.
2. Transitions and ATL.
3. Saves, rollback, settings.
4. Streaming and memory tuning.

## Validation

- First target game plays start to finish on PPSSPP, then on the PSP-3000.

## Rollback

Module-scoped; revert.
