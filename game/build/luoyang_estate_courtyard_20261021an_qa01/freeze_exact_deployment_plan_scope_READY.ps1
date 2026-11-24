param(
 [Parameter(Mandatory=$true)][string]$StageReceiptPath,
 [Parameter(Mandatory=$true)][string]$StageReceiptSHA,
 [Parameter(Mandatory=$true)][string]$IndexTrueSHA,
 [string]$Workspace='F:\Code\RPG_GAME'
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
# ROOT executes after reviewing the actual stager. Creates only NEW whole
# backups + frozen plan. Does NOT authorize the guard or deploy any target.
$workspaceRoot=[IO.Path]::GetFullPath($Workspace).TrimEnd([char[]]@('\','/'))
$gameRoot=Join-Path $workspaceRoot 'game'
$rootOut=Join-Path $gameRoot 'build/luoyang_estate_courtyard_20261021an_root01'
$beforePath=Join-Path $rootOut 'guard_before.json'
$beforeSHA='b8fb211add45fe7c81a9e6caee7a8e3ee8317a158738ce1d069e635e1d620d16'
$planPath=Join-Path $rootOut 'predeploy_plan_READY.json'
$backupDir=Join-Path $rootOut 'predeploy_full_backups'
function H([string]$p){return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function HashOK([string]$h){return $h -cmatch '^[0-9a-f]{64}$'}
function Disk([string]$p){
 if(!$p.StartsWith('res://') -or $p.Contains('..') -or $p.Contains('\')){throw "RESOURCE_PATH:$p"}
 $v=[IO.Path]::GetFullPath((Join-Path $gameRoot $p.Substring(6)))
 if(!$v.StartsWith($gameRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'OUTSIDE_GAME'}
 return $v
}
function Fact([string]$p){
 if(!(Test-Path -LiteralPath $p)){return @{path=$p;sha256='ABSENT';bytes=0;ticks='0'}}
 $item=Get-Item -LiteralPath $p;if($item.PSIsContainer){throw 'FILE_REQUIRED'}
 return @{path=$p;sha256=(H $p);bytes=[long]$item.Length;ticks=[string]$item.LastWriteTimeUtc.Ticks}
}
function SameFact($a,$b){return $a.path -ceq $b.path -and $a.sha256 -ceq $b.sha256 -and $a.bytes -eq $b.bytes -and $a.ticks -is [string] -and $b.ticks -is [string] -and $a.ticks -ceq $b.ticks}
if((Test-Path -LiteralPath $planPath) -or (Test-Path -LiteralPath $backupDir)){throw 'NEW_PLAN_AND_BACKUP_DIRECTORY_ONLY_PRESERVE_EVERY_PRIOR_OUTCOME'}
if(!(HashOK $StageReceiptSHA) -or !(HashOK $IndexTrueSHA)){throw 'ROOT_SUPPLIED_LOWERCASE_RECEIPT_AND_TRUE_INDEX_PINS_REQUIRED'}
if(!$StageReceiptPath.StartsWith('res://build/luoyang_estate_courtyard_20261021an_system01/') -or !$StageReceiptPath.EndsWith('/receipt.json')){throw 'ONLY_REVIEWED_AN_STAGER_RECEIPT'}
$stageDisk=Disk $StageReceiptPath
if((H $stageDisk) -cne $StageReceiptSHA -or (H $beforePath) -cne $beforeSHA){throw 'FROZEN_STAGE_OR_FRESH_BEFORE_CHANGED'}
$receipt=Get-Content -LiteralPath $stageDisk -Raw|ConvertFrom-Json -AsHashtable
$before=Get-Content -LiteralPath $beforePath -Raw|ConvertFrom-Json -AsHashtable
if($receipt.status -cne 'AN_STAGED_GATE_SCOPE_METADATA_SUCCESSOR_NOT_DEPLOYED_NOT_FIELD_PASS' -or $receipt.targets -isnot [Array] -or $receipt.targets.Count -ne 19 -or $receipt.all_six_manifest_whole_inverse -isnot [bool] -or !$receipt.all_six_manifest_whole_inverse -or $receipt.no_actual_collector_backfill -isnot [bool] -or !$receipt.no_actual_collector_backfill){throw 'EXACT_NINETEEN_REVIEWED_STAGER_TARGETS'}
# One explicitly approved metadata successor, not a status wildcard.
$fixedScopedPath='res://build/luoyang_estate_courtyard_20261021an_system01/staged_gate_scope_successor/receipt.json'
$fixedScopedSHA='b095c3bd2fd7dae621fba35d249b947f52b11861b29dd842d7011e1684d9fb43'
$fixedParentPath='res://build/luoyang_estate_courtyard_20261021an_system01/staged_retry2/receipt.json'
$fixedParentSHA='39e1594f0b1e35b4be636555c8cbfb4ccfb86097c892ba387635b1c1b58b47a4'
if($StageReceiptPath -cne $fixedScopedPath -or $StageReceiptSHA -cne $fixedScopedSHA -or (H (Disk $fixedParentPath)) -cne $fixedParentSHA){throw 'ONLY_EXACT_B095_SCOPE_SUCCESSOR_OF39E159'}
$successor=$receipt.metadata_scope_successor
$changedPaths=@('res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json','res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd')
if($successor.parent_receipt -cne $fixedParentPath -or $successor.parent_sha256 -cne $fixedParentSHA -or $successor.only_changed_target_paths.Count -ne 2 -or $successor.gate_count -ne 718 -or $successor.family_manifest_and_index_unchanged -ne $true -or $successor.temple_binding_and_helper_unchanged -ne $true){throw 'EXACT_TWO_TARGET_METADATA_SCOPE'}
foreach($path in $successor.only_changed_target_paths){if($path -cnotin $changedPaths){throw 'UNAPPROVED_METADATA_DELTA'}}
$parent=Get-Content -LiteralPath (Disk $fixedParentPath) -Raw|ConvertFrom-Json -AsHashtable
$parentRows=@{};foreach($row in $parent.targets){$parentRows[$row.target]=$row}
$expectedChanged=@{
 'res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json'='5591c50cb559ef82e0d331f261740f2f3a14027b0eb3d873fb66f5dee14e1dce'
 'res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd'='a78494c3adc431389a92f868bbd313ade2b597701169fb3ed46f0647aaf9dde5'
}
foreach($row in $receipt.targets){
 if(!$parentRows.ContainsKey($row.target) -or $row.old_sha256 -cne $parentRows[$row.target].old_sha256){throw 'TARGET_DOMAIN_OR_OLD_SHA_NOT_PARENT'}
 if($expectedChanged.ContainsKey($row.target)){
  if($row.candidate_sha256 -cne $expectedChanged[$row.target]){throw 'ONLY_EXACT_TWO_METADATA_NEW_SHA'}
 }elseif($row.candidate_path -cne $parentRows[$row.target].candidate_path -or $row.candidate_sha256 -cne $parentRows[$row.target].candidate_sha256){throw 'UNCHANGED_SEVENTEEN_TARGETS_MUST_BE_EXACT_PARENT'}
}
foreach($key in @('family_manifest_path','family_manifest_sha256','family_index_false_sha256','family_index_true_sha256','true_index_candidate_path','temple_binding_path','temple_binding_sha256')){if($receipt[$key] -cne $parent[$key]){throw 'FAMILY_TEMPLE_SOURCE_DOMAIN_UNCHANGED'}}
if($before.checked -ne 2096 -or $before.facts.Count -ne 2096 -or $before.save_paths.Count -ne 15 -or $before.status -cne 'AN_FRESH_CURRENT2096_FROM_AM2094_PATHS_PLUS_TWO_NEW_NOT_OLD_VALUES'){throw 'EXACT_FRESH2096_WITH15SAVES'}
$oldByPath=@{}
foreach($row in $before.facts){
 if($oldByPath.ContainsKey($row.path) -or !(SameFact (Fact $row.path) $row)){throw "FRESH_BASELINE_CHANGED_BEFORE_PLAN:$($row.path)"}
 $oldByPath[$row.path]=$row
}
$expected=@(
 'res://scripts/city/luoyang_precomputed_bundle_20261018r.gd',
 'res://scripts/city/luoyang_assembled_interiors_20261016g.gd',
 'res://scripts/city/luoyang_layout_room_index_20261018t.gd',
 'res://scripts/autoload/scene_router.gd',
 'res://scripts/city/luoyang_estate_family_20261021am.gd',
 'res://data/luoyang_culture_integration_20261019x/runtime_contract.json',
 'res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd',
 'res://scripts/city/luoyang_temple_assembly_20261016.gd',
 'res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json',
 'res://scripts/city/luoyang_estate_index_20261021am.gd',
 'res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json',
 'res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s1_luoyang_yamen/manifest.json',
 'res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s2_canal_docks/manifest.json',
 'res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s3_luoyang_market/manifest.json',
 'res://data/maps/luoyang_docks_district08_20261019aa/runtime/ch4_s2_canal_docks/manifest.json',
 'res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/manifest.json',
 'res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd',
 'res://scripts/city/luoyang_docks_district08_index_20261019aa.gd',
 'res://scripts/city/luoyang_docks_workyard_index_20261019ac.gd'
)
$index='res://scripts/city/luoyang_estate_index_20261021am.gd'
if($receipt.family_index_true_sha256 -cne $IndexTrueSHA -or !(HashOK $receipt.family_index_false_sha256)){throw 'ROOT_TRUE_INDEX_PIN_MUST_MATCH_STAGER_SOLE_BOOL_CANDIDATE'}
$trueDisk=Disk $receipt.true_index_candidate_path
if((H $trueDisk) -cne $IndexTrueSHA){throw 'ACTUAL_TRUE_INDEX_CANDIDATE_SHA'}
$plans=@();$seen=@{}
foreach($target in $receipt.targets){
 $res=$target.target
 if($res -isnot [string] -or $res -cnotin $expected -or $seen.ContainsKey($res)){throw 'ONLY_EXACT_UNIQUE_NINETEEN_AUTHORIZED_TARGET_PATHS'}
 $seen[$res]=$true
 $dest=Disk $res;$current=Fact $dest
 if($current.sha256 -cne $target.old_sha256){throw "CURRENT_OLD_SHA_MISMATCH:$res"}
 if($oldByPath.ContainsKey($dest) -and !(SameFact $current $oldByPath[$dest])){throw 'PROTECTED_TARGET_ALREADY_CHANGED'}
 if(!($target.candidate_path.StartsWith('res://build/luoyang_estate_courtyard_20261021an_system01/')) -or !(HashOK $target.candidate_sha256)){throw 'FROZEN_AN_CANDIDATE_REQUIRED'}
 $candidate=Disk $target.candidate_path
 if((H $candidate) -cne $target.candidate_sha256){throw "CANDIDATE_SHA_CHANGED:$res"}
 $selected=$candidate;$selectedSHA=$target.candidate_sha256
 if($res -ceq $index){
  if($target.candidate_sha256 -cne $receipt.family_index_false_sha256){throw 'STAGED_FALSE_INDEX_IDENTITY'}
  $false=[IO.File]::ReadAllText($candidate);$true=[IO.File]::ReadAllText($trueDisk)
  if([regex]::Matches($false,'const FORMAL_ENABLED=false').Count -ne 1 -or $true.Replace('const FORMAL_ENABLED=true','const FORMAL_ENABLED=false') -cne $false -or [regex]::Matches($true,'const FORMAL_ENABLED=true').Count -ne 1){throw 'SOLE_BOOL_TRUE_INDEX_FULL_TEXT_INVERSE'}
  $selected=$trueDisk;$selectedSHA=$IndexTrueSHA
 }
 $newItem=Get-Item -LiteralPath $selected
 if($newItem.PSIsContainer -or $newItem.Length -le 0){throw 'NONEMPTY_CANDIDATE_FILE'}
 $plans+=,@{path=$dest;resource_path=$res;old_sha256=$current.sha256;new_sha256=$selectedSHA;new_bytes=[long]$newItem.Length;candidate_path=$selected;before=$current;backup_path=$null;backup_sha256=$null}
}
if($plans.Count -ne 19 -or $seen.Count -ne 19){throw 'FULL_NINETEEN_DOMAIN'}
# All candidates and old state validated before creating a single backup.
[IO.Directory]::CreateDirectory($backupDir)|Out-Null
$number=0
foreach($plan in $plans){
 $number++
 if($plan.old_sha256 -cne 'ABSENT'){
  $backup=Join-Path $backupDir ('{0:D2}_{1}' -f $number,[IO.Path]::GetFileName($plan.path))
  $inputStream=[IO.File]::Open($plan.path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
  $outputStream=[IO.File]::Open($backup,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
  try{$inputStream.CopyTo($outputStream)}finally{$outputStream.Dispose();$inputStream.Dispose()}
  if((H $backup) -cne $plan.old_sha256 -or (Get-Item $backup).Length -ne $plan.before.bytes){throw 'FULL_BACKUP_SHA_BYTES_MISMATCH'}
  $plan.backup_path=$backup;$plan.backup_sha256=$plan.old_sha256
 }
 if(!(SameFact (Fact $plan.path) $plan.before) -or (H $plan.candidate_path) -cne $plan.new_sha256){throw 'SOURCE_CHANGED_DURING_BACKUP'}
}
$result=[ordered]@{status='ROOT_EXPLICIT_AN_PREDEPLOY_TARGETS';approved_by_root=$true;before_path=$beforePath;before_sha256=$beforeSHA;stage_receipt_path=$StageReceiptPath;stage_receipt_sha256=$StageReceiptSHA;index_true_sha256=$IndexTrueSHA;targets=$plans;target_count=19;guard_existing_domain=2096;save_count=15;late_target_expansion_allowed=$false;deployment_performed=$false;guard_authorization_performed=$false;coverage_boundary='Existing2096 plus exactly19 locked targets. New formal native/data and15NEW media require separate inventory; not a whole-workspace zero-change claim.'}
$stream=[IO.File]::Open($planPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
$writer=[IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($false))
try{$writer.Write(($result|ConvertTo-Json -Depth 15)+"`n")}finally{$writer.Dispose()}
@{path=$planPath;sha256=(H $planPath);target_count=19;before_sha256=$beforeSHA;deployment_performed=$false;next='Root reviews plan then runs guard -Mode authorize with exact plan SHA before any canonical writes'}|ConvertTo-Json -Compress

