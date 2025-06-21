@rem SPDX-License-Identifier: MIT OR GPL-3.0-or-later
@echo off
setlocal

cd /d "%~dp0"

set "port=13389"
set "dockerfile_path=ubuntu-noble.dockerfile"

set "arch_and_cd=%PROCESSOR_ARCHITECTURE%;%cd%"
set "publish=127.0.0.1:%port%:3389/tcp"

rem Check if Docker is installed and running
docker --version >nul 2>&1
if errorlevel 1 (
    echo Docker is not installed.
    goto error
)
docker info >nul 2>&1
if errorlevel 1 (
    echo Docker is not running.
    goto error
)

rem Generate Docker tag and container names from the current directory and architecture.
rem This is to avoid conflicts with other images and containers.
set "print_arch_and_cd_hash="
set "print_arch_and_cd_hash=%print_arch_and_cd_hash% Write-Host("
set "print_arch_and_cd_hash=%print_arch_and_cd_hash%   [System.BitConverter]::ToString("
set "print_arch_and_cd_hash=%print_arch_and_cd_hash%     (New-Object System.Security.Cryptography.SHA256Managed).ComputeHash("
set "print_arch_and_cd_hash=%print_arch_and_cd_hash%       [System.Text.Encoding]::UTF8.GetBytes($Env:arch_and_cd)"
set "print_arch_and_cd_hash=%print_arch_and_cd_hash%     )"
set "print_arch_and_cd_hash=%print_arch_and_cd_hash%   ).ToLower().Replace('-', '')"
set "print_arch_and_cd_hash=%print_arch_and_cd_hash% )"
for /f "usebackq" %%i in (
  `powershell -Command "%print_arch_and_cd_hash%"`
) do set "arch_and_cd_hash=%%i"

set "tag_name=ubuntu-noble-local-tag-%arch_and_cd_hash%"
set "container_name=ubuntu-noble-local-container-%arch_and_cd_hash%"

rem Create a working folder in the WSL home directory.
rem The reason for using WSL is that it provides better performance.
for /f "usebackq" %%i in (
  `wsl wslpath -a -w "$HOME/visual-workspace/ubuntu-noble"`
) do set "workspace_path=%%i"
md "%workspace_path%"
set "volume=%workspace_path%:/workspace"

docker container inspect "%container_name%"
if errorlevel 1 (
  rem If the container does not exist, build and start it.
  docker build --tag "%tag_name%" --file "%dockerfile_path%" --progress plain .
  docker run --detach --publish "%publish%" --volume "%volume%" --name "%container_name%" "%tag_name%" --gpus=all ^
  || docker run --detach --publish "%publish%" --volume "%volume%" --name "%container_name%" "%tag_name%"
) else (
  rem If the container already exists, restart the container and update the entrypoint script.
  docker stop "%container_name%"
  docker cp "%~dp0ubuntu-noble-entrypoint.sh" "%container_name%:/home/xyzzy/entrypoint.sh"
  docker start "%container_name%"
)

rem Wait until the remote desktop is started.
set "wait_port="
set "wait_port=%wait_port% for ($i=0; $i -lt 60; $i++) {"
set "wait_port=%wait_port%   if ((Test-NetConnection -ComputerName '127.0.0.1' -Port $Env:port).TcpTestSucceeded) {"
set "wait_port=%wait_port%     exit 0"
set "wait_port=%wait_port%   }"
set "wait_port=%wait_port%   Start-Sleep -Seconds 1"
set "wait_port=%wait_port% }"
powershell -Command "%wait_port%"
if errorlevel 1 (
  echo Failed to connect to the container on port "%port%"
  goto error
)

echo Remote desktop service has started in the Docker container. You can connect at "127.0.0.1:%port%".

:error
endlocal
exit /b
