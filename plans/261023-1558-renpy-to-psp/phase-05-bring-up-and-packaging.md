---
phase: 5
title: "Bring-up and packaging"
status: pending
effort: 1-2w
dependsOn: [4]
---

# Phase 05: Bring-up and packaging

## Context

Prove the converter on several games and make it usable by others.

## Requirements

- All three target games playable start to finish on the PSP-3000.
- `rpy2psp build` single command on Windows (Python packaged with its dependencies).
- Compat list in the shared format; user guide and the list of supported Ren'Py features.

## Files (create)

- `compat/*.toml`, `docs/user/USAGE.md`, `docs/user/SUPPORTED-FEATURES.md`, `.github/workflows/release.yml`

## Steps

1. Bring up the three targets and fix gaps.
2. Package and document.

## Validation

- Plan acceptance criteria in `plan.md` all met.

## Rollback

Docs and packaging only.
