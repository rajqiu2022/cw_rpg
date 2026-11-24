$ErrorActionPreference='Stop'
$parent=Join-Path $PSScriptRoot 'finite_Field03_INSPECTIONS_NOTREADY/test_NOTREADY.gd'
$out=Join-Path $PSScriptRoot 'finite_Field04_AWAIT_NOTREADY'
if((Get-FileHash -LiteralPath $parent).Hash -cne '62A0D3C3627FFE8BAF2BD2440B6294154C253846B1210F1E22F80DB8F4AFBE16'){throw 'parent03'}
if(Test-Path -LiteralPath $out){throw 'NEW only'}
$reps=@(@{old='if not _warehouse_door_overlap(): return false';new='if not await _warehouse_door_overlap(): return false'},@{old='finite_Field03_INSPECTIONS_NOTREADY/fixture_PENDING_FINAL_SOURCE.json';new='finite_Field04_AWAIT_NOTREADY/fixture_PENDING_FINAL_SOURCE.json'},@{old='finite_Field03_output/';new='finite_Field04_output/'})
$old=[IO.File]::ReadAllText($parent);$new=$old
foreach($r in $reps){if(([regex]::Matches($new,[regex]::Escape($r.old))).Count-ne1){throw 'unique hunk'};$new=$new.Replace($r.old,$r.new)}
$back=$new;for($i=$reps.Count-1;$i-ge0;$i--){$back=$back.Replace($reps[$i].new,$reps[$i].old)};if($back-cne$old){throw 'whole inverse'}
$null=New-Item -ItemType Directory -Path $out
[IO.File]::WriteAllText((Join-Path $out 'test_NOTREADY.gd'),$new,[Text.UTF8Encoding]::new($false))
$sha=(Get-FileHash -LiteralPath (Join-Path $out 'test_NOTREADY.gd')).Hash
$proof=@{status='ROOT_REVIEWED_ASYNC_DOOR_AWAIT_FIX_NO_ENGINE';parent_sha256='62A0D3C3627FFE8BAF2BD2440B6294154C253846B1210F1E22F80DB8F4AFBE16';candidate_sha256=$sha;hunks=$reps;whole_inverse=$true;parent_inverse_path='res://build/luoyang_city_revision_20261024e_docks_qa01/finite_Field03_INSPECTIONS_NOTREADY/whole_byte_delta_NOTREADY.json';parent_inverse_sha256='B39E9C076A781739081F016F1C9F13CBE8B0F97C92C69B75F19F2DF9DF17CD2A';whole_ms=60000;entry_ms=20000;inspection_setups=3;ready=$false;source_final_map_pending=$true;engine=0;formal_writes=0}
[IO.File]::WriteAllText((Join-Path $out 'whole_byte_delta_NOTREADY.json'),($proof|ConvertTo-Json -Depth 30),[Text.UTF8Encoding]::new($false))
@{script_sha256=$sha;proof_sha256=(Get-FileHash -LiteralPath (Join-Path $out 'whole_byte_delta_NOTREADY.json')).Hash}|ConvertTo-Json -Compress
