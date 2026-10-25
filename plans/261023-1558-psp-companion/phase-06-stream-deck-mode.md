---
phase: 6
title: "Stream Deck mode (Bitfocus Companion Satellite)"
status: in-progress
effort: 1w
dependsOn: [3]
---

# Phase 06: Stream Deck mode

## Context

Bitfocus Companion is open-source Stream Deck software with hundreds of integrations. Its Satellite API lets remote devices act as button surfaces. Making the PSP a Satellite surface gives it every integration without writing them.

## Requirements

- Verify the current Satellite API version and transport (documented TCP protocol) before implementing.
- `companion-host` bridges Bitfocus Satellite to the PSP: registers a virtual surface with a 6x3 key grid, receives key images (scaled to about 76x86 px) and text, forwards key presses and releases.
- PSP: draws the grid full screen; selection with D-pad or analog cursor, press with X; L/R switch Bitfocus pages; long-press supported (press and release events are sent separately).
- Wi-Fi budget: the host converts each key image to a palettised, compressed bitmap before sending; images are cached on the PSP by hash; only changed keys are re-sent, coalesced to at most 5 key updates per second. Animated keys are shown as static frames.
- Fallback when Bitfocus is not installed: the built-in 12-slot macro pad from phase 03.

## Files (create)

- `host/src/streamdeck/satellite.rs`, `host/src/streamdeck/bridge.rs`
- `psp/streamdeck.c`

## Steps

1. Read the Satellite API docs; test with a Satellite reference client.
2. Host bridge, then PSP grid rendering and input.

## Validation

- With Bitfocus Companion running, OBS scene switching and a Spotify play/pause button work from the PSP; key images update within one second.

## Risks

- API changes between Bitfocus versions. Pin and document the supported version range.

## Rollback

Feature-scoped; revert.

## Implementation status

- [x] Satellite client, PSP surface, key image cache, page switching; e2e test against a local Satellite server.
- [x] Version range pinned in code and docs: Satellite API 1.5 to 1.x (Companion 3.2+, pages need 4.3+), written against API 1.15 (Companion 5.2, `TESTED_API`); newer 1.x servers log a notice, 2.x is refused.
- [ ] OBS scene switch and Spotify play/pause from the PSP with a real Bitfocus Companion (needs the PSP and a desktop with Companion).
