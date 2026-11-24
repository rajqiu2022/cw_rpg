$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'USE_BUNDLED_PWSH7'}
$repo='F:/Code/RPG_GAME';$dir=$repo+'/game/build/world_coast_20261031h_qa01';$baselinePath=$dir+'/baseline_NOW_ACTUAL.json';$targetsPath=$repo+'/game/build/world_coast_20261031h_system03/template/finite_old_targets.json';$output=$dir+'/protected37_supplement_ACTUAL.json';$backupDir=$dir+'/source_backups03'
if((Test-Path -LiteralPath $output) -or (Test-Path -LiteralPath $backupDir)){throw 'PRESERVE_EXISTING_SUPPLEMENT'}
function Hash-Only([string]$p){$s=[IO.File]::OpenRead($p);try{return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($s)).ToLowerInvariant()}finally{$s.Dispose()}}
function Canonical([string]$p){if($p.StartsWith('res://')){$p=$repo+'/game/'+$p.Substring(6)}elseif(-not [IO.Path]::IsPathRooted($p)){$p=$repo+'/'+$p};return [IO.Path]::GetFullPath($p).Replace('\','/')}
function Metadata([string]$p){if($p.Contains('/app_userdata/')){throw 'SUPPLEMENT_NOT_SAVES'};$i=Get-Item -LiteralPath $p;$size=[long]$i.Length;$ticks=[string]$i.LastWriteTimeUtc.Ticks;$sha=Hash-Only $p;$after=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;bytes=$size;utc_ticks=$ticks;sha256=$sha;stable_during_hash=($size -eq $after.Length -and $ticks -ceq [string]$after.LastWriteTimeUtc.Ticks)}}
function Same($a,$b){foreach($k in @('exists','bytes','utc_ticks','sha256')){if($a[$k] -cne $b[$k]){return $false}};return $true}
if((Hash-Only $baselinePath) -cne '268843b011520163f8ce34e72473826b1071e22b703d2d8bdab868c25c261ea5'){throw 'FIRST3221_BASELINE_PIN'}
if((Hash-Only $targetsPath) -cne '37c51e4ecc10731a3c688c27e9ca32ae76f86478fb78bd9de39220372932c3b0'){throw 'EXACT37_TARGET_LIST_PIN'}
$baseline=[IO.File]::ReadAllText($baselinePath,[Text.Encoding]::UTF8)|ConvertFrom-Json -AsHashtable;$targets=[IO.File]::ReadAllText($targetsPath,[Text.Encoding]::UTF8)|ConvertFrom-Json -AsHashtable
if(-not $baseline.passed -or $baseline.source_count -ne 3221 -or $targets.paths.Count -ne 37 -or $baseline.source_backups.Count -ne 20){throw 'EXACT_BASELINE_AND_SCOPE_REQUIRED'}
$paths=@($targets.paths|ForEach-Object{Canonical $_}|Sort-Object -Unique)
if($paths.Count -ne 37){throw 'UNIQUE37_REQUIRED'}
$first=[ordered]@{};$second=[ordered]@{};$errors=[Collections.Generic.List[string]]::new();$started=[DateTime]::UtcNow.ToString('o')
foreach($p in $paths){$first[$p]=Metadata $p};foreach($p in $paths){$second[$p]=Metadata $p}
$coverage=[ordered]@{};$existing=[ordered]@{};$needed=@()
foreach($p in $paths){
 if(-not $first[$p].stable_during_hash -or -not $second[$p].stable_during_hash -or -not (Same $first[$p] $second[$p])){$errors.Add('FRESH37_DRIFT:'+ $p)}
 $covered=$baseline.facts.ContainsKey($p);$coverage[$p]=$covered
 if($covered -and -not(Same $baseline.facts[$p] $first[$p])){$errors.Add('UNAUTHORIZED_CHANGE_SINCE3221:'+ $p)}
 if($baseline.source_backups.ContainsKey($p)){
  $entry=$baseline.source_backups[$p];$copy=Metadata $entry.backup
  if($copy.sha256 -cne $first[$p].sha256 -or $copy.bytes -ne $first[$p].bytes){$errors.Add('EXISTING_BACKUP_BYTES_DIFFER:'+ $p)}
  $existing[$p]=[ordered]@{backup=$entry.backup;fact=$copy}
 }else{$needed+=@($p)}
}
if($errors.Count -eq 0){[void][IO.Directory]::CreateDirectory($backupDir)}
$new=[ordered]@{}
if($errors.Count -eq 0){foreach($p in $needed){$dest=$backupDir+'/'+$first[$p].sha256+'_'+[IO.Path]::GetFileName($p)+'.source';[IO.File]::Copy($p,$dest,$false);$copy=Metadata $dest;$after=Metadata $p;if($copy.sha256 -cne $first[$p].sha256 -or $copy.bytes -ne $first[$p].bytes -or -not(Same $first[$p] $after)){$errors.Add('NEW_BACKUP_NOT_FRESH_EXACT:'+ $p)};$new[$p]=[ordered]@{backup=$dest;backup_fact=$copy;original_after_copy=$after}}}
$result=[ordered]@{passed=($errors.Count -eq 0);status='FRESH37_TARGET_ONLY_SUPPLEMENT_NO_FORMAL_WRITE';started_utc=$started;finished_utc=[DateTime]::UtcNow.ToString('o');first_baseline_sha256='268843b011520163f8ce34e72473826b1071e22b703d2d8bdab868c25c261ea5';target_list_sha256='37c51e4ecc10731a3c688c27e9ca32ae76f86478fb78bd9de39220372932c3b0';target_count=37;facts=$first;second_facts=$second;first_baseline_coverage=$coverage;existing_backup_count=$existing.Count;new_backup_count=$new.Count;existing_backups=$existing;new_backups=$new;errors=$errors.ToArray();first_baseline_unchanged=((Hash-Only $baselinePath) -ceq '268843b011520163f8ce34e72473826b1071e22b703d2d8bdab868c25c261ea5');whole3221_rehash=0;history12382_rehash=0;engine_runs=0;process_control=0;save_APIs=0;production_writes=0;automatic_restore=$false}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($result|ConvertTo-Json -Depth 14)+[Environment]::NewLine);$f=[IO.File]::Open($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);try{$f.Write($bytes,0,$bytes.Length)}finally{$f.Dispose()}
[ordered]@{passed=$result.passed;target_count=37;baseline_coverage=@($coverage.Values|Where-Object{$_}).Count;existing_backups=$existing.Count;new_backups=$new.Count;errors=$errors.ToArray();report=$output;sha256=(Hash-Only $output)}|ConvertTo-Json -Depth 4
if($errors.Count){exit 1}
