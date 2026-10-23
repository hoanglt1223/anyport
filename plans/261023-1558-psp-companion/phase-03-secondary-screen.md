---
phase: 3
title: "Secondary screen: widgets, cursor, macros"
status: pending
effort: 1-2w
dependsOn: [1]
---

# Phase 03: Secondary screen

## Context

Widgets are drawn natively on the PSP from small data updates, which keeps them sharp and keeps Wi-Fi traffic tiny. Input replaces the missing touchscreen with a cursor and macro buttons.

## Requirements

- Widgets drawn natively from compact JSON (or a binary equivalent) that the host pushes only when a value changes, coalesced to at most one update per second per widget: clock (local tick on the PSP, no network), CPU/GPU/RAM/temperatures, now playing (title, artist, 64x64 cover JPEG sent once per track), notifications, next calendar event, Claude Code session status.
- Layouts: three pages switched with L/R; layout file on the host, sent once at connect.
- Cursor: analog nub moves a cursor with acceleration; X = tap; taps trigger widget actions on the host.
- Macro pad: Triangle opens a 3x4 grid of twelve macro slots; each slot runs a host action (media keys, mute mic, run a command, open an app, send a hotkey). Configured on the host; only the slot ID crosses the network.
- Wi-Fi budget: widgets alone average under 5 kbps.

## Files (create)

- `host/src/widgets/*.rs` (data sources and change detection), `host/src/macros.rs`
- `psp/widgets.c`, `psp/cursor.c`, `psp/macros.c`

## Steps

1. Widget pipeline with three widgets, then the rest.
2. Cursor and widget taps.
3. Macro pad.

## Validation

- Widgets update within one second of host changes; measured average traffic under 5 kbps over one hour.

## Rollback

Feature-scoped; revert.
