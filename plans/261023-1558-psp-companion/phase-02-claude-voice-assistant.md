---
phase: 2
title: "Claude voice assistant"
status: in-progress
effort: 2w
dependsOn: [1]
---

# Phase 02: Claude voice assistant

## Context

Push-to-talk on the PSP, intelligence on the host.

## Requirements

- PSP: hold R to record from the built-in mic with `sceAudioInput` (mono, 22.05 kHz or 11.025 kHz), compress to ADPCM, stream to the host while recording; level meter on screen.
- Host: speech-to-text (whisper.cpp local by default, hosted option), language auto-detect for Vietnamese and English.
- Host: call the Claude API with streaming; keep conversation history per session; system prompt tuned for short spoken answers; model configurable.
- Host: sentence-by-sentence text-to-speech (Piper local by default, hosted option), encode to mono MP3 at 48 kbps (speech does not need more), stream to the PSP.
- Mic upload is mono 11.025 kHz ADPCM (about 44 kbps) and only while R is held.
- PSP: show the transcript and the streaming reply text (with a font that covers Vietnamese diacritics), play MP3 through the Media Engine, L+R to stop speaking, scroll history with the D-pad.
- Errors (no network, API error, rate limit) shown in plain words on the PSP.

## Files (create)

- `host/src/voice/stt.rs`, `voice/tts.rs`, `voice/claude.rs`, `voice/session.rs`
- `psp/voice.c`, `psp/mp3_player.c`, `psp/text_view.c`, `psp/assets/font-vi.*`

## Steps

1. Mic capture and upload; host saves a WAV for checking.
2. STT and Claude round trip with text-only reply.
3. TTS and MP3 playback with streaming start.
4. History and error handling.

## Validation

- Ten Vietnamese and ten English questions answered correctly; first audio within about 3 seconds for short answers on the home network.

## Risks

- Mic quality on the PSP-3000 is low. Apply noise suppression on the host before STT.
- API cost from accidental long recordings. Cap recordings at 60 seconds.

## Rollback

Feature-scoped; revert.

## Implementation status

- [x] Push-to-talk, mic cleanup, whisper.cpp / hosted STT, streaming Claude client, Piper / hosted TTS, history and error notices (host tests with local test servers).
- [x] Real engines on Linux: whisper.cpp built from source (`base` model) and the Piper 2023.11.14-2 release with `en_US-amy-medium` and `vi_VN-vais1000-medium`; the gated tests pass, including a Piper-to-whisper.cpp round trip (`piper_speech_round_trips_through_whisper`).
- [ ] Live Claude API run (needs the user's API key).
- [ ] Ten Vietnamese and ten English questions on the PSP-3000 with first audio within about 3 s (needs the hardware).
