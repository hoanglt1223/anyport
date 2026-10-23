# AnyGBA phases 05-08: implementation report

Stopped after phase 07 because the PC had to restart. Nothing is pushed.

| Phase | Commit | Status line |
|---|---|---|
| 05 HLE BIOS | `f11dc00` | completed |
| 06 PPU renderer | `9a85991` | completed |
| 07 APU | `bd27625` | completed |
| 08 Saves, input, packaging | not started | pending |

Build: `repos/anygba/out/msvc` (VS 17 2022, x64, MSVC 14.44, Release).

## Reference oracle

mGBA 0.10.5 libretro core built from the official source tag in the session scratchpad (no BIOS file, so
mGBA's own HLE BIOS answers). `tests/oracle/mgba-oracle.py` drives it with ctypes: frame hashes, PNGs,
WAV, memory dumps. Build steps are in `tests/oracle/README.md`. No mGBA code is in the repo.

## Phase 05: HLE BIOS

Built: `runtime/src/bios/` (`swi_table`, `boot_state`, `math`, `memcpy`, `decompress`, `affine`).
Every SWI 0x00-0x2A is handled; numbers past 0x2A stop the run with an error naming the number and address.
Sound-driver SWIs and MultiBoot are stubs that log once. KEYCNT keypad interrupts were added because Stop
wakes on them. BIOS-region reads now return the right opcode inside and after an IRQ (jsmolka test 3/4).

Verified:

- jsmolka `bios.gba` passes as recompiled code (new CTest `gba-tests-bios`). mGBA's HLE fails its test 1.
- Div, DivArm, Sqrt, ArcTan, ArcTan2: 640 inputs, bit-identical to mGBA (r0, r1, r3).
- BgAffineSet/ObjAffineSet: within one 8.8 step of mGBA (80 of 128 matrix entries identical). mGBA uses
  float; ours uses the BIOS's 1.14 sine table and negates pb after the shift, as the MIT-licensed
  Cult-of-GBA replacement BIOS documents for the original. Not verified on hardware.
- LZ77 (Wram/Vram), RLE (Wram/Vram), Huffman 4/8-bit decompress data compressed by grit v0.10.0 back to
  the self-authored input, from EWRAM and from ROM. Diff8/16, BitUnPack, CpuSet/CpuFastSet,
  RegisterRamReset, SoftReset, boot state: unit tests.
- tonc `swi_demo`, `swi_vsync`, `tmr_demo` and Varooom 3D run 300-1200 frames without a BIOS error
  (previously they stopped at their first SWI). Nothing visible yet (no PPU).
- `ctest -C Release`: 9/9 including the slow label.

Deviation: the plan's "gbalz77" reference became grit's compressors (gbalzss needs POSIX getopt); same
family of devkitPro tools.

## Phase 06: PPU renderer

Built: `runtime/src/ppu/` (`ppu`, `bg_text`, `bg_affine`, `bg_bitmap`, `sprites`, `compose`). One line is
rendered at each visible HBlank start; BG2/BG3 reference points latch at VBlank and on register writes.
Test tooling: `anygba-shot` (interpreter-only headless runner mirroring the oracle's options), a PNG
writer and reader (own inflate) in `tests/support/`, `tests/oracle/make-ppu-goldens.py`, and
`tests/golden/ppu/` (48 cases, 180 KB of mGBA PNGs).

Verified:

- 48 golden pictures (35 tonc demo scenes, several driven by key holds for mosaic, blending modes,
  windows, affine BG/OBJ and Mode 7; jsmolka hello/shades/stripes; Varooom 3D menu and Butano splash):
  45 pixel-identical, 2 identical except the oracle's own RGB565 darken rounding (red/green +1 only,
  checked per pixel), 1 (`swi_demo`) differs in 62 cosine-curve pixels that come from ObjAffineSet
  fixed vs float, not the PPU. Includes `dma_demo` (HBlank DMA raster window) line for line.
- Pictures are matched within frames F-12..F+2: mGBA's libretro start shows six white frames before
  these ROMs draw, and CPU timing is not cycle accurate. Animated scenes (prio_demo, txt_obj, the
  Butano splash) still match exactly at some frame in the window.
- Excluded on purpose: `bigmap` (backdrop colour = VCOUNT at a point in the frame, i.e. CPU timing),
  `txt_se2` (prints profiling times), `swi_vsync` (rotates via ObjAffineSet every frame).
- `ctest -C Release`: 9/9 including slow. The golden test takes about 8 s (cases run in parallel).

Unverified: the OBJ per-line cycle budget (no test content reaches it); real-hardware rounding of the
darken effect (mGBA itself is inconsistent across its renderers).

## Phase 07: APU

Built: `runtime/src/apu/` (`apu`, `psg`, `fifo`, `mixer`). Output is 32768 Hz stereo, produced lazily
(`catch_up(now)` before every sound-register write, timer overflow, and `System::drain_audio`). PSG output
is averaged over each 512-cycle sample; FIFOs pop on timer 0/1 overflow and request DMA 1/2 at <= 16
bytes; mixing follows GBATEK (PSG +-0x80 per channel at full volume, FIFO +-0x200 at 100%, SOUNDBIAS,
10-bit clip). `main.cpp` now pushes real samples instead of silence (SDL resamples to the device; the
existing audio-led pacing replaces the plan's dynamic-rate resampler). `System::fifo_underruns()` is
printed by generated games on exit. KEYCNT/sound FIFO reads: FIFO registers now read as 0.

Test tooling: `tests/support/test_roms.cpp` builds self-authored register-script ROMs (8 sound tests);
`anygba-test-roms <dir>` writes them; `anygba-shot --wav`; `tests/oracle/make-apu-references.py`;
`tests/runtime/data/apu/` (cases.txt + 10 zlib-compressed mGBA captures, 150 KB).

Verified (windowed Pearson correlation vs mGBA, 1024-sample windows, lag search +-512):

- square1 0.9967, square2 (envelope) 0.9909, wave 0.9987, 7-bit noise 0.9916, FIFO A 0.9989,
  15-bit noise 0.9827 (threshold 0.97, broadband), panned mix 0.9879 (threshold 0.98).
- Sweep: per-block period counts within 1 of mGBA, silent from block 10 vs 11.
- tonc snd1_demo SOS ditty: period counts within 1 for 60 blocks. Varooom 3D sound effect after A: 0.9927.
- Recompiled varooom-3d and tonc-snd1_demo ran 17920 frames (5 emulated minutes) headless with no
  FIFO underruns reported. Not verified: audible playback, crackle, pacing with a real device (no audio
  output allowed on this PC); Varooom gameplay music (not reached without input scripting).
- `ctest -C Release` (all 9, incl. slow): in the final full run `unit-tests` failed once and passed on
  `--rerun-failed`. I did not have time to identify the flaky case. Suspects: the parallel
  (`std::async`) golden/APU tests or the platform timing tests under load.

## Phase 08: not started

## Resume from here

State:

- Repo `repos/anygba` at `bd27625` (phases 05 `f11dc00`, 06 `9a85991`, 07 `bd27625`), clean tree, not
  pushed (the lead pushes). Phase status lines 05-07 = completed, 08 = pending. `ak plan phase close`
  fails with "planstore: plan not found", so the status lines were edited directly.
- Build dir `repos/anygba/out/msvc` (VS 2022 generator). `cmake --build out/msvc --config Release`;
  if MSVC reports C1060 out of heap space, rerun the build. `ctest --test-dir out/msvc -C Release`.
- mGBA oracle: `mgba_libretro.dll` was built in this session's scratchpad, which may be gone after the
  reboot. Rebuild it per `tests/oracle/README.md` (clone mGBA tag 0.10.5, CMake flags listed there,
  ~2 minutes). Only needed to regenerate references; the tests use the committed references.
- Docker was not available (`docker info` failed), so the tonc ELF discovery measurement from phase 02
  is still pending.

First, investigate the flaky `unit-tests` run: loop `out/msvc/bin/Release/anygba-tests.exe` about 10 times
and look for the failing case.

Next, phase 08 (`plans/261023-1514-anygba-static-recompiler/phase-08-saves-input-packaging.md`):

- Saves: `runtime/src/save/{detect,sram,flash,eeprom}.cpp`. The bus currently maps 0x0E/0x0F to plain
  SRAM (`Memory::sram`, `bus.cpp` read8/write8). EEPROM needs the DMA 3 serial protocol (`dma.cpp`
  `run_dma`).
  - Test ROMs in the corpus: `gba-tests/save/{sram,flash64,flash128,none}.gba`. The jsmolka save tests
    report r12 like the others.
  - Persist through `SDL_GetPrefPath`. Back up the previous save before each write.
- Input: `runtime/src/input_map.cpp` plus an `anygba-input.ini` loader. The current fixed mapping is
  `gba_keys()` in `runtime/src/main.cpp`. KEYCNT interrupts already exist (`System::check_keypad_irq`).
- Driver: `tools/anygba/{main,build}.cpp`, the `anygba build game.gba` command. It runs recomp, then
  configures and builds against the install tree (`cmake/install.cmake`; see `tests/feedback-pass.cmake`
  for a working recomp+configure+build sequence). Write the docs in `docs/user/`.
- Note: the per-game TOML config already exists (`tools/recomp/config/`). Add a save-type key and
  patches there.

Known limitations to carry into the README/report:

- BgAffineSet/ObjAffineSet use fixed point, so they differ from mGBA by up to one 8.8 step. Hardware
  behaviour is unverified.
- Darken rounding is unverified on hardware.
- The OBJ per-line cycle budget is untested.
- CPU timing is not cycle accurate: pictures arrive a few frames earlier than in mGBA.
