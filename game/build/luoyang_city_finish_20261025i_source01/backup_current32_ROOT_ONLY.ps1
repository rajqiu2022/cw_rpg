$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$gameRoot='F:/Code/RPG_GAME/game'
$taskRoot="$gameRoot/build/luoyang_city_finish_20261025i_source01"
$planPath="$taskRoot/finish8_existing_target_scope32_PREPARATION.json"
$receiptPath="$taskRoot/immutable_current32_ROOT_EXECUTED.json"
function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function Native([string]$p){
 if(!$p.StartsWith('res://')){throw 'RES_PATH_REQUIRED'}
 $resolved=[IO.Path]::GetFullPath([IO.Path]::Combine($gameRoot,$p.Substring(6)))
 if(!$resolved.StartsWith([IO.Path]::GetFullPath($gameRoot)+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'OUTSIDE_GAME'}
 return $resolved
}
function Facts([string]$p){
 if(!(Test-Path -LiteralPath $p)){return @{exists=$false}}
 $v=Get-Item -LiteralPath $p
 return @{exists=$true;sha256=(Sha $p);bytes=$v.Length;ticks=[string]$v.LastWriteTimeUtc.Ticks}
}
if((Sha $planPath) -cne '2b74b371ea336b4725a76d4b23fce46d4c1e6cd26d987c515c6791016a9c6589'){throw 'PLAN_SHA'}
if(Test-Path -LiteralPath $receiptPath){throw 'RECEIPT_EXISTS'}
$plan=Get-Content -Raw -LiteralPath $planPath|ConvertFrom-Json -AsHashtable
if($plan.count -ne 32 -or $plan.targets.Count -ne 32){throw 'SCOPE32'}
$saveSpec=Get-Content -Raw -LiteralPath 'F:/Code/RPG_GAME/assets/staging/luoyang_finish7_masks_20261025i_import01/prepared_READY.json'|ConvertFrom-Json -AsHashtable
$saveBefore=@{}
foreach($p in $saveSpec.all15_save_facts.Keys){$saveBefore[$p]=Facts $p}
$rows=@()
foreach($row in $plan.targets){
 $src=Native $row.target;$sourceSnapshot=Native $row.immutable_old
 $rootBackup='res://build/luoyang_city_finish_20261025i_source01/root_only_backup32/'+$row.target.Substring(6)
 $dst=Native $rootBackup;$fact=Facts $src
 if(!$fact.exists -or $fact.sha256 -cne $row.old_sha256 -or $fact.bytes -ne $row.old_bytes){throw ('OLD_TARGET_CHANGED '+$row.target)}
 if(Test-Path -LiteralPath $dst){throw ('BACKUP_ALREADY_EXISTS '+$dst)}
 if((Sha $sourceSnapshot) -cne $row.old_sha256){throw 'SOURCE_IMMUTABLE_SNAPSHOT_SHA'}
 if(!$dst.StartsWith([IO.Path]::GetFullPath("$taskRoot/root_only_backup32")+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'BACKUP_SCOPE'}
 $rows+=@{target=$row.target;source_immutable_old=$row.immutable_old;immutable_old=$rootBackup;before=$fact}
}
foreach($row in $rows){
 $src=Native $row.target;$dst=Native $row.immutable_old
 [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($dst))|Out-Null
 $inputStream=[IO.File]::OpenRead($src);$outputStream=[IO.File]::Open($dst,[IO.FileMode]::CreateNew)
 try{$inputStream.CopyTo($outputStream)}finally{$inputStream.Dispose();$outputStream.Dispose()}
 $after=Facts $src
 if((ConvertTo-Json -Compress $after) -cne (ConvertTo-Json -Compress $row.before)){throw 'SOURCE_FACT_CHANGED_DURING_BACKUP'}
 if((Sha $dst) -cne $row.before.sha256 -or (Get-Item -LiteralPath $dst).Length -ne $row.before.bytes){throw 'BACKUP_BYTES'}
 $row.backup_sha256=Sha $dst
}
foreach($p in $saveBefore.Keys){if((ConvertTo-Json -Compress (Facts $p)) -cne (ConvertTo-Json -Compress $saveBefore[$p])){throw 'SAVE_FACT_CHANGED'}}
$receipt=@{status='ROOT_EXECUTED_CREATE_NEW_FULL_BACKUPS_NOT_DEPLOYMENT';plan_sha256=(Sha $planPath);count=32;rows=$rows;all15_save_facts_unchanged=$true;save_before=$saveBefore;canonical_writes=0;engine_calls=0;editor51856_alive=(@(Get-Process -Id 51856 -ErrorAction SilentlyContinue).Count -eq 1)}
$stream=[IO.File]::Open($receiptPath,[IO.FileMode]::CreateNew);$writer=[IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($false))
try{$writer.Write(($receipt|ConvertTo-Json -Depth 12)+"`n")}finally{$writer.Dispose()}
@{receipt=$receiptPath;sha256=(Sha $receiptPath);count=32}|ConvertTo-Json -Compress
