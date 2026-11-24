param(
 [Parameter(Mandatory=$true)][ValidateSet('before','authorize','after')][string]$Mode,
 [string]$BeforeSHA='', [string]$PlanPath='', [string]$PlanSHA='', [string]$AuthorizationSHA='',
 [string]$Workspace='F:\Code\RPG_GAME'
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$base=Join-Path $Workspace 'game/build/luoyang_city_full_rollout_20261022ap_root01/guard_integration35.ps1'
if((Get-FileHash -LiteralPath $base -Algorithm SHA256).Hash.ToLowerInvariant() -cne '752275cdd3b9689ec78a61f93f32cf3b38b47bf9412b0678605df8a68e990b1c'){throw 'FIXED_BASE_CHANGED'}
$original=[IO.File]::ReadAllText($base)
$changes=@(
 @('/integration35','/integration53'),
 @('/integration34/final_guard.json','/integration52/final_guard.json'),
 @('298336610cfd9c97a80f7c22395d3810e8e8e1f6372dfdd3b09910061dac5832','d2bc533a400deda9e67f5ddda5a80b68158e0c4f440ead58bbeb357d0bf5fc70'),
 @('FROM_AP34_PATHS_NOT_VALUES','FROM_AP52_PATHS_NOT_VALUES')
)
$next=$original
foreach($c in $changes){if(!$next.Contains($c[0])){throw 'EXACT_HUNK_MISSING'};$next=$next.Replace($c[0],$c[1])}
$inverse=$next
for($i=$changes.Count-1;$i -ge 0;$i--){$inverse=$inverse.Replace($changes[$i][1],$changes[$i][0])}
if($inverse -cne $original){throw 'WHOLE_INVERSE_FAILED'}
& ([scriptblock]::Create($next)) -Mode $Mode -BeforeSHA $BeforeSHA -PlanPath $PlanPath -PlanSHA $PlanSHA -AuthorizationSHA $AuthorizationSHA -Workspace $Workspace
