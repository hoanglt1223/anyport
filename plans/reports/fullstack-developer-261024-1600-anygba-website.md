# AnyGBA website

Status: DONE. Commit `b1ea0d5` in `repos/anygba` (local, not pushed).

## What was built

- `site/build.py`: a static generator that needs only Python 3.11+. It wraps `site/pages/*.html` in one shared layout, fills in `{{version}}`/`{{repo}}`, and runs `tools/compat-site/generate.py` into `compat/`. It embeds the compatibility table in the site layout and writes `.nojekyll`. `--check` confirms that every internal href, src and #anchor resolves.
- Pages: Home (what AnyGBA is, how it differs from an emulator, a short "Why this exists" with the Vietnamese line, screenshots, download buttons, status), Features (what works in 0.1.0, a "Coming in 0.2" section marked as in development, known limits), Guides (install, convert, run, saves, controls and remapping, TOML config, troubleshooting, FAQ with the legal note), Tools (`--help` output of anygba, anygba-recomp, a generated game and anygba-shot), Compatibility, and About (the full story with the Vietnamese quote and a translation, how it works, contributing, licence, thanks).
- Look: a retro-but-clean style with monospace headings and pixel borders. Light and dark follow the system setting, with a toggle saved in localStorage. It is responsive, with a collapsible menu below 52rem. The site includes a skip link, a visible focus outline and alt text on images. JavaScript is about 20 lines. The site is 1 MB in total.
- Downloads use `releases/latest/download/anygba-v0.1.0-<os>.<ext>`. Change `VERSION` in `site/build.py` at each release.
- `tools/compat-site/generate.py`: `page()` is split into `body()` plus the page shell. The standalone output is unchanged apart from a scrollable table wrapper.
- `.github/workflows/pages.yml` now runs `python site/build.py --out _site --check` and also triggers on changes under `site/**`.

## Screenshots

There are five PNGs in `site/assets/shots/`, rendered with `anygba-shot` from the corpus: Varooom 3D (menu and splash), tonc `m7_demo` and `tte_demo`, and ARMWrestler. I deliberately left out tonc `brin_demo`, `bld_demo`, `win_demo` and `obj_aff`, which use Metroid tiles or sprites, and `m7_ex`, which uses Mario Kart sprites. Those demos are open source, but their art is Nintendo's.

## Verification

- `python site/build.py --check`: all internal links resolve.
- External links checked with curl: all return 200, including the three release downloads. The exception is `problemkaputt.de/gbatek.htm`, which returns 403 to scripts. That is the site's bot block, and it is the canonical GBATEK URL.
- Headless Edge screenshots of every page at 1280 px, the home page in dark mode, and a narrow viewport. A grid overflow on narrow screens was found and fixed.

## Concerns

- The README's "Why this exists" text was copied into the site rather than linked, so it has to be kept in sync by hand.
- The working tree still contains the feature agent's uncommitted runtime and recomp changes. They were left untouched and are not in this commit.
- The 0.2 feature descriptions come from the brief, not from shipped code. Check them against the feature agent's result before 0.2 is released.

Status: DONE
Summary: The static AnyGBA website is built in `site/` by `site/build.py`, with the compatibility page embedded and links checked. The Pages workflow now publishes it, and the work is committed locally as b1ea0d5.
