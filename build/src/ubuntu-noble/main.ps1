# SPDX-License-Identifier: MIT

# このファイルは、PowerShell 2.0系でも動作するように記述する。

param(
  [bool]$Release = $False,
  [bool]$Rebuild = $False
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

function Start-AiSandbox {
  param(
    [bool]$Release,
    [bool]$Rebuild
  )

  $baseName = "ubuntu-noble"
  $directoryName = (Split-Path -Path $PSScriptRoot -Leaf)

  $tagName = "${baseName}-${directoryName}-local-tag"
  $workingTagName = "${baseName}-${directoryName}-local-working-tag"
  $containerName = "${baseName}-${directoryName}-local-container"
  $dockerfilePath = Join-Path $PSScriptRoot "Dockerfile"
  $entrypointShPath = Join-Path $PSScriptRoot "entrypoint.sh"
  $aiSandboxRdpPath = Join-Path $PSScriptRoot "ai-sandbox.rdp"
  $scriptPath = $script:MyInvocation.MyCommand.Path
  $rdpPort = Get-DeterministicRandom -SeedString $scriptPath -MinValue 49152 -MaxValue 59312 # Rancher Desktop doesn't support `port >= 59312`.

  Write-Output "* Docker Image Tag Name: ${tagName}"
  Write-Output "* Docker Container Name: ${containerName}"
  Write-Output "* Dockerfile Path: ${dockerfilePath}"
  Write-Output "* Dockerfile Entrypoint Path: ${entrypointShPath}"
  Write-Output "* Script Path: ${scriptPath}"
  Write-Output "* RDP Configuration Path: ${aiSandboxRdpPath}"
  Write-Output "* RDP Port Number: ${rdpPort}"

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
      Write-Error "ai-sandbox.rdpの抽出に失敗しました。"
    }
    $aiSandboxRdpContent = $aiSandboxRdpMatch.Groups[1].Value.Replace(
      "### HASH ###",
      (ConvertTo-SecureString "xyzzy" -AsPlainText -Force | ConvertFrom-SecureString)
    )
    Set-Content $aiSandboxRdpPath $aiSandboxRdpContent -Encoding Unicode
  }

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

  docker container inspect $containerName | Out-Null
  if (-not $?) {
    $hidpiScaleFactor = Get-HidpiScaleFactor
    Write-Output "* HiDPI Scale Factor: $hidpiScaleFactor"
    docker build . --tag $workingTagName --progress plain --build-arg hidpi_scale_factor=$hidpiScaleFactor
    if (-not $?) {
      Write-Error """docker build . --tag $workingTagName --progress plain --build-arg hidpi_scale_factor=$hidpiScaleFactor"" コマンドの実行に失敗しました"
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

  Write-Output ""
  Write-Output "/////////////////////////////////////////////////////////////////"
  Write-Output "Dockerコンテナ上でリモートデスクトップサービスが開始されました。"
  Write-Output "手動で接続する場合はRDPクライアントに次の情報を入力してください。"
  Write-Output "- コンピューター: 127.0.0.1:${rdpPort}"
  Write-Output "- ユーザー名: xyzzy"
  Write-Output "- パスワード: xyzzy"
  Write-Output "/////////////////////////////////////////////////////////////////"
  Write-Output ""

  mstsc ai-sandbox.rdp /v:"127.0.0.1:${rdpPort}"
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

Start-AiSandbox -Release $Release -Rebuild $Rebuild
