# PSP EBOOT builds: psp-companion and rpy2psp

Both EBOOTs now build cleanly with the pspdev toolchain in Docker, with no warnings from our own code. Both boot in PPSSPPHeadless. PC tests still pass. Nothing was pushed.

## psp-companion (`c2c0f73`)

- `scripts/build-psp.sh` failed under Git Bash: MSYS rewrote `-w /src` to `C:/Program Files/Git/src`. It now sets `MSYS_NO_PATHCONV=1`. After that fix the sources compiled and linked on the first try.
- `psp/storage.c`: a `strncpy` truncation warning. The code now uses `memcpy` with `strnlen` into the zeroed 33-byte field, which writes the same bytes.
- Stream Deck mode is now off by default (`StreamDeckConfig::default`, README example).
- LAME: added `THIRD_PARTY.md` with the LGPL notice and relink steps. The release workflow now ships it next to the exe, and the README license section links to it.
- README: added "Testing on a PSP-3000 (ARK-4)", with psplink steps that run `companion.elf`.
- `cargo test --workspace`: all pass.
- PPSSPPHeadless, 12 emulated seconds: the EBOOT boots and opens the system Wi-Fi dialog with no profiles; there was no crash. PPSSPP logs 11 `sceNetInet` NIDs as unknown, and `sceAudioInputInit` as UNIMPL. These are gaps in the emulator, and they need checking on hardware.

## rpy2psp (`11d5480`)

- The build worked on the first run. psp-gcc reported 27 `-Wformat` warnings because newlib's `uint32_t` is `unsigned long`. Those arguments are now cast to `unsigned`. The remaining warnings come from vendored minimp3 and were left alone.
- `docs/dev/engine.md`: added "Testing on a PSP-3000 (ARK-4)".
- ctest 4/4 and Python tests 46/46 pass. The Python tests need the venv `%TEMP%/rpy2psp-env`; system Python lacks PIL, numpy and etcpak.
- PPSSPPHeadless with `the_question` (data from `%TEMP%/vnpsp-targets`): the title menu renders. After pressing Cross, the first scene shows the background and dialogue text correctly.

## Workspace

`CLAUDE.md` now has the PPSSPPHeadless build and run recipe. The build lives in the session scratchpad and is not durable, so rebuild it with the recipe if it is gone. Phase statuses are unchanged: companion 01-04 and 06, and rpy2psp 04, stay `in-progress` until they are validated on the device. The companion `plan.md` table still shows `pending` for phases that the phase files mark `in-progress`. I did not edit it, because status cells must not be edited directly.

## Resume from here

1. The user tests on the PSP-3000 using the steps in `repos/psp-companion/README.md` and `repos/rpy2psp/docs/dev/engine.md`.
2. Companion: identify the 11 unknown `sceNetInet` NIDs, if networking in PPSSPP matters. Real hardware is the authority.
3. Mark phases completed only after hardware validation.

Status: DONE_WITH_CONCERNS
Summary: Both EBOOTs build warning-free (our code) and boot in PPSSPPHeadless; vnpsp renders a real scene, and the companion reaches the Wi-Fi dialog. LAME notice added, Stream Deck defaults to off, and PSP-3000 test steps are documented.
Concerns/Blockers: Companion networking, audio and voice cannot be exercised headlessly (no Wi-Fi profile, and PPSSPP lacks some NIDs). Hardware validation is pending.
