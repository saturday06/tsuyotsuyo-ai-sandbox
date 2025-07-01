# SPDX-License-Identifier: MIT

# このファイルは、PowerShell 2.0系でも動作するように記述する。

Param(
  [bool]$Release = $False,
  [bool]$Rebuild = $False
)

$ErrorActionPreference = "Stop"

Add-Type -TypeDefinition @"
using System;
using System.Security.Cryptography;
using System.Text;

namespace TsuyotsuyoAiSandbox
{
    public static class DeterministicRandom
    {
        public static int Get(string seedString, int minValue, int maxValue)
        {
            if (minValue > maxValue)
            {
                throw new ArgumentOutOfRangeException("minValue", "minValue cannot be greater than maxValue.");
            }
            if (minValue == maxValue)
            {
                return minValue;
            }

            // シードから乱数生成器の初期状態を決定
            byte[] hashBytes;
            using (SHA256 sha256 = SHA256.Create())
            {
                hashBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(seedString));
            }

            // ハッシュ値の最初の16バイトから4つのuintを抽出 (XorShiftの内部状態)
            uint x = BitConverter.ToUInt32(hashBytes, 0);
            uint y = BitConverter.ToUInt32(hashBytes, 4);
            uint z = BitConverter.ToUInt32(hashBytes, 8);
            uint w = BitConverter.ToUInt32(hashBytes, 12);

            // すべての状態変数が0になるのを避ける (ハッシュを使っているため極めて稀だが念のため)
            if (x == 0 && y == 0 && z == 0 && w == 0)
            {
                x = 1; // どれか1つは0以外にする
            }

            // XorShiftアルゴリズムを複数回ループして状態を更新し、その都度wを次の乱数として使う
            // ループの最後のwが最終的な生成値となる
            for (int i = 0; i < 100; i++)
            {
                uint t = x ^ (x << 11);
                x = y;
                y = z;
                z = w;
                w = (w ^ (w >> 19)) ^ (t ^ (t >> 8));
            }
            uint generatedValue = w;

            // 範囲に変換
            uint range = (uint)(maxValue - minValue);
            return (int)(minValue + (generatedValue % range));
        }
    }
}
"@

$baseName = "ubuntu-noble"
$directoryName = (Split-Path -Path $PSScriptRoot -Leaf)

$tagName = "${baseName}-${directoryName}-local-tag"
$workingTagName = "${baseName}-${directoryName}-local-working-tag"
$containerName = "${baseName}-${directoryName}-local-container"
$dockerfilePath = Join-Path $PSScriptRoot "Dockerfile"
$entrypointShPath = Join-Path $PSScriptRoot "entrypoint.sh"
$aiSandboxRdpPath = Join-Path $PSScriptRoot "ai-sandbox.rdp"
$rdpPort = [TsuyotsuyoAiSandbox.DeterministicRandom]::Get($MyInvocation.MyCommand.Path, 49152, 65536)

Write-Output "* Docker Image Tag Name: ${tagName}"
Write-Output "* Docker Container Name: ${containerName}"
Write-Output "* Dockerfile Path: ${dockerfilePath}"
Write-Output "* Dockerfile Entrypoint Path: ${entrypointShPath}"
Write-Output "* RDP Configuration Path: ${aiSandboxRdpPath}"
Write-Output "* RDP Port Number: ${rdpPort}"

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
exit 0
