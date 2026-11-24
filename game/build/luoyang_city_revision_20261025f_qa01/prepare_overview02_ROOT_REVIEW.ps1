$ErrorActionPreference='Stop'
$game=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
function Abs([string]$p){return Join-Path $game $p.Substring(6)}
function NewText([string]$p,[string]$s){$a=Abs $p;if(Test-Path -LiteralPath $a){throw 'exclusive new'};[IO.File]::WriteAllText($a,$s,[Text.UTF8Encoding]::new($false));return (Get-FileHash -LiteralPath $a).Hash.ToLowerInvariant()}
$parent='res://build/luoyang_city_revision_20261025f_qa01/overview01_ROOT_REVIEW/test_ROOT_REVIEW.gd'
$parentSha='e7c9bdc86f9facdb1fe1c3c2c4eeeaf1c7d056f89f935761bccfe8cd42369d72'
if((Get-FileHash -LiteralPath (Abs $parent)).Hash.ToLowerInvariant()-cne$parentSha){throw 'frozen parent'}
$pins=@{
 'res://build/luoyang_street_materials_20261025f_system01/material_revision02/market_purpose_layer_BUILD.gd'='ece43ee0e3cf777d834cd580b0fb66a8c8ddae29ebcfb138fa566bc5971687e6'
 'res://build/luoyang_street_materials_20261025f_system01/material_revision02/market_five_use_spec_BUILD.json'='2d6e7bc644328ecf80d26f101662a60d757deebb45415c9e33a6a131a17cf9f3'
 'res://build/luoyang_street_materials_20261025f_system01/material_revision02/market_use_materials_BUILD.gdshader'='84befe183f06894ee45c608c1ff49367b22d14cd2ddef38d84f81bdd58c7bbb0'
}
foreach($p in $pins.Keys){if((Get-FileHash -LiteralPath (Abs $p)).Hash.ToLowerInvariant()-cne$pins[$p]){throw ('candidate pin '+$p)}}
$out='res://build/luoyang_city_revision_20261025f_qa01/overview02_ROOT_REVIEW/'
if(Test-Path -LiteralPath (Abs $out)){throw 'new namespace only'}
$reps=@(
 @{old='const PURPOSE24E := "res://build/luoyang_street_materials_20261025f_system01/market_purpose_layer_BUILD.gd"';new='const PURPOSE24E := "res://build/luoyang_street_materials_20261025f_system01/material_revision02/market_purpose_layer_BUILD.gd"'},
 @{old='647f2adf1debb9f50b2f743b995a5205e04bd3f5a617f861a6e21a41773d8d6c';new='ece43ee0e3cf777d834cd580b0fb66a8c8ddae29ebcfb138fa566bc5971687e6'},
 @{old='const SPEC24E := "res://build/luoyang_street_materials_20261025f_system01/market_five_use_spec_BUILD.json"';new='const SPEC24E := "res://build/luoyang_street_materials_20261025f_system01/material_revision02/market_five_use_spec_BUILD.json"'},
 @{old='cade61d03248672edebaeed8ca272cbfdabeb157f19db72591967a9dd81ec034';new='2d6e7bc644328ecf80d26f101662a60d757deebb45415c9e33a6a131a17cf9f3'},
 @{old='res://build/luoyang_city_revision_20261025f_qa01/overview01_output/';new='res://build/luoyang_city_revision_20261025f_qa01/overview02_output/'}
)
$old=[IO.File]::ReadAllText((Abs $parent));$new=$old
foreach($r in $reps){if(([regex]::Matches($new,[regex]::Escape($r.old))).Count-ne1){throw 'unique hunk'};$new=$new.Replace($r.old,$r.new)}
$back=$new;for($i=$reps.Count-1;$i-ge0;$i--){$back=$back.Replace($reps[$i].new,$reps[$i].old)};if($back-cne$old){throw 'whole inverse'}
$null=New-Item -ItemType Directory -Path (Abs $out)
$scriptSha=NewText ($out+'test_ROOT_REVIEW.gd') $new
$fixture=@{status='ONE25F_ALLEY_MATERIAL_RESIDUAL_ROOT_MUST_READ_BEFORE_GPU';parent_path=$parent;parent_sha256=$parentSha;script_path=($out+'test_ROOT_REVIEW.gd');script_sha256=$scriptSha;inputs_changed_only=$pins;inherited_parent_actual='res://build/luoyang_city_revision_20261025f_qa01/overview01_output/48252_2688/result.json';parent_actual_checks=350;parent_actual_failures=0;parent_ART_local_rejected_dark_alley=$true;new_functional_assertions=0;unchanged_parent_renderer_scaffold=$true;whole_ms=60000;pictures=1;image_size=@(1536,1024);world_size=@(3072,2048);uniform_scale=.5;Sprite_count=43;material_sprites=6;NPC_Player_Field=0;geometry_raster_packet_replays=0;no_loading_or_formal_ART_credit=$true;root_sole_GPU=$true;engine_runs=0;formal_writes=0}
$fixtureSha=NewText ($out+'fixture_ROOT_REVIEW.json') ($fixture|ConvertTo-Json -Depth 30)
$proof=@{status='NEW_ONLY_FIVE_MECHANICAL_REPLACEMENTS_ROOT_REVIEW';parent_path=$parent;parent_sha256=$parentSha;candidate_sha256=$scriptSha;fixture_sha256=$fixtureSha;hunks=$reps;whole_forward_inverse=$true;EOF_preserved=$true;engine=0;formal_writes=0}
$proofSha=NewText ($out+'whole_byte_delta_ROOT_REVIEW.json') ($proof|ConvertTo-Json -Depth 30)
@{script_sha256=$scriptSha;fixture_sha256=$fixtureSha;proof_sha256=$proofSha}|ConvertTo-Json -Compress
