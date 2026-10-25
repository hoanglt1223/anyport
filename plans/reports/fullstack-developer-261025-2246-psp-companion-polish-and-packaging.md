# PSP Companion: polish and packaging (branch feat/polish-and-packaging)

Repo: /home/ubuntu/anyport/repos/psp-companion. Plan: plans/261023-1558-psp-companion (phase 05 and the status of 01, 02, 06 updated; plan.md table now matches the phase files).

## Done, with evidence

- **Settings page (unfinished work from the stopped agent):** finished and committed. It is served at `http://127.0.0.1:<ingest_port>/settings`, with a loopback Host check (against DNS rebinding) and a per-run token. The API key is never sent to the page, and network settings and paired devices are left alone. A tray "Settings..." item opens it. I added **Pair new PSP**, which returns a PIN so a headless or systemd host can pair without restarting. Test: `host/tests/settings_e2e.rs`.
- **`cargo test --workspace` passes on Linux:** 145 tests. `cargo clippy --all-targets -D warnings` is clean, both with the default features and with `--no-default-features`. `cargo fmt --check` is clean.
- **Real speech engines:** whisper.cpp was built from source (ggml `base` model) and Piper release 2023.11.14-2 was installed with the `en_US-amy-medium` and `vi_VN-vais1000-medium` voices, all in /home/ubuntu/anyport-scratch/voice. The gated tests pass: `whisper_cpp_transcribes_silence_to_nothing`, `piper_speaks`, and a new Piper-to-whisper.cpp round trip (`piper_speech_round_trips_through_whisper`).
- **Satellite API pinned:** the supported range is API 1.5 to 1.x. `TESTED_API` is 1.15 (Companion 5.2), checked against the version table at companion.free/for-developers/Satellite-API. Newer 1.x servers connect and log a notice. The range is documented in the README and in docs/user/FEATURES.md.
- **PSP EBOOT:** a clean `sh scripts/build-psp.sh` build succeeds.
- **PPSSPPHeadless smoke:** the app boots to the pairing screen. Screenshot: /home/ubuntu/anyport-scratch/pspc-smoke/pairing-screen.png.
- **Phase 01 gap (save data):** commit 400411a already moved the pairing key into the PSP save folder. I verified the migration in PPSSPP: a self-made legacy `pairing.dat` was moved into `PSP/SAVEDATA/PSPCOMPAN0000` (DATA.BIN, ICON0, PARAM.SFO) and the app went to "Connecting to SMOKE-PC...". Screenshot: /home/ubuntu/anyport-scratch/pspc-smoke/connect-screen.png.
- **Phase 05:**
  - power.c, the START menu and the ICON0/PIC1 art were already in commit 400411a.
  - Windows installer: an Inno Setup script with sign-in autostart and a private-network firewall rule. It compiles with Inno Setup 6 under Wine (`amake/innosetup` image).
  - Linux tarball with a systemd user unit and `install.sh`. I installed it into a scratch home, the installed binary served the settings page and gave out a PIN, and `systemd-analyze verify` passes.
  - User guides in docs/user (INSTALL, FEATURES, TROUBLESHOOTING), with the Wi-Fi router settings included. The README is updated (the save location replaces `pairing.dat`).
  - `ci.yml` covers the Linux build (fmt, clippy, tests, tarball) and the EBOOT build. `release.yml` now also publishes the Windows installer and the Linux tarball. actionlint reports nothing.

## Design calls

- The Linux release is the headless build (`--no-default-features`), so it needs no GTK at runtime; the settings page stands in for the tray.
- The systemd unit sets `PULSE_SOURCE=@DEFAULT_MONITOR@` for the PC speaker and reads the API key from the optional file `~/.config/psp-companion/env`.
- The host crate version is now 0.2.0, to match the PSP app.
- Package output goes to `out/packages/`, because a local hook blocks paths named `dist`.
- PPSSPPHeadless needs `docker run --shm-size=1g`. With Docker's default 64 MB shared memory, PPSSPP crashes with SIGBUS (exit 135) when the save dialog runs. This is noted in CLAUDE.md and the README.

## Remaining (needs things this box does not have)

- A live Claude API run, which needs the user's API key.
- All hardware checks on the PSP-3000: router join, real pairing, 10+10 voice questions, music for 30 minutes, OBS/Spotify through Bitfocus Companion, and 4 hours on battery with widgets only.
- Running the Windows installer on a real Windows PC: autostart, firewall rule, uninstall.
- PPSSPP cannot test networking from the PSP side because its HLE lacks several sceNetInet calls, so the emulator shows "Cannot open a UDP socket for discovery".
