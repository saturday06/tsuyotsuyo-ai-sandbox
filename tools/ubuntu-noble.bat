@rem SPDX-License-Identifier: MIT OR GPL-3.0-or-later

@echo off
setlocal

cd /d "%~dp0"

wsl /bin/sh ./ubuntu-noble.sh

endlocal
exit /b
