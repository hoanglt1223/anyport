# AnyGBA agent control API, MCP server and play journal

Date: 2026-10-24 (Asia/Saigon). Repo `repos/anygba`, branch **`feat/agent-control`** (from main `a09374a`),
worktree `D:\Projects\personal\anyport\repos\anygba\.claude\worktrees\agent-a5c22339156bc6ab4`. Seven local
commits `73c05c5..7f4d894`. Nothing is pushed. Spec: `plans/261023-1514-anygba-static-recompiler/phase-12-agent-control-api-and-mcp.md`.
I did not change the plan status, because the workspace `plans/` has uncommitted edits from other sessions.

## Outcome

Every generated game now has an agent control server and a play journal. Both are off by default, and you
can switch either one on or off while the game runs: menu Settings, F10/F11, `--control`/`--journal`, or
from MCP (`set_control` can only turn control off; `set_journal` works both ways). `anygba-mcp` is a C++
stdio MCP server that ships in the package `bin/` folder with the other programs, so no Python or Node is
needed. It lists running games, attaches by token file, or launches a built game with control on. It
provides every tool in the spec plus `detach`, `get_info`, `set_readonly`, `quit`, `list_states`,
`list_symbols`, `clear_debug`, `list_debug`, `journal_export` and `journal_clear`.

| Commit | Content |
|---|---|
| `73c05c5` | Debugger hooks in `System`: `on_watch`, called for bus accesses in watched regions. Watched regions leave the page fast path, so generated code is seen too. `on_breakpoint` is called by the interpreter before each instruction and at generated ROM function entries through the existing `AG_ENTER`/`rom_patched` check. |
| `03e7a2f` | `runtime/src/control/`: JSON, PNG, sockets, server, peek, symbols, controller. `runtime/src/journal/`. Player integration in `main.cpp`. `AiControl`/`Journal` hotkeys. Menu Settings page. |
| `0075c77` | `tools/mcp/` (`anygba-mcp`), unit tests, `mcp-e2e` CTest. |
| `3aa9abd` | `compat/symbols/BPEE.toml`. `share/anygba/symbols` install. `anygba build` copies symbols, and a `[symbols]` table in `--config` overrides them. The recompiler config accepts `symbols`. |
| `56bd896` | Ignore `__pycache__`. An earlier commit had picked up a `.pyc`; this commit removes it. |
| `39fe679` | Docs: `docs/user/AI-CONTROL.md`, `docs/dev/control-protocol.md`, the `[symbols]` section in GAME-CONFIG.md, USAGE/INPUT_MAPPING, README, and a site features card plus an "AI agents" guide section. |
| `7f4d894` | Fix: if the journal was switched off and on within one second, the new session appended to the previous session's folder. This made the e2e test fail about 1 run in 4. |

## Design decisions

- **No threads.** The game's thread polls the server, without blocking, once per VBlank. Each connection
  gets one request at a time. While the game is paused, it polls with a 15 ms timeout. Every command
  therefore runs at a frame boundary, at a stop, or at a safe point, so input stays deterministic with
  save states.
- **Input.** A command issued at frame F affects frames F+1 to F+n and is answered at F+n. On a paused
  game, input commands and `step_frames` run exactly that many frames and then pause again.
- **Save/load from a pause or stop.** The controller requests a safe point and lets the game run until it
  reaches one. It does the operation there, answers, and stays paused inside the safe-point action, where
  further loads can run directly.
- **A load moves the frame counter back.** Pending frame commands are answered as `interrupted` and queued
  input is dropped. Without this, run-until targets pointed into the old timeline. That was a real bug,
  found by the e2e hash test.
- **Breakpoints.** They stop at compiled ROM function entries or at any interpreted address. Addresses
  inside a compiled function are refused and the entry is named instead. Compiled RAM functions are
  refused because they have no `AG_ENTER`.
- **Watches.** They cover RAM, I/O, palette, VRAM and OAM, and can trigger on write, read, change or a value
  (equals). Each one either stops the game or only logs.
- **Safety.**
  - The server binds 127.0.0.1 only. `--control-host` rejects other values with exit code 2.
  - The token file holds 24 random bytes; tokens are compared in constant time.
  - A command before `hello`, or a wrong token, closes the connection.
  - Read-only mode allows only observe, debug and journal tools, and its watches and breakpoints can only
    log. Agents can turn read-only on but never off.
  - Any user GBA keypress suppresses agent input for 180 frames, and resumes the game if an agent had
    paused it.
  - When the last agent disconnects, its buttons, pause, breakpoints and watches are dropped.
  - Every mutating call is journaled with its arguments. Memory writes record the old bytes.
- **Journal.**
  - Storage is append-only JSONL, flushed after every record, under `<data>/journal/<game>/<session>/`.
  - Snapshots of `journal = true` symbols are taken every 10 emulated seconds; half-size PNG thumbnails
    every 30 seconds and on events.
  - Records include agent notes, goals and summaries. Summaries are computed from the file, so they work
    even after a crash.
  - Retention (age, then size) runs when a session starts. Export and clear are available.
  - Tokens never reach the journal, and pictures are shortened.

## Emerald symbols (verified headless on the user's ROM)

The addresses and layouts come from pret/pokeemerald: `global.h`, `pokemon.h`, `flags.h`, and
`pokeemerald.sym` on the symbols branch. Only names and numbers are committed. For the check I built the
ROM with this branch's package (scratch: `%TEMP%\agc-em\g`, outside the repo) and started from a copy of
phase 10's save. I then played it **through `anygba-mcp`** from CONTINUE, through the truck, the clock,
the rival's house and Route 101, to the starter battle. Results:

- Player name `AAAAAAA`. Trainer ID 44574, which equals the low half of the party's OT ID.
- Play time, map and position: truck (25,40), Littleroot (0,9), house 1F/2F (1,0)/(1,1), Route 101 (0,16),
  all matching `map_groups.json`.
- Money 3000 (XOR key ≠ 0), and 999999 with the shipped cheat.
- PC Potion ×1, Master Ball ×99 through the cheat (bag quantity XOR), steps and battles counted.
- `has_pokemon` flag set after the starter. Party: count 1, TORCHIC Lv5 19/19 HP with plausible stats.
- `battle_mons`: Torchic species 280, Fire/Fire, Blaze, Scratch/Growl, against Zigzagoon 288 Lv2 with
  Pickup, Tackle/Growl.

Party species, moves and IVs are encrypted and not listed. During battle, `battle_mons` shows them in
the clear.

## Tests

- **Unit (doctest)**: JSON; PNG round trip; buttons; symbols (pointer, XOR, bits, text, struct arrays,
  errors); journal (records, summary, search, retention, export, clear, crash-truncated line, quick
  restart); server (loopback only, token handshake, one request at a time, token file removed); menu
  Settings page; shipped symbol files parse.
- **`mcp-e2e`** (CTest, `RUN_SERIAL`): `anygba-mcp` over stdio drives the recompiled tonc `swi_vsync`
  through the following steps:
  - launch and tools/list;
  - wrong-token and before-hello refusals, and a non-loopback bind refused;
  - pause, screenshot PNG, and press/step frame counts;
  - KEYINPUT reflecting held agent buttons;
  - save, 60 frames, load, 60 frames, with identical frame hashes (and different from the hash at the save);
  - write and read memory and named symbols;
  - a cheat;
  - a watch stop at `0x03007FF8` and a breakpoint at the IRQ handler;
  - speed;
  - journal off and on (two sessions, nothing journaled while off);
  - control off (token file gone), then back on through the user's scripted F10 and re-attach with a new
    token;
  - quit, an offline journal summary, and read-only refusals;
  - a final check that the journal holds every command, the old bytes of memory writes, errors, the user's
    toggle, and no token.

  Six consecutive runs passed after the fix.
- **Full CTest** (`out/msvc`, MSVC, `/WX`): 19/19 pass with slow tests included (driver-build, feedback
  passes, install). The exception is `player-menu`, below. I did not run the compat checkpoints (they are
  off in this build tree).

## Concerns

- **`player-menu` fails on this PC because of the environment.** It passed earlier in this session, with
  my menu and hotkey changes in place. Then another session wrote
  `%APPDATA%\anyport\anygba\anygba-input.ini` with A and B swapped (18:38), along with Emerald saves and
  states in `%APPDATA%\...\saves`. None of these are mine. The test's `--write-input` copies that user
  file, so the scripted keys no longer reach Cheats. The test is not hermetic against the user's data
  folder. I left the user's files untouched.
- `python site/build.py --check` exits 1 because of the existing `compat/pokemon-emerald.toml` source text
  ("missing the user's own cartridge dump"). That problem is on main and is not caused by this branch's
  site edits.
- Windowed paths are untested on this PC: the indicator drawing, the idle presentation while paused, a real
  keypress taking over, and hotkeys while paused. The same code paths run headless.
- While the in-game menu is open, agents get no answers (documented). Commands are answered once per
  frame, so many small commands are limited to about 60 per second at 100%.
- Pokemon Emerald: the RTC work on main has not been merged here. With a working clock, Emerald behaviour
  may change; the symbol layouts will not.
- Merge risk with parallel branches: small edits to `system.hpp`, `bus.cpp`, `dispatch.cpp`,
  `rom_patch.cpp`, `boot_state.cpp`, `input_map.*`, `menu.*`, `main.cpp`, `cmake/install.cmake`, root and
  `tests/CMakeLists.txt`, `tools/anygba/build.cpp` and `tools/recomp/config/game_config.cpp`. The menu
  gained a Settings page; feat/video-filters may add one too.

## Scratch artefacts (not in the repo)

- Emerald build with the ROM embedded: `C:\Users\nguye\AppData\Local\Temp\agc-em\`. Delete it when no
  longer needed.
- Play scripts, states and screenshots: this scratchpad's `agent-control\` folder (`emu.py`, `s*.py`, `em\`).
- No game or MCP processes are left running.

Status: DONE_WITH_CONCERNS
Summary: The agent control server, the play journal (both switchable at runtime), `anygba-mcp` with
observe/play/control/debug/journal tools, per-game `[symbols]` and a Pokemon Emerald symbols file
verified by playing to the first battle through MCP are committed on `feat/agent-control` with docs and
tests. The stdio e2e test and the full CTest pass. The exception is `player-menu`, which fails because
another session wrote a remapped `anygba-input.ini` into the user's data folder.
