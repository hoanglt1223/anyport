---
phase: 1
title: "Prior-art check and feature census"
status: completed
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
- Choose the supported subset from the census. (The original target of 10 of 15 games was not reachable without a Python runtime: 5 of 15 are covered. The user narrowed the scope on 2026-10-23, see the gate.)

## Files (create)

- `rpy2psp/docs/dev/prior-art.md`, `docs/dev/census.md`, `tools/census/`

## Steps

1. Prior-art search.
2. Census run and subset decision.

## Exit criteria (gate)

- Subset documented in `docs/dev/census.md` and `tools/census/subset.json`: met.
- Three target games fully inside it (The Question, Zero Echoes, Arcance): met.
- Corpus coverage measured and reported (5 of 15, the user-accepted replacement for "10 of 15"): met.

## Rollback

Research only.
