param([Parameter(Mandatory=$true)][string]$ReceiptPath,[Parameter(Mandatory=$true)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$ReceiptSHA,[Parameter(Mandatory=$true)][string]$EvidencePath,[Parameter(Mandatory=$true)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$EvidenceSHA,[ValidatePattern('^[A-Za-z0-9_-]+\.json$')][string]$OutputName='final_guard38_ACTUAL.json')
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'USE_PWSH7'}
$repo='F:/Code/RPG_GAME';$qa=$repo+'/game/build/world_coast_20261031h_qa01';$output=$qa+'/'+$OutputName
if(Test-Path -LiteralPath $output){throw 'PRESERVE_EXISTING_REPORT'}
function Hash-Only([string]$p){$s=[IO.File]::OpenRead($p);try{return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($s)).ToLowerInvariant()}finally{$s.Dispose()}}
function Canonical([string]$p){if($p.StartsWith('res://')){$p=$repo+'/game/'+$p.Substring(6)}elseif(-not [IO.Path]::IsPathRooted($p)){$p=$repo+'/'+$p};return [IO.Path]::GetFullPath($p).Replace('\','/')}
function Json-Data([string]$p){if($p.Contains('/app_userdata/')){throw 'NO_SAVE_DESERIALIZATION'};return [IO.File]::ReadAllText($p,[Text.Encoding]::UTF8)|ConvertFrom-Json -AsHashtable}
function Metadata([string]$p){$i=Get-Item -LiteralPath $p -ErrorAction SilentlyContinue;if($null -eq $i){return [ordered]@{exists=$false;bytes=$null;utc_ticks=$null;sha256=$null;stable_during_hash=$true}};if($i.PSIsContainer){throw 'FILE_ONLY'};$length=[long]$i.Length;$ticks=[string]$i.LastWriteTimeUtc.Ticks;$sha=Hash-Only $p;$j=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;bytes=$length;utc_ticks=$ticks;sha256=$sha;stable_during_hash=($length -eq $j.Length -and $ticks -ceq [string]$j.LastWriteTimeUtc.Ticks)}}
function Same($a,$b){foreach($k in @('exists','bytes','utc_ticks','sha256')){if($a[$k] -cne $b[$k]){return $false}};return $true}
function Pin([string]$p,[string]$sha){if((Hash-Only $p) -cne $sha.ToLowerInvariant()){throw ('EXACT_PIN:'+ $p)}}
function Engines{return @(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'"|ForEach-Object{[ordered]@{pid=[int]$_.ProcessId;parent_pid=[int]$_.ParentProcessId;command_line=$_.CommandLine}})}
$receiptFull=Canonical $ReceiptPath;$evidenceFull=Canonical $EvidencePath
if((-not $receiptFull.StartsWith($repo+'/game/build/world_coast_20261031h_system04/') -and -not $receiptFull.StartsWith($qa+'/')) -or -not $evidenceFull.StartsWith($qa+'/')){throw 'EXACT_TASK_LOCAL_CUMULATIVE_MANIFESTS_ONLY'}
Pin $receiptFull $ReceiptSHA;Pin $evidenceFull $EvidenceSHA
$receipt=Json-Data $receiptFull;$evidence=Json-Data $evidenceFull
$basePath=$qa+'/baseline_NOW_ACTUAL.json';$suppPath=$qa+'/protected37_supplement_ACTUAL.json';$priorPath=$repo+'/game/build/world_coast_20261031h_system03/sealed_candidate03/receipt_REVIEW_ONLY.json'
Pin $basePath '268843b011520163f8ce34e72473826b1071e22b703d2d8bdab868c25c261ea5';Pin $suppPath '00e20df22fa10c8714d46f56cc101349fd5ab533dbb6ca11e08c269e2e05df48';Pin $priorPath '8e61ae93e1b11e51d983300fe64ad3dd651ff1515d972df2ff8f19ac484a43ef'
$base=Json-Data $basePath;$supp=Json-Data $suppPath;$prior=Json-Data $priorPath
if(-not $base.passed -or $base.source_count -ne 3221 -or $base.save_count -ne 171 -or $base.expected_absent_save_paths.Count -ne 9 -or -not $supp.passed -or $supp.target_count -ne 37 -or $prior.target_count -ne 37 -or $prior.targets.Count -ne 37 -or $receipt.target_count -ne 38 -or $receipt.targets.Count -ne 38){throw 'EXACT_FRESH3221_171_9_ORIGINAL37_CUMULATIVE38_REQUIRED'}
$facts=@{};foreach($p in $base.facts.Keys){$facts[$p]=$base.facts[$p]}
foreach($p in $supp.facts.Keys){if($facts.ContainsKey($p) -and -not(Same $facts[$p] $supp.facts[$p])){throw 'SUPPLEMENT_BASE_DISAGREES'};$facts[$p]=$supp.facts[$p]}
if($facts.Count -ne (3221+14+171)){throw 'EXACT3221_PLUS14_PLUS171_FACTS_REQUIRED'}
$original=@{}
foreach($entry in $prior.targets){$p=Canonical $entry.path;if($original.ContainsKey($p) -or -not $supp.facts.ContainsKey($p) -or $entry.before_sha256 -cne $supp.facts[$p].sha256 -or $entry.before_bytes -ne $supp.facts[$p].bytes){throw 'PRIOR37_ORIGINAL_FRESH_MISMATCH'};$original[$p]=$entry}
$coord=Canonical 'res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd'
if($original.ContainsKey($coord) -or -not $base.facts.ContainsKey($coord) -or $base.facts[$coord].sha256 -cne '2e57ca4fbb377925e70f86ca4c65f5138f946f123ac661cc31c1262953214c71' -or $base.facts[$coord].bytes -ne 36279){throw 'COORDINATOR_ORIGINAL_BASELINE3221_REQUIRED'}
$original[$coord]=[ordered]@{before_sha256=$base.facts[$coord].sha256;before_bytes=$base.facts[$coord].bytes}
$allowed=@{}
foreach($entry in $receipt.targets){$p=Canonical $entry.path;if($allowed.ContainsKey($p) -or -not $original.ContainsKey($p) -or -not $facts.ContainsKey($p) -or $entry.before_sha256 -cne $original[$p].before_sha256 -or $entry.before_bytes -ne $original[$p].before_bytes -or $entry.before_sha256 -cne $facts[$p].sha256 -or $entry.before_bytes -ne $facts[$p].bytes -or $entry.candidate_sha256 -cnotmatch '^[a-f0-9]{64}$' -or $entry.candidate_bytes -le 0){throw 'EXACT38_ORIGINAL_BEFORE_NOT_SYSTEM04_INTERMEDIATE_REQUIRED'};$allowed[$p]=$entry}
if($allowed.Count -ne 38){throw 'EXACT38_UNION_REQUIRED'}
$errors=[Collections.Generic.List[string]]::new();$processBefore=@(Engines)
foreach($engine in $processBefore){if($engine.pid -ne 51856){$errors.Add('UNEXPECTED_ENGINE:'+ $engine.pid)}}
if(@($processBefore|Where-Object pid -eq 51856).Count -ne 1){$errors.Add('EDITOR51856_MISSING')}
$first=[ordered]@{};$second=[ordered]@{};$changed=@();$sourceCount=0;$saveCount=0;$began=[DateTime]::UtcNow.ToString('o')
foreach($p in ($facts.Keys|Sort-Object)){$first[$p]=Metadata $p}
foreach($p in ($facts.Keys|Sort-Object)){$second[$p]=Metadata $p}
foreach($p in $facts.Keys){
 if($p.Contains('/app_userdata/')){$saveCount++}else{$sourceCount++}
 if(-not $first[$p].stable_during_hash -or -not $second[$p].stable_during_hash -or -not(Same $first[$p] $second[$p])){$errors.Add('FINAL_DRIFT:'+ $p)}
 if($allowed.ContainsKey($p)){$entry=$allowed[$p];if(-not $first[$p].exists -or $first[$p].sha256 -cne $entry.candidate_sha256 -or $first[$p].bytes -ne $entry.candidate_bytes){$errors.Add('AUTHORIZED38_AFTER_MISMATCH:'+ $p)};$changed+=@([ordered]@{path=$p;before=$facts[$p];after=$first[$p]})}
 elseif(-not(Same $facts[$p] $first[$p])){$errors.Add('UNAUTHORIZED_METADATA_CHANGE:'+ $p)}
}
if($sourceCount -ne 3235 -or $saveCount -ne 171){$errors.Add('FINAL_COUNTS_NOT_3235_171')}
foreach($p in $base.expected_absent_save_paths){if($first[$p].exists -or $second[$p].exists){$errors.Add('EXPECTED_ABSENT_CHANGED:'+ $p)}}
$pins=@{}
foreach($map in @($receipt.new_snapshot_pins,$receipt.new_code_pins,$receipt.explicit_world_proof_pins,$evidence.pins)){foreach($path in $map.Keys){$p=Canonical $path;if($p.Contains('/app_userdata/')){throw 'EVIDENCE_NOT_SAVE'};if($pins.ContainsKey($p) -and $pins[$p] -cne $map[$path]){throw 'INCONSISTENT_EVIDENCE_PIN'};$pins[$p]=$map[$path]}}
$evidenceFacts=[ordered]@{}
foreach($p in ($pins.Keys|Sort-Object)){$actual=Metadata $p;$again=Metadata $p;$evidenceFacts[$p]=$actual;if(-not $actual.exists -or $actual.sha256 -cne $pins[$p] -or -not $actual.stable_during_hash -or -not(Same $actual $again)){$errors.Add('EVIDENCE_PIN_OR_DRIFT:'+ $p)}}
$backups=[ordered]@{}
foreach($map in @($base.source_backups,$supp.existing_backups,$supp.new_backups)){foreach($p in $map.Keys){$entry=$map[$p];$bp=[string]$entry.backup;if($backups.Contains($bp)){continue};$actual=Metadata $bp;$backups[$bp]=$actual;if(-not(Same $entry.backup_fact $actual)){$errors.Add('BACKUP_METADATA_CHANGED:'+ $bp)}}}
$processAfter=@(Engines)
foreach($engine in $processAfter){if($engine.pid -ne 51856){$errors.Add('UNEXPECTED_ENGINE_AFTER:'+ $engine.pid)}}
if(@($processAfter|Where-Object pid -eq 51856).Count -ne 1){$errors.Add('EDITOR51856_MISSING_AFTER')}
$result=[ordered]@{passed=($errors.Count -eq 0);status='FINAL31H_EXACT_CUMULATIVE38_ORIGINAL_BEFORE_AND_NEW04_PROOFS_ONLY';started_utc=$began;finished_utc=[DateTime]::UtcNow.ToString('o');source_count=$sourceCount;save_count=$saveCount;first_baseline_source_count=3221;supplement_new_source_count=14;coordinator_origin='ORIGINAL_BASELINE3221_NOT_37SUPPLEMENT_OR04INTERMEDIATE';prior37_receipt_path=$priorPath;prior37_receipt_sha256='8e61ae93e1b11e51d983300fe64ad3dd651ff1515d972df2ff8f19ac484a43ef';expected_absent_save_paths=$base.expected_absent_save_paths;authorized_changes=$changed;facts=$first;second_facts=$second;evidence_facts=$evidenceFacts;backup_facts=$backups;receipt_path=$receiptFull;receipt_sha256=$ReceiptSHA.ToLowerInvariant();evidence_path=$evidenceFull;evidence_sha256=$EvidenceSHA.ToLowerInvariant();historical_since31f_retained=$base.historical_since31f;errors=$errors.ToArray();godot_processes_before=$processBefore;godot_processes_after=$processAfter;engine_runs=0;process_control=0;save_deserializations=0;save_writes=0;production_writes=0;automatic_restore=$false}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($result|ConvertTo-Json -Depth 18)+[Environment]::NewLine);$f=[IO.File]::Open($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);try{$f.Write($bytes,0,$bytes.Length)}finally{$f.Dispose()}
[ordered]@{passed=$result.passed;source_count=$sourceCount;save_count=$saveCount;authorized_count=$changed.Count;evidence_count=$pins.Count;backup_count=$backups.Count;errors=$errors.ToArray();report=$output;sha256=(Hash-Only $output)}|ConvertTo-Json -Depth 4
if($errors.Count){exit 1}
