# AnySWF phase 05 (runtime built-ins) and phase 06 (code parts)

Branch `feat/runtime-builtins` in `repos/anyswf-builtins` (worktree of `repos/anyswf`),
rebased on main `1871df0` (the export work). 12 commits, not pushed.

## Result

Phase 05 is implemented on PC and PSP; phase 06's profiler, VRAM texture cache and
memory accounting are implemented and measured under PPSSPP. Both phases stay
`in-progress` only for acceptance items that need the three real games or PSP-3000
hardware.

## What was done

- Linux portability: strict-C11 `posix_memalign` (main had the same fix), relative
  output dir in `build-corpus.sh`, `--jobs` for the AVM1 runner, `.pyc` untracked.
- Runtime built-ins (`runtime/src/builtins/`): prioritised action queue (Initialize,
  Construct, normal; unload ahead of queued frame scripts), all `onClipEvent`s and AS2
  handlers, AsBroadcaster, Key, Mouse (nub cursor with acceleration, mapped mouse button,
  PC keyboard/pointer from main's new platform input), SWF buttons and button-mode clips,
  drag and `_droptarget`, MovieClip methods (attachMovie, duplicate, createEmpty,
  createTextField, remove, depths, bounds, coordinates, hitTest bounds/shape,
  registerClass), drawing API with on-device tessellation, TextField/TextFormat with
  variable binding and autoSize, Date (port of Ruffle's), timers, Color, Stage, Sound
  with a lock-free software mixer (PCM, IMA ADPCM, MP3 via vendored minimp3; event,
  timeline and stream sounds), SharedObject as AMF0 `.sol` files.
- Platform: `plat_wall_clock` (sceRtc + system time zone on PSP) and a PC `user_dir`
  override for tests.
- Player/build: `anyswf.toml` runtime tables, `--input`, `--save-dir`, `--wav`,
  `--profile`, deterministic headless clock; `anyswf build` ships `--config` as
  `anyswf.toml` for every target.
- Phase 06: profiler overlay/log (`runtime/src/debug/profiler.c`), PSP VRAM texture
  residency with LRU (`runtime/src/render/texture_cache.c`), heap budget warning; two
  hot spots fixed from PPSSPP profiles (in-place GE meshes: 4.5 to 0.6 ms render; no scope
  allocation per clip per frame).
- Docs: `docs/user/USAGE.md` (new), README, EXPORT.md, runtime README, THIRD_PARTY.md;
  workspace `CLAUDE.md` AnySWF commands; plan phase files and table updated.

## Evidence (Linux box, this session)

| Check | Result |
|---|---|
| ctest (platform, runtime, builtins unit tests) | 3/3 |
| `hello --smoke` | PASS |
| swf2c fmt, clippy `-D warnings`, cargo test | clean, all pass |
| render tests (`tests/render/run.sh`) | 28/28, 1 known failure (unchanged) |
| AVM1 self-authored corpus | 15/15 (10 new tests) |
| AVM1 Ruffle `tests/ruffle-avm1` (gate >= 80%) | 165/199, 82.9% (was 164) |
| AVM1 Ruffle `tests/ruffle-avm1-builtins` (new, floor 50%) | 26/51 |
| PSP build (`scripts/psp-build.sh`) | no warnings |
| AS2 corpus as EBOOTs under PPSSPPHeadless | 11/11, 4 skipped (scripted input, UTC) |
| PPSSPP 10-minute emulated soak, two scripted scenes | 59.9 fps, heap and script heap flat |
| PSP frames vs Ruffle references | same content (diff = overlay and cursor) |

## Design calls

- New built-ins in `runtime/src/builtins/`; existing Math/String/Array stay in `avm1/`.
- Saves go to the per-game save folder from main's `ANYSWF_APP_ID` (`ms0:/PSP/SAVEDATA/<id>/`),
  not an extra `ANYSWF/<id>/` level; the runtime config ignores the build's top-level keys.
- MP3 decoded with minimp3 on the main CPU (Media Engine offload left as phase 06's optional item).
- Drawing API: even-odd band tessellation, gradients per vertex on a grid.
- Ruffle tests for the built-ins vendored as a separate suite with its own floor, so
  the original 199-test gate stays comparable; rich-text `edittext_*` tests excluded.
- Corpus expected outputs for self-authored tests follow Flash semantics as Ruffle
  implements them; where I could not verify Flash output (htmlText formatting) the test
  does not assert it.

## Remaining (and why)

- Phase 05 validation (three AS2 games playable start to finish) and phase 06
  baselines/tuning per game: the games are not on this box.
- All PSP-3000 hardware checks (psplink): no hardware here; PPSSPP only.
- Not implemented: input-text editing (sceUtilityOsk), rich-text runs/HTML layout,
  `setMask`, `beginBitmapFill`, VFPU and Media Engine work, script hot-path caches
  (waiting for game profiles). 25 of 51 built-in Ruffle tests still fail (mostly text
  metrics, Sound load semantics, timezone-fixed Date, some depth and bounds rounding).
- The PSP corpus runner skips scripted-input tests (PPSSPPHeadless cannot place the cursor).
