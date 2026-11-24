param(
    [string]$PythonPath = "python",
    [int]$Port = 8000
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$serverScript = Join-Path $PSScriptRoot "serve_wechat_smoke.py"
$probeUrl = "http://127.0.0.1:$Port/packs/chapter1_start.pck"
$stateRoot = Join-Path $repoRoot "game\build\wechat_smoke_server"
$pidPath = Join-Path $stateRoot "server.pid"

if (-not (Test-Path -LiteralPath $serverScript)) {
    throw "WeChat resource server script not found: $serverScript"
}

New-Item -ItemType Directory -Force -Path $stateRoot | Out-Null

$listener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
    Select-Object -First 1
if ($null -ne $listener) {
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Method Head -Uri $probeUrl -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Set-Content -LiteralPath $pidPath -Value $listener.OwningProcess -Encoding ascii
            Write-Host "WeChat resource server is already ready (PID $($listener.OwningProcess))."
            Write-Host "Probe: $probeUrl"
            return
        }
    }
    catch {
        throw "Port $Port is occupied by another process (PID $($listener.OwningProcess))."
    }
}

$pythonExe = (Get-Command $PythonPath -ErrorAction Stop).Source
$startArgs = @{
    FilePath = $pythonExe
    ArgumentList = @(
        $serverScript,
        "--repo-root", $repoRoot,
        "--bind", "127.0.0.1",
        "--port", "$Port"
    )
    WorkingDirectory = $repoRoot
    WindowStyle = "Hidden"
    PassThru = $true
}
$process = Start-Process @startArgs

Set-Content -LiteralPath $pidPath -Value $process.Id -Encoding ascii

$ready = $false
for ($attempt = 0; $attempt -lt 20; $attempt++) {
    Start-Sleep -Milliseconds 250
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Method Head -Uri $probeUrl -TimeoutSec 2
        if ($response.StatusCode -eq 200) {
            $ready = $true
            break
        }
    }
    catch {
        # The process may still be binding the port; keep polling briefly.
    }
}

if (-not $ready) {
    throw "WeChat resource server did not become ready. PID: $($process.Id)"
}

Write-Host "WeChat resource server started (PID $($process.Id))."
Write-Host "Probe: $probeUrl"
Write-Host "Keep this process running while testing in WeChat DevTools."
