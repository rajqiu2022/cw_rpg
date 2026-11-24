param(
 [Parameter(Mandatory=$true)][ValidateSet('before','authorize','after')][string]$Mode,
 [string]$BeforeSHA='', [string]$ReceiptSHA='', [string]$AuthorizationSHA='',
 [string]$Workspace='F:\Code\RPG_GAME'
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
# Root alone executes. Only NEW reports/backups; never deploys canonical files.
$taskWorkspace=[IO.Path]::GetFullPath($Workspace).TrimEnd([char[]]@('\','/'))
$taskGame=Join-Path $taskWorkspace 'game'
$taskOut=Join-Path $taskGame 'build/luoyang_estate_courtyard_20261021an_root01/arrival_retry1'
$parentPath=Join-Path $taskGame 'build/luoyang_estate_courtyard_20261021an_root01/final_guard.json'
$parentSHA='16ce0a42ae27a20b0d4f7af44880f32f48347b08458aaf2bfeeb7ec93e71ea5a'
$stageResource='res://build/luoyang_estate_courtyard_20261021an_system01/arrival_compiled_geometry_retry1/staged/receipt.json'
$beforePath=Join-Path $taskOut 'guard_before.json'
$authPath=Join-Path $taskOut 'deployment_authorization.json'
$planPath=Join-Path $taskOut 'predeploy_plan.json'
$backupDir=Join-Path $taskOut 'full_backups'
$outputPath=switch($Mode){'before'{$beforePath};'authorize'{$authPath};'after'{Join-Path $taskOut 'final_guard.json'}}
function TaskSourceSHA([string]$path){(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()}
function HashOK([string]$value){$value -cmatch '^[0-9a-f]{64}$'}
function Disk([string]$resource){
 if(!$resource.StartsWith('res://') -or $resource.Contains('..') -or $resource.Contains('\')){throw 'EXACT_RESOURCE_PATH'}
 $path=[IO.Path]::GetFullPath((Join-Path $taskGame $resource.Substring(6)))
 if(!$path.StartsWith($taskGame+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'OUTSIDE_GAME'}
 return $path
}
function Fact([string]$path){
 if(!(Test-Path -LiteralPath $path)){return @{path=$path;sha256='ABSENT';bytes=0;ticks='0'}}
 $item=Get-Item -LiteralPath $path;if($item.PSIsContainer){throw 'FILE_REQUIRED'}
 return @{path=$path;sha256=(TaskSourceSHA $path);bytes=[long]$item.Length;ticks=[string]$item.LastWriteTimeUtc.Ticks}
}
function SameFact($a,$b){$a.path -ceq $b.path -and $a.sha256 -ceq $b.sha256 -and $a.bytes -eq $b.bytes -and $a.ticks -is [string] -and $b.ticks -is [string] -and $a.ticks -ceq $b.ticks}
function WriteNewJSON([string]$path,$value){
 [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path))|Out-Null
 $stream=[IO.File]::Open($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 $writer=[IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($false))
 try{$writer.Write(($value|ConvertTo-Json -Depth 25)+"`n")}finally{$writer.Dispose()}
}
if(Test-Path -LiteralPath $outputPath){throw 'PRESERVE_PRIOR_RESIDUAL_EPOCH_OUTPUT'}
if((TaskSourceSHA $parentPath) -cne $parentSHA){throw 'PARENT_ORIGINAL_EPOCH_FINAL_GUARD_CHANGED'}
$parent=Get-Content -Raw -LiteralPath $parentPath|ConvertFrom-Json -AsHashtable
if($parent.passed -isnot [bool] -or !$parent.passed -or $parent.checked -ne 2101 -or $parent.facts.Count -ne 2101 -or $parent.save_paths.Count -ne 15){throw 'PARENT2096_PLUS_DEPLOYED_EXTRA_TARGETS_IS_ACTUAL2101'}
$paths=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($row in $parent.facts){if($row.path -isnot [string] -or ![IO.Path]::IsPathFullyQualified($row.path) -or !$paths.Add([IO.Path]::GetFullPath($row.path))){throw 'UNIQUE_PARENT_ABSOLUTE_PATHS'}}
$saveSet=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($path in $parent.save_paths){if(!$paths.Contains($path) -or !$saveSet.Add($path)){throw 'EXACT15_SAVE_DOMAIN'}}
$oldByPath=@{}
if($Mode -cne 'before'){
 if(!(HashOK $BeforeSHA) -or (TaskSourceSHA $beforePath) -cne $BeforeSHA){throw 'ROOT_EXPLICIT_NEW_FRESH_BEFORE_SHA'}
 $before=Get-Content -Raw -LiteralPath $beforePath|ConvertFrom-Json -AsHashtable
 if($before.status -cne 'AN_ARRIVAL_RETRY1_FRESH_CURRENT2101_NOT_PARENT_VALUES' -or $before.parent_sha256 -cne $parentSHA -or $before.facts.Count -ne 2101){throw 'RESIDUAL_BEFORE_DOMAIN'}
 foreach($row in $before.facts){if(!$paths.Contains($row.path) -or $oldByPath.ContainsKey($row.path) -or $row.ticks -isnot [string]){throw 'EXACT_BEFORE_PATHS_STRING_TICKS'};$oldByPath[$row.path]=$row}
}
$targets=@();$targetMap=@{};$facts=@();$changes=@();$unexpected=@();$saveChanges=@()
if($Mode -ceq 'authorize'){
 if(!(HashOK $ReceiptSHA)){throw 'ROOT_EXPLICIT_FINAL_REVIEWED_RECEIPT_SHA'}
 $stageDisk=Disk $stageResource
 if((TaskSourceSHA $stageDisk) -cne $ReceiptSHA){throw 'EXACT_RESIDUAL_RECEIPT_CHANGED'}
 $stage=Get-Content -Raw -LiteralPath $stageDisk|ConvertFrom-Json -AsHashtable
 if($stage.status -cne 'AN_ARRIVAL_COMPILED_GEOMETRY_SOURCE_SUCCESSOR_NOT_DEPLOYED_NOT_TRAVEL_PASS' -or $stage.parent_sha256 -cne 'b095c3bd2fd7dae621fba35d249b947f52b11861b29dd842d7011e1684d9fb43' -or $stage.targets.Count -ne 12 -or $stage.all_source_keysets_unchanged -ne $true -or $stage.all_native_geometry_room_storage_portal_uv_unchanged -ne $true -or $stage.router_g_xcontract_coordinator_temple_unchanged -ne $true){throw 'ONLY_EXACT_COMPILED_ARRIVAL_TWELVE_DEPENDENTS'}
 $expected=@('res://scripts/city/luoyang_estate_family_20261021am.gd','res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json','res://scripts/city/luoyang_estate_index_20261021am.gd','res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd','res://scripts/city/luoyang_docks_district08_index_20261019aa.gd','res://scripts/city/luoyang_docks_workyard_index_20261019ac.gd','res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json','res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s1_luoyang_yamen/manifest.json','res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s2_canal_docks/manifest.json','res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s3_luoyang_market/manifest.json','res://data/maps/luoyang_docks_district08_20261019aa/runtime/ch4_s2_canal_docks/manifest.json','res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/manifest.json')
 foreach($path in $paths){if(!(SameFact (Fact $path) $oldByPath[$path])){throw "DRIFT_BEFORE_AUTHORIZATION:$path"}}
 if((Test-Path -LiteralPath $planPath) -or (Test-Path -LiteralPath $backupDir)){throw 'NEW_PLAN_AND_FULL_BACKUPS_ONLY'}
 # Complete precheck before creating even one backup.
 foreach($row in $stage.targets){
  if($row.target -cnotin $expected){throw 'UNAPPROVED_TARGET'}
  $path=Disk $row.target;$candidate=Disk $row.candidate_path
  if(!$paths.Contains($path) -or $saveSet.Contains($path) -or $targetMap.ContainsKey($path)){throw 'TWELVE_UNIQUE_ALREADY_PROTECTED_NON_SAVE_TARGETS'}
  $current=Fact $path;$next=Fact $candidate
  if(!(HashOK $row.old_sha256) -or !(HashOK $row.candidate_sha256) -or $current.sha256 -cne $row.old_sha256 -or $next.sha256 -cne $row.candidate_sha256 -or $next.bytes -le 0){throw 'EXACT_OLD_AND_CANDIDATE_SHA_BYTES'}
  $target=@{path=$path;before=$current;candidate_path=$candidate;new_sha256=$next.sha256;new_bytes=$next.bytes;backup_path=$null;backup_sha256=$current.sha256}
  $targetMap[$path]=$target;$targets+=,$target
 }
 if($targetMap.Count -ne 12){throw 'EXACT_TWELVE_TARGET_SET'}
 [IO.Directory]::CreateDirectory($backupDir)|Out-Null
 for($index=0;$index -lt $targets.Count;$index++){
  $target=$targets[$index];$backup=Join-Path $backupDir ('{0:D2}_{1}' -f $index,[IO.Path]::GetFileName($target.path))
  $inputStream=[IO.File]::OpenRead($target.path);$outputStream=[IO.File]::Open($backup,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
  try{$inputStream.CopyTo($outputStream)}finally{$inputStream.Dispose();$outputStream.Dispose()}
  if((TaskSourceSHA $backup) -cne $target.before.sha256 -or (Get-Item -LiteralPath $backup).Length -ne $target.before.bytes){throw 'FULL_BACKUP_NOT_EXACT'}
  $target.backup_path=$backup
 }
 $plan=@{status='ROOT_EXPLICIT_AN_ARRIVAL_RETRY1_PREDEPLOY_TARGETS';approved_by_root=$true;before_sha256=$BeforeSHA;receipt_path=$stageDisk;receipt_sha256=$ReceiptSHA;target_count=12;targets=$targets;deployment_performed=$false}
 WriteNewJSON $planPath $plan
 $result=@{status='AN_ARRIVAL_RETRY1_EXACT_TWELVE_TARGETS_LOCKED_BEFORE_DEPLOYMENT';passed=$true;before_sha256=$BeforeSHA;plan_path=$planPath;plan_sha256=(TaskSourceSHA $planPath);receipt_path=$stageDisk;receipt_sha256=$ReceiptSHA;targets=$targets;target_count=12;no_late_allowlist=$true;deployment_performed=$false}
}else{
 if($Mode -ceq 'after'){
  if(!(HashOK $AuthorizationSHA) -or (TaskSourceSHA $authPath) -cne $AuthorizationSHA){throw 'EXPLICIT_FROZEN_AUTHORIZATION_NO_LATE_ALLOWLIST'}
  $auth=Get-Content -Raw -LiteralPath $authPath|ConvertFrom-Json -AsHashtable
  if($auth.status -cne 'AN_ARRIVAL_RETRY1_EXACT_TWELVE_TARGETS_LOCKED_BEFORE_DEPLOYMENT' -or $auth.passed -ne $true -or $auth.target_count -ne 12 -or $auth.before_sha256 -cne $BeforeSHA -or (TaskSourceSHA $auth.plan_path) -cne $auth.plan_sha256 -or (TaskSourceSHA $auth.receipt_path) -cne $auth.receipt_sha256){throw 'FROZEN_AUTH_PLAN_RECEIPT_CHANGED'}
  foreach($target in $auth.targets){if(!$paths.Contains($target.path) -or $targetMap.ContainsKey($target.path)){throw 'FROZEN_TARGET_DOMAIN'};$targetMap[$target.path]=$target}
 }
 foreach($path in @($paths|Sort-Object)){
  $current=Fact $path;$facts+=,$current
  if($Mode -ceq 'after'){
   if(!(SameFact $current $oldByPath[$path])){$change=@{path=$path;before=$oldByPath[$path];after=$current};$changes+=,$change;if(!$targetMap.ContainsKey($path)){$unexpected+=,$change};if($saveSet.Contains($path)){$saveChanges+=,$change}}
   if($targetMap.ContainsKey($path)){$target=$targetMap[$path];if($current.sha256 -cne $target.new_sha256 -or $current.bytes -ne $target.new_bytes -or (TaskSourceSHA $target.backup_path) -cne $target.backup_sha256 -or (Get-Item -LiteralPath $target.backup_path).Length -ne $target.before.bytes){$unexpected+=,@{path=$path;error='TARGET_OR_FULL_BACKUP_NOT_EXACT'}}}
  }
 }
 $result=@{status=if($Mode -ceq 'before'){'AN_ARRIVAL_RETRY1_FRESH_CURRENT2101_NOT_PARENT_VALUES'}else{'AN_ARRIVAL_RETRY1_FINAL_EXACT_FROZEN_TWELVE_TARGETS'};passed=($unexpected.Count -eq 0 -and $saveChanges.Count -eq 0);checked=$facts.Count;parent_path=$parentPath;parent_sha256=$parentSHA;parent_values_copied=$false;facts=$facts;save_paths=@($parent.save_paths);save_count=15;changes=$changes;unexpected_changes=$unexpected;unexpected_change_count=$unexpected.Count;save_changes=$saveChanges;save_change_count=$saveChanges.Count;authorized_target_count=$targetMap.Count;coverage='Parent actual2101 paths (2096 plus prior deployed outside-set targets), current facts freshly captured. New media/native outside this set require separate inventory; not zero changes across workspace.';engine_import_or_deployment_performed=$false}
 if($Mode -ceq 'after'){$result.before_sha256=$BeforeSHA;$result.authorization_sha256=$AuthorizationSHA}
}
WriteNewJSON $outputPath $result
@{path=$outputPath;sha256=(TaskSourceSHA $outputPath);mode=$Mode;passed=$result.passed}|ConvertTo-Json -Compress
if(!$result.passed){exit 1}
