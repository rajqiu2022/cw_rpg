$ErrorActionPreference='Stop'
$game=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
function Abs([string]$p){return Join-Path $game $p.Substring(6)}
function WriteNew([string]$p,[string]$v){$a=Abs $p;if(Test-Path -LiteralPath $a){throw 'exclusive new'};[IO.File]::WriteAllText($a,$v,[Text.UTF8Encoding]::new($false));return (Get-FileHash -LiteralPath $a).Hash.ToLowerInvariant()}
$parent='res://build/luoyang_city_revision_20261025f_qa01/field01_MATERIALS_READY/test_READY.gd'
$parentSHA='882c728fdf1f4b7baf87f9456a29078c4d72d4df699d58edbb950f77f6668634'
if((Get-FileHash -LiteralPath (Abs $parent)).Hash.ToLowerInvariant()-cne$parentSHA){throw 'fixed parent'}
$out='res://build/luoyang_city_revision_20261025f_qa01/field02_DEFAULT_ORACLE_ROOT_REVIEW/'
if(Test-Path -LiteralPath (Abs $out)){throw 'new namespace'}
$oracle=@'
func _legacy_false25f(mat: ShaderMaterial,id: String) -> bool:
	var raw: Variant=mat.get_shader_parameter("use_uv_transform")
	if typeof(raw)==TYPE_BOOL:
		return check(raw==false,"Explicit false only for legacy material "+id)
	if raw!=null or id not in ["clean_base","rear_court_and_tree_soil"]:
		return check(false,"No generic NIL/type fallback for material "+id)
	var shader_path: String="res://build/luoyang_street_materials_20261025f_system01/material_revision02/market_use_materials_BUILD.gdshader"
	var helper_path: String="res://build/luoyang_street_materials_20261025f_system01/material_revision02/market_purpose_layer_BUILD.gd"
	var shader_sha: String="84befe183f06894ee45c608c1ff49367b22d14cd2ddef38d84f81bdd58c7bbb0"
	var helper_sha: String="ece43ee0e3cf777d834cd580b0fb66a8c8ddae29ebcfb138fa566bc5971687e6"
	if not check(mat.shader.resource_path==shader_path and fixture.helper_path==helper_path and FileAccess.get_sha256(shader_path)==shader_sha and FileAccess.get_sha256(helper_path)==helper_sha,"Only exact84BE shader/ECE4 helper may interpret missing legacy override"): return false
	var shader_text: String=FileAccess.get_file_as_string(shader_path)
	var helper_text: String=FileAccess.get_file_as_string(helper_path).replace("\r\n","\n")
	var declaration: String="uniform bool use_uv_transform=false;"
	var only_optin: String="  if i<4:\n   # Only four purpose materials opt in. Clean base/tree keep the old shader path.\n   var sampling: Dictionary=group.sampling\n   material.set_shader_parameter(\"use_uv_transform\",true)"
	if not check(shader_text.count(declaration)==1 and helper_text.count(only_optin)==1 and helper_text.count("set_shader_parameter(\"use_uv_transform\"")==1,"Unique fixed defaultfalse and unique i<4-only explicit true setter, no saved/backfilled value"): return false
	records.append({"kind":"FIXED_SOURCE_SHADER_DEFAULT_NOT_GENERIC_NIL","purpose":id,"raw_override":raw,"raw_type":"TYPE_NIL","effective_static_default":false,"unique_literal":declaration,"shader_sha256":shader_sha,"helper_sha256":helper_sha,"explicit_true_scope":"only group i<4; base outside loop/tree i4","production_setters_added":0})
	return true

'@
$oldNatural='if not check(natural.get("scene")==scene and natural.get("id")==MARKET_25F and natural.get("sources_finalized")==true and int(natural.get("token",0))>0 and natural.get("sources",{})==fixture.expected_city_sources,"Natural complete new FINAL versus exact Source map; no collector"): return false'
$newNatural='if not (natural.get("scene")==scene and natural.get("id")==MARKET_25F and natural.get("sources_finalized")==true and int(natural.get("token",0))>0 and natural.get("sources",{})==fixture.expected_city_sources): return check(false,"Passive exact1877 new FINAL owner missing; no retry/collector")' + "`n`t" + 'records.append({"kind":"PASSIVE_NEW_COMPLETE_FINAL_REMAINING_ONLY","sources":natural.sources.size(),"token":str(natural.token),"parent_actual":"98160_2827/FE13A7B8","prior_complete_source_admission_credit_preserved":true,"new_source_performance_credit":false})'
$reps=@(
 @{old='func _material_readback25f() -> bool:';new=($oracle+"`n"+'func _material_readback25f() -> bool:')},
 @{old=$oldNatural;new=$newNatural},
 @{old='if not check(mat.get_shader_parameter("use_uv_transform")==false,"Clean base stays exact legacy shader branch"): return false';new='if not _legacy_false25f(mat,id): return false'},
 @{old='if not check(mat.get_shader_parameter("use_uv_transform")==false,"Tree soil retains original legacy UV/COLOR branch"): return false';new='if not _legacy_false25f(mat,id): return false'},
 @{old='res://build/luoyang_city_revision_20261025f_qa01/field01_output/';new='res://build/luoyang_city_revision_20261025f_qa01/field02_output/'},
 @{old='25F_ONE_MATERIAL_FIELD_IMAGE_ONE_APPROVED_POSE_NOTREADY';new='25F_REMAINING_MATERIALS_FIXED_DEFAULT_ORACLE_ONE_POSE_ONE_IMAGE'}
)
$old=[IO.File]::ReadAllText((Abs $parent));$new=$old
foreach($r in $reps){if(([regex]::Matches($new,[regex]::Escape($r.old))).Count-ne1){throw ('unique '+$r.old)};$new=$new.Replace($r.old,$r.new)}
$back=$new;for($i=$reps.Count-1;$i-ge0;$i--){$back=$back.Replace($reps[$i].new,$reps[$i].old)};if($back-cne$old){throw 'whole inverse'}
$null=New-Item -ItemType Directory -Path (Abs $out)
$h=WriteNew ($out+'test_ROOT_REVIEW.gd') $new
$proof=@{status='REMAINING_ONLY_FIXED_TWO_DEFAULTS_ROOT_REVIEW_NO_ENGINE';parent_path=$parent;parent_sha256=$parentSHA;candidate_sha256=$h;hunks=$reps;whole_byte_inverse=$true;parent_actual=@{path='res://build/luoyang_city_revision_20261025f_qa01/field01_output/98160_2827/result.json';sha256='fe13a7b8b589cd7e8e897fd1dbc15aa9856851ef52e93a1becef5c7ac26d17e6';checks=26;failures=2;whole_FAIL_preserved=$true;passed_prefix='ordinary11701860 hiddenoperable setup / complete1877 naturalFINAL / sixsprites / cleanbase source metadata';pose_writes=0;PNG=0};fixture_unchanged='res://build/luoyang_city_revision_20261025f_qa01/field01_MATERIALS_READY/fixture_READY.json';fixture_sha256='141f5b32aa910ea2cb12964384841badc7f4d0089920a9bf497e9b2b6764acff';default_oracle_only=@('clean_base','rear_court_and_tree_soil');source_pins=@{shader='84befe183f06894ee45c608c1ff49367b22d14cd2ddef38d84f81bdd58c7bbb0';helper='ece43ee0e3cf777d834cd580b0fb66a8c8ddae29ebcfb138fa566bc5971687e6'};non_NIL_wrong_values_rejected=$true;all_four_explicit_true_checks_unchanged=$true;whole_ms=60000;entry_ms=20000;one_safe_pose=@(1660,1468);maxPNG=1;INPUT=0;Space=0;production_setters=0;engine_calls=0;formal_writes=0}
$ph=WriteNew ($out+'whole_byte_delta_ROOT_REVIEW.json') ($proof|ConvertTo-Json -Depth 30)
@{script_sha256=$h;proof_sha256=$ph;engine_calls=0}|ConvertTo-Json -Compress
