$ErrorActionPreference='Stop'
$qaRoot='F:/Code/RPG_GAME/game/build/major_cities_20261028_qa04'
$scriptRes='res://build/major_cities_20261028_qa04/road_layer_READY.gd'
$scriptFile=Join-Path $qaRoot 'road_layer_READY.gd'
$expected='3732544a48a7d25f9fb29166a787b925092c02f6ffd0d20211849bbedab80d3e'
function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
if((Sha $scriptFile) -cne $expected){throw 'Frozen visual script differs.'}
$observed=Get-CimInstance Win32_Process -Filter 'ProcessId=67108'
if($null -eq $observed -or $observed.Name -cne 'Godot.exe' -or $observed.CommandLine -notlike '*res://scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn*'){throw 'Only the independently observed existing Redrock game is allowed concurrently.'}
$other=@(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'"|Where-Object {$_.ProcessId -notin @(51856,67108)})
if($other.Count -ne 0){throw 'Unexpected additional Godot process; none will be stopped.'}
$freeText=& nvidia-smi --query-gpu=memory.free --format=csv,noheader,nounits
if($LASTEXITCODE -ne 0 -or [int]$freeText -lt 4096){throw 'At least four GiB free VRAM required for this bounded isolated view.'}
$stem=Join-Path $qaRoot 'road_layer06_concurrent_ROOT_ACTUAL'
$stdout=$stem+'_stdout.log';$stderr=$stem+'_stderr.log';$receipt=$stem+'_process_receipt.json'
foreach($p in @($stdout,$stderr,$receipt)){if(Test-Path -LiteralPath $p){throw 'Preserve prior attempt; CreateNew logs only.'}}
$timer=[Diagnostics.Stopwatch]::StartNew()
$owned=Start-Process -FilePath 'F:/文件下载/编程工具/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe' -ArgumentList @('--path','F:/Code/RPG_GAME/game','--script',$scriptRes) -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
Write-Output ('OWN_LAUNCHER_PID='+$owned.Id)
$owned.WaitForExit();$timer.Stop();$exitCode=$owned.ExitCode
$after=Get-CimInstance Win32_Process -Filter 'ProcessId=67108'
$result=[ordered]@{script=$scriptRes;script_sha256=$expected;script_after_sha256=(Sha $scriptFile);actual_natural_console_exit_code=$exitCode;launcher_pid=$owned.Id;elapsed_wall_ms=$timer.ElapsedMilliseconds;observed_concurrent_pid=67108;observed_concurrent_command_before=$observed.CommandLine;observed_concurrent_command_after=$after.CommandLine;free_vram_mib_before=[int]$freeText;existing_game_or_editor_stopped=$false;production_guard_changed=$false;engine_import=$false;headless=$false;stdout_sha256=(Sha $stdout);stderr_sha256=(Sha $stderr);editor51856_present=[bool](Get-Process -Id 51856 -ErrorAction SilentlyContinue)}
$s=[IO.File]::Open($receipt,[IO.FileMode]::CreateNew);$w=[IO.StreamWriter]::new($s,[Text.UTF8Encoding]::new($false));try{$w.Write(($result|ConvertTo-Json -Depth 6)+"`n")}finally{$w.Dispose()}
[ordered]@{receipt=$receipt;sha256=(Sha $receipt);natural_exit=$exitCode;observed_redrock_retained=($null -ne $after)}|ConvertTo-Json -Compress
exit $exitCode


