---
phase: 1
title: "Prior-art check and feature census"
status: blocked
effort: 1w
dependsOn: []
---

# Phase 01: Prior-art check and feature census

## Context

Decide the supported subset from data, not guesses.

## Requirements

- Search for existing Ren'Py-to-console converters or PSP VN engines that could be reused.
- Pick 15 free Ren'Py games of different sizes and eras (Ren'Py 6, 7, 8).
- Census script (runs on PC with Ren'Py's own parser) counting statement types, ATL features, transitions, Python statement shapes, screen usage, and asset formats per game.
- Choose the supported subset that covers at least 10 of the 15 games fully.

## Files (create)

- `rpy2psp/docs/dev/prior-art.md`, `docs/dev/census.md`, `tools/census/`

## Steps

1. Prior-art search.
2. Census run and subset decision.

## Exit criteria (gate)

- Subset documented; at least three target games fully inside it.

## Rollback

Research only.
