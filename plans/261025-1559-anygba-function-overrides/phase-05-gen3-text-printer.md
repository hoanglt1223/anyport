---
phase: 5
title: "Gen 3 text printer override, Emerald and FireRed"
status: pending
effort: 1-1.5w
dependsOn: [4]
---

# Phase 05: Gen 3 text printer override, Emerald and FireRed

## Context

The first real use: the dialogue overlay added on 2026-10-25 draws text over the game's box by
reading memory each frame. With overrides, the Gen 3 text printer itself can hand each glyph run to
the host, so English and Vietnamese text render through the host font at window resolution inside
the game's own layout, with no overlay box and with scrolling, colours and speed preserved.

## Requirements

1. Decomp (phase 04) and verify (phase 03) the Gen 3 text printer path: glyph rendering into window
   tiles and the per-frame printer step; keep the original as fallback.
2. Override renders glyphs into a host text layer aligned to the game window/tiles; colours from the
   printer's palette; translation (existing table) applied at the string level.
3. Engine module `overrides/pokemon-gen3/` used by Emerald and FireRed, differing only in symbol
   tables (FireRed symbols from the pret/pokefirered reference, user's own ROM).
4. Toggle in the menu next to "Dialogue translation"; falls back to the overlay when the override is
   off.

## Files

- `overrides/pokemon-gen3/` (engine module, no ROM data), `compat/symbols/BPEE.toml`, a FireRed
  symbols file, `docs/user/TRANSLATION.md`

## Steps

1. Decomp + difftest the printer functions; enable for Emerald.
2. Host glyph layer and palette mapping; screenshots in field and battle.
3. FireRed symbols; same module; screenshots.

## Validation

- Difftest passes for every overridden printer function (≥10,000 states, recorded real states
  included).
- Headless screenshots at 1920x1080 in field, battle and menu text for Emerald and FireRed show host
  font text, correct colours and page breaks; frame pacing at 60 fps.
- With overrides off, frame hashes match the current build.

## Risks and rollback

- Battle and menu windows may use different printers; cover them one by one and keep the overlay
  path for any not yet overridden.
