$ErrorActionPreference = 'Stop'
$taskRoot = 'F:\Code\RPG_GAME\game\build\loading_20261106_system01'
$runRoot = Join-Path $taskRoot 'run08_market_diagnostic'
if (Test-Path -LiteralPath $runRoot) { throw 'Run folder already exists; retain prior evidence.' }
$null = New-Item -ItemType Directory -Path $runRoot
$taskAppData = Join-Path $runRoot 'appdata'
$taskLocalAppData = Join-Path $runRoot 'localappdata'
$null = New-Item -ItemType Directory -Path $taskAppData
$null = New-Item -ItemType Directory -Path $taskLocalAppData
$env:APPDATA = $taskAppData
$env:LOCALAPPDATA = $taskLocalAppData
$enginePath = 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe'
$taskArgs = @('--headless', '--path', 'F:/Code/RPG_GAME/game', '--script', 'res://build/loading_20261106_system01/market_source_diagnostic.gd')
$probeProcess = Start-Process -FilePath $enginePath -ArgumentList $taskArgs -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $runRoot 'stdout.log') -RedirectStandardError (Join-Path $runRoot 'stderr.log')
[pscustomobject]@{ wrapper_pid = $probeProcess.Id; evidence = $runRoot; note = 'Read-only Market source-set only, no timing or travel; early save suspension.' } | ConvertTo-Json -Compress
