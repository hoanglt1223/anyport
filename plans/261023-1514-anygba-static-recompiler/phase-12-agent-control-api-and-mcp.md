---
phase: 12
title: "Agent control API, MCP server, and play journal"
status: pending
effort: 2-3w
dependsOn: [10]
---

# Phase 12: Agent control API, MCP server, and play journal

## Context

The user wants AI agents to play, debug, and take control of a running AnyGBA game, and to keep a log and audit trail so an agent can learn from earlier sessions and play better. Everything is a runtime setting that can be switched on and off while the game runs, with no restart. Builds on save states, cheats, speed control, and the in-game menu from phase 10.

## Requirements

- **Control server inside the game**, off by default. Toggled at runtime from the in-game menu (Settings > AI control), a hotkey, or `--control` at start; turning it off closes connections immediately. Listens on 127.0.0.1 only, with a random token written to a per-user file (`%APPDATA%\anyport\anygba\control\<game>.json`: port, token, pid). Newline-delimited JSON-RPC over TCP. The OSD shows when an agent is connected and when it is pressing buttons.
- **`anygba-mcp`**: stdio MCP server (separate tool in the package) that lists running games, attaches by token file, or launches a built game exe with control on. Tools:
  - observe: `screenshot` (PNG image content, optional scale), `get_state` (frame, fps, speed, paused, connected pad, active cheats), `read_memory`, `read_named` (per-game symbols);
  - play: `press` / `hold` / `release` buttons for N frames, `input_sequence`, `step_frames`, `pause`, `resume`, `set_speed`;
  - control: `save_state` / `load_state` (slots and named states), `list_cheats` / `set_cheat`, `write_memory` (logged);
  - debug: `get_registers`, `disassemble`, `watch_memory` (stop or notify on write/read/value), `break_at_function` (function entries in recompiled code; any address in interpreter-run code), `get_call_stack`, `get_miss_log`, `tail_log`;
  - journal: `journal_search`, `journal_note`, `journal_summary`.
- **Per-game symbols**: `[symbols]` in the game TOML (name, address, type, count, struct layout) so agents read `party[0].hp` or `money` instead of raw bytes. Ship a symbols file for Pokémon Emerald (US) from public RAM maps (decomp project pokeemerald), verified headless on the user's ROM.
- **Play journal / audit trail**, toggled at runtime independently of the control server (Settings > Journal, hotkey, `--journal`, MCP `set_journal`):
  - append-only JSONL per session under the per-user data folder: every agent command with arguments, result and frame number, who issued it (agent/user/cheat), state saves/loads, memory writes, cheat toggles, speed changes, errors;
  - periodic snapshots of named symbols (configurable interval) and of the frame (thumbnail every N seconds or on events) so an agent can see what happened;
  - agent notes and goals (`journal_note`) and an end-of-session summary;
  - retention limit (size/days) and a way to export or clear; no data leaves the PC.
- **Safety**: every mutating call (write_memory, load_state, cheats) is in the journal; a "read-only agent" mode allows observe and debug tools only; user input always works and can take over at any time (user keypress pauses agent input for a configurable time).

## Files

- `runtime/src/control/` (server, JSON-RPC, command handlers), `runtime/src/journal/`
- `tools/mcp/` (`anygba-mcp`), `compat/symbols/` or the game TOML schema extension
- `docs/user/AI-CONTROL.md`, `docs/dev/control-protocol.md`

## Steps

1. Protocol doc and the in-game server behind a runtime toggle; token file; OSD indicator.
2. Observe and play commands; frame-accurate input queue; pause and step.
3. Control and debug commands on top of save states, cheats, and memory hooks; function-entry breakpoints and memory watches.
4. Journal with runtime toggle, retention, export.
5. `anygba-mcp` with all tools; launch/attach; image content for screenshots.
6. Emerald symbols, verified headless.
7. Docs, README, website section.

## Validation

- Headless end-to-end test: launch a corpus game with control on, connect through `anygba-mcp` over stdio, press buttons, step, screenshot, save/load state and check frame hashes match, toggle control and journal off and on without restart, and check the journal records every call.
- Token and localhost-only checks: a wrong token and a non-loopback bind are rejected.
- No game data committed; Emerald symbols are addresses and names only.

## Risks

- Breakpoints inside translated functions are limited to function entries; document it.
- Input timing: agent input must be applied at frame boundaries to stay deterministic with save states.
