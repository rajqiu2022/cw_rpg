param([Parameter(Mandatory=$true)][string]$DeploymentPath,[Parameter(Mandatory=$true)][string]$DeploymentSHA)
$ErrorActionPreference='Stop'
$game=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
function Abs([string]$p){if(-not$p.StartsWith('res://')){throw 'res path'};return Join-Path $game $p.Substring(6)}
function ReadPinned([string]$p,[string]$h){if((Get-FileHash -LiteralPath (Abs $p)).Hash.ToLowerInvariant()-cne$h.ToLowerInvariant()){throw ('pin '+$p)};return Get-Content -Raw -LiteralPath (Abs $p)|ConvertFrom-Json -AsHashtable}
function WriteNew([string]$p,[string]$v){$a=Abs $p;if(Test-Path -LiteralPath $a){throw 'exclusive new'};[IO.File]::WriteAllText($a,$v,[Text.UTF8Encoding]::new($false));return (Get-FileHash -LiteralPath $a).Hash.ToLowerInvariant()}
$sp='res://build/luoyang_city_revision_20261025f_source01/outputs/root_street_materials_exact18_stage01/receipt.json'
$sh='9876e1cc4bab5e292d9d15052b7758c7d4f1ce5e98fecfb49fda4b6f45feff67'
$s=ReadPinned $sp $sh;$d=ReadPinned $DeploymentPath $DeploymentSHA
if($s.status-cne'STREET_MATERIALS_EXACT18_STAGED_NOT_DEPLOYED'-or$s.targets.Count-ne18-or$s.target_partition.patch_count-ne7-or$s.target_partition.copy_count-ne11){throw 'stage18'}
if($d.stage_sha256.ToLowerInvariant()-cne$sh-or$d.targets.Count-ne18-or$d.GD_apply_patch-ne7-or$d.JSON_exact_copy-ne11){throw 'actual deploy18'}
$dm=@{};foreach($r in $d.targets){if($dm.ContainsKey($r.target)){throw 'duplicate deploy'};$dm[$r.target]=$r}
foreach($r in $s.targets){$a=Abs $r.target;$c=Abs $r.candidate_path;if((Get-FileHash -LiteralPath $c).Hash.ToLowerInvariant()-cne$r.candidate_sha256-or(Get-FileHash -LiteralPath $a).Hash.ToLowerInvariant()-cne$r.candidate_sha256-or$dm[$r.target].sha256.ToLowerInvariant()-cne$r.candidate_sha256-or(Get-Item -LiteralPath $a).Length-ne$dm[$r.target].bytes){throw ('formal exact18 '+$r.target)}}
$n=$s.nodes.expected_ch4_s3_luoyang_market_true;$m=ReadPinned $n.path $n.sha256
$ks=@($m.source_sha256.Keys|Sort-Object);$ns=@($n.value.source_sha256.Keys|Sort-Object)
if(($ks-join"`n")-cne($ns-join"`n")){throw 'independent whole map keys'}
foreach($p in $ks){if($m.source_sha256[$p]-cne$n.value.source_sha256[$p]){throw 'independent map value'}}
$helper='res://build/luoyang_street_materials_20261025f_system01/material_revision02/market_purpose_layer_BUILD.gd'
$spec='res://build/luoyang_street_materials_20261025f_system01/material_revision02/market_five_use_spec_BUILD.json'
$shader='res://build/luoyang_street_materials_20261025f_system01/material_revision02/market_use_materials_BUILD.gdshader'
$cp=@('res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','res://scripts/field/field_walkable_controller.gd','res://scripts/autoload/scene_router.gd','res://scripts/city/luoyang_environment_layer_20261022ap.gd',$helper,$spec,$shader)
$small=@{};foreach($p in $cp){if(-not$m.source_sha256.ContainsKey($p)-or(Get-FileHash -LiteralPath (Abs $p)).Hash.ToLowerInvariant()-cne$m.source_sha256[$p]){throw ('source core '+$p)};$small[$p]=$m.source_sha256[$p]}
if($small[$helper]-cne'ece43ee0e3cf777d834cd580b0fb66a8c8ddae29ebcfb138fa566bc5971687e6'-or$small[$spec]-cne'2d6e7bc644328ecf80d26f101662a60d757deebb45415c9e33a6a131a17cf9f3'-or$small[$shader]-cne'84befe183f06894ee45c608c1ff49367b22d14cd2ddef38d84f81bdd58c7bbb0'){throw 'final materials02'}
$envPath='res://data/maps/luoyang_full_city_20261022ap/environment.json';$env=ReadPinned $envPath '64a7efc81a2d37c588c4d63b302324ff9b2eb90cea932de543e85177e8a4afd2';$assets=@{}
foreach($key in @('road_stone','court_stone','road_earth','road_gravel')){$assets[$key]=$env.assets[$key].texture}
$fixture=@{ready=$true;formal_deployed=$true;status='ROOT_DEPLOYED25F_EXACT18_MATERIAL_VIEW_ONLY';scene_id='ch4_s3_luoyang_market';whole_ms=60000;entry_ms=20000;max_pictures=1;expected_city_count=$m.source_sha256.Count;expected_city_sources=$m.source_sha256;source_sha256=$small;helper_path=$helper;asset_paths=$assets;Root_approved_observation_writes=1;observation_foot=@(1660,1468);expected_source_stage_receipt=@{path=$sp;sha256=$sh;map_path=$n.path;map_sha256=$n.sha256};deployment_receipt=@{path=$DeploymentPath;sha256=$DeploymentSHA.ToLowerInvariant()};old_routes_doors_6body_8NPC_portrait_replays=0;new_loading_performance_credit=$false}
$template='res://build/luoyang_city_revision_20261025f_qa01/field01_MATERIALS_NOTREADY/test_NOTREADY.gd';$templateSHA='5e5b722732caf33125813d1aec58cab333bdf39d7b60428fd28fd37d71953411'
if((Get-FileHash -LiteralPath (Abs $template)).Hash.ToLowerInvariant()-cne$templateSHA){throw 'frozen template'}
$out='res://build/luoyang_city_revision_20261025f_qa01/field01_MATERIALS_READY/';if(Test-Path -LiteralPath (Abs $out)){throw 'new namespace'}
$null=New-Item -ItemType Directory -Path (Abs $out)
$fh=WriteNew ($out+'fixture_READY.json') ($fixture|ConvertTo-Json -Depth 100)
$reps=@(@{old='const MATERIAL_FIELD_READY := false';new='const MATERIAL_FIELD_READY := true'},@{old='res://build/luoyang_city_revision_20261025f_qa01/field01_MATERIALS_NOTREADY/fixture_PENDING_FINAL_SOURCE.json';new=($out+'fixture_READY.json')},@{old='PENDING_ROOT_OVERVIEW_ART_AND_EXACT18_SOURCE_DEPLOYMENT';new=$fh})
$old=[IO.File]::ReadAllText((Abs $template));$new=$old;foreach($r in $reps){if(([regex]::Matches($new,[regex]::Escape($r.old))).Count-ne1){throw 'unique hunk'};$new=$new.Replace($r.old,$r.new)}
$back=$new;for($i=$reps.Count-1;$i-ge0;$i--){$back=$back.Replace($reps[$i].new,$reps[$i].old)};if($back-cne$old){throw 'whole inverse'}
$gh=WriteNew ($out+'test_READY.gd') $new
$proof=@{parent_path=$template;parent_sha256=$templateSHA;candidate_sha256=$gh;fixture_sha256=$fh;hunks=$reps;whole_forward_inverse=$true;EOF_preserved=$true;independent_map=@{path=$n.path;sha256=$n.sha256;count=$m.source_sha256.Count};exact_source_stage=@{path=$sp;sha256=$sh};actual_deployment=@{path=$DeploymentPath;sha256=$DeploymentSHA.ToLowerInvariant()};engine_calls=0;formal_writes=0;scope='Only natural FINAL +6 actual materials+one safe16601468 pose+one original1.05PNG; zero INPUT/Space/old behavior replay'}
$ph=WriteNew ($out+'whole_byte_delta_READY.json') ($proof|ConvertTo-Json -Depth 40)
$guardParent='res://build/luoyang_city_revision_20261025f_qa01/guard18_fixture_NOTREADY.json';$guard=ReadPinned $guardParent 'bceeaba137ed647439ab4146fafbe6b76d4bb5186546be81ca54eb3ad438e824'
$guard.ready=$true;$guard.formal_deployed=$true;$guard.stage=@{path=$sp;sha256=$sh};$guard.deployment=@{path=$DeploymentPath;sha256=$DeploymentSHA.ToLowerInvariant()}
$guardSHA=WriteNew 'res://build/luoyang_city_revision_20261025f_qa01/guard18_fixture_READY.json' ($guard|ConvertTo-Json -Depth 20)
@{Field_script_sha256=$gh;Field_fixture_sha256=$fh;Field_proof_sha256=$ph;map_sha256=$n.sha256;map_count=$m.source_sha256.Count;guard_fixture_sha256=$guardSHA;engine_calls=0}|ConvertTo-Json -Compress
