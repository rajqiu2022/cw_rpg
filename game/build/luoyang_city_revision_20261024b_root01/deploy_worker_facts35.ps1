param([switch]$AfterPatch)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$game='F:/Code/RPG_GAME/game'
$stageRes='res://build/luoyang_city_space_20261024b_source01/outputs/root_market_worker_facts_exact35_stage01/receipt.json'
$stageSHA='af129e34538479d7aaae3a1e87e7194d44fc52354ec44de9dcd41a77eecadd0c'
function Local([string]$p){if(!$p.StartsWith('res://') -or $p.Contains('..')){throw 'RES_DOMAIN'};Join-Path $game $p.Substring(6)}
function Hash([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
if((Hash (Local $stageRes)) -cne $stageSHA){throw 'STAGE_CHANGED'}
$s=Get-Content -LiteralPath (Local $stageRes) -Raw|ConvertFrom-Json -AsHashtable
if($s.status -cne 'MARKET_DIALOGUE_EXACT35_STAGED_NOT_DEPLOYED' -or $s.targets.Count -ne 35 -or $s.target_partition.patch_count -ne 20 -or $s.target_partition.copy_count -ne 15){throw 'EXACT36_STAGE_SCHEMA'}
$backupPath="$game/build/luoyang_city_revision_20261024b_root01/worker_facts_predeploy35/backup_receipt.json"
if((Hash $backupPath) -cne '6c47b16fe01b6c71ace9fef922ff8e35e2658c3fc8400c1a709624cc4d394459'){throw 'BACKUP_CHANGED'}
$backup=Get-Content -LiteralPath $backupPath -Raw|ConvertFrom-Json -AsHashtable
$seen=@{};$gd=0;$json=0
foreach($r in $s.targets){
 if($seen.ContainsKey($r.target)){throw 'DUPLICATE_TARGET'};$seen[$r.target]=$true
 $b=@($backup.records|Where-Object {$_.target -ceq $r.target})
 if($b.Count -ne 1 -or $b[0].sha256 -cne $r.old_sha256 -or (Hash $b[0].backup_path) -cne $r.old_sha256){throw 'EXACT_BACKUP_IDENTITY'}
 if((Hash (Local $r.candidate_path)) -cne $r.candidate_sha256){throw 'CANDIDATE_CHANGED'}
 if($r.target.EndsWith('.gd')){$gd++;$expected=if($AfterPatch){$r.candidate_sha256}else{$r.old_sha256}}
 elseif($r.target.EndsWith('.json')){$json++;$expected=$r.old_sha256}else{throw 'ONLY_GD_JSON'}
 if((Hash (Local $r.target)) -cne $expected){throw "CANONICAL_PRECONDITION:$($r.target)"}
}
if($gd -ne 20 -or $json -ne 15 -or (Hash (Local $s.patch_path)) -cne $s.patch_sha256){throw 'PARTITION_OR_PATCH'}
if(!$AfterPatch){@{status='EXACT36_OLD_SOURCE_AND_BACKUPS_VERIFIED_READY_FOR_APPLY_PATCH';targets=35;patch_sha256=$s.patch_sha256}|ConvertTo-Json -Compress;exit 0}
$copyPath=Local $s.byte_copy_plan.path
if((Hash $copyPath) -cne $s.byte_copy_plan.sha256){throw 'COPY_PLAN_CHANGED'}
$copy=Get-Content -LiteralPath $copyPath -Raw|ConvertFrom-Json -AsHashtable
if($copy.rows.Count -ne 15 -or !$copy.no_GD_copy_or_native_write){throw 'COPY15_ONLY'}
$copySeen=@{}
foreach($r in $copy.rows){
 $match=@($s.targets|Where-Object {$_.target -ceq $r.target -and $_.candidate_path -ceq $r.candidate_path -and $_.candidate_sha256 -ceq $r.candidate_sha256})
 if(!$r.target.EndsWith('.json') -or $copySeen.ContainsKey($r.target) -or $match.Count -ne 1){throw 'COPY_TARGET_DOMAIN'}
 $copySeen[$r.target]=$true
 if((Hash (Local $r.target)) -cne $r.old_sha256 -or (Hash (Local $r.candidate_path)) -cne $r.candidate_sha256){throw 'COPY_OLD_NEW_PRECONDITION'}
}
foreach($r in $copy.rows){Copy-Item -LiteralPath (Local $r.candidate_path) -Destination (Local $r.target)}
$actual=@()
foreach($r in $s.targets){
 $p=Local $r.target;$h=Hash $p
 if($h -cne $r.candidate_sha256){throw 'FINAL_CANDIDATE_MISMATCH'}
 $actual+=@{target=$r.target;old_sha256=$r.old_sha256;candidate_path=$r.candidate_path;candidate_sha256=$r.candidate_sha256;actual_sha256=$h;bytes=(Get-Item -LiteralPath $p).Length}
}
$receipt=@{status='ROOT_EXACT35_DEPLOYED_FIRST_FINAL_VERIFIED';passed=$true;stage=@{path=$stageRes;sha256=$stageSHA};target_count=35;targets=$actual;partition=@{apply_patch_GD=20;exact_copy_JSON=15};full_backups_preserved=$true;save_writes=0;editor_stopped=$false;Field_journey_not_yet_run=$true}
$out="$game/build/luoyang_city_revision_20261024b_root01/deployment35_worker_facts_actual.json"
$stream=[IO.File]::Open($out,[IO.FileMode]::CreateNew);$writer=[IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($false))
try{$writer.Write(($receipt|ConvertTo-Json -Depth 10)+"`n")}finally{$writer.Dispose()}
@{path=$out;sha256=(Hash $out);targets=35;passed=$true}|ConvertTo-Json -Compress
