$ErrorActionPreference='Stop'
$game=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
function Abs([string]$p){return Join-Path $game $p.Substring(6)}
function NewText([string]$p,[string]$s){$a=Abs $p;if(Test-Path -LiteralPath $a){throw 'exclusive new'};[IO.File]::WriteAllText($a,$s,[Text.UTF8Encoding]::new($false));return (Get-FileHash -LiteralPath $a).Hash.ToLowerInvariant()}
$parent='res://build/luoyang_city_revision_20261024e_qa01/market_overview04_READABLE_PROFILES_READY/test_READY.gd'
$parentSha='9a5e4f354887d42ff250ec9e60c1c69a5cf71c4e4eda624ca79213e0c07902d9'
if((Get-FileHash -LiteralPath (Abs $parent)).Hash.ToLowerInvariant()-cne$parentSha){throw 'frozen parent'}
$pins=@{
 'res://build/luoyang_street_materials_20261025f_system01/market_purpose_layer_BUILD.gd'='647f2adf1debb9f50b2f743b995a5205e04bd3f5a617f861a6e21a41773d8d6c'
 'res://build/luoyang_street_materials_20261025f_system01/market_five_use_spec_BUILD.json'='cade61d03248672edebaeed8ca272cbfdabeb157f19db72591967a9dd81ec034'
 'res://build/luoyang_street_materials_20261025f_system01/market_use_materials02_BUILD.gdshader'='67c042044bb18c1212c1b4e5b3a7a00b6f51204abe9937a77dfc9f2395d2b4be'
}
foreach($p in $pins.Keys){if((Get-FileHash -LiteralPath (Abs $p)).Hash.ToLowerInvariant()-cne$pins[$p]){throw ('candidate pin '+$p)}}
$out='res://build/luoyang_city_revision_20261025f_qa01/overview01_ROOT_REVIEW/'
if(Test-Path -LiteralPath (Abs $out)){throw 'new namespace only'}
$reps=@(
 @{old='const PURPOSE24E := N24E+"market_purpose_layer04_readable_profiles_NOTREADY.gd"';new='const PURPOSE24E := "res://build/luoyang_street_materials_20261025f_system01/market_purpose_layer_BUILD.gd"'},
 @{old='d9a9975b69f9ead39dc813a50379c65714931fe01d9580196b8d993518a80890';new='647f2adf1debb9f50b2f743b995a5205e04bd3f5a617f861a6e21a41773d8d6c'},
 @{old='const SPEC24E := N24E+"market_five_use_spec04_readable_profiles_NOTREADY.json"';new='const SPEC24E := "res://build/luoyang_street_materials_20261025f_system01/market_five_use_spec_BUILD.json"'},
 @{old='dda3588304159d2f2272854632eb695640ae79201ef94e65aa77cd04f2cf95b7';new='cade61d03248672edebaeed8ca272cbfdabeb157f19db72591967a9dd81ec034'},
 @{old='res://build/luoyang_city_revision_20261024e_qa01/market_overview_output/';new='res://build/luoyang_city_revision_20261025f_qa01/overview01_output/'},
 @{old='24E_ONE_EARLY_AUTHORING_OVERVIEW_60S_NO_FIELD_OR_FORMAL_CREDIT';new='25F_ONE_MATERIAL_OVERVIEW_60S_NO_FIELD_OR_FORMAL_CREDIT'}
)
$old=[IO.File]::ReadAllText((Abs $parent));$new=$old
foreach($r in $reps){if(([regex]::Matches($new,[regex]::Escape($r.old))).Count-ne1){throw 'unique hunk'};$new=$new.Replace($r.old,$r.new)}
$back=$new;for($i=$reps.Count-1;$i-ge0;$i--){$back=$back.Replace($reps[$i].new,$reps[$i].old)};if($back-cne$old){throw 'whole inverse'}
$null=New-Item -ItemType Directory -Path (Abs $out)
$scriptSha=NewText ($out+'test_ROOT_REVIEW.gd') $new
$fixture=@{status='ONE25F_OVERVIEW_ROOT_MUST_READ_BEFORE_GPU';parent_path=$parent;parent_sha256=$parentSha;script_path=($out+'test_ROOT_REVIEW.gd');script_sha256=$scriptSha;inputs_changed_only=$pins;fixed43components='res://build/luoyang_city_blocks_20261024e_system01/publication04/output/9720/components_FIXED_NOT_RUNTIME.json';components_sha256='cafee170b4e33b159c8ad769e96ceeb97987d70eb561ee9b5049a8e25e827194';fixed_render_sha256='294c4ffdcad625e2a299959b8dc2be2328980a3946316d016f37793dbef112c6';same_parent350_scaffold=$true;whole_ms=60000;pictures=1;image_size=@(1536,1024);world_size=@(3072,2048);uniform_scale=.5;Sprite_count=43;material_sprites=6;NPC_Player_Field=0;geometry_raster_packet_replays=0;no_loading_or_formal_ART_credit=$true;root_sole_GPU=$true;engine_runs=0;formal_writes=0}
$fixtureSha=NewText ($out+'fixture_ROOT_REVIEW.json') ($fixture|ConvertTo-Json -Depth 30)
$proof=@{status='NEW_ONLY_SIX_MECHANICAL_REPLACEMENTS_ROOT_REVIEW';parent_path=$parent;parent_sha256=$parentSha;candidate_sha256=$scriptSha;fixture_sha256=$fixtureSha;hunks=$reps;whole_forward_inverse=$true;EOF_preserved=$true;engine=0;formal_writes=0}
$proofSha=NewText ($out+'whole_byte_delta_ROOT_REVIEW.json') ($proof|ConvertTo-Json -Depth 30)
@{script_sha256=$scriptSha;fixture_sha256=$fixtureSha;proof_sha256=$proofSha}|ConvertTo-Json -Compress
