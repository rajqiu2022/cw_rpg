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
$taskRoot=Join-Path $taskWorkspace 'game/build/luoyang_city_full_rollout_20261022ap_root01/integration2'
$parentPath=Join-Path $taskWorkspace 'game/build/luoyang_market_two_shops_20261021ao_root01/integration1/final_guard.json'
$parentSHA='9295e222f77080ff2d18298c6847774a6d552e9a6a56ad9e7b2d8cd41fd90632'
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
if(Test-Path -LiteralPath $outputPath){throw 'PRESERVE_EXISTING_AP_FULL_CITY_GUARD_OR_AUTHORIZATION'}
if((Sha $parentPath) -cne $parentSHA){throw 'AO_FINAL2105_PARENT_PIN_CHANGED'}
$parent=Get-Content -LiteralPath $parentPath -Raw|ConvertFrom-Json -AsHashtable
if($parent.status -cne 'AO_INTEGRATION1_FINAL_CURRENT2101_PLUS_LOCKED_DEPLOYMENT_TARGETS' -or $parent.passed -isnot [bool] -or !$parent.passed -or $parent.checked -ne 2105 -or $parent.facts.Count -ne 2105 -or $parent.save_paths.Count -ne 15){throw 'EXACT_AO_PARENT_DOMAIN'}
$paths=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($row in $parent.facts){if($row.path -isnot [string] -or ![IO.Path]::IsPathFullyQualified($row.path) -or !$paths.Add([IO.Path]::GetFullPath($row.path))){throw 'EXACT_UNIQUE_ABSOLUTE2105_PATHS'}}
$saveSet=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($path in $parent.save_paths){if(!$paths.Contains($path) -or !$saveSet.Add($path)){throw 'EXACT15_SAVE_PATHS'}}
# Inherit the final AO2105 path set only; capture CURRENT facts, never its old values.
# No target whitelist is guessed here. Authorize consumes only Root's exact frozen plan.
if($paths.Count -ne 2105 -or $saveSet.Count -ne 15){throw 'EXACT2105_AND15SAVES'}
$retainedFailPath=Join-Path $taskWorkspace 'game/build/luoyang_market_two_shops_20261021ao_root01/final_guard.json'
$retainedFailSHA='32d2aa66ffd865868ab30f084af036d48412d88884c14cd719f239e492eab35f'
if($parent.retained_prior_failure.sha256 -cne $retainedFailSHA -or (Sha $retainedFailPath) -cne $retainedFailSHA){throw 'KEEP_REAL_UNAUTHORIZED_TASK_WRITE_FAILURE_NO_RETROACTIVE_AUTH'}
$before=$null;$oldByPath=@{}
if($Mode -cne 'before'){
 if(!(FixedHash $BeforeSHA) -or (Sha $beforePath) -cne $BeforeSHA){throw 'ROOT_EXPLICIT_FRESH_BEFORE_SHA_REQUIRED'}
 $before=Get-Content -LiteralPath $beforePath -Raw|ConvertFrom-Json -AsHashtable
 if($before.status -cne 'AP_FULL_CITY_FRESH_CURRENT2105_FROM_AO_PATHS_NOT_VALUES' -or $before.checked -ne 2105 -or $before.parent_sha256 -cne $parentSHA -or $before.facts.Count -ne 2105){throw 'AP_BEFORE_DOMAIN'}
 foreach($row in $before.facts){if(!$paths.Contains($row.path) -or $oldByPath.ContainsKey($row.path) -or $row.ticks -isnot [string]){throw 'AP_BEFORE_EXACT_PATHS_STRING_TICKS'};$oldByPath[$row.path]=$row}
 if($oldByPath.Count -ne 2105){throw 'AP_BEFORE_FULL_DOMAIN'}
}
$facts=@();$changes=@();$unexpected=@();$allowed=@();$saveChanges=@();$targetMap=@{}
if($Mode -ceq 'authorize'){
 if(!(FixedHash $PlanSHA) -or ![IO.Path]::IsPathFullyQualified($PlanPath) -or (Sha $PlanPath) -cne $PlanSHA){throw 'ROOT_EXPLICIT_PLAN_PATH_AND_SHA_REQUIRED'}
 if([IO.Path]::GetFullPath($PlanPath) -ine [IO.Path]::GetFullPath((Join-Path $taskRoot 'predeploy_plan_READY.json'))){throw 'ONLY_AP_ROOT_EXPLICIT_NEW_PREDEPLOY_PLAN_PATH'}
 $plan=Get-Content -LiteralPath $PlanPath -Raw|ConvertFrom-Json -AsHashtable
 if($plan.status -cne 'ROOT_EXPLICIT_AP_FULL_CITY_PREDEPLOY_TARGETS' -or $plan.approved_by_root -isnot [bool] -or !$plan.approved_by_root -or $plan.before_sha256 -cne $BeforeSHA -or $plan.targets -isnot [Array] -or $plan.targets.Count -lt 1 -or $plan.target_count -ne $plan.targets.Count){throw 'ROOT_EXACT_PREDEPLOY_PLAN_REQUIRED'}
 foreach($path in $paths){if(!(SameFact (Fact $path) $oldByPath[$path])){throw "BASELINE_DRIFT_BEFORE_AUTHORIZATION:$path"}}
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
 $result=@{status='AP_FULL_CITY_ROOT_EXACT_TARGETS_LOCKED_BEFORE_DEPLOYMENT';passed=$true;before_path=$beforePath;before_sha256=$BeforeSHA;plan_path=$PlanPath;plan_sha256=$PlanSHA;targets=$targets;target_count=$targets.Count;existing2105_still_exact=$true;authorization_cannot_be_expanded_at_after=$true;deployment_performed=$false}
}else{
 $authorization=$null
 if($Mode -ceq 'after' -and (Test-Path -LiteralPath $authorizationPath)){
  if(!(FixedHash $AuthorizationSHA) -or (Sha $authorizationPath) -cne $AuthorizationSHA){throw 'FIXED_PREDEPLOY_AUTHORIZATION_SHA_REQUIRED_NO_LATE_ALLOWLIST'}
  $authorization=Get-Content -LiteralPath $authorizationPath -Raw|ConvertFrom-Json -AsHashtable
  if($authorization.status -cne 'AP_FULL_CITY_ROOT_EXACT_TARGETS_LOCKED_BEFORE_DEPLOYMENT' -or $authorization.passed -ne $true -or $authorization.before_sha256 -cne $BeforeSHA -or (Sha $authorization.plan_path) -cne $authorization.plan_sha256){throw 'FROZEN_AUTHORIZATION_OR_PLAN_CHANGED'}
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
 $result=@{status=if($Mode -ceq 'before'){'AP_FULL_CITY_FRESH_CURRENT2105_FROM_AO_PATHS_NOT_VALUES'}else{'AP_FULL_CITY_FINAL_CURRENT2105_PLUS_LOCKED_DEPLOYMENT_TARGETS'};passed=($unexpected.Count -eq 0 -and $saveChanges.Count -eq 0);mode=$Mode;checked=$facts.Count;parent_path=$parentPath;parent_sha256=$parentSHA;parent_fact_values_copied=$false;facts=$facts;save_paths=@($parent.save_paths);save_count=15;authorized_targets=@($targetMap.Keys);authorized_change_count=$allowed.Count;authorized_changes=$allowed;all_changes=$changes;unexpected_changes=$unexpected;unexpected_change_count=$unexpected.Count;save_changes=$saveChanges;save_change_count=$saveChanges.Count;coverage_boundary='2105 inherited AO paths freshly read. Only Root explicit before-deployment targets are allowed; unlisted paths and15save remain exact. NEW artifacts outside this set need separate inventory; no whole-workspace zero-change claim.';engine_import_image_or_deployment_writes=$false}
 if($Mode -ceq 'after'){$result.before_sha256=$BeforeSHA;$result.exact_unchanged=$facts.Count-$changes.Count;$result.authorization_sha256=$AuthorizationSHA}
}
$result.retained_prior_failure=@{path=$retainedFailPath;sha256=$retainedFailSHA;whole_pass=$false;relabelled_or_late_authorized=$false}
[IO.Directory]::CreateDirectory($taskRoot)|Out-Null
$stream=[IO.File]::Open($outputPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
$writer=[IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($false))
try{$writer.Write(($result|ConvertTo-Json -Depth 20)+"`n")}finally{$writer.Dispose()}
@{path=$outputPath;sha256=(Sha $outputPath);mode=$Mode;passed=$result.passed}|ConvertTo-Json -Compress
if(!$result.passed){exit 1}






