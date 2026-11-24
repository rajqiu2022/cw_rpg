param(
    [string]$DevToolsCli = "",
    [string]$PythonPath = "python",
    [switch]$RequireRealCredentials
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$projectRoot = Join-Path $repoRoot "game\build\wechat_trial\minigame"
$reportPath = Join-Path $repoRoot "game\build\wechat_trial\wechat-package-report.json"
$markerPath = Join-Path $projectRoot "WECHAT_TRIAL_PROJECT.txt"
if ([string]::IsNullOrWhiteSpace($DevToolsCli)) {
    # Windows PowerShell 5.1 decodes UTF-8 scripts without a BOM through the
    # active ANSI code page. Build the Chinese install-folder name explicitly.
    $devToolsFolder = (-join ([char[]](0x5FAE, 0x4FE1))) + "web" + (-join ([char[]](0x5F00, 0x53D1, 0x8005, 0x5DE5, 0x5177)))
    $DevToolsCli = Join-Path (Join-Path "C:\Program Files (x86)\Tencent" $devToolsFolder) "cli.bat"
}

if (-not (Test-Path -LiteralPath $DevToolsCli)) {
    throw "WeChat DevTools CLI not found: $DevToolsCli"
}

if (-not (Test-Path -LiteralPath $markerPath)) {
    throw "Official three-chapter trial marker is missing. Rebuild with scripts/build_wechat_trial.ps1 and import only: $projectRoot"
}

# Local developer builds reference the repository's HTTP resource server.
# Start it automatically before opening DevTools so clicking New Game cannot
# stall on chapter1_start.pck merely because the companion server was omitted.
if (Test-Path -LiteralPath $reportPath) {
    $report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
    $cdnUrl = [string]$report.cdnUrl
    if ($cdnUrl.StartsWith("http://localhost:") -or $cdnUrl.StartsWith("http://127.0.0.1:")) {
        $uri = [System.Uri]$cdnUrl
        & (Join-Path $PSScriptRoot "start_wechat_resource_server.ps1") -PythonPath $PythonPath -Port $uri.Port
    }
}

$preflightArgs = @((Join-Path $PSScriptRoot "validate_wechat_trial_release.py"), "--require-devtools-plugin")
if ($RequireRealCredentials) {
    $preflightArgs += "--require-real-credentials"
}
& $PythonPath @preflightArgs
if ($LASTEXITCODE -ne 0) {
    throw "WeChat release preflight failed with exit code $LASTEXITCODE"
}

& $DevToolsCli open --project $projectRoot --lang zh
if ($LASTEXITCODE -ne 0) {
    throw "Opening WeChat DevTools failed with exit code $LASTEXITCODE. If the CLI service port is disabled, manually import this exact folder: $projectRoot"
}

Write-Host "Opened WeChat trial project: $projectRoot"
