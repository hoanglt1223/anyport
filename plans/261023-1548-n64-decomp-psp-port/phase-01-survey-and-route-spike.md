---
phase: 1
title: "Prior-art check, game choice, and route spike"
status: in-progress
effort: 2w
dependsOn: []
---

# Phase 01: Prior-art check, game choice, and route spike

## Context

Choosing the right game and the right base decides whether this fits in the PSP's memory and CPU budget. This phase measures instead of guessing.

## Requirements

- Prior-art check on GitHub and PSP homebrew sites for PSP ports of: Super Mario 64, Star Fox 64, Mario Kart 64, Ocarina of Time, Majora's Mask, Paper Mario, and pokeemerald/pokefirered. Record findings with links.
- For each candidate without a PSP port, measure on a PC build: peak heap, asset footprint, display-list triangles per frame, and texture memory per frame.
- Compare two routes:
  - Route A: `libultraship` fork with a new GE backend (benefit: one backend unlocks SF64, MK64, OoT).
  - Route B: original decomp C + slim Fast3D + libultra shim (benefit: much lower memory and code size).
- Build a minimal PSP spike for the chosen route: boot to the game's first rendered frame, any visual quality.

## Files (create)

- `docs/dev/survey.md` (prior art, measurements, decision)
- Spike branch in the chosen fork

## Steps

1. Run the prior-art search; drop any game that already has a good PSP port.
2. Build PC versions of the remaining candidates; collect measurements.
3. Pick the game and the route; record the reason.
4. Build the boot-to-first-frame spike on PPSSPP, then on the PSP-3000.

## Exit criteria (gate)

- Go: the spike reaches a first rendered frame on the PSP-3000 and the measured peak heap is under 45 MB (leaving headroom).
- No-go: neither route fits. Then choose a lighter game (for example Star Fox 64 over OoT) and repeat.

## Risks

- Measurements on PC overstate memory (64-bit pointers, desktop allocators). Note pointer-size effects; PSP is 32-bit.

## Rollback

Spike branch only.
