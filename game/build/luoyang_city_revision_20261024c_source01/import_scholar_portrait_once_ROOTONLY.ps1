$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
# ROOT ONLY. Preparing this script does not launch Godot or promote any media.
$project='F:/Code/RPG_GAME/assets/staging/luoyang_scholar_portrait_20261024c_import'
$stem='F:/Code/RPG_GAME/game/build/luoyang_city_revision_20261024c_root01/scholar_portrait_isolate_import_once'
$godot='F:/文件下载/编程工具/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe'
$preparedSha='6f41021d0ad1718f63c0557cfba382edf7c700b7904ab93c279a279c7820e5d7'
$verifierSha='12806b01f2960496993b70d34e348a284633d492b3027ba02885ad354fd986d8'
$projectSha='82ac9e5f0459dfacd007433c4ce000b31515b4fad794196951c03d81b7ffb4f8'
function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function Fact([string]$p){
 if(!(Test-Path -LiteralPath $p)){return @{exists=$false}}
 $x=Get-Item -LiteralPath $p
 return @{exists=$true;sha256=(Sha $p);bytes=$x.Length;ticks=[string]$x.LastWriteTimeUtc.Ticks}
}
function NewJson([string]$p,$v){
 $f=[IO.File]::Open($p,[IO.FileMode]::CreateNew);$w=[IO.StreamWriter]::new($f,[Text.UTF8Encoding]::new($false))
 try{$w.Write(($v|ConvertTo-Json -Depth 18)+"`n")}finally{$w.Dispose()}
}
foreach($p in @($stem+'_stdout.log',$stem+'_stderr.log',$stem+'_process_receipt.json')){if(Test-Path -LiteralPath $p){throw 'PRESERVE_UNIQUE_OLD_LOG_OR_RECEIPT'}}
if((Sha "$project/prepared_READY.json") -cne $preparedSha -or (Sha "$project/verify_READY.gd") -cne $verifierSha -or (Sha "$project/project.godot") -cne $projectSha){throw 'FIXED_ISOLATE_INPUT_CHANGED'}
if(!(Test-Path -LiteralPath $godot)){throw 'FIXED_GODOT_EXECUTABLE_MISSING'}
$spec=Get-Content -LiteralPath "$project/prepared_READY.json" -Raw|ConvertFrom-Json -AsHashtable
if($spec.status -cne 'EXACT_ONE_OPAQUE_SCHOLAR_PORTRAIT_ISOLATED_IMPORT_PREPARED' -or $spec.textures.Count -ne 1 -or $spec.main_three_absent_targets.Count -ne 3){throw 'ONLY_ONE_PORTRAIT_ISOLATE_REQUIRED'}
foreach($p in $spec.main_three_absent_targets){if(Test-Path -LiteralPath $p){throw 'MAIN_THREE_LEAVES_NOT_ABSENT'}}
$engines=@(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'")
foreach($p in $engines){
 if($p.ProcessId -ne 51856){throw 'NONEDITOR_GODOT_ACTIVE_NO_KILL_OR_CONCURRENT_IMPORT'}
 if([string]::IsNullOrWhiteSpace($p.CommandLine) -or $p.CommandLine -notmatch '(?i)(--editor|(?:^|\s)-e(?:\s|$))'){throw 'KNOWN_PID_IS_NOT_PROVABLY_EDITOR_NO_PROCESS_MUTATION'}
}
$protected=@{}
foreach($p in @("$project/prepared_READY.json","$project/verify_READY.gd","$project/project.godot",$PSCommandPath)+@($spec.protected_main_sources.Keys)){$protected[$p]=Fact $p}
$beforeAbsent=@{};foreach($p in $spec.main_three_absent_targets){$beforeAbsent[$p]=Fact $p}
[void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($stem))
$started=[DateTime]::UtcNow.ToString('o');$timer=[Diagnostics.Stopwatch]::StartNew()
$process=Start-Process -FilePath $godot -ArgumentList @('--headless','--editor','--import','--path',$project,'--quit') -WindowStyle Hidden -RedirectStandardOutput ($stem+'_stdout.log') -RedirectStandardError ($stem+'_stderr.log') -PassThru
# The retained object is the exact spawned console process. Do not substitute a polled PID status.
$process.WaitForExit();$process.Refresh();$timer.Stop()
$naturalExit=$process.ExitCode
$protectedSame=$true;$protectedAfter=@{}
foreach($p in $protected.Keys){
 $protectedAfter[$p]=Fact $p;$a=$protected[$p];$b=$protectedAfter[$p]
 if($a.exists -ne $b.exists -or ($a.exists -and ($a.sha256 -cne $b.sha256 -or $a.bytes -ne $b.bytes -or $a.ticks -cne $b.ticks))){$protectedSame=$false}
}
$mainAbsent=$true;$afterAbsent=@{}
foreach($p in $spec.main_three_absent_targets){$afterAbsent[$p]=Fact $p;if($afterAbsent[$p].exists){$mainAbsent=$false}}
$report=@{scope='ONLY_ONE_NEW_OPAQUE_PORTRAIT_ISOLATED_EDITOR_IMPORT_NOT_NATIVE_VERIFY';project=$project;prepared_sha256=$preparedSha;verifier_sha256=$verifierSha;project_sha256=$projectSha;fixed_protection_parent_sha256='18eee16cb341f01a984acd1f260dd1511e0e543e0d61b90789cef3f960d5712a';launcher_pid=$PID;engine_pid=$process.Id;started_utc=$started;finished_utc=[DateTime]::UtcNow.ToString('o');elapsed_ms=$timer.ElapsedMilliseconds;actual_natural_console_exit_code=$naturalExit;exit_code_available=($null -ne $naturalExit);retained_process_WaitForExit=$true;process_stopped_by_tool=$false;stdout_path=$stem+'_stdout.log';stdout_sha256=(Sha ($stem+'_stdout.log'));stderr_path=$stem+'_stderr.log';stderr_sha256=(Sha ($stem+'_stderr.log'));protected_first=$protected;protected_final=$protectedAfter;protected_same=$protectedSame;main_three_before=$beforeAbsent;main_three_after=$afterAbsent;main_three_absent=$mainAbsent;main_project_import=$false;media_promotions=0;Field_or_runtime_pass_claim=$false;editor51856_alive=(@(Get-Process -Id 51856 -ErrorAction SilentlyContinue).Count -eq 1)}
NewJson ($stem+'_process_receipt.json') $report
$report|ConvertTo-Json -Depth 4
if($null -eq $naturalExit -or !$protectedSame -or !$mainAbsent){throw 'IMPORT_FINISHED_EVIDENCE_OR_PROTECTION_FAILURE_PRESERVED_NO_RETRY'}
exit $naturalExit
