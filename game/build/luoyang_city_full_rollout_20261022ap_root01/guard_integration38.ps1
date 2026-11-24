param([Parameter(Mandatory=$true)][ValidateSet('before','after')][string]$Mode,[string]$BeforeSHA='', [string]$Workspace='F:\Code\RPG_GAME')
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$tool=Join-Path $Workspace 'game/build/luoyang_city_full_rollout_20261022ap_root01/guard_integration37.ps1'
if((Get-FileHash -LiteralPath $tool -Algorithm SHA256).Hash.ToLowerInvariant() -cne '6731f9b3c19f993de44ade6fb37aa7c616f4bc006178e5ae976d656ee2c9e140'){throw 'FIXED37_GUARD_REQUIRED'}
$original=[IO.File]::ReadAllText($tool)
$changes=@(
 @("'game/build/luoyang_city_full_rollout_20261022ap_root01/integration37'","'game/build/luoyang_city_full_rollout_20261022ap_root01/integration38'"),
 @("'game/build/luoyang_city_full_rollout_20261022ap_root01/integration36/final_guard.json'","'game/build/luoyang_city_full_rollout_20261022ap_root01/integration37/final_guard.json'"),
 @('f3fd504e22d186b6196130dd641aa336ef50f8df69d32a43ef599e2d520ce6e8','c0751c78d4d5bdbb2adeccea9d3ab2d1d1d3e17d29da5d28f2fc1fb4a982a824'),
 @('FROM_AP36_PATHS_NOT_VALUES','FROM_AP37_PATHS_NOT_VALUES')
)
$next=$original
foreach($c in $changes){if(!$next.Contains($c[0])){throw 'EXACT_GUARD_SUCCESSOR_HUNK'};$next=$next.Replace($c[0],$c[1])}
$inverse=$next
for($i=$changes.Count-1;$i -ge 0;$i--){$inverse=$inverse.Replace($changes[$i][1],$changes[$i][0])}
if($inverse -cne $original){throw 'WHOLE_TOOL_INVERSE'}
& ([scriptblock]::Create($next)) -Mode $Mode -BeforeSHA $BeforeSHA -Workspace $Workspace
