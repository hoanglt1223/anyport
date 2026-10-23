---
phase: 3
title: "Asset pipeline"
status: completed
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

## Result (2026-10-23)

- Code is in `rpy2psp/rpy2psp/assets/`. The format is in `docs/dev/pack-format.md`. Commit: `5287506`.
- Deviation, DXT is not swizzled: the GE has no swizzled DXT mode (checked in PPSSPP), so DXT is stored in the GE block order. Swizzling applies to the T4/T8 glyph atlases.
- Deviation, movies: these become an H.264 Baseline elementary stream plus MP3 instead of PSMF. Playback is still to be proven in phase 04.
- Sizes: The Question 1.1 MiB, Zero Echoes 2.3 MiB, Arcance 2.3 MiB, all far under the 300 MB limit.
- `rpy2psp verify` passes for all three targets:
  - images: PSNR minimum 22.9 dB, mean 27.8 to 34.8 dB depending on the game;
  - glyphs: exact match, including the Japanese build of The Question;
  - music: 128 kbps / 44.1 kHz, SNR 24 dB;
  - ADPCM: SNR 31 to 42 dB.
- Spot checks of decoded textures and the CJK atlas look correct.
