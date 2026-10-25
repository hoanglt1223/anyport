---
title: "PSP Companion: Claude voice client, secondary screen, and PC speaker on a PSP-3000"
description: "Turn the PSP-3000 into a low-bandwidth Wi-Fi companion for the PC: push-to-talk Claude assistant using the built-in microphone, a widget secondary screen with cursor input and macro buttons, a Stream Deck mode, and wireless speakers for PC audio."
status: in-progress
priority: P2
effort: 6-8w part-time
branch: main
tags: [feature, psp, ai, companion]
blockedBy: []
blocks: []
created: 2026-10-23
---

# PSP Companion

## Overview

Two programs talk over the local network:

- **`companion-psp`** (C, pspsdk, runs on the PSP-3000 with ARK-4): UI, microphone capture, audio playback, widget rendering, input.
- **`companion-host`** (Rust, runs on the PC): owns the Claude API key, speech-to-text, text-to-speech, widget data, screen capture, PC audio capture, and macro execution.

The PSP never talks to the internet; the host does. This sidesteps the PSP's weak TLS and keeps the API key off the device.

## Hardware facts that shape the design

- The PSP-3000 has a **built-in microphone** (`sceAudioInput`), speakers, a 480x272 screen, 802.11b Wi-Fi (about 1-2 Mbps real throughput), and a Media Engine that decodes MP3 and H.264 cheaply.
- The PSP has **no touchscreen**. "Touch" is the analog nub driving a cursor with X as tap, plus the D-pad and face buttons as macro keys (Stream Deck style).
- Audio must be compressed: 44.1 kHz stereo PCM (1.4 Mbps) does not fit 802.11b reliably. MP3 at 96 kbps (music) or 48 kbps mono (speech) decoded on the Media Engine does.

## Features and acceptance criteria

1. **Claude voice assistant:** hold R, speak (Vietnamese or English), release. The answer appears as text on the PSP and is spoken through its speakers within about 3 seconds of a short reply on a home network. Conversation history kept on the host.
2. **Secondary screen:** native widgets (clock, CPU/GPU/RAM, now playing, notifications, calendar, Claude Code session status) drawn on the PSP from small JSON updates.
3. **Input:** cursor and tap on widgets; twelve macro slots mapped to host actions (media keys, mute mic, run a script, open an app).
4. **PC speaker:** PC system audio plays on the PSP with under 300 ms latency, selectable from the PSP.
5. **Stream Deck mode:** the PSP acts as a Bitfocus Companion Satellite surface, showing a grid of live button images and triggering any Bitfocus integration (OBS, vMix, Spotify, Home Assistant, hotkeys).
6. Pairing with a PIN; all traffic encrypted with a session key; the API key never leaves the host.

## Wi-Fi budget (hard constraint)

The PSP-3000 only has 802.11b, with about 1-2 Mbps of real throughput and high latency. Every feature must stay small on the network:

- No video over Wi-Fi. Screen mirroring and game streaming are out of scope.
- Sustained traffic stays under 300 kbps in total; only one audio stream (assistant reply or PC speaker) plays at a time.
- Data is pushed only when it changes, coalesced, and compressed. No polling from the PSP.
- Images are small and cached on the PSP; nothing is re-sent unless it changed.
- The status screen shows live throughput so regressions are visible.

## Non-goals

- Webcam (the PSP-3000 has none without the Go!Cam accessory). Using the PSP as a PC microphone. Internet access from the PSP itself.
- Screen mirroring and Steam/PC game streaming (too heavy for 802.11b; Moonlight PSP already exists for anyone who wants streaming anyway).

## Phases

| # | Phase | Effort | Depends on | Status |
|---|---|---|---|---|
| 01 | [Protocol, pairing, host and PSP skeletons](phase-01-protocol-and-skeletons.md) | 1-2w | none | in-progress |
| 02 | [Claude voice assistant](phase-02-claude-voice-assistant.md) | 2w | 01 | in-progress |
| 03 | [Secondary screen: widgets, cursor, macros](phase-03-secondary-screen.md) | 1-2w | 01 | in-progress |
| 04 | [PC audio to PSP speakers](phase-04-pc-speaker.md) | 1w | 01 | in-progress |
| 05 | [Polish, battery, packaging](phase-05-polish-and-packaging.md) | 1w | 02, 03, 04 | in-progress |
| 06 | [Stream Deck mode (Bitfocus Companion Satellite)](phase-06-stream-deck-mode.md) | 1w | 03 | in-progress |
Phases 02, 03, and 04 can run in parallel after 01.

## Dependencies

- Claude API on the host (model configurable; default the latest Opus, with a faster model option for lower voice latency).
- Speech-to-text: whisper.cpp locally (good Vietnamese support) or a hosted STT API, selectable.
- Text-to-speech: a local Piper voice or a hosted TTS, selectable, with Vietnamese voices.
- Moonlight PSP (GPL-3.0) as a reference for Media Engine usage on PSP.

## Key risks

- Wi-Fi: 802.11b and WPA2 compatibility with modern routers. Document a 2.4 GHz SSID setup; test with the user's router in phase 01.
- Voice latency: STT + Claude + TTS. Stream the Claude response and start TTS on the first sentence.
