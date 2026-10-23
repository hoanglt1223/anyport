---
phase: 1
title: "Evaluate PSPRecomp and prior ports, choose base"
status: in-progress
effort: 2w
dependsOn: []
---

# Phase 01: Evaluate PSPRecomp and prior ports, choose base

## Context

Several PSP static recompilation efforts exist. Building on them is cheaper than starting over, if their design allows a game-agnostic pipeline.

## Requirements

- Locate the upstream PSPRecomp repository and the ports built on it (PSP2I_Recomp, the GTA LCS/VCS and Ace Combat X recomps, PSP Web Recomp). Record license, activity, maintainers, supported games.
- Assess: how much is per-game (hand-written patches, hard-coded addresses) vs generic; VFPU coverage; HLE module structure; renderer design; build hosts.
- Build PSPRecomp against one homebrew PSP binary (open source, built with pspdev) to test the pipeline without commercial data.
- Decide one of: contribute upstream, fork, or new project. Record the decision with reasons.
- Pick the project license accordingly (GPL-2.0+ if PPSSPP code will be adapted).

## Files (create)

- `docs/dev/prior-art.md`, `docs/dev/decision-base.md`

## Steps

1. Survey and clone the projects.
2. Build and run the homebrew test.
3. Contact the maintainers if contributing is the likely path.
4. Write the decision.

## Exit criteria (gate)

- A written decision and, if contributing or forking, agreement on scope with upstream where possible.

## Rollback

Research only.
