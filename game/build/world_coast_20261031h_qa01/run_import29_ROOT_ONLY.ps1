param([Parameter(Mandatory=$true)][string]$GodotExe,[Parameter(Mandatory=$true)][ValidateSet('Import','Decode')][string]$Mode,[Parameter(Mandatory=$true)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$LogStem)
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'USE_BUNDLED_PWSH7'}
$taskRepo='F:/Code/RPG_GAME';$taskQA=$taskRepo+'/game/build/world_coast_20261031h_qa01';$taskIso=$taskQA+'/import_isolated02';$taskLogs=$taskRepo+'/game/build/world_coast_20261031h_root01'
function Hash-Only([string]$p){$s=[IO.File]::OpenRead($p);try{return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($s)).ToLowerInvariant()}finally{$s.Dispose()}}
function Write-NewJSON([string]$p,$data){$b=[Text.UTF8Encoding]::new($false).GetBytes(($data|ConvertTo-Json -Depth 10)+[Environment]::NewLine);$f=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);try{$f.Write($b,0,$b.Length)}finally{$f.Dispose()}}
function Quote-Arg([string]$v){if($v.Contains('"') -or $v.EndsWith('\')){throw 'UNSUPPORTED_ARG_ENCODING'};return '"'+$v+'"'}
if(-not [IO.Path]::IsPathRooted($GodotExe) -or -not(Test-Path -LiteralPath $GodotExe -PathType Leaf) -or [IO.Path]::GetFileName($GodotExe) -notmatch '(?i)^Godot.*\.exe$'){throw 'ROOTED_GODOT_EXE_REQUIRED'}
$taskPrepared=$taskQA+'/import29_PREPARED.json'
if((Hash-Only $taskPrepared) -cne 'c85a40f461055d438c61f43275b5e7d26770c4cec01352ce346f30fb52bdd7c9'){throw 'EXACT29_PREPARED_PIN'}
$taskReceiptData=[IO.File]::ReadAllText($taskPrepared,[Text.Encoding]::UTF8)|ConvertFrom-Json -AsHashtable
if($taskReceiptData.rows.Count -ne 29 -or (Hash-Only ($taskIso+'/project.godot')) -cne $taskReceiptData.project_sha256 -or (Hash-Only ($taskIso+'/import_fixture.json')) -cne $taskReceiptData.fixture_sha256 -or (Hash-Only ($taskIso+'/decode.gd')) -cne $taskReceiptData.decoder_sha256){throw 'EXACT_ISOLATED_PROJECT_ONLY'}
if(@(Get-ChildItem -LiteralPath ($taskIso+'/art') -Recurse -File -Filter '*.png').Count -ne 29){throw 'EXACT29_ISOLATED_PNGS'}
foreach($taskRow in $taskReceiptData.rows){$taskRelative=$taskRow.path.Substring(6);foreach($taskP in @($taskRepo+'/game/'+$taskRelative,$taskIso+'/'+$taskRelative)){if((Hash-Only $taskP) -cne $taskRow.sha256){throw 'PNG_PREIMPORT_DIFF'}}}
[void][IO.Directory]::CreateDirectory($taskLogs)
$taskOut=$taskLogs+'/'+$LogStem+'_stdout.log';$taskErr=$taskLogs+'/'+$LogStem+'_stderr.log';$taskLaunch=$taskLogs+'/'+$LogStem+'_LAUNCHED.json';$taskFinal=$taskLogs+'/'+$LogStem+'_process_receipt.json'
foreach($taskP in @($taskOut,$taskErr,$taskLaunch,$taskFinal)){if(Test-Path -LiteralPath $taskP){throw 'EXISTING_RUN_RETAINED'}}
$taskArgs=@('--headless','--path',$taskIso)
if($Mode -ceq 'Import'){$taskArgs+=@('--editor','--import')}else{$taskArgs+=@('--script','res://decode.gd')}
$taskStarted=[DateTime]::UtcNow.ToString('o');$taskWatch=[Diagnostics.Stopwatch]::StartNew()
$taskProcess=Start-Process -FilePath $GodotExe -ArgumentList (($taskArgs|ForEach-Object{Quote-Arg $_}) -join ' ') -WorkingDirectory $taskIso -WindowStyle Hidden -RedirectStandardOutput $taskOut -RedirectStandardError $taskErr -PassThru
$taskProcessID=[int]$taskProcess.Id
Write-NewJSON $taskLaunch ([ordered]@{engine_pid=$taskProcessID;mode=$Mode;project=$taskIso;arguments=$taskArgs;started_utc=$taskStarted;full_project_import=$false;source_PNG_count=29;process_control=0})
Write-Output ('OWN_ISOLATED_PID='+$taskProcessID+' RECORD='+$taskLaunch)
$taskProcess.WaitForExit();$taskProcess.Refresh();$taskExit=[int]$taskProcess.ExitCode;$taskWatch.Stop()
$taskPNGSame=$true;foreach($taskRow in $taskReceiptData.rows){if((Hash-Only ($taskRepo+'/game/'+$taskRow.path.Substring(6))) -cne $taskRow.sha256){$taskPNGSame=$false}}
$taskResult=[ordered]@{actual_natural_console_exit_code=$taskExit;exit_code_from_retained_process_WaitForExit=$true;engine_pid=$taskProcessID;mode=$Mode;project=$taskIso;started_utc=$taskStarted;finished_utc=[DateTime]::UtcNow.ToString('o');elapsed_wall_ms=$taskWatch.ElapsedMilliseconds;stdout_path=$taskOut;stdout_sha256=(Hash-Only $taskOut);stderr_path=$taskErr;stderr_sha256=(Hash-Only $taskErr);original29_PNGs_unchanged=$taskPNGSame;full_project_import=$false;autoloads=0;real_save_APIs=0;process_stopped_by_tool=$false;editor51856_still_running=($null -ne(Get-Process -Id 51856 -ErrorAction SilentlyContinue))}
Write-NewJSON $taskFinal $taskResult
[ordered]@{exit_code=$taskExit;engine_pid=$taskProcessID;mode=$Mode;PNG_preserved=$taskPNGSame;receipt=$taskFinal;receipt_sha256=(Hash-Only $taskFinal)}|ConvertTo-Json
if($taskExit -ne 0){exit $taskExit};if(-not $taskPNGSame){exit 1}
