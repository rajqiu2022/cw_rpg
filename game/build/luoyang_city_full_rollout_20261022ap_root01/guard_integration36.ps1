param(
 [Parameter(Mandatory=$true)][ValidateSet('before','authorize','after')][string]$Mode,
 [string]$BeforeSHA='', [string]$PlanPath='', [string]$PlanSHA='', [string]$AuthorizationSHA='',
 [string]$Workspace='F:\Code\RPG_GAME'
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$parentTool=Join-Path $Workspace 'game/build/luoyang_city_full_rollout_20261022ap_root01/guard_integration35.ps1'
if((Get-FileHash -LiteralPath $parentTool -Algorithm SHA256).Hash.ToLowerInvariant() -cne '752275cdd3b9689ec78a61f93f32cf3b38b47bf9412b0678605df8a68e990b1c'){throw 'FIXED35_TOOL_REQUIRED'}
$failedPath=Join-Path $Workspace 'game/build/luoyang_city_full_rollout_20261022ap_root01/integration35/final_guard.json'
if((Get-FileHash -LiteralPath $failedPath -Algorithm SHA256).Hash.ToLowerInvariant() -cne 'eda9e0e3797528f2b1f3e27127b2709430ac4fc717dfdc20971f9e48b7be131e'){throw 'KEEP_ORIGINAL35_TIMESTAMP_FAILURE'}
$failed=Get-Content -LiteralPath $failedPath -Raw|ConvertFrom-Json -AsHashtable
if($failed.passed -ne $false -or $failed.all_changes.Count -ne 2 -or $failed.save_change_count -ne 0 -or $failed.authorized_change_count -ne 0){throw 'ONLY_DOCUMENTED_PREDEPLOY_TIME_DRIFT'}
$expected=@('f583203a326a4750428a0a6689c7d35dadd749408eb051c8bb1d6200cb9293a8','b72003ea99c91ebe744bee65218c5d37f72ff87a3a28668cc7f576bcd430b7f2')
foreach($r in $failed.all_changes){if($r.before.sha256 -cne $r.after.sha256 -or $r.before.bytes -ne $r.after.bytes -or $r.after.sha256 -cnotin $expected){throw 'NOT_SAME_BYTE_IMPORT_METADATA_TIMESTAMP_ONLY'}}
# Keep35 FAIL and exact current imported bytes/timestamps; no restoration,
# late whitelist or second Stage. Inherit valid34's path domain, not values.
$original=[IO.File]::ReadAllText($parentTool)
$old="'game/build/luoyang_city_full_rollout_20261022ap_root01/integration35'"
$new="'game/build/luoyang_city_full_rollout_20261022ap_root01/integration36'"
if(!$original.Contains($old)){throw 'EXACT_OUTPUT_SUCCESSOR_REQUIRED'}
$next=$original.Replace($old,$new)
if($next.Replace($new,$old) -cne $original){throw 'WHOLE_TOOL_INVERSE_REQUIRED'}
& ([scriptblock]::Create($next)) -Mode $Mode -BeforeSHA $BeforeSHA -PlanPath $PlanPath -PlanSHA $PlanSHA -AuthorizationSHA $AuthorizationSHA -Workspace $Workspace
