---
phase: 7
title: "Game bring-up and coverage tracking"
status: pending
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
