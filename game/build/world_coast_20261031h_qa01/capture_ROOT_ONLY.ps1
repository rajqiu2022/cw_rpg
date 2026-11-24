param([Parameter(Mandatory=$true)][string]$Scope,[Parameter(Mandatory=$true)][ValidatePattern('^[a-f0-9]{64}$')][string]$ScopeSHA,[string]$OutputName='baseline_NOW_ACTUAL.json')
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'USE_BUNDLED_PWSH7'}
$repo='F:/Code/RPG_GAME';$taskDir=$repo+'/game/build/world_coast_20261031h_qa01'
if([IO.Path]::GetFileName($OutputName) -cne $OutputName -or $OutputName -notmatch '^[A-Za-z0-9_-]+\.json$'){throw 'BASENAME_ONLY'}
$output=$taskDir+'/'+$OutputName
if(Test-Path -LiteralPath $output){throw 'PRESERVE_EXISTING_BASELINE'}
function Hash-Only([string]$p){$s=[IO.File]::OpenRead($p);try{return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($s)).ToLowerInvariant()}finally{$s.Dispose()}}
function Json-Data([string]$p){if($p.Replace('\','/').Contains('/app_userdata/')){throw 'NO_SAVE_DESERIALIZATION'};return [IO.File]::ReadAllText($p,[Text.Encoding]::UTF8)|ConvertFrom-Json -AsHashtable}
function Canonical([string]$p){if($p.StartsWith('res://')){$p=$repo+'/game/'+$p.Substring(6)}elseif(-not [IO.Path]::IsPathRooted($p)){$p=$repo+'/'+$p};return [IO.Path]::GetFullPath($p).Replace('\','/')}
function Metadata([string]$p){$i=Get-Item -LiteralPath $p -ErrorAction SilentlyContinue;if($null -eq $i){return [ordered]@{exists=$false;bytes=$null;utc_ticks=$null;sha256=$null;stable_during_hash=$true}};if($i.PSIsContainer){throw 'FILE_EXPECTED'};$length=[long]$i.Length;$ticks=[string]$i.LastWriteTimeUtc.Ticks;$sha=Hash-Only $p;$j=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;bytes=$length;utc_ticks=$ticks;sha256=$sha;stable_during_hash=($length -eq $j.Length -and $ticks -ceq [string]$j.LastWriteTimeUtc.Ticks)}}
function Same($a,$b){foreach($k in @('exists','bytes','utc_ticks','sha256')){if($a[$k] -cne $b[$k]){return $false}};return $true}
function Engines{return @(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'"|ForEach-Object{[ordered]@{pid=[int]$_.ProcessId;parent_pid=[int]$_.ParentProcessId;command_line=$_.CommandLine;creation_utc=$_.CreationDate.ToUniversalTime().ToString('o')}})}
$scopePath=Canonical $Scope
if(-not $scopePath.StartsWith($taskDir+'/') -or (Hash-Only $scopePath) -cne $ScopeSHA){throw 'EXPLICIT_LOCAL_SCOPE_PIN'}
$scopeData=Json-Data $scopePath;$seedPath=Canonical $scopeData.seed
if((Hash-Only $seedPath) -cne $scopeData.seed_sha256){throw 'SEED_PIN'}
$seed=Json-Data $seedPath
if(-not $seed.passed -or $seed.source_count -ne 2779 -or $seed.save_count -ne 171 -or $seed.expected_absent_save_paths.Count -ne 9){throw 'EXACT31F_SEED_REQUIRED'}
$all=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($field in @('facts','evidence_facts')){foreach($p in $seed[$field].Keys){[void]$all.Add((Canonical $p))}}
foreach($p in $scopeData.current_source_pins.Keys){$entry=$scopeData.current_source_pins[$p];$q=Canonical $p;if((Hash-Only $q) -cne $entry.sha256 -or (Get-Item -LiteralPath $q).Length -ne $entry.bytes){throw ('CURRENT_SOURCE_PIN_CHANGED:'+ $p)};[void]$all.Add($q)}
foreach($p in @($scopePath,$PSCommandPath,$seedPath)){[void]$all.Add((Canonical $p))}

# Bounded exact old resource lookup only; never enumerate game/build trees.
$lookup=[Collections.Generic.Queue[string]]::new();$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($p in $scopeData.dependency_roots){$lookup.Enqueue((Canonical $p))}
while($lookup.Count -gt 0){
 $p=$lookup.Dequeue();if(-not $seen.Add($p)){continue}
 if($seen.Count -gt 2048){throw 'BOUNDED_DEPENDENCY_LOOKUP_OVER2048'}
 if(-not (Test-Path -LiteralPath $p -PathType Leaf)){throw ('DEPENDENCY_MISSING:'+ $p)}
 [void]$all.Add($p)
 $sidecar=$p+'.import';if(Test-Path -LiteralPath $sidecar -PathType Leaf){$lookup.Enqueue($sidecar)}
 if([IO.Path]::GetExtension($p) -notin @('.tres','.import')){continue}
 $content=[IO.File]::ReadAllText($p,[Text.Encoding]::UTF8)
 foreach($m in [regex]::Matches($content,'res://[^"\r\n]+')){
  $ref=Canonical $m.Value
  if((Test-Path -LiteralPath $ref -PathType Leaf) -and $ref.StartsWith($repo+'/game/')){$lookup.Enqueue($ref)}
 }
}

$errors=[Collections.Generic.List[string]]::new();$processBefore=@(Engines)
foreach($row in $processBefore){if($row.pid -ne 51856){$errors.Add('UNEXPECTED_ENGINE_PID:'+ $row.pid)}}
if(@($processBefore|Where-Object pid -eq 51856).Count -ne 1){$errors.Add('EDITOR51856_MISSING')}
$first=[ordered]@{};$second=[ordered]@{};$began=[DateTime]::UtcNow.ToString('o')
foreach($p in ($all|Sort-Object)){$first[$p]=Metadata $p};foreach($p in ($all|Sort-Object)){$second[$p]=Metadata $p}
$sources=0;$saves=0;$historical=@()
foreach($p in $all){
 if($p.Contains('/app_userdata/')){$saves++}else{$sources++}
 if(-not $first[$p].stable_during_hash -or -not $second[$p].stable_during_hash -or -not (Same $first[$p] $second[$p])){$errors.Add('CAPTURE_DRIFT:'+ $p)}
 if($seed.facts.ContainsKey($p) -and -not (Same $seed.facts[$p] $first[$p])){$historical+=@([ordered]@{path=$p;previous31f=$seed.facts[$p];fresh31h=$first[$p];rollback=$false;not_capture_failure=$true})}
}
if($saves -ne 171){$errors.Add('EXACT171_SAVE_PATHS')}
foreach($p in $seed.expected_absent_save_paths){if($first[$p].exists -or $second[$p].exists){$errors.Add('EXPECTED_ABSENT_CHANGED:'+ $p)}}

$backups=[ordered]@{};$backupDir=$taskDir+'/source_backups'
if(Test-Path -LiteralPath $backupDir){throw 'EXISTING_BACKUPS_RETAINED'}
[void][IO.Directory]::CreateDirectory($backupDir)
foreach($path in $scopeData.backup_targets){
 $p=Canonical $path
 if(-not $first.Contains($p) -or $p.Contains('/app_userdata/')){throw 'EXPLICIT_FRESH_SOURCE_BACKUP_ONLY'}
 $dest=$backupDir+'/'+$first[$p].sha256+'_'+[IO.Path]::GetFileName($p)+'.source'
 [IO.File]::Copy($p,$dest,$false);$copied=Metadata $dest;$after=Metadata $p
 if($copied.sha256 -cne $first[$p].sha256 -or $copied.bytes -ne $first[$p].bytes -or -not (Same $first[$p] $after)){$errors.Add('BYTE_BACKUP_NOT_EXACT_FRESH:'+ $p)}
 $backups[$p]=[ordered]@{backup=$dest;backup_fact=$copied;original_fresh_fact=$first[$p];original_after_copy_fact=$after;automatic_restore=$false}
}

$processAfter=@(Engines)
foreach($row in $processAfter){if($row.pid -ne 51856){$errors.Add('UNEXPECTED_ENGINE_AFTER:'+ $row.pid)}}
if(@($processAfter|Where-Object pid -eq 51856).Count -ne 1){$errors.Add('EDITOR51856_MISSING_AFTER')}
$result=[ordered]@{passed=($errors.Count -eq 0);status='FRESH31H_METADATA_ONLY';started_utc=$began;finished_utc=[DateTime]::UtcNow.ToString('o');source_count=$sources;save_count=$saves;facts=$first;second_facts=$second;expected_absent_save_paths=$seed.expected_absent_save_paths;historical_since31f=$historical;errors=$errors.ToArray();source_backups=$backups;bounded_dependency_lookup_count=$seen.Count;scope_path=$scopePath;scope_sha256=$ScopeSHA;seed_sha256=$scopeData.seed_sha256;godot_processes_before=$processBefore;godot_processes_after=$processAfter;all_values_fresh_not_inherited=$true;engine_runs=0;process_control=0;save_deserializations=0;save_writes=0;production_writes=0}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($result|ConvertTo-Json -Depth 18)+[Environment]::NewLine);$file=[IO.File]::Open($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);try{$file.Write($bytes,0,$bytes.Length)}finally{$file.Dispose()}
[ordered]@{passed=$result.passed;source_count=$sources;save_count=$saves;historical_differences=$historical.Count;backup_count=$backups.Count;lookup_count=$seen.Count;errors=$errors.ToArray();report=$output;sha256=(Hash-Only $output)}|ConvertTo-Json -Depth 4
if($errors.Count){exit 1}
