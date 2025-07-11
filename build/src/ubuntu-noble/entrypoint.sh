#!/bin/bash
# SPDX-License-Identifier: MIT

set -emux -o pipefail

cd "$(dirname "$0")"

for p in dbus-daemon Xvfb gnome-remote-desktop-daemon supervisord gnome-shell gnome-session xrdp xrdp-sesman plasma_session; do
  if pgrep "$p" >/dev/null; then
    echo "Killing existing $p processes..."
    pkill "$p" || true
  fi
done

tee /etc/supervisor/conf.d/default.conf <<SUPERVISORD_CONF >/dev/null
[program:dbus-daemon]
command=/usr/bin/dbus-daemon --system --nofork --nopidfile

[program:xrdp-sesman]
command=/usr/local/sbin/xrdp-sesman --nodaemon

[program:xrdp]
command=/usr/local/sbin/xrdp --nodaemon
SUPERVISORD_CONF

exec /usr/bin/supervisord --nodaemon
