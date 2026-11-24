param(
 [Parameter(Mandatory=$true)][ValidateSet('before','authorize','after')][string]$Mode,
 [string]$BeforeSHA='',
 [string]$PlanPath='',
 [string]$PlanSHA='',
 [string]$AuthorizationSHA='',
 [string]$Workspace='F:\Code\RPG_GAME'
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
# Reuse the fully reviewed exact guard, changing only the NEW output epoch.
# No old report, canonical file or timestamp is written by this wrapper.
$guardPath=Join-Path $Workspace 'game/build/luoyang_city_full_rollout_20261022ap_root01/guard_integration11.ps1'
$guardSha=(Get-FileHash -LiteralPath $guardPath -Algorithm SHA256).Hash.ToLowerInvariant()
if($guardSha -cne '08c4f0553b0825641207b057c50ef5b12e8e6b52deb16d3f24d8099bf9611047'){throw 'FIXED_INTEGRATION11_GUARD_CHANGED'}
$original=[IO.File]::ReadAllText($guardPath)
$needle="'game/build/luoyang_city_full_rollout_20261022ap_root01/integration11'"
$replacement="'game/build/luoyang_city_full_rollout_20261022ap_root01/integration12'"
if(([regex]::Matches($original,[regex]::Escape($needle))).Count -ne 1){throw 'EXACT_ONE_OUTPUT_EPOCH_REPLACEMENT_REQUIRED'}
$successor=$original.Replace($needle,$replacement)
if($successor.Replace($replacement,$needle) -cne $original){throw 'GUARD_COMPLETE_INVERSE_REQUIRED'}
$guard=[scriptblock]::Create($successor)
& $guard -Mode $Mode -BeforeSHA $BeforeSHA -PlanPath $PlanPath -PlanSHA $PlanSHA -AuthorizationSHA $AuthorizationSHA -Workspace $Workspace
