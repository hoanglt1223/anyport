---
phase: 4
title: "PC audio to PSP speakers"
status: in-progress
effort: 1w
dependsOn: [1]
---

# Phase 04: PC audio to PSP speakers

## Context

The PSP becomes a wireless speaker. Capture happens on the host; decoding uses the Media Engine so the PSP CPU stays free.

## Requirements

- Host: capture system audio with WASAPI loopback (Windows) or a selected output device; encode MP3 at 96 kbps stereo in small frames; send over UDP with sequence numbers; stop sending during silence (no packets for silent stretches).
- Only one audio stream at a time: starting the voice assistant reply pauses the speaker stream instead of mixing two streams over Wi-Fi.
- PSP: jitter buffer (target 150-250 ms), MP3 decode on the Media Engine, `sceAudio` output, volume on the PSP buttons; packet-loss concealment by repeating or muting a frame.
- Start/stop from the PSP menu.
- Optional on the host: switch the PC default output to a silent device while streaming (documented, user-controlled).

## Files (create)

- `host/src/audio/capture.rs`, `audio/encode_mp3.rs`, `audio/stream.rs`
- `psp/audio_stream.c`

## Steps

1. Loopback capture and MP3 encoding.
2. PSP jitter buffer and playback.
3. Pause and resume around voice assistant replies.

## Validation

- 30 minutes of music without dropouts on the home network; measured end-to-end latency under 300 ms.

## Risks

- Wi-Fi bursts. Adaptive jitter buffer grows on loss and shrinks when stable.

## Rollback

Feature-scoped; revert.
