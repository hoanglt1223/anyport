#!/usr/bin/env bash
# Prepares an Ubuntu 24.04 box to build and test every anyport repo headless.
set -euo pipefail

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  build-essential clang lld cmake ninja-build pkg-config git git-lfs curl ca-certificates unzip p7zip-full \
  python3 python3-pip python3-venv tmux htop \
  libasound2-dev libpulse-dev libx11-dev libxext-dev libxrandr-dev libxcursor-dev libxi-dev \
  libxss-dev libxfixes-dev libxtst-dev libwayland-dev libxkbcommon-dev wayland-protocols \
  libegl1-mesa-dev libgl1-mesa-dev libgles2-mesa-dev libgl1-mesa-dri mesa-utils libdrm-dev libgbm-dev \
  libudev-dev libdbus-1-dev xvfb docker.io gh openjdk-17-jdk-headless

sudo usermod -aG docker "$USER"
sudo systemctl enable --now docker

if ! command -v cargo >/dev/null; then
  curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal
fi

if ! command -v claude >/dev/null; then
  curl -fsSL https://claude.ai/install.sh | bash
fi

# Swap so parallel compiles of large generated sources degrade instead of failing.
if ! swapon --show | grep -q /swapfile; then
  sudo fallocate -l 32G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null
fi

mkdir -p ~/anyport/repos ~/games/gba ~/games/psp
echo "setup done; log out and back in for docker group, then: gh auth login"
