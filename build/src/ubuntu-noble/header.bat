@rem SPDX-License-Identifier: MIT
@echo off

setlocal enabledelayedexpansion
cd /d "%~dp0"

set "bat_path=%~f0"
set "bat_file_name=%~nx0"

:parse_command_line_arguments
if /i "%~1"=="/Rebuild" set sandbox_rebuild=true
if /i "%~1"=="/Restart" set sandbox_restart=true
if /i "%~1"=="/?" set sandbox_help=true
if /i "%~1"=="/help" set sandbox_help=true
shift
if not "%~1"=="" goto :parse_command_line_arguments

if "%sandbox_help%"=="true" (
  echo.
  echo.%bat_file_name% [/Rebuild] [/Restart] [/?]
  echo.
  echo./Rebuild
  echo.    Rebuild the sandbox environment.
  echo./Restart
  echo.    Restart the sandbox environment.
  echo./?
  echo.    Show this help message.
  echo.
  exit /b
)

echo.
echo //////////////////////////////////////////////////
echo.
echo               Tsuyotsuyo AI Sandbox
echo.
echo //////////////////////////////////////////////////
echo.

rem In default pwsh -> powershell or powershell -> pwsh causes module load error
set PSModulePath=

set "startup_script="
set "startup_script=%startup_script% $ErrorActionPreference = 'Stop';                                                "
set "startup_script=%startup_script%                                                                                 "
set "startup_script=%startup_script% $leafFolderName = (                                                             "
set "startup_script=%startup_script%   'ai-sandbox-' +                                                               "
set "startup_script=%startup_script%   [System.BitConverter]::ToString(                                              "
set "startup_script=%startup_script%     (New-Object System.Security.Cryptography.SHA256Managed).ComputeHash(        "
set "startup_script=%startup_script%       [System.Text.Encoding]::UTF8.GetBytes(                                    "
set "startup_script=%startup_script%         $Env::PROCESSOR_ARCHITECTURE + ';' + $Env:bat_path                      "
set "startup_script=%startup_script%       )                                                                         "
set "startup_script=%startup_script%     )                                                                           "
set "startup_script=%startup_script%   ).ToLower().Replace('-', '')                                                  "
set "startup_script=%startup_script% );                                                                              "
set "startup_script=%startup_script% $workspacePath = Join-Path ([System.IO.Path]::GetTempPath()) $leafFolderName;   "
set "startup_script=%startup_script% Write-Output ('* Workspace Path: ' + $workspacePath);                           "
set "startup_script=%startup_script% New-Item $workspacePath -ItemType Directory -Force | Out-Null;                  "
set "startup_script=%startup_script%                                                                                 "
set "startup_script=%startup_script% $batContent = Get-Content $Env:bat_path -Raw -Encoding UTF8;                    "
set "startup_script=%startup_script% $mainPs1DelimiterPattern = '^#{40} PowerShell #{40}\r\n';                       "
set "startup_script=%startup_script% $splitBatContent = $batContent -split $mainPs1DelimiterPattern,2,'Multiline';   "
set "startup_script=%startup_script% if ($splitBatContent.Length -lt 2) {                                            "
set "startup_script=%startup_script%   Write-Output (                                                                "
set "startup_script=%startup_script%     'Error: No delimiter ' + $mainPs1DelimiterPattern + ' in ' + $Env:bat_path  "
set "startup_script=%startup_script%   );                                                                            "
set "startup_script=%startup_script%   exit 1;                                                                       "
set "startup_script=%startup_script% }                                                                               "
set "startup_script=%startup_script% $mainPs1Content = $splitBatContent[1];                                          "
set "startup_script=%startup_script%                                                                                 "
set "startup_script=%startup_script% $mainPs1Path = Join-Path $workspacePath main.ps1;                               "
set "startup_script=%startup_script% Set-Content $mainPs1Path $mainPs1Content -Encoding UTF8;                        "
set "startup_script=%startup_script% Set-Location $workspacePath;                                                    "
set "startup_script=%startup_script% ( & $mainPs1Path                                                                "
set "startup_script=%startup_script%   -ExtractSources $True                                                         "
set "startup_script=%startup_script%   -Rebuild ([bool]$env:sandbox_rebuild)                                         "
set "startup_script=%startup_script%   -Restart ([bool]$env:sandbox_restart)                                         "
set "startup_script=%startup_script%   -ConfigPath ([System.IO.Path]::ChangeExtension($Env:bat_path, '.json'))       "
set "startup_script=%startup_script% );                                                                              "

where /q powershell.exe
if %errorlevel% equ 0 (
  powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -Command "%startup_script%"
  if !errorlevel! neq 0 pause
  goto :exit
)

where /q pwsh.exe
if %errorlevel% equ 0 (
  pwsh.exe -NoProfile -ExecutionPolicy RemoteSigned -Command "%startup_script%"
  if !errorlevel! neq 0 pause
  goto :exit
)

echo Error: Neither powershell.exe nor pwsh.exe was found on the system.
echo Please install PowerShell.

:exit
endlocal
exit /b
