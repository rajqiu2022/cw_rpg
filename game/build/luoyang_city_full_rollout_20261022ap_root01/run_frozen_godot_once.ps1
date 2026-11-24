param(
 [Parameter(Mandatory=$true)][string]$ScriptResPath,
 [Parameter(Mandatory=$true)][string]$ScriptSHA,
 [Parameter(Mandatory=$true)][string]$LogStem,
 [switch]$Headless,
 [string]$Project='F:/Code/RPG_GAME/game'
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
$workspace='F:/Code/RPG_GAME'
$projectFull=[IO.Path]::GetFullPath($Project)
$stemFull=[IO.Path]::GetFullPath($LogStem)
$workspaceFull=[IO.Path]::GetFullPath($workspace)
if(!$projectFull.StartsWith($workspaceFull+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or !$stemFull.StartsWith($workspaceFull+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'EXACT_WORKSPACE_PROJECT_AND_LOGS_REQUIRED'}
if(!$ScriptResPath.StartsWith('res://') -or $ScriptResPath.Contains('..') -or !$ScriptResPath.EndsWith('.gd') -or $ScriptSHA -cnotmatch '^[0-9a-f]{64}$'){throw 'EXACT_SCRIPT_PATH_AND_SHA_REQUIRED'}
$scriptFile=Join-Path $projectFull $ScriptResPath.Substring(6)
if((Sha $scriptFile) -cne $ScriptSHA){throw 'FROZEN_SCRIPT_CHANGED_BEFORE_LAUNCH'}
$stdout=$stemFull+'_stdout.log';$stderr=$stemFull+'_stderr.log';$receipt=$stemFull+'_process_receipt.json'
foreach($p in @($stdout,$stderr,$receipt)){if(Test-Path -LiteralPath $p){throw 'PRESERVE_PRIOR_ACTUAL_LOG_OR_RECEIPT'}}
$other=@(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'"|Where-Object {$_.ProcessId -ne 51856})
if($other.Count -ne 0){throw 'ANOTHER_GODOT_PROCESS_ACTIVE_DO_NOT_STOP_USER_PROCESS'}
$arguments=@('--path',$projectFull,'--script',$ScriptResPath)
if($Headless){$arguments=@('--headless')+$arguments}
$began=[DateTime]::UtcNow.ToString('o')
$timer=[Diagnostics.Stopwatch]::StartNew()
$process=Start-Process -FilePath 'F:/文件下载/编程工具/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe' -ArgumentList $arguments -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
Write-Output ('OWN_LAUNCHER_PID='+$process.Id)
$process.WaitForExit()
$timer.Stop()
$code=$process.ExitCode
$result=@{script=$ScriptResPath;script_sha256=$ScriptSHA;script_after_sha256=(Sha $scriptFile);project=$projectFull;headless=[bool]$Headless;launcher_pid=$process.Id;actual_natural_console_exit_code=$code;exit_code_from_retained_process_WaitForExit=$true;started_utc=$began;finished_utc=[DateTime]::UtcNow.ToString('o');elapsed_wall_ms=$timer.ElapsedMilliseconds;stdout_path=$stdout;stdout_sha256=(Sha $stdout);stderr_path=$stderr;stderr_sha256=(Sha $stderr);editor51856_still_running=(@(Get-Process -Id 51856 -ErrorAction SilentlyContinue).Count -eq 1);process_stopped_by_tool=$false;whole_runtime_or_ART_pass_claim=$false}
$stream=[IO.File]::Open($receipt,[IO.FileMode]::CreateNew)
$writer=[IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($false))
try{$writer.Write(($result|ConvertTo-Json -Depth 6)+"`n")}finally{$writer.Dispose()}
Write-Output (@{receipt=$receipt;sha256=(Sha $receipt);actual_natural_console_exit_code=$code}|ConvertTo-Json -Compress)
exit $code
