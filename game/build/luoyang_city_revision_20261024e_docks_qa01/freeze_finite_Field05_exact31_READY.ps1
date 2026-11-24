$ErrorActionPreference='Stop'
# Exclusive mechanical QA fixture + three-string READY projection, no engine/canonical writes.
$game=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
function Abs([string]$p){if(-not$p.StartsWith('res://')){throw 'res path'};return Join-Path $game $p.Substring(6)}
function Pinned([string]$p,[string]$sha){if((Get-FileHash -LiteralPath (Abs $p)).Hash.ToLowerInvariant()-cne$sha){throw ('pin '+$p)};return Get-Content -LiteralPath (Abs $p) -Raw|ConvertFrom-Json -AsHashtable}
function NewText([string]$p,[string]$text){$a=Abs $p;if(Test-Path -LiteralPath $a){throw 'NEW only'};[IO.File]::WriteAllText($a,$text,[Text.UTF8Encoding]::new($false));return (Get-FileHash -LiteralPath $a).Hash.ToLowerInvariant()}
$stagePath='res://build/luoyang_city_revision_20261024e_source01/outputs/root_docks_frontages_exact31_stage03/receipt.json';$stageSha='8ea2ed3e987510ace0ef772e4f683468b714e77c6648f7c086e234520f9bd826'
$deployPath='res://build/luoyang_city_revision_20261024e_root01/docks31_deployed_actual.json';$deploySha='ee47ad85fadce157fb805a039f734b8fcd1d4eb05d54a6d197ab539a93c20f89'
$seedPath='res://build/luoyang_city_revision_20261024e_source01/docks_navigation_transform_source_seed_NOT_RUNTIME.json';$seedSha='8309e8a3f97ec593fd4b572bd6ec601f6400d4c70bee88739e8669abfa0d9367'
$stage=Pinned $stagePath $stageSha;$deploy=Pinned $deployPath $deploySha;$seed=Pinned $seedPath $seedSha
if($stage.status-cne'DOCKS_FRONTAGES_EXACT31_STAGED_NOT_DEPLOYED'-or$stage.targets.Count-ne31){throw 'final31 Stage required'}
$n=$stage.nodes.expected_ch4_s2_canal_docks_true
if($n.sha256-cne'1c12a9932f024af3b184e00cde45f76ed89284ed5bd0429667a859a23ccaecfb'){throw 'Root fixed map pin'}
$map=Pinned $n.path $n.sha256;$sources=$map.source_sha256
$a=@($sources.Keys|Sort-Object);$b=@($n.value.source_sha256.Keys|Sort-Object)
if(($a-join"`n")-cne($b-join"`n")-or$a.Count-ne1844){throw 'complete map domain'}
foreach($p in $a){if($sources[$p]-cne$n.value.source_sha256[$p]){throw ('expected value '+$p)}}
if($seed.status-cne'ROOT_REVIEWABLE_SOURCE_DERIVED_DOCKS_NAV_AND_TRANSFORM_NOT_RUNTIME_OBSERVATIONS'-or$seed.expected_navigation39_ids.Count-ne39-or$seed.expected_native29_ids.Count-ne29-or$seed.expected_DG10_ids.Count-ne10-or$seed.expected_three_render.Count-ne3){throw 'source seed scope'}
$ids=@($seed.expected_native29_ids+$seed.expected_DG10_ids|Sort-Object);$expected=@($seed.expected_navigation39_ids|Sort-Object)
if(($ids-join"`n")-cne($expected-join"`n")-or@($expected|Select-Object -Unique).Count-ne39){throw 'seed whole39 IDs'}
$helper='res://build/luoyang_city_blocks_20261024e_system01/docks_three_frontages01/runtime02_READY/docks_frontage_session_READY.gd'
$bindPath='res://build/luoyang_city_blocks_20261024e_system01/docks_three_frontages01/runtime02_READY/binding_READY.json'
if($sources[$helper]-cne'3340eb04cc790fa346930ae164c577f5c5212da50efa5043fe16a035e263f385'-or$sources[$bindPath]-cne'dffded2e8d3bce09b50e3f127e26a060b6b3ab64ee9122c2ff3fb87184fbd012'){throw 'final runtime/binding pins'}
$binding=Pinned $bindPath $sources[$bindPath]
if($binding.ready-ne$true-or$binding.mask.RGBA_sha256-cne'0d0a5871dfa2dcd76c12861b238161f23e30f16ddbe71a545b62d2eeb1bb0816'-or$sources[$seed.author.path]-cne$seed.author.sha256){throw 'final exact author/mask binding'}
$core=@('res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','res://scripts/city/luoyang_district_life_20261016f.gd','res://scripts/field/field_walkable_controller.gd','res://scripts/city/luoyang_assembled_interiors_20261016g.gd','res://scripts/autoload/scene_router.gd',$helper,$bindPath,$seed.author.path)
$small=@{};foreach($p in $core){if(-not$sources.ContainsKey($p)-or(Get-FileHash -LiteralPath (Abs $p)).Hash.ToLowerInvariant()-cne$sources[$p]){throw ('not deployed '+$p)};$small[$p]=$sources[$p]};$small[$seedPath]=$seedSha
$fixture=@{ready=$true;formal_deployed=$true;status='ROOT_EXACT31_DEPLOYED_FINITE_DOCKS_3INSPECTION_WAREHOUSE_TRIP';scene_id='ch4_s2_canal_docks';whole_ms=60000;entry_ms=20000;max_pictures=1;expected_city_count=$sources.Count;expected_city_sources=$sources;source_sha256=$small;helper_path=$helper;mask_path=$binding.mask.path;expected_three_render=$seed.expected_three_render;expected_navigation_ids=$seed.expected_navigation39_ids;inspection_starts=@(@(600,1610),@(1860,748),@(638,670));Root_authorized_inspection_position_writes=3;warehouse_city_threshold=@(638,610);room_scene_path='res://data/maps/luoyang_layout_rooms_20261018t/luoyang_canal_warehouse_interior_20261016/scene.res';room_layout_path='res://data/maps/luoyang_layout_rooms_20261018t/luoyang_canal_warehouse_interior_20261016/layout.res';room_exit_world=@(960,1037.5);paths=@{approaches=@(@(@(600,1610),@(600,1558)),@(@(1860,748),@(1860,688)),@(@(638,670),@(638,640),@(638,610)));room_spawn_to_exit=@(@(960,975),@(960,1037.5))};source_stage=@{path=$stagePath;sha256=$stageSha;map_path=$n.path;map_sha256=$n.sha256};deployment=@{path=$deployPath;sha256=$deploySha};source_seed=@{path=$seedPath;sha256=$seedSha};continuous_connection_travel_credit=$false;packet_mask_oldroute_NPC_replay=$false}
foreach($p in @($fixture.room_scene_path,$fixture.room_layout_path,$binding.mask.path)){if(-not$sources.ContainsKey($p)){throw ('missing original room/mask source '+$p)}}
$template='res://build/luoyang_city_revision_20261024e_docks_qa01/finite_Field04_AWAIT_NOTREADY/test_NOTREADY.gd'
if((Get-FileHash -LiteralPath (Abs $template)).Hash-cne'0095AE8EE3729FBFD25BCF32BFD4B51DE7BB6F69C6CB88148073276EF2DA087A'){throw 'reviewed04 template'}
$out='res://build/luoyang_city_revision_20261024e_docks_qa01/finite_Field05_EXACT31_READY/'
if(Test-Path -LiteralPath (Abs $out)){throw 'NEW output directory only'}
$null=New-Item -ItemType Directory -Path (Abs $out)
$fixtureSha=NewText ($out+'fixture_READY.json') ($fixture|ConvertTo-Json -Depth 100)
$reps=@(@{old='const DOCKS_READY := false';new='const DOCKS_READY := true'},@{old='res://build/luoyang_city_revision_20261024e_docks_qa01/finite_Field04_AWAIT_NOTREADY/fixture_PENDING_FINAL_SOURCE.json';new=($out+'fixture_READY.json')},@{old='PENDING_ROOT_FINAL_SOURCE_MAP_AND_DEPLOYMENT';new=$fixtureSha})
$old=[IO.File]::ReadAllText((Abs $template));$new=$old
foreach($r in $reps){if(([regex]::Matches($new,[regex]::Escape($r.old))).Count-ne1){throw 'unique replacement'};$new=$new.Replace($r.old,$r.new)}
$back=$new;for($i=$reps.Count-1;$i-ge0;$i--){$back=$back.Replace($reps[$i].new,$reps[$i].old)};if($back-cne$old){throw 'whole inverse'}
$scriptSha=NewText ($out+'test_READY.gd') $new
$proof=@{status='ROOT_DEPLOYED_31_DOCKS_FINITE_QA_READY_NO_ENGINE';parent_path=$template;parent_sha256='0095ae8ee3729fbfd25bcf32bfd4b51de7bb6f69c6cb88148073276ef2da087a';script_sha256=$scriptSha;fixture_sha256=$fixtureSha;hunks=$reps;whole_forward_inverse=$true;EOF_preserved=$true;stage=$fixture.source_stage;deployment=$fixture.deployment;seed=$fixture.source_seed;keys=1844;all_keys_values_checked=$true;whole_ms=60000;entry_ms=20000;inspection_position_writes=3;camera_writes=0;photos=1;engine=0;formal_writes=0;prior_FAILs_preserved=$true}
$proofSha=NewText ($out+'whole_byte_delta_and_provenance_READY.json') ($proof|ConvertTo-Json -Depth 40)
@{script_sha256=$scriptSha;fixture_sha256=$fixtureSha;proof_sha256=$proofSha;keys=$sources.Count}|ConvertTo-Json -Compress
