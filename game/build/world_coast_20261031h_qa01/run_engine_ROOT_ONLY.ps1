param(
 [Parameter(Mandatory=$true)][string]$GodotExe,
 [Parameter(Mandatory=$true)][string]$Script,
 [Parameter(Mandatory=$true)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$ScriptSHA,
 [Parameter(Mandatory=$true)][string]$LogDir,
 [Parameter(Mandatory=$true)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$LogStem,
 [string]$UserArgsJSON='[]',
 [switch]$Headless,
 [switch]$CheckOnly
)
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'USE_BUNDLED_PWSH7'}
$taskRepo='F:/Code/RPG_GAME';$taskProject=$taskRepo+'/game'
function Hash-Only([string]$p){$s=[IO.File]::OpenRead($p);try{return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($s)).ToLowerInvariant()}finally{$s.Dispose()}}
function Write-NewJSON([string]$p,$data){$b=[Text.UTF8Encoding]::new($false).GetBytes(($data|ConvertTo-Json -Depth 12)+[Environment]::NewLine);$f=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);try{$f.Write($b,0,$b.Length)}finally{$f.Dispose()}}
function Quote-Arg([string]$value){if($value.Contains('"') -or $value.EndsWith('\') -or $value.Contains("`r") -or $value.Contains("`n")){throw 'UNSUPPORTED_ARG_ENCODING'};return '"'+$value+'"'}
if(-not [IO.Path]::IsPathRooted($GodotExe)){throw 'ROOTED_GODOT_EXE_REQUIRED'}
$taskExe=[IO.Path]::GetFullPath($GodotExe)
if(-not(Test-Path -LiteralPath $taskExe -PathType Leaf) -or [IO.Path]::GetFileName($taskExe) -notmatch '(?i)^godot[^/\\]*\.exe$'){throw 'EXACT_EXISTING_GODOT_EXE_REQUIRED'}
if($Script -notmatch '^res://build/world_coast_20261031h_(?:qa01|system01|system02)/[A-Za-z0-9_/-]+\.gd$' -or $Script.Contains('..')){throw 'EXACT_NEW_COAST_SCRIPT_ONLY'}
$taskScript=$taskProject+'/'+$Script.Substring(6)
if(-not(Test-Path -LiteralPath $taskScript -PathType Leaf) -or (Hash-Only $taskScript) -cne $ScriptSHA.ToLowerInvariant()){throw 'SCRIPT_PATH_AND_SHA_MISMATCH'}
if(-not [IO.Path]::IsPathRooted($LogDir)){throw 'ROOTED_LOG_DIR_REQUIRED'}
$taskLogs=[IO.Path]::GetFullPath($LogDir).Replace('\','/')
if($taskLogs -notmatch '^F:/Code/RPG_GAME/game/build/world_coast_20261031h_(?:qa01|root01)(?:/|$)' -or $taskLogs.Contains('/../')){throw 'NEW_COAST_LOG_DIRECTORY_ONLY'}
[void][IO.Directory]::CreateDirectory($taskLogs)
$taskStdout=$taskLogs+'/'+$LogStem+'_stdout.log';$taskStderr=$taskLogs+'/'+$LogStem+'_stderr.log';$taskLaunched=$taskLogs+'/'+$LogStem+'_LAUNCHED.json';$taskReceipt=$taskLogs+'/'+$LogStem+'_process_receipt.json'
foreach($taskOutput in @($taskStdout,$taskStderr,$taskLaunched,$taskReceipt)){if(Test-Path -LiteralPath $taskOutput){throw ('PRESERVE_EXISTING_RUN:'+ $taskOutput)}}
$taskUser=ConvertFrom-Json -InputObject $UserArgsJSON -NoEnumerate
if($taskUser -isnot [array]){throw 'USER_ARGS_MUST_BE_JSON_ARRAY'}
if($taskUser.Count%2 -ne 0){throw 'USER_ARGS_APPROVED_PAIRS_ONLY'}
for($taskI=0;$taskI -lt $taskUser.Count;$taskI+=2){
 $taskKey=$taskUser[$taskI];$taskValue=$taskUser[$taskI+1]
 if($taskKey -isnot [string] -or $taskValue -isnot [string]){throw 'STRING_ARGUMENTS_ONLY'}
 switch -Exact ($taskKey){
  '--source-plan-sha' {if($taskValue -notmatch '^[a-fA-F0-9]{64}$'){throw 'SOURCE_PLAN_SHA_ONLY'}}
  '--manifest-sha' {if($taskValue -notmatch '^[a-fA-F0-9]{64}$'){throw 'MANIFEST_SHA_ONLY'}}
  '--manifest' {if($taskValue -notmatch '^res://art/maps/world_coast_20261031h/[A-Za-z0-9_/-]+\.json$' -or $taskValue.Contains('..')){throw 'NEW_COAST_MANIFEST_ONLY'}}
  default {throw ('UNAPPROVED_ENGINE_USER_ARGUMENT:'+ $taskKey)}
 }
}
$taskArgs=[Collections.Generic.List[string]]::new()
if($Headless){$taskArgs.Add('--headless')}
$taskArgs.Add('--path');$taskArgs.Add($taskProject)
if($CheckOnly){$taskArgs.Add('--check-only')}
$taskArgs.Add('--script');$taskArgs.Add($Script)
if($taskUser.Count){$taskArgs.Add('--');foreach($taskValue in $taskUser){$taskArgs.Add($taskValue)}}
$taskStarted=[DateTime]::UtcNow.ToString('o');$taskWatch=[Diagnostics.Stopwatch]::StartNew()
$taskProcess=Start-Process -FilePath $taskExe -ArgumentList (($taskArgs|ForEach-Object{Quote-Arg $_}) -join ' ') -WorkingDirectory $taskProject -WindowStyle Hidden -RedirectStandardOutput $taskStdout -RedirectStandardError $taskStderr -PassThru
$taskProcessID=[int]$taskProcess.Id
Write-NewJSON $taskLaunched ([ordered]@{status='LAUNCHED_PROCESS_RETAINED_NOT_EXIT_CREDIT';engine_pid=$taskProcessID;launcher_pid=$PID;started_utc=$taskStarted;exe=$taskExe;project=$taskProject;script=$Script;script_sha256=$ScriptSHA.ToLowerInvariant();arguments=$taskArgs.ToArray();headless=[bool]$Headless;check_only=[bool]$CheckOnly;stdout_path=$taskStdout;stderr_path=$taskStderr;process_control=0})
Write-Output ('LAUNCHED_PID='+$taskProcessID+' RECORD='+$taskLaunched)
$taskProcess.WaitForExit();$taskProcess.Refresh();$taskExit=[int]$taskProcess.ExitCode;$taskWatch.Stop()
$taskResult=[ordered]@{actual_natural_console_exit_code=$taskExit;exit_code_from_retained_process_WaitForExit=$true;engine_pid=$taskProcessID;launcher_pid=$PID;started_utc=$taskStarted;finished_utc=[DateTime]::UtcNow.ToString('o');elapsed_wall_ms=$taskWatch.ElapsedMilliseconds;exe=$taskExe;project=$taskProject;script=$Script;script_sha256=$ScriptSHA.ToLowerInvariant();script_after_sha256=(Hash-Only $taskScript);headless=[bool]$Headless;check_only=[bool]$CheckOnly;stdout_path=$taskStdout;stdout_sha256=(Hash-Only $taskStdout);stderr_path=$taskStderr;stderr_sha256=(Hash-Only $taskStderr);editor51856_still_running=($null -ne(Get-Process -Id 51856 -ErrorAction SilentlyContinue));process_stopped_by_tool=$false;whole_runtime_or_ART_pass_claim=$false}
Write-NewJSON $taskReceipt $taskResult
[ordered]@{exit_code=$taskExit;engine_pid=$taskProcessID;elapsed_wall_ms=$taskWatch.ElapsedMilliseconds;receipt=$taskReceipt;receipt_sha256=(Hash-Only $taskReceipt)}|ConvertTo-Json -Depth 4
if($taskExit -ne 0){exit $taskExit}
