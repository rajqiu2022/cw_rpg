param([string]$GpuReport='')
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'USE_BUNDLED_PWSH7'}
$repo='F:/Code/RPG_GAME';$dir=$repo+'/game/build/world_bridges_20261030m_qa01'
$output=$dir+'/final_guard03_ACTUAL.json'
if(Test-Path -LiteralPath $output){throw 'KEEP_FIRST_FINAL_GUARD_NO_OVERWRITE'}
function Hash-Only([string]$path){
 $stream=[IO.File]::OpenRead($path);$algorithm=[Security.Cryptography.SHA256]::Create()
 try{return ([BitConverter]::ToString($algorithm.ComputeHash($stream))).Replace('-','').ToLowerInvariant()}
 finally{$algorithm.Dispose();$stream.Dispose()}
}
function Json-Report([string]$path){
 if($path.Replace('\','/').Contains('/app_userdata/')){throw 'NO_SAVE_DESERIALIZATION'}
 return Get-Content -LiteralPath $path -Raw -Encoding utf8 | ConvertFrom-Json -AsHashtable
}
function Metadata([string]$path){
 $item=Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
 if($null -eq $item){return [ordered]@{exists=$false;bytes=$null;utc_ticks=$null;sha256=$null;stable_during_hash=$true}}
 $length=[long]$item.Length;$ticks=[string]$item.LastWriteTimeUtc.Ticks
 $hash=Hash-Only $path;$after=Get-Item -LiteralPath $path
 return [ordered]@{exists=$true;bytes=$length;utc_ticks=$ticks;sha256=$hash;stable_during_hash=($length -eq $after.Length -and $ticks -ceq [string]$after.LastWriteTimeUtc.Ticks)}
}
function Same-Metadata($a,$b){
 foreach($key in @('exists','bytes','utc_ticks','sha256')){if($a[$key] -cne $b[$key]){return $false}}
 return $true
}
$baselinePath=$dir+'/baseline_NOW_ACTUAL.json';$residualPath=$dir+'/absence_residual_ACTUAL.json'
$receiptPath=$repo+'/game/build/world_bridges_20261030m_system01/FINAL_01_receipt_READY.json'
$promotePath=$repo+'/game/build/world_bridges_20261030m_root01/asset_promote01_ACTUAL.json'
foreach($pin in @(
 @($baselinePath,'1bd4f781041d605de01148a2528416c6ce0333cc356fa396df98d7a81f75df23'),
 @($residualPath,'e48631c8f054fc463a6227304050744a971c730baa1c8f7a5f43c69c63dc20a7'),
 @($receiptPath,'059fa03415dcd05e844692265689780f5a237c09aa49ddb00ea79e89a2a95499'),
 @($promotePath,'62a2d21273095a2c39a04e9b1627ba64b27b3d7ebf8df4279a8ecee6902468fa'))){
 if((Hash-Only $pin[0]) -cne $pin[1]){throw ('EXACT_METADATA_RECEIPT_REQUIRED:'+ $pin[0])}
}
$baseline=Json-Report $baselinePath;$residual=Json-Report $residualPath
$receipt=Json-Report $receiptPath;$promote=Json-Report $promotePath
if($baseline.passed -ne $false -or $baseline.source_count -ne 600 -or $baseline.save_count -ne 171 -or $residual.residual_passed -ne $true -or $residual.exact_expected_absence9.Count -ne 9){throw 'FIRST_WHOLE_FAIL_PLUS_PRECISE_ABSENCE_RESIDUAL_REQUIRED'}
$errors=[Collections.Generic.List[string]]::new()
$authorized=@{}
foreach($row in $receipt.targets){
 $path=$repo+'/'+$row.target
 if($row.target -notin @('game/scripts/world/world_v15_visible_stream_20261018r.gd','game/scripts/world/world_v15_stream_overlap_20261018r.gd')){throw 'ONLY_TWO_WORLD_GD_TARGETS_ALLOWED'}
 if($baseline.facts[$path].sha256 -cne $row.old_sha256){throw ('BASELINE_TARGET_BEFORE_MISMATCH:'+ $path)}
 $authorized[$path]=$row
}
if($authorized.Count -ne 2){throw 'EXACT_TWO_WORLD_GD_TARGETS_REQUIRED'}
$budgetPath=$repo+'/game/build/world_bridges_20261030m_system01/FINAL_02_budget_receipt_CANDIDATE.json'
if((Hash-Only $budgetPath) -cne 'b9b15fd2a422c134c8da3f1843ce93f49c59baedd8b5475cec31d1241b02dbe2'){throw 'EXACT_ROOT_APPLIED_BUDGET_ONE_HUNK_RECEIPT_REQUIRED'}
$budget=Json-Report $budgetPath
$streamPath=$repo+'/game/scripts/world/world_v15_visible_stream_20261018r.gd'
if($budget.target -cne 'game/scripts/world/world_v15_visible_stream_20261018r.gd' -or $budget.old_sha256 -cne $authorized[$streamPath].new_sha256 -or $budget.new_sha256 -cne 'bf465430c1bc74c93b39c917e05ed802751221ee32939fa16d6ac814873c2a65' -or $budget.replacements.Count -ne 1 -or $budget.whole_byte_inverse -ne $true){throw 'NO_WIDER_SOURCE_ALLOWANCE_FOR_BUDGET_SUCCESSOR'}
$authorized[$streamPath].new_sha256=$budget.new_sha256
$authorized[$streamPath].bytes=$budget.bytes
$strictPath=$repo+'/game/build/world_bridges_20261030m_system01/FINAL_03_strict_rows_receipt_CANDIDATE.json'
if((Hash-Only $strictPath) -cne '6bf46a2780bcdce0ec791189da61d103d8d33f1bcc6212e0ad5f8475c5f94212'){throw 'EXACT_ROOT_APPLIED_STRICT_TRES_ROWS_RECEIPT_REQUIRED'}
$strict=Json-Report $strictPath
if($strict.matches_original_logic_identical -ne $true -or $strict.epsilon_added -ne $false -or $strict.targets.Count -ne 3 -or $strict.new_modules.Count -ne 1){throw 'STRICT_ROWS_NOT_A_MATCH_GUARD_RELAXATION'}
$strictOverrides=@{}
foreach($entry in $strict.targets){
 $path=$repo+'/'+$entry.target
 if($path -ceq $streamPath){
  if($entry.old_sha256 -cne $authorized[$streamPath].new_sha256 -or $entry.new_sha256 -cne '2a7bc5badced3c22b0727ccdca918c38a30d8f4437a56438bdb7c5002f324622'){throw 'EXACT_STREAM_BF_TO_STRICT_BINDING_CHAIN_REQUIRED'}
  $authorized[$streamPath].new_sha256=$entry.new_sha256;$authorized[$streamPath].bytes=$entry.bytes
 }elseif($entry.target -cin @('game/build/world_bridges_20261030m_system01/bridge_visual_patch.gd','game/art/modules/world_bridges_20261030m/bridge_bindings.json')){
  if($receipt.new_modules[$entry.target].sha256 -cne $entry.old_sha256){throw 'NEW_MODULE_STRICT_SUCCESSOR_OLD_PIN_MISMATCH'}
  $strictOverrides[$path]=@{sha256=$entry.new_sha256;bytes=$entry.bytes}
 }else{throw 'NO_WIDER_TARGET_ALLOWANCE_FOR_STRICT_ROWS'}
}
if($strictOverrides.Count -ne 2 -or -not $strict.new_modules.Contains('game/build/world_bridges_20261030m_system01/bridge_source_rows_LAYOUT_TYPED_03_READY.json')){throw 'ONLY_HELPER_BINDING_PLUS_ONE_TYPED_ROWS_MODULE_ALLOWED'}
if($strict.new_modules['game/build/world_bridges_20261030m_system01/bridge_source_rows_LAYOUT_TYPED_03_READY.json'].sha256 -cne 'dd1e58a5955803d6c351eb87833731174483688c135de6a4fc14309fe39bcfed'){throw 'EXACT_CANONICAL_TYPED_ROWS_DD1E_REQUIRED'}


$parallel=@(($repo+'/game/build/three_towns_world_20261029j_system01/native_sources.json'),($repo+'/game/build/three_towns_world_20261029j_system01/town_registry.gd'))
$beforeProcesses=@(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'" | Select-Object ProcessId,Name,ExecutablePath,CommandLine,CreationDate)
if($beforeProcesses.Count -ne 1 -or $beforeProcesses[0].ProcessId -ne 51856){$errors.Add('ONLY_EDITOR51856_REQUIRED_BEFORE')}
$actual=[ordered]@{};$authorizedDiff=@();$parallelDiff=@();$unexpected=@();$saveDiff=@();$sources=0;$saves=0;$absent=0
foreach($path in ($baseline.facts.Keys | Sort-Object)){
 $now=Metadata $path;$actual[$path]=$now
 if(-not $now.stable_during_hash){$errors.Add('FILE_CHANGED_DURING_HASH:'+ $path)}
 if($path.Contains('/app_userdata/')){
  $saves+=1
  if(-not $now.exists){$absent+=1}
  if(-not (Same-Metadata $baseline.facts[$path] $now)){$saveDiff+=@([ordered]@{path=$path;before=$baseline.facts[$path];now=$now});$errors.Add('SAVE_EXACT_METADATA_CHANGED:'+ $path)}
 }else{
  $sources+=1
  if($authorized.Contains($path)){
   $entry=$authorized[$path]
   if(-not $now.exists -or $now.sha256 -cne $entry.new_sha256 -or $now.bytes -ne $entry.bytes){$errors.Add('AUTHORIZED_WORLD_FINAL_MISMATCH:'+ $path)}
   $authorizedDiff+=@([ordered]@{path=$path;before=$baseline.facts[$path];now=$now;exact_FINAL_sha256=$entry.new_sha256})
  }elseif(-not (Same-Metadata $baseline.facts[$path] $now)){
   $row=[ordered]@{path=$path;before=$baseline.facts[$path];now=$now;restore_or_rollback=$false}
   if($parallel -contains $path){$parallelDiff+=@($row);$errors.Add('KNOWN_PARALLEL_SOURCE_DIFF_RETAINED_NOT_CLAIMED_EXACT:'+ $path)}
   else{$unexpected+=@($row);$errors.Add('UNAUTHORIZED_BASELINE_SOURCE_DIFF:'+ $path)}
  }
 }
}
if($sources -ne 600 -or $saves -ne 171 -or $absent -ne 9){$errors.Add('EXACT600_SOURCE171_SAVE_9_EXPECTED_ABSENCE_COUNTS')}
# Exact scoped new leaves only. No repository/catalog recursion or allowances.
$newFacts=[ordered]@{}
$expected=@{}
foreach($path in $receipt.new_modules.Keys){$expected[$repo+'/'+$path]=$receipt.new_modules[$path]}
foreach($path in $receipt.immutable_runtime_inputs.Keys){$expected[$repo+'/'+$path]=$receipt.immutable_runtime_inputs[$path]}
foreach($row in $promote.facts){$expected[$row.path]=@{sha256=$row.sha256.ToLowerInvariant();bytes=$row.bytes}}
foreach($path in $strictOverrides.Keys){$expected[$path]=$strictOverrides[$path]}
foreach($path in $strict.new_modules.Keys){$expected[$repo+'/'+$path]=$strict.new_modules[$path]}

foreach($path in $expected.Keys){
 $now=if($actual.Contains($path)){$actual[$path]}else{Metadata $path}
 $newFacts[$path]=$now
 if(-not $now.exists -or -not $now.stable_during_hash -or $now.sha256 -cne $expected[$path].sha256 -or $now.bytes -ne $expected[$path].bytes){$errors.Add('SCOPED_NEW_RESOURCE_PIN_MISMATCH:'+ $path)}
}
$gpuFacts=$null
if(-not [string]::IsNullOrEmpty($GpuReport)){
 $gpuPath=[IO.Path]::GetFullPath($GpuReport).Replace('\','/')
 if(-not $gpuPath.StartsWith($dir+'/',[StringComparison]::OrdinalIgnoreCase)){throw 'GPU_REPORT_MUST_BE_EXPLICIT_SCOPED_QA_ARTIFACT'}
 $gpu=Json-Report $gpuPath
 $gpuFacts=[ordered]@{path=$gpuPath;sha256=(Hash-Only $gpuPath);passed=$gpu.passed;checks=$gpu.checks;errors=$gpu.errors;metadata_guard_does_not_rerun_or_override_GPU=$true}
}
$afterProcesses=@(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'" | Select-Object ProcessId,Name,ExecutablePath,CommandLine,CreationDate)
if($afterProcesses.Count -ne 1 -or $afterProcesses[0].ProcessId -ne 51856){$errors.Add('ONLY_EDITOR51856_REQUIRED_AFTER')}
if((Hash-Only $baselinePath) -cne '1bd4f781041d605de01148a2528416c6ce0333cc356fa396df98d7a81f75df23'){$errors.Add('FIRST_BASELINE_REPORT_CHANGED')}
$result=[ordered]@{
 passed=($errors.Count -eq 0);status='METADATA_ONLY_FINAL_NO_ENGINE_OR_MATRIX'
 source_count=$sources;save_count=$saves;expected_absent_save_paths=$absent;source_facts=$actual;scoped_new_resources=$newFacts
 first_NOW_whole_FAIL_preserved=$true;first_NOW_sha256='1bd4f781041d605de01148a2528416c6ce0333cc356fa396df98d7a81f75df23'
 exact_absence9_residual_inherited=$true;absence_residual_sha256='e48631c8f054fc463a6227304050744a971c730baa1c8f7a5f43c69c63dc20a7'
 authorized_only_two_world_GD_FINAL=$authorizedDiff;Root_applied_budget_one_hunk_chain=@{receipt=$budgetPath;before=$budget.old_sha256;after=$budget.new_sha256};parallel_native_registry_differences_not_rollback=$parallelDiff
 unexpected_source_differences=$unexpected;save_differences=$saveDiff;errors=$errors.ToArray()
 historical_reference_differences_preserved=$baseline.historical_since_30l_reference
 Root_applied_strict_TRES_rows_chain=@{receipt=$strictPath;new_modules=$strict.new_modules;matches_original_logic_identical=$true;epsilon_added=$false};GPU_evidence=$gpuFacts;godot_before=$beforeProcesses;godot_after=$afterProcesses
 catalog_authorization_is_separate_explicit_Art_manifest_not_broad_source_exemption=$true
 engine_runs=0;process_control=0;save_deserializations=0;save_writes=0;production_writes=0
}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($result | ConvertTo-Json -Depth 15)+[Environment]::NewLine)
$file=[IO.File]::Open($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
try{$file.Write($bytes,0,$bytes.Length)}finally{$file.Dispose()}
[ordered]@{passed=$result.passed;sources=$sources;saves=$saves;new_resources=$newFacts.Count;parallel_differences=$parallelDiff.Count;unexpected=$unexpected.Count;save_differences=$saveDiff.Count;errors=$errors.ToArray();report=$output;sha256=(Hash-Only $output)} | ConvertTo-Json -Depth 4
if($errors.Count -gt 0){exit 1}
