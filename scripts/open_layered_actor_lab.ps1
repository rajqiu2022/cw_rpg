param([string]$GodotPath = '')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$labPath = Join-Path $projectRoot 'game/build/layered_actor_20261106_lab'
if (-not $GodotPath) {
    $runningEditor = Get-CimInstance Win32_Process -Filter "name like 'Godot%win64.exe'" |
        Where-Object { $_.CommandLine -like '*--editor*' } | Select-Object -First 1
    if ($runningEditor) { $GodotPath = $runningEditor.ExecutablePath }
}
if (-not $GodotPath) {
    $knownExecutable = 'F:/文件下载/编程工具/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64.exe'
    if (Test-Path -LiteralPath $knownExecutable) { $GodotPath = $knownExecutable }
}
if (-not $GodotPath -or -not (Test-Path -LiteralPath $GodotPath)) {
    throw '请使用 -GodotPath 指定 Godot 4.6 可执行文件。'
}
# Independent project: does not run the game's autoloads, access saves or control its editor.
Start-Process -FilePath $GodotPath -ArgumentList @('--path', ('"' + $labPath + '"')) -WindowStyle Hidden
