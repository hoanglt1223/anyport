# rpy2psp phases 02-03: paused partway through phase 02

Date: 2026-10-23. Plan: `plans/261023-1558-renpy-to-psp`. Repo: `repos/rpy2psp` (local, nothing pushed).

The work was paused at the coordinator's request early in phase 02. **No commit was made.** The new code imports three modules that do not exist yet, so nothing can be tested end to end, and per the pause instructions broken work stays uncommitted.

## Phase 02 (script reader and bytecode compiler): in progress

`phase-02-script-compiler.md` status is now `in-progress`.

### Built (uncommitted, in `repos/rpy2psp/rpy2psp/compiler/`)

- `lexer.py`: the census lexer (logical lines and indentation tree), plus:
  - Ren'Py's exact string semantics, ported from `renpy/lexer.py`: whitespace collapsing, `\{`→`{{`, `\[`→`[[`, `\%`→`%%`, `\n`, `\uXXXX`, and triple-quoted monologue splitting.
  - A per-line cursor `LineLexer` with `name`, `label_name` (local labels), `image_name_component`, `simple_expression`, `delimited`, `string`, and `triple_string`, following Ren'Py's keyword and image-keyword rules.
  - A `raw` field on `Line`, so that lines rebuilt from `.rpyc` can carry Python block source.
- `reader.py`:
  - `Game`, a read-only view over loose files and `.rpa` entries.
  - Statement node dataclasses and the full `.rpy` statement parser: say (who-string, attributes, `@` temporary attributes, `nointeract`, `id`, `with`, monologue), label/jump/call/return, menu (caption, `set`, conditions), if/elif/else, while, `$` and python/init python blocks, init with priority and offset, define/default (priority, index, `+=`/`|=`), image (expression or ATL), transform, show/scene/hide (expression, `text`, at/as/behind/onlayer/zorder/with, ATL block), with, play/queue/stop, voice, pause, window, nvl, translate (dialogue, strings, python, style), and screen/style/testcase/rpy.
  - Unsupported statements (layeredimage, camera, `show layer`, `init label`, `synchro_start`, unknown words) become `Unsupported` nodes that carry the file and line.
  - `read_scripts` prefers `.rpy` over `.rpyc` and loads only the selected `tl/<language>`.

### Verified

- Both new modules parse as Python (`ast.parse`). They have not been run.
- Census unit tests: `python -m unittest test_census` in `tools/census` gives 2 tests OK. The census code is unchanged.
- The README's `python -I -m unittest test_census` fails with "No module named test_census", because `-I` drops the current directory from `sys.path`. This happened before my changes; the README command should be fixed.

### Findings that settle design questions (keep them)

- **PSP DXT is not swizzled.** In PPSSPP (`GPU/Common/TextureCacheCommon.cpp`, `DecodeDXTBlocks`), DXT is a row-major grid of 4x4 blocks with no swizzle path. Block layout (`TextureDecoder.h`):
  - DXT1 is `lines[4]`, then `color1`, then `color2`. This is the reverse of DDS, which puts the colors first.
  - DXT5 is the color block, then `u32 alphadata2`, `u16 alphadata1`, `alpha1`, `alpha2`.
  - RGB565 expands with plain shifts and no bit replication.
  - So phase 03 should write DXT in this native block order and swizzle only the uncompressed glyph atlases (T4/T8). The request said "swizzled DXT1/DXT5"; this is a necessary deviation, and the user should be told.
- **Translation IDs** (`renpy/translation/__init__.py`): the ID is `label_` plus the first 8 hex digits of md5 over each Say's `get_code() + "\r\n"`. `get_code` is `who attrs [@ tmp] "encoded what" [nointeract] [id x] [args] [with w]`. Menu captions get `nointeract`. Only `voice`, `voice sustain`, and `nvl clear` are translatable non-Say statements. Check this against `the_question/game/tl/japanese/script.rpy`, for example `start_915cb944` and `rightaway_8cb5deeb`.
- **Init priorities**: image runs at 500, screen at -500, and define/default/transform at their stated priority. All are offset by `init offset`.
- **Automatic names**:
  - `images/` files become image names: the lowercased stem with the extension removed, split on spaces. Accepted extensions are `.jpg .jpeg .png .webp .avif .svg`.
  - Files under `audio/` become `audio.<lowercased stem>` (`.wav .mp2 .mp3 .ogg .opus .flac`).
  - Both behaviours depend on version: `images/` scanning is off when `script_version <= 6.99.1`, and `audio/` when `<= 7.3.2`.
- **File search order**: `tl/<lang>/` first, then the name as given, then `images/`, `audio/`, or `fonts/`.
- **Builtins** (`renpy/common/00definitions.rpy`): positions such as left and right, `image black = Solid("#000")`, `fade = Fade(.5,0,.5)`, `dissolve = Dissolve(.5)`, `pixellate = Pixellate(1,5)`, wipe/slide = `CropMove(1.0, mode)`, `push*` = `PushMove`, `vpunch`/`hpunch` = `Move(...)`, and `move`/`ease` from `define.move_transitions`.
- **`.rpyc` format** (`renpy/script.py`): an `RENPY RPC2` header, then `(slot, start, length)` u32 triples ending at slot 0. Read slot 2 first, then slot 1; the slot data is zlib-compressed `pickle(data, stmts)`. Older files are a single zlib blob. AST field lists are recorded in `renpy/ast.py` and `renpy/atl.py`.
- **Real test material outside the repo**:
  - Arcance ships Ren'Py 6.99 `.rpyc` files (Python 2 pickles) next to its `.rpy`.
  - Zero Echoes ships `tl/None/common.rpymc` (Python 3 pickle).
  - Use these to cross-check `.rpyc` decoding against the `.rpy` parse.

### Not done

- `atl.py`, `rpa.py`, `rpyc_decode.py`, `expr.py`, `bytecode.py`, `compile.py`, `rpy2psp/cli.py`, `pyproject.toml` and the pinned requirements, `docs/dev/bytecode.md`, the golden tests under `tests/compiler/`, and corpus coverage numbers.
- The authorised `plan.md` edits: the narrowed acceptance criteria and the phase-01 status and gate text.

## Phase 03 (asset pipeline): not started

Status remains `pending`.

## Environment prepared (outside the repo)

- Venv: `%TEMP%\rpy2psp-env`. Installed: Pillow 13.0.0, numpy 2.5.4, etcpak 0.9.15 (BC1/BC3 encode and decode), lameenc 1.9.0, soundfile 0.14.0 (libsndfile 1.2.2: OGG, MP3, Opus), and soxr 1.1.0. Pin these versions in the requirements file. A local hook blocks paths named `.venv`, so the venv cannot live in the repo.
- ffmpeg is on PATH (WinGet). It could be used for optional movies.
- Full target games with assets are in `%TEMP%\rpy2psp-census\full\{the_question,arcance,zero_echoes}`. `the_question` also has `sdk-fonts/SourceHanSansLite.ttf` and `renpy/common/DejaVuSans*.woff2`, which are Ren'Py's default fonts and are needed because the_question ships no fonts.
- The `.rpy`-only census corpus is in `%TEMP%\rpy2psp-census\games`, with all 22 games present.
- Ren'Py reference sources (MIT, read-only) are in the session scratchpad `...\scratchpad\renpy-src\renpy\`. They can be re-extracted with `git show HEAD:<path>` in `%TEMP%\rpy2psp-census\games\the_question`.
- Git sparse checkout under Git Bash needs `MSYS_NO_PATHCONV=1`, or patterns without a leading `/`. Otherwise MSYS rewrites `/game/` into `C:/Program Files/Git/game/`.

## Resume from here

1. **Exact next step:** write `repos/rpy2psp/rpy2psp/compiler/atl.py` with `parse_atl(lines)`. `reader.py` imports it, and it is the first missing import. Then write `rpa.py`, with an `RpaArchive` that has `names()`, `read()`, and `close()`, supports RPA-1.0, 2.0, and 3.0, and uses a restricted unpickler that allows only `_codecs.encode`. Then write `rpyc_decode.py`, with `decode_rpyc(bytes, rel)` returning a `Line` tree and raising `RpycError`; it needs inert stand-in classes for `renpy.*` and must never construct real classes.
2. Then write `expr.py`, `bytecode.py`, and `compile.py`, plus the CLI and `rpy2psp/__init__.py`. Also add `!rpy2psp/**/*.rpy` to `.gitignore` if a prelude `.rpy` is used.
3. Files in progress, all untracked and uncommitted: `rpy2psp/compiler/lexer.py` and `rpy2psp/compiler/reader.py`. No `__init__.py` files exist yet.
4. Planned design, not yet written down in the repo:
   - **Bytecode:** a stack VM with sections for strings, symbols, labels, characters, images, displayables, transforms, transitions, and assets.
   - **Asset manifest:** a JSON manifest of asset recipes keyed by a hash of each recipe. Phase 03 consumes it.
   - **Coordinates:** pixel values stay in source-resolution space, and the engine scales them uniformly to fit 480x272.
   - **Labels and calls:** label parameters use dynamic binding (`BIND`).
   - **Defaults and loading:** `default` runs through a defaults routine, both at a new game and after a save is loaded.
   - **Testing:** a test-only Python reference VM, to play through the target games during tests.
5. After that, make the `plan.md` and phase-01 edits that the user authorised.

Status: BLOCKED
Summary: Paused by the coordinator early in phase 02. The lexer and statement parser are written but uncommitted, because their imported modules (atl, rpa, rpyc_decode) do not exist yet. Phase 03 has not started.
Concerns/Blockers: PSP DXT textures cannot be swizzled (confirmed from PPSSPP source), so phase 03 will swizzle only the glyph atlases. The authorised plan.md and phase-01 edits are still pending.
