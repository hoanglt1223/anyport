# AnyGBA phases 08-09: finishing the compat tracker after the crash

Date: 2026-10-24 (Asia/Saigon). Repo: `repos/anygba`, three new local commits on top of `596882b`, not pushed.

## Outcome

The phase 09 work left uncommitted after the crash has been reviewed, fixed, verified and committed. The
phase 08 acceptance work is closed. The repo is ready for a v0.1.0 tag: the version is 0.1.0 in
`CMakeLists.txt` and `release.yml` triggers on `v*`. Nothing has been tagged.

| Commit | Content |
|---|---|
| `cf1ca8f` test | Unit-test temp folders now get per-process names (`tests/support/temp_dir.h`). |
| `eab35b6` feat | `compat/` (49 TOMLs + `schema.md`), `tools/compat-site/generate.py`, `tests/compat-run.cmake`, compat tests in `tests/CMakeLists.txt`, a compat CI job, `pages.yml`, README status. |
| `e407071` docs | `docs/dev/RETRO.md`. |

## Review findings and fixes

- The `ci.yml` compat job had a broken apt-get line. The shell had removed the backslash continuations,
  which left one long line with a shorter package list. I replaced it with the build job's package list.
  The other new files have no such damage: `generate.py` runs and renders all 49 titles.
- The README claimed every title gives "the same final picture as the interpreter". The check behind this
  claim (`out/fb/interp-match.json`) had never finished, so I ran it again. Running `anygba-shot` at each
  checkpoint frame matches the recorded hash for 40 of 41 titles. The exception is tonc `txt_se2`, a speed
  benchmark that prints timer counts (I checked the screenshot). Its TOML already lists this as a blocker,
  and the README now names the exception.

## Flaky unit tests

The suite passed 20 times in a row when run serially. Three test files used fixed folders under `%TEMP%`
(`anygba-save-test`, `anygba-embed-test`, `anygba-cli-test`, `anygba-replace-test`) and deleted them
with `remove_all`. When two `anygba-tests` processes ran at once, each one deleted the other's files.
This is the probable cause of the earlier failure; I could not reproduce the failure itself. After the
fix, three concurrent runs pass.

## Verification (Windows, MSVC, `out/msvc` configured with `ANYGBA_COMPAT_TESTS=ON`)

- Build is clean.
- `ctest -LE slow -j8`: 53/53 pass. This includes all 41 compat checkpoints and the `compat-site` test.
- Unit tests: 20 serial runs and 3 concurrent runs all pass.
- I did not run the `slow` label (feedback-pass and driver tests) in this session.

## Resume from here

- Before tagging `v0.1.0`, push and confirm that `ci.yml` (build plus compat on 3 hosts) and `pages.yml`
  pass on GitHub. Linux and macOS have never run. GitHub Pages must be enabled in the repo settings
  (source: GitHub Actions).
- Optionally, run `ctest --test-dir out/msvc -C Release -L slow` once before tagging.
- Phase 09 stays in progress: step 4 needs a commercial title from the user's own dump, and nothing from
  it may be committed except its TOML.
- Phase 02 still has a pending item: measuring tonc ELF discovery needs Docker (`tests/build-tonc-elves.sh`).
- Hub plan files were updated but not committed: `phase-08` (completed) and `phase-09` (status note with
  commit IDs).

Status: DONE_WITH_CONCERNS
Summary: Phase 09 work is fixed, verified (53/53 fast tests, 41/41 checkpoints) and committed in three
commits, and the likely cause of the flaky unit tests is fixed. Concern: Linux and macOS CI and the
Pages deploy have not run yet, and the commercial-title step still needs the user.
