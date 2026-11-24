param(
    [string]$Version = "1.0.33"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$toolRoot = Join-Path $repoRoot ".tools\wechat\transformer-$Version"
$exePath = Join-Path $toolRoot "wx-transformer-v$Version-win.exe"
$zipPath = Join-Path $toolRoot "wx-transformer-v$Version.zip"
$expectedExeSha256 = "FE4CEEDCBCC6E52EC33A5A120D78E516BE1CBAD6C04705D7B0B7BB6E6A2CE878"
$downloadUrl = "https://game.weixin.qq.com/cgi-bin/gamewxagwasmsplitwap/getunityplugininfo?download=1&biz_id=3&version=$Version"

New-Item -ItemType Directory -Force -Path $toolRoot | Out-Null
if (-not (Test-Path -LiteralPath $exePath)) {
    Write-Host "Downloading official WeChat WASM transformer v$Version..."
    Invoke-WebRequest -UseBasicParsing -Uri $downloadUrl -OutFile $zipPath
    Expand-Archive -LiteralPath $zipPath -DestinationPath $toolRoot -Force
}

if (-not (Test-Path -LiteralPath $exePath)) {
    throw "WeChat transformer executable was not found after extraction: $exePath"
}
$actualExeHash = (Get-FileHash -LiteralPath $exePath -Algorithm SHA256).Hash
if ($Version -eq "1.0.33" -and $actualExeHash -ne $expectedExeSha256) {
    throw "Transformer executable SHA-256 mismatch. Expected $expectedExeSha256, got $actualExeHash"
}

Write-Output $exePath
