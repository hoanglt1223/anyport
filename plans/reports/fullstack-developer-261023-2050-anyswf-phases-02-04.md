# AnySWF phases 02, 04 and 03: implementation report (paused)

Status: paused partway through phase 02 at the coordinator's request. Phase 02 is `in-progress`. Phases 04 and 03 were not started, so they stay `pending`. Nothing has been pushed.

## Phase 02: SWF parsing and asset pipeline (in progress)

### Built

The work is committed in `repos/anyswf` as commit `90609ae` (`feat(swf2c): SWF parsing, tessellation, ...`). Everything sits in the `swf2c` library crate (`swf2c/src/lib.rs`) and is not yet wired into the CLI.

- **Dependencies.** All are pinned exactly in `swf2c/Cargo.toml`:
  - `swf =0.3.0`, with only the `flate2` feature enabled
  - `lyon =1.0.19`, `jpeg-decoder =0.3.2`, `png =0.18.1`, `gif =0.14.2`, `flate2 =1.1.9`
  - `symphonia =0.5.5` (MP3 decoding only; MPL-2.0, used unmodified)
- **`parse.rs`.** Handles FWS and CWS. ZWS (LZMA) is rejected with a clear message, and AVM2 SWFs are rejected.
- **`characters.rs`.** Builds the character table and the side tables: JPEGTables, FontInfo, button colour transforms, exports and init actions. It also produces the `inspect` text report.
- **`tessellate.rs`.** Links the edge soup into paths (adapted from Ruffle's ShapeConverter), then tessellates fills and strokes with lyon. Hairlines get a minimum width, and consecutive solid draws are merged.
- **`gradients.rs`.**
  - Linear gradients bake to a 256x1 ramp texture, with reflect baked as a mirrored 512x1 ramp.
  - Radial and focal gradients bake to a 64x64 texture. A 1D ramp cannot be used for them, because distance from the centre does not interpolate linearly across a triangle.
  - Also covers linear-RGB interpolation and UV generation.
- **`bitmaps.rs`.**
  - Decodes JPEG1/2/3 (including the PNG and GIF payloads), and Lossless 1/2 with alpha unmultiplied.
  - Resamples by area averaging.
  - Quantises to CLUT8 by median cut when PSNR is at least 40 dB. Otherwise it uses 565 for opaque images, 5551 for binary alpha, and 4444 for graded alpha.
  - Pads to powers of two, stretches textures used in repeating fills, splits images above 512 into tiles, and swizzles for the GE (unswizzle is included).
- **`sounds.rs`.**
  - Decodes SWF ADPCM (following Ruffle), PCM 8/16-bit, and MP3 (through symphonia).
  - Encodes and decodes the IMA ADPCM output format (blocks of 1024 frames).
  - Includes the MP3 stream-block payload helper.
- **`text.rs`.** Provides font data for DefineFont 1/2/3, lays out static text into outlines (with the text matrix baked in), and builds the device-font atlas.
- **`device_font.rs`.** Holds the TIC-80 system font (MIT), credited in `THIRD_PARTY.md`.
- **`scripts.rs`.** Gives every action block a deterministic index. Both the asset timelines and the phase 04 C emitter will use it.
- **`assets_bin.rs`.** Serialises assets.bin v1:
  - a 64-byte header and a block directory
  - blocks aligned to 64 bytes, and the DATA block aligned to 16 bytes inside
  - record layouts for characters, shapes, draws, textures, morphs, sprites, frames, commands, labels, buttons, clip actions, edit text, fonts, glyphs, sounds, exports, init actions, scripts, strings, data, and the device font

### Verified

These commands were run on Windows 11 in `repos/anyswf/swf2c`:

- `cargo test`: 24 tests pass, covering:
  - swizzle round trip
  - CLUT8 and pow2 padding, the fallback to 565, tiling, and unmultiply
  - gradient ramps and radial bake, and UV mapping
  - IMA round trip with SNR above 25 dB in mono and stereo, PCM decode, and the SWF ADPCM header
  - edge linking, the hairline minimum width, and fill-then-stroke order
  - assets.bin header, alignment and strings
  - the device font atlas
  - ZWS rejection, and a SWF write-then-parse round trip
- `cargo fmt --check` and `cargo clippy --all-targets -- -D warnings` are clean.
- The **Ruffle exporter** builds from `refs/ruffle` (commit 8b25621) with:

  ```
  CARGO_TARGET_DIR=<scratchpad>/ruffle-target cargo build --release --locked -p exporter
  ```

  It took 3m43s and nothing was written inside `refs`. Command line for reference images: `exporter.exe -s --width 480 --height 272 <test.swf> <out.png>`. It has not yet been run on a real SWF; the one attempt used a wrong path. Note that the exporter's default quality is anti-aliased, so render comparisons must tolerate edge differences. The binary is in the session scratchpad and has to be rebuilt after the pause.

### Unverified / not done

None of these exist yet:

- The CLI commands (`swf2c inspect`, `swf2c assets`).
- `convert.rs` and the timeline encoding, including morph-ratio collection.
- `docs/dev/assets-bin-format.md`.
- The C loader `runtime/src/assets.c`.
- The render path and the comparison against Ruffle on 20 SWFs.
- The test-SWF generator and the Ruffle test SWFs copied into `tests/` with their licence.
- The release workflow.

Docker/PSP: `docker info` failed when checked at the start, so no PSP build was attempted.

### Open issues

- `.gitignore` ignores `*.swf`. Copying Ruffle test SWFs into `tests/` will need a negation rule such as `!tests/ruffle/**/*.swf`.
- The README says that no SWF content ships with the project. It needs to be reworded once Ruffle's test SWFs are included.

## Phase 04 and phase 03

Neither was started.

## Resume from here

1. Write `swf2c/src/convert.rs`, which orchestrates the build. The plan already worked out:
   - **Bitmaps:** collect usage with the repeating flag from every fill style, then convert them.
   - **Shapes and morphs:**
     - Tessellate shapes at `tolerance = 0.35 * 20 / target_scale` twips, with `min_stroke = 20 / target_scale`.
     - Morphs are tessellated at every ratio the timelines use. Port Ruffle's `build_morph_frame` from `core/src/display_object/morph_shape.rs`.
     - Static text becomes a shape, and font glyphs become shapes too.
  - **Draws:**
     - Positions are s16 with a per-mesh shift. Solid vertices are 12 bytes (RGBA, then x, y, z, pad); textured vertices are 16 bytes (u, v as f32, then x, y, z, pad).
     - Split draws so each has at most 65535 vertices and 65535 indices.
     - Bitmaps that need several tiles are clipped per tile in UV space.
     - Change `bitmaps::encode` to replicate edge pixels into the padding instead of using zeros.
   - **Timelines:** encode with the `cmd::*` and `place::*` layouts in `assets_bin.rs`, and look script indices up through `scripts::Scripts::index_of`. Also convert sound streams (MP3 kept, everything else to IMA), buttons, edit text, sounds, exports and init actions.
   - Set `target_scale` to `min(480/W, 272/H)`.
2. Add the `inspect` and `assets` subcommands in `swf2c/src/main.rs`.
3. Write `docs/dev/assets-bin-format.md` from the record layouts in `assets_bin.rs`.
4. Write the C loader `runtime/src/assets.c`, which validates every bounds check, plus a minimal GL static-frame renderer and a headless screenshot tool.
5. Add the test SWF generator (an example using the `swf` crate writer), copy in the selected Ruffle visual SWFs with their licence, generate reference PNGs with the Ruffle exporter, and write a comparison script in Python using only the standard library.
6. Then do phase 04, then phase 03, and add the release workflow.

Files in progress: none are left uncommitted. Everything written so far is in commit `90609ae`.

Status: DONE_WITH_CONCERNS
Summary: Paused partway through phase 02 on request. The swf2c asset-conversion modules are committed with 24 passing tests and clean clippy and fmt, and the conversion driver, CLI, C loader and render validation are still to do. Phases 04 and 03 were not started.
Concerns/Blockers: Phase 02's acceptance check (render within threshold of Ruffle on 20 SWFs) has not been run. The PSP build could not run because Docker was not available.
