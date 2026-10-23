---
phase: 7
title: "Game bring-up and compatibility list"
status: pending
effort: ongoing
dependsOn: [6]
---

# Phase 07: Game bring-up and compatibility list

## Context

From here, progress is per game. Reuse the compat tracker format from AnyGBA (`compat/*.toml` rendered to a static page) so all projects report the same way.

## Requirements

- Compat record per SWF (title, SWF version, stage: renders/menus/playable/perfect, PSP fps, unimplemented APIs, notes). No SWF content committed.
- A short tester guide: how to build an EBOOT from a SWF and report results.

## Files (create)

- `compat/*.toml`, `tools/compat-site/`, `.github/workflows/pages.yml`
- `CONTRIBUTING.md`

## Steps

1. Import the compat site generator.
2. Bring up ten more AS2 games; fix the most common missing APIs.

## Validation

- Plan acceptance criteria in `plan.md` all met.

## Risks

- Contributors attaching copyrighted SWFs. State the policy in CONTRIBUTING and reject such PRs.

## Rollback

Docs and CI only; revert.
