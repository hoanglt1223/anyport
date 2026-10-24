# AnyPSP playtest: Naruto: Ultimate Ninja Heroes (ULUS-10299), headless

Date: 2026-10-25 (Asia/Saigon). Repo: `repos/anypsp`, runner `out/runners/unh1-text/Release/anypsp-run-unh1-gpu.exe`, reference `out/msvc/Release/anypsp-interp-gpu.exe`. No code was changed. Game output stays in scratch, not committed.

## Outcome

The game plays headless from boot through title, mode select, team select, the stage 1 intro, a full battle with input, the pause menu and two profile screens. No crash, hang, HLE "unknown" message, or garbled texture was seen in the sampled frames. Two behaviours need a decision: the title's default cursor and silent return from Load Game with an empty memstick, and a round timer that runs slower than real time. Triangle→Circle jutsu input works headless. Save write/load was not exercised.

Coverage: about 24 distinct scenarios, against a budget of about 40. Stopped early because the machine is shutting down.

## Scratch layout

Base: `C:/Users/nguye/AppData/Local/Temp/claude/D--Projects-personal-anyport/6abeed62-62d9-4274-ac7a-e6a4cccd14e1/scratchpad/playtest/`

- `scripts/pad.py`: compiles a step list (`w N`, `t BTN[+BTN]`, `h BTN N`) to the `--input frame:mask` string. Masks are the kernel values: Circle 0x2000, Cross 0x4000, Triangle 0x1000, Square 0x8000, Start 0x0008.
- `scripts/run-scn.sh`: runs a scenario (deterministic, shared `ms/` memstick, `--png-every` dumps, `run.wav`, `hashes.txt`).
- `scripts/wav_stats.py`: level, clipping and silence stats for a WAV.
- `scripts/prefix/to-battle.txt`: the shared input prefix from boot to the first battle frame (about 9426 vblanks).
- Each scenario folder holds `steps.txt`, `input.txt`, `run.log`, frames and hashes.

## Findings, by priority

### 1. Medium: title defaults to Load Game; Cross on it returns silently to the title

- Repro: `s02-newgame/steps.txt` (`w 1500`, `t x`). The title shows Load Game highlighted with no save present. Cross leads to a grey loading frame, then a Naruto splash card, then back to the title.
- Frames: `s02-newgame/frame_001600.png` (loading), `s02-newgame/frame_001750.png` (splash), `s02-newgame/frame_001950.png` (title again). The same title state appears in `s04-v1/frame_002600.png`, `s04-v2/frame_002600.png`, `s04-v3/frame_002600.png`.
- Working path: `s05-up-x/steps.txt` (Up, then Cross) reaches MODE SELECT. Frames `s05-up-x/frame_002300.png` and `s05-up-x/frame_002900.png`.
- Log: `[savedata] mode 4` (list-load) at boot returns `kLoadNoData` with an empty memstick, which is the expected code. Nothing is written to the console for the silent return.
- Expected: New Game is the default cursor when there is no save, or Load Game is greyed out. Actual: Load Game is the default cursor and Cross on it fails with no message.
- Subsystem: the game's own title logic. Unclear whether the save-size query (`mode 8`, `sizes`) reports the wrong answer. Verify on hardware before filing.
- Shared with the interpreter: `s02-newgame/hashes.txt` and `s02-interp/hashes.txt` match on all 2122 frames, so this is not GE-specific.

### 2. Info: Triangle→Circle jutsu works headless

- Triangle alone starts Naruto's cyan aura and a red-tinted clone. Frame `s15-tri-only/frame_009800.png` against the baseline `s14-base/frame_009750.png` (no aura, full chakra bar).
- The Circle press after Triangle adds a yellow guard bubble and a projectile streak. Frame `s14-jutsu/frame_009850.png` against `s15-tri-only/frame_009850.png`, which has no bubble.
- The input reaches the game: hashes diverge from frame 9733, seven vblanks after the Triangle press (`s14-jutsu/hashes.txt` vs `s14-base/hashes.txt`).
- Caveat: the translated runner was used, and the interpreter and soft-renderer comparison was not run for these frames. Whether the clone's red tint and the chakra bar's colour are correct is not verified.
- Control mapping, from the in-game Control Settings (`s16-pause/frame_010100.png`): Attack Circle, Jump Cross, Secret Technique Triangle, Use Item Square, Select Item L, Guard R. The earlier assumption that Square attacks was wrong; Square uses items.

### 3. Low: full-scale samples in battle audio

- `s19-full-battle/run.wav`: 66 samples at full scale (46 at +32767, 20 at -32768), around 80 to 90 s of the recording. Peak 32768.
- The repeated peaks near 19200 are not a plateau (only 99 samples at that level), so they are not hard clipping.
- Likely cause: mixer headroom or float-to-int16 conversion. Subsystem: SAS mix or the audio output path. Check on hardware whether it is audible.

### 4. Open question: round timer runs slower than real time under `--deterministic`

- The round timer drops about one unit per 135 vblanks (85 at vblank 9750, 80 at 10425, 39 at 15800, 33 at 16600). At 60 vblanks per second, one unit per second would be 60 vblanks.
- Likely guest-clock effect of `--deterministic` (docs/user/desktop.md), or the game's own rate. Not verified on hardware. Severity unknown until compared with a non-deterministic run or with the PSP.

### 5. Gap: menu inventory did not match the request

- Title: New Game and Load Game only.
- Mode select carousel (`s07-modes-end`): Heroes Mode, VS CPU, Wireless (not testable), Promotion Test, Naruto's House, Parameter Power-Up.
- Naruto's House (`s17-house-param/frame_003700.png`, `frame_004700.png`): View Items, Edit Your Profile, Staff Credits.
- Parameter Power-Up (`s18-param/frame_004700.png`): renders correctly, 0 points.
- Pause menu (`s16-pause/frame_009850.png`): Control Settings (the options screen), 1P and Basic Command Charts, Achievements, Restart, Return to Mode Select.
- Shop and a standalone Options entry were not found. Skills appear in the team-select panel (`s09-course/frame_003750.png`).
- Open question: confirm whether Shop and Options exist in this build, and where.

### 6. Not verified: a full battle result and save data

- `s19-full-battle`: no save written (memstick empty), battle still running at frame 16906. Frame `s19-full-battle/frame_016600.png` shows the HUD with the timer at 33.
- `s20-result` (25250 frames, finished): frames were dumped every 500 vblanks but not reviewed before shutdown. Result screen, save prompt and any save file are unknown.

## Graphics and HUD (sampled)

No garbled text, missing textures, or z-fighting was seen in the sampled frames: title (`s01-title/frame_001400.png`), mode select, team select (`s09-course/frame_003750.png`), VS intro (`s10-battle/frame_005300.png`), battle HUD (`s14-jutsu/frame_010000.png`), pause and control screens. Sprites are small at scale 1; `--scale 2` was used for close looks.

## Speed

Headless deterministic runs ran at 38 to 320 vblanks per second, depending on host load from other agents. Game fps was about 30 (game frames are about half of vblanks). The interpreter ran at about 67 to 128 vblanks per second.

## Not covered

- Soft renderer and interpreter comparison for battle frames (the title is compared by hash only).
- Throws, chakra charge (R or L hold), item use with Square, secret jutsu beyond the Triangle start, block at close range.
- Save write and load-game path (memstick empty in every run). Pause "Return to Mode Select" and "Restart".
- Lose condition, KO result screen (`s20-result` not reviewed), Promotion Test, VS CPU, Naruto's House Edit Your Profile.
- Frame-rate or flicker checks beyond the hash comparison.

## Resume from here

1. Review `s20-result` frames at the end (result screen, save prompt), then check `ms/` for save files.
2. Edit Your Profile in Naruto's House, then save and reload to test the savedata path.
3. Interpreter run of the `s15-tri-only` steps for a hash comparison in battle at scale 1.
4. Soft renderer run of `s14-jutsu` frames 9800 and 9850 to classify the clone and bubble.
5. Throws, chakra charge, item use, and a lose condition.

## Status

Status: PARTIAL. Verified boot, title, mode select, team select, battle with input, pause menu, Naruto's House and Parameter Power-Up. Found one medium behaviour question on the title, one low audio issue, and one timing question. Save and battle-result coverage is missing.

## Unresolved questions

- Is Load Game meant to be the default cursor with no save, and should it be greyed out? Needs hardware check.
- Does the round timer run at the game's real rate under `--deterministic`?
- Where are Shop and Options in this build? Are they absent or nested under menus not reached?
- Does the clone's red tint and the chakra bar colour match PSP output?
