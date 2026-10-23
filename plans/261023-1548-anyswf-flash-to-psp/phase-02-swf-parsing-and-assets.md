---
phase: 2
title: "SWF parsing and asset pipeline"
status: in-progress
effort: 2w
dependsOn: [1]
---

# Phase 02: SWF parsing and asset pipeline

## Context

Everything the PSP would struggle to compute at runtime is precomputed here into a single `assets.bin` the runtime can load with minimal parsing.

## Requirements

- Parse SWF (compressed `CWS` and uncompressed `FWS`; reject `ZWS`/LZMA with a clear message until supported) through Ruffle's `swf` crate.
- Character table: shapes, morph shapes, sprites (MovieClips) with their timelines, buttons, static and dynamic text, fonts, bitmaps, sounds.
- Shapes: tessellate fills and strokes with `lyon` at a chosen tolerance for the target scale (stage scaled to 480x272). Output vertex buffers in the GE vertex format (16-bit positions where possible, colors, UVs for gradient and bitmap fills).
- Gradients: bake each gradient into a small 1D texture; linear and radial via UV generation; focal radial approximated.
- Morph shapes: tessellate at each morph ratio the timeline actually uses.
- Fonts and text: embedded glyphs become meshes; device text uses a bundled open bitmap font.
- Bitmaps: decode JPEG/lossless, scale for the target, quantise to CLUT8 when lossless enough (else 5551/4444), split above 512x512, swizzle for the GE.
- Sounds: event sounds to PCM/ADPCM; streamed MP3 kept as MP3 for Media Engine decode.
- `assets.bin` format documented, versioned, little-endian, 16-byte aligned blocks.

## Files (create)

- `swf2c/src/parse.rs`, `characters.rs`, `tessellate.rs`, `gradients.rs`, `bitmaps.rs`, `sounds.rs`, `text.rs`
- `swf2c/src/assets_bin.rs`, `docs/dev/assets-bin-format.md`
- `runtime/src/assets.c` (loader)
- `tests/swf2c/*`

## Steps

1. Parse and dump a character table report (`swf2c inspect game.swf`).
2. Tessellation and gradient baking, checked against Ruffle-rendered reference PNGs on the PC target.
3. Bitmap conversion and swizzling; sound conversion.
4. Write and load `assets.bin`.

## Validation

- Static-frame render of 20 test SWFs on the PC target is within a perceptual diff threshold of Ruffle's output.
- `assets.bin` for a typical 2 MB SWF stays under 8 MB.

## Risks

- Tessellation of complex art creates too many triangles. Raise tolerance per shape by screen size; log the triangle budget per frame.

## Rollback

Tool module; revert.
