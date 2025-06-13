#!/bin/bash
# SPDX-License-Identifier: MIT OR GPL-3.0-or-later

set -eu -o pipefail

cd "$(dirname "$0")/.."

sudo chown -R "$(id -u):$(id -g)" .
find . -type f -name "*.sh" -exec chmod +x {} +
./tools/install_hadolint.sh
