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
# Root executes. No deployment, copying, backup creation or image writes here.
$taskWorkspace=[IO.Path]::GetFullPath($Workspace).TrimEnd([char[]]@('\','/'))
$taskRoot=Join-Path $taskWorkspace 'game/build/luoyang_market_two_shops_20261021ao_root01/media_retry2'
$parentPath=Join-Path $taskWorkspace 'game/build/luoyang_market_two_shops_20261021ao_root01/scope_retry1/final_guard.json'
$parentSHA='9ab1b5a1544b8192e327189656e438d6c249e46eabe1667f389fda535088e6c2'
$beforePath=Join-Path $taskRoot 'guard_before.json'
$authorizationPath=Join-Path $taskRoot 'deployment_authorization.json'
$outputPath=switch($Mode){'before'{$beforePath};'authorize'{$authorizationPath};'after'{Join-Path $taskRoot 'final_guard.json'}}
function Sha([string]$path){return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()}
function FixedHash([string]$value){return $value -cmatch '^[0-9a-f]{64}$'}
function Fact([string]$path){
 if(Test-Path -LiteralPath $path){$item=Get-Item -LiteralPath $path;if($item.PSIsContainer){throw "FILE_IS_DIRECTORY:$path"};return @{path=$path;sha256=(Sha $path);bytes=[long]$item.Length;ticks=[string]$item.LastWriteTimeUtc.Ticks}}
 return @{path=$path;sha256='ABSENT';bytes=0;ticks='0'}
}
function SameFact($a,$b){return $a.path -ceq $b.path -and $a.sha256 -ceq $b.sha256 -and $a.bytes -eq $b.bytes -and $a.ticks -ceq $b.ticks -and $a.ticks -is [string] -and $b.ticks -is [string]}
if(Test-Path -LiteralPath $outputPath){throw 'PRESERVE_OLD_FAIL_RECOVERY_AND_EXISTING_MEDIA_RETRY2_OUTPUT'}
if((Sha $parentPath) -cne $parentSHA){throw 'AN_FINAL2101_PARENT_PIN_CHANGED'}
$parent=Get-Content -LiteralPath $parentPath -Raw|ConvertFrom-Json -AsHashtable
if($parent.status -cne 'AO_SCOPE_RETRY1_FINAL_CURRENT2101_TASKS_ONLY_AUTHORIZATION' -or $parent.passed -isnot [bool] -or !$parent.passed -or $parent.checked -ne 2101 -or $parent.facts.Count -ne 2101 -or $parent.save_paths.Count -ne 15){throw 'EXACT_AN_PARENT_DOMAIN'}
$paths=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($row in $parent.facts){if($row.path -isnot [string] -or ![IO.Path]::IsPathFullyQualified($row.path) -or !$paths.Add([IO.Path]::GetFullPath($row.path))){throw 'EXACT_UNIQUE_ABSOLUTE2101_PATHS'}}
$saveSet=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($path in $parent.save_paths){if(!$paths.Contains($path) -or !$saveSet.Add($path)){throw 'EXACT15_SAVE_PATHS'}}
# Inherit the final AN path set only; capture CURRENT facts, never its old values.
# No target whitelist is guessed here. Authorize consumes only Root's exact frozen plan.
if($paths.Count -ne 2101 -or $saveSet.Count -ne 15){throw 'EXACT2101_AND15SAVES'}
# The first epoch really failed; no retroactive authorization or timestamp rollback.
$failedPath=Join-Path $taskWorkspace 'game/build/luoyang_market_two_shops_20261021ao_root01/final_guard.json'
$failedSHA='32d2aa66ffd865868ab30f084af036d48412d88884c14cd719f239e492eab35f'
$failedBeforePath=Join-Path $taskWorkspace 'game/build/luoyang_market_two_shops_20261021ao_root01/guard_before.json'
$failedBeforeSHA='7d5944ca6cf4b1776d7a707634a7d9f0034b7ea03643b7bff920613bff296f29'
$taskYAML=[IO.Path]::GetFullPath((Join-Path $taskWorkspace 'prompts/tasks.yaml'))
if((Sha $failedPath) -cne $failedSHA -or (Sha $failedBeforePath) -cne $failedBeforeSHA){throw 'PRESERVED_REAL_FAILED_EPOCH_CHANGED'}
$failed=Get-Content -LiteralPath $failedPath -Raw|ConvertFrom-Json -AsHashtable
$failedBefore=Get-Content -LiteralPath $failedBeforePath -Raw|ConvertFrom-Json -AsHashtable
if($failed.passed -isnot [bool] -or $failed.passed -or $failed.checked -ne 2101 -or $failed.unexpected_change_count -ne 1 -or $failed.unexpected_changes.Count -ne 1 -or $failed.save_change_count -ne 0 -or $failed.authorized_change_count -ne 0 -or $failed.before_sha256 -cne $failedBeforeSHA -or $failed.authorization_sha256 -cne '' -or [IO.Path]::GetFullPath($failed.unexpected_changes[0].path) -ine $taskYAML){throw 'EXACT_UNAUTHORIZED_TASKS_ONLY_FAIL_NO_LATE_AUTHORIZATION'}
# Recovery epoch9AB1 is preserved; current tasks may legitimately be97C5 or a later explicitly authorized value.
# This epoch captures current content and ticks, never demands the pre-incident4D content.
if($parent.retained_failed_epoch.sha256 -cne $failedSHA -or $parent.authorized_change_count -ne 1 -or $parent.save_change_count -ne 0 -or $parent.unexpected_change_count -ne 0){throw 'EXACT_ROOT_AUTHORIZED_TASKS_RECOVERY_PARENT'}
$before=$null;$oldByPath=@{}
if($Mode -cne 'before'){
 if(!(FixedHash $BeforeSHA) -or (Sha $beforePath) -cne $BeforeSHA){throw 'ROOT_EXPLICIT_FRESH_BEFORE_SHA_REQUIRED'}
 $before=Get-Content -LiteralPath $beforePath -Raw|ConvertFrom-Json -AsHashtable
 if($before.status -cne 'AO_MEDIA_RETRY2_FRESH_CURRENT2101_FROM_AUTHORIZED_TASKS_RECOVERY' -or $before.checked -ne 2101 -or $before.parent_sha256 -cne $parentSHA -or $before.facts.Count -ne 2101){throw 'AO_BEFORE_DOMAIN'}
 foreach($row in $before.facts){if(!$paths.Contains($row.path) -or $oldByPath.ContainsKey($row.path) -or $row.ticks -isnot [string]){throw 'AO_BEFORE_EXACT_PATHS_STRING_TICKS'};$oldByPath[$row.path]=$row}
 if($oldByPath.Count -ne 2101){throw 'AO_BEFORE_FULL_DOMAIN'}
}
$facts=@();$changes=@();$unexpected=@();$allowed=@();$saveChanges=@();$targetMap=@{}
if($Mode -ceq 'authorize'){
 if(!(FixedHash $PlanSHA) -or ![IO.Path]::IsPathFullyQualified($PlanPath) -or (Sha $PlanPath) -cne $PlanSHA){throw 'ROOT_EXPLICIT_PLAN_PATH_AND_SHA_REQUIRED'}
 if([IO.Path]::GetFullPath($PlanPath) -ine [IO.Path]::GetFullPath((Join-Path $taskRoot 'predeploy_plan_READY.json'))){throw 'ONLY_AO_ROOT_EXPLICIT_NEW_PREDEPLOY_PLAN_PATH'}
 $plan=Get-Content -LiteralPath $PlanPath -Raw|ConvertFrom-Json -AsHashtable
 if($plan.status -cne 'ROOT_EXPLICIT_AO_PREDEPLOY_TARGETS' -or $plan.approved_by_root -isnot [bool] -or !$plan.approved_by_root -or $plan.before_sha256 -cne $BeforeSHA -or $plan.targets -isnot [Array] -or $plan.targets.Count -lt 1 -or $plan.target_count -ne $plan.targets.Count){throw 'ROOT_EXACT_PREDEPLOY_PLAN_REQUIRED'}
 foreach($path in $paths){if(!(SameFact (Fact $path) $oldByPath[$path])){throw "BASELINE_DRIFT_BEFORE_AUTHORIZATION:$path"}}
 if($plan.targets.Count -ne 1 -or [IO.Path]::GetFullPath($plan.targets[0].path) -ine $taskYAML){throw 'THIS_NEW_EPOCH_AUTHORIZES_ONLY_ROOT_EXACT_TASKS_APPEND_NOT_PRODUCTION'}
 $targets=@()
 foreach($target in $plan.targets){
  if($target.path -isnot [string] -or ![IO.Path]::IsPathFullyQualified($target.path)){throw 'TARGET_ABSOLUTE_PATH_REQUIRED'}
  $path=[IO.Path]::GetFullPath($target.path)
  $insideWorkspace=$path.StartsWith($taskWorkspace+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)
  if(!$insideWorkspace -or $saveSet.Contains($path) -or $path -ieq (Join-Path $taskWorkspace 'game/project.godot') -or $targetMap.ContainsKey($path)){throw 'ONLY_ROOT_EXACT_UNIQUE_WORKSPACE_FILES_NOT_PROJECT_OR_SAVES'}
  if(!(FixedHash $target.new_sha256) -or ($target.new_bytes -isnot [long] -and $target.new_bytes -isnot [int]) -or $target.new_bytes -le 0){throw 'EXACT_NONEMPTY_NEW_SHA_BYTES_REQUIRED'}
  if($target.candidate_path -isnot [string] -or ![IO.Path]::IsPathFullyQualified($target.candidate_path) -or $target.candidate_path -ieq $path -or !(Test-Path -LiteralPath $target.candidate_path) -or (Sha $target.candidate_path) -cne $target.new_sha256 -or (Get-Item -LiteralPath $target.candidate_path).Length -ne $target.new_bytes){throw 'FROZEN_CANDIDATE_PATH_SHA_BYTES_REQUIRED'}
  $current=Fact $path
  if($current.sha256 -cne $target.old_sha256){throw "TARGET_OLD_SHA_CURRENT_MISMATCH:$path"}
  if($oldByPath.ContainsKey($path) -and !(SameFact $current $oldByPath[$path])){throw 'PROTECTED_TARGET_DRIFT_BEFORE_AUTHORIZATION'}
  if($current.sha256 -ceq 'ABSENT'){
   if($target.backup_path -ne $null -or $target.backup_sha256 -ne $null){throw 'ABSENT_TARGET_MUST_NOT_CLAIM_BACKUP'}
  }else{
   if(!(FixedHash $target.old_sha256) -or ![IO.Path]::IsPathFullyQualified($target.backup_path) -or $target.backup_path -ieq $path -or $target.backup_sha256 -cne $current.sha256 -or (Sha $target.backup_path) -cne $current.sha256 -or (Get-Item -LiteralPath $target.backup_path).Length -ne $current.bytes){throw 'EXACT_OLD_FULL_BACKUP_REQUIRED_BEFORE_AUTHORIZATION'}
  }
  $record=@{path=$path;before=$current;new_sha256=$target.new_sha256;new_bytes=$target.new_bytes;backup_path=$target.backup_path;backup_sha256=$target.backup_sha256;candidate_path=$target.candidate_path}
  $targetMap[$path]=$record;$targets+=,$record
 }
 $result=@{status='AO_MEDIA_RETRY2_ROOT_TASKS_ONLY_LOCKED_BEFORE_DEPLOYMENT';passed=$true;before_path=$beforePath;before_sha256=$BeforeSHA;plan_path=$PlanPath;plan_sha256=$PlanSHA;targets=$targets;target_count=$targets.Count;existing2101_still_exact=$true;authorization_cannot_be_expanded_at_after=$true;deployment_performed=$false}
}else{
 $authorization=$null
 if($Mode -ceq 'after' -and (Test-Path -LiteralPath $authorizationPath)){
  if(!(FixedHash $AuthorizationSHA) -or (Sha $authorizationPath) -cne $AuthorizationSHA){throw 'FIXED_PREDEPLOY_AUTHORIZATION_SHA_REQUIRED_NO_LATE_ALLOWLIST'}
  $authorization=Get-Content -LiteralPath $authorizationPath -Raw|ConvertFrom-Json -AsHashtable
  if($authorization.status -cne 'AO_MEDIA_RETRY2_ROOT_TASKS_ONLY_LOCKED_BEFORE_DEPLOYMENT' -or $authorization.passed -ne $true -or $authorization.before_sha256 -cne $BeforeSHA -or (Sha $authorization.plan_path) -cne $authorization.plan_sha256){throw 'FROZEN_AUTHORIZATION_OR_PLAN_CHANGED'}
  foreach($target in $authorization.targets){if($targetMap.ContainsKey($target.path)){throw 'DUPLICATE_AUTH_TARGET'};$targetMap[$target.path]=$target;if(!$paths.Contains($target.path)){[void]$paths.Add($target.path);$oldByPath[$target.path]=$target.before}}
 }elseif($Mode -ceq 'after' -and $AuthorizationSHA -ne ''){throw 'NO_MATCHING_PREDEPLOY_AUTHORIZATION'}
 foreach($path in @($paths|Sort-Object)){
  $current=Fact $path;$facts+=,$current
  if($Mode -ceq 'after'){
   $old=$oldByPath[$path]
   if(!(SameFact $current $old)){$entry=@{path=$path;before=$old;after=$current};$changes+=,$entry;if($targetMap.ContainsKey($path)){$allowed+=,$entry}else{$unexpected+=,$entry};if($saveSet.Contains($path)){$saveChanges+=,$entry}}
   if($targetMap.ContainsKey($path)){
    $target=$targetMap[$path]
    if($current.sha256 -cne $target.new_sha256 -or $current.bytes -ne $target.new_bytes){$unexpected+=,@{path=$path;error='DEPLOYED_SHA_OR_BYTES_NOT_EXACT_APPROVED_TARGET'}}
    if($target.backup_path -ne $null -and (Sha $target.backup_path) -cne $target.backup_sha256){$unexpected+=,@{path=$path;error='OLD_BACKUP_CHANGED'}}
   }
  }
 }
 $result=@{status=if($Mode -ceq 'before'){'AO_MEDIA_RETRY2_FRESH_CURRENT2101_FROM_AUTHORIZED_TASKS_RECOVERY'}else{'AO_MEDIA_RETRY2_FINAL_CURRENT2101_TASKS_ONLY_AUTHORIZATION'};passed=($unexpected.Count -eq 0 -and $saveChanges.Count -eq 0);mode=$Mode;checked=$facts.Count;parent_path=$parentPath;parent_sha256=$parentSHA;parent_fact_values_copied=$false;facts=$facts;save_paths=@($parent.save_paths);save_count=15;authorized_targets=@($targetMap.Keys);authorized_change_count=$allowed.Count;authorized_changes=$allowed;all_changes=$changes;unexpected_changes=$unexpected;unexpected_change_count=$unexpected.Count;save_changes=$saveChanges;save_change_count=$saveChanges.Count;coverage_boundary='2101 inherited AN paths freshly read. Only Root explicit before-deployment targets are allowed; unlisted paths and15save remain exact. NEW artifacts outside this set need separate inventory; no whole-workspace zero-change claim.';engine_import_image_or_deployment_writes=$false}
 if($Mode -ceq 'after'){$result.before_sha256=$BeforeSHA;$result.exact_unchanged=$facts.Count-$changes.Count;$result.authorization_sha256=$AuthorizationSHA}
}
$result.retained_failed_epoch=@{path=$failedPath;sha256=$failedSHA;before_sha256=$failedBeforeSHA;whole_pass=$false;late_authorization=$false;prior_recovery_epoch_path=$parentPath;prior_recovery_epoch_sha256=$parentSHA;requires_old4D_content=$false;mtime_rollback_performed=$false}
[IO.Directory]::CreateDirectory($taskRoot)|Out-Null
$stream=[IO.File]::Open($outputPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
$writer=[IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($false))
try{$writer.Write(($result|ConvertTo-Json -Depth 20)+"`n")}finally{$writer.Dispose()}
@{path=$outputPath;sha256=(Sha $outputPath);mode=$Mode;passed=$result.passed}|ConvertTo-Json -Compress
if(!$result.passed){exit 1}






