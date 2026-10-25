---
phase: 7
title: "Game bring-up and coverage tracking"
status: in-progress
effort: ongoing
dependsOn: [6]
---

# Phase 07: Game bring-up and coverage tracking

## Context

Coverage tracking turns a per-game hack into a framework other people can push forward, as AnyPS5's progress map does.

## Requirements

- Coverage badges: HLE functions by NID, VFPU opcodes, GE commands.
- Compat records per title (stage, hosts, blockers), no game data committed.
- Bring-up discussion template and CONTRIBUTING with the legal policy.

## Files (create)

- `compat/*.toml`, `tools/compat-site/` (shared format with AnyGBA), `.github/workflows/pages.yml`, `CONTRIBUTING.md`

## Steps

1. Coverage extraction from the build and runtime logs.
2. Site generation and publishing.
3. Bring up five titles of different genres.

## Validation

- Plan acceptance criteria in `plan.md` all met.

## Rollback

Docs and CI only.

## Progress (2026-10-25, branch feat/hosts-and-compat)

- [x] Coverage extraction: HLE by NID (anypsp-hle-coverage, hle-coverage.json), VFPU instructions translated natively (anypsp-coverage), GE commands (scan in tools/compat-site/generate.py)
- [x] Compat records (compat/*.toml, schema.md) and the site generator with badges; pages.yml publishes once Pages is enabled (PAGES_ENABLED)
- [x] CONTRIBUTING.md with the legal policy, bring-up discussion template
- [x] UNH 1 (ULUS-10299) entry with headless evidence and the slow `unh1_regression` ctest (skips without the disc)
- [ ] Five titles of different genres in-game, two playable start to finish (only UNH 1 locally; needs more games)
