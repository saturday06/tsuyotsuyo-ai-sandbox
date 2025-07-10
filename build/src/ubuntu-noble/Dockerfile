# SPDX-License-Identifier: MIT
#
# サーバーとして動作するわけではないのでHEALTHCHECKは不要
# checkov:skip=CKV_DOCKER_2: "Ensure that HEALTHCHECK instructions have been added to container images"

FROM ubuntu:noble
ARG hidpi_scale_factor=1
ARG user_name=developer

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
  apt-get update
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
    "bc=*" \
    "blender=*" \
    "build-essential=*" \
    "check=*" \
    "cmake=*" \
    "curl=*" \
    "dbus-x11=*" \
    "dbus=*" \
    "dconf-editor=*" \
    "desktop-file-utils=*" \
    "diffutils=*" \
    "dolphin-plugins=*" \
    "dotnet-sdk-8.0=*" \
    "emacs=*" \
    "ffmpeg=*" \
    "ffmpegthumbs=*" \
    "file=*" \
    "fonts-dejavu-core=*" \
    "fonts-liberation=*" \
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
    "fonts-ubuntu=*" \
    "git-lfs=*" \
    "git=*" \
    "gnupg=*" \
    "gwenview=*" \
    "ibus-gtk=*" \
    "ibus-gtk3=*" \
    "ibus-gtk4=*" \
    "ibus-mozc=*" \
    "ibus=*" \
    "im-config=*" \
    "imagemagick=*" \
    "iproute2=*" \
    "jq=*" \
    "kde-plasma-desktop=*" \
    "kio-extras=*" \
    "kwin-x11=*" \
    "language-pack-ja=*" \
    "less=*" \
    "libavcodec-dev=*" \
    "libavformat-dev=*" \
    "libcanberra-pulse=*" \
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
    "libtesseract-dev=*" \
    "libx11-dev=*" \
    "libx264-dev=*" \
    "libxfixes-dev=*" \
    "libxi6=*" \
    "libxkbcommon0=*" \
    "libxrandr-dev=*" \
    "libxrandr-dev=*" \
    "lsof=*" \
    "mesa-utils=*" \
    "moreutils=*" \
    "mozc-utils-gui=*" \
    "nasm=*" \
    "net-tools=*" \
    "netcat-openbsd=*" \
    "nkf=*" \
    "openssh-client=*" \
    "paprefs=*" \
    "patchutils=*" \
    "pavucontrol=*" \
    "plasma-pa=*" \
    "plasma-systemmonitor=*" \
    "procps=*" \
    "pulseaudio-utils=*" \
    "pulseaudio=*" \
    "qml-module-qt-labs-platform=*" \
    "recordmydesktop=*" \
    "ruby=*" \
    "shellcheck=*" \
    "shfmt=*" \
    "speech-dispatcher=*" \
    "sudo=*" \
    "supervisor=*" \
    "systemsettings=*" \
    "tesseract-ocr=*" \
    "tofrodos=*" \
    "unzip=*" \
    "upower=*" \
    "vim=*" \
    "wget=*" \
    "winpr-utils=*" \
    "x11-utils=*" \
    "x11-xserver-utils=*" \
    "xdotool=*" \
    "xorg=*" \
    "xserver-xorg-dev=*" \
    "xserver-xorg-input-all=*" \
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
  curl --fail --show-error --location --retry 5 --retry-all-errors --output xrdp.tar.gz https://github.com/neutrinolabs/xrdp/releases/download/v0.10.4.1/xrdp-0.10.4.1.tar.gz
  test "$(shasum -a 512256 xrdp.tar.gz)" = "bd3bb42081cbc05dfc85045f4422627d4e1464654bac26e126f4bf1959f7bd05  xrdp.tar.gz"
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
  echo '(ibus version && ibus restart) || true' >>/etc/xrdp/reconnectwm.sh
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

RUN <<'SETUP_SYSTEM_LOCALE'
  set -eu
  locale-gen "ja_JP.UTF-8"
  cat <<'DEFAULT_LOCALE' >/etc/default/locale
LANG=ja_JP.UTF-8
LANGUAGE=ja_JP:ja
LC_ALL=ja_JP.UTF-8
DEFAULT_LOCALE
SETUP_SYSTEM_LOCALE

RUN <<'SETUP_USER'
  set -eu
  userdel -r ubuntu
  useradd --create-home --user-group --shell /bin/bash "$user_name"
  echo "${user_name} ALL=(root) NOPASSWD:ALL" | tee "/etc/sudoers.d/${user_name}"
  mkdir -p /workspace
  echo "${user_name}:$(openssl rand -hex 255)" | chpasswd
  xdg_runtime_dir="/run/user/$(id -u "$user_name")"
  mkdir -p "$xdg_runtime_dir"
  chown "${user_name}:${user_name}" "$xdg_runtime_dir"
  chmod 700 "$xdg_runtime_dir"
SETUP_USER

USER "$user_name"
WORKDIR "/home/${user_name}"

RUN <<'SETUP_USER_LOCAL_ENVIRONMENT'
  set -eu

  mkdir -p ~/.local/share/applications

  cp /usr/share/applications/code.desktop ~/.local/share/applications/code-no-sandbox.desktop
  desktop-file-edit \
    --set-name="Visual Studio Code (No Sandbox)" \
    ~/.local/share/applications/code-no-sandbox.desktop
  desktop-file-edit \
    --set-key=Exec \
    --set-value="/usr/share/code/code --no-sandbox --disable-gpu --disable-dev-shm-usage %F" \
    ~/.local/share/applications/code-no-sandbox.desktop

  cp /usr/share/applications/google-chrome.desktop ~/.local/share/applications/google-chrome-no-sandbox.desktop
  desktop-file-edit \
    --set-name="Google Chrome (No Sandbox)" \
    ~/.local/share/applications/google-chrome-no-sandbox.desktop
  desktop-file-edit \
    --set-key=Exec \
    --set-value="/usr/bin/google-chrome-stable --no-sandbox --disable-gpu --disable-dev-shm-usage %U" \
    ~/.local/share/applications/google-chrome-no-sandbox.desktop

  cat <<'SHELL_PROFILE_SCRIPT' >>~/.profile
export BLENDER_VRM_LOGGING_LEVEL_DEBUG=yes
export UV_LINK_MODE=copy
# https://github.com/microsoft/vscode/blob/fb769554405bee9be16e21ceb0a496bd29126941/resources/linux/bin/code.sh#L15-L29
export DONT_PROMPT_WSL_INSTALL=true
export PATH="/usr/local/cuda/bin:$PATH"
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
SHELL_PROFILE_SCRIPT

  mkdir -p ~/.config/mozc/
  cat <<'MOZC_IBUS_CONFIG' >~/.config/mozc/ibus_config.textproto
engines {
  name : "mozc-jp"
  longname : "Mozc"
  layout : "default"
  layout_variant : ""
  layout_option : ""
  rank : 80
}
active_on_launch: True
MOZC_IBUS_CONFIG

  cat <<'PLASMASHELLRC' >~/.config/plasmashellrc
[PlasmaViews][Panel 2][Defaults]
thickness=48
PLASMASHELLRC

  cat <<'KACTIVITYMANAGERDRC' >~/.config/kactivitymanagerdrc
[activities]
208ca9a2-ff65-4693-8513-d7405b026eb2=Default

[main]
currentActivity=208ca9a2-ff65-4693-8513-d7405b026eb2
KACTIVITYMANAGERDRC

  cat <<'PLASMA_ORG_KDE_PLASMA_DESKTOP_APPLETSRC' >~/.config/plasma-org.kde.plasma.desktop-appletsrc
[ActionPlugins][0]
RightButton;NoModifier=org.kde.contextmenu
wheel:Vertical;NoModifier=org.kde.switchdesktop

[ActionPlugins][1]
RightButton;NoModifier=org.kde.contextmenu

[Containments][1]
ItemGeometries-1800x960=
ItemGeometriesHorizontal=
activityId=208ca9a2-ff65-4693-8513-d7405b026eb2
formfactor=0
immutability=1
lastScreen=0
location=0
plugin=org.kde.plasma.folder
wallpaperplugin=org.kde.image

[Containments][2]
activityId=
formfactor=2
immutability=1
lastScreen=0
location=4
plugin=org.kde.panel
wallpaperplugin=org.kde.image

[Containments][2][Applets][16]
immutability=1
plugin=org.kde.plasma.showdesktop

[Containments][2][Applets][3]
immutability=1
plugin=org.kde.plasma.kickoff

[Containments][2][Applets][3][Configuration]
PreloadWeight=100
popupHeight=514
popupWidth=641

[Containments][2][Applets][3][Configuration][General]
favoritesPortedToKAstats=true

[Containments][2][Applets][3][Configuration][Shortcuts]
global=Alt+F1

[Containments][2][Applets][3][Shortcuts]
global=Alt+F1

[Containments][2][Applets][4]
immutability=1
plugin=org.kde.plasma.pager

[Containments][2][Applets][5]
immutability=1
plugin=org.kde.plasma.icontasks

[Containments][2][Applets][5][Configuration][General]
launchers=preferred://filemanager,applications:firefox-esr.desktop,applications:code-no-sandbox.desktop,applications:org.kde.konsole.desktop

[Containments][2][Applets][6]
immutability=1
plugin=org.kde.plasma.marginsseparator

[Containments][2][Applets][7]
immutability=1
plugin=org.kde.plasma.kimpanel

[Containments][2][Applets][8]
immutability=1
plugin=org.kde.plasma.systemtray

[Containments][2][Applets][8][Configuration]
PreloadWeight=55
SystrayContainmentId=9

[Containments][2][ConfigDialog]
DialogHeight=84
DialogWidth=1800

[Containments][2][General]
AppletOrder=3;4;5;6;7;8;16

[Containments][9]
activityId=
formfactor=2
immutability=1
lastScreen=0
location=4
plugin=org.kde.plasma.private.systemtray
wallpaperplugin=org.kde.image

[Containments][9][Applets][10]
immutability=1
plugin=org.kde.plasma.manage-inputmethod

[Containments][9][Applets][11]
immutability=1
plugin=org.kde.plasma.keyboardlayout

[Containments][9][Applets][12]
immutability=1
plugin=org.kde.plasma.clipboard

[Containments][9][Applets][13]
immutability=1
plugin=org.kde.plasma.notifications

[Containments][9][Applets][14]
immutability=1
plugin=org.kde.plasma.devicenotifier

[Containments][9][General]
extraItems=org.kde.plasma.battery,org.kde.plasma.manage-inputmethod,org.kde.plasma.keyboardlayout,org.kde.plasma.mediacontroller,org.kde.plasma.clipboard,org.kde.plasma.notifications,org.kde.plasma.devicenotifier
knownItems=org.kde.plasma.battery,org.kde.plasma.manage-inputmethod,org.kde.plasma.keyboardlayout,org.kde.plasma.mediacontroller,org.kde.plasma.clipboard,org.kde.plasma.notifications,org.kde.plasma.devicenotifier

[ScreenMapping]
itemsOnDisabledScreens=
screenMapping=
PLASMA_ORG_KDE_PLASMA_DESKTOP_APPLETSRC

  kcm_force_font_dpi=$(perl -MPOSIX=floor -le 'print floor(96 * sqrt(shift))' "$hidpi_scale_factor")
  kwriteconfig5 --file ~/.config/kcmfonts --group General --key forceFontDPI "$kcm_force_font_dpi"
  kwriteconfig5 --file ~/.config/kscreenlockerrc --group Daemon --key Autolock false
  kwriteconfig5 --file ~/.config/kscreenlockerrc --group Daemon --key LockAfterIdle false
  kwriteconfig5 --file ~/.config/kscreenlockerrc --group Daemon --key LockOnResume false
  kwriteconfig5 --file ~/.config/kscreenlockerrc --group Daemon --key Timeout 0
  kwriteconfig5 --file ~/.config/ksplashrc --group KSplash --key Theme None
  kwriteconfig5 --file ~/.config/ksplashrc --group KSplash --key Engine none
  kwriteconfig5 --file ~/.config/kuriikwsfilterrc --group General --key DefaultWebShortcut google
  kwriteconfig5 --file ~/.config/kglobalshortcutsrc --group kwin --key "Walk Through Windows of Current Application" 'none,alt+`,Walk Through Windows of Current Application'
  kwriteconfig5 --file ~/.config/kwalletrc --group "Wallet" --key "Enabled" "false"

  xvfb-run --auto-servernum gsettings set org.freedesktop.ibus.general preload-engines "['mozc-jp', 'xkb:us::eng']"
  xvfb-run --auto-servernum gsettings set org.freedesktop.ibus.general.hotkey triggers "['<Super>space', '<Alt>grave', '<Alt>Kanji', '<Alt>Zenkaku_Hankaku']"
  xvfb-run --auto-servernum gsettings set org.freedesktop.ibus.general use-system-keyboard-layout false
  xvfb-run --auto-servernum gsettings set org.gnome.desktop.interface text-scaling-factor "$hidpi_scale_factor"

  xdg-settings set default-web-browser firefox-esr.desktop || true
  timeout --signal=HUP 2 xvfb-run --auto-servernum firefox --private-window --setDefaultBrowser || true

  # https://docs.astral.sh/uv/getting-started/installation/
  curl --fail --show-error --location --retry 5 --retry-all-errors https://astral.sh/uv/install.sh | sh

  # https://github.com/Schniz/fnm/blob/v1.38.1/README.md?plain=1#L25
  curl --fail --show-error --location --retry 5 --retry-all-errors https://fnm.vercel.app/install | bash
SETUP_USER_LOCAL_ENVIRONMENT

USER root
WORKDIR /root
COPY --chown=root:root --chmod=755 ./entrypoint.sh /root/entrypoint.sh
ENTRYPOINT ["/bin/bash", "-lmic", "/root/entrypoint.sh 2>&1 | tee /root/entrypoint.log"]
