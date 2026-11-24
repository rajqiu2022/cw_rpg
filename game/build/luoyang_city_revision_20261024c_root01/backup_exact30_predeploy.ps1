$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$game='F:/Code/RPG_GAME/game'
$scopePath="$game/build/luoyang_city_revision_20261024c_source01/exact30_old_scope_PREPARATION_NOT_STAGE.json"
$scopeSHA='8fe4a63d01a0196bf05c8ff1768be08d2ce99ff9a0a826c88f230f380eecfef3'
$destination="$game/build/luoyang_city_revision_20261024c_root01/exact30_old_backup"
function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
if((Sha $scopePath) -cne $scopeSHA -or (Test-Path -LiteralPath $destination)){throw 'FIXED_SCOPE_OR_ABSENT_BACKUP_REQUIRED'}
$scope=Get-Content -LiteralPath $scopePath -Raw|ConvertFrom-Json -AsHashtable
if($scope.target_count -ne 30 -or $scope.targets.Count -ne 30){throw 'EXACT30_REQUIRED'}
$rows=@()
foreach($row in $scope.targets){
 if(!$row.target.StartsWith('res://') -or $row.target.Contains('..')){throw 'EXACT_RES_PATH'}
 $path=[IO.Path]::GetFullPath((Join-Path $game $row.target.Substring(6)))
 $actualSHA=Sha $path
 if($actualSHA -cne $row.old_sha256){throw "OLD_DECLARED_SHA_MISMATCH:$path"}
 $snapshot=Join-Path $game $row.immutable_snapshot.Substring(6)
 if((Sha $snapshot) -cne $row.old_sha256){throw 'IMMUTABLE_PARENT_SNAPSHOT_MISMATCH'}
 $f=Get-Item -LiteralPath $path
 $rows+=,@{target=$row.target;path=$path;old_sha256=$actualSHA;bytes=$f.Length;ticks=[string]$f.LastWriteTimeUtc.Ticks;backup=(Join-Path $destination $row.target.Substring(6))}
}
if(@($rows.target|Select-Object -Unique).Count -ne 30){throw 'EXACT_UNIQUE30'}
foreach($row in $rows){
 [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($row.backup))
 $inputStream=[IO.File]::OpenRead($row.path)
 try{$outputStream=[IO.File]::Open($row.backup,[IO.FileMode]::CreateNew);try{$inputStream.CopyTo($outputStream)}finally{$outputStream.Dispose()}}finally{$inputStream.Dispose()}
 $f=Get-Item -LiteralPath $row.path
 if((Sha $row.backup) -cne $row.old_sha256 -or (Sha $row.path) -cne $row.old_sha256 -or $f.Length -ne $row.bytes -or [string]$f.LastWriteTimeUtc.Ticks -cne $row.ticks){throw 'BACKUP_OR_SOURCE_CHANGED'}
}
$receipt=@{status='ROOT_EXACT30_PREDEPLOY_FULL_OLD_BACKUP';passed=$true;scope_path=$scopePath;scope_sha256=$scopeSHA;count=30;rows=$rows;canonical_writes=0;source_expectation='FOUR_FIXED_24B_STAGE_DECLARATIONS_NOT_OBSERVED_FILL';root_protection_sha256='18eee16cb341f01a984acd1f260dd1511e0e543e0d61b90789cef3f960d5712a'}
$rp="$destination/receipt.json"
$stream=[IO.File]::Open($rp,[IO.FileMode]::CreateNew);$writer=[IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($false))
try{$writer.Write(($receipt|ConvertTo-Json -Depth 12)+"`n")}finally{$writer.Dispose()}
@{receipt=$rp;sha256=(Sha $rp);backups=30}|ConvertTo-Json -Compress
