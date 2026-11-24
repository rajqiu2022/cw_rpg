param([Parameter(Mandatory=$true)][string]$ExpectedManifest,[Parameter(Mandatory=$true)][ValidatePattern('^[a-f0-9]{64}$')][string]$ExpectedManifestSHA,[Parameter(Mandatory=$true)][string]$EvidenceManifest,[Parameter(Mandatory=$true)][ValidatePattern('^[a-f0-9]{64}$')][string]$EvidenceManifestSHA,[string]$OutputName='final_guard_ACTUAL.json')
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'USE_BUNDLED_PWSH7'}
$repo='F:/Code/RPG_GAME';$taskDir=$repo+'/game/build/adventure_world_20261031f_qa01'
if([IO.Path]::GetFileName($OutputName) -cne $OutputName -or $OutputName -notmatch '^[A-Za-z0-9_-]+\.json$'){throw 'OUTPUT_BASENAME_ONLY'}
$output=$taskDir+'/'+$OutputName
if(Test-Path -LiteralPath $output){throw 'PRESERVE_EXISTING_REPORT'}
$errors=[Collections.Generic.List[string]]::new()
function Hash-Only([string]$p){$s=[IO.File]::OpenRead($p);try{return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($s)).ToLowerInvariant()}finally{$s.Dispose()}}
function Json-Data([string]$p){if($p.Replace('\','/').Contains('/app_userdata/')){throw 'NO_SAVE_DESERIALIZATION'};return [IO.File]::ReadAllText($p,[Text.Encoding]::UTF8)|ConvertFrom-Json -AsHashtable}
function Canonical([string]$p){if($p.StartsWith('res://')){$p=$repo+'/game/'+$p.Substring(6)}elseif(-not [IO.Path]::IsPathRooted($p)){$p=$repo+'/'+$p};return [IO.Path]::GetFullPath($p).Replace('\','/')}
function Metadata([string]$p){$i=Get-Item -LiteralPath $p -ErrorAction SilentlyContinue;if($null -eq $i){return [ordered]@{exists=$false;bytes=$null;utc_ticks=$null;sha256=$null;stable_during_hash=$true}};if($i.PSIsContainer){throw 'FILE_EXPECTED'};$length=[long]$i.Length;$ticks=[string]$i.LastWriteTimeUtc.Ticks;$sha=Hash-Only $p;$j=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;bytes=$length;utc_ticks=$ticks;sha256=$sha;stable_during_hash=($length -eq $j.Length -and $ticks -ceq [string]$j.LastWriteTimeUtc.Ticks)}}
function Same($a,$b){foreach($k in @('exists','bytes','utc_ticks','sha256')){if($a[$k] -cne $b[$k]){return $false}};return $true}
function Engines{return @(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'"|ForEach-Object{[ordered]@{pid=[int]$_.ProcessId;parent_pid=[int]$_.ParentProcessId;command_line=$_.CommandLine;creation_utc=$_.CreationDate.ToUniversalTime().ToString('o')}})}
function Pin([string]$p,[string]$sha){if((Hash-Only $p) -cne $sha){throw ('EXPLICIT_PIN:'+ $p)}}
$expectedPath=Canonical $ExpectedManifest;$evidencePath=Canonical $EvidenceManifest
if(-not $expectedPath.StartsWith($repo+'/game/build/adventure_world_20261031f_qa01/') -or -not $evidencePath.StartsWith($taskDir+'/')){throw 'EXPECTED_LOCAL_TASK_MANIFESTS_ONLY'}
Pin $expectedPath $ExpectedManifestSHA;Pin $evidencePath $EvidenceManifestSHA
$expected=Json-Data $expectedPath;$evidence=Json-Data $evidencePath
$baselinePath=$taskDir+'/baseline_NOW_ACTUAL.json';Pin $baselinePath $expected.baseline_sha256
$baseline=Json-Data $baselinePath
if(-not $baseline.passed -or $baseline.source_count -ne 2779 -or $baseline.save_count -ne 171 -or $baseline.expected_absent_save_paths.Count -ne 9 -or $expected.authorized_targets.Count -ne 1){throw 'EXACT31F_FRESH_SCOPE_REQUIRED'}
$allowed=@{}
foreach($path in $expected.authorized_targets.Keys){$p=Canonical $path;$entry=$expected.authorized_targets[$path];if(-not $baseline.facts.ContainsKey($p) -or $p.Contains('/app_userdata/') -or -not (Same $baseline.facts[$p] $entry.before_fresh)){throw ('EXACT_FRESH_BEFORE_REQUIRED:'+ $p)};$allowed[$p]=$entry}
$beforeProcess=@(Engines)
foreach($p in $beforeProcess){if($p.pid -ne 51856){$errors.Add('UNEXPECTED_ENGINE:'+ $p.pid)}}
if(@($beforeProcess|Where-Object pid -eq 51856).Count -ne 1){$errors.Add('EDITOR51856_MISSING')}
$first=[ordered]@{};$second=[ordered]@{};$began=[DateTime]::UtcNow.ToString('o')
foreach($p in ($baseline.facts.Keys|Sort-Object)){$first[$p]=Metadata $p}
foreach($p in ($baseline.facts.Keys|Sort-Object)){$second[$p]=Metadata $p}
$changed=@();$sourceCount=0;$saveCount=0
foreach($p in $baseline.facts.Keys){
 if($p.Contains('/app_userdata/')){$saveCount++}else{$sourceCount++}
 if(-not $first[$p].stable_during_hash -or -not $second[$p].stable_during_hash -or -not (Same $first[$p] $second[$p])){$errors.Add('FINAL_DRIFT:'+ $p)}
 if($allowed.ContainsKey($p)){$entry=$allowed[$p];if(-not $first[$p].exists -or $first[$p].sha256 -cne $entry.after_sha256 -or $first[$p].bytes -ne $entry.after_bytes){$errors.Add('AUTHORIZED_AFTER_MISMATCH:'+ $p)};$changed+=@([ordered]@{path=$p;before=$baseline.facts[$p];after=$first[$p]})}
 elseif(-not (Same $baseline.facts[$p] $first[$p])){$errors.Add('UNAUTHORIZED_METADATA_CHANGE:'+ $p)}
}
foreach($p in $baseline.expected_absent_save_paths){if($first[$p].exists -or $second[$p].exists){$errors.Add('EXPECTED_ABSENT_CHANGED:'+ $p)}}
$evidenceFirst=[ordered]@{};$evidenceSecond=[ordered]@{}
foreach($path in $evidence.pins.Keys){$p=Canonical $path;if($p.Contains('/app_userdata/')){throw 'EVIDENCE_NOT_SAVE'};$evidenceFirst[$p]=Metadata $p}
foreach($path in $evidence.pins.Keys){$p=Canonical $path;$evidenceSecond[$p]=Metadata $p;if(-not $evidenceFirst[$p].exists -or $evidenceFirst[$p].sha256 -cne $evidence.pins[$path] -or -not $evidenceFirst[$p].stable_during_hash -or -not $evidenceSecond[$p].stable_during_hash -or -not (Same $evidenceFirst[$p] $evidenceSecond[$p])){$errors.Add('EVIDENCE_PIN_OR_DRIFT:'+ $p)}}
$afterProcess=@(Engines)
foreach($p in $afterProcess){if($p.pid -ne 51856){$errors.Add('UNEXPECTED_ENGINE_AFTER:'+ $p.pid)}}
if(@($afterProcess|Where-Object pid -eq 51856).Count -ne 1){$errors.Add('EDITOR51856_MISSING_AFTER')}
$result=[ordered]@{passed=($errors.Count -eq 0);status='FINAL31F_ONE_PRECISE_SOURCE_CHANGE_METADATA_ONLY';started_utc=$began;finished_utc=[DateTime]::UtcNow.ToString('o');baseline_sha256=$expected.baseline_sha256;expected_manifest_sha256=$ExpectedManifestSHA;evidence_manifest_sha256=$EvidenceManifestSHA;source_count=$sourceCount;save_count=$saveCount;expected_absent_save_paths=$baseline.expected_absent_save_paths;facts=$first;second_facts=$second;authorized_changes=$changed;evidence_facts=$evidenceFirst;evidence_second_facts=$evidenceSecond;historical_since31e_retained_not_current_drift=$baseline.historical_since31e;errors=$errors.ToArray();godot_processes_before=$beforeProcess;godot_processes_after=$afterProcess;engine_runs=0;process_control=0;save_deserializations=0;save_writes=0;production_writes=0}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($result|ConvertTo-Json -Depth 18)+[Environment]::NewLine);$file=[IO.File]::Open($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);try{$file.Write($bytes,0,$bytes.Length)}finally{$file.Dispose()}
[ordered]@{passed=$result.passed;source_count=$sourceCount;save_count=$saveCount;authorized_count=$changed.Count;evidence_count=$evidenceFirst.Count;historical_differences_retained=$baseline.historical_since31e.Count;errors=$errors.ToArray();report=$output;sha256=(Hash-Only $output)}|ConvertTo-Json -Depth 4
if($errors.Count){exit 1}
