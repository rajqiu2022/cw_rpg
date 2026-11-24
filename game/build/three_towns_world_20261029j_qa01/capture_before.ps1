$ErrorActionPreference='Stop'
$taskRoot='F:/Code/RPG_GAME';$qaRoot=Join-Path $taskRoot 'game/build/three_towns_world_20261029j_qa01'
function Fact([string]$p){if(-not [IO.File]::Exists($p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant();bytes=$i.Length;utc_ticks=$i.LastWriteTimeUtc.Ticks.ToString()}}
function NewBytes([string]$p,[byte[]]$b){[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($p))|Out-Null;$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$s.Write($b,0,$b.Length)}finally{$s.Dispose()}}
$output=Join-Path $qaRoot 'baseline_before_ACTUAL.json';if(Test-Path -LiteralPath $output){throw 'Preserve first baseline; CreateNew only.'}
$paths=@(
 'game/scripts/autoload/scene_router.gd',
 'game/data/maps/luoyang_full_city_20261022ap/execution_successor.json',
 'game/scripts/city/luoyang_execution_index_20261022ap.gd',
 'game/data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json',
 'game/scripts/city/luoyang_precomputed_bundle_index_20261018r.gd',
 'game/data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json',
 'game/scripts/city/luoyang_quarters_index_20261022ap.gd',
 'game/data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/manifest.json',
 'game/scripts/city/luoyang_docks_workyard_index_20261019ac.gd',
 'game/data/scenes/world_map_jianghu.tres','game/data/scenes/world_map_jianghu_v15.tres',
 'game/data/maps/world_map_jianghu_layout_v15.tres','game/data/maps/world_map_v15_complete_v9c_source.json',
 'game/art/maps/world_map_v15_complete_v9c/art_contract.json',
 'game/scripts/world/world_map_v15_contract.gd','game/scripts/world/world_map_v14_contract.gd',
 'game/scripts/ui/world_travel_minimap.gd','game/scripts/ui/world_map_panel.gd','game/scripts/ui/field_primary_hud.gd',
 'game/scripts/field/field_walkable_controller.gd','game/scripts/field/player.gd','game/scripts/autoload/game_state.gd',
 'game/scripts/autoload/save_manager.gd','game/scripts/autoload/quest_manager.gd','game/scripts/autoload/inventory.gd',
 'game/project.godot','game/scenes/player.tscn',
 'game/scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn',
 'game/scenes/drafts/desert_town_20261029d/desert_town.tscn',
 'game/scenes/drafts/miao_terrain_20261029i/miao_town.tscn',
 'game/art/modules/miao_terrain_20261029i/terrain.json',
 'game/art/modules/miao_terrain_20261029i/ground.gdshader',
 'game/build/bianzhou_city_20261028_system01/router_entry.gd',
 'game/build/bianzhou_city_20261028_system01/city_author.gd',
 'game/build/bianzhou_city_20261028_system01/bianzhou_field.gd',
 'game/build/jinling_city_20261029_system01/router_entry.gd',
 'game/build/jinling_city_20261029_system01/city_author.gd',
 'game/build/jinling_city_20261029_system01/jinling_field.gd',
 'game/build/jinling_city_20261029_system01/river_binding_BUILD.json',
 'game/build/luoyang_city_full_rollout_20261022ap_root01/run_frozen_godot_once.ps1'
)
foreach($dir in @('redrock_luoyang_standard_20261028b','redrock_desert_complete_20261028d','redrock_city_life_20261029a','desert_town_20261029d','miao_town_20261029f','miao_building_variety_20261029h','miao_terrain_20261029i')){
 foreach($f in Get-ChildItem -LiteralPath (Join-Path $taskRoot ('game/scripts/drafts/'+$dir)) -File -Filter '*.gd'){$paths+='game/scripts/drafts/'+$dir+'/'+$f.Name}
}
$sources=[ordered]@{};$backups=@()
foreach($relative in ($paths|Select-Object -Unique)){
 $p=Join-Path $taskRoot $relative;$fact=Fact $p;if(-not $fact.exists){throw "Current source missing: $relative"};$sources[$relative]=$fact
 $copy=Join-Path $qaRoot ('source_before/'+$relative);NewBytes $copy ([IO.File]::ReadAllBytes($p));[IO.File]::SetLastWriteTimeUtc($copy,[DateTime]::new([long]$fact.utc_ticks,[DateTimeKind]::Utc));$copied=Fact $copy
 if($copied.sha256 -cne $fact.sha256 -or $copied.bytes -ne $fact.bytes -or $copied.utc_ticks -cne $fact.utc_ticks){throw 'Source backup is not exact.'};$backups+=@{source=$relative;path=$copy;fact=$copied}
}
$savePaths=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$prior=Get-Content -Raw -LiteralPath (Join-Path $taskRoot 'game/build/jinling_city_20261029_qa01/final_guard04_ROOT_ACTUAL.json')|ConvertFrom-Json
foreach($e in $prior.save15.PSObject.Properties){[void]$savePaths.Add($e.Name)}
foreach($relative in @('assets/staging/miao_terrain_20261029i/protected-before.json','assets/staging/desert_town_20261029d/protected-before.json','assets/staging/redrock_city_life_20261029a/protected-before.json')){
 foreach($row in (Get-Content -Raw -LiteralPath (Join-Path $taskRoot $relative)|ConvertFrom-Json)){
  if($row.path -match '[/\\]save_[0-4]\.json(?:\.(?:bak|tmp))?$'){[void]$savePaths.Add($row.path)}
 }
}
$saves=[ordered]@{};foreach($p in ($savePaths|Sort-Object)){$saves[$p]=Fact $p}
foreach($relative in $sources.Keys){$now=Fact (Join-Path $taskRoot $relative);if($now.sha256 -cne $sources[$relative].sha256 -or $now.bytes -ne $sources[$relative].bytes -or $now.utc_ticks -cne $sources[$relative].utc_ticks){throw "Source changed during capture: $relative"}}
$processes=@(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'"|Select-Object ProcessId,Name)
$result=[ordered]@{status='THREE_TOWNS_SMALL_READONLY_BEFORE';utc=[DateTime]::UtcNow.ToString('o');sources=$sources;exact_backups=$backups;registered_save_paths=$saves;root_save15_paths=@($prior.save15.PSObject.Properties|ForEach-Object Name);godot_processes=$processes;editor51856_present=(@($processes|Where-Object ProcessId -eq 51856).Count -eq 1);save_contents_parsed=$false;save_writes=0;canonical_writes=0;engine_calls=0;processes_stopped=0}
NewBytes $output ([Text.UTF8Encoding]::new($false).GetBytes(($result|ConvertTo-Json -Depth 15)+"`n"))
[ordered]@{path=$output;sha256=(Fact $output).sha256;sources=$sources.Count;backups=$backups.Count;registered_save_paths=$saves.Count;root_save15=$result.root_save15_paths.Count;editor51856=$result.editor51856_present;engine_calls=0}|ConvertTo-Json -Compress
