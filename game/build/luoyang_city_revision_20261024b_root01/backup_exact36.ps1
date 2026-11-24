$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$game='F:/Code/RPG_GAME/game'
$scope="$game/build/luoyang_city_space_20261024b_source01/exact36_existing_scope_PREPARATION_NOT_STAGE.json"
$root="$game/build/luoyang_city_revision_20261024b_root01/predeploy36"
function Hash([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
if((Hash $scope) -cne '42d08025cc285ae41685798836c48ec7b4f536461a1d562ea0ab9109489484e4'){throw 'SCOPE_CHANGED'}
if(Test-Path -LiteralPath $root){throw 'PRESERVE_BACKUP_ROOT'}
$config=Get-Content -Raw -LiteralPath $scope|ConvertFrom-Json
if($config.target_count -ne 36 -or $config.targets.Count -ne 36){throw 'EXACT36_ONLY'}
$before=@();$seen=@{}
foreach($row in $config.targets){
 $res=[string]$row.target
 if(!$res.StartsWith('res://') -or $res.Contains('..') -or $seen.ContainsKey($res)){throw 'UNIQUE_DECLARED_PATH_REQUIRED'}
 $seen[$res]=$true
 $p=Join-Path $game $res.Substring(6)
 if(!(Test-Path -LiteralPath $p) -or (Hash $p) -cne $row.old_sha256){throw "EXACT_OLD_SOURCE_MISMATCH:$res"}
 $item=Get-Item -LiteralPath $p
 $before+=@{target=$res;path=$p;sha256=$row.old_sha256;bytes=$item.Length;ticks=[string]$item.LastWriteTimeUtc.Ticks}
}
New-Item -ItemType Directory -Path "$root/backups"|Out-Null
$records=@();$index=0
foreach($row in $before){
 $name=('{0:D2}_' -f $index)+[IO.Path]::GetFileName($row.path)
 $backup=Join-Path "$root/backups" $name
 Copy-Item -LiteralPath $row.path -Destination $backup
 if((Hash $backup) -cne $row.sha256 -or (Hash $row.path) -cne $row.sha256){throw 'BYTE_EXACT_BACKUP_REQUIRED'}
 $item=Get-Item -LiteralPath $row.path
 if($item.Length -ne $row.bytes -or [string]$item.LastWriteTimeUtc.Ticks -cne $row.ticks){throw 'SOURCE_CHANGED_DURING_BACKUP'}
 $row.backup_path=$backup;$row.backup_sha256=(Hash $backup)
 $records+=$row;$index++
}
$report=@{status='EXACT36_PREDEPLOY_BACKUPS_NOT_DEPLOYMENT';scope_path=$scope;scope_sha256=(Hash $scope);count=36;records=$records;extra_UI_domain_protected=$true;production_writes=0;save_writes=0;editor_stopped=$false}
$out="$root/backup_receipt.json"
[IO.File]::WriteAllText($out,($report|ConvertTo-Json -Depth 8)+"`n",[Text.UTF8Encoding]::new($false))
@{path=$out;sha256=(Hash $out);backups=36;all_old_sources_current=$true}|ConvertTo-Json
