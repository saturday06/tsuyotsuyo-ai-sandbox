# SPDX-License-Identifier: MIT

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true
Set-StrictMode -Version 3.0

Set-Location $PSScriptRoot

$outputContent = (Get-Content "header.bat" -Raw -Encoding UTF8)
$outputContent += "######################################## PowerShell ########################################`n"
$outputContent += (Get-Content "main.ps1" -Raw -Encoding UTF8)
$outputContent += "<# ##################################### Dockerfile ########################################`n"
$outputContent += (Get-Content "Dockerfile" -Raw -Encoding UTF8)
$outputContent += "######################################## Dockerfile ##################################### #>`n"
$outputContent += "<# ##################################### entrypoint.sh ########################################`n"
$outputContent += (Get-Content "entrypoint.sh" -Raw -Encoding UTF8)
$outputContent += "######################################## entrypoint.sh ##################################### #>`n"
$outputContent += "<# ##################################### ai-sandbox.rdp ########################################`n"
$outputContent += (Get-Content "ai-sandbox.rdp" -Raw -Encoding Unicode)
$outputContent += "password 51:b:### HASH ###`n"
$outputContent += "######################################## ai-sandbox.rdp ##################################### #>`n"
$outputContent = $outputContent.Replace("`r`n", "`n").Replace("`n", "`r`n")

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$outputPath = Join-Path $PSScriptRoot ".." ".." ".." "ai-sandbox.bat"
[System.IO.File]::WriteAllBytes($outputPath, $utf8NoBom.GetBytes($outputContent))
