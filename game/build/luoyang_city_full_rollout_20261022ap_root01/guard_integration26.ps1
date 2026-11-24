param(
 [Parameter(Mandatory=$true)][ValidateSet('before','after')][string]$Mode,
 [string]$BeforeSHA='',
 [string]$Workspace='F:\Code\RPG_GAME'
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$parentTool=Join-Path $Workspace 'game/build/luoyang_city_full_rollout_20261022ap_root01/guard_integration11.ps1'
if((Get-FileHash -LiteralPath $parentTool -Algorithm SHA256).Hash.ToLowerInvariant() -cne '08c4f0553b0825641207b057c50ef5b12e8e6b52deb16d3f24d8099bf9611047'){throw 'FIXED_GUARD_BASE_CHANGED'}
$original=[IO.File]::ReadAllText($parentTool)
$changes=@(
 @("'game/build/luoyang_city_full_rollout_20261022ap_root01/integration11'","'game/build/luoyang_city_full_rollout_20261022ap_root01/integration26'"),
 @("'game/build/luoyang_market_two_shops_20261021ao_root01/integration1/final_guard.json'","'game/build/luoyang_city_full_rollout_20261022ap_root01/integration25/final_guard.json'"),
 @("'9295e222f77080ff2d18298c6847774a6d552e9a6a56ad9e7b2d8cd41fd90632'","'478f624b666ceb55346343fb60e4e21cc10a009e0ea459438a95446d020098c9'"),
 @('2105','2117'),
 @('FROM_AO_PATHS_NOT_VALUES','FROM_AP25_PATHS_NOT_VALUES'),
 @("'AO_INTEGRATION1_FINAL_CURRENT2101_PLUS_LOCKED_DEPLOYMENT_TARGETS'","('AP_FULL_CITY_FINAL_CURRENT'+'2117'+'_PLUS_LOCKED_DEPLOYMENT_TARGETS')")
)
$next=$original
foreach($change in $changes){if(!$next.Contains($change[0])){throw 'EXACT_GUARD_SUCCESSOR_HUNK_MISSING'};$next=$next.Replace($change[0],$change[1])}
$inverse=$next
for($i=$changes.Count-1;$i -ge 0;$i--){$inverse=$inverse.Replace($changes[$i][1],$changes[$i][0])}
if($inverse -cne $original){throw 'COMPLETE_GUARD_SOURCE_INVERSE_REQUIRED'}
& ([scriptblock]::Create($next)) -Mode $Mode -BeforeSHA $BeforeSHA -Workspace $Workspace
