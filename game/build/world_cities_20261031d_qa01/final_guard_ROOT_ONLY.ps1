param([Parameter(Mandatory=$true)][string]$ExpectedManifest,[Parameter(Mandatory=$true)][ValidatePattern('^[a-f0-9]{64}$')][string]$ExpectedManifestSHA,[string]$OutputName='final_guard_ACTUAL.json')
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'USE_BUNDLED_PWSH7'}
$repo='F:/Code/RPG_GAME';$taskDir=$repo+'/game/build/world_cities_20261031d_qa01'
if([IO.Path]::GetFileName($OutputName) -cne $OutputName -or $OutputName -notmatch '^[A-Za-z0-9_-]+\.json$'){throw 'OUTPUT_BASENAME_ONLY'}
$output=$taskDir+'/'+$OutputName
if(Test-Path -LiteralPath $output){throw 'EXISTING_REPORT_RETAINED'}
$errors=[Collections.Generic.List[string]]::new()
function Hash-Only([string]$path){$stream=[IO.File]::OpenRead($path);try{return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($stream)).ToLowerInvariant()}finally{$stream.Dispose()}}
function Json-Data([string]$path){if($path.Replace('\','/').Contains('/app_userdata/')){throw 'NO_SAVE_DESERIALIZATION'};return [IO.File]::ReadAllText($path,[Text.Encoding]::UTF8)|ConvertFrom-Json -AsHashtable}
function Canonical([string]$path){if($path.StartsWith('res://')){$path=$repo+'/game/'+$path.Substring(6)}elseif(-not [IO.Path]::IsPathRooted($path)){$path=$repo+'/'+$path};return [IO.Path]::GetFullPath($path).Replace('\','/')}
function Metadata([string]$path){
 $i=Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
 if($null -eq $i){return [ordered]@{exists=$false;bytes=$null;utc_ticks=$null;sha256=$null;stable_during_hash=$true}}
 if($i.PSIsContainer){throw 'FILE_EXPECTED'}
 $length=[long]$i.Length;$ticks=[string]$i.LastWriteTimeUtc.Ticks
 try{$sha=Hash-Only $path;$j=Get-Item -LiteralPath $path;return [ordered]@{exists=$true;bytes=$length;utc_ticks=$ticks;sha256=$sha;stable_during_hash=($length -eq $j.Length -and $ticks -ceq [string]$j.LastWriteTimeUtc.Ticks)}}
 catch{$script:errors.Add('READ_FAILED:'+ $path);return [ordered]@{exists=$true;bytes=$length;utc_ticks=$ticks;sha256=$null;stable_during_hash=$false}}
}
function Same($a,$b){foreach($key in @('exists','bytes','utc_ticks','sha256')){if($a[$key] -cne $b[$key]){return $false}};return $true}
function Engines {return @(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'"|ForEach-Object{[ordered]@{pid=[int]$_.ProcessId;parent_pid=[int]$_.ParentProcessId;name=$_.Name;exe=$_.ExecutablePath;command_line=$_.CommandLine;creation_utc=$_.CreationDate.ToUniversalTime().ToString('o')}})}
function Pin([string]$path,[string]$sha){if((Hash-Only $path) -cne $sha){throw ('EXPLICIT_PIN_CHANGED:'+ $path)}}
$expectedPath=Canonical $ExpectedManifest
if(-not $expectedPath.StartsWith($taskDir+'/',[StringComparison]::OrdinalIgnoreCase)){throw 'EXPLICIT_MANIFEST_THIS_QA_DIRECTORY_ONLY'}
Pin $expectedPath $ExpectedManifestSHA
$expected=Json-Data $expectedPath
$baselinePath=$taskDir+'/baseline_NOW_ACTUAL.json';Pin $baselinePath $expected.baseline_sha256
$baseline=Json-Data $baselinePath
if(-not $baseline.passed -or $baseline.source_count -ne $expected.baseline_source_count -or $baseline.save_count -ne 171 -or $baseline.expected_absent_save_paths.Count -ne 9){throw 'EXPLICIT_FRESH_BASELINE_REQUIRED'}
if($baseline.previous21_old_targets_fresh_coverage.Count -ne 21 -or @($baseline.previous21_old_targets_fresh_coverage|Where-Object{-not $_.included_now}).Count -ne 0){throw 'PRIOR21_TARGETS_MUST_ALL_HAVE_FRESH_COVERAGE'}
$allowed=@{}
foreach($path in $expected.allowed_old_targets.Keys){
 $p=Canonical $path
 if(-not $baseline.facts.ContainsKey($p) -or $p.Contains('/app_userdata/')){throw ('DO_NOT_INVENT_FRESH_AUTHORIZED_COVERAGE:'+ $path)}
 $entry=$expected.allowed_old_targets[$path]
 if($entry.before_sha256 -cne $baseline.facts[$p].sha256 -or $entry.before_bytes -ne $baseline.facts[$p].bytes){throw ('AUTHORIZED_BEFORE_NOT_FRESH:'+ $path)}
 $allowed[$p]=$entry
}
$processBefore=@(Engines)
if($processBefore.Count -ne 1 -or $processBefore[0].pid -ne 51856){$errors.Add('ONLY_EDITOR51856_REQUIRED_BEFORE')}
$facts=[ordered]@{};$saveSecond=[ordered]@{};$unexpected=@();$saveDiff=@();$authorized=@();$sources=0;$saves=0
foreach($path in $baseline.facts.Keys){
 $now=Metadata $path;$facts[$path]=$now;$isSave=$path.Contains('/app_userdata/')
 if($isSave){$saves++}else{$sources++}
 if(-not $now.stable_during_hash){$errors.Add('UNSTABLE_HASH:'+ $path)}
 if($allowed.ContainsKey($path)){
  $entry=$allowed[$path]
  if($now.sha256 -cne $entry.after_sha256 -or $now.bytes -ne $entry.after_bytes){$errors.Add('AUTHORIZED_FINAL_NOT_EXACT:'+ $path)}
  $authorized+=@([ordered]@{path=$path;fresh_before=$baseline.facts[$path];after=$now;expected=$entry;changed=(-not (Same $baseline.facts[$path] $now))})
 }elseif(-not (Same $baseline.facts[$path] $now)){
  $row=[ordered]@{path=$path;before=$baseline.facts[$path];after=$now;rollback=$false}
  if($isSave){$saveDiff+=@($row);$errors.Add('SAVE_METADATA_DIFF:'+ $path)}else{$unexpected+=@($row);$errors.Add('UNEXPECTED_SOURCE_DIFF:'+ $path)}
 }
}
foreach($path in $baseline.facts.Keys){
 if(-not $path.Contains('/app_userdata/')){continue}
 $now=Metadata $path;$saveSecond[$path]=$now
 if(-not $now.stable_during_hash -or -not (Same $facts[$path] $now) -or -not (Same $baseline.facts[$path] $now)){$errors.Add('SAVE_SECOND_NOT_EXACT:'+ $path)}
}
foreach($path in $baseline.expected_absent_save_paths){if($facts[$path].exists -or $saveSecond[$path].exists){$errors.Add('EXPECTED_ABSENCE_CHANGED:'+ $path)}}
if($sources -ne $baseline.source_count -or $saves -ne 171 -or $authorized.Count -ne $expected.allowed_old_targets.Count){$errors.Add('EXACT_SOURCE_SAVE_AUTHORIZATION_COUNTS')}
$newPins=[ordered]@{}
foreach($path in $expected.new_runtime_pins.Keys){$p=Canonical $path;$entry=$expected.new_runtime_pins[$path];$now=Metadata $p;$newPins[$p]=$now;if($now.sha256 -cne $entry.sha256 -or $now.bytes -ne $entry.bytes -or -not $now.stable_during_hash){$errors.Add('NEW_RUNTIME_PIN:'+ $path)}}
$evidence=[ordered]@{}
foreach($path in $expected.evidence_pins.Keys){$p=Canonical $path;$entry=$expected.evidence_pins[$path];$now=Metadata $p;$evidence[$p]=$now;if($now.sha256 -cne $entry.sha256 -or $now.bytes -ne $entry.bytes){$errors.Add('EVIDENCE_PIN:'+ $path)}}
$nativePath=Canonical $expected.native_manifest;$native=Json-Data $nativePath
if($native.sources.Count -ne $expected.native_count){$errors.Add('NATIVE_COUNT_NOT_EXPLICIT_EXPECTED')}
$nativeFacts=[ordered]@{}
foreach($path in $native.sources.Keys){$p=Canonical $path;$now=if($facts.Contains($p)){$facts[$p]}elseif($newPins.Contains($p)){$newPins[$p]}else{Metadata $p};$nativeFacts[$path]=$now;if($now.sha256 -cne $native.sources[$path] -or -not $now.stable_during_hash){$errors.Add('NATIVE_DEPENDENCY_PIN:'+ $path)}}
$processAfter=@(Engines)
if($processAfter.Count -ne 1 -or $processAfter[0].pid -ne 51856){$errors.Add('ONLY_EDITOR51856_REQUIRED_AFTER')}
if(($processBefore|ConvertTo-Json -Depth 5 -Compress) -cne ($processAfter|ConvertTo-Json -Depth 5 -Compress)){$errors.Add('EDITOR_IDENTITY_CHANGED')}
$result=[ordered]@{passed=($errors.Count -eq 0);status='FINAL31D_METADATA_ONLY_NO_ENGINE_NO_REBASE';expected_manifest=$expectedPath;expected_manifest_sha256=$ExpectedManifestSHA;baseline_sha256=$expected.baseline_sha256;source_count=$sources;save_count=$saves;facts=$facts;save_second_facts=$saveSecond;expected_absent_save_paths=$baseline.expected_absent_save_paths;authorized_fresh_source_changes=$authorized;unexpected_source_changes=$unexpected;save_changes=$saveDiff;new_runtime_pins=$newPins;evidence_facts=$evidence;native_dependency_facts=$nativeFacts;native_count=$native.sources.Count;godot_processes_before=$processBefore;godot_processes_after=$processAfter;errors=$errors.ToArray();historical_since31c=$baseline.historical_since31c;all_authorized_old_targets_fresh_this_round=$true;engine_runs=0;process_control=0;save_deserializations=0;save_writes=0;production_writes=0;previous_success_matrices_not_repeated=$true;stderr_clean_not_claimed=$true}
$payload=[Text.UTF8Encoding]::new($false).GetBytes(($result|ConvertTo-Json -Depth 18)+[Environment]::NewLine)
$file=[IO.File]::Open($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
try{$file.Write($payload,0,$payload.Length)}finally{$file.Dispose()}
[ordered]@{passed=$result.passed;source_count=$sources;save_count=$saves;authorized_fresh=$authorized.Count;unexpected=$unexpected.Count;save_changes=$saveDiff.Count;errors=$errors.ToArray();report=$output;sha256=(Hash-Only $output)}|ConvertTo-Json -Depth 4
if($errors.Count -gt 0){exit 1}
