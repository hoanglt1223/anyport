# Emerald filter comparison and Android APK (Linux)

## Outcome

- **A. Filter comparison: done.** 29 variants were rendered for 6 Emerald scenes (title, Birch intro dialogue, naming screen, Littleroot Town, starter choice, first battle), and each scene has a labelled full grid and a zoom grid. A new input script reaches all six scenes from boot.
- **B. APK: done, rebuilt at the coordinator's request.** `/home/ubuntu/anyport-out/android/Pokemon Emerald.apk` is built from `main` at `ae90434` (the redesigned menu plus the Video-tab live preview and graphics presets) for arm64-v8a, signed with the same debug key. It is versionCode 1480621, SHA-256 `742150c1...3dc1`. `libmain.so` contains `video.preset` / "Graphics preset". The first APK was also built with an Android runtime from `ae90434`, which was already committed when that runtime was built, but this rebuild uses a desktop toolchain and runtime that are both fresh at `ae90434`. **It will not install over the APK that is on the phone now** (see Concerns).
- No AnyGBA code was changed and nothing was committed. Linux needed one configure flag (below), but nothing in the code was broken.

## Recommendation: `xbrz4x`

This is based on the zoom grids at 4x output (960x640).

- **Text:** the dialogue, naming and battle-menu fonts get rounded strokes, and each letter keeps its shape and its drop shadow. `xbr4x` bends letters (the "L"s of the LITTLEROOT TOWN sign warp). `hq4x`, `hq3x`, `2xsai` and `super-2xsai` blur the text and run the shadow into the glyph. `scale4x` and `eagle` leave stair-steps.
- **Sprite edges:** Torchic, the player and Birch get clean anti-aliased outlines. Their shading and the grass dither stay intact; `xbr4x` turns the dither into blotches.
- **Artifacts:** none of note. The AI options change the art itself:
  - `ai=frame general-x4v3` removes the text shadows and wipes out the grass texture.
  - `ai=frame x4plus` and the x4plus AI pack turn the font's "e" into an "o" ("at timos").
  - The AI pack keeps blocky sprite silhouettes, while the inside of each sprite is smoothed.
  - On this CPU the AI options take 0.5 s (general) and 7.6 s (x4plus) per frame, so neither is real time here.
- **Alternatives:** `sharp-bilinear` (identical to `nearest` at whole multiples, with even pixels otherwise) is the purist pick. `xbrz4x+lcd-grid` gives a handheld look, but the grid darkens the picture noticeably.

## Paths

- Grids:
  - `/home/ubuntu/anyport-out/emerald-filters/grid-<scene>.png`: every variant at full 960x640, 5 per row, with names.
  - `zoom-<scene>.png`: the same text or sprite crop of every variant, enlarged 2x.
  - `zoom-shortlist.png`: 11 shortlisted filters, one row per scene.
- Raw shots: `shots/<variant>/<scene>.png`.
- Input script: `emerald-route.txt` (`--script` format, 664 events). Run it with `--no-save --rtc-start 1792900000`. Scene frames: 3900 title, 6220 dialogue, 7900 naming, 18600 Littleroot, 26840 starter, 27620 battle (Zigzagoon; Emerald's first battle is Zigzagoon, not Poochyena). A feedback-built binary reached the same battle, so the script is not tied to one build.
- Renderers:
  - `render-filters.py`: one game run per variant; the AI pack variant takes `EMERALD_AI_PACK=<pack dir>`.
  - `render-ai-frame.py`: the `ai=frame` shots.
  - `make-grids.py`: builds the grids.
- What `--filter` accepts:
  - Scalers: nearest, bilinear, sharp-bilinear, scale2x/3x/4x, eagle, 2xsai, super-2xsai, super-eagle, hq2x/3x/4x, xbr2x/3x/4x, xbrz2x-6x.
  - Effects: lcd-grid, scanlines, crt.
  - `ghosting`.
  - All of the above can be joined with `+`.
  - AI is set through `--video ai=frame|layers;ai-model=general-x4v3|x4plus` or `--hd-pack`. `ai=layers` was not rendered because it runs 5 models per frame.
- Rendered variants: every scaler, the three effects on nearest, `nearest+ghosting`, `xbrz4x+lcd-grid`, `ai=frame` with both models, and an x4plus AI pack.
- APK: `/home/ubuntu/anyport-out/android/Pokemon Emerald.apk` (32.7 MB).
  - Package `io.anyport.anygba.ga9dec84dfe7f` (same id as before), versionCode 1480595, versionName 0.3.1.
  - arm64-v8a, the same ABI as the previous user APK.
  - v2/v3 signatures verified, `zipalign -P 16` passes, and `libmain.so` contains the new menu's Speed section strings.
  - Built with two trace-feedback passes from the route: 2958 interpreted addresses before feedback, 88 after.

## How it was done (Linux notes)

- **Desktop build:** `out/linux-filters`, clang and Ninja, `-j5`. clang has no `clang-scan-deps` here, so configure needs `-DCMAKE_CXX_SCAN_FOR_MODULES=OFF` (gcc would avoid this). It was installed to `out/linux-filters/prefix`.
- **Android runtime:** `build-runtime.cmake` with `BUILD_ROOT=out/linux-android`, run under `taskset` to 5 cores because the script calls `--parallel` with no limit.
- **SDK:** cmdline-tools, platform-tools, `platforms;android-35`, `build-tools;35.0.0` and `ndk;27.0.12077973` are now in `~/android-sdk`, with licences accepted.
- **AI:** ONNX Runtime 1.24.4 for linux-x64 was downloaded to scratch and used through `ANYGBA_ONNXRUNTIME`. The models were downloaded once into a scratch cache (`ANYGBA_AI_CACHE`). After that, everything runs offline.
- **AI frame shots:** `ai=frame` shows the newest finished upscale, which lags by seconds on a CPU. These shots therefore load a save state taken at each scene and are taken 600 frames later (900 for x4plus) at paced speed with no input. Animated scenes (title shimmer, Littleroot's town sign and walking NPC, Torchic's idle bob) can differ slightly from the other shots.
- **AI pack:** the HD dump for the six scenes (1350 images, from the states) was upscaled with `hdpack ai-upscale --model x4plus` in 187 s on CPU. The pack covers only those scenes.
- **Ghosting:** the naming-screen shot still shows Birch from the previous screen, because ghosting blends across the scene cut. That is expected.
- **Kept / cleaned up:** scratch (game binaries, states, dumps, pack, ROM-derived data) is in `/tmp/claude-1000/-home-ubuntu-anyport/b2f7615d-93a0-4725-a2a6-4c0fc60c5915/scratchpad/emf`. All processes I started have exited.

## Concerns

- **Signing key differs from the phone's APK.** The previous APK was signed with the Windows PC's debug key (SHA-256 `86f66eab...dc2b`). This one uses a new Linux debug key (`f4168f91...7289`, in `~/.android/debug.keystore`). Android will refuse it as an update, and uninstalling deletes the saves. Before switching, export the save (Setup > save export) or the `.sav` from the phone. The alternative is to rebuild on the Windows PC, or with that PC's `debug.keystore` passed through `--keystore`.
- **The APK was not run on a device or emulator.** This user cannot access `/dev/kvm`, so no emulator ran. The same commit's desktop build plays the whole route.

## Unresolved questions

- Should the Windows `debug.keystore` be copied here, so that Linux-built APKs update the phone in place?
- Should a full-game x4plus AI pack be generated? The full route dump has about 20k images, roughly 45 minutes on 5 CPU cores.

Status: DONE_WITH_CONCERNS
Summary: Filter grids for 29 variants across 6 Emerald scenes are in /home/ubuntu/anyport-out/emerald-filters (recommendation: xbrz4x), and the v0.3.1 arm64 APK with the new menu is at /home/ubuntu/anyport-out/android/Pokemon Emerald.apk.
Concerns/Blockers: The APK is signed with a new Linux debug key, so it cannot update the phone's existing install without uninstalling, which deletes saves. It was not run on an emulator (no KVM access).
