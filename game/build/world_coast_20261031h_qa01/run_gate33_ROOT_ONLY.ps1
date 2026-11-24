param([Parameter(Mandatory=$true)][string]$GodotExe,[Parameter(Mandatory=$true)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$ScriptSHA,[Parameter(Mandatory=$true)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$LogStem,[switch]$CheckOnly)
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'USE_BUNDLED_PWSH7'}
$taskProject='F:/Code/RPG_GAME/game';$taskScript='res://build/world_coast_20261031h_system03/gate_source_probe03_ROOT_ONLY.gd';$taskLogs=$taskProject+'/build/world_coast_20261031h_root01'
function Hash-Only([string]$p){$s=[IO.File]::OpenRead($p);try{return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($s)).ToLowerInvariant()}finally{$s.Dispose()}}
function Write-NewJSON([string]$p,$data){$b=[Text.UTF8Encoding]::new($false).GetBytes(($data|ConvertTo-Json -Depth 10)+[Environment]::NewLine);$f=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);try{$f.Write($b,0,$b.Length)}finally{$f.Dispose()}}
function Quote-Arg([string]$v){if($v.Contains('"') -or $v.EndsWith('\')){throw 'UNSUPPORTED_ARG_ENCODING'};return '"'+$v+'"'}
if(-not [IO.Path]::IsPathRooted($GodotExe) -or -not(Test-Path -LiteralPath $GodotExe -PathType Leaf) -or [IO.Path]::GetFileName($GodotExe) -notmatch '(?i)^Godot.*\.exe$'){throw 'ROOTED_GODOT_EXE_REQUIRED'}
if((Hash-Only ($taskProject+'/'+$taskScript.Substring(6))) -cne $ScriptSHA.ToLowerInvariant()){throw 'EXACT_GATE03_SCRIPT_PIN'}
$taskOut=$taskLogs+'/'+$LogStem+'_stdout.log';$taskErr=$taskLogs+'/'+$LogStem+'_stderr.log';$taskLaunch=$taskLogs+'/'+$LogStem+'_LAUNCHED.json';$taskFinal=$taskLogs+'/'+$LogStem+'_process_receipt.json'
foreach($taskP in @($taskOut,$taskErr,$taskLaunch,$taskFinal)){if(Test-Path -LiteralPath $taskP){throw 'EXISTING_RUN_RETAINED'}}
$taskArgs=@('--headless','--path',$taskProject)
if($CheckOnly){$taskArgs+=@('--check-only')}
$taskArgs+=@('--script',$taskScript)
if(-not $CheckOnly){$taskArgs+=@('--','--coast-v16-source-probe')}
$taskStarted=[DateTime]::UtcNow.ToString('o');$taskWatch=[Diagnostics.Stopwatch]::StartNew()
$taskProcess=Start-Process -FilePath $GodotExe -ArgumentList (($taskArgs|ForEach-Object{Quote-Arg $_}) -join ' ') -WorkingDirectory $taskProject -WindowStyle Hidden -RedirectStandardOutput $taskOut -RedirectStandardError $taskErr -PassThru
$taskProcessID=[int]$taskProcess.Id
Write-NewJSON $taskLaunch ([ordered]@{console_pid=$taskProcessID;script=$taskScript;script_sha256=$ScriptSHA.ToLowerInvariant();arguments=$taskArgs;started_utc=$taskStarted;check_only=[bool]$CheckOnly;process_control=0})
Write-Output ('OWN_GATE_CONSOLE_PID='+$taskProcessID+' RECORD='+$taskLaunch)
$taskProcess.WaitForExit();$taskProcess.Refresh();$taskExit=[int]$taskProcess.ExitCode;$taskWatch.Stop()
$taskResult=[ordered]@{actual_natural_console_exit_code=$taskExit;exit_code_from_retained_process_WaitForExit=$true;console_pid=$taskProcessID;script=$taskScript;script_sha256=$ScriptSHA.ToLowerInvariant();script_after_sha256=(Hash-Only ($taskProject+'/'+$taskScript.Substring(6)));check_only=[bool]$CheckOnly;started_utc=$taskStarted;finished_utc=[DateTime]::UtcNow.ToString('o');elapsed_wall_ms=$taskWatch.ElapsedMilliseconds;stdout_path=$taskOut;stdout_sha256=(Hash-Only $taskOut);stderr_path=$taskErr;stderr_sha256=(Hash-Only $taskErr);real_save_APIs=0;process_stopped_by_tool=$false;editor51856_still_running=($null -ne(Get-Process -Id 51856 -ErrorAction SilentlyContinue))}
Write-NewJSON $taskFinal $taskResult
[ordered]@{exit_code=$taskExit;console_pid=$taskProcessID;receipt=$taskFinal;receipt_sha256=(Hash-Only $taskFinal)}|ConvertTo-Json
if($taskExit -ne 0){exit $taskExit}
