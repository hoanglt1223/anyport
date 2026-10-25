# PPSSPPHeadless Docker images on the Linux box

- `docker pull pspdev/pspdev` done (790 MB).
- `scripts/ppsspp-headless/Dockerfile` (stages `compile` and `run`) + `build-image.sh [ppsspp checkout]`; source: shallow clone of hrydgard/ppsspp at 1610388 in `~/anyport-scratch/ppsspp`, ext + ffmpeg submodules, debian:trixie, `-DHEADLESS=ON -DUSE_DISCORD=OFF -DUSE_MINIUPNPC=OFF`, `--target PPSSPPHeadless`, `-j6`.
- Images: `ppsspp-headless:local` (compile stage, 5.44 GB) and `ppsspp-headless-run:local` (runtime libs only, 631 MB). Both: binary + `assets/` in `/opt/ppsspp`, `/usr/local/bin/PPSSPPHeadless` symlink, WORKDIR `/work`.
- Smoke: AnySWF `hello` EBOOT (built with `scripts/psp-build.sh` in a scratch copy of the repo) ran at 60 fps in both images; `--screenshot-at=3` produced a 480x272 PNG with the RGB triangle on a dark background.
- Working command (added to CLAUDE.md):
  `docker run --rm -u "$(id -u):$(id -g)" -e HOME=/tmp -v "$PWD:/work" -w /work ppsspp-headless:local PPSSPPHeadless --memstick=/work/ms --timeout-emulated=5 --screenshot-at=3:a.png /work/ms/PSP/GAME/HELLO/EBOOT.PBP`
- Design call: kept CLAUDE.md's meaning (the `:local` tag is the build image with the binary on PATH); the slim image is also runnable.
