param([switch]$CheckOnly, [switch]$WorkerOnly)
$ErrorActionPreference = 'Stop'
$taskRoot = 'F:\Code\RPG_GAME'
$taskExe = 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe'
$taskScript = if ($WorkerOnly) { 'test_field_loading_motion_worker_20261013.gd' } else { 'test_field_loading_transition_token_20261013.gd' }
$taskTest = Join-Path $taskRoot ('game\tests\' + $taskScript)
$taskPin = if ($WorkerOnly) { '8AA31B6F19F0CB009F82C2346D97C2FD991318B7D5DD0D879AADBEA9204D01D4' } else { 'E53454BAADF89CE6F5C97FEE94768B67A6BB3B2A007B8B13001219B2B52D17D1' }
if ((Get-FileHash -LiteralPath $taskTest -Algorithm SHA256).Hash -ne $taskPin) { throw 'Frozen test mismatch' }
$taskOutput = Join-Path $taskRoot ('game\build\loading_runtime_transition_20261013_' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $taskOutput | Out-Null
$taskSources = @('game/scripts/autoload/loading_manager.gd','game/scripts/autoload/scene_router.gd','game/scripts/field/field_walkable_controller.gd','game/scripts/ui/loading_screen.gd','game/scripts/city/luoyang_enclosure_v11_candidate_contract.gd','game/scripts/city/luoyang_city3_motion_guard_20261009.gd','game/tests/test_field_loading_transition_token_20261013.gd','game/data/scenes/ch4_s0_luoyang_gate.tres','game/data/scenes/ch4_s1_luoyang_yamen.tres','game/data/scenes/ch4_s2_luoyang_docks.tres','game/data/scenes/ch4_s3_luoyang_market.tres','game/data/scenes/world_map_jianghu.tres') | ForEach-Object { Join-Path $taskRoot $_ }
$taskSources += $taskExe
if ($WorkerOnly) { $taskSources += @($taskTest, (Join-Path $taskRoot 'game\data\scenes\ch4_s2_canal_docks.tres')) }
$taskSaveDir = 'C:\Users\rajqiu\AppData\Roaming\Godot\app_userdata\云影侠传'
$taskSaves = foreach ($index in 0..4) { foreach ($suffix in @('', '.bak', '.tmp')) { Join-Path $taskSaveDir ('save_' + $index + '.json' + $suffix) } }
function Get-TaskSnapshot($Paths) {
    @($Paths | ForEach-Object {
        if (Test-Path -LiteralPath $_ -PathType Leaf) {
            $item = Get-Item -LiteralPath $_
            [ordered]@{path=$_;exists=$true;bytes=$item.Length;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash;ticks=$item.LastWriteTimeUtc.Ticks}
        } else { [ordered]@{path=$_;exists=$false} }
    })
}
$taskSourceBefore = Get-TaskSnapshot $taskSources
$taskSaveBefore = Get-TaskSnapshot $taskSaves
$taskSourceBefore | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $taskOutput 'source_before.json') -Encoding utf8
$taskSaveBefore | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $taskOutput 'saves_before.json') -Encoding utf8
$taskArgs = @('--headless','--audio-driver','Dummy','--path','F:/Code/RPG_GAME/game','--script',('res://tests/' + $taskScript))
if ($CheckOnly) { $taskArgs += '--check-only' } else { $taskArgs += @('--','--field-loading-key') }
$taskProcess = Start-Process -FilePath $taskExe -ArgumentList $taskArgs -WindowStyle Hidden -RedirectStandardOutput (Join-Path $taskOutput 'stdout.log') -RedirectStandardError (Join-Path $taskOutput 'stderr.log') -PassThru
$taskTicks = $taskProcess.StartTime.ToUniversalTime().Ticks
[ordered]@{pid=$taskProcess.Id;startTicks=$taskTicks;exe=$taskExe;args=$taskArgs;checkOnly=[bool]$CheckOnly} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $taskOutput 'process.json') -Encoding utf8
Write-Output ('START ' + $taskProcess.Id + ' ' + $taskOutput)
$taskNatural = $taskProcess.WaitForExit($(if ($CheckOnly) { 30000 } elseif ($WorkerOnly) { 55000 } else { 105000 }))
if (-not $taskNatural) {
    $taskLive = Get-Process -Id $taskProcess.Id -ErrorAction SilentlyContinue
    if ($null -ne $taskLive -and $taskLive.StartTime.ToUniversalTime().Ticks -eq $taskTicks -and $taskLive.Path -eq $taskExe) { Stop-Process -Id $taskLive.Id; $taskProcess.WaitForExit() }
    else { throw 'Timeout process identity did not match own process' }
}
$taskProcess.Refresh()
$taskSourceAfter = Get-TaskSnapshot $taskSources
$taskSaveAfter = Get-TaskSnapshot $taskSaves
$taskSourceAfter | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $taskOutput 'source_after.json') -Encoding utf8
$taskSaveAfter | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $taskOutput 'saves_after.json') -Encoding utf8
$taskSourcesUnchanged = (ConvertTo-Json $taskSourceBefore -Depth 8 -Compress) -ceq (ConvertTo-Json $taskSourceAfter -Depth 8 -Compress)
$taskSavesUnchanged = (ConvertTo-Json $taskSaveBefore -Depth 8 -Compress) -ceq (ConvertTo-Json $taskSaveAfter -Depth 8 -Compress)
[ordered]@{pid=$taskProcess.Id;natural=$taskNatural;exit=$taskProcess.ExitCode;sourceUnchanged=$taskSourcesUnchanged;player15Unchanged=$taskSavesUnchanged;finishedUtc=[DateTime]::UtcNow.ToString('o')} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $taskOutput 'completion.json') -Encoding utf8
Get-Content -LiteralPath (Join-Path $taskOutput 'completion.json')
Get-Content -LiteralPath (Join-Path $taskOutput 'stderr.log')
Get-Content -LiteralPath (Join-Path $taskOutput 'stdout.log') -Tail 5
