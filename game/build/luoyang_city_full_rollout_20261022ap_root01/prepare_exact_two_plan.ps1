param(
 [Parameter(Mandatory=$true)][string]$Epoch,
 [Parameter(Mandatory=$true)][string]$ReceiptPath,
 [Parameter(Mandatory=$true)][string]$ReceiptSHA,
 [Parameter(Mandatory=$true)][string]$ScopeSHA,
 [Parameter(Mandatory=$true)][string]$GuardPath
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$GameRoot='F:\Code\RPG_GAME\game'
function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function Res([string]$p){if(-not $p.StartsWith('res://') -or $p.Contains('..')){throw 'Resource path'};[IO.Path]::GetFullPath((Join-Path $GameRoot $p.Substring(6)))}
$ScopePath=Join-Path $Epoch 'scope_READY.json'
if((Sha $ReceiptPath) -cne $ReceiptSHA -or (Sha $ScopePath) -cne $ScopeSHA){throw 'Root explicit actual receipt and scope pins'}
$Receipt=Get-Content -Raw $ReceiptPath|ConvertFrom-Json
$Scope=Get-Content -Raw $ScopePath|ConvertFrom-Json
if($Receipt.targets.Count -ne 2 -or $Scope.target_count -ne 2 -or $Receipt.target_partition.patch_count -ne 2 -or $Receipt.target_partition.copy_count -ne 0 -or -not $Receipt.target_partition.union_exact_targets){throw 'Exact two patches no copies'}
if((Sha (Res $Receipt.patch_path)) -cne $Receipt.patch_sha256){throw 'Exact candidate patch'}
$Targets=@()
foreach($Row in $Receipt.targets){
 $Old=@($Scope.targets|Where-Object{$_.target -ceq $Row.target})
 if($Old.Count -ne 1 -or $Old[0].old_sha256 -cne $Row.old_sha256){throw 'Exact scope'}
 $Canonical=Res $Row.target;$Candidate=Res $Row.candidate_path
 if((Sha $Canonical) -cne $Row.old_sha256 -or (Sha $Old[0].backup_path) -cne $Row.old_sha256 -or (Sha $Candidate) -cne $Row.candidate_sha256 -or (Get-Item $Candidate).Length -ne $Row.candidate_bytes){throw 'No canonical backup or candidate drift'}
 $Targets+=@{path=$Canonical;old_sha256=$Row.old_sha256;backup_path=$Old[0].backup_path;backup_sha256=$Old[0].backup_sha256;candidate_path=$Candidate;new_sha256=$Row.candidate_sha256;new_bytes=$Row.candidate_bytes}
}
$Output=Join-Path $Epoch 'predeploy_plan_READY.json'
if(Test-Path $Output){throw 'Preserve prior plan'}
& $GuardPath -Mode before
if(-not $?){throw 'Fresh guard failed'}
$BeforeSHA=Sha (Join-Path $Epoch 'guard_before.json')
@{status='ROOT_EXPLICIT_AP_FULL_CITY_PREDEPLOY_TARGETS';approved_by_root=$true;before_sha256=$BeforeSHA;actual_stage_receipt_sha256=$ReceiptSHA;scope_sha256=$ScopeSHA;target_count=2;targets=$Targets}|ConvertTo-Json -Depth 12|Set-Content $Output -Encoding utf8NoBOM
$PlanSHA=Sha $Output
& $GuardPath -Mode authorize -BeforeSHA $BeforeSHA -PlanPath $Output -PlanSHA $PlanSHA
if(-not $?){throw 'Authorization failed; no canonical write'}
@{before_sha256=$BeforeSHA;plan_sha256=$PlanSHA;authorization_sha256=(Sha (Join-Path $Epoch 'deployment_authorization.json'))}|ConvertTo-Json
