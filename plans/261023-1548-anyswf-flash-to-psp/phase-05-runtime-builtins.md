---
phase: 5
title: "Runtime built-ins"
status: pending
effort: 2-3w
dependsOn: [3, 4]
---

# Phase 05: Runtime built-ins

## Context

Games call into the Flash player's built-in classes. This phase implements the subset classic AS2 games use, driven by what the test games actually call.

## Requirements

- `MovieClip` (properties `_x`, `_y`, `_xscale`, `_rotation`, `_alpha`, `_visible`, `_currentframe`, `_width`/`_height`; methods `gotoAndPlay/Stop`, `play`, `stop`, `attachMovie`, `duplicateMovieClip`, `removeMovieClip`, `createEmptyMovieClip`, `hitTest` (bounds and shape via precomputed outlines), `swapDepths`, `getBounds`, `startDrag`; events `onEnterFrame`, `onLoad`, `onPress`, `onRelease`, `onRollOver`).
- Drawing API (`lineTo`, `beginFill`, `curveTo`) with on-device tessellation for small paths; warn on heavy use.
- `Button` states and hit areas.
- `Key` (PSP buttons mapped to arrow keys, space, enter, and configurable letters), `Mouse` (analog nub cursor with acceleration, X = click).
- `TextField` for dynamic text with embedded or bundled fonts, no input fields on first pass (on-screen keyboard later via `sceUtilityOsk`).
- `Math`, `String`, `Array`, `Object`, `Number`, `Boolean`, `Date`, `setInterval`/`clearInterval`, `getTimer`.
- `Sound` (attachSound, start, stop, setVolume, streaming MP3 via Media Engine).
- `SharedObject.getLocal` saved as files under `ms0:/PSP/SAVEDATA/ANYSWF/<game-id>/`.
- Per-game `anyswf.toml`: key mapping, stage scaling mode, cursor speed.

## Files (create)

- `runtime/src/builtins/movieclip.c`, `button.c`, `key.c`, `mouse.c`, `textfield.c`, `math.c`, `string.c`, `array.c`, `date.c`, `timers.c`, `sound.c`, `sharedobject.c`, `drawing.c`
- `docs/user/USAGE.md`

## Steps

1. Implement built-ins in the order test games hit them (log every unimplemented call by name).
2. Input mapping and cursor.
3. Sound and SharedObject.

## Validation

- Three chosen AS2 mini games are playable start to finish on the PC target.

## Risks

- Long tail of rarely used APIs. Keep the "unimplemented call" log as the work queue.

## Rollback

Module-scoped; revert.
