$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME'
$folder=Join-Path $repo 'game/build/riverside_visual_20261101a_source01'
$before=Get-Content -LiteralPath (Join-Path $folder 'before02_ACTUAL.json') -Raw|ConvertFrom-Json
$mini=Get-Content -LiteralPath (Join-Path $folder 'minimap_before_ACTUAL.json') -Raw|ConvertFrom-Json
$prior=Get-Content -LiteralPath $before.prior_guard_path -Raw|ConvertFrom-Json
$fixed=[ordered]@{}
$rels=@(
'game/data/maps/adventure_20261030k/luoyang_riverside_layout.tres',
'game/data/maps/adventure_20261030k/luoyang_riverside_background.tres',
'game/data/maps/adventure_20261030k/luoyang_walk.svg',
'game/art/modules/sect_maps_20261029k/quiet_ground.png',
'game/data/scenes/adventure_luoyang_riverside_route.tres',
'game/data/scenes/adventure_zhuwei_hunting_ground.tres',
'game/data/scenes/adventure_xiangzhou_deep_mine.tres',
'game/data/maps/adventure_20261030k/forest_layout.tres',
'game/data/maps/adventure_20261030k/forest_background.tres',
'game/data/maps/adventure_20261030k/forest_walk.svg',
'game/data/maps/adventure_20261030k/mine_layout.tres',
'game/data/maps/adventure_20261030k/mine_background.tres',
'game/data/maps/adventure_20261030k/mine_walk.svg',
'game/data/maps/adventure_20261030k/adventure_config.json',
'game/data/maps/adventure_20261030k/luoyang_adventure_config.json',
'game/data/scenes/world_map_jianghu.tres',
'game/project.godot',
'game/scripts/autoload/scene_router.gd',
'game/scripts/field/field_walkable_controller.gd',
'game/scripts/city/luoyang_execution_index_20261022ap.gd',
'game/scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd',
'game/build/three_towns_world_20261029j_system01/native_sources.json',
'game/build/three_towns_world_20261029j_system01/town_registry.gd',
'game/build/world_coast_20261031h_system02/world_contract_dispatch03.gd',
'game/build/world_coast_20261031h_system02/world_v16_contract03.gd',
'game/art/maps/world_coast_20261031h/candidate02/runtime_contract03.json'
)
foreach($y in 0..2){foreach($x in 0..3){$rels+=('game/data/maps/adventure_20261030k/luoyang_riverside_ground_'+$x+'_'+$y+'.tres')}}
foreach($rel in $rels){
    $path=($repo+'/'+$rel)
    $fact=$prior.facts.PSObject.Properties[$path].Value
    if($null -eq $fact){$fact=$prior.evidence_facts.PSObject.Properties[$path].Value}
    if($null -eq $fact){throw ('NO_PRIOR_FIXED_FACT:'+ $path)}
    $fixed[$path]=$fact
}
$authorized=[ordered]@{
    'F:/Code/RPG_GAME/game/build/adventure_world_20261031f_system01/world_links.gd'='a816e8e2466889ffa4aa46263f70b8743e7a0fd7e8370ea342d33d95a8f37ebf'
    'F:/Code/RPG_GAME/game/scripts/adventure/adventure_runtime.gd'='b0f8974caacd1ff96f0a2fb783702eef43b353831531b0269af975d072107c51'
    'F:/Code/RPG_GAME/game/scripts/adventure/adventure_minimap.gd'='0dad4c1354ce74fb6fd2d5ba1a510c9438c014e3c2954a1500ff41aa9516c38a'
}
$proofs=[ordered]@{
    'F:/Code/RPG_GAME/assets/raw/riverside_visual_20261101a/shelter_v1.png'='8bc58e32a1f2d32f3af25a833b0aa77a5261858a90f2e72cebb78d7e15d71ffa'
    'F:/Code/RPG_GAME/game/art/modules/riverside_visual_20261101a/shelter_v1.png'='3da5c59f18a0fdbde2c4dacf188be3ec46d609d185a3b237f14721268e438415'
    'F:/Code/RPG_GAME/game/art/modules/riverside_visual_20261101a/shelter_v1.png.import'='a218a11f4c8cdf3e2dd515fa3f0cd8cdd9846e36f32bd40264bc952fe153fe95'
    'F:/Code/RPG_GAME/game/.godot/imported/shelter_v1.png-63b45e7efafe234d93fa91ea1a945df6.ctex'='e9b63377ec23e0be7695a1c7b30c3754fcd9bfec8921d0990f72fac7cd659a5a'
    'F:/Code/RPG_GAME/game/build/riverside_visual_20261101a_system01/natural_ground.gd'='1653826e97c16dc3891c54c23e48be1c97ef555f0f9b0250d37184dd32531b3e'
    'F:/Code/RPG_GAME/game/build/riverside_visual_20261101a_system01/natural_ground.gdshader'='e2bd062c476c829c46b8b1ec5d802110b4b246999d5b235a6600004932be6d62'
}
$metadata=[ordered]@{status='EXPLICIT_THREE_AUTHORIZED_TARGETS_BOUNDED_FROZEN_INPUTS_AND_SIX_NEW_PROOFS';authorized_after_sha256=$authorized;frozen_before_facts=$fixed;new_proof_sha256=$proofs;save_before_path='F:/Code/RPG_GAME/game/build/riverside_visual_20261101a_source01/before02_ACTUAL.json';minimap_before_path='F:/Code/RPG_GAME/game/build/riverside_visual_20261101a_source01/minimap_before_ACTUAL.json';prior3236_credit='HISTORICAL_ONLY_NOT_REHASHED';prior_guard_sha256=$before.prior_guard_sha256;root_approval_required=$true;retained_sealing_failure='Initial prepare safely refused unavailable priorfact for genericlayered_v3contract; removed outofscope optionalpin, no fallback to current implicitapproval.'}
$output=Join-Path $folder 'final_expected_REVIEW_ONLY.json'
if(Test-Path -LiteralPath $output){throw 'NEW_EXPECTED_ONLY'}
[IO.File]::WriteAllText($output,($metadata|ConvertTo-Json -Depth 12),[Text.UTF8Encoding]::new($false))
[ordered]@{output=$output;authorized_count=$authorized.Count;frozen_count=$fixed.Count;new_proof_count=$proofs.Count}|ConvertTo-Json
