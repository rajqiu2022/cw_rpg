param(
 [string]$ProjectRoot='F:\Code\RPG_GAME',
 [string]$SeedInventory='game/build/joint_world_luoyang_20261003_qa/420_luoyang_motion_source_inventory_retry1_20261009/source_inventory.json',
 [ValidateSet('candidate','formal')][string]$Mode='candidate',
 [ValidateSet('geometry','gameplay','save','all')][string]$Stage='all',
 [Parameter(Mandatory=$true)][string]$OutputDirectory
)
# Fresh read-only inventory, not QA/Field/approval. Only the NEW unique BUILD
# evidence is written. No engine, player/settings/import/production mutation.
# The seed is paths only; no historical hash or guard credit is inherited.
$ErrorActionPreference='Stop'
$project=[IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
$game=Join-Path $project 'game'
$build=Join-Path $game 'build\joint_world_luoyang_20261003_qa'
$target=[IO.Path]::GetFullPath($OutputDirectory)
if (-not $target.StartsWith($build+'\',[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $target)) { throw 'Output must be NEW unique QA BUILD child' }
$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$visited=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$directories=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$dynamicLiterals=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$queue=[Collections.Generic.Queue[string]]::new()
$expected=@{}
$parsedRecords=[Collections.Generic.List[object]]::new()
$battleRecords=[Collections.Generic.List[object]]::new()
function Resolve-Source([string]$value) {
 if ($value.StartsWith('res://')) { $value=Join-Path $game $value.Substring(6) }
 elseif (-not [IO.Path]::IsPathRooted($value)) { $value=Join-Path $project $value }
 $path=[IO.Path]::GetFullPath($value)
 if (-not $path.StartsWith($project+'\',[StringComparison]::OrdinalIgnoreCase)) { throw "Outside project source: $path" }
 return $path
}
function Add-Source([string]$value,[bool]$Required=$true) {
 if ([string]::IsNullOrEmpty($value)) { return }
 $path=Resolve-Source $value
 if (Test-Path -LiteralPath $path -PathType Container) { [void]$directories.Add($path); return }
 if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { if ($Required) { throw "Missing required file: $path" }; return }
 if ($seen.Add($path)) { $queue.Enqueue($path) }
}
function Add-Bound([string]$value,[string]$sha) {
 if ($sha -notmatch '^[a-fA-F0-9]{64}$') { throw "Malformed bound SHA: $value" }
 Add-Source $value
 $path=Resolve-Source $value
 if ($expected.ContainsKey($path) -and $expected[$path] -cne $sha.ToUpperInvariant()) { throw "Conflicting bound SHA: $value" }
 $expected[$path]=$sha.ToUpperInvariant()
}
function Read-Bound([string]$value,[string]$sha) {
 Add-Bound $value $sha
 $path=Resolve-Source $value
 if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $sha.ToUpperInvariant()) { throw "Current bound JSON SHA differs: $value" }
 $record=Get-Content -LiteralPath $path -Raw | ConvertFrom-Json -AsHashtable -Depth 100
 if ($record -isnot [Collections.IDictionary]) { throw "JSON record not dictionary: $value" }
 $parsedRecords.Add([ordered]@{path=$value;sha256=$sha;kind='CURRENT_EXPLICIT_CONTRACT_RECORD'})
 # Catalog members become guarded leaves; their JSON contents are never read.
 foreach ($key in @('asset_sha256','source_catalog')) {
  if ($record.Contains($key)) {
   if ($record[$key] -isnot [Collections.IDictionary]) { throw "Invalid $key at $value" }
   foreach ($leaf in $record[$key].Keys) { Add-Bound $leaf $record[$key][$leaf] }
  }
 }
 return $record
}
$seedPath=Resolve-Source $SeedInventory
$seed=Get-Content -LiteralPath $seedPath -Raw | ConvertFrom-Json -AsHashtable -Depth 16
if ($seed.scope -cne 'FRESH_CURRENT_LUOYANG_MOTION_SOURCE_INVENTORY_ONLY' -or $seed.source_count -ne 2930 -or $seed.sources.Count -ne 2930) { throw 'Expected actual ROOT420 seed inventory, paths only' }
foreach ($row in $seed.sources) { Add-Source $row.path }
Add-Source $seedPath
Add-Source $PSCommandPath
$ids=@('ch4_s0_luoyang_gate','ch4_s1_luoyang_yamen','ch4_s2_canal_docks','ch4_s3_luoyang_market')
$patchShas=@('20cb77de45df28def34fdeee5f7c75300182ade0a1f6af338088059e47f05de1','2e1f562c429aabc89ebd38f044192e0f8dd71738147cb51b5fba4f9d6b7b50d4','b4b06110c299bf97dad8eb7134d8b0902135b37bc7c7f4952522ce6f30a5cf23','ba46bfa02e4152918d6696033450bf1f0329be01318f69449a7fad7355a85c84')
$baseShas=@('2818f9fca10d30abbbbd386ff2b26a3d4ed87f300a9b8ef47f882bcb83f7640d','b7bfdd920ba69858b70c9cf77c5d3b65161f14032ae3eb0e1f5f5f0b04385315','5ac079c73a9ab7716c62d7ba540d39a513be93ed17f5feef0effbd2e1ac26cdb','bc100b541f74ddaa49391ccb7e8a5161905f3586c243dc74eded840284f8dc5f')
$groundShas=@('1976d00447c8c399b92c9c2b1abdd1c8ce09d97f45263e7449b726f16bbaa3d3','1fd971708ac0375e557749f8175b804ac58d71409e717e7be88cab7eb78e181f','aa2aba7052cb289511eb83d68e6135d96e4001c2950763bb9309e2cdbac2e744','559c0ffc87f822873e9fbf04aa9b0ce49d98794a806b29a6efd75c16e3847fae')
Add-Bound 'game/scripts/city/luoyang_enclosure_v11_candidate_contract.gd' 'D112F9E7867D612596AB1EAD2428000749EA44F62A26433A73E170480AF6EC51'
for ($i=0;$i -lt 4;$i++) {
 $id=$ids[$i]; $root="res://art/maps/luoyang_enclosure_v11/$id/"
 $basePath="res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/$id/art_contract.json"
 $patch=Read-Bound ($root+'art_patch.json') $patchShas[$i]
 if ($patch.canonical_scene_id -cne $id -or $patch.base_manifest_path -cne $basePath -or $patch.base_manifest_sha256 -cne $baseShas[$i] -or $patch.export_plan_path -cne ($root+'export_plan.json')) { throw "Current patch identity/binding differs: $id" }
 Add-Bound $patch.export_plan_path $patch.export_plan_sha256
 $base=Read-Bound $basePath $baseShas[$i]
 $ground=Read-Bound ($root+'ground_v14/root_ground_v14_02/ground_capture.json') $groundShas[$i]
 foreach ($record in @($patch,$base,$ground)) {
  foreach ($key in @('ground_path','walk_path','raw_walk_path')) { if ($record[$key] -is [string] -and $record[$key]) { Add-Source $record[$key] } }
  foreach ($object in @($record.objects)) {
   if ($null -eq $object) { continue }
   foreach ($key in @('texture','source','native_mesh','native_material')) { if ($object[$key] -is [string] -and $object[$key]) { Add-Source $object[$key] } }
  }
 }
 Add-Source "game/data/scenes/luoyang_enclosure_v11_candidates/$id.tres"
 Add-Source "game/data/maps/luoyang_enclosure_v11_candidates/${id}_layout.tres"
 Add-Source "game/data/scenes/$id.tres" # formal write protection even in candidate mode
}
if ($parsedRecords.Count -ne 12) { throw 'Exactly twelve current JSON records required' }
$seeds=@(
 'game/tests/test_luoyang_enclosure_v11_city_only_fresh_20261009.gd',
 'game/tests/helpers/luoyang_enclosure_v11_city_only_phase.gd',
 'game/tests/helpers/luoyang_enclosure_v11_city_only_current_save.gd',
 'game/tests/helpers/luoyang_enclosure_v11_city_only_raw.gd',
 'game/tests/helpers/luoyang_enclosure_v11_city_only_target_raw.gd',
 'game/tests/test_luoyang_city3_motion_guard_units_retry1_20261009.gd',
 'game/tests/test_luoyang_shop_corner_motion_repair_focused_retry1_20261009.gd',
 'game/project.godot','game/scenes/player.tscn','game/scenes/field_walkable.tscn',
 'game/scenes/npc_node.tscn','game/scenes/exit_zone.tscn',
 'game/art/fonts/default_theme.tres','game/art/fonts/LXGWWenKaiLite-Regular.ttf',
 'game/scripts/autoload/audio_manager.gd','game/scripts/autoload/cursor_manager.gd',
 'game/scripts/battle/battle_controller.gd'
)
foreach ($path in $seeds) { Add-Source $path }
# Finite known gameplay families, not a directory walk or arbitrary JSON graph.
if ($Stage -in @('gameplay','all')) {
 foreach ($bounty in @('luoyang_red_scar','luoyang_seal_thief')) {
  $path="game/data/bounties/$bounty.tres"; Add-Source $path
  $text=[IO.File]::ReadAllText((Resolve-Source $path))
  $enemyMatch=[regex]::Match($text,'(?m)^enemy_ids\s*=\s*Array\[StringName\]\(\[([^\]]+)\]\)')
  if (-not $enemyMatch.Success) { throw "Missing authored enemy_ids: $bounty" }
  $enemyIds=@([regex]::Matches($enemyMatch.Groups[1].Value,'&"([a-z0-9_]+)"') | ForEach-Object {$_.Groups[1].Value})
  foreach ($enemy in $enemyIds) {
   $enemyPath="game/data/enemies/$enemy.tres"; Add-Source $enemyPath
   $enemyText=[IO.File]::ReadAllText((Resolve-Source $enemyPath))
   $skillMatch=[regex]::Match($enemyText,'(?m)^skill_ids\s*=\s*Array\[StringName\]\(\[([^\]]+)\]\)')
   foreach ($skill in [regex]::Matches($skillMatch.Groups[1].Value,'&"([a-z0-9_]+)"')) { Add-Source ("game/data/skills/"+$skill.Groups[1].Value+'.tres') }
  }
  $locations=@([regex]::Matches($text,'"scene_id":&"([a-z0-9_]+)"') | ForEach-Object {$_.Groups[1].Value})
  foreach ($id in $locations) { Add-Source "game/data/scenes/$id.tres" }
  $battleRecords.Add([ordered]@{bounty_id=$bounty;definition=$path;enemy_ids=$enemyIds;possible_location_ids=$locations;all_locations_guarded_before_random_selection=$true})
 }
 # BattleController._load_standard_frames: exactly five states x four frames.
 $families=@(@('standard_v5/lengguyun','lengguyun'),@('standard_v2/thug_lone','thug_lone'))
 foreach ($weapon in @('sword','dao','staff','palm','hidden')) {
  $version=if ($weapon -in @('sword','dao')) {'weapon_variants_v4'} else {'weapon_variants_v3'}
  $families+=,@("$version/lengguyun/$weapon","lengguyun_$weapon")
 }
 foreach ($family in $families) {
  foreach ($state in @('ready','move','attack','hit','defeat')) {
   foreach ($frame in 1..4) { Add-Source ('game/art/sprites/battle/{0}/{1}_{2}_{3:00}.png' -f $family[0],$family[1],$state,$frame) }
  }
 }
}
# All forty possible current overworld Player strips, even if only one is drawn.
foreach ($family in @('sword','dao','staff','palm','hidden')) {
 foreach ($state in @('idle','walk')) {
  foreach ($direction in @('up','down','left','right')) {
   $frames=if ($state -eq 'idle') {4} else {8}
   Add-Source "game/art/characters/weapon_variants/lengguyun/v7_idle_stable/$family/lengguyun_${family}_${state}_${direction}_25d_${frames}f.png"
  }
 }
}
while ($queue.Count -gt 0) {
 $path=$queue.Dequeue()
 if (-not $visited.Add($path)) { continue }
 if (Test-Path -LiteralPath ($path+'.import') -PathType Leaf) { Add-Source ($path+'.import') }
 $extension=[IO.Path]::GetExtension($path).ToLowerInvariant()
 if ($extension -notin @('.gd','.tscn','.tres','.godot','.gdshader','.gdshaderinc','.import','.gltf')) { continue }
 $text=[IO.File]::ReadAllText($path)
 if ($extension -eq '.gd') {
  foreach ($match in [regex]::Matches($text,'(res://[^"''\\\r\n]+\.gd)(?=["''\r\n])')) { Add-Source $match.Groups[1].Value }
  foreach ($match in [regex]::Matches($text,'(?:preload|load)\("(res://[^"\r\n]+)"\)')) { Add-Source $match.Groups[1].Value }
  # Complete asset literals used by startup/UI/Field/battle are guarded. Paths
  # with interpolation remain explicit unclaimed, not converted to fake files.
  $runtimeAssetText=$path -match '\\scripts\\(autoload|ui|battle|field|city)\\' -or $path -match '\\scripts\\player\.gd$' -or $path -match '\\tests\\helpers\\luoyang_enclosure_v11_'
  foreach ($match in [regex]::Matches($(if ($runtimeAssetText) {$text} else {''}),'"(res://[^"\r\n]+\.(?:png|jpg|jpeg|svg|ttf|otf|wav|ogg|mp3|tres|tscn|gdshader|gdshaderinc|cfg|json))"')) {
   $value=$match.Groups[1].Value
   if ($value.Contains('%') -or $value.Contains('{')) { [void]$dynamicLiterals.Add($value); continue }
   Add-Source $value
  }
 } else {
  # .import captures every remap.path.* and deps.dest_files leaf, including
  # compressed variants; no ConfigFile generic remap.path read is attempted.
  foreach ($match in [regex]::Matches($text,'"(res://[^"\r\n]+)"')) { Add-Source $match.Groups[1].Value }
  if ($extension -eq '.gltf') {
   foreach ($match in [regex]::Matches($text,'"uri"\s*:\s*"([^"\r\n]+)"')) {
    $uri=$match.Groups[1].Value
    if ($uri.StartsWith('data:')) { continue }
    Add-Source (Join-Path (Split-Path -Parent $path) $uri)
   }
  }
 }
 # Existing NPC runtime aliases selected by npc_node's direction/state logic.
 if ($path -match '\\art\\characters\\' -and $path -match '_(idle|walk)_(up|down|left|right)_') {
  # Mirrors npc_node's candidate names, not a directory enumeration: it does
  # not change 4f to 8f. Optional siblings absent on disk claim no file guard.
  foreach ($direction in @('up','down','left','right')) {
   $directional=$path -replace '_(up|down|left|right)_',("_${direction}_")
   $variants=@($directional)
   foreach ($version in 2..9) { if ($directional.Contains("_v${version}_")) { $variants+= $directional.Replace("_v${version}_",'_') } }
   foreach ($variant in $variants) {
    Add-Source $variant $false
    Add-Source ($variant.Replace('_idle_','_walk_')) $false
    Add-Source ($variant.Replace('_walk_','_idle_')) $false
   }
  }
 }
}
$records=[Collections.Generic.List[object]]::new()
[long]$totalBytes=0
foreach ($path in @($seen | Sort-Object)) {
 $item=Get-Item -LiteralPath $path
 $sha=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
 if ($expected.ContainsKey($path) -and $sha -cne $expected[$path]) { throw "Frozen catalog/source SHA differs: $path" }
 $totalBytes+=[long]$item.Length
 $records.Add([ordered]@{path=$item.FullName;project_relative=$item.FullName.Substring($project.Length+1).Replace('\','/');bytes=$item.Length;sha256=$sha;last_write_utc_ticks=$item.LastWriteTimeUtc.Ticks})
}
$result=[ordered]@{
 scope='FRESH_CURRENT_LUOYANG_FOUR_DISTRICTS_SOURCE_INVENTORY_ONLY';mode=$Mode;stage=$Stage
 collected_utc=[DateTime]::UtcNow.ToString('o');seed_path=$seedPath;seed_sha256=(Get-FileHash -LiteralPath $seedPath -Algorithm SHA256).Hash
 seed_credit_inherited=$false;engine_executed=$false;historical_json_graph_expanded=$false
 current_json_records=$parsedRecords.ToArray();current_json_record_count=$parsedRecords.Count
 current_bounty_consumed_leaf_expansion=$battleRecords.ToArray();source_count=$records.Count;source_bytes=$totalBytes
 source_paths=@($records | ForEach-Object {$_.project_relative});sources=$records.ToArray()
 excluded_existing_directories=@($directories | Sort-Object);excluded_directory_file_guard_claimed=$false
 unclaimed_interpolated_literals=@($dynamicLiterals | Sort-Object)
 limitations=@('No Field/geometry/gameplay/save/audio approval','Caller must snapshot all15 normal player files and active slot before engine launch and after natural exit','Only current12 contract JSON parsed; catalog JSON leaves not recursively expanded','New unknown runtime paths not covered unless present in this prelaunch source list','Existing directory literals excluded; no directory-recursion/file-guard credit')
}
New-Item -ItemType Directory -Path $target | Out-Null
$output=Join-Path $target 'source_inventory.json'
[IO.File]::WriteAllText($output,($result | ConvertTo-Json -Depth 16),[Text.UTF8Encoding]::new($false))
$back=Get-Content -LiteralPath $output -Raw | ConvertFrom-Json -AsHashtable -Depth 16
if ($back.source_count -ne $records.Count -or $back.sources.Count -ne $records.Count -or $back.source_bytes -ne $totalBytes -or $back.current_json_record_count -ne 12) { throw 'Inventory readback mismatch' }
[pscustomobject]@{path=$output;sha256=(Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash;source_count=$records.Count;source_bytes=$totalBytes;engine_executed=$false}
