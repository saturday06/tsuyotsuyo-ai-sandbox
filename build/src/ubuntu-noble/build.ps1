# SPDX-License-Identifier: MIT

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true
Set-StrictMode -Version 3.0

$outputContent = Get-Content (Join-Path $PSScriptRoot "header.bat") -Raw -Encoding UTF8
$outputContent += "`n"

$outputContent += "######################################## PowerShell ########################################`n"
$outputContent += Get-Content (Join-Path $PSScriptRoot "main.ps1") -Raw -Encoding UTF8
$outputContent += "`n"

$outputContent += "<# ##################################### Dockerfile ########################################`n"
$outputContent += Get-Content (Join-Path $PSScriptRoot "Dockerfile") -Raw -Encoding UTF8
$outputContent += "######################################## Dockerfile ##################################### #>`n"
$outputContent += "`n"

$outputContent += "<# ##################################### entrypoint.sh ########################################`n"
$outputContent += Get-Content (Join-Path $PSScriptRoot "entrypoint.sh") -Raw -Encoding UTF8
$outputContent += "######################################## entrypoint.sh ##################################### #>`n"
$outputContent += "`n"

$outputContent += "<# ##################################### ai-sandbox.rdp ########################################`n"
$outputContent += Get-Content (Join-Path $PSScriptRoot "ai-sandbox.rdp") -Raw -Encoding Unicode
$outputContent += "password 51:b:### HASH ###`n"
$outputContent += "######################################## ai-sandbox.rdp ##################################### #>`n"

$outputContent = $outputContent.Replace("`r`n", "`n").Replace("`n", "`r`n")

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$outputPath = Join-Path $PSScriptRoot ".." ".." ".." "ai-sandbox.bat"
[System.IO.File]::WriteAllBytes($outputPath, $utf8NoBom.GetBytes($outputContent))
