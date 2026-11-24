param([Parameter(Mandatory=$true)][string]$AuthorizedSourcesJson)
$ErrorActionPreference='Stop'
$taskRoot='F:\Code\RPG_GAME';$qaRoot=Join-Path $taskRoot 'game/build/major_cities_20261028_qa04'
function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function WriteNew([string]$p,[byte[]]$bytes){$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()}}
$previous=Get-Content -LiteralPath (Join-Path $qaRoot 'completion_actual_READY.json') -Raw|ConvertFrom-Json
$plan=Get-Content -LiteralPath $AuthorizedSourcesJson -Raw|ConvertFrom-Json
$fixed=[ordered]@{};foreach($p in $previous.fixed_sources.PSObject.Properties){$fixed[$p.Name]=$p.Value}
foreach($group in @($plan.sources,$plan.new_modules)){foreach($p in $group.PSObject.Properties){$fixed['res://'+$p.Name.Substring(5)]=$p.Value.sha256}}
$media=Get-Content -LiteralPath (Join-Path $qaRoot 'visual_media24_before_ACTUAL.json') -Raw|ConvertFrom-Json
foreach($p in $media.PSObject.Properties){$fixed['res://'+$p.Name.Substring(5)]=$p.Value.sha256}
$prior='res://build/bianzhou_city_20261028_system04/city_author.gd';$fixed[$prior]='072940d877cb880bd97d92b30c1d0b7d11abbd14641e464632965dc14a4444a7'
$base='res://build/major_cities_20261028_qa04/completion_actual_READY.gd';$fixed[$base]='732a86f39df87ce249ec70060c8b0a30b59c68b0aca537a23140e7aba994afde'
$inherited='res://build/major_cities_20261028_qa04/actual/120780/completion_actual_result.json';$fixed[$inherited]=Sha (Join-Path $taskRoot ('game/'+$inherited.Substring(6)))
foreach($p in $fixed.Keys){if((Sha (Join-Path $taskRoot ('game/'+$p.Substring(6)))) -cne $fixed[$p]){throw "Frozen visual suffix source mismatch: $p"}}
$soil='res://art/maps/bianzhou_enclosure_20261028d/compacted_earth_tile_v1.png'
$grass='res://art/external/polyhaven/world_terrain_v14_ninth/grass_ground/grass_ground_diff_2k.jpg'
$paving='res://art/modules/luoyang_moat_v1/cobblestone_floor_08_diff_1k.jpg'
$farmland='res://art/maps/world_map_v15_complete_v9c/ecology/luoyang_farmland_scene_components.png'
$fixture=[ordered]@{
 ready=$true;whole_seconds=30;entry_seconds=20;max_png=1;city_id='openworld_bianzhou_city';city_field=$previous.city_field;author=$previous.author;prior_author=$prior;baseline=$previous.baseline;fixed_sources=$fixed;inherited_actual=$inherited
 changed_npc_ids=@('bianzhou_life_05','bianzhou_life_06','bianzhou_life_12','bianzhou_life_16','bianzhou_life_19','bianzhou_life_22','bianzhou_life_31','bianzhou_life_33','bianzhou_life_38');visible_female_id='bianzhou_life_12'
 female_sprite='res://art/characters/npc_zhuwei_vegetable_vendor_idle_down_25d_4f_v2_runtime.png';female_portrait='res://art/characters/portraits/generic/portrait_generic_older_woman_v1.png'
 farmland_source_uv=@(@(80,276),@(506,479),@(339,740),@(0,543));farmland_contracts=@(@{id='south_west_cultivated_field_native_uv';foot=@(1900,6050)},@{id='south_east_cultivated_field_native_uv';foot=@(4300,6050)})
 runtime_ground=@(
  @{id='inner_city_base';texture=$soil;period=@(512,512)},
  @{id='axis0';texture=$paving;period=@(128,128)},
  @{id='housing_root_grass_0';texture=$grass;feather=32},
  @{id='south_west_cultivated_field_native_uv';texture=$farmland;feather=80;native_uv=$true}
 )
 no_new_png_import=$true;art_verdict='PENDING_ROOT_AND_ART_NATIVE_IMAGES';old_176_1122_38_not_repeated=$true
}
$json=Join-Path $qaRoot 'visual_residual_READY.json';$gd=Join-Path $qaRoot 'visual_residual_READY.gd'
WriteNew $json ([Text.UTF8Encoding]::new($false).GetBytes(($fixture|ConvertTo-Json -Depth 24)+"`n"));WriteNew $gd ([IO.File]::ReadAllBytes((Join-Path $qaRoot 'visual_residual_DRAFT.gd')))
[ordered]@{script=$gd;sha256=(Sha $gd);fixture_sha256=(Sha $json);fixed_sources=$fixed.Count;public_setup=1;native_png=1;review_only_png=1;engine_calls=0}|ConvertTo-Json -Compress
