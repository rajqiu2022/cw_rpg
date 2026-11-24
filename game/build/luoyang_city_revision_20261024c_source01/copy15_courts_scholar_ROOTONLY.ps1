$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
# Root runs only after the exact fifteen-GD apply_patch. No GD/native/save copy.
$game='F:/Code/RPG_GAME/game'
$stageRes='res://build/luoyang_city_revision_20261024c_source01/outputs/root_courts_scholar_exact30_stage03/receipt.json'
$stageSHA='99a719091627f5b6cbc015aa7c4281d42f01b1786a5a9f4cafe3becc55cc51ce'
$planSHA='f1b5485a5713887914c33f7585869c22647c857a863e1b00ba7b3d15f928456c'
$backupPath='F:/Code/RPG_GAME/game/build/luoyang_city_revision_20261024c_root01/exact30_old_backup/receipt.json'
$backupSHA='f55b46d79bac42868f840232f491569c6dc952c8518a576ddd61d7df3d1114fb'
$out='F:/Code/RPG_GAME/game/build/luoyang_city_revision_20261024c_root01/deployment30_actual.json'
function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function Res([string]$p){if(!$p.StartsWith('res://') -or $p.Contains('..')){throw 'EXACT_RES_ONLY'};Join-Path $game $p.Substring(6)}
if(Test-Path -LiteralPath $out){throw 'PRESERVE_EXISTING_DEPLOYMENT_RECEIPT_NO_RETRY'}
if((Sha (Res $stageRes)) -cne $stageSHA -or (Sha $backupPath) -cne $backupSHA){throw 'LOCKED_STAGE_AND_FULL_OLD_BACKUP_REQUIRED'}
$s=Get-Content -LiteralPath (Res $stageRes) -Raw|ConvertFrom-Json -AsHashtable
$b=Get-Content -LiteralPath $backupPath -Raw|ConvertFrom-Json -AsHashtable
if($s.status -cne 'YAMEN_COURTS_SCHOLAR_EXACT30_STAGED_NOT_DEPLOYED' -or $s.targets.Count -ne 30 -or $s.target_partition.patch_count -ne 15 -or $s.target_partition.copy_count -ne 15 -or $b.count -ne 30 -or $b.rows.Count -ne 30){throw 'EXACT30_PARTITION_AND_BACKUP'}
if($s.source_first.Count -ne $s.source_final.Count){throw 'STAGE_FIRST_FINAL_DOMAIN'}
foreach($p in $s.source_first.Keys){if(!$s.source_final.ContainsKey($p) -or $s.source_final[$p] -cne $s.source_first[$p]){throw 'STAGE_FIRST_FINAL_SHA_NOT_EXACT'}}
if($s.byte_copy_plan.sha256 -cne $planSHA -or (Sha (Res $s.byte_copy_plan.path)) -cne $planSHA){throw 'EXACT15_COPY_PLAN_REQUIRED'}
$plan=Get-Content -LiteralPath (Res $s.byte_copy_plan.path) -Raw|ConvertFrom-Json -AsHashtable
$targets=@{};foreach($r in $s.targets){if($targets.ContainsKey($r.target)){throw 'DUPLICATE_TARGET'};$targets[$r.target]=$r}
$backups=@{};foreach($r in $b.rows){if(!$targets.ContainsKey($r.target) -or $backups.ContainsKey($r.target) -or $r.old_sha256 -cne $targets[$r.target].old_sha256 -or (Sha $r.backup) -cne $r.old_sha256 -or (Get-Item -LiteralPath $r.backup).Length -ne $r.bytes){throw 'FULL30_OLD_BACKUP_CHANGED'};$backups[$r.target]=@{sha256=(Sha $r.backup);bytes=(Get-Item -LiteralPath $r.backup).Length;ticks=[string](Get-Item -LiteralPath $r.backup).LastWriteTimeUtc.Ticks;path=$r.backup}}
$gd=@($s.targets|Where-Object {$_.target.EndsWith('.gd')});$json=@($s.targets|Where-Object {$_.target.EndsWith('.json')})
if($gd.Count -ne 15 -or $json.Count -ne 15 -or $plan.rows.Count -ne 15){throw 'EXACT15_PLUS15_ONLY'}
foreach($r in $gd){if((Sha (Res $r.target)) -cne $r.candidate_sha256 -or (Sha (Res $r.candidate_path)) -cne $r.candidate_sha256 -or (Get-Item -LiteralPath (Res $r.target)).Length -ne (Get-Item -LiteralPath (Res $r.candidate_path)).Length){throw 'GD_MUST_ALREADY_BE_EXACT_APPLY_PATCH_CANDIDATE'}}
$seen=@{}
foreach($r in $plan.rows){
 if(!$r.target.EndsWith('.json') -or !$targets.ContainsKey($r.target) -or $seen.ContainsKey($r.target)){throw 'EXACT_DISJOINT_JSON_PLAN'}
 $t=$targets[$r.target]
 if($r.old_sha256 -cne $t.old_sha256 -or $r.candidate_sha256 -cne $t.candidate_sha256 -or $r.candidate_path -cne $t.candidate_path -or (Sha (Res $r.target)) -cne $r.old_sha256 -or (Sha (Res $r.candidate_path)) -cne $r.candidate_sha256 -or (Get-Item -LiteralPath (Res $r.candidate_path)).Length -ne $r.candidate_bytes){throw 'EXACT_JSON_OLD_AND_FROZEN_NEW_BYTES'}
 $seen[$r.target]=$true
}
foreach($r in $plan.rows){[IO.File]::Copy((Res $r.candidate_path),(Res $r.target),$true);if((Sha (Res $r.target)) -cne $r.candidate_sha256 -or (Get-Item -LiteralPath (Res $r.target)).Length -ne $r.candidate_bytes){throw 'STOP_PARTIAL_COPY_PRESERVE_BACKUPS_NO_AUTO_RESTORE'}}
$rows=@()
foreach($r in $s.targets){$actual=Sha (Res $r.target);if($actual -cne $r.candidate_sha256){throw 'ALL30_CURRENT_NOT_EXACT'};$rows+=,@{target=$r.target;old_sha256=$r.old_sha256;candidate_path=$r.candidate_path;candidate_sha256=$r.candidate_sha256;actual_sha256=$actual;bytes=(Get-Item -LiteralPath (Res $r.target)).Length}}
foreach($r in $backups.Values){if((Sha $r.path) -cne $r.sha256 -or (Get-Item -LiteralPath $r.path).Length -ne $r.bytes -or [string](Get-Item -LiteralPath $r.path).LastWriteTimeUtc.Ticks -cne $r.ticks){throw 'OLD_BACKUP_CHANGED_DURING_JSON_COPY'}}
$receipt=@{status='EXACT30_COURTS_SCHOLAR_DEPLOYED';passed=$true;target_count=30;stage=@{path=$stageRes;sha256=$stageSHA};partition=@{apply_patch_GD=15;exact_copy_JSON=15};targets=$rows;copy_plan_sha256=$planSHA;full_old_backup_sha256=$backupSHA;old_backups_unchanged=$true;GD_copied=0;native_or_save_writes=0;source_first_final_equal_in_stage=$true}
$stream=[IO.File]::Open($out,[IO.FileMode]::CreateNew);$writer=[IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($false))
try{$writer.Write(($receipt|ConvertTo-Json -Depth 12)+"`n")}finally{$writer.Dispose()}
@{path=$out;sha256=(Sha $out);target_count=30;copied_JSON=15}|ConvertTo-Json -Compress
