---
phase: 6
title: "Asset extraction, packaging, release"
status: pending
effort: 1w
dependsOn: [5]
---

# Phase 06: Asset extraction, packaging, release

## Context

Releases must not contain any game data. Users extract assets from their own ROM.

## Requirements

- Asset extraction runs on PC with the upstream extractor, verified by ROM hash; output written into the PSP game folder layout. Optional on-device extraction if memory allows.
- `EBOOT.PBP` with icon and title (original art, not Nintendo assets).
- Install guide for PSP-3000 with ARK-4: folder layout, controls, known issues.
- Release CI builds the EBOOT only.

## Files (create, in the game fork)

- `port/psp/extract.md` (user guide), `port/psp/icon0.png`, `.github/workflows/psp-release.yml`

## Steps

1. Wire the extractor output to the PSP layout.
2. Package and write the guide.
3. Do a clean install on the PSP-3000 from the guide alone.

## Validation

- A clean install from the guide works on the PSP-3000.
- Plan acceptance criteria in `plan.md` all met.

## Risks

- Users with a different ROM revision. Support only the revisions the upstream extractor supports and say so clearly.

## Rollback

Packaging only; revert.
