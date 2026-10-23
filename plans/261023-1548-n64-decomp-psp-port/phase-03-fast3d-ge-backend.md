---
phase: 3
title: "Fast3D GE renderer backend"
status: pending
effort: 3-4w
dependsOn: [2]
---

# Phase 03: Fast3D GE renderer backend

## Context

Fast3D interprets the game's N64 display lists (F3D/F3DEX/F3DEX2 microcode commands) and calls a backend to draw triangles. The PC ports have OpenGL/DirectX/Metal backends; this phase adds one for the PSP GE.

## Requirements

- Vertex transform and lighting on the VFPU (or the GE's hardware transform when the matrix model allows), clipping, fog.
- Textures: convert N64 formats (RGBA16/32, IA, I, CI4/CI8) to GE formats once and cache them by address and TLUT; respect wrap/mirror/clamp; texture size limits (pad to power of two up to 512).
- Combiner: map the most common combiner modes (texture × shade, texture only, shade only, texture × prim, decal) onto GE texture functions and vertex colors; log unmapped modes with their frequency.
- Blending and depth: N64 render modes to GE blend, alpha test, depth test/write, and decal depth bias.
- Render at 480x272 with the game's 4:3 viewport centred, or a 16:9 fit if the PC port supports it cheaply.

## Files (create, in the game fork)

- `port/psp/gfx_ge.c`, `gfx_ge_textures.c`, `gfx_ge_combiner.c`, `gfx_vfpu.c`

## Steps

1. Untextured shaded triangles.
2. Texture conversion and cache.
3. Combiner mapping, ordered by measured frequency in the chosen game.
4. Render modes, fog, decals.

## Validation

- The first level renders recognisably on the PSP-3000; a screenshot comparison with the PC port lists remaining visual differences.

## Risks

- Texture cache thrash in 2 MB VRAM. Keep textures in main RAM and let the GE read them there when VRAM is full.

## Rollback

Port-only files; revert.
