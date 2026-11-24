$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$game=Join-Path $repo 'game';$q='res://build/luoyang_city_revision_20261025g_qa01/'
function Abs([string]$path){if($path.StartsWith('res://')){return Join-Path $game $path.Substring(6)};return $path}
function Pin([string]$path,[string]$expected){$raw=[IO.File]::ReadAllBytes((Abs $path));if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($raw)).ToLowerInvariant() -ne $expected){throw "Pin $path"};return [Text.Encoding]::UTF8.GetString($raw)}
function WriteNew([string]$path,[object]$value,[bool]$raw=$false){$a=Abs $path;if(Test-Path -LiteralPath $a){throw "Preserve $path"};$text=if($raw){[string]$value}else{($value|ConvertTo-Json -Depth 100)+"`n"};[IO.File]::WriteAllText($a,$text,[Text.UTF8Encoding]::new($false));return @{path=$path;sha256=(Get-FileHash -LiteralPath $a -Algorithm SHA256).Hash.ToLowerInvariant()}}
function Once([string]$text,[string]$old,[string]$new){if($text.Split($old,[StringSplitOptions]::None).Count -ne 2){throw "Unique exact replacement $old"};return $text.Replace($old,$new)}
$deployment=@{path='res://build/luoyang_city_revision_20261025g_root01/courtyard45_32_deployed_actual.json';sha256='7f2a7be12b86f3021d87dfc0f74294e2961c3ef376e4c8bb533cc59a74870071'}
$deployed=(Pin $deployment.path $deployment.sha256)|ConvertFrom-Json -AsHashtable
if($deployed.passed -ne $true -or $deployed.targets.Count -ne 32 -or $deployed.target_count -ne 32 -or $deployed.target_partition.patch_count -ne 17 -or $deployed.target_partition.copy_count -ne 15 -or $deployed.JSON15_written.Count -ne 15 -or $deployed.stage_sha256 -ne 'c972f71442cc6573d8e55a92bf0ce875039879be651dd30e3fd32df585d97396'){throw 'Exact actualdeployment32'}
$fieldParent=@{path=$q+'Field01_NOTREADY/fixture_stage02_NOTREADY.json';sha256='2bc545d67a9c6a861b0c9ab3b49834a19d5686c0352cd8bb25f4a47fb0deb003'}
$guardParent=@{path=$q+'guard32_fixture_stage02_NOTREADY.json';sha256='be4446006d652acc4b41306359df117234f64cd542e0356b8c8c7d52218783a9'}
$fieldOld=Pin $fieldParent.path $fieldParent.sha256;$guardOld=Pin $guardParent.path $guardParent.sha256
$field=$fieldOld|ConvertFrom-Json -AsHashtable;$guard=$guardOld|ConvertFrom-Json -AsHashtable
foreach($fixture in @($field,$guard)){$fixture.ready=$true;$fixture.formal_deployed=$true;$fixture.deployment=$deployment}
$field.status='ROOT_READY_TWO25G_INSPECTIONS_NEW45_FINAL_SHORT_INPUT_ONE_IMAGE_NOT_PERFORMANCE';$guard.status='ROOT_READY_EXACT32_DEPLOYED_2121_PLUS_TWO_MEDIA_148_BACKUPS_FIXED33'
$stage=(Pin $field.stage.path $field.stage.sha256)|ConvertFrom-Json -AsHashtable
foreach($row in $deployed.targets){$c=@($stage.targets|Where-Object target -eq $row.target);if($c.Count -ne 1 -or $c[0].candidate_sha256 -ne $row.sha256){throw "Actual deployment mismatch $($row.target)"}}
$dir=Abs ($q+'Field01_ROOT_READY');if(Test-Path -LiteralPath $dir){throw 'PreserveREADY'};[IO.Directory]::CreateDirectory($dir)|Out-Null
$fieldPin=WriteNew ($q+'Field01_ROOT_READY/fixture_READY.json') $field
$guardPin=WriteNew ($q+'guard32_fixture_ROOT_READY.json') $guard
$testParent=@{path=$q+'Field01_NOTREADY/test_NOTREADY.gd';sha256='e7b201324e3f1a193c560a41e74f14ff6622453228f5f51c3c9f315519da373c'}
$testOld=Pin $testParent.path $testParent.sha256;$test=$testOld
$test=Once $test 'const COURTS_READY25G=false' 'const COURTS_READY25G=true'
$test=Once $test 'PENDING_FINAL25G_SOURCE_FIXTURE' $fieldPin.path
$test=Once $test 'PENDING_FINAL25G_SOURCE_SHA' $fieldPin.sha256
$test=Once $test 'Field01_output/' 'Field01_ROOT_READY_output/'
$test=Once $test '25G_TWO_EXPLICIT_INSPECTIONS_SHORT_INPUT_OPAQUE_NEW_PROPS_ACTOR_GHOST_ONE_IMAGE_NOTREADY' '25G_TWO_EXPLICIT_INSPECTIONS_SHORT_INPUT_OPAQUE_NEW_PROPS_ACTOR_GHOST_ONE_IMAGE_ROOT_READY'
$testPin=WriteNew ($q+'Field01_ROOT_READY/test_READY.gd') $test $true
$guardCodeParent=@{path=$q+'guard32_NOTREADY.py';sha256='eb33b3284db5b9dd107d94c88341eeb23517bf8a4c3ce4536d7eaaf259366518'}
$guardCodeOld=Pin $guardCodeParent.path $guardCodeParent.sha256
$oldAssertion="assert deploy['stage_sha256'].lower()==fixture['stage']['sha256'] and deploy['GD_apply_patch']==17 and deploy['JSON_exact_copy']==15"
$newAssertion="assert deploy['passed'] is True and deploy['status']=='ROOT_EXACT32_DEPLOYED_GD17_PATCH_JSON15_EXACTCOPY' and deploy['stage_sha256'].lower()==fixture['stage']['sha256'] and deploy['target_partition']==dict(patch_count=17,copy_count=15,total=32) and len(deploy['JSON15_written'])==15"
$guardCode=Once $guardCodeOld $oldAssertion $newAssertion
$guardCodePin=WriteNew ($q+'guard32_ROOT_READY.py') $guardCode $true
$delta=[ordered]@{status='QA_ONLY_STAGE02_FREEZE_COMPLETE_FORWARD_REVERSE_TEXT_NO_FUNCTION_CHANGE';formal_writes=0;engine_calls=0;guard_calls=0;hunks=@(@{parent=$fieldParent;child=$fieldPin;old_text=$fieldOld;new_text=([IO.File]::ReadAllText((Abs $fieldPin.path)));reverse_old_text=([IO.File]::ReadAllText((Abs $fieldPin.path)));reverse_new_text=$fieldOld},@{parent=$guardParent;child=$guardPin;old_text=$guardOld;new_text=([IO.File]::ReadAllText((Abs $guardPin.path)));reverse_old_text=([IO.File]::ReadAllText((Abs $guardPin.path)));reverse_new_text=$guardOld},@{parent=$testParent;child=$testPin;old_text=$testOld;new_text=$test;reverse_old_text=$test;reverse_new_text=$testOld},@{parent=$guardCodeParent;child=$guardCodePin;old_text=$guardCodeOld;new_text=$guardCode;reverse_old_text=$guardCode;reverse_new_text=$guardCodeOld})}
$deltaPin=WriteNew ($q+'final_stage02_ROOT_READY_whole_byte_delta.json') $delta
@{field=$testPin;field_fixture=$fieldPin;guard=$guardCodePin;guard_fixture=$guardPin;whole_inverse=$deltaPin;formal_deployed=$true;engine_calls=0;guard_calls=0}|ConvertTo-Json -Depth 5
