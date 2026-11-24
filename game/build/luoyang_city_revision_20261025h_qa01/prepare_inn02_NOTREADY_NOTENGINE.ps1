$ErrorActionPreference='Stop'
$base='F:/Code/RPG_GAME/game/build/luoyang_city_revision_20261025h_qa01'
$parent=Join-Path $base 'inn01_NOTREADY.gd'
if((Get-FileHash -LiteralPath $parent -Algorithm SHA256).Hash -ne 'C424C8B02F30D5BC835FB84B7E04E6C3F80558C66E0CA0F782CD25725DF6A39B'){throw 'Pin original hardfalse'}
$old=[IO.File]::ReadAllText($parent);$text=$old
function Once([string]$s,[string]$a,[string]$b){if($s.Split($a,[StringSplitOptions]::None).Count -ne 2){throw "Unique $a"};return $s.Replace($a,$b)}
$text=Once $text 'fixture.meal_price==5 and fixture.lodging_price==20' 'fixture.meal_price==5 and fixture.lodging_price==20 and fixture.full_party_policy=="NO_CHARGE_REJECT"'
$text=Once $text 'tiny.max_hp=3;tiny.max_mp=1;tiny.hp=1;tiny.mp=0' 'tiny.max_hp=3;tiny.max_mp=1;tiny.hp=0;tiny.mp=0'
$needle="func exercise_cpu() -> bool:"
$addition=@'
func _legitimate_new_meal_session25h() -> bool:
	var before: Dictionary=ORACLE25H.snapshot(gs25h)
	if not check(not ORACLE25H.all_full(before) and before.gold>=5,"New legitimate session has current damaged party and sufficient current gold"): return false
	var expected: Dictionary=ORACLE25H.expected(before,"meal",true)
	if not await adapter25h.call("real_open_service_and_decide",self,"meal","confirm"): return false
	var after: Dictionary=ORACLE25H.snapshot(gs25h)
	if not check(after==expected,"Fresh legal menu can consume again; no permanent consumed flag"): return false
	records.append({"kind":"25H_LEGITIMATE_NEW_MEAL_SESSION","before":before,"after":after,"deltas":ORACLE25H.deltas(before,after),"same_request_replay":false,"intermediate_memory_setup":false})
	completed25h.append("meal/fresh_legal_session/confirm")
	return true

'@
$text=Once $text $needle ($addition+$needle)
$needle2='if not await adapter25h.call("assert_same_confirmation_replay_no_side_effect",self,service): return false'
$add2=$needle2+"`n`t`tif service==`"meal`" and not await _legitimate_new_meal_session25h(): return false"
$text=Once $text $needle2 $add2
$text=Once $text 'inn01_output/' 'inn02_output/'
$target=Join-Path $base 'inn02_NOTREADY.gd';if(Test-Path -LiteralPath $target){throw 'Preserve original02'}
[IO.File]::WriteAllText($target,$text,[Text.UTF8Encoding]::new($false))
$sha=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant()
$delta=@{status='HARDFALSE_ROOT_POLICY_UPDATE_ONLY_NOT_ENGINE';parent=@{path='res://build/luoyang_city_revision_20261025h_qa01/inn01_NOTREADY.gd';sha256='c424c8b02f30d5bc835fb84b7e04e6c3f80558c66e0ca0f782cd25725df6a39b'};child=@{path='res://build/luoyang_city_revision_20261025h_qa01/inn02_NOTREADY.gd';sha256=$sha};old_text=$old;new_text=$text;reverse_old_text=$text;reverse_new_text=$old;Root_policy='Both full=no charge;hp0 companion eligible;new legal session may consume again';implementation_writes=0;engine_calls=0}
$dp=Join-Path $base 'inn02_whole_delta_NOTRUN.json';if(Test-Path -LiteralPath $dp){throw 'Preserve delta'};[IO.File]::WriteAllText($dp,(($delta|ConvertTo-Json -Depth 7)+"`n"),[Text.UTF8Encoding]::new($false))
@{path=$target;sha256=$sha;whole_delta_sha256=(Get-FileHash -LiteralPath $dp -Algorithm SHA256).Hash.ToLowerInvariant();engine_calls=0}|ConvertTo-Json
