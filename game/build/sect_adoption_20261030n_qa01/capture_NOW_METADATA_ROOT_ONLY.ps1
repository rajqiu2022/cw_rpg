param([string]$OutputName='baseline_NOW_ACTUAL.json')
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'USE_BUNDLED_PWSH7_NOT_LEGACY_POWERSHELL'}
$repo='F:/Code/RPG_GAME'
$taskDir=$repo+'/game/build/sect_adoption_20261030n_qa01'
if([IO.Path]::GetFileName($OutputName) -cne $OutputName -or $OutputName -notmatch '^[A-Za-z0-9_-]+\.json$'){throw 'OUTPUT_BASENAME_ONLY'}
$output=$taskDir+'/'+$OutputName
if(Test-Path -LiteralPath $output){throw 'EXISTING_BASELINE_RETAINED_NO_REBASE_OR_OVERWRITE'}
$errors=[Collections.Generic.List[string]]::new()
function Json-Data([string]$path){
 if($path.Replace('\','/').Contains('/app_userdata/')){throw 'SAVE_CONTENT_DESERIALIZATION_FORBIDDEN'}
 return Get-Content -LiteralPath $path -Raw -Encoding utf8 | ConvertFrom-Json -AsHashtable
}
function Hash-Only([string]$path){
 $stream=[IO.File]::OpenRead($path);$algorithm=[Security.Cryptography.SHA256]::Create()
 try{return ([BitConverter]::ToString($algorithm.ComputeHash($stream))).Replace('-','').ToLowerInvariant()}
 finally{$algorithm.Dispose();$stream.Dispose()}
}
function Metadata([string]$path){
 $before=Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
 if($null -eq $before){return [ordered]@{exists=$false;bytes=$null;utc_ticks=$null;sha256=$null;stable_during_hash=$true}}
 if($before.PSIsContainer){throw ('FILE_EXPECTED:'+ $path)}
 $length=[long]$before.Length;$ticks=[string]$before.LastWriteTimeUtc.Ticks
 try{
  $hash=Hash-Only $path
  $after=Get-Item -LiteralPath $path -ErrorAction Stop
  return [ordered]@{exists=$true;bytes=$length;utc_ticks=$ticks;sha256=$hash;stable_during_hash=($length -eq $after.Length -and $ticks -ceq [string]$after.LastWriteTimeUtc.Ticks)}
 }catch{
  $script:errors.Add('FACT_READ_FAILED:'+ $path +':'+$_.Exception.Message)
  return [ordered]@{exists=$true;bytes=$length;utc_ticks=$ticks;sha256=$null;stable_during_hash=$false;read_error=$_.Exception.Message}
 }
}
function Same-Metadata($first,$second){
 foreach($key in @('exists','bytes','utc_ticks','sha256')){if($first[$key] -cne $second[$key]){return $false}}
 return $true
}
function Canonical([string]$path){
 if($path.StartsWith('res://')){$path=$repo+'/game/'+$path.Substring(6)}
 return [IO.Path]::GetFullPath($path).Replace('\','/')
}
function Engine-Inventory {
 return @(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'" | ForEach-Object {
  [ordered]@{pid=[int]$_.ProcessId;parent_pid=[int]$_.ParentProcessId;name=$_.Name;exe=$_.ExecutablePath;command_line=$_.CommandLine;creation_utc=$_.CreationDate.ToUniversalTime().ToString('o')}
 })
}
function Require-Only-Editor($rows,[int]$pidExpected,[string]$label){
 if($rows.Count -ne 1 -or [int]$rows[0].pid -ne $pidExpected){$script:errors.Add('ONLY_EDITOR_REQUIRED_'+$label)}
}
$fixturePath=$taskDir+'/capture_inputs_READY.json'
$fixture=Json-Data $fixturePath
foreach($relative in $fixture.source_pins.Keys){
 $path=$repo+'/'+$relative
 if((Hash-Only $path) -cne $fixture.source_pins[$relative]){throw ('PATH_SEED_OR_REFERENCE_PIN_CHANGED:'+ $relative)}
}
$previous=Json-Data ($repo+'/'+$fixture.previous_report)
$native=Json-Data ($repo+'/'+$fixture.native_manifest)
if($previous.source_count -ne 600 -or $previous.save_count -ne 171 -or $native.sources.Count -ne 166 -or $fixture.original_registry_IDs.Count -ne 14){throw 'EXACT600_SEED_171_SAVE_166_NATIVE_14_ORIGINAL_ID_SCOPE'}
$all=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$source=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$saves=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$expectedAbsent=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($path in $previous.source_facts.Keys){
 [void]$all.Add((Canonical $path))
 if($path.Contains('/app_userdata/') -and $previous.source_facts[$path].exists -eq $false){[void]$expectedAbsent.Add((Canonical $path))}
}
foreach($path in $previous.scoped_new_resources.Keys){[void]$all.Add((Canonical $path))}
foreach($path in $native.sources.Keys){[void]$all.Add((Canonical $path))}
foreach($path in $fixture.additional_source_paths){[void]$all.Add((Canonical $path))}
foreach($relative in $fixture.source_pins.Keys){[void]$all.Add((Canonical ($repo+'/'+$relative)))}
foreach($path in @($fixturePath,$PSCommandPath)){[void]$all.Add((Canonical $path))}
foreach($path in $all){
 if($path.StartsWith('C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/',[StringComparison]::OrdinalIgnoreCase)){[void]$saves.Add($path)}
 elseif($path.StartsWith($repo+'/',[StringComparison]::OrdinalIgnoreCase)){[void]$source.Add($path)}
 else{throw ('UNEXPECTED_EXTERNAL_PATH:'+ $path)}
}
if($saves.Count -ne 171 -or $expectedAbsent.Count -ne 9){throw 'EXACT171_SAVE_SEEDS_WITH9_PROVEN_EXPECTED_ABSENCES'}
$began=[DateTime]::UtcNow.ToString('o')
$processFirst=@(Engine-Inventory);Require-Only-Editor $processFirst ([int]$fixture.allowed_editor_pid) 'BEFORE'
$first=[ordered]@{};$second=[ordered]@{}
foreach($path in ($all | Sort-Object)){$first[$path]=Metadata $path}
# Single fresh second read, no retries or auto-rebase if anything changes.
foreach($path in ($all | Sort-Object)){$second[$path]=Metadata $path}
$sourceDrift=@();$saveDrift=@();$concurrent=@()
foreach($path in $all){
 if($expectedAbsent.Contains($path)){
  if($first[$path].exists -or $second[$path].exists){$errors.Add('PREVIOUSLY_ABSENT_SAVE_NOW_EXISTS_RECORD_ONLY_NO_DELETE:'+ $path)}
 }elseif(-not $first[$path].exists -or -not $second[$path].exists){$errors.Add('REQUIRED_SOURCE_OR_SAVE_FILE_MISSING:'+ $path)}
 $changed=(-not (Same-Metadata $first[$path] $second[$path])) -or -not $first[$path].stable_during_hash -or -not $second[$path].stable_during_hash
 if(-not $changed){continue}
 $row=[ordered]@{path=$path;first=$first[$path];second=$second[$path];no_rollback=$true;no_rebase=$true}
 if($saves.Contains($path)){$saveDrift+=@($row);$errors.Add('SAVE_NOT_STABLE_DOUBLE_READ:'+ $path)}
 elseif($fixture.concurrent_record_only_paths -contains $path){$concurrent+=@($row)}
 else{$sourceDrift+=@($row);$errors.Add('SOURCE_CHANGED_DURING_CAPTURE:'+ $path)}
}
$historical=@();$concurrentObservations=@()
foreach($oldPath in $previous.source_facts.Keys){
 $path=Canonical $oldPath
 if(-not (Same-Metadata $previous.source_facts[$oldPath] $first[$path])){
  $historical+=@([ordered]@{path=$path;kind=if($saves.Contains($path)){'SAVE_METADATA_HISTORY_ONLY'}else{'SOURCE_HISTORY_ONLY'};reference_30m=$previous.source_facts[$oldPath];now_first=$first[$path];historical_not_current_baseline_failure=$true;restore_or_rollback=$false})
 }
}
foreach($path in $fixture.concurrent_record_only_paths){
 $concurrentObservations+=@([ordered]@{path=$path;reference_30m=$previous.source_facts[$path];now_first=$first[$path];now_second=$second[$path];record_only_not_rollback=$true;future_final_header_requires_explicit_author_receipt=$true})
}
$processLast=@(Engine-Inventory);Require-Only-Editor $processLast ([int]$fixture.allowed_editor_pid) 'AFTER'
if($processFirst.Count -eq 1 -and $processLast.Count -eq 1){
 if(($processFirst[0] | ConvertTo-Json -Compress) -cne ($processLast[0] | ConvertTo-Json -Compress)){$errors.Add('EDITOR_IDENTITY_CHANGED_DURING_CAPTURE')}
}
$result=[ordered]@{
 status=if($errors.Count -gt 0){'CAPTURE_NOW_RECORDED_ERRORS_DO_NOT_REBASE'}elseif($concurrent.Count -gt 0){'CAPTURE_NOW_KNOWN_CONCURRENT_SOURCE_DRIFT_RETAINED'}else{'CAPTURE_NOW_STABLE_METADATA_ONLY'}
 passed=($errors.Count -eq 0);capture_started_utc=$began;capture_finished_utc=[DateTime]::UtcNow.ToString('o')
 source_count=$source.Count;save_count=$saves.Count;fact_count=$all.Count;inherited_path_seed_source_count=600;native_source_paths=166;original_registry_IDs=$fixture.original_registry_IDs;expected_absent_save_paths=@($expectedAbsent | Sort-Object)
 facts=$first;second_facts=$second;source_drift_during_capture=$sourceDrift;save_drift_during_capture=$saveDrift
 known_concurrent_source_drift=$concurrent;concurrent_path_observations=$concurrentObservations
 historical_since_30m_reference=$historical;historical_values_not_reused_as_now_baseline=$true
 errors=$errors.ToArray();godot_processes_before=$processFirst;godot_processes_after=$processLast
 seed_source_pins=$fixture.source_pins
 previous_five_bridges_no_engine_retest=$true;new_scope_only_two_original_World_sect_IDs=$true;source_dependency_closure_count=$fixture.additional_source_paths.Count
 engine_runs=0;process_control=0;save_deserializations=0;save_writes=0;production_writes=0
}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($result | ConvertTo-Json -Depth 15)+[Environment]::NewLine)
$file=[IO.File]::Open($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
try{$file.Write($bytes,0,$bytes.Length)}finally{$file.Dispose()}
[ordered]@{status=$result.status;passed=$result.passed;source_count=$source.Count;save_count=$saves.Count;historical_differences=$historical.Count;known_concurrent_changes=$concurrent.Count;errors=$errors.ToArray();report=$output;report_sha256=(Hash-Only $output)} | ConvertTo-Json -Depth 4
if($errors.Count -gt 0){exit 1}
