---
phase: 5
title: "Polish, battery, packaging"
status: pending
effort: 1w
dependsOn: [2, 3, 4]
---

# Phase 05: Polish, battery, packaging

## Context

A companion device has to be pleasant to leave running all day.

## Requirements

- Power: lower CPU clock when idle, dim the screen after inactivity, Wi-Fi power save between widget updates; show battery level.
- Home menu: Assistant, Screen, Macros, Speaker, Settings.
- Host installer for Windows (MSI or a single exe with autostart option); config UI for STT/TTS/model choice, widgets, macros.
- `EBOOT.PBP` with original icon art; install guide for PSP-3000 with ARK-4; troubleshooting for Wi-Fi.

## Files (create)

- `psp/power.c`, `psp/menu.c`, `psp/ICON0.PNG`
- `host/packaging/*`
- `docs/user/INSTALL.md`, `docs/user/TROUBLESHOOTING.md`

## Steps

1. Power management and menu.
2. Host packaging.
3. Clean install from the guide on the user's PSP-3000 and PC.

## Validation

- All acceptance criteria in `plan.md` met; the PSP runs as a screen for at least 4 hours on battery with widgets only.

## Rollback

Packaging only.
