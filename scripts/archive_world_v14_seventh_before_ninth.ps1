$ErrorActionPreference = 'Stop'
$workspace = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$outPath = [IO.Path]::GetFullPath((Join-Path $workspace 'game/art/maps/world_map_v14'))
$archivePath = [IO.Path]::GetFullPath((Join-Path $workspace 'game/build/world_map_v14_seventh_failed_before_ninth'))
$workspacePrefix = $workspace.TrimEnd('\') + '\'
if (-not $outPath.StartsWith($workspacePrefix, [StringComparison]::OrdinalIgnoreCase) -or
    -not $archivePath.StartsWith($workspacePrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Resolved archive paths escaped the workspace.'
}
if (-not (Test-Path -LiteralPath $outPath -PathType Container)) { throw 'Seventh OUT missing.' }
if (Test-Path -LiteralPath $archivePath) { throw 'Archive already exists; never overwrite evidence.' }
$formalPath = Join-Path $workspace 'game/data/scenes/world_map_jianghu.tres'
$mainPath = Join-Path $workspace 'game/scripts/dev/build_world_map_native_full_v14.gd'
if ((Get-FileHash -LiteralPath $formalPath -Algorithm SHA256).Hash -ne '09FA89449B1792063E66AD488AA2F60671AA00DA2193E5C68ACB861DF14D71D5') {
    throw 'Formal v12 is not the frozen source.'
}
if ((Get-FileHash -LiteralPath $mainPath -Algorithm SHA256).Hash -ne 'B5B4283EA770ADC1C567DBDF421DA796760D4B331CA783A7A58BE8938A99E81E') {
    throw 'Main source is not the actual seventh executed source.'
}
$manifest = Get-Content -LiteralPath (Join-Path $outPath 'manifest.json') -Raw | ConvertFrom-Json
if ($manifest.capture_iteration -ne 7 -or $manifest.production_approved -ne $false) { throw 'Not the failed seventh candidate.' }
$files = @(Get-ChildItem -LiteralPath $outPath -File -Recurse | ForEach-Object {
    [pscustomobject]@{
        relative = $_.FullName.Substring($outPath.Length + 1)
        size = $_.Length
        sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
    }
})
$null = New-Item -ItemType Directory -Path $archivePath
$sourceCopies = @(
    'game/scripts/dev/build_world_map_native_full_v14.gd',
    'game/scripts/dev/world_map_v14_seventh_native_surface.gd',
    'game/data/scenes/world_map_jianghu_v14.tres',
    'game/data/maps/world_map_jianghu_layout_v14.tres',
    'game/data/background_sets/world_map_jianghu_v14_streamed.tres'
)
$sourceRecords = @()
foreach ($relative in $sourceCopies) {
    $source = Join-Path $workspace $relative
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Missing snapshot source: $relative" }
    $destination = Join-Path $archivePath $relative
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force
    Copy-Item -LiteralPath $source -Destination $destination
    $sourceRecords += [pscustomobject]@{ path = $relative; sha256 = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash }
}
# Recoverable move, not deletion. Both absolute paths have been validated above.
$archivedOut = Join-Path $archivePath 'original_out'
Move-Item -LiteralPath $outPath -Destination $archivedOut
foreach ($record in $files) {
    $actual = Join-Path $archivedOut $record.relative
    if ((Get-Item -LiteralPath $actual).Length -ne $record.size -or
        (Get-FileHash -LiteralPath $actual -Algorithm SHA256).Hash -ne $record.sha256) {
        throw "Archived bytes differ: $($record.relative)"
    }
}
$evidence = [ordered]@{
    status = 'SEVENTH_VISUAL_FAIL_RETAINED_NO_FORMAL_CHANGE'
    recoverable_archive = $archivePath
    original_out = $outPath
    source_snapshots = $sourceRecords
    files = $files
    file_count = $files.Count
    all_bytes_verified_after_move = $true
    formal_sha256 = (Get-FileHash -LiteralPath $formalPath -Algorithm SHA256).Hash
}
$evidence | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $archivePath 'archive_evidence.json') -Encoding utf8
[pscustomobject]@{ Archive = $archivePath; Files = $files.Count; Verified = $true } | ConvertTo-Json
