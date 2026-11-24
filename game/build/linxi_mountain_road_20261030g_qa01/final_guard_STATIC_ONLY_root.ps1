$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/linxi_mountain_road_20261030g_qa01"
$baselinePath="$qa/baseline_joint_preserve_user_STATIC_ONLY.json"
$deploymentPath="$qa/deployment_ROOT_ACTUAL.json"
$authPath="$repo/game/build/linxi_road_portrait_20261030g_source01/closure01_READY/auth_READY.json"
$output="$qa/final_guard_STATIC_ONLY_ROOT_ACTUAL.json"
if(Test-Path -LiteralPath $output){throw 'IMMUTABLE_FINAL_REPORT_EXISTS_DO_NOT_REBASE_OR_OVERWRITE'}
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
function Same($a,$b){return $a.exists -eq $b.exists -and (!$a.exists -or ($a.sha256 -ceq $b.sha256 -and $a.bytes -eq $b.bytes -and $a.utc_ticks -ceq $b.utc_ticks))}
function Absolute([string]$p){if($p.StartsWith('res://')){$p='game/'+$p.Substring(6)};$full=[IO.Path]::GetFullPath("$repo/$p").Replace('\','/');if(!$p.StartsWith('game/') -or !$full.StartsWith("$repo/game/",[StringComparison]::OrdinalIgnoreCase)){throw "OUTSIDE_EXACT_GAME_SOURCE:$p"};return $full}
if((Fact $baselinePath).sha256 -cne 'f77b48bd207552d35e9c0a8fdb7e9b7e7b72b890717dfb85ba140e67bc667d94'){throw 'EXACT_ACTUAL_FRESH_BASELINE_REQUIRED_NO_RECAPTURE'}
if((Fact $deploymentPath).sha256 -cne '7541839306f7369a092a3b456dc88af410b456293b11060546a627afeb398074'){throw 'EXACT_ROOT_DEPLOYMENT_RECEIPT_REQUIRED'}
if((Fact $authPath).sha256 -cne 'f1d72b5e51ff69b67b881f6400bcd10b6e2bdab790028f6918814dd4d928835e'){throw 'EXACT_JOINT_AUTH_REQUIRED'}
$baseline=Get-Content -LiteralPath $baselinePath -Raw|ConvertFrom-Json
$deployment=Get-Content -LiteralPath $deploymentPath -Raw|ConvertFrom-Json
$auth=Get-Content -LiteralPath $authPath -Raw|ConvertFrom-Json
if(@($baseline.sources.PSObject.Properties).Count -ne 30 -or @($auth.sources.PSObject.Properties).Count -ne 30 -or @($deployment.targets).Count -ne 30 -or @($baseline.exact_backups).Count -ne 30 -or @($baseline.protected_sources.PSObject.Properties).Count -ne 67 -or @($baseline.registered_save_paths.PSObject.Properties).Count -ne 171 -or @($auth.new_modules.PSObject.Properties).Count -ne 14 -or @($auth.runtime_inputs.PSObject.Properties).Count -ne 15){throw 'EXACT30_TARGET30_BACKUP67_PROTECTED171_SAVE14_NEW15_INPUT_SCOPE_REQUIRED'}
$issues=@();$targets=[ordered]@{};$backups=[ordered]@{};$protected=[ordered]@{};$modules=[ordered]@{};$inputs=[ordered]@{}
foreach($p in $auth.sources.PSObject.Properties){
 $old=$baseline.sources.PSObject.Properties[$p.Name];$deployed=@($deployment.targets|Where-Object {$_.target -ceq $p.Name})
 if(!$old -or $deployed.Count -ne 1){$issues+=@{kind='TARGET_SET_NOT_EXACT';path=$p.Name};continue}
 $f=Fact (Absolute $p.Name);$targets[$p.Name]=$f
 if(!$f.exists -or $f.sha256 -cne $p.Value.sha256 -or $f.bytes -ne $p.Value.bytes -or $f.sha256 -cne $deployed[0].sha256 -or $f.bytes -ne $deployed[0].bytes -or $f.utc_ticks -cne $deployed[0].utc_ticks){$issues+=@{kind='TRUE_POSTDEPLOY_SOURCE_DIFF';path=$p.Name;expected_auth=$p.Value;expected_deployment=$deployed[0];actual=$f}}
}
foreach($copy in $baseline.exact_backups){
 $path=[IO.Path]::GetFullPath($copy.path).Replace('\','/')
 if(!$path.StartsWith("$qa/source_before/game/",[StringComparison]::OrdinalIgnoreCase)){throw 'BACKUP_OUTSIDE_ORIGINAL_EXACT_QA_BACKUP_SCOPE'}
 $f=Fact $path;$backups[$copy.source]=$f
 if(!(Same $f $copy.fact) -or !(Same $f $baseline.sources.PSObject.Properties[$copy.source].Value)){$issues+=@{kind='ORIGINAL_BEFORE_BACKUP_DIFF';path=$copy.source;expected=$copy.fact;actual=$f}}
}
foreach($p in $baseline.protected_sources.PSObject.Properties){$f=Fact (Absolute $p.Name);$protected[$p.Name]=$f;if(!(Same $f $p.Value)){$issues+=@{kind='IMMUTABLE_SOURCE_DIFF';path=$p.Name;expected=$p.Value;actual=$f}}}
foreach($p in $auth.new_modules.PSObject.Properties){$f=Fact (Absolute $p.Name);$modules[$p.Name]=$f;if(!$f.exists -or $f.sha256 -cne $p.Value.sha256 -or $f.bytes -ne $p.Value.bytes){$issues+=@{kind='NEW_MODULE_HASH_OR_BYTES_DIFF';path=$p.Name;expected=$p.Value;actual=$f}}}
foreach($p in $auth.runtime_inputs.PSObject.Properties){$f=Fact (Absolute $p.Name);$inputs[$p.Name]=$f;if(!$f.exists -or $f.sha256 -cne $p.Value.sha256 -or $f.bytes -ne $p.Value.bytes){$issues+=@{kind='RUNTIME_INPUT_DIFF';path=$p.Name;expected=$p.Value;actual=$f}}}
$saveFirst=[ordered]@{};$saves=[ordered]@{};$saveDiffs=@();$saveCaptureChanges=@()
function SaveFact([string]$p){try{return Fact $p}catch{return [ordered]@{exists=(Test-Path -LiteralPath $p);capture_error=$_.Exception.Message}}}
foreach($p in $baseline.registered_save_paths.PSObject.Properties){$saveFirst[$p.Name]=SaveFact $p.Name}
foreach($p in $baseline.registered_save_paths.PSObject.Properties){
 $f=SaveFact $p.Name;$saves[$p.Name]=$f
 if($f.capture_error -or $saveFirst[$p.Name].capture_error -or !(Same $saveFirst[$p.Name] $f)){$saveCaptureChanges+=@{path=$p.Name;first=$saveFirst[$p.Name];second=$f}}
 if($f.capture_error -or !(Same $p.Value $f)){$saveDiffs+=@{path=$p.Name;baseline=$p.Value;current=$f}}
}
$processes=@();$processIssues=@();$present=@()
foreach($p in @(Get-CimInstance Win32_Process -Filter "name like 'Godot%'")){
 $window=Get-Process -Id $p.ProcessId -ErrorAction SilentlyContinue
 $row=[ordered]@{process_id=[int]$p.ProcessId;name=$p.Name;command_line=$p.CommandLine;parent_process_id=[int]$p.ParentProcessId;creation_utc_ticks=[string]$p.CreationDate.ToUniversalTime().Ticks;main_window_handle=if($window){[string]$window.MainWindowHandle}else{$null}}
 $expected=@($baseline.godot_processes_observed|Where-Object {$_.process_id -eq $p.ProcessId})
 if($p.ProcessId -notin @(51856,139344) -or $expected.Count -ne 1){$processIssues+=@{kind='UNEXPECTED_ENGINE_RECORD_ONLY_NO_STOP';actual=$row}}
 elseif($row.name -cne $expected[0].name -or $row.command_line -cne $expected[0].command_line -or $row.parent_process_id -ne $expected[0].parent_process_id -or $row.creation_utc_ticks -cne $expected[0].creation_utc_ticks){$processIssues+=@{kind='PRESERVED_PID_IDENTITY_DIFF';expected=$expected[0];actual=$row}}
 $processes+=$row;$present+=[int]$p.ProcessId
}
$missing=@(51856,139344|Where-Object {$_ -notin $present})
$sourcePass=($issues.Count -eq 0);$savePass=($saveDiffs.Count -eq 0 -and $saveCaptureChanges.Count -eq 0);$processPass=($processIssues.Count -eq 0)
$status=if(!$sourcePass){'TRUE_SOURCE_DIFF_FAIL_NO_ROLLBACK'}elseif(!$savePass){'SOURCE_PASS_EXTERNAL_SAVE_DIFF_RECORDED_STATIC_ONLY'}elseif(!$processPass){'SOURCE_AND_SAVE_PASS_PROCESS_IDENTITY_REQUIRES_REVIEW'}else{'USER_GAME_PRESERVED_STATIC_ONLY_FINAL_GUARD_PASS'}
$report=[ordered]@{status=$status;passed=($sourcePass -and $savePass -and $processPass);source_pass=$sourcePass;save_pass=$savePass;process_identity_pass=$processPass;baseline=(Fact $baselinePath);deployment=(Fact $deploymentPath);auth=(Fact $authPath);targets=$targets;before_backups=$backups;protected_sources=$protected;new_modules=$modules;runtime_inputs=$inputs;source_diffs=$issues;save_double_read_first=$saveFirst;registered_save_paths=$saves;save_changes_during_capture=$saveCaptureChanges;save_diffs_from_actual_fresh_baseline=$saveDiffs;godot_processes_observed=$processes;process_identity_diffs=$processIssues;previous_user_pid_absent_record_only=$missing;save_diff_policy='Preserve current user values; record only; never restore or rebase';scope_does_not_scan_unrelated_QA_logs_gallery_or_artmeta=$true;new_engine_or_compile_runs=0;production_writes=0;save_contents_deserialized=$false;save_writes=0;process_controls=0;game_input=0;movement_or_World_entry_acceptance=$false}
$stream=[IO.File]::Open($output,[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($report|ConvertTo-Json -Depth 28)+"`n");$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
[ordered]@{path=$output;sha256=(Fact $output).sha256;status=$status;passed=$report.passed;source_diffs=$issues.Count;save_diffs=$saveDiffs.Count;save_capture_changes=$saveCaptureChanges.Count;process_identity_diffs=$processIssues.Count;targets=$targets.Count;backups=$backups.Count;protected=$protected.Count;new_modules=$modules.Count;runtime_inputs=$inputs.Count;saves=$saves.Count;processes_stopped=0}|ConvertTo-Json
if(!$report.passed){throw 'STATIC_FINAL_GUARD_DIFFERENCE_RECORDED_NO_ROLLBACK_NO_REBASE'}
