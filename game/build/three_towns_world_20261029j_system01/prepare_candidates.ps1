param()
$ErrorActionPreference='Stop'
$taskRoot='F:/Code/RPG_GAME'
$out='game/build/three_towns_world_20261029j_system01'
$utf8=[Text.UTF8Encoding]::new($false,$true)
function ReadUtf8([string]$p){return $utf8.GetString([IO.File]::ReadAllBytes("$taskRoot/$p"))}
function PutNew([string]$p,[string]$text){$file="$taskRoot/$out/$p";if(Test-Path -LiteralPath $file){throw "Immutable output already exists: $file"};[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($file))|Out-Null;[IO.File]::WriteAllBytes($file,$utf8.GetBytes($text))}
$worldSpecText=ReadUtf8 'game/build/three_towns_world_20261029j_world01/world_spec.json'
if(Test-Path -LiteralPath "$taskRoot/$out/world_spec.json"){if((ReadUtf8 "$out/world_spec.json")-cne$worldSpecText){throw 'World spec candidate moved'}}else{PutNew 'world_spec.json' $worldSpecText}
$router=ReadUtf8 'game/scripts/autoload/scene_router.gd'
$nl=if($router.Contains("`r`n")){"`r`n"}else{"`n"}
$pairs=@(
 @('func _go_field_smart_prepared(scene_id: StringName, player_spawn: Variant = null, pending_action: String = "", spawn_version: int = -1, local_spawn_version: int = -1) -> bool:',(@('func _go_field_smart_prepared(scene_id: StringName, player_spawn: Variant = null, pending_action: String = "", spawn_version: int = -1, local_spawn_version: int = -1) -> bool:',"`tvar towns29j: Variant=load(`"res://build/three_towns_world_20261029j_system01/town_registry.gd`")","`ttowns29j.ensure_watcher(self)","`tif towns29j.IDS.has(scene_id):return towns29j.start(self,scene_id,player_spawn,pending_action,local_spawn_version)")-join$nl)),
 @('func get_world_map_position_for_scene(scene_id: StringName, world_scene_id: StringName = WORLD_MAP_SCENE) -> Variant:',(@('func get_world_map_position_for_scene(scene_id: StringName, world_scene_id: StringName = WORLD_MAP_SCENE) -> Variant:',"`tif world_scene_id in [WORLD_MAP_SCENE,WORLD_MAP_V15_SCENE] and world_version_for_scene(world_scene_id)==15:","`t`tvar towns29j: Variant=load(`"res://build/three_towns_world_20261029j_system01/town_registry.gd`")","`t`tif towns29j.IDS.has(scene_id):return towns29j.town(scene_id).world_foot/towns29j.WORLD_SIZE")-join$nl)),
 @('func get_field_scene_path(scene_id: StringName) -> String:',(@('func get_field_scene_path(scene_id: StringName) -> String:',"`tvar towns29j: Variant=load(`"res://build/three_towns_world_20261029j_system01/town_registry.gd`")","`tif towns29j.IDS.has(scene_id):return towns29j.FIELD")-join$nl))
)
$after=$router;$hunks=@()
foreach($pair in $pairs){$before=$pair[0];$next=$pair[1];if(($after.Split([string[]]@($before),[StringSplitOptions]::None).Count-1)-ne1){throw 'Nonunique Router hunk'};$after=$after.Replace($before,$next);$hunks+=,[ordered]@{before=$before;after=$next}}
$reverse=$after;foreach($h in $hunks){$reverse=$reverse.Replace($h.after,$h.before)};if($reverse-cne$router){throw 'Router inverse differs'}
PutNew 'router_hunks_READY.json' (($hunks|ConvertTo-Json -Depth 8)+"`n")
# The existing audited source successor builder is reused as a bulk mechanical transform.
$builder=ReadUtf8 'game/build/jinling_city_20261029_system01/prepare_source_closure01.ps1'
$builder=$builder.Replace("game/build/jinling_city_20261029_system01/source_closure01_READY","$out/source_closure01_READY")
$builder=$builder.Replace('game/build/bianzhou_city_20261028_system01/source_closure04_READY/receipt.json','game/build/jinling_city_20261029_system01/source_closure01_READY/receipt.json')
$builder=$builder.Replace("res://build/luoyang_bianzhou_router_20261028_source01/Router_READY.gd","res://build/jinling_city_20261029_system01/source_closure01_READY/Router_READY.gd")
$builder=$builder.Replace("`$newSnapshot='res://build/jinling_city_20261029_system01/source_closure01_READY/Router_READY.gd'","`$newSnapshot='res://build/three_towns_world_20261029j_system01/source_closure01_READY/Router_READY.gd'")
$builder=$builder.Replace('game/build/jinling_city_20261029_system01/router_hunk_FINAL.json',"$out/router_hunks_READY.json")
$builder=$builder.Replace('$rb=ReadUtf8 ''game/scripts/autoload/scene_router.gd'';$ra=Once $rb $h.before $h.after','$rb=ReadUtf8 ''game/scripts/autoload/scene_router.gd'';$ra=$rb;foreach($part in $h){$ra=Once $ra $part.before $part.after}')
$builder=$builder.Replace('if((Once $ra $h.after $h.before)-cne$rb){throw ''Router whole inverse differs.''}','$ri=$ra;foreach($part in $h){$ri=Once $ri $part.after $part.before};if($ri-cne$rb){throw ''Router whole inverse differs.''}')
$builder=$builder.Replace('replacements=@([ordered]@{old=$h.before;new=$h.after})','replacements=@($h|ForEach-Object{[ordered]@{old=$_.before;new=$_.after}})')
# Preserve the literal immutable parent snapshot reference after the broad output substitution.
$builder=$builder.Replace("`$oldSnapshot='res://build/three_towns_world_20261029j_system01/source_closure01_READY/Router_READY.gd'","`$oldSnapshot='res://build/jinling_city_20261029_system01/source_closure01_READY/Router_READY.gd'")
PutNew 'prepare_source_closure_READY.ps1' $builder
& ([scriptblock]::Create($builder))

# Pin native scene chains and small geometry packet, without altering any original content.
$sourcePaths=@(
 'game/scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn',
 'game/scripts/drafts/redrock_city_life_20261029a/town_controller.gd',
 'game/scripts/drafts/redrock_desert_complete_20261028d/town_controller.gd',
 'game/scripts/drafts/redrock_luoyang_standard_20261028b/town_controller.gd',
 'game/scripts/drafts/redrock_luoyang_standard_20261028b/preview_player.gd',
 'game/scenes/drafts/desert_town_20261029d/desert_town.tscn',
 'game/scripts/drafts/desert_town_20261029d/town_controller.gd',
 'game/scenes/drafts/miao_terrain_20261029i/miao_town.tscn',
 'game/scripts/drafts/miao_terrain_20261029i/town_controller.gd',
 'game/scripts/drafts/miao_terrain_20261029i/terrain.gd',
 'game/scripts/drafts/miao_building_variety_20261029h/town_controller.gd',
 'game/art/modules/miao_terrain_20261029i/terrain.json',
 "$out/world_spec.json"
 'game/art/external/polyhaven/world_terrain_v14_sixth/brown_mud_03/brown_mud_03_diff_2k.jpg'
)
$sources=[ordered]@{}
foreach($p in $sourcePaths){$sources['res://'+$p.Substring(5)]=(Get-FileHash -LiteralPath "$taskRoot/$p" -Algorithm SHA256).Hash.ToLowerInvariant()}
PutNew 'native_sources.json' (([ordered]@{sources=$sources}|ConvertTo-Json -Depth 8)+"`n")
$auth=[ordered]@{sources=[ordered]@{};new_modules=[ordered]@{}}
$closure=Get-Content -Raw -LiteralPath "$taskRoot/$out/source_closure01_READY/receipt.json"|ConvertFrom-Json
foreach($r in $closure.targets){$auth.sources[$r.target]=[ordered]@{sha256=$r.new_sha256;bytes=$r.bytes}}
foreach($f in Get-ChildItem -LiteralPath "$taskRoot/$out" -File -Recurse){if($f.Name -eq 'auth_READY.json'){continue};$path=$f.FullName.Replace('\','/').Substring($taskRoot.Length+1);$auth.new_modules[$path]=[ordered]@{sha256=(Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash.ToLowerInvariant();bytes=$f.Length}}
foreach($id in @('openworld_redrock_town','openworld_desert_city','openworld_lanxi_zhai')){$f=Get-Item -LiteralPath "$taskRoot/$out/$id.tres";$auth.new_modules["game/data/scenes/$id.tres"]=[ordered]@{sha256=(Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash.ToLowerInvariant();bytes=$f.Length}}
PutNew 'auth_READY.json' (($auth|ConvertTo-Json -Depth 8)+"`n")
