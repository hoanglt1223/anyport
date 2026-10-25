---
phase: 5
title: "Polish, battery, packaging"
status: in-progress
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

## Implementation status

- [x] `psp/power.c`: battery badge and estimate, CPU 222 -> 133 MHz after 15 s idle, system backlight auto-off for dimming (or keep the screen on), no auto-sleep, WLAN power save setting, reconnect after resume.
- [x] START menu (`psp/menu.c`): Screen, Assistant, Macros, Stream Deck, PC speaker, Settings.
- [x] Original `ICON0.PNG` and `PIC1.PNG` drawn by `tools/make-psp-art.py`; settings and pairing in the system save.
- [x] Host settings page at `http://127.0.0.1:<ingest_port>/settings` (STT/TTS/model, speaker device, Stream Deck, widgets, macros, Pair new PSP), loopback Host check and per-run token; tray "Settings..." item.
- [x] Windows installer `host/packaging/windows/companion-host.iss` (Inno Setup 6, sign-in autostart and private-network firewall rule as options); compiles under Inno Setup 6 in Wine.
- [x] Linux tarball `host/packaging/linux/package.sh` (headless build, `install.sh`, systemd user unit); installed into a scratch home and the host served the settings page and a pairing PIN.
- [x] `docs/user/INSTALL.md`, `FEATURES.md`, `TROUBLESHOOTING.md`.
- [x] `.github/workflows/ci.yml` (Linux fmt, clippy, tests, tarball; EBOOT build) and `release.yml` (Windows exe and installer, Linux tarball, EBOOT zip); actionlint clean.
- [ ] Run the Windows installer on a Windows PC (autostart, firewall rule, uninstall).
- [ ] Clean install from the guide on the user's PSP-3000 and PC; 4 hours on battery with widgets only (needs the hardware).
