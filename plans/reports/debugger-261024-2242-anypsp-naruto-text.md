# AnyPSP: garbled text in Naruto: Ultimate Ninja Heroes 1

Date: 2026-10-24 (Asia/Saigon). Repo: `repos/anypsp`, commit `270ed2f` on main (local, not pushed).

## Outcome

- **Fixed.** All in-game text (the dialogue box, "Start the battle?", YES/NO) now renders correctly in the translated GPU runner, the interpreter GPU runner and the soft renderer.
- **New runner for play:** `D:\Projects\personal\anyport\repos\anypsp\out\runners\unh1-text\Release\anypsp-run-unh1-gpu.exe` (`/O2`; built with `ANYPSP_RUNNER_JOBS=4` because 8 jobs ran the compiler out of heap). `out/runners/unh1-lazy` was not touched.

## Root cause

UNH 1 does not use sceLibFont: an HLE trace up to frame 5500 shows no `sceFont*` calls. The game draws each glyph on the CPU into its own RAM texture. Each texture is 16x32 CLUT4 at `0x08D8xxxx`, with a stride of 0x270 bytes and the texture buffer width register set to 16 (`tex=8d8a930/f4/504/bw10` in the `PSPWEB_DUMP_FRAME` log).

At 4 bits per texel, a 16-texel row is 8 bytes. The PSP GE ignores the low bits of the buffer width, so a row is always a whole number of 16-byte units, and anything under 16 bytes counts as 16. PPSSPP does the same in `GetTextureBufw` and `textureAlignMask16`. The game relies on this and writes its glyph rows 16 bytes apart.

`Ge::bind_texture`/`fetch_texel` (`runtime/host/ge.cpp`) used the raw width of 8 bytes. As a result, texture row 2k showed the left half of real row k, and odd rows showed the stale bytes between rows. The dumped glyph texture shows this: even rows hold glyph strokes and odd rows repeat junk. That produced the striped noise.

## Elimination

| Hypothesis | Result |
|---|---|
| Lazy coherence or texture cache invalidation | Ruled out: the translated lazy runner, the soft renderer (`--renderer soft`) and the interpreter GPU runner all give the same garbled frame 5500. |
| Translated code bug | Ruled out: the interpreter shows the same output. |
| sceLibFont HLE | Ruled out: the game makes no sceFont calls. |
| CLUT, swizzle or T4 nibble order | Ruled out: the CLUT colours are right, the texture is not swizzled (`kTexMode` is 0), and the glyph strokes in the even rows have the correct nibble order. |
| Buffer width alignment | Confirmed: the row pattern matches 8-byte against 16-byte rows. A unit test fails before the fix and passes after it. |

## Fix

`Ge::texture_buf_width()` rounds the buffer width down to a multiple of 16 bytes, with 16 bytes as the minimum, for formats 0 to 7. DXT formats are unchanged. It is now used for the texture key and size, for texel fetch, and for the render-target lookup.

## Validation

- New test: `tests/unit/ge_texture_tests.cpp`, in `anypsp_hle_tests`. It renders a 16x2 CLUT4 texture with bufw 16 through the software GE. It fails before the fix (row 1 sampled the wrong bytes) and passes after it.
- `ctest` 6/6 pass. `tests/ge-screenshots.py` is still 13/28, the same set as before.
- Deterministic UNH 1 run, same input script as the earlier reports, 6000 frames:
  - The translated `unh1-text` frame 5500 is pixel-identical to the fixed interpreter's frame 5500.
  - Frames 5550 to 5700 show clean text.

Frames are scratch only (game output, never committed). They are under `C:\Users\nguye\AppData\Local\Temp\claude\D--Projects-personal-anyport\6abeed62-62d9-4274-ac7a-e6a4cccd14e1\scratchpad\naruto-text\`:

- Before: `lazy\frame_005500.png` (translated lazy runner), `soft\frame_005500.png` (soft renderer), `interp\frame_005500.png` (interpreter).
- After: `text\frame_005500.png` (translated `unh1-text`) and `interp-fix\frame_005500.png` (interpreter). `after.png` shows frames 5550 to 5700.

## Notes

- The other agent's uncommitted `runtime/gpu/display.{cpp,hpp}` edits were in the working tree, so they are compiled into `unh1-text`. They are not in my commit.
- No processes are left running.

## Unresolved questions

- The user's exact Ino dialogue frame was not captured, because the scripted input skips dialogue. It uses the same CPU glyph-texture path that is now fixed.

Status: DONE
Summary: The text was garbled because the GE used the raw texture buffer width (8 bytes) where hardware rounds it up to 16-byte rows. UNH 1's CPU-drawn 16x32 CLUT4 glyphs rely on that rounding. Fixed in `ge.cpp` with a regression unit test; ctest is 6/6 and GE screenshots stay at 13/28. The playable runner is in `out/runners/unh1-text`.
