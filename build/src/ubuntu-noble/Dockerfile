# SPDX-License-Identifier: MIT

FROM ubuntu:noble

# https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

WORKDIR /root

RUN <<'INSTALL_BASE_PACKAGES'
  set -eu
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install \
    "apt-transport-https=*" \
    "curl=*" \
    "ca-certificates=*" \
    "gnupg=*" \
    "lsb-release=*" \
    "openssl=*" \
    "pkg-config=*" \
    "software-properties-common=*" \
    -y --no-install-recommends
  apt-get dist-clean
  rm -rf /var/lib/apt/lists/*
INSTALL_BASE_PACKAGES

# https://github.com/cli/cli/blob/v2.65.0/docs/install_linux.md#debian-ubuntu-linux-raspberry-pi-os-apt
RUN <<'INSTALL_GH'
  set -eu
  curl --fail --show-error --location --retry 5 --retry-all-errors --output /etc/apt/keyrings/githubcli-archive-keyring.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg
  chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install "gh=*" -y --no-install-recommends
  apt-get dist-clean
  rm -rf /var/lib/apt/lists/*
INSTALL_GH

# https://code.visualstudio.com/docs/setup/linux#_install-vs-code-on-linux
RUN <<'INSTALL_VISUAL_STUDIO_CODE'
  set -eu
  curl --fail --show-error --location --retry 5 --retry-all-errors --output code.deb https://go.microsoft.com/fwlink/?LinkID=760868
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install ./code.deb -y --no-install-recommends
  rm code.deb
  apt-get dist-clean
  rm -rf /var/lib/apt/lists/*
INSTALL_VISUAL_STUDIO_CODE

# https://docs.unity3d.com/hub/manual/InstallHub.html#install-hub-linux
RUN <<'INSTALL_UNITY_HUB'
  set -eu
  curl --fail --show-error --location --retry 5 --retry-all-errors https://hub.unity3d.com/linux/keys/public | gpg --dearmor > /usr/share/keyrings/Unity_Technologies_ApS.gpg
  echo "deb [signed-by=/usr/share/keyrings/Unity_Technologies_ApS.gpg] https://hub.unity3d.com/linux/repos/deb stable main" > /etc/apt/sources.list.d/unityhub.list
  apt update
  apt-get install "unityhub=*" -y --no-install-recommends
  apt-get dist-clean
  rm -rf /var/lib/apt/lists/*
INSTALL_UNITY_HUB

RUN <<'INSTALL_GOOGLE_CHROME_STABLE'
  set -eu
  curl --fail --show-error --location --retry 5 --retry-all-errors --output google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install ./google-chrome.deb -y --no-install-recommends
  rm google-chrome.deb
  apt-get dist-clean
  rm -rf /var/lib/apt/lists/*
INSTALL_GOOGLE_CHROME_STABLE

# https://support.mozilla.org/en-US/kb/install-firefox-linux
RUN <<'INSTALL_FIREFOX_ESR'
  set -eu
  install -d -m 0700 ~/.gnupg
  install -d -m 0755 /etc/apt/keyrings
  curl --fail --show-error --location --retry 5 --retry-all-errors https://packages.mozilla.org/apt/repo-signing-key.gpg --output /etc/apt/keyrings/packages.mozilla.org.asc
  gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc \
    | awk '/pub/{getline; gsub(/^ +| +$/,""); if($0 == "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3") print "\nThe key fingerprint matches ("$0").\n"; else print "\nVerification failed: the fingerprint ("$0") does not match the expected one.\n"}'
  echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" >> /etc/apt/sources.list.d/mozilla.list
  echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' > /etc/apt/preferences.d/mozilla
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install "firefox-esr=*" -y --no-install-recommends
  apt-get dist-clean
  rm -rf /var/lib/apt/lists/*
  update-alternatives --set x-www-browser /usr/bin/firefox-esr
INSTALL_FIREFOX_ESR

# https://developer.nvidia.com/cuda-downloads
# https://docs.nvidia.com/cuda/cuda-installation-guide-linux/#meta-packages
RUN <<'INSTALL_CUDA_TOOLKIT'
  set -eu
  if uname -r | grep -Eq "\-microsoft-standard-WSL2$"; then
    cuda_keyring_os=wsl-ubuntu
  else
    cuda_keyring_os=ubuntu
  fi
  curl --fail --show-error --location --retry 5 --retry-all-errors --output cuda-keyring.deb "https://developer.download.nvidia.com/compute/cuda/repos/${cuda_keyring_os}/x86_64/cuda-keyring_1.1-1_all.deb"
  DEBIAN_FRONTEND=noninteractive apt-get install ./cuda-keyring.deb -y --no-install-recommends
  rm cuda-keyring.deb
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install "cuda-toolkit-12-9=*" -y --no-install-recommends
  apt-get dist-clean
  rm -rf /var/lib/apt/lists/*
INSTALL_CUDA_TOOLKIT

RUN <<'INSTALL_OFFICIAL_PACKAGES'
  set -eu
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install \
    "advancecomp=*" \
    "apt-file=*" \
    "audacity=*" \
    "blender=*" \
    "build-essential=*" \
    "check=*" \
    "cmake=*" \
    "curl=*" \
    "dbus-x11=*" \
    "dbus=*" \
    "diffutils=*" \
    "dotnet-sdk-8.0=*" \
    "emacs=*" \
    "ffmpeg=*" \
    "file=*" \
    "fonts-noto-cjk-extra=*" \
    "fonts-noto-cjk=*" \
    "fonts-noto-color-emoji=*" \
    "fonts-noto-core=*" \
    "fonts-noto-extra=*" \
    "fonts-noto-hinted=*" \
    "fonts-noto-mono=*" \
    "fonts-noto-ui-core=*" \
    "fonts-noto-ui-extra=*" \
    "fonts-noto-unhinted=*" \
    "fonts-noto=*" \
    "git-lfs=*" \
    "git=*" \
    "gnome-keyring=*" \
    "gnupg=*" \
    "ibus-gtk=*" \
    "ibus-gtk3=*" \
    "ibus-gtk4=*" \
    "ibus-mozc=*" \
    "ibus=*" \
    "im-config=*" \
    "imagemagick=*" \
    "jq=*" \
    "less=*" \
    "libavcodec-dev=*" \
    "libavformat-dev=*" \
    "libepoxy-dev=*" \
    "libfreetype-dev=*" \
    "libfuse2t64=*" \
    "libfuse3-dev=*" \
    "libgbm-dev=*" \
    "libimlib2-dev=*" \
    "libjpeg-turbo8-dev=*" \
    "libmp3lame-dev=*" \
    "libopenh264-dev=*" \
    "libopus-dev=*" \
    "libpam0g-dev=*" \
    "libpulse-dev=*" \
    "libsm6=*" \
    "libssl-dev=*" \
    "libx11-dev=*" \
    "libx264-dev=*" \
    "libxfixes-dev=*" \
    "libxi6=*" \
    "libxkbcommon0=*" \
    "libxrandr-dev=*" \
    "libxrandr-dev=*" \
    "mesa-utils=*" \
    "moreutils=*" \
    "nasm=*" \
    "netcat-openbsd=*" \
    "nkf=*" \
    "paprefs=*" \
    "patchutils=*" \
    "pavucontrol=*" \
    "procps=*" \
    "pulseaudio-utils=*" \
    "pulseaudio=*" \
    "recordmydesktop=*" \
    "ruby=*" \
    "shellcheck=*" \
    "shfmt=*" \
    "sudo=*" \
    "supervisor=*" \
    "unzip=*" \
    "upower=*" \
    "vim=*" \
    "wget=*" \
    "winpr-utils=*" \
    "x11-utils=*" \
    "x11-xserver-utils=*" \
    "xdotool=*" \
    "xfce4-pulseaudio-plugin=*" \
    "xfce4-terminal=*" \
    "xorg=*" \
    "xserver-xorg-dev=*" \
    "xserver-xorg-input-all=*" \
    "xubuntu-desktop=*" \
    "xvfb=*" \
    "xz-utils=*" \
    "zopfli=*" \
    "zsh=*" \
    -y --no-install-recommends

  apt-get dist-clean
  rm -rf /var/lib/apt/lists/*
INSTALL_OFFICIAL_PACKAGES

RUN <<'INSTALL_XRDP'
  set -eu
  curl --fail --show-error --location --retry 5 --retry-all-errors --output xrdp.tar.gz https://github.com/neutrinolabs/xrdp/releases/download/v0.10.3/xrdp-0.10.3.tar.gz
  test "$(shasum -a 512256 xrdp.tar.gz)" = "f5435113ee2e1faa483743f6a000dae579f667ff185a00a53f0bce31a05eb65c  xrdp.tar.gz"
  mkdir -p xrdp
  cd xrdp
  tar -xf ../xrdp.tar.gz --strip-components=1
  ./configure \
    --enable-fuse \
    --enable-opus \
    --enable-pixman \
    --enable-x264 \
    --enable-openh264 \
    --enable-mp3lame \
    --enable-utmp \
    --enable-rdpsndaudin \
    --enable-vsock \
    --enable-jpeg \
    --with-imlib2=yes \
    --with-freetype2=yes
  make
  make install
INSTALL_XRDP

RUN <<'INSTALL_XORGXRDP'
  set -eu
  curl --fail --show-error --location --retry 5 --retry-all-errors --output xorgxrdp.tar.gz https://github.com/neutrinolabs/xorgxrdp/releases/download/v0.10.4/xorgxrdp-0.10.4.tar.gz
  test "$(shasum -a 512256 xorgxrdp.tar.gz)" = "1d9981d591628c9a068f1a8b5522da04b9f59fa9c631560e6eb18c5fe8002b50  xorgxrdp.tar.gz"
  mkdir -p xorgxrdp
  cd xorgxrdp
  tar -xf ../xorgxrdp.tar.gz --strip-components=1
  ./configure --enable-glamor
  make
  make install
INSTALL_XORGXRDP

RUN <<'INSTALL_PULSEAUDIO_MODULE_XRDP'
  set -eu
  curl --fail --show-error --location --retry 5 --retry-all-errors --output pulseaudio-module-xrdp.tar.gz https://github.com/neutrinolabs/pulseaudio-module-xrdp/archive/refs/tags/v0.8.tar.gz
  test "$(shasum -a 512256 pulseaudio-module-xrdp.tar.gz)" = "416cbf772f8642876f4b175350d443f8a97770bf37cad50c65518991590f970e  pulseaudio-module-xrdp.tar.gz"
  mkdir -p pulseaudio-module-xrdp
  cd pulseaudio-module-xrdp
  tar xf ../pulseaudio-module-xrdp.tar.gz --strip-components=1
  ./scripts/install_pulseaudio_sources_apt.sh
  ./bootstrap
  ./configure "PULSE_DIR=$HOME/pulseaudio.src"
  make
  make install
  echo "autospawn=yes" > /run/pulseaudio-enable-autospawn
INSTALL_PULSEAUDIO_MODULE_XRDP

RUN <<'SETUP_USER'
  set -eu
  useradd --create-home --user-group --shell /bin/bash xyzzy
  echo "xyzzy ALL=(root) NOPASSWD:ALL" | tee /etc/sudoers.d/xyzzy
  mkdir -p /workspace
  chown xyzzy:xyzzy /workspace
  echo xyzzy:xyzzy | chpasswd
  xdg_runtime_dir="/run/user/$(id -u xyzzy)"
  mkdir -p "$xdg_runtime_dir"
  chown xyzzy:xyzzy "$xdg_runtime_dir"
  chmod 700 "$xdg_runtime_dir"
SETUP_USER

USER xyzzy
WORKDIR /home/xyzzy

RUN <<'SETUP_USER_LOCAL_ENVIRONMENT'
  set -eu

  cat <<'SHELL_PROFILE_SCRIPT' >>~/.profile
export BLENDER_VRM_LOGGING_LEVEL_DEBUG=yes
export UV_LINK_MODE=copy
# https://github.com/microsoft/vscode/blob/fb769554405bee9be16e21ceb0a496bd29126941/resources/linux/bin/code.sh#L15-L29
export DONT_PROMPT_WSL_INSTALL=true
export PATH="/usr/local/cuda/bin:$PATH"
SHELL_PROFILE_SCRIPT

  cat <<'XSESSION_SCRIPT' >~/.xsession
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
xfce4-session
XSESSION_SCRIPT

  xdg-settings set default-web-browser firefox-esr.desktop || true
  timeout --signal=HUP 2 xvfb-run -a firefox --private-window --setDefaultBrowser || true

  # https://docs.astral.sh/uv/getting-started/installation/
  curl --fail --show-error --location --retry 5 --retry-all-errors https://astral.sh/uv/install.sh | sh

  # https://github.com/Schniz/fnm/blob/v1.38.1/README.md?plain=1#L25
  curl --fail --show-error --location --retry 5 --retry-all-errors https://fnm.vercel.app/install | bash
SETUP_USER_LOCAL_ENVIRONMENT

WORKDIR /workspace

COPY --chown=xyzzy:xyzzy --chmod=755 ./entrypoint.sh /home/xyzzy/entrypoint.sh
ENTRYPOINT ["/bin/bash", "-lmic", "/home/xyzzy/entrypoint.sh 2>&1 | tee /home/xyzzy/entrypoint.log"]
