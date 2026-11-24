param(
    [Parameter(Mandatory)][string]$RunName,
    [Parameter(Mandatory)][string]$Entry,
    [Parameter(Mandatory)][string]$SourcePathsFile,
    [Parameter(Mandatory)][string]$SourcePathsSHA,
    [string[]]$RunArgs = @(),
    [switch]$Gpu,
    [ValidateRange(30,600)][int]$TimeoutSeconds = 90
)
$ErrorActionPreference = 'Stop'
$projectRoot = 'F:\Code\RPG_GAME'
$taskRoot = Join-Path $projectRoot 'game\build\loading_20261106_system02'
$saveRoot = 'C:\Users\rajqiu\AppData\Roaming\Godot\app_userdata\云影侠传'
if ($RunName -notmatch '^[A-Za-z0-9_-]+$') { throw 'Invalid RunName' }
$runRoot = Join-Path $taskRoot $RunName
if (Test-Path -LiteralPath $runRoot) { throw 'Evidence directory already exists; retain it.' }
function Assert-SourcePath([string]$Path) {
    $full = [IO.Path]::GetFullPath($Path)
    if (-not $full.StartsWith($projectRoot + '\',[StringComparison]::OrdinalIgnoreCase)) { throw "Source outside project: $full" }
    if ($full -match '(?i)[\\/](app_userdata|saves?|appdata|localappdata)[\\/]|[\\/]save_\d+\.json') { throw "Forbidden save source: $full" }
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { throw "Missing source: $full" }
    return $full
}
$inventoryPath = Assert-SourcePath $SourcePathsFile
if ((Get-FileHash -LiteralPath $inventoryPath -Algorithm SHA256).Hash -ne $SourcePathsSHA) { throw 'Inventory SHA mismatch' }
$inventory = Get-Content -LiteralPath $inventoryPath -Raw | ConvertFrom-Json -AsHashtable
if (-not $inventory.ContainsKey('source_paths') -or @($inventory.source_paths).Count -eq 0) { throw 'Expected nonempty source_paths array' }
$sourceSet = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($relative in $inventory.source_paths) {
    $relative = [string]$relative
    if ($relative.StartsWith('res://')) { $relative = 'game/' + $relative.Substring(6) }
    if ([IO.Path]::IsPathRooted($relative)) { throw 'Inventory paths must be project-relative or res://' }
    $null = $sourceSet.Add((Assert-SourcePath (Join-Path $projectRoot $relative)))
}
if (-not $Entry.StartsWith('res://') -or -not $Entry.EndsWith('.gd')) { throw 'Entry must be res:// script' }
$entryPath = Assert-SourcePath (Join-Path $projectRoot ('game/' + $Entry.Substring(6)))
if (-not $sourceSet.Contains($entryPath)) { throw 'Entry must be in finite source inventory' }
$null = $sourceSet.Add($inventoryPath)
$null = $sourceSet.Add((Assert-SourcePath $PSCommandPath))
$enginePath = 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe'
$engineSHA = '975BF1D254B989EE12B64DF4D07DA692A31175F72424BAA180F1078BFC0D71B0'
if ((Get-FileHash -LiteralPath $enginePath -Algorithm SHA256).Hash -ne $engineSHA) { throw 'Engine SHA mismatch' }
function Source-Record([string]$Path) {
    $item = Get-Item -LiteralPath $Path
    return @{ path=$Path; bytes=$item.Length; utc_ticks=$item.LastWriteTimeUtc.Ticks; sha256=(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }
}
function Player-Metadata {
    foreach ($slot in 0..4) {
        foreach ($suffix in @('', '.bak', '.tmp')) {
            $path = Join-Path $saveRoot ("save_$slot.json$suffix")
            if (Test-Path -LiteralPath $path -PathType Leaf) {
                $item = Get-Item -LiteralPath $path
                @{ path=$path; exists=$true; bytes=$item.Length; utc_ticks=$item.LastWriteTimeUtc.Ticks }
            } else { @{ path=$path; exists=$false; bytes=$null; utc_ticks=$null } }
        }
    }
}
function Write-Record([string]$Name,$Value) { $Value | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath (Join-Path $runRoot $Name) -Encoding utf8NoBOM }
$null = New-Item -ItemType Directory -Path $runRoot
$copyRoot = Join-Path $runRoot 'source_copies'
$null = New-Item -ItemType Directory -Path $copyRoot
$sourcesBefore = @($sourceSet | Sort-Object | ForEach-Object { Source-Record $_ })
$playerBefore = @(Player-Metadata)
foreach ($record in $sourcesBefore) {
    $copyPath = Join-Path $copyRoot ($record.sha256 + '.source')
    if (-not (Test-Path -LiteralPath $copyPath)) { Copy-Item -LiteralPath $record.path -Destination $copyPath }
    if ((Get-FileHash -LiteralPath $copyPath).Hash -ne $record.sha256 -or (Get-FileHash -LiteralPath $record.path).Hash -ne $record.sha256) { throw 'Source changed during capture' }
}
Write-Record 'before.json' @{ sources=$sourcesBefore; player_metadata=$playerBefore; player_scope='15 named slot metadata records ONLY; not prior 171 matrix; no save content hashing/copying'; engine_sha256=$engineSHA }
$taskAppData = Join-Path $runRoot 'appdata'
$taskLocalAppData = Join-Path $runRoot 'localappdata'
$null = New-Item -ItemType Directory -Path $taskAppData
$null = New-Item -ItemType Directory -Path $taskLocalAppData
$oldAppData = $env:APPDATA; $oldLocalAppData = $env:LOCALAPPDATA
$probeProcess = $null; $timedOut = $false; $exitCode = $null; $launchError = ''; $ownPid = $null
try {
    $env:APPDATA = $taskAppData; $env:LOCALAPPDATA = $taskLocalAppData
    $taskArgs = @('--path', 'F:/Code/RPG_GAME/game', '--audio-driver', 'WASAPI', '--accessibility', 'disabled', '--script', $Entry)
    if ($Gpu) { $taskArgs += @('--rendering-method', 'gl_compatibility') } else { $taskArgs += @('--headless') }
    $taskArgs += $RunArgs
    $probeProcess = Start-Process -FilePath $enginePath -ArgumentList $taskArgs -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $runRoot 'stdout.log') -RedirectStandardError (Join-Path $runRoot 'stderr.log')
    $ownPid = $probeProcess.Id
    Write-Record 'owned_process.json' @{ actual_gui_pid=$ownPid; engine_path=$enginePath; start_utc=$probeProcess.StartTime.ToUniversalTime().ToString('o'); args=$taskArgs; appdata=$taskAppData; localappdata=$taskLocalAppData; timeout_seconds=$TimeoutSeconds }
    if (-not $probeProcess.WaitForExit($TimeoutSeconds * 1000)) { $timedOut=$true; $probeProcess.Kill(); if (-not $probeProcess.WaitForExit(10000)) { throw 'Owned process did not exit within 10s after Kill' } }
    $exitCode = $probeProcess.ExitCode
} catch { $launchError=$_.Exception.ToString() }
finally {
    $env:APPDATA=$oldAppData; $env:LOCALAPPDATA=$oldLocalAppData
    if ($null -ne $probeProcess -and -not $probeProcess.HasExited) { $probeProcess.Kill(); $null=$probeProcess.WaitForExit(10000); $timedOut=$true }
}
$sourcesAfter = @($sourceSet | Sort-Object | ForEach-Object { Source-Record $_ })
$playerAfter = @(Player-Metadata)
$sourceChanges = @()
for ($i=0; $i -lt $sourcesBefore.Count; $i++) {
    if ($sourcesBefore[$i].sha256 -ne $sourcesAfter[$i].sha256 -or $sourcesBefore[$i].bytes -ne $sourcesAfter[$i].bytes -or $sourcesBefore[$i].utc_ticks -ne $sourcesAfter[$i].utc_ticks) { $sourceChanges += $sourcesBefore[$i].path }
}
$playerChanges = @()
for ($i=0; $i -lt $playerBefore.Count; $i++) {
    foreach ($key in @('exists','bytes','utc_ticks')) { if ($playerBefore[$i][$key] -ne $playerAfter[$i][$key]) { $playerChanges += $playerBefore[$i].path; break } }
}
$engineAfter = (Get-FileHash -LiteralPath $enginePath -Algorithm SHA256).Hash
Write-Record 'after.json' @{ sources=$sourcesAfter; player_metadata=$playerAfter; source_changes=$sourceChanges; player_metadata_changes=$playerChanges; engine_sha256=$engineAfter; actual_gui_pid=$ownPid; exit_code=$exitCode; timed_out=$timedOut; launch_error=$launchError; stderr_reviewed=$false; status='PROTECTION_REPORT_NOT_FUNCTIONAL_OR_ART_ACCEPTANCE' }
@{ actual_gui_pid=$ownPid; exit_code=$exitCode; timed_out=$timedOut; source_changes=$sourceChanges.Count; player_metadata_changes=$playerChanges.Count; evidence=$runRoot; launch_error=$launchError } | ConvertTo-Json -Compress
if ($timedOut -or $launchError -or $null -eq $exitCode -or $sourceChanges.Count -or $playerChanges.Count -or $engineAfter -ne $engineSHA) { exit 1 }
exit $exitCode
