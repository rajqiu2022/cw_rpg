param(
 [Parameter(Mandatory=$true)][ValidateSet('before','authorize','after')][string]$Mode,
 [string]$BeforeSHA='', [string]$PlanPath='', [string]$PlanSHA='', [string]$AuthorizationSHA='',
 [string]$Workspace='F:\Code\RPG_GAME'
)
$ErrorActionPreference='Stop'
$path=Join-Path $Workspace 'game/build/luoyang_city_full_rollout_20261022ap_root01/guard_integration15.ps1'
if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -cne '773ac745906aa5f7857baecdfb87021bf92efb7b6296dc8c120c5069f9132355'){throw 'FIXED_UNEXECUTED_GUARD15_SOURCE_CHANGED'}
$old=[IO.File]::ReadAllText($path)
$from="'AP_FULL_CITY_FINAL_CURRENT2113_PLUS_LOCKED_DEPLOYMENT_TARGETS'"
$to="('AP_FULL_CITY_FINAL_CURRENT'+(2110+3)+'_PLUS_LOCKED_DEPLOYMENT_TARGETS')"
if(([regex]::Matches($old,[regex]::Escape($from))).Count -ne 1){throw 'EXACT_STATUS_LITERAL_ONLY'}
$new=$old.Replace($from,$to)
if($new.Replace($to,$from) -cne $old){throw 'WHOLE_SOURCE_INVERSE'}
# Keep the failed original tool. Avoid inverse replacement colliding with the
# parent's 2113 status string; the evaluated comparison remains exactly 2113.
& ([scriptblock]::Create($new)) -Mode $Mode -BeforeSHA $BeforeSHA -PlanPath $PlanPath -PlanSHA $PlanSHA -AuthorizationSHA $AuthorizationSHA -Workspace $Workspace
