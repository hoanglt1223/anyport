---
phase: 7
title: "Game bring-up and compatibility list"
status: in-progress
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

## Implementation status (2026-10-25, branch `feat/export-and-compat`)

- [x] Compat format `compat/*.toml` (AnyGBA's stages and fields plus SWF/AS version, targets, PSP fps, unimplemented APIs; `compat/schema.md`)
- [x] `tools/compat-site/generate.py` adapted from AnyGBA, with unit tests; `.github/workflows/pages.yml` validates on every change and deploys only once Pages is enabled and `PAGES_ENABLED` is `true`
- [x] `CONTRIBUTING.md`: no-SWF policy and tester guide (build, play, report)
- [x] Compat entries for the self-made corpora (5 AS2, 13 generated render movies) and the vendored Ruffle suites
- [ ] Bring up ten AS2 games and fix the most common missing APIs (needs game SWFs, not on this box)
- [ ] Plan acceptance criteria (three games at native frame rate on a PSP-3000)
