#!/bin/bash
# SPDX-License-Identifier: MIT OR GPL-3.0-or-later

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
command=/usr/sbin/xrdp-sesman --nodaemon

[program:xrdp]
command=/usr/sbin/xrdp --nodaemon
SUPERVISORD_CONF

exec sudo /usr/bin/supervisord --nodaemon
