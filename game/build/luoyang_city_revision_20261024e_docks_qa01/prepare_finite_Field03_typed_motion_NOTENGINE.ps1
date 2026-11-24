$ErrorActionPreference='Stop'
$oldPath=Join-Path $PSScriptRoot 'finite_Field02_INSPECTIONS_NOTREADY/test_NOTREADY.gd'
$out=Join-Path $PSScriptRoot 'finite_Field03_INSPECTIONS_NOTREADY'
if((Get-FileHash -LiteralPath $oldPath).Hash -cne 'A1BCD817C9019484A0F036D673B1290CA924EB3D78C759C05D1A33F3436FC17A'){throw 'immutable02'}
if(Test-Path -LiteralPath $out){throw 'NEW only'}
$reps=@(@{old='_player().set_can_move(_player().can_move)';new='_player().call("set_can_move",_player().get("can_move"))'},@{old='finite_Field02_INSPECTIONS_NOTREADY/fixture_PENDING_FINAL_SOURCE.json';new='finite_Field03_INSPECTIONS_NOTREADY/fixture_PENDING_FINAL_SOURCE.json'},@{old='finite_Field02_output/';new='finite_Field03_output/'})
$old=[IO.File]::ReadAllText($oldPath);$new=$old
foreach($r in $reps){if(([regex]::Matches($new,[regex]::Escape($r.old))).Count -ne 1){throw 'hunk multiplicity'};$new=$new.Replace($r.old,$r.new)}
$back=$new;for($i=$reps.Count-1;$i -ge 0;$i--){$back=$back.Replace($reps[$i].new,$reps[$i].old)};if($back -cne $old){throw 'inverse'}
$null=New-Item -ItemType Directory -Path $out
[IO.File]::WriteAllText((Join-Path $out 'test_NOTREADY.gd'),$new,[Text.UTF8Encoding]::new($false))
$sha=(Get-FileHash -LiteralPath (Join-Path $out 'test_NOTREADY.gd')).Hash
$proof=@{status='NEW_TYPED_CHARACTERBODY_MOTION_CALL_PREEMPTIVE_STATIC_FIX_NOT_ENGINE_FAIL';parent_sha256='A1BCD817C9019484A0F036D673B1290CA924EB3D78C759C05D1A33F3436FC17A';candidate_sha256=$sha;hunks=$reps;whole_inverse=$true;predecessor_full_inverse_path='res://build/luoyang_city_revision_20261024e_docks_qa01/finite_Field02_INSPECTIONS_NOTREADY/whole_byte_delta_NOTREADY.json';predecessor_full_inverse_sha256='489B849C42A305D018C601EFD8267B0522D8548CA7E6BE296488AC20FE709B53';reason='_player returns CharacterBody2D, use original motion method via call/get without guessing a built-in member';ready=$false;source_final_map_pending=$true;engine=0;formal_writes=0}
[IO.File]::WriteAllText((Join-Path $out 'whole_byte_delta_NOTREADY.json'),($proof|ConvertTo-Json -Depth 30),[Text.UTF8Encoding]::new($false))
@{script_sha256=$sha;proof_sha256=(Get-FileHash -LiteralPath (Join-Path $out 'whole_byte_delta_NOTREADY.json')).Hash}|ConvertTo-Json -Compress
