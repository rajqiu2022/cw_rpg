param(
    [string]$ProjectRoot = 'F:/Code/RPG_GAME',
    [string]$Godot = 'F:/文件下载/编程工具/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64.exe',
    [switch]$CheckOnly,
    [ValidateRange(120,180)][int]$TimeoutSeconds = 150
)
$ErrorActionPreference = 'Stop'
$game = Join-Path $ProjectRoot 'game'
$entry = 'res://tests/test_field_loading_live_phase_cold_contract_retry2_20261013.gd'
$output = Join-Path $game ('build/loading_live_phase_cold_contract_retry2_20261013_' + [guid]::NewGuid().ToString('N'))
function Snapshot([string[]]$Paths) {
    @($Paths | ForEach-Object {
        $p = [IO.Path]::GetFullPath($_)
        if (Test-Path -LiteralPath $p -PathType Leaf) {
            $f = Get-Item -LiteralPath $p
            [ordered]@{path=$p;exists=$true;bytes=$f.Length;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash;ticks=$f.LastWriteTimeUtc.Ticks}
        } else { [ordered]@{path=$p;exists=$false} }
    })
}
function SaveJson([string]$Name, $Value) {
    $Value | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $output $Name) -Encoding utf8
}
# Immutable earlier result provides PATHS ONLY; every current leaf is freshly hashed.
$seed = Join-Path $game 'build/joint_world_luoyang_20261003_qa/field_loading_source_cancel_78424_1533154/result.json'
if ((Get-FileHash -LiteralPath $seed -Algorithm SHA256).Hash -cne '4F4D93218F49A5ED8A37C026674E58CFE64EB526FE2BAE124106BAF0AB93BBE6') { throw 'Known path seed bytes changed' }
$seedResult = Get-Content -LiteralPath $seed -Raw | ConvertFrom-Json -AsHashtable
$seedRows = @($seedResult.rows | Where-Object { $_.kind -ceq 'ACTUAL_COMPLETE_SOURCE_WORKER_ONLY' })
if ($seedRows.Count -ne 1 -or $seedRows[0].sources -isnot [System.Collections.IDictionary] -or $seedRows[0].sources.Count -eq 0) { throw 'Known real source path table missing' }
$sourceSet = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($path in $seedRows[0].sources.Keys) {
    if ($path -isnot [string] -or -not $path.StartsWith('res://', [StringComparison]::Ordinal) -or $path.Contains('..')) { throw 'Invalid project path seed' }
    $absolute = [IO.Path]::GetFullPath((Join-Path $game $path.Substring(6)))
    if (-not $absolute.StartsWith(([IO.Path]::GetFullPath($game).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar), [StringComparison]::OrdinalIgnoreCase)) { throw 'Source path leaves project' }
    [void]$sourceSet.Add($absolute)
}
$relative = @(
    'scripts/autoload/loading_manager.gd','scripts/autoload/scene_router.gd',
    'scripts/field/field_walkable_controller.gd','scripts/ui/loading_screen.gd',
    'scripts/city/luoyang_enclosure_v11_candidate_contract.gd','scripts/city/luoyang_city3_motion_guard_20261009.gd',
    'scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd',
    'scripts/dev/luoyang_v3_wall_v5_saved_resource_checker.gd','scripts/city/luoyang_enclosure_v14_ground_binding.gd',
    'scripts/dev/luoyang_v3_wall_v5_note_saved_resource_checker.gd',
    'scripts/city/luoyang_layered_v3_wall_v5_candidate_contract.gd','scripts/city/luoyang_base_cold_cpu_workspace_20261013.gd',
    'tests/test_field_loading_live_phase_cold_contract_retry2_20261013.gd','tests/test_field_loading_live_phase_cold_contract_20261013.gd','tests/test_field_loading_v4_ground_receipt_cold_contract_20261013.gd','tests/test_field_loading_source_receipt_cold_contract_20261013.gd','tests/test_field_loading_base_cpu_cold_contract_20261013.gd','tests/test_field_loading_cold_contract_20261013.gd','tests/test_field_loading_key_exit_cleanup_20261013.gd',
    'scripts/autoload/platform_bridge.gd','scripts/autoload/audio_manager.gd',
    'scripts/domain/scene_script.gd','scripts/domain/walkable_map_layout.gd',
    'scenes/field_walkable.tscn','data/maps/interior_inn_hall_layout_v1.tres',
    'data/scenes/ch4_s0_luoyang_gate.tres','data/scenes/ch4_s1_luoyang_yamen.tres',
    'data/scenes/ch4_s2_canal_docks.tres','data/scenes/ch4_s3_luoyang_market.tres',
    'data/scenes/world_map_jianghu.tres','data/scenes/interior_inn_hall.tres',
    'data/maps/luoyang_enclosure_v11_candidates/ch4_s0_luoyang_gate_layout.tres',
    'art/maps/luoyang_enclosure_v11/ch4_s0_luoyang_gate/walk.png',
    'art/backgrounds/bg_interior_inn_hall_v1.png','art/backgrounds/bg_interior_inn_hall_v1.png.import','project.godot'
)
foreach ($path in $relative) { [void]$sourceSet.Add([IO.Path]::GetFullPath((Join-Path $game $path))) }
$smallImport = Join-Path $game 'art/backgrounds/bg_interior_inn_hall_v1.png.import'
foreach ($match in [regex]::Matches([IO.File]::ReadAllText($smallImport), '"(res://\.godot/imported/[^"\r\n]+)"')) {
    [void]$sourceSet.Add([IO.Path]::GetFullPath((Join-Path $game $match.Groups[1].Value.Substring(6))))
}
foreach ($path in @($Godot,$PSCommandPath,$seed,(Join-Path $ProjectRoot 'scripts/qa/run_field_loading_live_phase_cold_contract_20261013.ps1'))) { [void]$sourceSet.Add([IO.Path]::GetFullPath($path)) }
$sourcePaths = @($sourceSet | Sort-Object)
foreach ($path in $sourcePaths) { if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw ('Required current source leaf absent: ' + $path) } }
$playerRoot = Join-Path $env:APPDATA 'Godot/app_userdata/云影侠传'
$playerPaths = @(foreach ($index in 0..4) { foreach ($suffix in @('','.bak','.tmp')) { Join-Path $playerRoot ('save_' + $index + '.json' + $suffix) } })
if ((Get-FileHash -LiteralPath $Godot).Hash -cne '975BF1D254B989EE12B64DF4D07DA692A31175F72424BAA180F1078BFC0D71B0') { throw 'GUI executable SHA differs' }
New-Item -ItemType Directory -Path $output | Out-Null
$sourceBefore = Snapshot $sourcePaths
$playersBefore = Snapshot $playerPaths
SaveJson 'source_before.json' $sourceBefore
SaveJson 'saves_before.json' $playersBefore
$arguments = @('--audio-driver','Dummy','--path',('"' + $game + '"'),'--script',$entry,'--verbose')
if ($CheckOnly) { $arguments = @('--headless') + $arguments + @('--check-only') }
$arguments += @('--','--field-loading-key')
$process = Start-Process -FilePath $Godot -ArgumentList $arguments -WindowStyle Hidden -RedirectStandardOutput (Join-Path $output 'stdout.log') -RedirectStandardError (Join-Path $output 'stderr.log') -PassThru
$pidOwned = $process.Id
$ticksOwned = $process.StartTime.ToUniversalTime().Ticks
$exeOwned = $process.Path
# Observed path may be unavailable; never replace it with the declared target.
$declaredTarget = [IO.Path]::GetFullPath($Godot)
SaveJson 'process.json' ([ordered]@{pid=$pidOwned;startTicks=$ticksOwned;exe=$exeOwned;observedExe=$exeOwned;declaredTarget=$declaredTarget;observedExeCaptured=(-not [string]::IsNullOrEmpty($exeOwned));args=$arguments;checkOnly=[bool]$CheckOnly;pathSeed=$seed;oldDigestCredit=$false;sourceCount=$sourcePaths.Count;scope='ONE_STAGE9_LIVE_PHASE_COLD_GATE_CONTRACT_AND_LOADING_GPU_NOT_CITY_FIELD_OR_AUDIO'})
$timer = [Diagnostics.Stopwatch]::StartNew()
$timeout = $false
$runnerError = ''
while (-not $process.WaitForExit(250)) {
    if ($timer.Elapsed.TotalSeconds -ge $TimeoutSeconds) {
        $timeout = $true
        try {
            $actual = Get-Process -Id $pidOwned -ErrorAction Stop
            if ([string]::IsNullOrEmpty($exeOwned) -or [string]::IsNullOrEmpty($actual.Path) -or $actual.StartTime.ToUniversalTime().Ticks -ne $ticksOwned -or $actual.Path -cne $exeOwned -or [IO.Path]::GetFullPath($actual.Path) -cne [IO.Path]::GetFullPath($Godot)) { throw 'Timeout ownership mismatch; no process stopped' }
            Stop-Process -Id $pidOwned -ErrorAction Stop
            if (-not $process.WaitForExit(10000)) { throw 'Owned process did not exit within bounded cleanup' }
        } catch { $runnerError = $_.Exception.Message }
        break
    }
}
$natural = -not $timeout -and $process.HasExited
$actualExit = if ($process.HasExited) { $process.ExitCode } else { $null }
$sourceAfter = Snapshot $sourcePaths
$playersAfter = Snapshot $playerPaths
SaveJson 'source_after.json' $sourceAfter
SaveJson 'saves_after.json' $playersAfter
$sameSources = (ConvertTo-Json -InputObject $sourceBefore -Depth 12 -Compress) -ceq (ConvertTo-Json -InputObject $sourceAfter -Depth 12 -Compress)
$samePlayers = (ConvertTo-Json -InputObject $playersBefore -Depth 12 -Compress) -ceq (ConvertTo-Json -InputObject $playersAfter -Depth 12 -Compress)
SaveJson 'completion.json' ([ordered]@{pid=$pidOwned;declaredTarget=$declaredTarget;observedExe=$exeOwned;observedExeCaptured=(-not [string]::IsNullOrEmpty($exeOwned));natural=$natural;exit=$actualExit;timedOut=$timeout;error=$runnerError;sourceUnchanged=$sameSources;player15Unchanged=$samePlayers;finishedUtc=[DateTime]::UtcNow.ToString('o');stdoutSHA=(Get-FileHash -LiteralPath (Join-Path $output 'stdout.log')).Hash;stderrSHA=(Get-FileHash -LiteralPath (Join-Path $output 'stderr.log')).Hash;scope='ONE_REAL_STAGE9_LIVE_PHASE_COLD_CONTRACT_NOT_FULL_FIELD_OR_SMOOTHNESS';stderrRequiresExactIndependentReview=$true})
Write-Output $output
if (-not $natural -or -not $sameSources -or -not $samePlayers -or $runnerError -ne '') { exit 2 }
exit $actualExit
