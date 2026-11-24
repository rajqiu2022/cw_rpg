param([string]$OutputName='final_guard_ACTUAL.json')
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'USE_BUNDLED_PWSH7'}
$repo='F:/Code/RPG_GAME'
$taskDir=$repo+'/game/build/lanxi_boardwalk_edges_20261031a_qa01'
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
$receiptPath=$repo+'/game/build/lanxi_boardwalk_edges_20261031a_system01/receipt_READY.json'
Pin $baselinePath '83b5b8717598f04be5ed853b1586210a2601c6a325bc935b648ed2a08555647e'
Pin $receiptPath '44868bfd01a97b2581d61ab392ca697feba6ca6313c7ca500feed9ece3f19ead'
$baseline=Read-JsonData $baselinePath;$receipt=Read-JsonData $receiptPath
if(-not $baseline.passed -or $baseline.source_count -ne 979 -or $baseline.save_count -ne 171 -or $baseline.expected_absent_save_paths.Count -ne 9){throw 'EXACT979_171_9_FRESH_BASELINE_REQUIRED'}
$allowed=@{}
foreach($target in $receipt.targets){$allowed[(Canonical $target.target)]=$target}
if($allowed.Count -ne 3 -or $receipt.new_modules.Count -ne 1){throw 'ONLY_THREE_OLD_TARGETS_ONE_NEW_HELPER'}
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
  if($baseline.facts[$path].sha256 -cne $target.old_sha256 -or $now.sha256 -cne $target.new_sha256 -or $now.bytes -ne $target.bytes){$errors.Add('AUTHORIZED_TARGET_NOT_EXACT:'+ $path)}
  $authorized+=@($row)
 }else{$sourceDiff+=@($row);$errors.Add('UNEXPECTED_SOURCE_DIFF:'+ $path)}
}
foreach($path in $baseline.facts.Keys){
 if(-not $path.Contains('/app_userdata/')){continue}
 $now=Metadata $path;$saveSecond[$path]=$now
 if(-not $now.stable_during_hash -or -not (Same $facts[$path] $now) -or -not (Same $baseline.facts[$path] $now)){$errors.Add('SAVE_FRESH_SECOND_NOT_EXACT:'+ $path)}
}
foreach($path in $baseline.expected_absent_save_paths){if($facts[$path].exists -or $saveSecond[$path].exists){$errors.Add('EXPECTED_ABSENCE_CHANGED:'+ $path)}}
if($sourceCount -ne 979 -or $saveCount -ne 171 -or $authorized.Count -ne 3){$errors.Add('EXPECTED979_171_THREE_AUTHORIZED_DIFFS')}
$inverse=@();$oldNative=$null
foreach($target in $receipt.targets){
 $path=Canonical $target.target;$text=[IO.File]::ReadAllText($path,[Text.Encoding]::UTF8)
 if((Hash-Bytes ([Text.UTF8Encoding]::new($false).GetBytes($text))) -cne $target.new_sha256){throw ('INVERSE_FINAL_SHA:'+ $path)}
 for($i=$target.replacements.Count-1;$i -ge 0;$i--){
  $h=$target.replacements[$i]
  if(([regex]::Matches($text,[regex]::Escape([string]$h.new))).Count -ne 1){throw ('EXACT_HUNK_NOT_UNIQUE:'+ $path)}
  $text=$text.Replace([string]$h.new,[string]$h.old)
 }
 $oldHash=Hash-Bytes ([Text.UTF8Encoding]::new($false).GetBytes($text))
 if($oldHash -cne $target.old_sha256 -or $oldHash -cne $baseline.facts[$path].sha256){throw ('EXACT_INVERSE_NOT_FRESH_BASELINE:'+ $path)}
 if($target.target.EndsWith('native_sources.json')){$oldNative=$text|ConvertFrom-Json -AsHashtable}
 $inverse+=@([ordered]@{path=$path;exact_inverse_to_fresh_baseline=$true;old_sha256=$oldHash;file_written=$false})
}
$modules=[ordered]@{}
foreach($relative in $receipt.new_modules.Keys){
 $entry=$receipt.new_modules[$relative];$path=Canonical $relative;$fact=Metadata $path;$modules[$path]=$fact
 if($fact.sha256 -cne $entry.sha256 -or $fact.bytes -ne $entry.bytes -or -not $fact.stable_during_hash){$errors.Add('NEW_HELPER_PIN:'+ $path)}
}
$native=Read-JsonData ($repo+'/game/build/three_towns_world_20261029j_system01/native_sources.json')
if($oldNative.sources.Count -ne 200 -or $native.sources.Count -ne 201){throw 'EXPECTED_OLD200_NEW201'}
$sceneURI='res://scenes/drafts/miao_terrain_20261029i/miao_town.tscn'
$preserved=0
foreach($path in $oldNative.sources.Keys){
 if($path -ceq $sceneURI){if($native.sources[$path] -cne 'cd88d0003066eb42a0dcec5d20404e4bad6313456b383584386ef3f1eda9d756'){$errors.Add('AUTHORIZED_SCENE_NATIVE_KEY_NOT_FINAL')};continue}
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
 'game/build/lanxi_boardwalk_edges_20261031a_qa01/boardwalk_ROOT_ONLY.gd'='582513060792f2cd807dd1d197d5aa89dcc030f846d97c9fc325685aaf016b2e'
 'game/build/lanxi_boardwalk_edges_20261031a_qa01/actual_inputs_READY.json'='ae743780c22e95ea8b254e34c4fcb086e512470db0a4552853d80ca2a19a0487'
 'game/build/lanxi_boardwalk_edges_20261031a_qa01/actual/83612/result.json'='cc70017213ebdb5dd96aaffef52208ff8dbc5e8c22d838bca97fad951e6f9e30'
}
$qaFacts=[ordered]@{}
foreach($relative in $qaPins.Keys){$path=Canonical $relative;$fact=Metadata $path;$qaFacts[$path]=$fact;if($fact.sha256 -cne $qaPins[$relative]){$errors.Add('FROZEN_QA_EVIDENCE_PIN:'+ $path)}}
$processAfter=@(Engines)
if($processAfter.Count -ne 1 -or $processAfter[0].pid -ne 51856){$errors.Add('ONLY_EDITOR51856_REQUIRED_AFTER')}
if(($processBefore|ConvertTo-Json -Compress -Depth 5) -cne ($processAfter|ConvertTo-Json -Compress -Depth 5)){$errors.Add('EDITOR_IDENTITY_CHANGED')}
$result=[ordered]@{
 passed=($errors.Count -eq 0);status='FINAL_METADATA_ONLY_NO_ENGINE_RETEST';baseline_sha256='83b5b8717598f04be5ed853b1586210a2601c6a325bc935b648ed2a08555647e'
 source_count=$sourceCount;save_count=$saveCount;facts=$facts;save_second_facts=$saveSecond;expected_absent_save_paths=$baseline.expected_absent_save_paths
 authorized_source_changes=$authorized;unexpected_source_changes=$sourceDiff;save_changes=$saveDiff;exact_source_inverse=$inverse
 new_modules=$modules;native_dependency_facts=$dependencies;native_old200_keys_only_authorized_scene_hash_changed=$true;native_other199_keys_preserved=$preserved;native_new_count=201
 frozen_qa_evidence=$qaFacts;historical_two_user_save_changes_from_fresh_baseline_retained=$baseline.historical_since_30n
 errors=$errors.ToArray();godot_processes_before=$processBefore;godot_processes_after=$processAfter
 engine_runs=0;process_control=0;save_deserializations=0;save_writes=0;production_writes=0
 successful42checks18inputs_one_image_inherited_no_retest=$true;original7_exit_errors_and_ObjectDB_warning_retained_not_clean=$true
}
$utf8=[Text.UTF8Encoding]::new($false);$file=[IO.File]::Open($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
try{$payload=$utf8.GetBytes(($result|ConvertTo-Json -Depth 15)+[Environment]::NewLine);$file.Write($payload,0,$payload.Length)}finally{$file.Dispose()}
[ordered]@{passed=$result.passed;source_count=$sourceCount;save_count=$saveCount;authorized_source_changes=$authorized.Count;unexpected_source_changes=$sourceDiff.Count;save_changes=$saveDiff.Count;errors=$errors.ToArray();report=$output;sha256=(Hash-Only $output)}|ConvertTo-Json -Depth 5
if($errors.Count -gt 0){exit 1}
