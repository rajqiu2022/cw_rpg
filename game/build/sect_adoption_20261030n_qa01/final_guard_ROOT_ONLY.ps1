param([string]$OutputName='final_guard_ACTUAL.json')
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'USE_BUNDLED_PWSH7'}
$repo='F:/Code/RPG_GAME'
$taskDir=$repo+'/game/build/sect_adoption_20261030n_qa01'
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
Pin $baselinePath 'ad04a408ed5a1a981704728ef5d55614138048b9eb523de0630194dc002228a8'
$firstReceiptPath=$repo+'/game/build/sect_adoption_20261030n_system01/closure_receipt_READY.json'
$fallbackPath=$repo+'/game/build/sect_adoption_20261030n_system01/fallback02_receipt_READY.json'
Pin $firstReceiptPath '67d0eba75b76ac2f2350c87431f2da63cf700aae6901034663785ff0711a10e4'
Pin $fallbackPath 'c2493d965a92d7a2dd47ab674666fdff9129842c64c36a934e34212f2c66e6f9'
$baseline=Read-JsonData $baselinePath;$closure=Read-JsonData $firstReceiptPath;$fallback=Read-JsonData $fallbackPath
if(-not $baseline.passed -or $baseline.source_count -ne 970 -or $baseline.save_count -ne 171 -or $baseline.expected_absent_save_paths.Count -ne 9){throw 'EXACT_BASELINE_REQUIRED'}
$allowed=@{}
foreach($target in $closure.targets){$path=Canonical $target.target;$allowed[$path]=@{old_sha256=$target.old_sha256;sha256=$target.new_sha256;bytes=$target.bytes}}
foreach($target in $fallback.targets){$path=Canonical $target.target;if($allowed.ContainsKey($path)){$allowed[$path].sha256=$target.new_sha256;$allowed[$path].bytes=$target.bytes}}
if($allowed.Count -ne 2){throw 'ONLY_TWO_ORIGINAL_SOURCE_TARGETS'}
$processBefore=@(Engines)
if($processBefore.Count -ne 1 -or $processBefore[0].pid -ne 51856){$errors.Add('ONLY_EDITOR51856_REQUIRED_BEFORE')}
$facts=[ordered]@{};$saveSecond=[ordered]@{};$sourceDiff=@();$saveDiff=@();$authorized=@();$external=@();$saveCount=0;$sourceCount=0
foreach($path in $baseline.facts.Keys){
 $now=Metadata $path;$facts[$path]=$now
 $isSave=$path.Contains('/app_userdata/')
 if($isSave){$saveCount++}else{$sourceCount++}
 if(-not $now.stable_during_hash){$errors.Add('UNSTABLE_HASH:'+ $path)}
 if(Same $baseline.facts[$path] $now){continue}
 $row=[ordered]@{path=$path;before=$baseline.facts[$path];after=$now;rollback=$false}
 if($isSave){$saveDiff+=@($row);$errors.Add('SAVE_METADATA_DIFF:'+ $path)}
 elseif($allowed.ContainsKey($path)){
  $expected=$allowed[$path]
  if($baseline.facts[$path].sha256 -cne $expected.old_sha256 -or $now.sha256 -cne $expected.sha256 -or $now.bytes -ne $expected.bytes){$errors.Add('AUTHORIZED_TARGET_NOT_EXACT_FINAL:'+ $path)}
  $authorized+=@($row)
 }else{$sourceDiff+=@($row);$errors.Add('UNEXPECTED_SOURCE_DIFF:'+ $path)}
}
foreach($path in $baseline.facts.Keys){if(-not $path.Contains('/app_userdata/')){continue};$now=Metadata $path;$saveSecond[$path]=$now;if(-not $now.stable_during_hash -or -not (Same $facts[$path] $now) -or -not (Same $baseline.facts[$path] $now)){$errors.Add('SAVE_FRESH_SECOND_NOT_EXACT:'+ $path)}}
foreach($path in $baseline.expected_absent_save_paths){if($facts[$path].exists -or $saveSecond[$path].exists){$errors.Add('EXPECTED_ABSENCE_CHANGED:'+ $path)}}
if($sourceCount -ne 970 -or $saveCount -ne 171 -or $authorized.Count -ne 2){$errors.Add('EXPECTED970_171_AND_TWO_AUTHORIZED_DIFFS')}
# Receipt inverse is in-memory only: FINAL -> fallback02 parent -> original baseline.
function Inverse([string]$text,$target){
 if((Hash-Bytes ([Text.UTF8Encoding]::new($false).GetBytes($text))) -cne $target.new_sha256){throw ('INVERSE_NEW_SHA:'+ $target.target)}
 for($i=$target.replacements.Count-1;$i -ge 0;$i--){$h=$target.replacements[$i];if(([regex]::Matches($text,[regex]::Escape([string]$h.new))).Count -ne 1){throw ('INVERSE_HUNK_NOT_UNIQUE:'+ $target.target)};$text=$text.Replace([string]$h.new,[string]$h.old)}
 if((Hash-Bytes ([Text.UTF8Encoding]::new($false).GetBytes($text))) -cne $target.old_sha256){throw ('INVERSE_OLD_SHA:'+ $target.target)}
 return $text
}
$inverse=@();$oldNative=$null
foreach($target in $closure.targets){
 $path=Canonical $target.target;$text=[IO.File]::ReadAllText($path,[Text.Encoding]::UTF8)
 foreach($patch in $fallback.targets){if($patch.target -ceq $target.target){$text=Inverse $text $patch}}
 $text=Inverse $text $target
 if((Hash-Bytes ([Text.UTF8Encoding]::new($false).GetBytes($text))) -cne $baseline.facts[$path].sha256){throw 'INVERSE_NOT_BASELINE'}
 if($target.target.EndsWith('native_sources.json')){$oldNative=$text|ConvertFrom-Json -AsHashtable}
 $inverse+=@([ordered]@{path=$path;exact_fallback_then_closure_inverse_to_baseline=$true;baseline_sha256=$baseline.facts[$path].sha256;file_written=$false})
}
$modules=[ordered]@{}
foreach($relative in $closure.new_modules.Keys){$entry=$closure.new_modules[$relative];$sha=$entry.sha256;$bytes=$entry.bytes;foreach($patch in $fallback.targets){if($patch.target -ceq $relative){$sha=$patch.new_sha256;$bytes=$patch.bytes}};$path=Canonical $relative;$fact=Metadata $path;$modules[$path]=$fact;if($fact.sha256 -cne $sha -or $fact.bytes -ne $bytes -or -not $fact.stable_during_hash){$errors.Add('NEW_RUNTIME_MODULE_PIN:'+ $path)}}
$nativePath=$repo+'/game/build/three_towns_world_20261029j_system01/native_sources.json';$currentNative=Read-JsonData $nativePath
$dependencies=[ordered]@{};$oldPreserved=$true
if($oldNative.sources.Count -ne 166 -or $currentNative.sources.Count -ne 200 -or $closure.native_added.Count -ne 34 -or $modules.Count -ne 5){throw 'EXPECTED166_200_34_5'}
foreach($path in $oldNative.sources.Keys){if($currentNative.sources[$path] -cne $oldNative.sources[$path]){$oldPreserved=$false;$errors.Add('OLD166_NATIVE_KEY_OR_VALUE_CHANGED:'+ $path)}}
foreach($path in $currentNative.sources.Keys){$absolute=Canonical $path;$fact=if($facts.Contains($absolute)){$facts[$absolute]}elseif($modules.Contains($absolute)){$modules[$absolute]}else{Metadata $absolute};$dependencies[$path]=$fact;if($fact.sha256 -cne $currentNative.sources[$path] -or -not $fact.stable_during_hash){$errors.Add('NATIVE_DEPENDENCY_PIN:'+ $path)}}
$processAfter=@(Engines)
if($processAfter.Count -ne 1 -or $processAfter[0].pid -ne 51856){$errors.Add('ONLY_EDITOR51856_REQUIRED_AFTER')}
if(($processBefore|ConvertTo-Json -Compress -Depth 5) -cne ($processAfter|ConvertTo-Json -Compress -Depth 5)){$errors.Add('EDITOR_IDENTITY_CHANGED')}
$result=[ordered]@{passed=($errors.Count -eq 0);status='FINAL_METADATA_ONLY_NO_RETEST';baseline_sha256='ad04a408ed5a1a981704728ef5d55614138048b9eb523de0630194dc002228a8';source_count=$sourceCount;save_count=$saveCount;facts=$facts;save_second_facts=$saveSecond;expected_absent_save_paths=$baseline.expected_absent_save_paths;authorized_source_changes=$authorized;unexpected_source_changes=$sourceDiff;save_changes=$saveDiff;parallel_changes_recorded_not_rolled_back=$external;exact_receipt_inverse=$inverse;new_modules=$modules;native_dependency_facts=$dependencies;native_old166_preserved=$oldPreserved;native_added_count=34;native_current_count=200;original14_registry_preserved_by_exact_inverse=$true;errors=$errors.ToArray();godot_processes_before=$processBefore;godot_processes_after=$processAfter;engine_runs=0;process_control=0;save_deserializations=0;save_writes=0;production_writes=0;successful54checks20inputs_two_images_inherited_not_repeated=$true;preengine_launch01_failure_retained=$true}
$utf8=[Text.UTF8Encoding]::new($false);$file=[IO.File]::Open($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
try{$payload=$utf8.GetBytes(($result|ConvertTo-Json -Depth 15)+[Environment]::NewLine);$file.Write($payload,0,$payload.Length)}finally{$file.Dispose()}
[ordered]@{passed=$result.passed;source_count=$sourceCount;save_count=$saveCount;authorized_source_changes=$authorized.Count;unexpected_source_changes=$sourceDiff.Count;save_changes=$saveDiff.Count;errors=$errors.ToArray();report=$output;sha256=(Hash-Only $output)}|ConvertTo-Json -Depth 5
if($errors.Count -gt 0){exit 1}
