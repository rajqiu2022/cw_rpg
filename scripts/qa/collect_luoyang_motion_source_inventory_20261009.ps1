param(
    [string]$ProjectRoot = 'F:\Code\RPG_GAME',
    [string]$BaselineBefore = 'game/build/joint_world_luoyang_20261003_qa/419_luoyang_shop_corner_readonly_headless_20261009/before.json',
    [Parameter(Mandatory=$true)][string]$OutputDirectory
)
# Read-only source collection, except NEW unique BUILD evidence JSON. No engine,
# network, player-file write, cache update, settings or production mutation.
# The 419 list is a seed list only: all SHA/bytes/ticks are freshly read now.
# JSON catalogs are NOT traversed. Seen files and visited text are independent.
$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
$game = Join-Path $project 'game'
$build = Join-Path $game 'build\joint_world_luoyang_20261003_qa'
$target = [IO.Path]::GetFullPath($OutputDirectory)
if (-not $target.StartsWith($build + '\', [StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $target)) { throw 'Output must be a NEW unique child of the QA BUILD evidence domain' }
$baseline = [IO.Path]::GetFullPath((Join-Path $project $BaselineBefore))
$old = Get-Content -LiteralPath $baseline -Raw | ConvertFrom-Json -AsHashtable -Depth 100
if (-not $old.sources -or $old.sources.Count -lt 1000) { throw 'Expected actual ROOT419 before source list' }
$seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$visited = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$excludedDirectories = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$queue = [Collections.Generic.Queue[string]]::new()
function Add-Source([string]$value, [bool]$Required = $true) {
    if ([string]::IsNullOrEmpty($value)) { return }
    if ($value.StartsWith('res://')) { $value = Join-Path $game $value.Substring(6) }
    elseif (-not [IO.Path]::IsPathRooted($value)) { $value = Join-Path $project $value }
    $absolute = [IO.Path]::GetFullPath($value)
    if (-not $absolute.StartsWith($project+'\',[StringComparison]::OrdinalIgnoreCase)) { throw "Outside project source: $absolute" }
    # Some source literals name asset directories rather than input files.
    # Exclude only a directory that actually exists; never recurse or hash it,
    # and never turn a genuinely missing required file into an exclusion.
    if (Test-Path -LiteralPath $absolute -PathType Container) {
        [void]$excludedDirectories.Add($absolute)
        return
    }
    if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) {
        if ($Required) { throw "Missing required source: $absolute" }
        return
    }
    if ($seen.Add($absolute)) { $queue.Enqueue($absolute) }
}
foreach ($row in $old.sources) { Add-Source $row.path }
Add-Source $baseline
Add-Source $PSCommandPath
$seeds = @(
 'game/tests/test_luoyang_city3_motion_guard_units_20261009.gd',
 'game/tests/test_luoyang_shop_corner_motion_repair_focused_20261009.gd',
 'game/scripts/city/luoyang_city3_motion_guard_20261009.gd',
 'game/scripts/field/field_walkable_controller.gd',
 'game/project.godot', 'game/scenes/player.tscn', 'game/scenes/field_walkable.tscn',
 'game/scenes/npc_node.tscn', 'game/scenes/exit_zone.tscn',
 'game/art/fonts/default_theme.tres','game/art/fonts/LXGWWenKaiLite-Regular.ttf',
 'game/scripts/autoload/audio_manager.gd','game/scripts/autoload/cursor_manager.gd',
 'game/data/scenes/luoyang_enclosure_v11_candidates/ch4_s3_luoyang_market.tres'
)
foreach ($seed in $seeds) { Add-Source $seed }
while ($queue.Count -gt 0) {
    $path = $queue.Dequeue()
    # An old-list seed still gets scanned once in THIS invocation.
    if (-not $visited.Add($path)) { continue }
    if (Test-Path -LiteralPath ($path+'.import') -PathType Leaf) { Add-Source ($path+'.import') }
    $extension = [IO.Path]::GetExtension($path).ToLowerInvariant()
    if ($extension -notin @('.gd','.tscn','.tres','.godot','.gdshader','.gdshaderinc','.import')) { continue }
    $text = [IO.File]::ReadAllText($path)
    if ($extension -eq '.gd') {
        # Script literal closure is exact .gd; never .gdshader truncated to .gd.
        $pattern = '(res://[^"''\\\r\n]+\.gd)(?=["''\r\n])'
        foreach ($match in [regex]::Matches($text,$pattern)) { Add-Source $match.Groups[1].Value }
        $pattern = '(?:preload|load)\("(res://[^"\r\n]+)"\)'
        foreach ($match in [regex]::Matches($text,$pattern)) { Add-Source $match.Groups[1].Value }
        if ($path -match '\\scripts\\(autoload|ui)\\') {
            $pattern = '(res://[^"\r\n]+\.(?:png|svg|ttf|otf|wav|ogg|mp3|json|cfg|tres|tscn))'
            foreach ($match in [regex]::Matches($text,$pattern)) { Add-Source $match.Groups[1].Value $false }
        }
    } else {
        foreach ($match in [regex]::Matches($text,'(res://[^"\r\n]+)')) { Add-Source $match.Groups[1].Value }
    }
}
# Forty possible current Player strips; all must already exist before runtime.
foreach ($family in @('sword','dao','staff','palm','hidden')) {
 foreach ($state in @('idle','walk')) {
  foreach ($direction in @('up','down','left','right')) {
   $frames = if ($state -eq 'idle') {4} else {8}
   $asset = "game/art/characters/weapon_variants/lengguyun/v7_idle_stable/$family/lengguyun_${family}_${state}_${direction}_25d_${frames}f.png"
   Add-Source $asset
   Add-Source ($asset+'.import')
   foreach ($match in [regex]::Matches([IO.File]::ReadAllText((Join-Path $project ($asset+'.import'))),'(res://[^"\r\n]+)')) { Add-Source $match.Groups[1].Value }
  }
 }
}
$records = @($seen | Sort-Object | ForEach-Object {
    $item = Get-Item -LiteralPath $_
    [ordered]@{path=$item.FullName; project_relative=$item.FullName.Substring($project.Length+1).Replace('\','/'); bytes=$item.Length; sha256=(Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash; last_write_utc_ticks=$item.LastWriteTimeUtc.Ticks}
})
$result = [ordered]@{
 scope='FRESH_CURRENT_LUOYANG_MOTION_SOURCE_INVENTORY_ONLY'; collected_utc=[DateTime]::UtcNow.ToString('o')
 historical_419_credit_inherited=$false; baseline_before_path=$baseline; baseline_before_sha256=(Get-FileHash -LiteralPath $baseline).Hash
 source_count=$records.Count; source_bytes=($records|Measure-Object -Property bytes -Sum).Sum
 source_paths=@($records|ForEach-Object {$_.project_relative}); sources=$records
 excluded_existing_directories=@($excludedDirectories|Sort-Object)
 excluded_directory_file_guard_claimed=$false
 limitations=@('Not a Field/audio/route test','Not a player snapshot; caller must separately protect all15 player files and active slot before/after','No historical JSON/catalog graph recursion','Dynamically constructed unknown future assets are not claimed covered; actual runtime paths must be present in first snapshot')
}
New-Item -ItemType Directory -Path $target | Out-Null
$output = Join-Path $target 'source_inventory.json'
$encoded = $result | ConvertTo-Json -Depth 12
[IO.File]::WriteAllText($output,$encoded,[Text.UTF8Encoding]::new($false))
$readback=Get-Content -LiteralPath $output -Raw|ConvertFrom-Json -AsHashtable -Depth 12
if ($readback.source_count -ne $records.Count -or $readback.sources.Count -ne $records.Count) { throw 'Inventory readback count mismatch' }
[pscustomobject]@{path=$output;sha256=(Get-FileHash -LiteralPath $output).Hash;source_count=$records.Count;source_bytes=$result.source_bytes;engine_executed=$false}
