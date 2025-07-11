# SPDX-License-Identifier: MIT

# このファイルは、PowerShell 2.0系でも動作するように記述する。

param(
  [bool]$Release = $False,
  [bool]$Rebuild = $False,
  [string]$ConfigPath = (Join-Path $PSScriptRoot ai-sandbox.json)
)

$ErrorActionPreference = "Stop"

Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;

    namespace TsuyotsuyoAiSandbox
    {
        public static class ShcoreDll
        {
            [DllImport("Shcore.dll")]
            public static extern int GetScaleFactorForMonitor(IntPtr hMon, out uint pScale);
        }

        public static class User32Dll
        {
            [DllImport("User32.dll")]
            public static extern IntPtr MonitorFromWindow(IntPtr hWnd, uint dwFlags);
        }
    }
"@

function Get-DeterministicRandom {
  param(
    [string]$SeedString,
    [int]$MinValue,
    [int]$MaxValue
  )

  if ($MinValue -gt $MaxValue) {
    throw "MinValue cannot be greater than MaxValue."
  }
  if ($MinValue -eq $MaxValue) {
    return $MinValue
  }

  # シードから乱数生成器の初期状態を決定
  $sha256 = [System.Security.Cryptography.SHA256]::Create()
  $hashBytes = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($SeedString))
  $sha256.Dispose()

  # ハッシュ値の最初の32バイトから4つのulongを抽出 (XorShift256+の内部状態)
  # SHA256は32バイト出力するので、そのまま4つのulongに変換できる
  $s0 = [System.BitConverter]::ToUInt64($hashBytes, 0)
  $s1 = [System.BitConverter]::ToUInt64($hashBytes, 8)
  $s2 = [System.BitConverter]::ToUInt64($hashBytes, 16)
  $s3 = [System.BitConverter]::ToUInt64($hashBytes, 24)

  # すべての状態変数が0になるのを避ける (ハッシュを使っているため極めて稀だが念のため)
  if ($s0 -eq 0 -and $s1 -eq 0 -and $s2 -eq 0 -and $s3 -eq 0) {
    $s0 = 1 # どれか1つは0以外にする
  }

  # XorShift256+アルゴリズムを複数回ループして状態を更新
  for ($i = 0; $i -lt 100; $i++) {
    $t = $s1 -shl 17 # a
    $s2 = $s2 -bxor $s0
    $s3 = $s3 -bxor $s1
    $s1 = $s1 -bxor $s2
    $s0 = $s0 -bxor $s3
    $s2 = $s2 -bxor $t
    $s3 = ($s3 -shl 45) -bor ($s3 -shr (64 - 45)) # rotl(45)
  }
  $generatedValue = $s0

  # 範囲に変換
  $range = [uint64]($MaxValue - $MinValue)
  return $MinValue + [int]($generatedValue % $range)
}

function Get-HidpiScaleFactor {
  param()

  $hidpiScaleFactorPercentage = 100
  try {
    $monitorHandle = [TsuyotsuyoAiSandbox.User32Dll]::MonitorFromWindow([IntPtr]::Zero, 1)
    [void][TsuyotsuyoAiSandbox.ShcoreDll]::GetScaleFactorForMonitor(
      $monitorHandle,
      [ref]$hidpiScaleFactorPercentage
    )
  }
  catch [System.DllNotFoundException] {
  }
  $hidpiScaleFactor = $hidpiScaleFactorPercentage / 100.0
  return $hidpiScaleFactor
}

function New-Password {
  $lowercase = 'abcdefghijklmnopqrstuvwxyz'.ToCharArray()
  $uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.ToCharArray()
  $numbers = '0123456789'.ToCharArray()
  $symbols = '!@#$%^&*()-_=+[]{}|;:,.<>?'.ToCharArray()

  # 各文字種から1文字ずつランダムに選択
  $passwordChars = @()
  $passwordChars += $lowercase | Get-Random -Count 1
  $passwordChars += $uppercase | Get-Random -Count 1
  $passwordChars += $numbers | Get-Random -Count 1
  $passwordChars += $symbols | Get-Random -Count 1

  # 全ての文字種からランダムに選択
  $allChars = $lowercase + $uppercase + $numbers + $symbols
  for ($i = 1; $i -le 60; $i++) {
    $passwordChars += ($allChars | Get-Random -Count 1)
  }

  # シャッフルして最終パスワードを生成
  $password = ($passwordChars | Sort-Object { Get-Random }) -join ''
  return $password
}

function Start-AiSandbox {
  param(
    [bool]$Release,
    [bool]$Rebuild,
    [string]$ConfigPath
  )

  $userName = "developer"
  $baseName = "ubuntu-noble"
  $hostName = "ai-sandbox"
  $directoryName = (Split-Path -Path $PSScriptRoot -Leaf)
  $scriptPath = $script:MyInvocation.MyCommand.Path

  $config = @{}
  if (Test-Path $ConfigPath) {
    foreach ($property in (Get-Content $ConfigPath | ConvertFrom-Json).PSObject.Properties) {
      $config[$property.Name] = $property.Value
    }
  }

  $tagAndContainerNamePattern = "^[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])?$"

  $configUpdated = $False
  $tagName = $config["tag_name"]
  if (-not ($tagName -is [string] -and ($tagName -match $tagAndContainerNamePattern))) {
    $tagName = "${baseName}-${directoryName}-tag"
    $config["tag_name"] = $tagName
    $configUpdated = $True
  }

  $containerName = $config["container_name"]
  if (-not ($containerName -is [string] -and $containerName -match $tagAndContainerNamePattern)) {
    $containerName = "${baseName}-${directoryName}-container"
    $config["container_name"] = $containerName
    $configUpdated = $True
  }

  $rdpPort = $config["rdp_port"] -as [int]
  if (-not($rdpPort -ne $null -and 0 -lt $rdpPort -and $rdpPort -lt 65536)) {
    $rdpPort = Get-DeterministicRandom -SeedString $scriptPath -MinValue 49152 -MaxValue 59312 # Rancher Desktop doesn't support `port >= 59312`.
    $config["rdp_port"] = $rdpPort
    $configUpdated = $True
  }

  $rdpWidth = $config["rdp_width"] -as [int]
  if (-not($rdpWidth -ne $null -and 0 -lt $rdpWidth -and $rdpWidth -lt 65536)) {
    $rdpWidth = 1800
    $config["rdp_width"] = $rdpWidth
    $configUpdated = $True
  }

  $rdpHeight = $config["rdp_height"] -as [int]
  if (-not($rdpHeight -ne $null -and 0 -lt $rdpHeight -and $rdpHeight -lt 65536)) {
    $rdpHeight = 960
    $config["rdp_height"] = $rdpHeight
    $configUpdated = $True
  }

  if ($configUpdated) {
    Set-Content $ConfigPath (ConvertTo-Json $config)
  }

  $workingTagName = "${baseName}-${directoryName}-working-tag"
  $dockerfilePath = Join-Path $PSScriptRoot "Dockerfile"
  $entrypointShPath = Join-Path $PSScriptRoot "entrypoint.sh"

  if ($Release) {
    # RDPクライアントのタイトルに設定ファイル名を表示する
    $aiSandboxRdpPath = Join-Path $PSScriptRoot ([System.IO.Path]::GetFileNameWithoutExtension($ConfigPath) + ".rdp")
  }
  else {
    $aiSandboxRdpPath = Join-Path $PSScriptRoot "ai-sandbox-dev.rdp"
  }

  Write-Output "* Config Path: ${ConfigPath}"
  Write-Output "* Docker Image Tag Name: ${tagName}"
  Write-Output "* Docker Container Name: ${containerName}"
  Write-Output "* Dockerfile Path: ${dockerfilePath}"
  Write-Output "* Dockerfile Entrypoint Path: ${entrypointShPath}"
  Write-Output "* Script Path: ${scriptPath}"
  Write-Output "* RDP Configuration Path: ${aiSandboxRdpPath}"
  Write-Output "* RDP Port Number: ${rdpPort}"

  $rdpPassword = New-Password

  if ($Release) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding $False
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
      Write-Error "RDP接続設定ファイルの抽出に失敗しました。"
    }
    $aiSandboxRdpContent = $aiSandboxRdpMatch.Groups[1].Value
  }
  else {
    $aiSandboxRdpContent = Get-Content (Join-Path $PSScriptRoot "ai-sandbox.rdp") -Encoding Unicode
  }
  $aiSandboxRdpContent += "username:s:${userName}`n"
  $aiSandboxRdpContent += "password 51:b:" + (ConvertTo-SecureString $rdpPassword -AsPlainText -Force | ConvertFrom-SecureString)
  Set-Content $aiSandboxRdpPath $aiSandboxRdpContent -Encoding Unicode

  if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
    Write-Output "*** dockerコマンドが見つかりませんでした。dockerをインストールしてください。 ***"
    exit 1
  }

  docker info | Out-Null
  if (-not $?) {
    Write-Output "*** ""docker info"" コマンドの実行に失敗しました。dockerが正常動作しているかを確認してください。 ***"
    exit 1
  }

  if ($Rebuild) {
    docker container rm -f $containerName
    docker image rm -f $tagName
    docker image rm -f $workingTagName
  }

  $containerInspectResults = docker container inspect $containerName --format json | ConvertFrom-Json
  if ($containerInspectResults) {
    # RDPのポート番号が不一致の場合、現在のコンテナの状態をイメージに保存し、コンテナを再作成する
    $restartReason = "ポート番号が一致しません。現在のコンテナの状態をイメージに保存し、そこからコンテナを再作成します。"
    foreach ($container in $containerInspectResults) {
      if ($container.Name -ne "/$containerName") {
        continue
      }
      foreach ($portBinding in $container.HostConfig.PortBindings) {
        $hostIpPort = $portBinding."3389/tcp"
        if (-not($hostIpPort)) {
          continue
        }
        if ($hostIpPort.HostPort -eq $rdpPort.ToString()) {
          $restartReason = $null
          break
        }
      }
      break;
    }

    if (-not ($restartReason) -and -not (Test-NetConnection "127.0.0.1" -Port $rdpPort).TcpTestSucceeded) {
      $restartReason = "リモートデスクトップのアドレス「127.0.0.1:$rdpPort」に接続できません。Dockerコンテナを再起動します。"
    }

    docker cp "entrypoint.sh" "${containerName}:/root/entrypoint.sh"

    if ($restartReason) {
      Write-Output $restartReason
      docker stop $containerName
      docker commit $containerName $tagName
      docker container rm -f $containerName
      $containerInspectResults = $null
    }
  }

  if (-not ($containerInspectResults)) {
    $rebuildImage = $True
    $imageInspectResults = docker image inspect $tagName --format json | ConvertFrom-Json
    foreach ($image in $imageInspectResults) {
      if ($image.RepoTags -contains "${tagName}:latest") {
        $rebuildImage = $False
        break
      }
    }

    if ($rebuildImage) {
      $hidpiScaleFactor = Get-HidpiScaleFactor
      Write-Output "* HiDPI Scale Factor: $hidpiScaleFactor"
      docker build . --tag $workingTagName --progress plain --build-arg hidpi_scale_factor=$hidpiScaleFactor --build-arg user_name=$userName
      if (-not $?) {
        Write-Error """docker build . --tag $workingTagName --progress plain --build-arg hidpi_scale_factor=$hidpiScaleFactor --build-arg user_name=$userName"" コマンドの実行に失敗しました"
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
    }

    docker run --rm --gpus=all busybox true
    if ($?) {
      docker run --detach --publish "127.0.0.1:${rdpPort}:3389/tcp" --name $containerName --hostname $hostName --gpus=all $tagName
    }
    else {
      docker run --detach --publish "127.0.0.1:${rdpPort}:3389/tcp" --name $containerName --hostname $hostName $tagName
    }
  }

  $rdpReady = $False
  for ($i = 0; $i -lt 10; $i++) {
    if ((Test-NetConnection "127.0.0.1" -Port $rdpPort).TcpTestSucceeded) {
      $rdpReady = $True
      break
    }
    Start-Sleep -Seconds 1
  }
  if (-not $rdpReady) {
    Write-Error """127.0.0.1:${rdpPort}""に接続できませんでした。"
  }

  # パイプでCRが付与されるので受信側でfromdosコマンドを用いて削除する。PowerShell 2.0だと-NoNewLineオプションは無い。
  "${userName}:${rdpPassword}" | docker exec --interactive --user root $containerName /bin/bash -eu -o pipefail -c "fromdos | chpasswd"
  if (-not ($?)) {
    Write-Error "docker内ユーザーのパスワード変更に失敗しました。"
  }

  Write-Output ""
  Write-Output "/////////////////////////////////////////////////////////////////"
  Write-Output "Dockerコンテナ上でリモートデスクトップサービスが開始されました。"
  Write-Output "手動で接続する場合は次のRDP接続設定ファイルをご利用ください。"
  Write-Output "${aiSandboxRdpPath}"
  Write-Output "/////////////////////////////////////////////////////////////////"
  Write-Output ""

  mstsc $aiSandboxRdpPath /v:"127.0.0.1:${rdpPort}" /w:$rdpWidth /h:$rdpHeight
  if ($?) {
    Write-Output "リモートデスクトップクライアントを起動しました。自動的に接続できます。"
  }
  else {
    Write-Error "リモートデスクトップクライアントの起動に失敗しました。"
  }

  $closeTimeoutSeconds = 20
  Write-Output "このコンソールプログラムは、${closeTimeoutSeconds}秒後に終了します。"
  Start-Sleep -Seconds $closeTimeoutSeconds
}

Start-AiSandbox -Release $Release -Rebuild $Rebuild -ConfigPath $ConfigPath
