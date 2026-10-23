---
phase: 5
title: "GameMaker 8 via OpenGMK (spike first)"
status: pending
effort: 2-6w
dependsOn: [1]
---

# Phase 05: GameMaker 8 via OpenGMK

## Context

OpenGMK reimplements the GameMaker 8 runner in Rust. Rust can target the PSP through the `rust-psp` toolchain (`mipsel-sony-psp`). This is the riskiest runner, so it starts with a one-week spike.

## Requirements

- Spike: build OpenGMK's runner core for `mipsel-sony-psp`, replacing its desktop window, renderer, and audio backends with PSP stubs; measure memory for three small GM8 games.
- If the spike fits (under 45 MB peak for small games): implement a GE renderer backend, audio through `sceAudio`, input mapping (keyboard keys to PSP buttons per game config, mouse to analog nub cursor).
- Load GM8 `.exe` game data from the Memory Stick (data extracted by OpenGMK's own decoder).

## Files (create, in the fork)

- PSP backend crate and build configuration

## Validation

- Go: three small GM8 games playable. No-go: a written report with memory and speed measurements.

## Risks

- OpenGMK's design favours accuracy (it was built for TAS replays), which can mean high memory use. The spike decides.
