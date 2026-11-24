$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$project='F:/Code/RPG_GAME/assets/staging/luoyang_market_walk_20261024b_import'
$stem='F:/Code/RPG_GAME/game/build/luoyang_city_revision_20261024b_root01/single_walk_import_once'
if((Get-FileHash -LiteralPath "$project/prepared_READY.json" -Algorithm SHA256).Hash -cne 'EB831D8E54763DAB5680571BEE5E1A3760D8AA2AD14F1731FE22778EA6098693'){throw 'PREPARED_CHANGED'}
foreach($p in @($stem+'_stdout.log',$stem+'_stderr.log',$stem+'_receipt.json')){if(Test-Path -LiteralPath $p){throw 'PRESERVE_OLD_LOGS'}}
$other=@(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'"|Where-Object {$_.ProcessId -ne 51856})
if($other.Count -ne 0){throw 'ANOTHER_GODOT_ACTIVE'}
$timer=[Diagnostics.Stopwatch]::StartNew()
$process=Start-Process -FilePath 'F:/文件下载/编程工具/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe' -ArgumentList @('--headless','--editor','--import','--path',$project,'--quit') -WindowStyle Hidden -RedirectStandardOutput ($stem+'_stdout.log') -RedirectStandardError ($stem+'_stderr.log') -PassThru
$process.WaitForExit();$timer.Stop()
$report=@{scope='ONLY_SINGLE_NEW_WALK_ISOLATED_IMPORT';project=$project;prepared_sha256='eb831d8e54763dab5680571bee5e1a3760d8aa2ad14f1731fe22778ea6098693';pid=$process.Id;natural_exit_code=$process.ExitCode;retained_WaitForExit=$true;elapsed_ms=$timer.ElapsedMilliseconds;main_project_import=$false;editor51856_alive=(@(Get-Process -Id 51856 -ErrorAction SilentlyContinue).Count -eq 1)}
[IO.File]::WriteAllText(($stem+'_receipt.json'),($report|ConvertTo-Json)+"`n",[Text.UTF8Encoding]::new($false))
$report|ConvertTo-Json
exit $process.ExitCode
