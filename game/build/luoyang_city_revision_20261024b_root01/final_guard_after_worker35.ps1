$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$game='F:/Code/RPG_GAME/game'
$taskDir="$game/build/luoyang_city_revision_20261024b_root01"
function Hash([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function Local([string]$p){if(!$p.StartsWith('res://') -or $p.Contains('..')){throw 'RES_DOMAIN'};Join-Path $game $p.Substring(6)}
$stagePath="$game/build/luoyang_city_space_20261024b_source01/outputs/root_market_worker_facts_exact35_stage01/receipt.json"
if((Hash $stagePath) -cne 'af129e34538479d7aaae3a1e87e7194d44fc52354ec44de9dcd41a77eecadd0c'){throw 'STAGE_CHANGED'}
$s=Get-Content -LiteralPath $stagePath -Raw|ConvertFrom-Json -AsHashtable
$allowed=@{};foreach($r in $s.targets){$allowed[(Local $r.target)]=$r.candidate_sha256;if((Hash (Local $r.target)) -cne $r.candidate_sha256){throw "CURRENT36_CHANGED:$($r.target)"}}
$allowed[(Local 'res://scripts/ui/dialog_box.gd')]='fe8165682670f7bcc5689d963b456f5d9503ba7f6abece575ad4f04e82c9c337'
if((Hash (Local 'res://scripts/ui/dialog_box.gd')) -cne $allowed[(Local 'res://scripts/ui/dialog_box.gd')]){throw 'UI_DRIFT'}
$backup=Get-Content -LiteralPath "$taskDir/predeploy36/backup_receipt.json" -Raw|ConvertFrom-Json -AsHashtable
foreach($r in $backup.records){if((Hash $r.backup_path) -cne $r.sha256){throw 'ORIGINAL_BACKUP_CHANGED'}}
$nextBackup=Get-Content -LiteralPath "$taskDir/worker_facts_predeploy35/backup_receipt.json" -Raw|ConvertFrom-Json -AsHashtable
foreach($r in $nextBackup.records){if((Hash $r.backup_path) -cne $r.sha256){throw 'WORKER35_BACKUP_CHANGED'}}
$source=0
foreach($p in $s.source_first.Keys){$disk=Local $p;$expected=if($allowed.ContainsKey($disk)){$allowed[$disk]}else{$s.source_first[$p]};if((Hash $disk) -cne $expected){throw "DECLARED_SOURCE_DRIFT:$p"};$source++}
$freshPath="$taskDir/after_native_import_before_deploy.json"
if((Hash $freshPath) -cne '667a957c8dd19147225bd2edabfb91a870ea81646fb01bad61373d48452a35a2'){throw 'FRESH_CHANGED'}
$fresh=Get-Content -LiteralPath $freshPath -Raw|ConvertFrom-Json -AsHashtable
$same=0;$changes=@();$saves=0
foreach($f in $fresh.facts){
 $p=[string]$f.path;$exists=Test-Path -LiteralPath $p
 if($allowed.ContainsKey($p)){
  if(!$exists -or (Hash $p) -cne $allowed[$p]){throw 'AUTHORIZED_TARGET_MISMATCH'}
  $changes+=@{path=$p;old_sha256=$f.sha256;new_sha256=$allowed[$p]};continue
 }
 if($exists -ne $f.exists){throw "EXISTENCE_CHANGED:$p"}
 if($exists){$i=Get-Item -LiteralPath $p;if((Hash $p) -cne $f.sha256 -or $i.Length -ne $f.bytes -or [string]$i.LastWriteTimeUtc.Ticks -cne $f.ticks){throw "UNAUTHORIZED_FACT_CHANGED:$p"}}
 $same++;if($p -in $fresh.save_paths){$saves++}
}
if($fresh.facts.Count -ne 2120 -or $saves -ne 15 -or $allowed.Count -ne 36){throw 'DOMAIN_COUNTS'}
$out="$taskDir/final_guard_after_worker35_actual.json"
$report=@{status='EXACT36_FINAL_GUARD_FROM_FIXED_STAGE_AND_LATEST_PREDEPLOY_PROTECTION';passed=$true;existing_protected=2120;authorized_existing_changes=$changes;unchanged_facts=$same;all36_current_expected=$true;all36_backups_original=$true;stage_source_files_checked=$source;latest15saves_exact_sha_bytes_ticks=$true;save_comparison='Against latest667A only; original earlier two save changes preserved and not attributed';UI_extra_target_separately_in36=$true;editor_not_stopped=$true}
$stream=[IO.File]::Open($out,[IO.FileMode]::CreateNew);$writer=[IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($false))
try{$writer.Write(($report|ConvertTo-Json -Depth 8)+"`n")}finally{$writer.Dispose()}
@{path=$out;sha256=(Hash $out);checked=$source;unchanged=$same;authorized=$changes.Count;saves=$saves;passed=$true}|ConvertTo-Json -Compress
