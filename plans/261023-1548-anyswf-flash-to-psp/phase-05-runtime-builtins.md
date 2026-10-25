---
phase: 5
title: "Runtime built-ins"
status: in-progress
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

Progress (2026-10-25, branch `feat/runtime-builtins`):

- Done on PC and PSP (PPSSPP): every built-in listed above, plus AsBroadcaster, Stage,
  Color, TextFormat, setTimeout and `Object.registerClass` linkage. Code is in
  `runtime/src/builtins/` (the planned `math.c`, `string.c` and `array.c` already existed
  as `runtime/src/avm1/builtins*.c`), the mixer in `runtime/src/audio/`, settings in
  `runtime/src/config.c`; `docs/user/USAGE.md` documents them.
- Design calls: the drawing API tessellates by horizontal bands (holes and
  self-intersections follow even-odd), gradients are shaded per vertex on a grid; MP3
  streams decode with minimp3 on the main CPU (Media Engine decoding stays an optional
  phase 06 item); saves are AMF0 `<name>.sol` files in the game's save folder
  (`ms0:/PSP/SAVEDATA/<id>/`, the id from `anyswf build`); `anyswf.toml` is the build
  config file, copied next to `assets.bin`, with runtime tables `[keys]`, `[cursor]`,
  `[stage]`, `[debug]`; on PC the real keyboard and mouse drive Key and Mouse.
- Tests: 15/15 self-authored AS2 tests (10 new, with scripted input, repeated runs for
  SharedObject and an audible-output check), 165/199 Ruffle AVM1 tests (82.9%), 26/51 in
  the new `tests/ruffle-avm1-builtins` suite (rich-text layout excluded; floor 50%),
  28/28 render tests including two scripted cases against Ruffle references, unit tests
  for config, mixer, tessellation and texture cache; the PSP build passes 11/11 corpus
  tests under PPSSPPHeadless (4 skipped: scripted input, UTC time zone).
- Still open, and why this phase stays `in-progress`: the validation needs three real AS2
  games, which are not on the Linux build box; input text editing (sceUtilityOsk),
  rich-text runs, `setMask` and `beginBitmapFill` are not implemented.

## Risks

- Long tail of rarely used APIs. Keep the "unimplemented call" log as the work queue.

## Rollback

Module-scoped; revert.
