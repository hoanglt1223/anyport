# Phase 01 report: protocol, pairing, host and PSP skeletons

Plan: `plans/261023-1558-psp-companion/phase-01-protocol-and-skeletons.md` (status set to `in-progress`).
Repo: `repos/psp-companion/` (no commits, as instructed).

## What was built

- **Protocol spec** `protocol/PROTOCOL.md`: UDP broadcast discovery (47860), cleartext handshake, SPAKE2 pairing on
  edwards25519 (RFC 9382 M/N, SHA-512, HKDF/HMAC-SHA256), per-session HKDF key schedule bound to both handshake
  messages, TCP frames (`u16` length + ChaCha20-Poly1305, implicit counters, length as AAD), UDP audio datagrams
  (session tag + 64-bit seq header as AAD, 64-entry replay window, 1200-byte cap), all message types from the phase
  (hello/version, ping, widgets, input, macro, voice upload/reply text, audio stream control and packets,
  Stream Deck images and presses), timers, versioning, and the rate-limit rules.
- **Host** (`host/`, Rust 2024): lib + bin. Discovery responder, pairing (PIN: 120 s, 3 attempts), sessions
  (newer session replaces older), UDP audio registration and `send_datagram`, `broadcast` for push-on-change
  callers, a shared token bucket (300 kbps hard cap, incoming bytes charged as debt, TCP waits, UDP drops),
  TOML config with validation and atomic save, daily-rolling file logs plus stderr, tray UI (status, PIN,
  live in/out kbps, pair, forget, open logs/config, quit), `--headless`, `--pair`, `--config`.
- **PSP client** (`psp/`, C): Wi-Fi profile dialog, profile memory and silent reconnect, WLAN-switch detection,
  broadcast discovery with host list, manual IP via OSK, PIN entry via OSK, SPAKE2 pairing, encrypted session,
  keepalive Ping only (15 s), Pong timeout, audio UDP registration with bounded retries, status screen (RTT,
  live in/out/total kbps against budget, totals, UDP state), back-off 1-30 s, rediscovery of the paired host by
  host ID after repeated failures, pairing record with checksum and write-then-rename.
  Portable code (`crypto.c`, `protocol.c`) has no PSP headers.
- **Cross-check harness** `tools/xcheck/`: compiles `psp/crypto.c` and `psp/protocol.c` with the PC C compiler and
  checks them byte-for-byte against the Rust host.
- `LICENSE` (MIT, Henry Nguyen), `README.md` (build, run, firewall, router settings, security notes),
  `scripts/build-psp.{sh,ps1}`, root Cargo workspace (`default-members = ["host"]`).

## Verified (commands run in `repos/psp-companion`)

- `cargo build`: clean, no warnings.
- `cargo test`: 41 unit tests (framing, codec, messages, handshake, AEAD with RFC 8439 vector, replay window,
  session keys, SPAKE2 key derivation and failure cases, PIN expiry and attempts, rate limiter, config, tray text)
  plus 4 end-to-end tests over localhost (discovery, wrong PIN, pairing, session, ping/pong, UDP register + audio
  datagram, broadcast, session replacement, unknown device, wrong key, wrong direction, version mismatch). All pass.
- `cargo test --workspace`: adds 10 C-vs-Rust cross-checks (SHA-256/512, HMAC, HKDF, Poly1305 RFC vector, AEAD
  both ways, C SPAKE2 client pairing with the Rust host, wrong PIN and bad points, session keys and C-sealed frames
  opened by the host, protocol encoders/decoders both ways). All pass. These were compiled with MSVC x64
  (warnings as errors), not the PSP's MIPS toolchain.
- `cargo clippy --workspace --all-targets`: 0 warnings. `cargo fmt --check`: clean.
- Headless smoke run (`companion-host --headless --pair --config <scratch config bound to 127.0.0.1>` under a 4 s
  timeout): starts, binds, logs the PIN, exits; no process left running (checked with `tasklist`). The log folder it
  created in `%LOCALAPPDATA%\psp-companion` was deleted afterwards.
- `ak plan validate` on the plan directory: valid.

Per the coordinator's instruction, the tray app was never launched interactively, and nothing was run that plays
audio, shows notifications, or opens windows. The tray code compiles and its text logic is unit-tested, but the tray
itself is unverified.

## Not verified

- **PSP build**: not run. Docker Desktop is installed, but its engine is not running (the named pipe is missing), and
  starting it would open a window. No WSL distro or clang is available. `psp/Makefile` and the build scripts are
  written but have not been run. The PSP-specific files (`main.c`, `net.c`, `wifi.c`, `ui.c`, `rng.c`, `storage.c`)
  were checked by hand against the pspsdk headers in `refs/pspsdk` only.
- **On-device behaviour**: PPSSPP and real PSP-3000 testing, the router test (plan step 4), Wi-Fi-drop recovery, and
  the debug-screen-over-GU text rendering approach.
- **`sceAudioInputInit(0, 0x7FFF, 0)` gain value** used for microphone entropy: the parameter is undocumented. A
  failure is handled (it falls back to timer entropy, with a 500 ms timeout thread), but whether the mic actually
  delivers noise is unverified.
- Tray icon on Windows (real event loop), firewall prompt behaviour on `0.0.0.0` binds.

## Open issues / notes

- Pairing keys are stored in plain form in the host config and in `pairing.dat` next to the EBOOT (not in
  `PSP/SAVEDATA`, because a raw file without PARAM.SFO shows as corrupted data in the XMB). This is a deviation from
  the "PSP save folder" wording.
- The PSP RNG has no hardware source in user mode. The host nonce keeps session keys fresh regardless, but the
  security of the one-time pairing depends on PSP entropy. This is documented in the README.
- SPAKE2 on the PSP uses TweetNaCl-style 16x16-bit-limb arithmetic. Pairing time on the 333 MHz Allegrex is unmeasured
  (estimated at a few seconds; a "Pairing..." screen is shown during it).
- The workspace `CLAUDE.md` should list the new commands (`cargo build`, `cargo test --workspace`,
  `scripts/build-psp.sh`); I did not edit it because it is outside this phase's file ownership.

## Unresolved questions

1. Can Docker Desktop be started (it opens a window) so the PSP build can be verified, or should that wait for the
   user?
2. Should the phase stay `in-progress` until the real-hardware and router test (step 4) passes? I assumed yes.
