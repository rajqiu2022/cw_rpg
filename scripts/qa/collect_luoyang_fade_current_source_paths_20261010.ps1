param(
 [string]$ProjectRoot='F:\Code\RPG_GAME',
 [Parameter(Mandatory=$true)][string]$OutputDirectory,
 [string[]]$AdditionalSourcePaths=@()
)
# PATH seeds only: old row hashes/ticks are NEVER current identity authority.
# No engine/import/publisher/approval; only one NEW unique QA BUILD inventory.
$ErrorActionPreference='Stop'
$project=[IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
$game=Join-Path $project 'game'
$build=Join-Path $game 'build\joint_world_luoyang_20261003_qa'
$target=[IO.Path]::GetFullPath($OutputDirectory)
if (-not $target.StartsWith($build+'\',[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $target)) {throw 'NEW unique QA BUILD child required'}
$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$visited=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$queue=[Collections.Generic.Queue[string]]::new()
$excluded=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$dynamicPrefixes=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$seedProofs=[Collections.Generic.List[object]]::new()
function Resolve-Source([string]$value) {
 if ($value.StartsWith('res://',[StringComparison]::Ordinal)) {$value=Join-Path $game $value.Substring(6)}
 elseif (-not [IO.Path]::IsPathRooted($value)) {$value=Join-Path $project $value}
 $path=[IO.Path]::GetFullPath($value)
 if (-not $path.StartsWith($project+'\',[StringComparison]::OrdinalIgnoreCase)) {throw "Source outside project: $value"}
 return $path
}
function Add-Leaf([string]$value,[bool]$expand=$false) {
 $path=Resolve-Source $value
 if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {throw "Missing required leaf: $path"}
 [void]$seen.Add($path)
 if ($expand) {$queue.Enqueue($path)}
 # Every actual compiled remap/deps leaf, not just optional remap.path.
 if (Test-Path -LiteralPath ($path+'.import') -PathType Leaf) {
  $import=$path+'.import';[void]$seen.Add($import)
  foreach ($m in [regex]::Matches([IO.File]::ReadAllText($import),'"(res://[.]godot/imported/[^"\r\n]+)"')) {
   $compiled=Resolve-Source $m.Groups[1].Value
   if (-not (Test-Path -LiteralPath $compiled -PathType Leaf)) {throw "Missing compiled import leaf: $compiled"}
   [void]$seen.Add($compiled)
  }
 }
}
$seeds=@(
 @{relative='455_be0_strict4624_candidate_save_headless_20261010/before.json';sha='A54A387722499B7A617FE2F05D9D74A681821F202A61A64980EA49B695492619';field='sources';count=4624},
 @{relative='424_luoyang_full_source_inventory_20261009/source_inventory.json';sha='29E9F1B12D984134BED7E8AE292D0D4F68BA4706E053A56997A9A978BAAD99A6';field='sources';count=4381},
 @{relative='428_luoyang_finite_source_inventory_retry3_20261009/source_inventory.json';sha='7CC2EF19AE0329DBEA384EE8084ED75FCFF75B0EB9C0CBA3CA1D6AB455ED0C23';field='sources';count=4614}
)
foreach ($seed in $seeds) {
 $path=Join-Path $build $seed.relative
 if ((Get-FileHash -LiteralPath $path).Hash -cne $seed.sha) {throw 'Fixed path seed document differs'}
 $record=[IO.File]::ReadAllText($path)|ConvertFrom-Json -AsHashtable -Depth 100
 if ($record -isnot [Collections.IDictionary] -or $record[$seed.field] -isnot [array] -or $record[$seed.field].Count -ne $seed.count) {throw 'Typed seed rows/count differ'}
 $unique=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 foreach ($row in $record[$seed.field]) {
  if ($row -isnot [Collections.IDictionary] -or $row.path -isnot [string]) {throw 'Typed path seed row required'}
  $leaf=Resolve-Source $row.path
  if (-not $unique.Add($leaf)) {throw 'Duplicate within fixed path seed'}
  Add-Leaf $leaf
 }
 Add-Leaf $path
 $seedProofs.Add(@{path=$path;sha256=$seed.sha;path_count=$unique.Count;old_digest_credit=$false})
}
$roots=@(
 'game/project.godot',
 'game/tests/test_luoyang_enclosure_v11_city_only_fresh_20261009.gd',
 'game/tests/helpers/luoyang_enclosure_v11_city_only_phase.gd',
 'game/tests/helpers/luoyang_enclosure_v11_fade_native_npc_band_probe_20261010.gd',
 'game/tests/test_luoyang_fade_current_runtime_bindings_units_20261010.gd',
 'game/scripts/field/field_walkable_controller.gd',
 'game/scripts/city/luoyang_enclosure_building_fade_runtime_20261010.gd',
 'game/scripts/city/luoyang_enclosure_building_fade_preview_20261010.gd',
 'scripts/qa/prepare_luoyang_city_only_actual_six_approval_draft_retry12_20261010.ps1',
 'scripts/qa/test_luoyang_fade_current_six_binding_units_20261010.ps1',
 'scripts/qa/run_luoyang_city_only_current_protected_20261010.ps1'
)
foreach ($root in $roots) {Add-Leaf $root $true}
Add-Leaf $PSCommandPath
foreach ($extra in $AdditionalSourcePaths) {Add-Leaf $extra $true}
$ids=@('ch4_s0_luoyang_gate','ch4_s1_luoyang_yamen','ch4_s2_canal_docks','ch4_s3_luoyang_market')
foreach ($id in $ids) {
 foreach ($path in @("game/data/scenes/$id.tres","game/data/scenes/luoyang_enclosure_v11_candidates/$id.tres","game/data/maps/luoyang_enclosure_v11_candidates/$($id)_layout.tres","game/data/maps/luoyang_v3_legacy/$($id)_scene.tres","game/data/maps/luoyang_v3_legacy/$($id)_layout.tres")) {Add-Leaf $path $true}
}
# Finite startup dynamic leaves, never a historical graph.
foreach ($directory in @('bounties','quests','items','equipment','skills')) {
 foreach ($leaf in Get-ChildItem -LiteralPath (Join-Path $game ('data/'+$directory)) -Filter '*.tres' -File) {Add-Leaf $leaf.FullName $true}
}
while ($queue.Count -gt 0) {
 $path=$queue.Dequeue()
 if (-not $visited.Add($path)) {continue}
 if ([IO.Path]::GetExtension($path).ToLowerInvariant() -notin @('.gd','.tscn','.tres','.godot')) {continue}
 foreach ($m in [regex]::Matches([IO.File]::ReadAllText($path),'"(res://[^"\r\n]+)"')) {
  $value=$m.Groups[1].Value
  if ($value.Contains('%') -or $value.EndsWith('/') -or $value -ceq 'res://') {[void]$dynamicPrefixes.Add($value);continue}
  $child=Resolve-Source $value
  if (Test-Path -LiteralPath $child -PathType Container) {[void]$excluded.Add($child);continue}
  if ([IO.Path]::GetExtension($child) -notin @('.gd','.gdshader','.tscn','.tres','.png','.jpg','.jpeg','.wav','.ogg','.mp3','.ttf','.otf','.json','.res','.ctex','.godot')) {[void]$dynamicPrefixes.Add($value);continue}
  Add-Leaf $child $true
 }
}
$records=[Collections.Generic.List[object]]::new()
[long]$bytes=0
foreach ($path in @($seen|Sort-Object)) {
 $item=Get-Item -LiteralPath $path
 $row=[ordered]@{path=$item.FullName;project_relative=$item.FullName.Substring($project.Length+1).Replace('\','/');exists=$true;bytes=[long]$item.Length;sha256=(Get-FileHash -LiteralPath $path).Hash;utc_ticks=$item.LastWriteTimeUtc.Ticks.ToString([Globalization.CultureInfo]::InvariantCulture)}
 $records.Add($row);$bytes+=$row.bytes
}
$result=[ordered]@{scope='CURRENT_FADE_CITY_ONLY_FRESH_SOURCE_PATHS_NOT_APPROVAL';engine_executed=$false;old_digest_credit=$false;collected_utc=[DateTime]::UtcNow.ToString('o');seed_provenance=$seedProofs.ToArray();source_count=$records.Count;source_bytes=$bytes;sources=$records.ToArray();source_paths=@($records|ForEach-Object {$_.project_relative});excluded_existing_directories=@($excluded|Sort-Object);excluded_dynamic_prefixes=@($dynamicPrefixes|Sort-Object);historical_json_graph_expanded=$false;limitations=@('Paths only; wrapper freshly hashes/copies before every launch','Bounded12 art catalogs use seed leaves; no JSON graph traversal','Directory/prefix exclusions are NOT file-guard credit','No Field/audio/six/visual/approval or player snapshot credit')}
New-Item -ItemType Directory -Path $target|Out-Null
$output=Join-Path $target 'source_paths.json'
[IO.File]::WriteAllText($output,($result|ConvertTo-Json -Depth 100),[Text.UTF8Encoding]::new($false))
$back=[IO.File]::ReadAllText($output)|ConvertFrom-Json -AsHashtable -Depth 100
if ($back.source_count -ne $records.Count -or $back.source_paths.Count -ne $records.Count -or $back.source_bytes -ne $bytes) {throw 'Fresh path inventory readback failed'}
[pscustomobject]@{path=$output;sha256=(Get-FileHash -LiteralPath $output).Hash;source_count=$records.Count;source_bytes=$bytes;engine_executed=$false}

