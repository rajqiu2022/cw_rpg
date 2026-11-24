$ErrorActionPreference='Stop'
$GameRoot='F:\Code\RPG_GAME\game'
$InputPath=Join-Path $GameRoot 'build\luoyang_city_full_rollout_20261022ap_system01\execution_input_handoff6_PENDING.json'
$Locked=Join-Path $GameRoot 'build\luoyang_city_full_rollout_20261022ap_root01\execution_ten_ROOT_LOCKED.json'
if ((Get-FileHash -LiteralPath $InputPath).Hash.ToLowerInvariant() -cne '72fab504d095fc24750b83caf32dd89ebeb3978dbfc4d79d2983a03056bdbdea') {throw 'Frozen h6 input'}
if (Test-Path -LiteralPath $Locked) {throw 'Preserve locked input'}
$Spec=Get-Content -LiteralPath $InputPath -Raw | ConvertFrom-Json -AsHashtable
if ($Spec.status -cne 'PENDING_ROOT_FINAL_CODE_FREEZE_AND_NEW_NATIVE_ART' -or $Spec.owned.Count -ne 10 -or $Spec.authority_helper_sha256 -cne '621343ea4bc1486dcd0ff16405d92ed0ec08747d10a5c503f4cd5e2507db30fd') {throw 'Closed ten/helper'}
if (@($Spec.owned | Where-Object {$_.path -like '*estate_family*'}).Count -ne 0) {throw 'EstateFamily is unchanged, not owned'}
$Spec.status='ROOT_LOCKED_AP_EXECUTABLE_TARGETS'
$Spec.output_root='res://build/luoyang_city_full_rollout_20261022ap_system01/execution_staged_root01/'
$Spec.root_scope='Only ten exact candidate code transitions and explicit historical byte inverses. No canonical deployment, media/data/geometry or Field approval; all pending actual gates remain pending.'
$Spec.root_source_input_sha256='72fab504d095fc24750b83caf32dd89ebeb3978dbfc4d79d2983a03056bdbdea'
$Spec | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $Locked -Encoding utf8NoBOM
Get-FileHash -LiteralPath $Locked
