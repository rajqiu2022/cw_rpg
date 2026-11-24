param(
 [Parameter(Mandatory=$true)][string]$ActualPath,
 [Parameter(Mandatory=$true)][string]$ActualSha256,
 [Parameter(Mandatory=$true)][string]$RootAuthorizationPath,
 [Parameter(Mandatory=$true)][string]$RootAuthorizationSha256,
 [Parameter(Mandatory=$true)][string]$ReceiptPath
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$game='F:/Code/RPG_GAME/game'
$isolate='F:/Code/RPG_GAME/assets/staging/luoyang_scholar_portrait_20261024c_import'
$rootBuild='F:/Code/RPG_GAME/game/build/luoyang_city_revision_20261024c_root01'
$png='res://art/characters/portraits/luoyang_scholar_20261024c/paper_scholar_v1.png'
$compiled='res://.godot/imported/paper_scholar_v1.png-a84b0a85bc8e14dc620e75dc75b57eda.ctex'
function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function Within([string]$p,[string]$parent){[IO.Path]::GetFullPath($p).StartsWith([IO.Path]::GetFullPath($parent)+'\',[StringComparison]::OrdinalIgnoreCase)}
if(!(Within $ActualPath $isolate) -or !(Within $RootAuthorizationPath $rootBuild) -or !(Within $ReceiptPath $rootBuild)){throw 'EXACT_ISOLATE_AND_ROOT_BUILD_PATHS_ONLY'}
if((Sha $ActualPath) -cne $ActualSha256.ToLowerInvariant() -or (Sha $RootAuthorizationPath) -cne $RootAuthorizationSha256.ToLowerInvariant()){throw 'ROOT_LOCKED_REPORT_AND_AUTH_REQUIRED'}
$auth=Get-Content -LiteralPath $RootAuthorizationPath -Raw|ConvertFrom-Json -AsHashtable
if($auth.status -cne 'ROOT_APPROVED_SCHOLAR_PORTRAIT_EXACT_THREE_MEDIA_PROMOTION' -or !$auth.approved_by_root -or $auth.actual_report.sha256 -cne $ActualSha256.ToLowerInvariant()){throw 'EXPLICIT_ROOT_THREE_MEDIA_AUTH_REQUIRED'}
$r=Get-Content -LiteralPath $ActualPath -Raw|ConvertFrom-Json -AsHashtable
if(!$r.passed -or $r.failures.Count -ne 0 -or $r.rows.Count -ne 1 -or $r.scope -cne 'ONLY_ONE_OPAQUE_SCHOLAR_PORTRAIT_ISOLATED_FULL_RGBA_NOT_RUNTIME'){throw 'EXACT_ONE_PORTRAIT_NATIVE_FULL_RGBA_PASS_REQUIRED'}
$row=$r.rows[0]
if($row.domain -cne 'paper_scholar_portrait' -or !$row.full_RGBA_exact -or !$row.opaque_full_RGBA -or !$row.params23 -or $row.mipmaps -ne 0 -or $row.detect_3d_compress_to -ne 0 -or $row.png -cne $png -or $row.compiled -cne $compiled -or $row.sidecar -cne ($png+'.import') -or $row.png_sha256 -cne 'ebd60b64edbcc061401a0fc1219d1f120a4f5d4e98db1ab1d129c81f845c2a74' -or $row.decoded_RGBA_sha256 -cne '3b2f42c9e5fe7afe3ac43ae1894e7fcea4d8584a158da829311f8f80306b1261' -or $row.size[0] -ne 1254 -or $row.size[1] -ne 1254){throw 'FIXED_UNEDITED_OPAQUE_PORTRAIT_ONLY'}
$leaves=@()
foreach($kind in @('sidecar','compiled','png')){
 $res=$row[$kind]
 if(!$res.StartsWith('res://') -or $res.Contains('..')){throw 'EXACT_RES_PATH'}
 $source=[IO.Path]::GetFullPath((Join-Path $isolate $res.Substring(6)))
 $target=[IO.Path]::GetFullPath((Join-Path $game $res.Substring(6)))
 if(!(Within $source $isolate) -or !(Within $target $game) -or (Test-Path -LiteralPath $target)){throw 'NEW_EXACT_THREE_MAIN_LEAVES_ABSENT_REQUIRED'}
 $h=$row[$kind+'_sha256'];$bytes=(Get-Item -LiteralPath $source).Length
 if((Sha $source) -cne $h){throw 'FIXED_ISOLATE_BYTES_CHANGED'}
 $leaves+=,@{kind=$kind;source=$source;target=$target;sha256=$h;bytes=$bytes}
}
if($leaves.Count -ne 3 -or @($leaves.target|Select-Object -Unique).Count -ne 3 -or $auth.ordered_targets.Count -ne 3 -or (Test-Path -LiteralPath $ReceiptPath)){throw 'EXACT_THREE_AND_NEW_RECEIPT'}
for($i=0;$i -lt 3;$i++){
 if([IO.Path]::GetFullPath($auth.ordered_targets[$i].target) -cne $leaves[$i].target -or $auth.ordered_targets[$i].sha256 -cne $leaves[$i].sha256 -or $auth.ordered_targets[$i].bytes -ne $leaves[$i].bytes){throw 'ROOT_PREAUTHORIZED_ORDERED_TARGET_ROWS_EXACT'}
}
$written=@()
foreach($leaf in $leaves){
 [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($leaf.target))
 $inputStream=[IO.File]::OpenRead($leaf.source)
 try{$outputStream=[IO.File]::Open($leaf.target,[IO.FileMode]::CreateNew);try{$inputStream.CopyTo($outputStream)}finally{$outputStream.Dispose()}}finally{$inputStream.Dispose()}
 if((Sha $leaf.target) -cne $leaf.sha256 -or (Get-Item -LiteralPath $leaf.target).Length -ne $leaf.bytes){throw 'STOP_PARTIAL_NEW_COPY_NO_OVERWRITE_OR_DELETE'}
 $written+=,@{path=$leaf.target;sha256=$leaf.sha256;bytes=$leaf.bytes;ticks=[string](Get-Item -LiteralPath $leaf.target).LastWriteTimeUtc.Ticks}
}
$receipt=@{passed=$true;status='EXACT_THREE_SCHOLAR_PORTRAIT_NEW_MEDIA_PROMOTED_NOT_RUNTIME';actual_report_sha256=$ActualSha256;Root_authorization_sha256=$RootAuthorizationSha256;written=$written;old_sources_overwritten=0;main_project_import=$false;pixel_edits=0}
[void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($ReceiptPath)))
$stream=[IO.File]::Open($ReceiptPath,[IO.FileMode]::CreateNew);$writer=[IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($false))
try{$writer.Write(($receipt|ConvertTo-Json -Depth 12)+"`n")}finally{$writer.Dispose()}
@{receipt=$ReceiptPath;sha256=(Sha $ReceiptPath);new_leaves=3}|ConvertTo-Json -Compress
