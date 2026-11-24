$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'USE_BUNDLED_PWSH7'}
$dir='F:/Code/RPG_GAME/game/build/world_bridges_20261030m_qa01'
$firstPath=$dir+'/baseline_NOW_ACTUAL.json'
$previousPath='F:/Code/RPG_GAME/game/build/gather_actions_20261030l_root01/final_guard_ACTUAL.json'
$output=$dir+'/absence_residual_ACTUAL.json'
if(Test-Path -LiteralPath $output){throw 'RESIDUAL_ALREADY_EXISTS_RETAIN_FIRST'}
function Hash-Only([string]$path){
 $stream=[IO.File]::OpenRead($path);$algorithm=[Security.Cryptography.SHA256]::Create()
 try{return ([BitConverter]::ToString($algorithm.ComputeHash($stream))).Replace('-','').ToLowerInvariant()}
 finally{$algorithm.Dispose();$stream.Dispose()}
}
function Metadata([string]$path){
 $item=Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
 if($null -eq $item){return [ordered]@{exists=$false;bytes=$null;utc_ticks=$null;sha256=$null;stable_during_hash=$true}}
 $length=[long]$item.Length;$ticks=[string]$item.LastWriteTimeUtc.Ticks
 $hash=Hash-Only $path;$after=Get-Item -LiteralPath $path
 return [ordered]@{exists=$true;bytes=$length;utc_ticks=$ticks;sha256=$hash;stable_during_hash=($length -eq $after.Length -and $ticks -ceq [string]$after.LastWriteTimeUtc.Ticks)}
}
function Same-Metadata($before,$after){
 foreach($key in @('exists','bytes','utc_ticks','sha256')){if($before[$key] -cne $after[$key]){return $false}}
 return $true
}
function Inventory-Only {
 return @(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'" | Select-Object ProcessId,ParentProcessId,Name,ExecutablePath,CommandLine,CreationDate)
}
$firstSha=Hash-Only $firstPath
if($firstSha -cne '1bd4f781041d605de01148a2528416c6ce0333cc356fa396df98d7a81f75df23'){throw 'EXACT_FIRST_WHOLE_FAIL_REQUIRED'}
if((Hash-Only $previousPath) -cne '1f0866761e828dfd88dde6ae1d3f8c825f47cfbf074508e7559b61ecd83198d9'){throw 'EXACT_PATH_SEED_REFERENCE_REQUIRED'}
# These are QA metadata reports, not player save JSON deserialization.
$first=Get-Content -LiteralPath $firstPath -Raw -Encoding utf8 | ConvertFrom-Json -AsHashtable
$previous=Get-Content -LiteralPath $previousPath -Raw -Encoding utf8 | ConvertFrom-Json -AsHashtable
if($first.passed -ne $false -or $first.errors.Count -ne 9 -or $first.source_count -ne 600 -or $first.save_count -ne 171){throw 'EXACT_FIRST_FAIL_COUNTS_REQUIRED'}
if($first.source_drift_during_capture.Count -ne 0 -or $first.save_drift_during_capture.Count -ne 0){throw 'NOT_AN_ABSENCE_ONLY_RESIDUAL'}
$errors=[Collections.Generic.List[string]]::new()
$exactAbsent=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($message in $first.errors){
 if(-not $message.StartsWith('EXPECTED_FILE_MISSING:')){throw 'UNKNOWN_FIRST_ERROR_REQUIRES_NEW_AUTHORITY'}
 $path=$message.Substring('EXPECTED_FILE_MISSING:'.Length)
 if(-not $path.StartsWith('C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/',[StringComparison]::OrdinalIgnoreCase)){throw 'ONLY_EXACT_SAVE_ABSENCE_ERRATUM_ALLOWED'}
 if(-not $previous.facts.Contains($path) -or $previous.facts[$path].exists -ne $false -or $first.facts[$path].exists -ne $false -or $first.second_facts[$path].exists -ne $false){throw ('NOT_PREEXISTING_EXPECTED_ABSENCE:'+ $path)}
 [void]$exactAbsent.Add($path)
}
if($exactAbsent.Count -ne 9){throw 'EXACT_NINE_UNIQUE_ABSENT_PATHS_REQUIRED'}
$processBefore=@(Inventory-Only)
if($processBefore.Count -ne 1 -or $processBefore[0].ProcessId -ne 51856){$errors.Add('ONLY_EDITOR51856_REQUIRED_BEFORE')}
$fresh=[ordered]@{};$absentRows=@();$saveRows=0;$present=0
foreach($path in ($first.facts.Keys | Sort-Object)){
 if(-not $path.StartsWith('C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/',[StringComparison]::OrdinalIgnoreCase)){continue}
 # Only the 171 save metadata paths are fresh-read; no 600-source rehash.
 $saveRows+=1;$now=Metadata $path;$fresh[$path]=$now
 if($now.exists){$present+=1}
 if(-not $now.stable_during_hash -or -not (Same-Metadata $first.facts[$path] $now)){$errors.Add('SAVE_METADATA_CHANGED_SINCE_FIRST:'+ $path)}
 if($exactAbsent.Contains($path)){
  $absentRows+=@([ordered]@{path=$path;old_path_seed_exists=$previous.facts[$path].exists;first_exists=$first.facts[$path].exists;first_second_exists=$first.second_facts[$path].exists;now_exists=$now.exists;only_erratum='EXPECTED_ABSENCE_IS_NOT_MISSING_REQUIRED_FILE'})
  if($now.exists){$errors.Add('EXPECTED_ABSENT_NOW_APPEARED:'+ $path)}
 }elseif(-not $now.exists){$errors.Add('NEW_UNKNOWN_ABSENCE_NOT_PERMITTED:'+ $path)}
}
if($saveRows -ne 171 -or $present -ne 162){$errors.Add('EXACT171_PATHS_162_PRESENT9_EXPECTED_ABSENT_REQUIRED')}
if((Hash-Only $firstPath) -cne $firstSha){$errors.Add('FIRST_REPORT_CHANGED_MUST_RETAIN_ORIGINAL_FAIL')}
$processAfter=@(Inventory-Only)
if($processAfter.Count -ne 1 -or $processAfter[0].ProcessId -ne 51856){$errors.Add('ONLY_EDITOR51856_REQUIRED_AFTER')}
$result=[ordered]@{
 status='ABSENCE_ONLY_RESIDUAL_NOT_RECAPTURE_OR_REBASE';residual_passed=($errors.Count -eq 0)
 original_whole_FAIL_preserved=$true;first_report=$firstPath;first_sha256=$firstSha;first_passed=$first.passed;first_errors_retained=$first.errors
 source600_fresh_read_again=0;source600_first_success_inherited_only=$true;first171_double_read_inherited_only=$true
 exact_expected_absence9=$absentRows;fresh171_save_metadata=$fresh;fresh_save_paths=$saveRows;fresh_present_save_files=$present
 all171_same_first_SHA_bytes_UTCticks=($errors.Count -eq 0);historical2_reference_diffs_retained=$first.historical_since_30l_reference
 errors=$errors.ToArray();godot_before=$processBefore;godot_after=$processAfter
 engine_runs=0;process_control=0;production_writes=0;save_deserializations=0;save_writes=0
}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($result | ConvertTo-Json -Depth 12)+[Environment]::NewLine)
$file=[IO.File]::Open($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
try{$file.Write($bytes,0,$bytes.Length)}finally{$file.Dispose()}
[ordered]@{residual_passed=$result.residual_passed;expected_absent=$exactAbsent.Count;save_paths=$saveRows;present=$present;errors=$errors.ToArray();report=$output;sha256=(Hash-Only $output);first_FAIL_preserved=$true} | ConvertTo-Json -Depth 4
if($errors.Count -gt 0){exit 1}
