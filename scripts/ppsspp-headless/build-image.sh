#!/bin/sh
# Builds ppsspp-headless:local (full compile image) and ppsspp-headless-run:local (runtime libs only).
# Usage: build-image.sh [ppsspp checkout] (default: shallow clone into ~/anyport-scratch/ppsspp)
set -eu
here=$(cd "$(dirname "$0")" && pwd)
src=${1:-$HOME/anyport-scratch/ppsspp}
if ! git -C "$src" rev-parse --git-dir >/dev/null 2>&1; then
    git clone --depth 1 https://github.com/hrydgard/ppsspp "$src"
fi
git -C "$src" submodule update --init --recursive --depth 1 -- ext ffmpeg
docker build -f "$here/Dockerfile" --target compile --build-arg JOBS="${JOBS:-6}" -t ppsspp-headless:local "$src"
docker build -f "$here/Dockerfile" --target run -t ppsspp-headless-run:local "$src"
