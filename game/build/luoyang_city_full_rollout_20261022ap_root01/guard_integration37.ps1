param([Parameter(Mandatory=$true)][ValidateSet('before','after')][string]$Mode,[string]$BeforeSHA='', [string]$Workspace='F:\Code\RPG_GAME')
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$tool=Join-Path $Workspace 'game/build/luoyang_city_full_rollout_20261022ap_root01/guard_integration35.ps1'
if((Get-FileHash -LiteralPath $tool -Algorithm SHA256).Hash.ToLowerInvariant() -cne '752275cdd3b9689ec78a61f93f32cf3b38b47bf9412b0678605df8a68e990b1c'){throw 'FIXED35_GUARD_REQUIRED'}
$original=[IO.File]::ReadAllText($tool)
$changes=@(
 @("'game/build/luoyang_city_full_rollout_20261022ap_root01/integration35'","'game/build/luoyang_city_full_rollout_20261022ap_root01/integration37'"),
 @("'game/build/luoyang_city_full_rollout_20261022ap_root01/integration34/final_guard.json'","'game/build/luoyang_city_full_rollout_20261022ap_root01/integration36/final_guard.json'"),
 @('298336610cfd9c97a80f7c22395d3810e8e8e1f6372dfdd3b09910061dac5832','f3fd504e22d186b6196130dd641aa336ef50f8df69d32a43ef599e2d520ce6e8'),
 @('FROM_AP34_PATHS_NOT_VALUES','FROM_AP36_PATHS_NOT_VALUES')
)
$next=$original
foreach($c in $changes){if(!$next.Contains($c[0])){throw 'EXACT_GUARD_SUCCESSOR_HUNK'};$next=$next.Replace($c[0],$c[1])}
$inverse=$next
for($i=$changes.Count-1;$i -ge 0;$i--){$inverse=$inverse.Replace($changes[$i][1],$changes[$i][0])}
if($inverse -cne $original){throw 'WHOLE_TOOL_INVERSE'}
& ([scriptblock]::Create($next)) -Mode $Mode -BeforeSHA $BeforeSHA -Workspace $Workspace
