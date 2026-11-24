param(
 [Parameter(Mandatory=$true)][ValidateSet('before','after')][string]$Mode,
 [string]$BeforeSHA='', [string]$Workspace='F:\Code\RPG_GAME'
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$priorTool=Join-Path $Workspace 'game/build/luoyang_city_full_rollout_20261022ap_root01/guard_integration33.ps1'
if((Get-FileHash -LiteralPath $priorTool -Algorithm SHA256).Hash.ToLowerInvariant() -cne '0d5dc172a0f5028ba5005fd7500ec03eb430785dedc86211f72925dcb826f5b9'){throw 'FROZEN33_TOOL_REQUIRED'}
$failPath=Join-Path $Workspace 'game/build/luoyang_city_full_rollout_20261022ap_root01/integration33/final_guard.json'
if((Get-FileHash -LiteralPath $failPath -Algorithm SHA256).Hash.ToLowerInvariant() -cne '9944e3be37d89a949915b3f7a622a3c960c1036f8a11839b87ae44dc295eaf86'){throw 'RETAIN33_REAL_FAILURE'}
$failed=Get-Content -LiteralPath $failPath -Raw|ConvertFrom-Json -AsHashtable
$tasks=[IO.Path]::GetFullPath((Join-Path $Workspace 'prompts/tasks.yaml'))
if($failed.passed -ne $false -or $failed.checked -ne 2118 -or $failed.unexpected_change_count -ne 1 -or $failed.save_change_count -ne 0 -or $failed.unexpected_changes[0].path -ine $tasks -or $failed.unexpected_changes[0].after.sha256 -cne '9c27ffc9f97a9ba2c238f6da8a7bdab193027e1622445d086be8b727d7b56544'){throw 'ONLY_DOCUMENTED_EXTERNAL_TASKS_DRIFT_NOT_RETROACTIVE_AUTH'}
if($Mode -ceq 'before' -and (Get-FileHash -LiteralPath $tasks -Algorithm SHA256).Hash.ToLowerInvariant() -cne '9c27ffc9f97a9ba2c238f6da8a7bdab193027e1622445d086be8b727d7b56544'){throw 'NEW_EXTERNAL_BASELINE_OBSERVATION_REQUIRED'}
# Preserve the failed33 epoch. Reuse valid32's PATH domain only, freshly read
# CURRENT facts including external tasks9C27. No prior write is authorized.
$original=[IO.File]::ReadAllText($priorTool)
$old="'game/build/luoyang_city_full_rollout_20261022ap_root01/integration33'"
$new="'game/build/luoyang_city_full_rollout_20261022ap_root01/integration34'"
if(!$original.Contains($old)){throw 'EXACT_OUTPUT_SUCCESSOR_REQUIRED'}
$next=$original.Replace($old,$new)
if($next.Replace($new,$old) -cne $original){throw 'WHOLE_TOOL_INVERSE_REQUIRED'}
& ([scriptblock]::Create($next)) -Mode $Mode -BeforeSHA $BeforeSHA -Workspace $Workspace
