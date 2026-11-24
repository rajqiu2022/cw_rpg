$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
# ROOT ONLY. Preparing this script does not launch Godot or promote any media.
$project='F:/Code/RPG_GAME/assets/staging/luoyang_yamen_courts_mask_20261024c_import'
$stem='F:/Code/RPG_GAME/game/build/luoyang_city_revision_20261024c_root01/courts_mask_isolate_import_once'
$godot='F:/文件下载/编程工具/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe'
$preparedSha='7c7140e25a1c0922eebffb7ee53a261ab0e60dc4e1f31be9695d0555fef13006'
$verifierSha='fc0cd5abf77ce34288683640264a5c19868e703d47a570117230479e6bd83376'
$projectSha='f4dd4753edbb5183686a20dc084adb5ff3a2e159d07cafa92c86340204902051'
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
if($spec.status -cne 'EXACT_ONE_COURTS_OVERLAY_MASK_ISOLATED_IMPORT_PREPARED' -or $spec.textures.Count -ne 1 -or $spec.main_two_absent_targets.Count -ne 2){throw 'ONLY_ONE_OVERLAY_MASK_ISOLATE_REQUIRED'}
foreach($p in $spec.main_two_absent_targets){if(Test-Path -LiteralPath $p){throw 'MAIN_TWO_LEAVES_NOT_ABSENT'}}
$engines=@(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'")
foreach($p in $engines){
 if($p.ProcessId -ne 51856){throw 'NONEDITOR_GODOT_ACTIVE_NO_KILL_OR_CONCURRENT_IMPORT'}
 if([string]::IsNullOrWhiteSpace($p.CommandLine) -or $p.CommandLine -notmatch '(?i)(--editor|(?:^|\s)-e(?:\s|$))'){throw 'KNOWN_PID_IS_NOT_PROVABLY_EDITOR_NO_PROCESS_MUTATION'}
}
$protected=@{}
foreach($p in @("$project/prepared_READY.json","$project/verify_READY.gd","$project/project.godot",$PSCommandPath)+@($spec.protected_main_sources.Keys)){$protected[$p]=Fact $p}
$beforeAbsent=@{};foreach($p in $spec.main_two_absent_targets){$beforeAbsent[$p]=Fact $p}
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
foreach($p in $spec.main_two_absent_targets){$afterAbsent[$p]=Fact $p;if($afterAbsent[$p].exists){$mainAbsent=$false}}
$report=@{scope='ONLY_ONE_PUBLISHED_OVERLAY_MASK_ISOLATED_EDITOR_IMPORT_NOT_NATIVE_VERIFY';project=$project;prepared_sha256=$preparedSha;verifier_sha256=$verifierSha;project_sha256=$projectSha;fixed_protection_parent_sha256='18eee16cb341f01a984acd1f260dd1511e0e543e0d61b90789cef3f960d5712a';launcher_pid=$PID;engine_pid=$process.Id;started_utc=$started;finished_utc=[DateTime]::UtcNow.ToString('o');elapsed_ms=$timer.ElapsedMilliseconds;actual_natural_console_exit_code=$naturalExit;exit_code_available=($null -ne $naturalExit);retained_process_WaitForExit=$true;process_stopped_by_tool=$false;stdout_path=$stem+'_stdout.log';stdout_sha256=(Sha ($stem+'_stdout.log'));stderr_path=$stem+'_stderr.log';stderr_sha256=(Sha ($stem+'_stderr.log'));protected_first=$protected;protected_final=$protectedAfter;protected_same=$protectedSame;main_two_before=$beforeAbsent;main_two_after=$afterAbsent;main_two_absent=$mainAbsent;main_project_import=$false;media_promotions=0;Field_or_runtime_pass_claim=$false;editor51856_alive=(@(Get-Process -Id 51856 -ErrorAction SilentlyContinue).Count -eq 1)}
NewJson ($stem+'_process_receipt.json') $report
$report|ConvertTo-Json -Depth 4
if($null -eq $naturalExit -or !$protectedSame -or !$mainAbsent){throw 'IMPORT_FINISHED_EVIDENCE_OR_PROTECTION_FAILURE_PRESERVED_NO_RETRY'}
exit $naturalExit
