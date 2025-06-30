@rem SPDX-License-Identifier: MIT
@echo off

setlocal enabledelayedexpansion
cd /d "%~dp0"

echo.
echo //////////////////////////////////////////////////
echo.
echo                     AI Sandbox
echo.
echo //////////////////////////////////////////////////
echo.

set "arch_and_cd=%PROCESSOR_ARCHITECTURE%;%cd%"
set "bat_path=%~f0"

set PSModulePath=

set "startup_script="
set "startup_script=%startup_script% $ErrorActionPreference = 'Stop'; "
set "startup_script=%startup_script% $workspacePath = (Join-Path "
set "startup_script=%startup_script%   ([System.IO.Path]::GetTempPath()) "
set "startup_script=%startup_script%   ( "
set "startup_script=%startup_script%     'ai-sandbox-' + [System.BitConverter]::ToString( "
set "startup_script=%startup_script%       (New-Object System.Security.Cryptography.SHA256Managed).ComputeHash( "
set "startup_script=%startup_script%         [System.Text.Encoding]::UTF8.GetBytes($Env:arch_and_cd) "
set "startup_script=%startup_script%       ) "
set "startup_script=%startup_script%     ).ToLower().Replace('-', '') "
set "startup_script=%startup_script%   ) "
set "startup_script=%startup_script% ); "
set "startup_script=%startup_script% Write-Host * Workspace Path: $workspacePath; "
set "startup_script=%startup_script% New-Item $workspacePath -ItemType Directory -Force | Out-Null; "
set "startup_script=%startup_script% Set-Location $workspacePath; "
set "startup_script=%startup_script% $mainPs1Path = (Join-Path $workspacePath main.ps1); "
set "startup_script=%startup_script% $batContent = Get-Content $Env:bat_path -Raw -Encoding UTF8; "
set "startup_script=%startup_script% $mainPs1DelimiterPattern = '^#{40} PowerShell #{40}\r\n'; "
set "startup_script=%startup_script% $splitBatContent = $batContent -split $mainPs1DelimiterPattern,2,'Multiline'; "
set "startup_script=%startup_script% if ($splitBatContent.Length -lt 2) { "
set "startup_script=%startup_script%   Write-Host ('Error: No delimiter ' + $mainPs1DelimiterPattern + ' in ' + $Env:bat_path); "
set "startup_script=%startup_script%   exit 1; "
set "startup_script=%startup_script% } "
set "startup_script=%startup_script% $mainPs1Content = $splitBatContent[1]; "
set "startup_script=%startup_script% Set-Content $mainPs1Path $mainPs1Content -Encoding UTF8; "
set "startup_script=%startup_script% & $mainPs1Path -Release $True; "

where /q powershell.exe
if %errorlevel% equ 0 (
  powershell.exe -NoProfile -Command "%startup_script%"
  if !errorlevel! neq 0 pause
  goto :exit
)

where /q pwsh.exe
if %errorlevel% equ 0 (
  pwsh.exe -NoProfile -Command "%startup_script%"
  if !errorlevel! neq 0 pause
  goto :exit
)

echo Error: Neither powershell.exe nor pwsh.exe was found on the system.
echo Please install PowerShell.

:exit
endlocal
exit /b
######################################## PowerShell ########################################
#!/usr/bin/env pwsh
# SPDX-License-Identifier: MIT

# このファイルは、PowerShell 2.0系でも動作するように記述する。

Param([bool]$Release = $false)

$ErrorActionPreference = "Stop"

$baseName = "ubuntu-noble"
$rdpPort = 13389

$directoryName = (Split-Path -Path $PSScriptRoot -Leaf)

$tagName = "${baseName}-${directoryName}-local-tag"
$workingTagName = "${baseName}-${directoryName}-local-working-tag"
$containerName = "${baseName}-${directoryName}-local-container"
$dockerfilePath = Join-Path $PSScriptRoot "Dockerfile"
$entrypointShPath = Join-Path $PSScriptRoot "entrypoint.sh"
$aiSandboxRdpPath = Join-Path $PSScriptRoot "ai-sandbox.rdp"

Write-Host "* Docker Image Tag Name: ${tagName}"
Write-Host "* Docker Container Name: ${containerName}"
Write-Host "* Dockerfile Path: ${dockerfilePath}"
Write-Host "* Dockerfile Entrypoint Path: ${entrypointShPath}"
Write-Host "* RDP Configuration Path: ${aiSandboxRdpPath}"

if ($Release) {
  $scriptPath = $MyInvocation.MyCommand.Path
  $utf8NoBom = New-Object System.Text.UTF8Encoding $false
  $dockerfileMatch = [regex]::Match(
    (Get-Content $scriptPath -Raw -Encoding UTF8),
    "(?s)<# #{37} Dockerfile #{40}\r\n(.+?)#{40} Dockerfile #{37} #>"
  )
  if (-not $dockerfileMatch.Success) {
    Write-Error "Dockerfileの抽出に失敗しました。"
  }
  $dockerfileContent = $dockerfileMatch.Groups[1].Value.Replace("`r`n", "`n")
  [System.IO.File]::WriteAllBytes($dockerfilePath, $utf8NoBom.GetBytes($dockerfileContent))

  $entrypointShMatch = [regex]::Match(
    (Get-Content $scriptPath -Raw -Encoding UTF8),
    "(?s)<# #{37} entrypoint\.sh #{40}\r\n(.+)#{40} entrypoint\.sh #{37} #>"
  )
  if (-not $entrypointShMatch.Success) {
    Write-Error "entrypoint.shの抽出に失敗しました。"
  }
  $entrypointShContent = $entrypointShMatch.Groups[1].Value.Replace("`r`n", "`n")
  [System.IO.File]::WriteAllBytes($entrypointShPath, $utf8NoBom.GetBytes($entrypointShContent))

  $aiSandboxRdpMatch = [regex]::Match(
    (Get-Content $scriptPath -Raw -Encoding UTF8),
    "(?s)<# #{37} ai-sandbox\.rdp #{40}\r\n(.+)#{40} ai-sandbox\.rdp #{37} #>"
  )
  if (-not $entrypointShMatch.Success) {
    Write-Error "ai-sandbox.rdpの抽出に失敗しました。"
  }
  $aiSandboxRdpContent = $aiSandboxRdpMatch.Groups[1].Value.Replace(
    "### HASH ###",
    (ConvertTo-SecureString "xyzzy" -AsPlainText -Force | ConvertFrom-SecureString)
  )
  Set-Content $aiSandboxRdpPath $aiSandboxRdpContent -Encoding Unicode
}

if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
  Write-Host "*** dockerコマンドが見つかりませんでした。dockerをインストールしてください。 ***"
  exit 1
}

docker info | Out-Null
if (-not $?) {
  Write-Host "*** ""docker info"" コマンドの実行に失敗しました。dockerが正常動作しているかを確認してください。 ***"
  exit 1
}

docker container inspect $containerName | Out-Null
if (-not $?) {
  docker build --tag $workingTagName --progress plain .
  if (-not $?) {
    Write-Error """docker build --tag $workingTagName --progress plain ."" コマンドの実行に失敗しました"
  }
  docker image rm $tagName
  docker image tag $workingTagName $tagName
  if (-not $?) {
    Write-Error """docker image tag $workingTagName $tagName"" コマンドの実行に失敗しました"
  }
  docker image rm $workingTagName
  if (-not $?) {
    Write-Error """docker image rm $workingTagName"" コマンドの実行に失敗しました"
  }
  docker run --gpus=all ubuntu:noble true
  if ($?) {
    docker run --detach --publish "127.0.0.1:${rdpPort}:3389/tcp" --name $containerName --gpus=all $tagName
  }
  else {
    docker run --detach --publish "127.0.0.1:${rdpPort}:3389/tcp" --name $containerName $tagName
  }
}
else {
  docker cp "entrypoint.sh" "${containerName}:/home/xyzzy/entrypoint.sh"
  if (-not (Test-NetConnection "127.0.0.1" -Port $rdpPort).TcpTestSucceeded) {
    docker stop $containerName
    if (-not $?) {
      Write-Error """docker stop $containerName"" コマンドの実行に失敗しました"
    }
    docker start $containerName
    if (-not $?) {
      Write-Error """docker start $containerName"" コマンドの実行に失敗しました"
    }
  }
}

$rdpReady = $false
for ($i = 0; $i -lt 10; $i++) {
  if ((Test-NetConnection "127.0.0.1" -Port $rdpPort).TcpTestSucceeded) {
    $rdpReady = $true
    break
  }
  Start-Sleep -Seconds 1
}
if (-not $rdpReady) {
  Write-Error """127.0.0.1:${rdpPort}""に接続できませんでした。"
}

Write-Host
Write-Host "/////////////////////////////////////////////////////////////////"
Write-Host "Dockerコンテナ上でリモートデスクトップサービスが開始されました。"
Write-Host "手動で接続する場合はRDPクライアントに次の情報を入力してください。"
Write-Host "- コンピューター: 127.0.0.1:${rdpPort}"
Write-Host "- ユーザー名: xyzzy"
Write-Host "- パスワード: xyzzy"
Write-Host "/////////////////////////////////////////////////////////////////"
Write-Host

mstsc sandbox.rdp /v:"127.0.0.1:${rdpPort}"
if ($?) {
  Write-Host "リモートデスクトップクライアントを起動しました。自動的に接続できます。"
}
else {
  Write-Warning "リモートデスクトップクライアントの起動に失敗しました。"
}

$closeTimeoutSeconds = 10
Write-Host "このコンソールプログラムは、${closeTimeoutSeconds}秒後に終了します。"
Start-Sleep -Seconds $closeTimeoutSeconds
<# ##################################### Dockerfile ########################################
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
######################################## Dockerfile ##################################### #>
<# ##################################### entrypoint.sh ########################################
#!/bin/bash
# SPDX-License-Identifier: MIT

set -emux -o pipefail

cd "$(dirname "$0")"

for p in dbus-daemon Xvfb gnome-remote-desktop-daemon supervisord gnome-shell gnome-session xrdp xrdp-sesman; do
  if pgrep "$p" >/dev/null; then
    echo "Killing existing $p processes..."
    sudo pkill "$p" || true
  fi
done

sudo tee /etc/supervisor/conf.d/default.conf <<SUPERVISORD_CONF >/dev/null
[program:dbus-daemon]
command=/usr/bin/dbus-daemon --system --nofork --nopidfile

[program:xrdp-sesman]
command=/usr/local/sbin/xrdp-sesman --nodaemon

[program:xrdp]
command=/usr/local/sbin/xrdp --nodaemon
SUPERVISORD_CONF

exec sudo /usr/bin/supervisord --nodaemon
######################################## entrypoint.sh ##################################### #>
<# ##################################### ai-sandbox.rdp ########################################
screen mode id:i:1
use multimon:i:0
desktopwidth:i:1920
desktopheight:i:1080
session bpp:i:32
winposstr:s:0,1,632,309,3427,1924
compression:i:1
keyboardhook:i:2
audiocapturemode:i:1
videoplaybackmode:i:1
connection type:i:6
networkautodetect:i:0
bandwidthautodetect:i:1
displayconnectionbar:i:1
enableworkspacereconnect:i:0
disable wallpaper:i:1
allow font smoothing:i:0
allow desktop composition:i:0
disable full window drag:i:1
disable menu anims:i:1
disable themes:i:1
disable cursor setting:i:0
bitmapcachepersistenable:i:1
full address:s:127.0.0.1:13389
audiomode:i:0
redirectprinters:i:0
redirectlocation:i:0
redirectcomports:i:0
redirectsmartcards:i:0
redirectclipboard:i:1
redirectposdevices:i:0
autoreconnection enabled:i:1
authentication level:i:0
prompt for credentials:i:0
negotiate security layer:i:1
remoteapplicationmode:i:0
alternate shell:s:
shell working directory:s:
gatewayhostname:s:
gatewayusagemethod:i:4
gatewaycredentialssource:i:4
gatewayprofileusagemethod:i:1
promptcredentialonce:i:0
gatewaybrokeringtype:i:0
use redirection server name:i:0
rdgiskdcproxy:i:0
kdcproxyname:s:
remoteappmousemoveinject:i:1
redirectwebauthn:i:0
enablerdsaadauth:i:0
drivestoredirect:s:
username:s:xyzzy
password 51:b:### HASH ###
######################################## ai-sandbox.rdp ##################################### #>
