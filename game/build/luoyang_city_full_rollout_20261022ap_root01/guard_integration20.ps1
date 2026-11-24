param(
 [Parameter(Mandatory=$true)][ValidateSet('before','after')][string]$Mode,
 [string]$BeforeSHA='',
 [string]$Workspace='F:\Code\RPG_GAME'
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$parentTool=Join-Path $Workspace 'game/build/luoyang_city_full_rollout_20261022ap_root01/guard_integration19.ps1'
if((Get-FileHash -LiteralPath $parentTool -Algorithm SHA256).Hash.ToLowerInvariant() -cne 'fa5b67fd93d6b7a9f2c23f0633e2f439844f8a1e8db1da371502673dedff7179'){throw 'FIXED_GUARD_PARENT_CHANGED'}
$original=[IO.File]::ReadAllText($parentTool)
$changes=@(
 @("'game/build/luoyang_city_full_rollout_20261022ap_root01/integration19'","'game/build/luoyang_city_full_rollout_20261022ap_root01/integration20'"),
 @("'game/build/luoyang_city_full_rollout_20261022ap_root01/integration18/final_guard.json'","'game/build/luoyang_city_full_rollout_20261022ap_root01/integration19/final_guard.json'"),
 @("'ea3d7b5fd359dedab0d253cee4c59ca9d89144935bbf3b98032249f0c7b9f999'","'0cc0e7727a78de774e31a71c602426d8377ad4b1c38ad0937b357b14ae96551c'")
)
$next=$original
foreach($change in $changes){if(!$next.Contains($change[0])){throw 'EXACT_GUARD_SUCCESSOR_HUNK_MISSING'};$next=$next.Replace($change[0],$change[1])}
$inverse=$next
for($i=$changes.Count-1;$i -ge 0;$i--){$inverse=$inverse.Replace($changes[$i][1],$changes[$i][0])}
if($inverse -cne $original){throw 'COMPLETE_GUARD_SOURCE_INVERSE_REQUIRED'}
& ([scriptblock]::Create($next)) -Mode $Mode -BeforeSHA $BeforeSHA -Workspace $Workspace
