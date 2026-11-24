$ErrorActionPreference = 'Stop'
# Root-only single engine window. This file does not stop any existing process.
$taskRoot = 'F:\Code\RPG_GAME\game\build\loading_20261106_system01'
$runRoot = Join-Path $taskRoot 'run07_root_residual'
if (Test-Path -LiteralPath $runRoot) { throw 'Run folder already exists; retain prior evidence and do not rerun implicitly.' }
$null = New-Item -ItemType Directory -Path $runRoot
$taskAppData = Join-Path $runRoot 'appdata'
$taskLocalAppData = Join-Path $runRoot 'localappdata'
$null = New-Item -ItemType Directory -Path $taskAppData
$null = New-Item -ItemType Directory -Path $taskLocalAppData
$env:APPDATA = $taskAppData
$env:LOCALAPPDATA = $taskLocalAppData
$enginePath = 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe'
$taskArgs = @('--path', 'F:/Code/RPG_GAME/game', '--script', 'res://build/loading_20261106_system01/paired_hash_residual.gd', '--resolution', '1280x720', '--position', '0,0')
$probeProcess = Start-Process -FilePath $enginePath -ArgumentList $taskArgs -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $runRoot 'stdout.log') -RedirectStandardError (Join-Path $runRoot 'stderr.log')
[pscustomobject]@{ wrapper_pid = $probeProcess.Id; evidence = $runRoot; note = 'No auto kill; probe has finite watchdog and early checkpoint-save suspension.' } | ConvertTo-Json -Compress
