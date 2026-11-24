param([string]$OutputName='final_guard_ACTUAL.json')
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'USE_BUNDLED_PWSH7'}
$repo='F:/Code/RPG_GAME'
$taskDir=$repo+'/game/build/lanxi_terrace_banks_20261031b_qa01'
if([IO.Path]::GetFileName($OutputName) -cne $OutputName -or $OutputName -notmatch '^[A-Za-z0-9_-]+\.json$'){throw 'BASENAME_ONLY'}
$output=$taskDir+'/'+$OutputName
if(Test-Path -LiteralPath $output){throw 'EXISTING_REPORT_RETAINED'}
$errors=[Collections.Generic.List[string]]::new()
function Hash-Bytes([byte[]]$bytes){return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()}
function Hash-Only([string]$path){$s=[IO.File]::OpenRead($path);try{return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($s)).ToLowerInvariant()}finally{$s.Dispose()}}
function Read-JsonData([string]$path){if($path.Contains('/app_userdata/')){throw 'NO_SAVE_DESERIALIZATION'};return [IO.File]::ReadAllText($path,[Text.Encoding]::UTF8)|ConvertFrom-Json -AsHashtable}
function Canonical([string]$path){if($path.StartsWith('res://')){$path=$repo+'/game/'+$path.Substring(6)}elseif($path.StartsWith('game/')){$path=$repo+'/'+$path};return [IO.Path]::GetFullPath($path).Replace('\','/')}
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

$baselinePath=$taskDir+'/baseline_NOW_ACTUAL.json'
$receiptPath=$repo+'/game/build/lanxi_paddy_passage_20261031b_system01/replacement_receipt_READY.json'
Pin $baselinePath '0fd676ce7c77349ace76a395726cd22699f1f021216d97f578fa8b83c3e533fb'
Pin $receiptPath 'ec969d124bdeab29019e4400092784dcb9e7035d5d6ada18335d84f7556b1594'
$baseline=Read-JsonData $baselinePath;$receipt=Read-JsonData $receiptPath
if(-not $baseline.passed -or $baseline.source_count -ne 986 -or $baseline.save_count -ne 171 -or $baseline.expected_absent_save_paths.Count -ne 9){throw 'EXACT986_171_9_FRESH_BASELINE_REQUIRED'}
$allowed=@{}
foreach($target in $receipt.targets){$allowed[(Canonical $target.target)]=$target}
if($allowed.Count -ne 3 -or @($receipt.new_modules).Count -ne 1){throw 'ONLY_THREE_OLD_TARGETS_ONE_NEW_HELPER'}
$processBefore=@(Engines)
if($processBefore.Count -ne 1 -or $processBefore[0].pid -ne 51856){$errors.Add('ONLY_EDITOR51856_REQUIRED_BEFORE')}
$facts=[ordered]@{};$saveSecond=[ordered]@{};$sourceDiff=@();$saveDiff=@();$authorized=@();$saveCount=0;$sourceCount=0
foreach($path in $baseline.facts.Keys){
 $now=Metadata $path;$facts[$path]=$now;$isSave=$path.Contains('/app_userdata/')
 if($isSave){$saveCount++}else{$sourceCount++}
 if(-not $now.stable_during_hash){$errors.Add('UNSTABLE_HASH:'+ $path)}
 if(Same $baseline.facts[$path] $now){continue}
 $row=[ordered]@{path=$path;before=$baseline.facts[$path];after=$now;rollback=$false}
 if($isSave){$saveDiff+=@($row);$errors.Add('SAVE_METADATA_DIFF:'+ $path)}
 elseif($allowed.ContainsKey($path)){
  $target=$allowed[$path]
  if($baseline.facts[$path].sha256 -cne $target.before.sha256 -or $now.sha256 -cne $target.candidate.sha256 -or $now.bytes -ne $target.candidate.bytes){$errors.Add('AUTHORIZED_TARGET_NOT_EXACT:'+ $path)}
  $authorized+=@($row)
 }else{$sourceDiff+=@($row);$errors.Add('UNEXPECTED_SOURCE_DIFF:'+ $path)}
}
foreach($path in $baseline.facts.Keys){
 if(-not $path.Contains('/app_userdata/')){continue}
 $now=Metadata $path;$saveSecond[$path]=$now
 if(-not $now.stable_during_hash -or -not (Same $facts[$path] $now) -or -not (Same $baseline.facts[$path] $now)){$errors.Add('SAVE_FRESH_SECOND_NOT_EXACT:'+ $path)}
}
foreach($path in $baseline.expected_absent_save_paths){if($facts[$path].exists -or $saveSecond[$path].exists){$errors.Add('EXPECTED_ABSENCE_CHANGED:'+ $path)}}
if($sourceCount -ne 986 -or $saveCount -ne 171 -or $authorized.Count -ne 3){$errors.Add('EXPECTED986_171_THREE_AUTHORIZED_DIFFS')}
$inverse=@();$oldNative=$null
$staticProofPath=$repo+'/game/build/lanxi_paddy_passage_20261031b_system01/inverse_and_neighbor_STATIC_READY.json'
Pin $staticProofPath '4fa772682a91789fc62c91beb2366cf6d133e6ac3bb6129992fe76a2f929cc6b'
$staticProof=Read-JsonData $staticProofPath
foreach($target in $receipt.targets){
 $path=Canonical $target.target;$beforePath=Canonical $target.before.path;$candidatePath=Canonical $target.candidate.path
 $beforeFact=Metadata $beforePath;$candidateFact=Metadata $candidatePath
 if($beforeFact.sha256 -cne $target.before.sha256 -or $beforeFact.bytes -ne $target.before.bytes -or $beforeFact.sha256 -cne $baseline.facts[$path].sha256){throw ('BEFORE_BACKUP_NOT_FRESH_BASELINE:'+ $path)}
 if($candidateFact.sha256 -cne $target.candidate.sha256 -or $candidateFact.bytes -ne $target.candidate.bytes){throw ('CANDIDATE_NOT_RECEIPT_PIN:'+ $path)}
 $match=@($staticProof.records|Where-Object{$_.before_sha256 -ceq $beforeFact.sha256 -and $_.after_sha256 -ceq $candidateFact.sha256 -and $_.forward_byte_exact -eq $true -and $_.inverse_byte_exact -eq $true})
 if($match.Count -ne 1){throw ('PINNED_STATIC_FORWARD_INVERSE_EVIDENCE_MISSING:'+ $path)}
 if($target.target.EndsWith('native_sources.json')){$oldNative=Read-JsonData $beforePath}
 $inverse+=@([ordered]@{path=$path;before_backup=$beforeFact;candidate=$candidateFact;pinned_System_in_memory_forward_inverse_evidence=$match[0];guard_did_not_reexecute_diff_or_write_source=$true})
}
$modules=[ordered]@{}
foreach($entry in @($receipt.new_modules)){
 $path=Canonical $entry.path;$fact=Metadata $path;$modules[$path]=$fact
 if($fact.sha256 -cne $entry.sha256 -or $fact.bytes -ne $entry.bytes -or -not $fact.stable_during_hash){$errors.Add('NEW_HELPER_PIN:'+ $path)}
}
$native=Read-JsonData ($repo+'/game/build/three_towns_world_20261029j_system01/native_sources.json')
if($oldNative.sources.Count -ne $receipt.source_count_before -or $native.sources.Count -ne $receipt.source_count_after){throw 'EXPECTED_RECEIPT_NATIVE_KEY_COUNTS'}
$sceneURI='res://scenes/drafts/miao_terrain_20261029i/miao_town.tscn'
$preserved=0
foreach($path in $oldNative.sources.Keys){
 if($path -ceq $sceneURI){if($native.sources[$path] -cne '80d0a6207197012b800a0894a3bf8e60de38c223c98fc7a029e7f0747b6c6206'){$errors.Add('AUTHORIZED_SCENE_NATIVE_KEY_NOT_FINAL')};continue}
 if($native.sources[$path] -cne $oldNative.sources[$path]){$errors.Add('OLD_NATIVE_KEY_VALUE_CHANGED:'+ $path)}else{$preserved++}
}
$dependencies=[ordered]@{}
foreach($path in $native.sources.Keys){
 $absolute=Canonical $path
 $fact=if($facts.Contains($absolute)){$facts[$absolute]}elseif($modules.Contains($absolute)){$modules[$absolute]}else{Metadata $absolute}
 $dependencies[$path]=$fact
 if($fact.sha256 -cne $native.sources[$path] -or -not $fact.stable_during_hash){$errors.Add('NATIVE_DEPENDENCY_PIN:'+ $path)}
}
$qaPins=[ordered]@{
 'game/build/lanxi_terrace_banks_20261031b_qa01/paddy_ROOT_ONLY.gd'='66914e73ed628824fd5c37a51c48614f17968b46e2da1c02aa379221399e9600'
 'game/build/lanxi_terrace_banks_20261031b_qa01/actual_inputs_READY.json'='a108c35ff349c636fef8dee61376bfb026d5723e2e60eecf7871d6a3ba1da50e'
}
$qaFacts=[ordered]@{}
foreach($relative in $qaPins.Keys){$path=Canonical $relative;$fact=Metadata $path;$qaFacts[$path]=$fact;if($fact.sha256 -cne $qaPins[$relative]){$errors.Add('FROZEN_QA_EVIDENCE_PIN:'+ $path)}}
$processAfter=@(Engines)
if($processAfter.Count -ne 1 -or $processAfter[0].pid -ne 51856){$errors.Add('ONLY_EDITOR51856_REQUIRED_AFTER')}
if(($processBefore|ConvertTo-Json -Compress -Depth 5) -cne ($processAfter|ConvertTo-Json -Compress -Depth 5)){$errors.Add('EDITOR_IDENTITY_CHANGED')}
$result=[ordered]@{
 passed=($errors.Count -eq 0);status='FINAL_METADATA_ONLY_NO_ENGINE_RETEST';baseline_sha256='0fd676ce7c77349ace76a395726cd22699f1f021216d97f578fa8b83c3e533fb'
 source_count=$sourceCount;save_count=$saveCount;facts=$facts;save_second_facts=$saveSecond;expected_absent_save_paths=$baseline.expected_absent_save_paths
 authorized_source_changes=$authorized;unexpected_source_changes=$sourceDiff;save_changes=$saveDiff;exact_source_inverse=$inverse
 new_modules=$modules;native_dependency_facts=$dependencies;native_old_keys_only_authorized_scene_hash_changed=$true;native_other200_keys_preserved=$preserved;native_new_count=$receipt.source_count_after
 frozen_qa_evidence=$qaFacts;historical_since_31a=$baseline.historical_since_31a
 errors=$errors.ToArray();godot_processes_before=$processBefore;godot_processes_after=$processAfter
 engine_runs=0;process_control=0;save_deserializations=0;save_writes=0;production_writes=0
 new_paddy_actual_only_no_engine_retest_by_guard=$true;original7_exit_errors_and_ObjectDB_warning_retained_not_clean=$true
}
$utf8=[Text.UTF8Encoding]::new($false);$file=[IO.File]::Open($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
try{$payload=$utf8.GetBytes(($result|ConvertTo-Json -Depth 15)+[Environment]::NewLine);$file.Write($payload,0,$payload.Length)}finally{$file.Dispose()}
[ordered]@{passed=$result.passed;source_count=$sourceCount;save_count=$saveCount;authorized_source_changes=$authorized.Count;unexpected_source_changes=$sourceDiff.Count;save_changes=$saveDiff.Count;errors=$errors.ToArray();report=$output;sha256=(Hash-Only $output)}|ConvertTo-Json -Depth 5
if($errors.Count -gt 0){exit 1}
