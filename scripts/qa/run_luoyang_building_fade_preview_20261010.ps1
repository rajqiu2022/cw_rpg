# NEW standalone Dummy building-fade preview wrapper. Does not run strict six.
# ROOT alone executes it; paths from a prior before snapshot are PATH SEEDS only.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ProjectRoot,
    [Parameter(Mandatory)][string]$GodotExecutable,
    [Parameter(Mandatory)][string]$PlayerSaveDirectory,
    [Parameter(Mandatory)][string]$SeedBeforeJSON,
    [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$SeedBeforeSHA,
    [Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RunName,
    [ValidateSet('units','gpu')][string]$Mode='units',
    [ValidateRange(30,600)][int]$TimeoutSeconds=180
)
$ErrorActionPreference='Stop'
$rootPath=(Resolve-Path -LiteralPath $ProjectRoot).Path.TrimEnd('\','/')
$gamePath=Join-Path $rootPath 'game'
$exePath=(Resolve-Path -LiteralPath $GodotExecutable).Path
$savePath=(Resolve-Path -LiteralPath $PlayerSaveDirectory).Path
$seedPath=(Resolve-Path -LiteralPath $SeedBeforeJSON).Path
$expectedEngine='975BF1D254B989EE12B64DF4D07DA692A31175F72424BAA180F1078BFC0D71B0'
$entry='game/tests/test_luoyang_building_fade_preview_20261010.gd'
$helper='game/scripts/city/luoyang_enclosure_building_fade_preview_20261010.gd'
$expectedHelper='BB5D12158C01AAD7BC6E36F53E0BF103AF016E195BA690B97A04F6669F8C7BCA'
function File-Identity([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return [ordered]@{path=$Path;exists=$false;bytes=0L;sha256='ABSENT';utc_ticks='ABSENT'}
    }
    $item=Get-Item -LiteralPath $Path
    return [ordered]@{path=$item.FullName;exists=$true;bytes=[long]$item.Length;
        sha256=(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash;
        utc_ticks=$item.LastWriteTimeUtc.Ticks.ToString([Globalization.CultureInfo]::InvariantCulture)}
}
function Source-Path([string]$Path) {
    if ($Path.StartsWith('res://',[StringComparison]::Ordinal)) {
        $Path=Join-Path $gamePath $Path.Substring(6)
    } elseif (-not [IO.Path]::IsPathRooted($Path)) { $Path=Join-Path $rootPath $Path }
    $full=[IO.Path]::GetFullPath($Path)
    if (-not $full.StartsWith($rootPath+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
        throw "Source outside project: $Path"
    }
    return $full
}
$sources=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$visited=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
function Add-Source([string]$Path) {
    $full=Source-Path $Path
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { throw "Missing required source: $full" }
    $null=$sources.Add($full)
    if (-not $visited.Add($full)) { return }
    $extension=[IO.Path]::GetExtension($full).ToLowerInvariant()
    if ($extension -in @('.gd','.tscn','.tres','.godot')) {
        $content=[IO.File]::ReadAllText($full)
        foreach ($sourceMatch in [regex]::Matches($content,'res://[^"\r\n]+(?=["\r\n])')) {
            $dependency=Source-Path $sourceMatch.Value
            # Directory constants are excluded, never claimed as file guards.
            if (Test-Path -LiteralPath $dependency -PathType Leaf) { Add-Source $dependency }
        }
    }
    $import=$full+'.import'
    if (-not (Test-Path -LiteralPath $import -PathType Leaf)) { return }
    Add-Source $import
    $importText=[IO.File]::ReadAllText($import)
    foreach ($compiledMatch in [regex]::Matches($importText,'res://[.]godot/imported/[^"\r\n]+')) {
        Add-Source $compiledMatch.Value
    }
}
if ((Get-FileHash -LiteralPath $exePath -Algorithm SHA256).Hash -cne $expectedEngine) { throw 'Unexpected installed executable' }
if ((Get-FileHash -LiteralPath $seedPath -Algorithm SHA256).Hash -cne $SeedBeforeSHA.ToUpperInvariant()) { throw 'Wrong path seed document SHA' }
if ((Get-FileHash -LiteralPath (Join-Path $rootPath $helper) -Algorithm SHA256).Hash -cne $expectedHelper) { throw 'Wrong NEW helper SHA' }
$seed=[IO.File]::ReadAllText($seedPath) | ConvertFrom-Json -AsHashtable -Depth 100
if ($seed.sources -isnot [array] -or $seed.sources.Count -lt 4624) { throw 'Expected full current path seed, not narrow historical wrapper' }
foreach ($row in $seed.sources) {
    if ($row -isnot [Collections.IDictionary] -or $row.path -isnot [string]) { throw 'Untyped path seed row' }
    Add-Source $row.path
}
# No seed row SHA/bytes/ticks are used. Snapshot every current source freshly.
foreach ($path in @($entry,$helper,'game/project.godot','game/scenes/player.tscn',
    'game/scripts/city/luoyang_enclosure_native_depth_overlap_20261009.gd',
    'game/scripts/city/luoyang_v3_modular_overlap.gd','game/scripts/world/outskirts_modular_overlap.gd',
    'game/scripts/world/v14_modular_overlap.gd','game/scripts/field/player.gd',
    'game/scripts/autoload/platform_bridge.gd','game/scripts/autoload/save_manager.gd',
    'game/data/scenes/world_map_jianghu.tres','game/data/maps/world_map_jianghu_layout_v14.tres',
    'game/data/config/outskirts_native_adoption.json',
    'game/art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/ch4_s3_luoyang_market/entities/inn.png',
    'game/art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/ch4_s0_luoyang_gate/entities/south_gate.png',
    'game/art/characters/hero_idle_down_25d_runtime_4f.png',
    'game/art/characters/weapon_variants/lengguyun/v7_idle_stable/sword/lengguyun_sword_idle_down_25d_4f.png')) { Add-Source $path }
foreach ($id in @('ch4_s0_luoyang_gate','ch4_s1_luoyang_yamen','ch4_s2_canal_docks','ch4_s3_luoyang_market')) {
    Add-Source ("game/data/scenes/$id.tres")
    Add-Source ("game/data/maps/luoyang_enclosure_v11_candidates/"+$id+'_layout.tres')
}
Add-Source $PSCommandPath
# Known startup dynamic leaves only, single level, never historical JSON traversal.
foreach ($directory in @('bounties','quests','items','equipment','skills')) {
    foreach ($leaf in Get-ChildItem -LiteralPath (Join-Path $gamePath "data/$directory") -File -Filter '*.tres') { Add-Source $leaf.FullName }
}
$sourceRows=@($sources | Sort-Object | ForEach-Object { File-Identity $_ })
$playerRows=@(foreach ($index in 0..4) { foreach ($suffix in @('','.bak','.tmp')) { File-Identity (Join-Path $savePath ("save_$index.json$suffix")) } })
$runDirectory=Join-Path $gamePath ("build/joint_world_luoyang_20261003_qa/"+$RunName)
if (Test-Path -LiteralPath $runDirectory) { throw 'Refuse existing evidence directory' }
$null=New-Item -ItemType Directory -Path $runDirectory
$displayArgs=if ($Mode -eq 'units') { @('--display-driver','headless') } else { @('--rendering-method','gl_compatibility') }
$modeFlag=if ($Mode -eq 'units') { '--building-fade-units' } else { '--building-fade-gpu-preview' }
$launchArguments=@('--path',$gamePath,'--script','res://tests/test_luoyang_building_fade_preview_20261010.gd','--audio-driver','Dummy','--verbose')+$displayArgs+@('--',$modeFlag,'--audio-preview-dummy')
$before=[ordered]@{scope='BUILDING_FADE_PREVIEW_NOT_APPROVAL';audio_tested=$false;production_field_integrated=$false;approval=$false;
    timestamp_utc=[DateTime]::UtcNow.ToString('o');sources=$sourceRows;players=$playerRows;engine=(File-Identity $exePath);
    seed_path=$seedPath;seed_sha256=$SeedBeforeSHA;path_seed_only=$true;arguments=$launchArguments}
$before | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath (Join-Path $runDirectory 'before.json') -Encoding utf8NoBOM
# Avoid same-basename overwrites: every source archive has SHA prefix.
$archive=Join-Path $runDirectory 'source_copies'
$null=New-Item -ItemType Directory -Path $archive
foreach ($row in $sourceRows) {
    if ([IO.Path]::GetExtension($row.path) -in @('.gd','.ps1','.godot')) {
        Copy-Item -LiteralPath $row.path -Destination (Join-Path $archive ($row.sha256+'_'+[IO.Path]::GetFileName($row.path)))
    }
}
# Paths may contain spaces: native argument quoting is explicit.
$argumentLine=($launchArguments | ForEach-Object { '"'+$_.Replace('"','\"')+'"' }) -join ' '
$process=Start-Process -FilePath $exePath -ArgumentList $argumentLine -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $runDirectory 'stdout.log') -RedirectStandardError (Join-Path $runDirectory 'stderr.log')
$started=[DateTime]::UtcNow
$timedOut=$false
while (-not $process.HasExited) {
    if (([DateTime]::UtcNow-$started).TotalSeconds -gt $TimeoutSeconds) {
        $timedOut=$true
        # Only this unique wrapper-owned process. Never editor/all-Godot stops.
        Stop-Process -Id $process.Id -ErrorAction Stop
        break
    }
    $null=$process.WaitForExit(250)
    $process.Refresh()
}
$process.WaitForExit()
$changedSources=@(foreach ($row in $sourceRows) {
    $now=File-Identity $row.path
    if (($row | ConvertTo-Json -Compress) -cne ($now | ConvertTo-Json -Compress)) { [ordered]@{before=$row;after=$now} }
})
$changedPlayers=@(foreach ($row in $playerRows) {
    $now=File-Identity $row.path
    if (($row | ConvertTo-Json -Compress) -cne ($now | ConvertTo-Json -Compress)) { [ordered]@{before=$row;after=$now} }
})
$after=[ordered]@{scope='BUILDING_FADE_PREVIEW_NOT_APPROVAL';audio_tested=$false;production_field_integrated=$false;approval=$false;
    timestamp_utc=[DateTime]::UtcNow.ToString('o');actual_exit_code=$process.ExitCode;timed_out=$timedOut;
    source_changes=$changedSources;player_changes=$changedPlayers;engine_after=(File-Identity $exePath);
    stdout=(File-Identity (Join-Path $runDirectory 'stdout.log'));stderr=(File-Identity (Join-Path $runDirectory 'stderr.log'))}
$after | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath (Join-Path $runDirectory 'after.json') -Encoding utf8NoBOM
# All stderr remains retained for ROOT classification; exit0 never means clean.
Write-Output ("BUILDING_FADE_WRAPPER "+$runDirectory+" OS="+$process.ExitCode+" source_changes="+$changedSources.Count+" player_changes="+$changedPlayers.Count)
if ($timedOut -or $changedSources.Count -ne 0 -or $changedPlayers.Count -ne 0 -or $process.ExitCode -ne 0 -or $after.engine_after.sha256 -cne $expectedEngine) { exit 1 }
exit 0

