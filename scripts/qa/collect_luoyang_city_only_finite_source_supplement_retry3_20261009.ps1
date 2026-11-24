param(
 [string]$ProjectRoot='F:\Code\RPG_GAME',
 [Parameter(Mandatory=$true)][string]$OutputDirectory
)
# NEW bounded supplement over actual ROOT427 paths, freshly hashed here. No
# engine, import/settings/player/production mutation or past snapshot credit.
# Only current explicitly reached SceneDefs encounter fields and twelve menu
# PNG leaves expand semantics. Never traverse a scene/world/history JSON graph.
$ErrorActionPreference='Stop'
$project=[IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
$game=Join-Path $project 'game'
$build=Join-Path $game 'build\joint_world_luoyang_20261003_qa'
$target=[IO.Path]::GetFullPath($OutputDirectory)
if (-not $target.StartsWith($build+'\',[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $target)) { throw 'Output must be a NEW unique QA BUILD child' }
$seed=Join-Path $build '427_luoyang_full_gameplay_source_inventory_20261009\source_inventory.json'
$seedSHA='7A339B41B596DF3A6B3F8BA9168C38C0CB6CEE5A5F7DC967D825CFECAE17EA89'
if ((Get-FileHash -LiteralPath $seed -Algorithm SHA256).Hash -cne $seedSHA) { throw 'Actual ROOT427 inventory binding differs' }
$prior=Get-Content -LiteralPath $seed -Raw | ConvertFrom-Json -AsHashtable -Depth 16
if ($prior.scope -cne 'FRESH_CURRENT_LUOYANG_FOUR_DISTRICTS_SOURCE_INVENTORY_ONLY' -or $prior.mode -cne 'candidate' -or $prior.stage -cne 'all' -or $prior.source_count -ne 4568 -or $prior.sources.Count -ne 4568) { throw 'Actual ROOT427 inventory schema differs' }
$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$visited=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$enemyPaths=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$directories=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$queue=[Collections.Generic.Queue[string]]::new()
$sceneRecords=[Collections.Generic.List[object]]::new()
$menuPaths=[Collections.Generic.List[string]]::new()
$old=@{}
function Resolve-Source([string]$value) {
 if ($value.StartsWith('res://')) { $value=Join-Path $game $value.Substring(6) }
 elseif (-not [IO.Path]::IsPathRooted($value)) { $value=Join-Path $project $value }
 $path=[IO.Path]::GetFullPath($value)
 if (-not $path.StartsWith($project+'\',[StringComparison]::OrdinalIgnoreCase)) { throw "Outside project source: $path" }
 return $path
}
function Add-Source([string]$value) {
 if ([string]::IsNullOrEmpty($value)) { return }
 $path=Resolve-Source $value
 if (Test-Path -LiteralPath $path -PathType Container) { [void]$directories.Add($path); return }
 if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing required file: $path" }
 if ($seen.Add($path)) { $queue.Enqueue($path) }
}
function Add-Enemy([string]$id) {
 if ($id -notmatch '^[a-z0-9_]+$') { throw "Invalid actual encounter enemy ID: $id" }
 $path=Resolve-Source "game/data/enemies/$id.tres"
 Add-Source $path
 if ($enemyPaths.Add($path) -and $visited.Remove($path)) { $queue.Enqueue($path) }
}
foreach ($row in $prior.sources) {
 Add-Source $row.path
 $path=Resolve-Source $row.path
 if ($old.ContainsKey($path)) { throw 'Duplicate original source path' }
 $old[$path]=$row
}
Add-Source $seed
Add-Source $PSCommandPath
$cityIds=@('ch4_s0_luoyang_gate','ch4_s1_luoyang_yamen','ch4_s2_canal_docks','ch4_s3_luoyang_market')
$scenePaths=@('game/data/scenes/linxi_tutorial.tres','game/data/scenes/ch4_s4_ancient_temple.tres','game/data/scenes/openworld_bianzhou_old_post.tres','game/data/scenes/openworld_xiangzhou_mine_valley.tres','game/data/scenes/world_map_jianghu.tres')
foreach ($id in $cityIds) {
 $scenePaths+="game/data/scenes/luoyang_enclosure_v11_candidates/$id.tres"
 $scenePaths+="game/data/maps/luoyang_v3_legacy/${id}_scene.tres"
}
foreach ($scenePath in $scenePaths) {
 Add-Source $scenePath
 $text=[IO.File]::ReadAllText((Resolve-Source $scenePath))
 $groups=[regex]::Match($text,'(?m)^encounter_groups\s*=([^\r\n]*)')
 $enemyIds=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
 if ($groups.Success) {
  foreach ($member in [regex]::Matches($groups.Groups[1].Value,'"enemy_ids"\s*:\s*\[([^\]]*)\]')) {
   foreach ($entry in [regex]::Matches($member.Groups[1].Value,'&?"([a-z0-9_]+)"')) { [void]$enemyIds.Add($entry.Groups[1].Value); Add-Enemy $entry.Groups[1].Value }
  }
  # Refuse an authored nonempty syntax this narrow current reader did not parse.
  if ($groups.Groups[1].Value -notmatch '^\s*(?:Array\[Dictionary\]\()?\[\]\)?\s*$' -and $enemyIds.Count -eq 0) { throw "Unparsed current encounter groups: $scenePath" }
 }
 $sceneRecords.Add([ordered]@{path=$scenePath;encounter_field_present=$groups.Success;enemy_ids=@($enemyIds | Sort-Object);semantic_expansion='ONLY_THIS_EXPLICIT_SCENE_ENCOUNTER_FIELD'})
}
# MainMenu V5_BUTTON_MAP: three controls x three states, plus three actual
# fallback text PNGs (included conservatively; not claiming fallback was drawn).
$menuScript='game/scripts/ui/main_menu.gd'
Add-Source $menuScript
$menuText=[IO.File]::ReadAllText((Resolve-Source $menuScript))
foreach ($name in @('new_game','load','quit')) {
 foreach ($state in @('normal','hover','pressed')) {
  $leaf="btn_menu_v5_${name}_${state}.png"
  if (-not $menuText.Contains('"'+$leaf+'"')) { throw "Current menu declaration differs: $leaf" }
  $path="game/art/ui/button/$leaf"; Add-Source $path; $menuPaths.Add($path)
 }
 $leaf="btn_menu_text_$name.png"
 if (-not $menuText.Contains('"'+$leaf+'"')) { throw "Current fallback declaration differs: $leaf" }
 $path="game/art/ui/button/$leaf"; Add-Source $path; $menuPaths.Add($path)
}
while ($queue.Count -gt 0) {
 $path=$queue.Dequeue()
 if (-not $visited.Add($path)) { continue }
 if (Test-Path -LiteralPath ($path+'.import') -PathType Leaf) { Add-Source ($path+'.import') }
 $extension=[IO.Path]::GetExtension($path).ToLowerInvariant()
 if ($extension -notin @('.gd','.tres','.tscn','.godot','.gdshader','.gdshaderinc','.import','.gltf')) { continue }
 $text=[IO.File]::ReadAllText($path)
 if ($enemyPaths.Contains($path)) {
  foreach ($field in @('skill_ids','party_reinforcement_ids')) {
   $member=[regex]::Match($text,('(?m)^'+$field+'\s*=\s*Array\[StringName\]\(\[([^\]]*)\]\)'))
   foreach ($entry in [regex]::Matches($member.Groups[1].Value,'&"([a-z0-9_]+)"')) {
    if ($field -eq 'skill_ids') { Add-Source ('game/data/skills/'+$entry.Groups[1].Value+'.tres') }
    else { Add-Enemy $entry.Groups[1].Value }
   }
  }
 }
 if ($extension -eq '.gd') {
  foreach ($sourceMatch in [regex]::Matches($text,'(?:preload|load)\("(res://[^"\r\n]+)"\)')) { Add-Source $sourceMatch.Groups[1].Value }
 } else {
  # Includes every remap.path.* and deps.dest_files string, not generic path only.
  foreach ($sourceMatch in [regex]::Matches($text,'"(res://[^"\r\n]+)"')) { Add-Source $sourceMatch.Groups[1].Value }
  if ($extension -eq '.gltf') {
   foreach ($uri in [regex]::Matches($text,'"uri"\s*:\s*"([^"\r\n]+)"')) {
    if (-not $uri.Groups[1].Value.StartsWith('data:')) { Add-Source (Join-Path (Split-Path -Parent $path) $uri.Groups[1].Value) }
   }
  }
 }
}
$records=[Collections.Generic.List[object]]::new()
[long]$totalBytes=0
foreach ($path in @($seen | Sort-Object)) {
 $item=Get-Item -LiteralPath $path
 $sha=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
 if ($old.ContainsKey($path)) {
  $row=$old[$path]
  if ($sha -cne $row.sha256 -or $item.Length -ne $row.bytes -or $item.LastWriteTimeUtc.Ticks -ne $row.last_write_utc_ticks) { throw "ROOT427 source changed before this fresh collection: $path" }
 }
 $totalBytes+=[long]$item.Length
 $records.Add([ordered]@{path=$item.FullName;project_relative=$item.FullName.Substring($project.Length+1).Replace('\','/');bytes=$item.Length;sha256=$sha;last_write_utc_ticks=$item.LastWriteTimeUtc.Ticks})
}
$result=[ordered]@{
 scope='FRESH_CURRENT_LUOYANG_FOUR_DISTRICTS_SOURCE_INVENTORY_ONLY';mode='candidate';stage='all';collected_utc=[DateTime]::UtcNow.ToString('o')
 seed_path=$seed;seed_sha256=$seedSHA;seed_credit_inherited=$false;engine_executed=$false;historical_json_graph_expanded=$false
 current_json_records=$prior.current_json_records;current_json_record_count=12
 explicitly_reached_scene_encounters=$sceneRecords.ToArray();current_encounter_enemy_paths=@($enemyPaths | Sort-Object)
 current_menu_png_paths=$menuPaths.ToArray();menu_fallback_draw_claimed=$false
 source_count=$records.Count;source_bytes=$totalBytes;sources=$records.ToArray();source_paths=@($records | ForEach-Object {$_.project_relative})
 excluded_existing_directories=@($directories | Sort-Object);excluded_directory_file_guard_claimed=$false
 limitations=@('Current12 contract records retained as provenance, not newly parsed; all their ROOT427 source files freshly hashed and exact ticks checked','No Field/gameplay/save/audio/formal approval','No retrospective ROOT427 snapshot credit for new paths','Caller must snapshot all15 player files and active slot before engine launch and after exit','Only explicit13 SceneDefs encounter semantics and12 menu leaves; no all-world dialog or enemy enumeration')
}
New-Item -ItemType Directory -Path $target | Out-Null
$output=Join-Path $target 'source_inventory.json'
[IO.File]::WriteAllText($output,($result | ConvertTo-Json -Depth 16),[Text.UTF8Encoding]::new($false))
$back=Get-Content -LiteralPath $output -Raw | ConvertFrom-Json -AsHashtable -Depth 16
if ($back.source_count -ne $records.Count -or $back.sources.Count -ne $records.Count -or $back.source_bytes -ne $totalBytes -or $back.current_menu_png_paths.Count -ne 12 -or $back.explicitly_reached_scene_encounters.Count -ne 13) { throw 'Inventory readback mismatch' }
[pscustomobject]@{path=$output;sha256=(Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash;source_count=$records.Count;source_bytes=$totalBytes;engine_executed=$false}
