---
phase: 14
title: "HD packs, AI upscaling, and widescreen"
status: pending
effort: 4-6w
dependsOn: [11]
---

# Phase 14: HD packs, AI upscaling, and widescreen

## Context

Filters (phase 11) smooth pixel art but cannot add detail. The user wants GBA games to look like modern games. AnyGBA's PPU is a high-level renderer, so it knows which tile, sprite and palette is drawn where; that enables replacement art, rendering at higher internal resolution, and drawing beyond the 240x160 window. Pokémon Emerald (user's own dump) is the test game; nothing from it is committed.

## Requirements

1. **HD texture packs**
   - Dump mode: write every unique tile/sprite (8x8 tiles, OBJ shapes, affine BG tiles, bitmap-mode frames) as PNG, keyed by a hash of pixel data + palette (with a palette-independent variant key so one HD image can serve palette swaps), with a JSON index (first-seen frame, layer, usage count).
   - Load mode: a pack folder (`hdpacks/<game code>/`) with PNGs at any integer scale (2x-16x) replaces originals at render time; missing entries fall back to the original (filtered); hot reload while the game runs for pack authors.
   - The PPU renders at internal scale N (compositing layers, windows, blending, mosaic, affine) so HD art composes correctly; pack metadata for multi-tile sprites (assemble by OBJ, not only 8x8).
   - Pack format documented (`docs/user/HD-PACKS.md`); pack creator tool: dump, de-duplicate, preview, and batch import.
2. **Math upscaling** (beyond phase 11): edge-directed scalers applied per layer before compositing (sharper than whole-frame scaling), and an internal-resolution affine/rotation renderer (Mode 7 style BGs and rotated sprites rendered at N x without stair-stepping).
3. **AI upscaling**
   - Offline: `anygba hdpack ai-upscale` runs an upscaling model over a dump to generate a full HD pack (GPU via ONNX Runtime DirectML/CUDA/CPU), so every game can get an AI pack in minutes.
   - Real-time: an optional small model on the final frame or per layer on the GPU, keeping 60 fps at 1080p on this PC; off by default.
   - Models: only models whose weights have permissive licences (e.g. Real-ESRGAN family, BSD-3) downloaded on first use with hash pinning, not committed; record provenance.
4. **Widescreen**
   - Per-game 16:9 (and 16:10) mode: render extra columns left/right from the BG tilemaps and sprites the game already has in VRAM; HUD/text layers kept centred via per-game layer rules; per-game hacks in config (e.g. camera/culling patches, tilemap streaming wider) where the game only streams tiles near the view.
   - Emerald first: overworld and battle scenes in 16:9 without visible garbage; fall back to pillarbox where a scene cannot be widened.
5. Menu (Video page), CLI and game TOML options for all of the above; runtime toggles without restart.

## Files

- `runtime/src/video/` (internal-scale PPU path, pack loader, AI runner), `tools/hdpack/`, `docs/user/HD-PACKS.md`, `docs/user/WIDESCREEN.md`, `compat/` widescreen fields.

## Validation

- Headless: dump/reload round trip on a corpus homebrew game gives the identical frame at 1x with an identity pack; a synthetic 4x pack replaces tiles exactly; internal-scale PPU matches the 1x PPU when downsampled; widescreen keeps the centre 240x160 identical to normal mode; AI offline upscale produces a pack and timing for the real-time path is recorded.
- Emerald checked headless at several scenes (overworld, battle, menu) with screenshots kept outside the repo.

## Risks

- Palette-cycling and procedurally drawn tiles produce many hashes; mitigate with palette-independent keys and dump filters.
- Widescreen needs per-game work; document per-game status in compat.
- AI model size and GPU availability; CPU fallback for offline only.
