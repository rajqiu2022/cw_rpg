param([Parameter(Mandatory=$true)][string]$Scope,[Parameter(Mandatory=$true)][ValidatePattern('^[a-f0-9]{64}$')][string]$ScopeSHA,[string]$OutputName='baseline_NOW_ACTUAL.json')
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'USE_BUNDLED_PWSH7'}
$repo='F:/Code/RPG_GAME'
$taskDir=$repo+'/game/build/world_cities_20261031d_qa01'
if([IO.Path]::GetFileName($OutputName) -cne $OutputName -or $OutputName -notmatch '^[A-Za-z0-9_-]+\.json$'){throw 'OUTPUT_BASENAME_ONLY'}
$output=$taskDir+'/'+$OutputName
if(Test-Path -LiteralPath $output){throw 'EXISTING_BASELINE_RETAINED_NO_REBASE'}
$errors=[Collections.Generic.List[string]]::new()
function Hash-Only([string]$path){$stream=[IO.File]::OpenRead($path);try{return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($stream)).ToLowerInvariant()}finally{$stream.Dispose()}}
function Json-Data([string]$path){if($path.Replace('\','/').Contains('/app_userdata/')){throw 'NO_SAVE_DESERIALIZATION'};return [IO.File]::ReadAllText($path,[Text.Encoding]::UTF8)|ConvertFrom-Json -AsHashtable}
function Canonical([string]$path){if($path.StartsWith('res://')){$path=$repo+'/game/'+$path.Substring(6)}elseif(-not [IO.Path]::IsPathRooted($path)){$path=$repo+'/'+$path};return [IO.Path]::GetFullPath($path).Replace('\','/')}
function Metadata([string]$path){
 $i=Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
 if($null -eq $i){return [ordered]@{exists=$false;bytes=$null;utc_ticks=$null;sha256=$null;stable_during_hash=$true}}
 if($i.PSIsContainer){throw ('FILE_EXPECTED:'+ $path)}
 $length=[long]$i.Length;$ticks=[string]$i.LastWriteTimeUtc.Ticks
 try{$sha=Hash-Only $path;$j=Get-Item -LiteralPath $path;return [ordered]@{exists=$true;bytes=$length;utc_ticks=$ticks;sha256=$sha;stable_during_hash=($length -eq $j.Length -and $ticks -ceq [string]$j.LastWriteTimeUtc.Ticks)}}
 catch{$script:errors.Add('READ_FAILED:'+ $path);return [ordered]@{exists=$true;bytes=$length;utc_ticks=$ticks;sha256=$null;stable_during_hash=$false}}
}
function Same($a,$b){foreach($k in @('exists','bytes','utc_ticks','sha256')){if($a[$k] -cne $b[$k]){return $false}};return $true}
function Engines {return @(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'"|ForEach-Object{[ordered]@{pid=[int]$_.ProcessId;parent_pid=[int]$_.ParentProcessId;name=$_.Name;exe=$_.ExecutablePath;command_line=$_.CommandLine;creation_utc=$_.CreationDate.ToUniversalTime().ToString('o')}})}
function Pin([string]$path,[string]$sha){if((Hash-Only $path) -cne $sha){throw ('EXPLICIT_PIN_CHANGED:'+ $path)}}
$scopePath=Canonical $Scope
if(-not $scopePath.StartsWith($taskDir+'/',[StringComparison]::OrdinalIgnoreCase)){throw 'SCOPE_IN_THIS_QA_DIRECTORY_ONLY'}
Pin $scopePath $ScopeSHA
$scopeData=Json-Data $scopePath
$seedPath=Canonical $scopeData.seed_report;Pin $seedPath $scopeData.seed_sha256
$seed=Json-Data $seedPath
if(-not $seed.passed -or $seed.source_count -ne 1770 -or $seed.save_count -ne 171 -or $seed.expected_absent_save_paths.Count -ne 9){throw 'EXACT_31C_PATH_SEED_REQUIRED'}
$previousPath=Canonical $scopeData.previous_scope_manifest;Pin $previousPath $scopeData.previous_scope_manifest_sha256
$previous=Json-Data $previousPath
$all=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$absent=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($path in $seed.facts.Keys){[void]$all.Add((Canonical $path))}
foreach($key in @('new_runtime_pins','receipt_facts')){foreach($path in $seed[$key].Keys){[void]$all.Add((Canonical $path))}}
foreach($path in $seed.historical_authorized_targets.Keys){[void]$all.Add((Canonical $path))}
[void]$all.Add((Canonical $seed.watcher_history_only.path))
foreach($path in $scopeData.critical_current_pins.Keys){
 $p=Canonical $path;$entry=$scopeData.critical_current_pins[$path]
 Pin $p $entry.sha256
 if((Get-Item -LiteralPath $p).Length -ne $entry.bytes){throw ('PIN_BYTES:'+ $path)}
 [void]$all.Add($p)
}
# Explicitly close the prior coverage holes before sampling fresh values.
$priorTargets=@($previous.allowed_old_targets.Keys)+@($previous.historical_authorized_targets.Keys)+@($previous.unseeded_authorized_old.path)
if($priorTargets.Count -ne 21){throw 'EXACT_PRIOR20_FORMAL_PLUS_TASKS'}
foreach($path in $priorTargets){$p=Canonical $path;if(-not $all.Contains($p)){throw ('PRIOR_FORMAL_TARGET_MISSING:'+ $path)}}
foreach($path in $scopeData.previous_ten_unseeded_now_explicit){if(-not $all.Contains((Canonical $path))){throw 'PRIOR_COVERAGE_HOLE_NOT_FIXED'}}
$nativePath=Canonical $scopeData.native_manifest;$native=Json-Data $nativePath
if($native.sources.Count -ne $scopeData.native_count){throw 'NATIVE_COUNT_CHANGED_BEFORE_CAPTURE'}
foreach($path in $native.sources.Keys){[void]$all.Add((Canonical $path))}
$regionPath=Canonical $scopeData.region_manifest;$region=Json-Data $regionPath
if($region.runtime_modules.Count -ne $scopeData.region_runtime_count){throw 'REGION_COUNT_CHANGED_BEFORE_CAPTURE'}
foreach($path in $region.runtime_modules.Keys){[void]$all.Add((Canonical $path))}
foreach($entry in $region.compiled_bindings.Values){[void]$all.Add((Canonical $entry.path))}
foreach($path in @($scopePath,$PSCommandPath,$seedPath,$previousPath)){[void]$all.Add((Canonical $path))}
foreach($path in $seed.expected_absent_save_paths){[void]$absent.Add((Canonical $path))}
$sources=0;$saves=0
foreach($path in $all){if($path.StartsWith('C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/',[StringComparison]::OrdinalIgnoreCase)){$saves++}elseif($path.StartsWith($repo+'/',[StringComparison]::OrdinalIgnoreCase)){$sources++}else{throw ('OUTSIDE_DECLARED_ROOTS:'+ $path)}}
if($saves -ne 171 -or $absent.Count -ne 9){throw 'EXACT171_AND9_ABSENT_REQUIRED'}
$processBefore=@(Engines)
if($processBefore.Count -ne 1 -or $processBefore[0].pid -ne 51856){$errors.Add('ONLY_EDITOR51856_REQUIRED_BEFORE')}
$first=[ordered]@{};$second=[ordered]@{};$historical=@();$concurrent=@();$began=[DateTime]::UtcNow.ToString('o')
foreach($path in ($all|Sort-Object)){$first[$path]=Metadata $path}
foreach($path in ($all|Sort-Object)){$second[$path]=Metadata $path}
foreach($path in $all){
 if($absent.Contains($path)){if($first[$path].exists -or $second[$path].exists){$errors.Add('EXPECTED_ABSENCE_CHANGED:'+ $path)}}elseif(-not $first[$path].exists -or -not $second[$path].exists){$errors.Add('EXPECTED_FILE_MISSING:'+ $path)}
 if(-not $first[$path].stable_during_hash -or -not $second[$path].stable_during_hash -or -not (Same $first[$path] $second[$path])){$concurrent+=@([ordered]@{path=$path;first=$first[$path];second=$second[$path];rollback=$false});$errors.Add('CAPTURE_DRIFT:'+ $path)}
 if($seed.facts.ContainsKey($path) -and -not (Same $seed.facts[$path] $first[$path])){$historical+=@([ordered]@{path=$path;previous31c=$seed.facts[$path];fresh31d=$first[$path];capture_failure=$false;rollback=$false})}
}
$processAfter=@(Engines)
if($processAfter.Count -ne 1 -or $processAfter[0].pid -ne 51856){$errors.Add('ONLY_EDITOR51856_REQUIRED_AFTER')}
if(($processBefore|ConvertTo-Json -Depth 5 -Compress) -cne ($processAfter|ConvertTo-Json -Depth 5 -Compress)){$errors.Add('EDITOR_IDENTITY_CHANGED')}
$priorCoverage=@();foreach($path in $priorTargets){$p=Canonical $path;$priorCoverage+=@([ordered]@{path=$p;included_now=$all.Contains($p);current_fresh=$first[$p];previous_capture_had_it=$seed.facts.ContainsKey($p)})}
$result=[ordered]@{passed=($errors.Count -eq 0);status='FRESH_NOW_PRE31D_ALL_FACTS_RESAMPLED';started_utc=$began;finished_utc=[DateTime]::UtcNow.ToString('o');source_count=$sources;save_count=$saves;facts=$first;second_facts=$second;expected_absent_save_paths=@($absent|Sort-Object);historical_since31c=$historical;concurrent_changes=$concurrent;previous21_old_targets_fresh_coverage=$priorCoverage;scope_path=$scopePath;scope_sha256=$ScopeSHA;seed_path=$seedPath;seed_sha256=$scopeData.seed_sha256;native_count=$native.sources.Count;region_runtime_count=$region.runtime_modules.Count;godot_processes_before=$processBefore;godot_processes_after=$processAfter;errors=$errors.ToArray();all_values_fresh_not_inherited=$true;engine_runs=0;process_control=0;save_deserializations=0;save_writes=0;production_writes=0}
$payload=[Text.UTF8Encoding]::new($false).GetBytes(($result|ConvertTo-Json -Depth 18)+[Environment]::NewLine)
$file=[IO.File]::Open($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
try{$file.Write($payload,0,$payload.Length)}finally{$file.Dispose()}
[ordered]@{passed=$result.passed;source_count=$sources;save_count=$saves;prior_targets_covered=$priorCoverage.Count;expected_absent=9;historical_differences=$historical.Count;errors=$errors.ToArray();report=$output;sha256=(Hash-Only $output)}|ConvertTo-Json -Depth 4
if($errors.Count -gt 0){exit 1}
