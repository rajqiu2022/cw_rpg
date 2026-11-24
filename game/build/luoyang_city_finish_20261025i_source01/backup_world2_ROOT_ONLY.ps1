$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$gameRoot='F:/Code/RPG_GAME/game'
$taskRoot="$gameRoot/build/luoyang_city_finish_20261025i_source01"
$receiptPath="$taskRoot/world2_old_backup_ROOT_EXECUTED.json"
if(Test-Path -LiteralPath $receiptPath){throw 'PRESERVE_RECEIPT'}
function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
$targets=@(
 @{relative='scripts/world/world_v15_visible_stream_20261018r.gd';expected='9da2f8b5de0983fa5c23ca07ab651ab4dc0462e7b0353028fbfc96664f5dbba1'},
 @{relative='scripts/field/background_chunk_streamer.gd';expected='68db675234eb77d11416b75fe0c653b8672116b3649b0d90bc299327815c0bc8'}
)
$rows=@()
foreach($row in $targets){
 $src=[IO.Path]::GetFullPath("$gameRoot/"+$row.relative)
 $dst=[IO.Path]::GetFullPath("$taskRoot/root_only_world2_old_backup/"+$row.relative)
 if(!$src.StartsWith([IO.Path]::GetFullPath($gameRoot)+'\',[StringComparison]::OrdinalIgnoreCase) -or !$dst.StartsWith([IO.Path]::GetFullPath("$taskRoot/root_only_world2_old_backup")+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'SCOPE'}
 if((Sha $src) -cne $row.expected -or (Test-Path -LiteralPath $dst)){throw 'PRECONDITION'}
 $info=Get-Item -LiteralPath $src
 $rows+=@{target=('res://'+$row.relative);source=$src;backup=$dst;expected_sha256=$row.expected;bytes=$info.Length;ticks=[string]$info.LastWriteTimeUtc.Ticks}
}
foreach($row in $rows){
 [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($row.backup))|Out-Null
 $inputStream=[IO.File]::OpenRead($row.source);$outputStream=[IO.File]::Open($row.backup,[IO.FileMode]::CreateNew)
 try{$inputStream.CopyTo($outputStream)}finally{$inputStream.Dispose();$outputStream.Dispose()}
 $info=Get-Item -LiteralPath $row.source
 if((Sha $row.backup) -cne $row.expected_sha256 -or (Sha $row.source) -cne $row.expected_sha256 -or $info.Length -ne $row.bytes -or [string]$info.LastWriteTimeUtc.Ticks -cne $row.ticks){throw 'EXACT_BACKUP_OR_SOURCE_CHANGED'}
}
$receipt=@{status='ROOT_EXECUTED_WORLD_TWO_OLD_HOOK_BACKUPS_NOT_CITY32_NOT_DEPLOYMENT';count=2;rows=$rows;canonical_writes=0;engine_calls=0}
$f=[IO.File]::Open($receiptPath,[IO.FileMode]::CreateNew);$w=[IO.StreamWriter]::new($f,[Text.UTF8Encoding]::new($false))
try{$w.Write(($receipt|ConvertTo-Json -Depth 8)+"`n")}finally{$w.Dispose()}
@{path=$receiptPath;sha256=(Sha $receiptPath);count=2}|ConvertTo-Json -Compress
