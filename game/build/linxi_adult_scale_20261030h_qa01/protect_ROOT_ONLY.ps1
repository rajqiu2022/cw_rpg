param([Parameter(Mandatory=$true)][ValidateSet('Capture','Final')][string]$Mode,[Parameter(Mandatory=$true)][ValidatePattern('^[a-f0-9]{64}$')][string]$ExpectedAuthSHA)
$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/linxi_adult_scale_20261030h_qa01"
$authPath="$repo/game/build/linxi_adult_scale_20261030h_system01/closure01_READY/auth_READY.json"
$receiptPath="$repo/game/build/linxi_adult_scale_20261030h_system01/closure01_READY/receipt_READY.json"
$scopePath="$qa/protection_scope_READY.json";$basePath="$qa/baseline_ROOT_ACTUAL.json"
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
function Same($a,$b){return $a.exists -eq $b.exists -and (!$a.exists -or ($a.sha256 -ceq $b.sha256 -and $a.bytes -eq $b.bytes -and $a.utc_ticks -ceq $b.utc_ticks))}
function Absolute([string]$p){if($p.StartsWith('res://')){$p='game/'+$p.Substring(6)};$full=[IO.Path]::GetFullPath("$repo/$p").Replace('\','/');if(!$p.StartsWith('game/') -or !$full.StartsWith("$repo/game/",[StringComparison]::OrdinalIgnoreCase)){throw "SOURCE_OUTSIDE_PROJECT:$p"};return $full}
function NewJson([string]$p,$v){$stream=[IO.File]::Open($p,[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($v|ConvertTo-Json -Depth 30)+"`n");$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}}
if((Fact $scopePath).sha256 -cne '5c88fbed861eeb4165c14a7bcd00c246990b347c00eab0e27e3026afe5409bb3'){throw 'FROZEN_SCOPE_CHANGED'}
if((Fact $authPath).sha256 -cne $ExpectedAuthSHA){throw 'EXACT_FINAL_H_AUTH_REQUIRED'}
$auth=Get-Content -LiteralPath $authPath -Raw|ConvertFrom-Json;$receipt=Get-Content -LiteralPath $receiptPath -Raw|ConvertFrom-Json;$scope=Get-Content -LiteralPath $scopePath -Raw|ConvertFrom-Json
if(@($auth.sources.PSObject.Properties).Count -ne 6 -or @($receipt.targets).Count -ne 6 -or @(Compare-Object @($scope.exact_targets|Sort-Object) @($auth.sources.PSObject.Properties.Name|Sort-Object)).Count -ne 0){throw 'ONLY_EXACT_SIX_H_EXISTING_TARGETS_ALLOWED'}
$processes=@();foreach($p in @(Get-CimInstance Win32_Process -Filter "name like 'Godot%'")){
 $window=Get-Process -Id $p.ProcessId -ErrorAction SilentlyContinue
 $row=[ordered]@{process_id=[int]$p.ProcessId;name=$p.Name;command_line=$p.CommandLine;parent_process_id=[int]$p.ParentProcessId;creation_utc_ticks=[string]$p.CreationDate.ToUniversalTime().Ticks;main_window_handle=if($window){[string]$window.MainWindowHandle}else{$null}}
 if($p.ProcessId -ne 51856){throw "ROOT_OWNED_TEST_MUST_EXIT_FIRST_OTHER_ENGINE_NOT_STOPPED:$($p.ProcessId)"};$processes+=$row
}
$issues=@();$targets=[ordered]@{};$protected=[ordered]@{};$backups=@();$modules=[ordered]@{};$inputs=[ordered]@{}
if($Mode -ceq 'Capture'){
 if(Test-Path -LiteralPath $basePath){throw 'IMMUTABLE_BASELINE_EXISTS_NO_RECAPTURE_OR_REBASE'}
 foreach($p in $auth.sources.PSObject.Properties){$f=Fact (Absolute $p.Name);$r=@($receipt.targets|Where-Object {$_.target -ceq $p.Name});if($r.Count -ne 1 -or !$f.exists -or $f.sha256 -cne $r[0].old_sha256){throw "NOT_UNDEPLOYED_FORMAL_PARENT:$($p.Name)"};$targets[$p.Name]=$f}
 $protectPaths=@(@($scope.protected)+@($auth.immutable_inputs.PSObject.Properties.Name)|Sort-Object -Unique)
 foreach($p in $protectPaths){if($p -in $scope.exact_targets){throw 'PROTECTION_OVERLAPS_TARGET'};$f=Fact (Absolute $p);if(!$f.exists){throw "MISSING_PROTECTED:$p"};$protected[$p]=$f}
 foreach($p in $auth.immutable_inputs.PSObject.Properties){if($protected[$p.Name].sha256 -cne $p.Value.sha256){throw "AUTHOR_IMMUTABLE_INPUT_CHANGED:$($p.Name)"}}
 foreach($p in $targets.Keys){$destination="$qa/source_before/$p";[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination))|Out-Null;$stream=[IO.File]::Open($destination,[IO.FileMode]::CreateNew);try{$bytes=[IO.File]::ReadAllBytes((Absolute $p));$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()};[IO.File]::SetLastWriteTimeUtc($destination,[DateTime]::new([long]$targets[$p].utc_ticks,[DateTimeKind]::Utc));$copy=Fact $destination;if(!(Same $copy $targets[$p]) -or !(Same (Fact (Absolute $p)) $targets[$p])){throw "COPY_RACE_KEEP_FACTS_NO_REBASE:$p"};$backups+=@{source=$p;path=$destination;fact=$copy}}
 $gGuard="$repo/game/build/linxi_mountain_road_20261030g_qa01/final_guard_STATIC_ONLY_ROOT_ACTUAL.json"
 if((Fact $gGuard).sha256 -cne '10fda71296622febefd8ff92e4ea8e19851134b69e920d5a930c996e903f22dc'){throw 'EXACT_CLOSED_G_REPORT_FOR_REGISTERED_PATH_NAMES_ONLY_REQUIRED'}
 $prior=Get-Content -LiteralPath $gGuard -Raw|ConvertFrom-Json;$savePaths=@($prior.registered_save_paths.PSObject.Properties.Name)
}else{
 $baseline=Get-Content -LiteralPath $basePath -Raw|ConvertFrom-Json
 if($baseline.auth.sha256 -cne $ExpectedAuthSHA -or @($baseline.sources.PSObject.Properties).Count -ne 6 -or @($baseline.exact_backups).Count -ne 6 -or !$baseline.save_capture_stable){throw 'EXACT_SUCCESSFUL_ACTUAL_H_BASELINE_REQUIRED'}
 foreach($p in $auth.sources.PSObject.Properties){$f=Fact (Absolute $p.Name);$targets[$p.Name]=$f;if(!$f.exists -or $f.sha256 -cne $p.Value.sha256 -or $f.bytes -ne $p.Value.bytes){$issues+=@{kind='TRUE_POSTDEPLOY_SOURCE_DIFF';path=$p.Name;expected=$p.Value;actual=$f}}}
 foreach($p in $baseline.protected_sources.PSObject.Properties){$f=Fact (Absolute $p.Name);$protected[$p.Name]=$f;if(!(Same $p.Value $f)){$issues+=@{kind='IMMUTABLE_SOURCE_DIFF';path=$p.Name;expected=$p.Value;actual=$f}}}
 foreach($copy in $baseline.exact_backups){$path=[IO.Path]::GetFullPath($copy.path).Replace('\','/');if(!$path.StartsWith("$qa/source_before/game/",[StringComparison]::OrdinalIgnoreCase)){throw 'BACKUP_OUTSIDE_EXACT_H_SCOPE'};$f=Fact $path;$backups+=@{source=$copy.source;path=$path;fact=$f};if(!(Same $copy.fact $f)){$issues+=@{kind='ORIGINAL_BACKUP_DIFF';path=$copy.source;expected=$copy.fact;actual=$f}}}
 $native=Get-Content -LiteralPath "$repo/game/build/three_towns_world_20261029j_system01/native_sources.json" -Raw|ConvertFrom-Json
 foreach($p in $baseline.old_native_entries.PSObject.Properties){$source='game/'+$p.Name.Substring(6);$expected=$p.Value;if($auth.sources.PSObject.Properties[$source]){$expected=$auth.sources.PSObject.Properties[$source].Value.sha256};if($native.sources.PSObject.Properties[$p.Name].Value -cne $expected){$issues+=@{kind='OLD_NATIVE_KEY_OR_UNTARGETED_VALUE_CHANGED';path=$p.Name;expected=$expected;actual=$native.sources.PSObject.Properties[$p.Name].Value}}}
 $savePaths=@($baseline.registered_save_paths.PSObject.Properties.Name)
}
foreach($p in $auth.new_modules.PSObject.Properties){$f=Fact (Absolute $p.Name);$modules[$p.Name]=$f;if(!$f.exists -or $f.sha256 -cne $p.Value.sha256 -or $f.bytes -ne $p.Value.bytes){$issues+=@{kind='NEW_MODULE_DIFF';path=$p.Name;expected=$p.Value;actual=$f}}}
foreach($p in $auth.runtime_inputs.PSObject.Properties){$f=Fact (Absolute $p.Name);$inputs[$p.Name]=$f;if(!$f.exists -or $f.sha256 -cne $p.Value.sha256 -or $f.bytes -ne $p.Value.bytes){$issues+=@{kind='RUNTIME_INPUT_DIFF';path=$p.Name;expected=$p.Value;actual=$f}}}
if($savePaths.Count -ne 171){throw 'EXACT171_REGISTERED_SAVE_PATHS_REQUIRED'}
$first=[ordered]@{};$saves=[ordered]@{};$during=@();$saveDiffs=@()
function SaveFact([string]$p){try{return Fact $p}catch{return [ordered]@{exists=(Test-Path -LiteralPath $p);capture_error=$_.Exception.Message}}}
foreach($p in $savePaths){$first[$p]=SaveFact $p}
foreach($p in $savePaths){$saves[$p]=SaveFact $p;if($first[$p].capture_error -or $saves[$p].capture_error -or !(Same $first[$p] $saves[$p])){$during+=@{path=$p;first=$first[$p];second=$saves[$p]}};if($Mode -ceq 'Final' -and !(Same $baseline.registered_save_paths.PSObject.Properties[$p].Value $saves[$p])){$saveDiffs+=@{path=$p;baseline=$baseline.registered_save_paths.PSObject.Properties[$p].Value;current=$saves[$p]}}}
$report=[ordered]@{status='STATIC_ONLY_H_CURRENT_SOURCE_SAVE_FACTS';passed=($issues.Count -eq 0 -and $during.Count -eq 0 -and $saveDiffs.Count -eq 0);auth=(Fact $authPath);receipt=(Fact $receiptPath);scope=(Fact $scopePath);sources=$targets;exact_backups=$backups;protected_sources=$protected;new_modules=$modules;runtime_inputs=$inputs;source_diffs=$issues;save_double_read_first=$first;registered_save_paths=$saves;save_capture_stable=($during.Count -eq 0);save_changes_during_capture=$during;save_diffs_from_actual_h_baseline=$saveDiffs;godot_processes_observed=$processes;engine_calls=0;production_writes=0;save_contents_deserialized=$false;save_writes=0;process_controls=0;game_input=0;old_g_evidence_unchanged_and_not_retested=$true;save_diff_policy='Record and preserve current values; no rollback or rebase'}
if($Mode -ceq 'Capture'){$native=Get-Content -LiteralPath "$repo/game/build/three_towns_world_20261029j_system01/native_sources.json" -Raw|ConvertFrom-Json;$report.old_native_entries=$native.sources;$report.old_location_rows=Get-Content -LiteralPath "$repo/game/build/four_settlements_20261030e_system01/locations.json" -Raw|ConvertFrom-Json;$out=$basePath}else{$report.baseline=(Fact $basePath);$out="$qa/final_guard_ROOT_ACTUAL.json"}
NewJson $out $report
[ordered]@{path=$out;sha256=(Fact $out).sha256;mode=$Mode;passed=$report.passed;sources=$targets.Count;backups=$backups.Count;protected=$protected.Count;new_modules=$modules.Count;runtime_inputs=$inputs.Count;saves=$saves.Count;source_diffs=$issues.Count;save_capture_changes=$during.Count;save_diffs=$saveDiffs.Count}|ConvertTo-Json
if(!$report.passed){throw 'H_PROTECTION_DIFFERENCE_RECORDED_NO_REBASE_OR_ROLLBACK'}
