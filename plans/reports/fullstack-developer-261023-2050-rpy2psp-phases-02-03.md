# rpy2psp phases 02-03

Date: 2026-10-23. Plan: `plans/261023-1558-renpy-to-psp`. Repo: `repos/rpy2psp`. There are two local commits, `affea80` (phase 02) and `5287506` (phase 03). Nothing has been pushed and no tags were created.

Both phases are complete. The three target games compile with zero unsupported constructs. Their assets convert into a pack that decodes back cleanly on the PC. 5 of the 15 census games compile.

The plan was updated as you authorised:

- **Acceptance criteria:** the scope is now dialogue-driven VNs, the three targets must be fully covered, and coverage of the 15-game corpus is reported rather than gated.
- **Phase statuses:** phase 01 is `completed` with the new gate text. Phases 02 and 03 are `completed`, each with a result note.
- **Validation:** `ak plan validate` reports OK. The plan is now 3 of 5 phases done.

## Phase 02: script reader and bytecode compiler (`affea80`)

### Built

The compiler lives in `rpy2psp/compiler/`:

| Module | What it does |
|---|---|
| `lexer.py` | Ren'Py's line and string rules. The census tool now uses this lexer instead of its own copy. |
| `reader.py` | The statement parser, plus one view over loose game files and `.rpa` archives. File lookups ignore case, as Ren'Py's do. |
| `rpa.py` | Reads RPA-1, RPA-2 and RPA-3 archives. The archive index unpickler only allows `_codecs.encode` and `bytes`. |
| `rpyc_decode.py` | A restricted unpickler for compiled scripts. Ren'Py classes become inert stand-ins, every other class is refused, and the result is turned back into source lines. |
| `atl.py` | The animation (ATL) subset. |
| `expr.py` | Evaluates expressions at build time, and compiles the runtime ones to the stack VM. |
| `bytecode.py` | Opcodes, assembler, file container and disassembler. |
| `translate.py` | Dialogue translation IDs, computed the same way Ren'Py computes them. |
| `compile.py` | Everything else: definitions run in init order, the prelude of built-in transforms and transitions, the init-time `for`/`if` loops that auto-define images, and the story flow. |

Around the compiler:

- CLI: `python -m rpy2psp compile | disasm | coverage`.
- Format spec: `docs/dev/bytecode.md`.
- Tests: golden disassembly tests (6 self-written cases), lexer/rpa/rpyc tests, opt-in target-game tests, and a reference interpreter (`tests/compiler/refvm.py`) that plays compiled games.

### Verified

**Tests.** `python -m unittest discover -s tests -t .` passes all 29 tests across both phases, with nothing skipped. A fresh environment built only from `requirements.txt` also passes, and `pip check` is clean.

**Targets compile with zero errors and play through.** The reference interpreter tried every menu path:

| Game | Paths explored | Result |
|---|---|---|
| The Question | 3 | All 71 say lines reached |
| Zero Echoes | 2,000 (capped) | 84 played to the end, with the passwords typed in |
| Arcance | 3,302 played to the end | 226 of 246 lines reached |

None of these runs hit a runtime error. The 20 Arcance lines never reached sit behind conditions the story never satisfies. I checked one: the flee-to-dragon branch needs witch option 71, but the scene is only reachable with option 8.

**Translations.** For The Question in Japanese, Korean, Simplified Chinese and Traditional Chinese, all 70 `translate` blocks match a dialogue line by ID, with none left over.

**Compiled scripts (`.rpyc`).**
- Arcance ships real Ren'Py 6.99 compiled files (Python 2 pickles). Once addresses are ignored, they compile to the same instructions as its `.rpy` sources. The only difference is one extra `return` per file, which Ren'Py adds itself.
- A Ren'Py 8 compiled module (Python 3 pickle) also decodes.
- Malicious pickles (`os.system`, `builtins.eval`) are refused.

**Corpus coverage.** 5 of 15 compile with zero errors, the same five the census predicted:

| Games | Errors | Main causes |
|---|---|---|
| the_question, wanted_dragon, chemistry_hero, arcance, zero_echoes | 0 | none |
| rms_dating_sim | 5 | a custom screen |
| wonder | 6 | Python functions, a custom screen |
| marystory | 20 | movie sprites, irisout, a custom screen; 15 of the 20 are audio files missing from the repo |
| Python-heavy games | 34 to 33,898 | Python functions and classes, custom screens |

The per-game table is in `docs/dev/census.md`.

### Decisions and deviations

- **Code location.** The code lives in `repos/rpy2psp/rpy2psp/compiler/` so it installs as a Python package. `translate.py` was added as a separate module.
- **Undefined images.** These are warnings that show nothing, which is what Ren'Py does outside developer mode. The reason is that Arcance itself contains the typo `background ragonCave`.
- **Template UI files** (gui, screens and options). Errors there become warnings, as the census treated them. Screen size, fonts and outlines are still read from them.
- **Unsupported-construct list.** Everything outside `subset.json` reports the file and line. One addition is that `CropMove`/`PushMove` with wipe, slide or push modes is accepted, because those built-in transitions are already in the subset.

## Phase 03: asset pipeline (`5287506`)

### Built

The pipeline lives in `rpy2psp/assets/`:

| Module | What it does |
|---|---|
| `images.py` | Renders image recipes (file, composite, scale/factor, crop, flip, grayscale/sepia, alpha, colour matrix). Scales to fit 480x272 with premultiplied Lanczos, splits into tiles of at most 512 pixels, and encodes DXT1 (opaque) or DXT5. Includes an independent decoder that behaves like the PSP's graphics chip (the GE), plus swizzle and unswizzle. |
| `fonts.py` | Finds fonts in the game, then in `--font-dir`, then a `--fallback-font`. Checks glyph coverage, renders glyphs with FreeType, packs them into 512-pixel pages, and stores them swizzled: 4-bit (T4), or 8-bit (T8) packing fill and outline when the game uses outlines. |
| `audio.py` | Decodes sources with libsndfile. Music becomes MP3 at 128 kbps CBR and 44.1 kHz. Sound effects and voice become PCM16 if 1 second or shorter, otherwise block-based IMA ADPCM. Includes decoders and SNR measurement. |
| `movies.py` | Uses ffmpeg to produce an H.264 Baseline 480x272 stream plus MP3 audio. |
| `pack.py` | Builds `data.pak`: entries 64-byte aligned, stored in the order scenes first use them, identical entries shared, with a per-scene asset index. Also `verify_pack`. |

Around the pipeline:

- CLI: `pack` and `verify`.
- Format spec: `docs/dev/pack-format.md`.
- Tests: `tests/assets/test_assets.py`, 12 tests on generated inputs.
- Dependencies are pinned in `pyproject.toml`, with a full lock in `requirements.txt`.
- `.github/workflows/release.yml`: on a `v*` tag it runs the tests, packages a PyInstaller one-folder build, smoke-tests the exe, zips it, and publishes it with `gh release create`.

### Verified

Each game was run through `rpy2psp pack`, then `rpy2psp verify`. The fonts came from the Ren'Py repository's `renpy/common` and `sdk-fonts` folders:

| Game | `data.pak` | Images (PSNR min / mean) | Audio | Glyphs |
|---|---|---|---|---|
| The Question | 1.09 MiB | 12 images, 26.4 / 27.8 dB | MP3 128 kbps / 44.1 kHz, SNR 24.0 dB, length off by 14 ms | 95, exact |
| The Question (Japanese build) | 1.13 MiB | - | - | 371 CJK glyphs, exact |
| Zero Echoes | 2.32 MiB | 5 images, 32.3 / 34.8 dB | MP3 SNR 24.2 dB; 4 ADPCM effects at 31 to 42 dB | 467 Chinese glyphs, exact |
| Arcance | 2.31 MiB | 35 images, 22.9 / 34.6 dB | none | 101, exact |

Every game is far under the 300 MB limit, and every check passes.

- **Visual spot checks:** a decoded background, a decoded sprite with transparency, and the unswizzled Japanese glyph page all look correct.
- **Decoder cross-check:** my GE decoder was compared with Pillow's standard DDS decoder. Alpha is identical, and RGB is lower by 0 to 7, which is the PSP's colour expansion.
- **Bug caught by the cross-check:** a 32-bit overflow in the DXT5 alpha unpacking.
- **Quality:** the image PSNR floor is set at 20 dB. Standard BC3 on the same Ren'Py sprite reaches only 27.8 dB, so the lower numbers are a limit of the format, not of the pipeline.
- **Tests:** these cover Vietnamese text with and without outlines (using a system font), ADPCM and PCM round trips, an OGG source turned into MP3, a full compile, pack and verify on a generated game, and the movie path (ffmpeg present: H.264 Baseline at 480x272 confirmed).
- **Release packaging, tried locally:** the PyInstaller one-folder build, about 73 MB, compiled, packed and verified Zero Echoes end to end. That build first failed for lack of etcpak's and archspec's data files; those are now collected.

### Deviations

- **DXT is not swizzled.** You asked for swizzled DXT textures, but the GE has no swizzled DXT mode: PPSSPP's `DecodeDXTBlocks` reads plain row-major 4x4 blocks. So DXT is written in the GE's own block order (indices before colours, DXT5 alpha after the colour block), and swizzling is applied only to the uncompressed glyph atlases.
- **Colour pre-scaling.** Colours are scaled by 255/248 before compression, because the GE expands 5-bit colour by shifting rather than by repeating the high bits.
- **Texture memory.** Only the rows actually used are stored, while the texture height register is set to the next power of two. A full-screen background in DXT1 is therefore 69,632 bytes. The engine must clamp its texture coordinates to those rows.
- **Movies are not PSMF.** They are a raw H.264 stream plus MP3. No target game uses movies.
- **Font sizes.** These are set by `--font-size` (default 14 px), because vnpsp draws its own text box. Kerning is not stored.
- **Effects sample rate.** Effects keep their source rate if it is 11025, 22050, 44100 or 48000 Hz, and are resampled to 44,100 Hz otherwise.

### Not verified

- **On a PSP.** Nothing has been tested on PPSSPP or real hardware: DXT sampling with the stored rows, CLUT text rendering, `sceMp3` playback, ADPCM decoding cost, and H.264 decoding. That belongs to phases 04 and 05.
- **The release workflow on GitHub.** It has not run on GitHub, because it needs a tag and I created none. The same PyInstaller command worked locally. ffmpeg is probably absent on `windows-latest`, so the movie test may be skipped there.
- **One build-system pin.** `setuptools==80.9.0` in `[build-system]` was not installed or exercised, because installs use `requirements.txt`.

## Open issues

1. **Fonts outside the game.** Ren'Py's default fonts (DejaVuSans, SourceHanSansLite) ship with the SDK, not with games. You must pass `--font-dir` pointing at a Ren'Py SDK. Nothing is bundled, because of the no-shared-fonts rule.
2. **Gapless music loops.** MP3 encoder padding will cause a small gap when music loops. The engine should trim the encoder delay (1105 samples, measured).
3. **Saves.** They store code addresses, so a save is only valid for the exact `script.vnb` it was made with. The format reserves a flags field, but no script hash is written yet. Phase 04 should add one.

## Resume from here

Phases 02 and 03 are complete and committed. The next step is phase 04 (native VN engine). It consumes:

- `script.vnb`, specified in `docs/dev/bytecode.md` with a reference interpreter in `tests/compiler/refvm.py`;
- `data.pak`, specified in `docs/dev/pack-format.md`.

Nothing is in progress and the working tree is clean.

Status: DONE_WITH_CONCERNS
Summary: Phases 02 and 03 are implemented, tested (29 tests), and committed locally as `affea80` and `5287506`. The three target games compile with zero unsupported constructs, 5 of 15 corpus games compile, and every converted asset decodes back and matches its source on PC.
Concerns/Blockers: DXT is stored in the GE's block order, not swizzled, because the hardware has no swizzled DXT mode. Movies are a raw H.264 stream rather than PSMF. Nothing has been tested on a PSP, and the release workflow has not run on GitHub.
