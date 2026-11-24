param(
 [Parameter(Mandatory=$true)][string]$AuthorizedSourcesJson,
 [Parameter(Mandatory=$true)][string]$NewMediaFactsJson
)
$ErrorActionPreference='Stop'
$taskRoot='F:\Code\RPG_GAME';$qaRoot=Join-Path $taskRoot 'game/build/major_cities_20261028_qa04'
function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function WriteNew([string]$p,[byte[]]$bytes){$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()}}
$baseline=Get-Content -LiteralPath (Join-Path $qaRoot 'baseline_before_ACTUAL.json') -Raw|ConvertFrom-Json
$plan=Get-Content -LiteralPath $AuthorizedSourcesJson -Raw|ConvertFrom-Json
$completion=Get-Content -LiteralPath (Join-Path $taskRoot 'game/build/bianzhou_city_20261028_system04/completion_binding_BUILD.json') -Raw|ConvertFrom-Json
$gate=Get-Content -LiteralPath (Join-Path $taskRoot 'game/build/bianzhou_city_20261028_system04/gate_binding_BUILD.json') -Raw|ConvertFrom-Json
if($completion.status -cne 'READY_FINAL_BINDING' -or $gate.status -cne 'READY_FOR_BOUND_FIELD'){throw 'RGBA permission/import/binding still pending; do not freeze actual.'}
$fixed=[ordered]@{}
foreach($p in $baseline.sources15.PSObject.Properties){$fixed['res://'+$p.Name.Substring(5)]=$p.Value.sha256}
foreach($group in @($plan.sources,$plan.new_modules)){foreach($p in $group.PSObject.Properties){$fixed['res://'+$p.Name.Substring(5)]=$p.Value.sha256}}
$helper='res://build/major_cities_20261028_qa01/bianzhou_bounded_DRAFT.gd';$fixed[$helper]='ccf485cd4f7f6ac20a527f30ead59bb185c0d8636705d3e73ea7cb3892ffce19'
$audit='res://build/major_cities_20261028_art01/reuse_resources.json';$fixed[$audit]=Sha (Join-Path $taskRoot ('game/'+$audit.Substring(6)))
$media=Get-Content -LiteralPath $NewMediaFactsJson -Raw|ConvertFrom-Json
foreach($p in $media.PSObject.Properties){if(-not $p.Value.exists){throw 'Actual media cannot be absent.'};$fixed['res://'+$p.Name.Substring(5)]=$p.Value.sha256}
foreach($p in $fixed.Keys){if((Sha (Join-Path $taskRoot ('game/'+$p.Substring(6)))) -cne $fixed[$p]){throw "Final actual source mismatch: $p"}}
$portraits=[ordered]@{
 'res://art/characters/street_expansion_v1/npc_escort_guard_idle_down_4f_v2_runtime.png'='res://art/characters/portraits/street_expansion_v1/portrait_escort_guard_v1.png'
 'res://art/characters/street_expansion_v1/npc_street_merchant_idle_down_4f_v3_runtime.png'='res://art/characters/portraits/street_expansion_v1/portrait_street_merchant_v1.png'
 'res://art/characters/street_expansion_v1/npc_vegetable_seller_idle_down_4f.png'='res://art/characters/portraits/street_expansion_v1/portrait_vegetable_seller_v1.png'
 'res://art/characters/luoyang_docks_roles_20261019ad/npc_docks_strong_carrier_idle_down_1f_v1_runtime.png'='res://art/characters/portraits/luoyang_docks_roles_20261019ad/portrait_docks_strong_carrier_v1.png'
 'res://art/characters/npc_duqingshan_v3_idle_down_25d_4f.png'='res://art/characters/portrait_duqingshan_steady.png'
 'res://art/characters/luoyang_city_finish_20261025i/guard_young_bluegrey_idle_v1_runtime160.png'='res://art/characters/portraits/luoyang_city_finish_20261025i/guard_young_bluegrey_portrait_v1.png'
 'res://art/characters/luoyang_city_finish_20261025i/guard_veteran_ochre_idle_v1_runtime160.png'='res://art/characters/portraits/luoyang_city_finish_20261025i/guard_veteran_ochre_portrait_v1.png'
 'res://art/characters/street_expansion_v1/npc_inn_waiter_idle_down_4f.png'='res://art/characters/portraits/street_expansion_v1/portrait_inn_waiter_v1.png'
 'res://art/characters/npc_linxi_farmer_idle_down_25d_4f_v1_runtime.png'='res://art/characters/portraits/portrait_linxi_farmer_v1.png'
 'res://art/characters/npc_luoyang_paper_scholar_idle_down_25d_1f_20261024.png'='res://art/characters/portraits/luoyang_scholar_20261024c/paper_scholar_v1.png'
}
$visits=@(
 @{id='north_gate_and_residential_courts_explicit_setup';foot=@(3072,1050);stages=@(
  @{route=(,@(3072,1082));image='north_gate_NATIVE'},
  @{route=@(@(3072,1570),@(1450,1570),@(1450,1530));image='residential_courts_NATIVE'}
 )},
 @{id='east_post_stable_explicit_second_setup_not_continuous_travel';foot=@(4510,3600);stages=@(
  @{route=(,@(5550,3600));image='post_stable_court_NATIVE'}
 )}
)
$fixture=[ordered]@{ready=$true;media_status='IMPORTED_FINAL_SOURCE_FROZEN';whole_seconds=60;entry_seconds=20;max_png=3;city_id='openworld_bianzhou_city';size=@(6144,6144);author='res://build/bianzhou_city_20261028_system01/city_author.gd';city_field='res://build/bianzhou_city_20261028_system01/bianzhou_field.gd';baseline='res://build/major_cities_20261028_qa04/baseline_before_ACTUAL.json';fixed_sources=$fixed;public_setups=$visits;portraits_by_sprite=$portraits;geometry_component_inheritance=@('actual/122144/geometry_result.json','actual/102092/geometry_residual_result.json');old_business_replay=$false;overview='Independent4096sharedWorld2D_review_camera_only_not_normal_game_camera_credit'}
$json=Join-Path $qaRoot 'completion_actual_READY.json';$gd=Join-Path $qaRoot 'completion_actual_READY.gd'
WriteNew $json ([Text.UTF8Encoding]::new($false).GetBytes(($fixture|ConvertTo-Json -Depth 28)+"`n"));WriteNew $gd ([IO.File]::ReadAllBytes((Join-Path $qaRoot 'completion_actual_DRAFT.gd')))
[ordered]@{script=$gd;sha256=(Sha $gd);fixture_sha256=(Sha $json);fixed_sources=$fixed.Count;public_setups=2;normal_png=3;review_only_png=1;engine_calls=0}|ConvertTo-Json -Compress
