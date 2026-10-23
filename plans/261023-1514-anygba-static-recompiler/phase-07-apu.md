---
phase: 7
title: "APU"
status: completed
effort: 1w
dependsOn: [4]
---

# Phase 07: APU

## Context

GBA audio is four legacy Game Boy channels plus two 8-bit DirectSound FIFOs that games feed through DMA 1/2, clocked by timer 0 or 1 overflow. Most commercial games use the Nintendo "m4a"/Sappy engine, which runs in game code and only needs the FIFOs to be correct.

## Requirements

- PSG channels: two square (one with sweep), wave RAM, noise; envelopes, length, frequency.
- FIFO A/B (32 bytes each), refill DMA request when half empty, timer-driven sample pop.
- Mixer honouring SOUNDCNT_L/H/X and SOUNDBIAS; resample to 48 kHz for the platform stream.

## Files (create)

- `runtime/src/apu/apu.cpp`, `apu/psg.cpp`, `apu/fifo.cpp`, `apu/mixer.cpp`
- `tests/runtime/apu_tests.cpp`

## Steps

1. FIFO and DMA sound path first (covers most games).
2. PSG channels.
3. Mixer and resampler; audio-driven frame sync from phase 04.

## Validation

- Butano audio example and a tonc sound demo play without crackle for 5 minutes.
- Waveform capture compared with mGBA output (correlation above 0.99 on PSG test tones).

## Risks

- Buffer underruns from frame pacing jitter. Use a dynamic rate control on the resampler.

## Rollback

Isolated module; revert.
