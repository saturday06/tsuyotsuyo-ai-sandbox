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

mstsc ai-sandbox.rdp /v:"127.0.0.1:${rdpPort}"
if ($?) {
  Write-Host "リモートデスクトップクライアントを起動しました。自動的に接続できます。"
}
else {
  Write-Warning "リモートデスクトップクライアントの起動に失敗しました。"
}

$closeTimeoutSeconds = 10
Write-Host "このコンソールプログラムは、${closeTimeoutSeconds}秒後に終了します。"
Start-Sleep -Seconds $closeTimeoutSeconds
