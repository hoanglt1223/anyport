---
phase: 3
title: "Asset pipeline"
status: pending
effort: 2w
dependsOn: [1]
---

# Phase 03: Asset pipeline

## Context

Desktop VN assets (1280x720 or 1920x1080 PNG/WebP, OGG/Opus audio, TrueType fonts) are converted once into formats the PSP reads directly.

## Requirements

- Images: scale to 480x272 space, keep alpha, compress to DXT5 (or DXT1 when opaque), power-of-two padding with UV rects, swizzled; layered images and `im.Composite` flattened where static.
- Fonts: collect every glyph used in the game text (covers Vietnamese and CJK), render glyph atlases at the sizes used, with outlines when the game uses them.
- Audio: music to MP3 (Media Engine decode) at 128 kbps; sound effects to ADPCM or short PCM.
- Movies: optional conversion to PSMF/H.264 Baseline at 480x272 for simple cutscenes.
- Asset pack format with an index for streaming by scene.

## Files (create)

- `rpy2psp/assets/` (`images.py`, `fonts.py`, `audio.py`, `movies.py`, `pack.py`)
- `rpy2psp/docs/dev/pack-format.md`

## Steps

1. Image conversion and packing.
2. Glyph collection and atlases.
3. Audio and optional movies.

## Validation

- Converted assets for a target game total under 300 MB; visual spot checks against the desktop version.

## Rollback

Module-scoped; revert.
