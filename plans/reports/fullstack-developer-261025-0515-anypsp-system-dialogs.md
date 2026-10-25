# AnyPSP: system utility dialogs in the desktop window

Date: 2026-10-25 (UTC). Repo: `repos/anypsp`, branch `feat/system-dialogs` in the worktree `repos/anypsp-dialogs` (from `d28d6cf`). Build: `repos/anypsp-dialogs/out/linux` (clang, Release, Ninja). Not merged, not pushed.

## Outcome

AnyPSP now draws the PSP's message and savedata dialogs over the running game in the window and waits for the player. Headless runs still answer them at once by default, and their frame hashes are unchanged.

In Naruto: Ultimate Ninja Heroes (ULUS-10299), choosing Load Game with an empty memory stick shows "There is no data." until Cross or Circle is pressed, then the game goes on as before (result `0x80110307`). Saving in Naruto's House shows the system list with three "New data" slots, saves on Cross, and shows "Save completed.", which closes after one second. Load Game with that save shows the save with its ICON0, title, detail and date, then "Load completed.".

## Commits

| Commit | What |
|--------|------|
| `ef0116a feat(hle): interactive message and savedata dialogs` | `system_dialog.hpp` (host-agnostic `SystemDialog`), `Kernel::set_interactive_dialogs`, `system_dialog()`, `dialog_move/focus/confirm/back`; message dialog and savedata flows in `devices.cpp` and `savedata.cpp`; 6 HLE tests |
| `acd0bf9 feat(desktop): draw the PSP system dialogs over the game` | `runtime/gpu/dialog_overlay.{hpp,cpp}` (Frame, View, Keys, Icons, Overlay), the glue in `main_gpu.cpp` (`--dialogs auto\|show`), 21 strings in en and vi, `load_icon_pixels` shared with the Saves tab, 4 UI tests, and 17 golden pictures (`tests/golden/menu/dialog-*.png`, 456 KB) |
| `0cde325 docs(desktop): system dialogs and --dialogs` | `docs/user/desktop.md`, new "System dialogs" section |
| `b58bda7 feat(hle): list delete returns to the list while saves remain` | Coordinator decision: after "Delete completed." the list comes back while saves remain; it closes with the delete result when the list is empty or the player backs out (cancel if nothing was deleted). New HLE test. |

## Behaviour (PPSSPP's `PSPMsgDialog.cpp`/`PSPSaveDialog.cpp` as the reference; our own code)

- Message dialog: mode 0 shows "An error has occurred. (80XXXXXX)", mode 1 shows the game's text. Option `0x10` gives Yes/No and `0x100` starts the focus on No; otherwise there is a single OK. Status stays 2 until the player answers, then it becomes 3. On answer the dialog writes result 0 at `0x1C` and `0x30`, and buttonPressed at `0x240`: 1 for Yes, 2 for No, and 3 for going back.
- Savedata modes:
  - LISTLOAD or LISTDELETE with no saves shows "There is no data.", then returns NoData (`0x80110307` / `0x80110347`).
  - The list shows the saves, plus "New data" when saving. Circle cancels with result 1. Loading, or saving to new data, runs at once.
  - Saving over a save, or deleting one, asks first, starting on No. No goes back to the list.
  - After the action comes "X completed.", which closes on Cross or after 1 s of guest time. A Store error shows "Unable to ... (code)" and returns that code.
  - LOAD, SAVE and DELETE without a list ask Yes/No first. Loading or deleting a missing save shows "There is no data.". AUTO* and data-only modes have no UI.
- Input: Cross confirms, Circle goes back, and the d-pad moves with key repeat. The game gets a released pad and a centred stick while a dialog is open. Buttons still held when it closes stay hidden from the game until they are released. Mouse clicks and taps choose rows and buttons, and the wheel moves the focus. The game keeps running underneath, and Escape still opens the menu on top.
- Look: a dimmed backdrop and a card in the menu's theme, language and UI scale, drawn at window resolution. It is drawn through `GlHost::edit_window` before the frame-rate badge (the overlay is chained with the new `GlHost::overlay()` getter).

## Deviations from the design

- **The game's button layout decides Cross or Circle.** The design said Cross confirms. I read `buttonSwap` (common `+8`), as the PSP and PPSSPP do: 1 means Cross confirms. Japanese-layout games confirm with Circle, and the footer glyphs follow. For UNH1 (US) it is Cross.
- **What a plain OK message reports.** On a PSP a plain message has no confirm button, so confirming it reports what going back reports: 0 for V1/V2 requests, 3 for V3. The V3 OK option reports 1. A V1 request (572 bytes) gets no buttonPressed write. The non-interactive path still writes 1 at `0x240` as before.
- **Answering moves the status to 3 at once.** If status is already 2, the next GetStatus returns 3. The non-interactive sequence 1, 2, 3 is unchanged.
- **The dialog view lives in AnyPSP, not in anyui.** `anyui/` must stay identical with AnyGBA's copy, so `dialog_overlay.*` uses anyui's Canvas, Font, Theme and icons from AnyPSP's side.
- **`--dialogs auto|show` was added.** The default is show in a window and auto headless. It was needed to capture real-game dialog pictures headless; `--input` drives the answers.

## Tests

- `anypsp_hle_tests`: 26/26 (after the list-delete follow-up). New cases:
  - non-interactive message dialog answers Yes;
  - interactive message dialog: Yes/No with default No, back, error code, V3 OK, V1, shutdown while open;
  - LISTLOAD and LISTDELETE with no saves, non-interactive and interactive, with the full status sequence;
  - list save to new data, the overwrite question with No back to the list, cancel, list load, list delete;
  - single-slot LOAD, SAVE and DELETE, plus an AUTO mode;
  - the completed message closing itself after about one second of vblanks.
- `anypsp_desktop_tests`: 38/38. New cases:
  - frames, translations, error codes and wrapping;
  - Keys: no double action, layout swap, list repeat;
  - golden pictures: list, overwrite question, no data, and Yes/No, each in en and vi, dark and light, at 1x, plus the list at 2x;
  - the Overlay following the menu's language and theme, with a real ICON0.PNG.

  I looked at the pictures myself.
- `ctest --test-dir out/linux -E corpus_analysis`: 5/5 passed.
- Frame-hash checks (auto, the headless default), baseline `d28d6cf` against the branch, both `--deterministic`:
  - input4 (6000 vblanks): identical, and also identical to `scratch-out/unh1-fu/sas/h.txt`;
  - Load Game on an empty memory stick (1800 vblanks): identical.

## Screenshots (`/home/ubuntu/anyport/scratch-out/dialogs/`)

- `unh1-load-nodata.png`: "There is no data." over the title (1x headless).
- `unh1-save-flow-sheet.png`: the game's "Save data?", the system list, "Save completed.", then Mode Select.
- `unh1-load-list-2x.png`, `unh1-load-completed-2x.png`: the list with the real ICON0, and "Load completed.".
- `goldens/`: all 17 golden pictures at full size.
- `hashes/`: the before and after hash files. `hashrun.sh` is the run script.

## What is left

- The window path was not run on this box. There is no display, and the rule is to keep games `--headless` here. It needs a desktop check: drawing, mouse and taps, gamepad, Escape over a dialog, and the badge on top. The same drawing and input code is exercised by the headless show runs and the unit tests; only the `edit_window` and pointer glue in `main_gpu.cpp` is untested.
- Not done: `sceUtilityMsgDialogAbort`, the netconf and gamesharing dialogs (still answered at once), the OSK, and "Loading/Saving, please wait" steps. Saving is instant here.
- The full-window readback and redraw costs a few milliseconds per presented frame while a dialog is open. This is fine at 1080p; it is worth measuring at 4K.

## Unresolved questions

- None. Decided by the coordinator: list delete returns to the list (done in the follow-up commit), and the Load icon stays.
