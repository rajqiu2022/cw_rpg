$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$game='F:/Code/RPG_GAME/game'
$taskDir="$game/build/luoyang_city_revision_20261024b_root01"
function Hash([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function Local([string]$p){if(!$p.StartsWith('res://') -or $p.Contains('..')){throw 'RES_DOMAIN'};[IO.Path]::GetFullPath((Join-Path $game $p.Substring(6)))}
$pins=@(
 @('res://build/luoyang_city_space_20261024b_source01/outputs/root_market_dialogue_exact36_stage02/receipt.json','516c535b908d5fb22d8620311431e2c1e8a13d01b4f0289d7d81732f4aeefd8c'),
 @('res://build/luoyang_city_space_20261024b_source01/outputs/root_market_worker_facts_exact35_stage01/receipt.json','af129e34538479d7aaae3a1e87e7194d44fc52354ec44de9dcd41a77eecadd0c'),
 @('res://build/luoyang_city_space_20261024b_source01/outputs/root_C_packed_exact27_stage01/receipt.json','91a1e5d25a596436066f508a6ac13cc4518125a88a1c271aae8061e5024423ed'),
 @('res://build/luoyang_city_space_20261024b_source01/outputs/root_ENV_texture_union_exact18_stage02/receipt.json','a7f8ce3a8b54cf78e3fe836c39ebab8ddb8e8f3ec58a53b6f6a2e6edf946ead6')
)
$stages=@();$allowed=@{}
foreach($pin in $pins){
 $p=Local $pin[0];if((Hash $p) -cne $pin[1]){throw 'FIXED_STAGE_CHANGED'}
 $s=Get-Content -Raw -LiteralPath $p|ConvertFrom-Json -AsHashtable;$stages+=$s
 foreach($r in $s.targets){$disk=Local $r.target;if($allowed.ContainsKey($disk) -and $allowed[$disk] -cne $r.old_sha256){throw 'SUCCESSOR_TARGET_EDGE_MISMATCH'};$allowed[$disk]=$r.candidate_sha256}
}
if($allowed.Count -ne 36){throw 'EXACT_UNION36_TARGETS'}
foreach($p in $allowed.Keys){if((Hash $p) -cne $allowed[$p]){throw "CANONICAL_TARGET_DRIFT:$p"}}
$expected=@{}
foreach($s in $stages){foreach($p in $s.source_first.Keys){
 $disk=Local $p;$h=if($allowed.ContainsKey($disk)){$allowed[$disk]}else{$s.source_first[$p]}
 if($expected.ContainsKey($disk) -and $expected[$disk] -cne $h){throw "IMMUTABLE_SOURCE_CONFLICT:$p"};$expected[$disk]=$h
}}
foreach($p in $expected.Keys){if((Hash $p) -cne $expected[$p]){throw "SOURCE_DRIFT:$p"}}
$backups=0
foreach($dir in @('predeploy36','worker_facts_predeploy35','packed_predeploy27','env_predeploy18')){
 $b=Get-Content -Raw -LiteralPath "$taskDir/$dir/backup_receipt.json"|ConvertFrom-Json -AsHashtable
 foreach($r in $b.records){if((Hash $r.backup_path) -cne $r.sha256){throw 'ORIGINAL_BACKUP_CHANGED'};$backups++}
}
if($backups -ne 116){throw 'BACKUP_DOMAIN116'}
$freshPath="$taskDir/after_native_import_before_deploy.json"
if((Hash $freshPath) -cne '667a957c8dd19147225bd2edabfb91a870ea81646fb01bad61373d48452a35a2'){throw 'LATEST_PREDEPLOY_GUARD_CHANGED'}
$fresh=Get-Content -LiteralPath $freshPath -Raw|ConvertFrom-Json -AsHashtable
$same=0;$changes=@();$saves=0
foreach($f in $fresh.facts){
 $p=[IO.Path]::GetFullPath([string]$f.path);$exists=Test-Path -LiteralPath $p
 if($allowed.ContainsKey($p)){
  if(!$exists -or (Hash $p) -cne $allowed[$p]){throw 'AUTHORIZED_TARGET_MISMATCH'}
  $changes+=@{path=$p;old_sha256=$f.sha256;new_sha256=$allowed[$p]};continue
 }
 if($exists -ne $f.exists){throw "EXISTENCE_CHANGED:$p"}
 if($exists){$i=Get-Item -LiteralPath $p;if((Hash $p) -cne $f.sha256 -or $i.Length -ne $f.bytes -or [string]$i.LastWriteTimeUtc.Ticks -cne $f.ticks){throw "UNAUTHORIZED_FACT_CHANGED:$p"}}
 $same++;if($f.path -in $fresh.save_paths){$saves++}
}
if($fresh.facts.Count -ne 2120 -or $saves -ne 15){throw 'PROTECTION_DOMAIN_COUNTS'}
$report=@{status='ALL_FOUR_FIXED_STAGE_SUCCESSORS_AND_LATEST_PROTECTION_VERIFIED';passed=$true;stage_pins=$pins;unique_source_files_checked=$expected.Count;all36_union_current_expected=$true;original_backup_count=$backups;protected_count=2120;unchanged_facts=$same;authorized_existing_changes=$changes;latest15saves_exact_sha_bytes_ticks=$true;save_comparison='Latest667A only, not initial old two-save differences';UI_extra_target_separately_in_union36=$true;no_ART_or_performance_claim=$true}
$out="$taskDir/final_guard_all_successors_actual.json"
$stream=[IO.File]::Open($out,[IO.FileMode]::CreateNew);$writer=[IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($false))
try{$writer.Write(($report|ConvertTo-Json -Depth 10)+"`n")}finally{$writer.Dispose()}
@{path=$out;sha256=(Hash $out);sources=$expected.Count;protected=2120;authorized=$changes.Count;unchanged=$same;saves=$saves;backups=$backups;passed=$true}|ConvertTo-Json -Compress
