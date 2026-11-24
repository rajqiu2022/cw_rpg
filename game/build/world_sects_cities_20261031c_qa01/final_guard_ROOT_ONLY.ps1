param([Parameter(Mandatory=$true)][string]$ExpectedManifest,[Parameter(Mandatory=$true)][ValidatePattern('^[a-f0-9]{64}$')][string]$ExpectedManifestSHA,[string]$OutputName='final_guard_ACTUAL.json')
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'USE_BUNDLED_PWSH7'}
$repo='F:/Code/RPG_GAME'
$taskDir=$repo+'/game/build/world_sects_cities_20261031c_qa01'
if([IO.Path]::GetFileName($OutputName) -cne $OutputName -or $OutputName -notmatch '^[A-Za-z0-9_-]+\.json$'){throw 'BASENAME_ONLY'}
$output=$taskDir+'/'+$OutputName
if(Test-Path -LiteralPath $output){throw 'EXISTING_REPORT_RETAINED'}
$errors=[Collections.Generic.List[string]]::new()
function Hash-Bytes([byte[]]$bytes){return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()}
function Hash-Only([string]$path){$s=[IO.File]::OpenRead($path);try{return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($s)).ToLowerInvariant()}finally{$s.Dispose()}}
function Read-JsonData([string]$path){if($path.Contains('/app_userdata/')){throw 'NO_SAVE_DESERIALIZATION'};return [IO.File]::ReadAllText($path,[Text.Encoding]::UTF8)|ConvertFrom-Json -AsHashtable}
function Canonical([string]$path){if($path.StartsWith('res://')){$path=$repo+'/game/'+$path.Substring(6)}elseif(-not [IO.Path]::IsPathRooted($path)){$path=$repo+'/'+$path};return [IO.Path]::GetFullPath($path).Replace('\','/')}
function Metadata([string]$path){
 $i=Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
 if($null -eq $i){return [ordered]@{exists=$false;bytes=$null;utc_ticks=$null;sha256=$null;stable_during_hash=$true}}
 $length=[long]$i.Length;$ticks=[string]$i.LastWriteTimeUtc.Ticks
 try{$sha=Hash-Only $path;$j=Get-Item -LiteralPath $path;return [ordered]@{exists=$true;bytes=$length;utc_ticks=$ticks;sha256=$sha;stable_during_hash=($length -eq $j.Length -and $ticks -ceq [string]$j.LastWriteTimeUtc.Ticks)}}
 catch{$script:errors.Add('METADATA_READ_FAILED:'+ $path);return [ordered]@{exists=$true;bytes=$length;utc_ticks=$ticks;sha256=$null;stable_during_hash=$false}}
}
function Same($a,$b){foreach($k in @('exists','bytes','utc_ticks','sha256')){if($a[$k] -cne $b[$k]){return $false}};return $true}
function Engines {return @(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'"|ForEach-Object{[ordered]@{pid=[int]$_.ProcessId;parent_pid=[int]$_.ParentProcessId;name=$_.Name;exe=$_.ExecutablePath;command_line=$_.CommandLine;creation_utc=$_.CreationDate.ToUniversalTime().ToString('o')}})}
function Pin([string]$path,[string]$sha){if((Hash-Only $path) -cne $sha){throw ('EVIDENCE_PIN_CHANGED:'+ $path)}}

$manifestPath=if([IO.Path]::GetFileName($ExpectedManifest) -ceq $ExpectedManifest){$taskDir+'/'+$ExpectedManifest}else{Canonical $ExpectedManifest}
if(-not $manifestPath.StartsWith($taskDir+'/',[StringComparison]::OrdinalIgnoreCase)){throw 'EXPECTED_MANIFEST_MUST_BE_THIS_QA_DIRECTORY'}
Pin $manifestPath $ExpectedManifestSHA
$expected=Read-JsonData $manifestPath
$baselinePath=$taskDir+'/baseline_NOW_ACTUAL.json'
Pin $baselinePath '59b75d6bdd34fb4dfe82ffff189f38140a0beacac0b3839b3a5491c68913e127'
$baseline=Read-JsonData $baselinePath
if(-not $baseline.passed -or $baseline.source_count -ne 1770 -or $baseline.save_count -ne 171 -or $baseline.expected_absent_save_paths.Count -ne 9){throw 'EXACT1770_171_9_FRESH_BASELINE_REQUIRED'}
if($expected.allowed_old_targets.Count -ne 11 -or $expected.historical_authorized_targets.Count -ne 9 -or $expected.native_count -ne 221 -or $expected.registry_count -ne 17){throw 'EXPLICIT_FRESH11_HISTORICAL9_PLUS_WATCHER_221_17_SCOPE'}
$receiptFacts=[ordered]@{}
foreach($relative in $expected.receipt_pins.Keys){
 $path=Canonical $relative;$fact=Metadata $path;$receiptFacts[$path]=$fact
 if($fact.sha256 -cne $expected.receipt_pins[$relative].sha256 -or $fact.bytes -ne $expected.receipt_pins[$relative].bytes){throw ('FORMAL_RECEIPT_PIN_CHANGED:'+ $path)}
}
$allowed=@{}
foreach($relative in $expected.allowed_old_targets.Keys){$allowed[(Canonical $relative)]=$expected.allowed_old_targets[$relative]}
foreach($path in $allowed.Keys){if(-not $baseline.facts.ContainsKey($path)){throw ('DO_NOT_INVENT_FRESH_COVERAGE:'+ $path)}}
foreach($relative in $expected.historical_authorized_targets.Keys){if($baseline.facts.ContainsKey((Canonical $relative))){throw 'HISTORICAL_GROUP_MUST_NOT_BE_CLAIMED_FRESH'}}
$processBefore=@(Engines)
if($processBefore.Count -ne 1 -or $processBefore[0].pid -ne 51856){$errors.Add('ONLY_EDITOR51856_REQUIRED_BEFORE')}
$facts=[ordered]@{};$saveSecond=[ordered]@{};$unexpected=@();$saveDiff=@();$authorized=@();$sources=0;$saves=0
foreach($path in $baseline.facts.Keys){
 $now=Metadata $path;$facts[$path]=$now;$isSave=$path.Contains('/app_userdata/')
 if($isSave){$saves++}else{$sources++}
 if(-not $now.stable_during_hash){$errors.Add('UNSTABLE_HASH:'+ $path)}
 if($allowed.ContainsKey($path)){
  $entry=$allowed[$path]
  if($baseline.facts[$path].sha256 -cne $entry.before_sha256 -or $baseline.facts[$path].bytes -ne $entry.before_bytes -or $now.sha256 -cne $entry.after_sha256 -or $now.bytes -ne $entry.after_bytes){$errors.Add('EXPLICIT_AUTHORIZED_SOURCE_NOT_EXACT:'+ $path)}
  $authorized+=@([ordered]@{path=$path;fresh_before=$baseline.facts[$path];after=$now;expected=$entry;changed=(-not (Same $baseline.facts[$path] $now))})
 }elseif(-not (Same $baseline.facts[$path] $now)){
  $row=[ordered]@{path=$path;before=$baseline.facts[$path];after=$now;rollback=$false}
  if($isSave){$saveDiff+=@($row);$errors.Add('SAVE_METADATA_DIFF:'+ $path)}else{$unexpected+=@($row);$errors.Add('UNEXPECTED_FRESH_SOURCE_DIFF:'+ $path)}
 }
}
foreach($path in $baseline.facts.Keys){
 if(-not $path.Contains('/app_userdata/')){continue}
 $now=Metadata $path;$saveSecond[$path]=$now
 if(-not $now.stable_during_hash -or -not (Same $facts[$path] $now) -or -not (Same $baseline.facts[$path] $now)){$errors.Add('SAVE_FRESH_SECOND_NOT_EXACT:'+ $path)}
}
foreach($path in $baseline.expected_absent_save_paths){if($facts[$path].exists -or $saveSecond[$path].exists){$errors.Add('EXPECTED_ABSENCE_CHANGED:'+ $path)}}
if($sources -ne 1770 -or $saves -ne 171 -or $authorized.Count -ne 11){$errors.Add('EXPECTED1770_171_AND11_FRESH_AUTHORIZATIONS')}
$historical=[ordered]@{};$newPins=[ordered]@{};$chainEvidence=@()
foreach($relative in $expected.historical_authorized_targets.Keys){
 $entry=$expected.historical_authorized_targets[$relative];$path=Canonical $relative;$now=Metadata $path;$before=Metadata (Canonical $entry.before_snapshot)
 if($entry.fresh_baseline_included -ne $false -or $entry.old_mtime_claimed -ne $false){throw 'NO_HISTORICAL_FILE_OLD_MTIME_CLAIMS'}
 if($now.sha256 -cne $entry.after_sha256 -or $now.bytes -ne $entry.after_bytes -or $before.sha256 -cne $entry.historical_before_sha256 -or $before.bytes -ne $entry.historical_before_bytes){$errors.Add('HISTORICAL_BYTE_CHAIN_PIN:'+ $path)}
 $historical[$path]=[ordered]@{after_observed_now=$now;historical_before_sha256=$entry.historical_before_sha256;historical_before_bytes=$entry.historical_before_bytes;before_snapshot_observed_now=$before;evidence_chain=$entry.evidence_chain;fresh_baseline_included=$false;old_mtime_claimed=$false;rollback=$false}
}
# Validate each bounded declared byte edge and backup; do not re-run565-source overlay.
$entries=@($expected.allowed_old_targets.Values)+@($expected.historical_authorized_targets.Values)
foreach($entry in $entries){
 foreach($edge in $entry.evidence_chain){
  if(-not $edge.ContainsKey('candidate')){continue}
  $candidate=Metadata (Canonical $edge.candidate)
  if($candidate.sha256 -cne $edge.new_sha256){$errors.Add('CANDIDATE_EDGE_SHA:'+ $edge.candidate)}
  $before=$null
  if(-not [string]::IsNullOrEmpty([string]$edge.before)){$before=Metadata (Canonical $edge.before);if($before.sha256 -cne $edge.old_sha256){$errors.Add('BEFORE_EDGE_SHA:'+ $edge.before)}}
  $chainEvidence+=@([ordered]@{receipt=$edge.receipt;old_sha256=$edge.old_sha256;new_sha256=$edge.new_sha256;before_snapshot_now=$before;candidate_now=$candidate;exact_inverse_credit='Inherited pinned author proof and Root formal application; guard does not reexecute diff'})
 }
}
foreach($relative in $expected.new_runtime_pins.Keys){
 $entry=$expected.new_runtime_pins[$relative];$path=Canonical $relative;$fact=Metadata $path;$newPins[$path]=$fact
 if($fact.sha256 -cne $entry.sha256 -or $fact.bytes -ne $entry.bytes -or -not $fact.stable_during_hash){$errors.Add('NEW_RUNTIME_PIN:'+ $path)}
}
$watch=$expected.unseeded_authorized_old;$watchPath=Canonical $watch.path;$watchNow=Metadata $watchPath;$watchProof=$null
if($baseline.facts.ContainsKey($watchPath) -or $watch.fresh_baseline_included -ne $false -or $watch.old_mtime_claimed -ne $false){throw 'WORLD_WATCHER_NOT_FRESH_OLD_MTIME_NOT_CLAIMED'}
if($watchNow.sha256 -cne $watch.sha256 -or $watchNow.bytes -ne $watch.bytes){$errors.Add('WATCHER_FINAL_PIN')}
try{
 $proofPath=Canonical $watch.proof_script.path;Pin $proofPath $watch.proof_script.sha256
 $proofText=& 'C:/Users/rajqiu/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' $proofPath
 $code=$LASTEXITCODE
 if($code -ne 0){throw 'WATCHER_HISTORICAL_INVERSE_FAILED'}
 $watchProof=$proofText|ConvertFrom-Json -AsHashtable
 if($watchProof.current_sha256 -cne $watch.sha256 -or $watchProof.inverse_sha256 -cne $watch.historical_before_sha256 -or $watchProof.inverse_bytes -ne $watch.historical_before_bytes -or $watchProof.old_mtime_not_claimed -ne $true -or $watchProof.matches_historical_auth_FINAL -ne $true){throw 'WATCHER_PROOF_FIELDS_NOT_EXACT'}
}catch{$errors.Add('WATCHER_HISTORY_ONLY_PROOF:'+ $_.Exception.Message)}
$nativePath=Canonical $expected.native_path;$native=Read-JsonData $nativePath
$nativeBeforePath=Canonical $expected.native_before.path;Pin $nativeBeforePath $expected.native_before.sha256
$oldNative=Read-JsonData $nativeBeforePath
if($oldNative.sources.Count -ne 202 -or $native.sources.Count -ne $expected.native_count){$errors.Add('NATIVE202_TO_EXPLICIT221_COUNT')}
$oldPreserved=0
foreach($path in $oldNative.sources.Keys){
 $required=if($expected.old_native_updated_source_keys.ContainsKey($path)){$expected.old_native_updated_source_keys[$path]}else{$oldNative.sources[$path]}
 if($native.sources[$path] -cne $required){$errors.Add('ORIGINAL_NATIVE_KEY_UNEXPECTED_CHANGE:'+ $path)}else{$oldPreserved++}
}
$dependencies=[ordered]@{}
foreach($path in $native.sources.Keys){
 $absolute=Canonical $path
 $fact=if($facts.Contains($absolute)){$facts[$absolute]}elseif($newPins.Contains($absolute)){$newPins[$absolute]}elseif($absolute -ceq $watchPath){$watchNow}else{Metadata $absolute}
 $dependencies[$path]=$fact
 if($fact.sha256 -cne $native.sources[$path] -or -not $fact.stable_during_hash){$errors.Add('NATIVE_DEPENDENCY_PIN:'+ $path)}
}
$registryBeforePath=Canonical $expected.registry_before.path;Pin $registryBeforePath $expected.registry_before.sha256
function Registry-IDs([string]$path){
 $text=[IO.File]::ReadAllText($path,[Text.Encoding]::UTF8)
 $list=[regex]::Match($text,'const IDS\s*:=\s*(\[[^\]]+\])').Groups[1].Value
 return @([regex]::Matches($list,'"([^"\r\n]+)"')|ForEach-Object{$_.Groups[1].Value})
}
$oldIDs=@(Registry-IDs $registryBeforePath);$newIDs=@(Registry-IDs (Canonical $expected.registry_path))
if($oldIDs.Count -ne 16 -or $newIDs.Count -ne $expected.registry_count -or ($newIDs|Select-Object -Unique).Count -ne $newIDs.Count){$errors.Add('REGISTRY16_TO17_IDS')}
for($i=0;$i -lt [Math]::Min($oldIDs.Count,$newIDs.Count);$i++){if($oldIDs[$i] -cne $newIDs[$i]){$errors.Add('ORIGINAL_REGISTRY_ORDER_OR_ID_CHANGED')}}
$processAfter=@(Engines)
if($processAfter.Count -ne 1 -or $processAfter[0].pid -ne 51856){$errors.Add('ONLY_EDITOR51856_REQUIRED_AFTER')}
if(($processBefore|ConvertTo-Json -Depth 5 -Compress) -cne ($processAfter|ConvertTo-Json -Depth 5 -Compress)){$errors.Add('EDITOR_IDENTITY_CHANGED')}
$result=[ordered]@{
 passed=($errors.Count -eq 0);status='FINAL31C_METADATA_ONLY_NO_ENGINE_NO_REBASE';expected_manifest=$manifestPath;expected_manifest_sha256=$ExpectedManifestSHA
 baseline_sha256=$expected.baseline_sha256;source_count=$sources;save_count=$saves;facts=$facts;save_second_facts=$saveSecond;expected_absent_save_paths=$baseline.expected_absent_save_paths
 authorized_fresh_source_changes=$authorized;unexpected_fresh_source_changes=$unexpected;save_changes=$saveDiff
 authorized_old_file_count_including_tasks=21;fresh_authorized_count=11;historical_authorized_count=10
 historical_authorized_targets=$historical;watcher_history_only=[ordered]@{path=$watchPath;after_observed_now=$watchNow;historical_inverse=$watchProof;fresh_baseline_included=$false;old_mtime_claimed=$false}
 receipt_facts=$receiptFacts;bounded_candidate_byte_edges=$chainEvidence;new_runtime_pins=$newPins
 native_dependency_facts=$dependencies;native_old202_declared_updates_preserved=$oldPreserved;native_current_count=$native.sources.Count
 original16_registry_IDs=$oldIDs;current17_registry_IDs=$newIDs;historical_updates_from_baseline=$baseline.historical_since_31b
 godot_processes_before=$processBefore;godot_processes_after=$processAfter;errors=$errors.ToArray()
 engine_runs=0;process_control=0;save_deserializations=0;save_writes=0;production_writes=0;successful_actual_matrices_not_repeated=$true;old_exit_errors_not_claimed_clean=$true
}
$utf8=[Text.UTF8Encoding]::new($false);$file=[IO.File]::Open($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
try{$payload=$utf8.GetBytes(($result|ConvertTo-Json -Depth 20)+[Environment]::NewLine);$file.Write($payload,0,$payload.Length)}finally{$file.Dispose()}
[ordered]@{passed=$result.passed;source_count=$sources;save_count=$saves;authorized_fresh=11;authorized_history=10;unexpected=$unexpected.Count;save_changes=$saveDiff.Count;errors=$errors.ToArray();report=$output;sha256=(Hash-Only $output)}|ConvertTo-Json -Depth 5
if($errors.Count -gt 0){exit 1}
