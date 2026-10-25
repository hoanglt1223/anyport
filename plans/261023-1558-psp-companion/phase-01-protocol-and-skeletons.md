---
phase: 1
title: "Protocol, pairing, host and PSP skeletons"
status: in-progress
effort: 1-2w
dependsOn: []
---

# Phase 01: Protocol, pairing, host and PSP skeletons

## Context

Every feature rides on one connection between PSP and host. Getting it right first keeps the features independent.

## Requirements

- Discovery by UDP broadcast on the LAN; manual IP entry as a fallback.
- Pairing: the host shows a 6-digit PIN; the PSP enters it through the on-screen keyboard (`sceUtilityOsk`); both derive a shared key (PAKE-style or PIN-salted key derivation). The key is stored in the PSP save folder and the host config.
- Transport: one TCP control channel (length-prefixed messages, versioned) plus one UDP channel for audio; ChaCha20-Poly1305 encryption (cheap on the PSP CPU).
- Message types: hello/version, ping, widget data, input events, macro trigger, voice upload, voice reply text, audio stream control and packets, Stream Deck key images and presses.
- PSP skeleton: Wi-Fi profile selection dialog, connect, show status (including live throughput), reconnect on drop.
- Wi-Fi budget built into the protocol: push-on-change only, no PSP-side polling, keepalive at most every 15 seconds, and a host-side rate limiter that enforces the 300 kbps total cap from `plan.md`.
- Host skeleton (Rust): system tray app, config file, logs, pairing UI.

## Files (create)

- `psp-companion/protocol/PROTOCOL.md` (message spec)
- `psp-companion/host/` (Rust: `main.rs`, `net/`, `pairing.rs`, `config.rs`, `tray.rs`)
- `psp-companion/psp/` (C: `main.c`, `net.c`, `crypto.c`, `ui.c`, `Makefile`)

## Steps

1. Write the protocol spec.
2. Host: discovery, pairing, encrypted channel, tray.
3. PSP: Wi-Fi connect, discovery, pairing, encrypted channel, status screen.
4. Test on the user's router (2.4 GHz, WPA2-AES).

## Validation

- PSP pairs with the host, survives Wi-Fi drops, and measures throughput and round-trip time on the status screen.

## Risks

- Router incompatibility with 802.11b clients. Document the needed router settings.

## Rollback

Greenfield; delete the branch.

## Implementation status

- [x] Protocol spec, host discovery/pairing/encrypted channels/tray, PSP client (cargo tests and C-vs-Rust cross-checks green on Linux).
- [x] Pairing key stored in the PSP save folder (`ms0:/PSP/SAVEDATA/PSPCOMPAN0000`, system save utility); an old `pairing.dat` beside the EBOOT is migrated and removed. Verified in PPSSPPHeadless: a legacy file was moved into the save and the app went straight to "Connecting to <PC>".
- [x] PPSSPPHeadless smoke: the EBOOT boots to the pairing screen (Wi-Fi dialog, discovery, "No PC found" without a host).
- [ ] Router test with the user's 2.4 GHz WPA2-AES network and real pairing on the PSP-3000 (needs the hardware).
