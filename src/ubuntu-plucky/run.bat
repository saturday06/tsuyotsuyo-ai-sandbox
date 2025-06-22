@rem SPDX-License-Identifier: MIT OR GPL-3.0-or-later
@echo off
setlocal

cd /d "%~dp0"

set "usage=Usage: ubuntu-plucky\run.bat Docker-Container-and-Image-Base-Name Remote-Desktop-Server-Port"
if "%~1" == "" (
  echo %usage%
  goto error
)
if "%~2" == "" (
  echo %usage%
  goto error
)

set "name=%1"
set "port=%2"

set "arch_and_cd=%PROCESSOR_ARCHITECTURE%;%cd%"
set "publish=127.0.0.1:%port%:3389/tcp"

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
if "%arch_and_cd_hash%"=="" (
  echo Failed to generate a unique hash for the current directory and architecture.
  echo Please ensure that the current directory is valid and try again.
  goto error
)

set "tag_name=%name%-local-tag-%arch_and_cd_hash%"
set "working_tag_name=%name%-local-working-tag-%arch_and_cd_hash%"
set "container_name=%name%-local-container-%arch_and_cd_hash%"
set "busybox_container_name=%name%-busybox-container-%arch_and_cd_hash%"

rem Check if Docker is installed and running
docker --version >nul 2>&1
if errorlevel 1 (
  echo Docker is not installed.
  echo Run `docker --version` for more info.
  goto error
)
docker info >nul 2>&1
if errorlevel 1 (
  echo Docker is not running.
  echo Run `docker info` for more info.
  goto error
)

set "support_wsl_path=true"
for /f "usebackq" %%i in (
  `wsl wslpath -w /tmp/%name%`
) do set "wsl_tmp_path=%%i"
docker run --volume "%wsl_tmp_path%:/workspace" --name "%busybox_container_name%" busybox true
if errorlevel 1 (
  set "support_wsl_path=false"
  wsl docker --version >nul 2>&1
  if errorlevel 1 (
    echo Docker is not installed.
    echo Run `wsl docker --version` for more info.
    goto error
  )
  wsl docker info >nul 2>&1
  if errorlevel 1 (
    echo Docker is not running.
    echo Run `wsl docker info` for more info.
    goto error
  )
)

rem Create a working folder in the WSL home directory.
rem The reason for using WSL is that it provides better performance.
set "wsl_workspace_path=$HOME/visual-workspace/%name%"
if "%support_wsl_path%"=="true" (
  for /f "usebackq" %%i in (
    `wsl wslpath -a -w "%wsl_workspace_path%"`
  ) do set "workspace_path=%%i"
  md "%workspace_path%"
) else (
  set "workspace_path=%wsl_workspace_path%"
)
set "volume=%workspace_path%:/workspace"

docker container inspect "%container_name%"
if errorlevel 1 (
  rem If the container does not exist, build and start it.
  docker build --tag "%working_tag_name%" --progress plain .
  if errorlevel 1 (
    echo Failed to build the Docker image.
    goto error
  )

  docker image rm "%tag_name%"

  docker image tag "%working_tag_name%" "%tag_name%"
  if errorlevel 1 (
    echo Failed to tag the Docker image.
    goto error
  )

  docker image rm "%working_tag_name%"
  if errorlevel 1 (
    echo Failed to remove the working Docker image tag.
    goto error
  )

  if "%support_wsl_path%"=="true" (
    docker run --detach --publish "%publish%" --volume "%volume%" --name "%container_name%" "%tag_name%" --gpus=all ^
    || docker run --detach --publish "%publish%" --volume "%volume%" --name "%container_name%" "%tag_name%" ^
  ) else (
    wsl docker run --detach --publish "%publish%" --volume "%volume%" --name "%container_name%" "%tag_name%" --gpus=all ^
    || wsl docker run --detach --publish "%publish%" --volume "%volume%" --name "%container_name%" "%tag_name%"
  )
  if errorlevel 1 (
    echo Failed to run the Docker container.
    goto error
  )
) else (
  powershell -Command "if ((Test-NetConnection '127.0.0.1' -Port $Env:port).TcpTestSucceeded) { exit 0 } else { exit 1 }"
  if errorlevel 1 (
    rem If the container already exists but the port is not open, restart the container.
    docker stop "%container_name%"
    if errorlevel 1 (
      echo Failed to stop the Docker container.
      goto error
    )

    docker cp "%~dp0entrypoint.sh" "%container_name%:/home/xyzzy/entrypoint.sh"
    if errorlevel 1 (
      echo Failed to copy the entrypoint script to the Docker container.
      goto error
    )

    docker start "%container_name%"
    if errorlevel 1 (
      echo Failed to start the Docker container.
      goto error
    )
  )
)

rem Wait until the remote desktop is started.
set "wait_port="
set "wait_port=%wait_port% for ($i=0; $i -lt 60; $i++) {"
set "wait_port=%wait_port%   if ((Test-NetConnection '127.0.0.1' -Port $Env:port).TcpTestSucceeded) {"
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
mstsc "%~dp0default.rdp" /v:"127.0.0.1:%port%"

:error

if "%busybox_container_name%" neq "" (
  docker rm "%busybox_container_name%"
)

endlocal
exit /b
