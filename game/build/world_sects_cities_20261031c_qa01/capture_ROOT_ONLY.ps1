param([string]$OutputName='baseline_NOW_ACTUAL.json')
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'USE_BUNDLED_PWSH7_NOT_LEGACY_POWERSHELL'}
$repo='F:/Code/RPG_GAME'
$taskDir=$repo+'/game/build/world_sects_cities_20261031c_qa01'
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

$seedPath=$repo+'/game/build/lanxi_terrace_banks_20261031b_qa01/final_guard_ACTUAL.json'
$scopePath=$taskDir+'/source_scope_READY.json'
if((Hash-Only $seedPath) -cne '38429886e3a20ed4582484d0d212d8ced65c636803c4da0a7e32c4486ee87ea9'){throw 'FIXED_PATH_SEED_PIN_CHANGED'}
$scope=Json-Data $scopePath;$seed=Json-Data $seedPath
if(-not $seed.passed -or $seed.source_count -ne 986 -or $seed.save_count -ne 171 -or $seed.expected_absent_save_paths.Count -ne 9){throw 'EXACT986_171_9_SEED_REQUIRED'}
foreach($relative in $scope.current_source_pins.Keys){if((Hash-Only ($repo+'/'+$relative)) -cne $scope.current_source_pins[$relative].sha256){throw ('PREDEPLOY_SOURCE_PIN_CHANGED:'+ $relative)}}
$nativePath=$repo+'/game/build/three_towns_world_20261029j_system01/native_sources.json'
$native=Json-Data $nativePath
if($native.sources.Count -ne 202){throw 'CURRENT202_NATIVE_REQUIRED'}
$all=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$sources=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$saves=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$absent=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($path in $seed.facts.Keys){[void]$all.Add((Canonical $path))}
foreach($field in @('new_modules','native_dependency_facts','frozen_qa_evidence')){foreach($path in $seed[$field].Keys){[void]$all.Add((Canonical $path))}}
foreach($path in $native.sources.Keys){[void]$all.Add((Canonical $path))}
$generatorPath=$repo+'/'+$scope.closure_generator
if((Hash-Only $generatorPath) -cne '4b604487f4e374c79c1312d41bba33e88526d94e8f47d35228dd7a50af0d13cf'){throw 'FINITE_CLOSURE_GENERATOR_PIN_CHANGED'}
$generatedText=& 'C:/Users/rajqiu/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' $generatorPath
if($LASTEXITCODE -ne 0){throw 'READONLY_CLOSURE_GENERATOR_FAILED'}
$generated=$generatedText|ConvertFrom-Json -AsHashtable
if($generated.missing_declared_roots.Count -gt 0){throw 'DECLARED_ROOT_MISSING'}
foreach($path in $generated.additional_source_paths){[void]$all.Add((Canonical $path))}
[void]$all.Add((Canonical $generatorPath))
foreach($relative in $scope.current_source_pins.Keys){[void]$all.Add((Canonical ($repo+'/'+$relative)))}
foreach($path in @($scopePath,$PSCommandPath)){[void]$all.Add((Canonical $path))}
foreach($path in $seed.expected_absent_save_paths){[void]$absent.Add((Canonical $path))}
foreach($path in $all){
 if($path.StartsWith('C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/',[StringComparison]::OrdinalIgnoreCase)){[void]$saves.Add($path)}
 elseif($path.StartsWith($repo+'/',[StringComparison]::OrdinalIgnoreCase)){[void]$sources.Add($path)}
 else{throw ('UNEXPECTED_PATH:'+ $path)}
}
if($saves.Count -ne 171 -or $absent.Count -ne 9){throw 'EXACT171_WITH9_ABSENT_REQUIRED'}
$processFirst=@(Engine-Inventory);Require-Only-Editor $processFirst 51856 'BEFORE'
$first=[ordered]@{};$second=[ordered]@{};$began=[DateTime]::UtcNow.ToString('o')
foreach($path in ($all|Sort-Object)){$first[$path]=Metadata $path}
foreach($path in ($all|Sort-Object)){$second[$path]=Metadata $path}
$drift=@();$historical=@()
foreach($path in $all){
 if($absent.Contains($path)){
  if($first[$path].exists -or $second[$path].exists){$errors.Add('EXPECTED_ABSENT_NOW_EXISTS:'+ $path)}
 }elseif(-not $first[$path].exists -or -not $second[$path].exists){$errors.Add('EXPECTED_FILE_MISSING:'+ $path)}
 if(-not (Same-Metadata $first[$path] $second[$path]) -or -not $first[$path].stable_during_hash -or -not $second[$path].stable_during_hash){
  $drift+=@([ordered]@{path=$path;first=$first[$path];second=$second[$path];rollback=$false})
  $errors.Add('CONCURRENT_CHANGE_DURING_CAPTURE:'+ $path)
 }
 if($seed.facts.ContainsKey($path) -and -not (Same-Metadata $seed.facts[$path] $first[$path])){
  $historical+=@([ordered]@{path=$path;previous_31b=$seed.facts[$path];fresh_now=$first[$path];historical_only_not_capture_failure=$true;rollback=$false})
 }
}
$processLast=@(Engine-Inventory);Require-Only-Editor $processLast 51856 'AFTER'
if(($processFirst|ConvertTo-Json -Depth 5 -Compress) -cne ($processLast|ConvertTo-Json -Depth 5 -Compress)){$errors.Add('EDITOR_IDENTITY_CHANGED')}
$result=[ordered]@{
 passed=($errors.Count -eq 0);status='FRESH_NOW_METADATA_ONLY_PRE_31C_DEPLOY';started_utc=$began;finished_utc=[DateTime]::UtcNow.ToString('o')
 source_count=$sources.Count;save_count=$saves.Count;seed_source_count=986;current_native_keys=202;additional_source_count=($sources.Count-986)
 facts=$first;second_facts=$second;expected_absent_save_paths=@($absent|Sort-Object)
 concurrent_changes=$drift;historical_since_31b=$historical;errors=$errors.ToArray()
 godot_processes_before=$processFirst;godot_processes_after=$processLast
 original_head_registry='9da1cf4f403e9f5be9848da6feac8f89bfad78d618a94e85edb5f328b545bf79'
 original_head_native='c38bfc9c52d5f12419aadeffbbf18a574c9b7109fc7c86f3b8a2ddf78340d654'
 fixed_31b_seed_sha256='38429886e3a20ed4582484d0d212d8ced65c636803c4da0a7e32c4486ee87ea9'
 scope_reference_pins=$scope.current_source_pins
 values_are_all_fresh_not_inherited=$true;prior_user_game_updates_are_historical_not_rolled_back=$true
 engine_runs=0;process_control=0;save_deserializations=0;save_writes=0;production_writes=0
}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($result|ConvertTo-Json -Depth 15)+[Environment]::NewLine)
$file=[IO.File]::Open($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
try{$file.Write($bytes,0,$bytes.Length)}finally{$file.Dispose()}
[ordered]@{passed=$result.passed;source_count=$sources.Count;save_count=$saves.Count;expected_absent=9;historical_differences=$historical.Count;errors=$errors.ToArray();report=$output;sha256=(Hash-Only $output)}|ConvertTo-Json -Depth 4
if($errors.Count -gt 0){exit 1}
