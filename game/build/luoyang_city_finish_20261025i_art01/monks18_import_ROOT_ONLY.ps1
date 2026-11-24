$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$taskIsolate='F:/Code/RPG_GAME/game/build/luoyang_city_finish_20261025i_art01/monks17_single_sprite_isolate_ROOT_PREPARED'
$taskStem='F:/Code/RPG_GAME/game/build/luoyang_city_finish_20261025i_art01/monks18_import_actual'
function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
if((Sha "$taskIsolate/prepared_READY.json") -cne '06fb0a7d9a7980964e9db4cdf47c086381f0d9e18dd5e66793bbe9f5d73e8f3a' -or (Sha "$taskIsolate/verify_READY.gd") -cne '230c122e7c435238eb14f5061e5a2ee0dcb0ea2bd70c56b397ad2dc129f7eecb' -or (Sha "$taskIsolate/project.godot") -cne '7b91bac6217ba3c16768016f3bde1a1938330a4a733efeee14bcf539bcee90e4'){throw 'FROZEN_SINGLE_SPRITE_ISOLATE_REQUIRED'}
$taskSpec=Get-Content -Raw -LiteralPath "$taskIsolate/prepared_READY.json" | ConvertFrom-Json -AsHashtable
foreach($p in $taskSpec.main_three_absent_targets){if(Test-Path -LiteralPath $p){throw 'MAIN_THREE_TARGETS_MUST_STAY_ABSENT'}}
if(@(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'" | Where-Object {$_.ProcessId -ne 51856}).Count -ne 0){throw 'OTHER_GODOT_ACTIVE_DO_NOT_STOP'}
$taskStdout=$taskStem+'_stdout.log';$taskStderr=$taskStem+'_stderr.log';$taskReceipt=$taskStem+'_process_receipt.json'
foreach($p in @($taskStdout,$taskStderr,$taskReceipt)){if(Test-Path -LiteralPath $p){throw 'RETAIN_PREVIOUS_IMPORT_RESULT'}}
$taskTimer=[Diagnostics.Stopwatch]::StartNew();$taskStarted=[DateTime]::UtcNow.ToString('o')
$taskProcess=Start-Process -FilePath 'F:/文件下载/编程工具/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe' -ArgumentList @('--headless','--path',$taskIsolate,'--editor','--import','--quit') -WindowStyle Hidden -RedirectStandardOutput $taskStdout -RedirectStandardError $taskStderr -PassThru
Write-Output ('OWN_IMPORT_LAUNCHER_PID='+$taskProcess.Id)
$taskProcess.WaitForExit();$taskTimer.Stop();$taskCode=$taskProcess.ExitCode
$taskRecord=@{phase='single_elder_sprite_isolate_import';project=$taskIsolate;actual_natural_console_exit_code=$taskCode;launcher_pid=$taskProcess.Id;started_utc=$taskStarted;finished_utc=[DateTime]::UtcNow.ToString('o');elapsed_ms=$taskTimer.ElapsedMilliseconds;retained_process_WaitForExit=$true;stopped_by_tool=$false;stdout_sha256=(Sha $taskStdout);stderr_sha256=(Sha $taskStderr);verifier_sha256=(Sha "$taskIsolate/verify_READY.gd");editor51856_still_running=(@(Get-Process -Id 51856 -ErrorAction SilentlyContinue).Count -eq 1);main_promotion=$false}
$taskFile=[IO.File]::Open($taskReceipt,[IO.FileMode]::CreateNew);$taskWriter=[IO.StreamWriter]::new($taskFile,[Text.UTF8Encoding]::new($false))
try{$taskWriter.Write(($taskRecord | ConvertTo-Json -Depth 5)+"`n")}finally{$taskWriter.Dispose()}
@{path=$taskReceipt;sha256=(Sha $taskReceipt);natural_exit_code=$taskCode} | ConvertTo-Json -Compress
exit $taskCode
