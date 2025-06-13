#!/bin/bash
# SPDX-License-Identifier: MIT OR GPL-3.0-or-later

set -eux -o pipefail

apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get install \
  advancecomp \
  blender \
  curl \
  cmake \
  dbus \
  dbus-x11 \
  dotnet-sdk-8.0 \
  diffutils \
  emacs \
  ffmpeg \
  file \
  fonts-noto \
  git \
  git-lfs \
  gnome-remote-desktop \
  gnupg \
  imagemagick \
  less \
  libsm6 \
  libxi6 \
  libxkbcommon0 \
  lxterminal \
  mesa-utils \
  moreutils \
  mutter \
  netcat-openbsd \
  nkf \
  patchutils \
  procps \
  python3-pygit2 \
  python3-numpy \
  python3-tqdm \
  python3-typing-extensions \
  recordmydesktop \
  ruby \
  shellcheck \
  shfmt \
  sudo \
  supervisor \
  xubuntu-desktop \
  xserver-xorg-input-all \
  uchardet \
  unzip \
  vim \
  x11-xserver-utils \
  x11vnc \
  xorgxrdp \
  xvfb \
  xrdp \
  xz-utils \
  weston \
  wget \
  winpr-utils \
  zopfli \
  zsh \
  -y
