---
phase: 4
title: "Audio"
status: pending
effort: 1-2w
dependsOn: [2]
---

# Phase 04: Audio

## Context

N64 audio is synthesised from command lists (the audio microcode). PC ports run this synthesis in C and output PCM. On PSP the same code runs, with output through `sceAudio`.

## Requirements

- Audio synthesis on a dedicated PSP thread with a ring buffer to `sceAudioOutputBlocking`.
- Output rate matching the game's rate (often 32 kHz); resample to 44.1 kHz if needed.
- Profile synthesis cost; if above ~15% of a frame, move it to the Media Engine or reduce voices.

## Files (create, in the game fork)

- `port/psp/audio_psp.c`

## Steps

1. Port the PC audio output path to `sceAudio`.
2. Profile and optimise.

## Validation

- Music and effects play without crackle for 10 minutes on the PSP-3000.

## Risks

- CPU contention with rendering. The Media Engine offload is the fallback.

## Rollback

Port-only file; revert.
