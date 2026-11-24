$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$taskDir='F:/Code/RPG_GAME/game/build/luoyang_city_revision_20261024b_root01'
$isolate='F:/Code/RPG_GAME/assets/staging/luoyang_two_complete_shops_isolated_import_20261024b'
$game='F:/Code/RPG_GAME/game'
function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function NewJson([string]$p,$v){$f=[IO.File]::Open($p,[IO.FileMode]::CreateNew);$w=[IO.StreamWriter]::new($f,[Text.UTF8Encoding]::new($false));try{$w.Write(($v|ConvertTo-Json -Depth 12)+"`n")}finally{$w.Dispose()}}
$actual=$isolate+'/two_complete_shops_import_result_53660.json'
if((Sha $actual) -cne '4a3f7a03baf37110fa840bd8f83d3718b81e189f1dc3c219d65d2c5d7959ee12'){throw 'EXACT_ACTUAL_CHANGED'}
$r=Get-Content -LiteralPath $actual -Raw|ConvertFrom-Json -AsHashtable
if(!$r.passed -or $r.checks -ne 139 -or $r.failures.Count -ne 0 -or $r.rows.Count -ne 2){throw 'FULL_RGBA_ACTUAL_REQUIRED'}
$leaves=@()
foreach($row in $r.rows){
 if($row.domain -notin @('apothecary','bookshop') -or !$row.full_RGBA_exact -or !$row.params23 -or $row.mipmaps -ne 0){throw 'TWO_FIXED_DOMAINS_REQUIRED'}
 foreach($kind in @('sidecar','compiled','png')){
  $res=$row[$kind]
  if(!$res.StartsWith('res://') -or $res.Contains('..')){throw 'EXACT_RES_PATH_REQUIRED'}
  $source=[IO.Path]::GetFullPath((Join-Path $isolate $res.Substring(6)))
  $target=[IO.Path]::GetFullPath((Join-Path $game $res.Substring(6)))
  if(!$source.StartsWith([IO.Path]::GetFullPath($isolate)+'\',[StringComparison]::OrdinalIgnoreCase) -or !$target.StartsWith([IO.Path]::GetFullPath($game)+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'EXACT_WORKSPACE_LEAVES_ONLY'}
  if(Test-Path -LiteralPath $target){throw 'NEW_MEDIA_DESTINATION_NOT_ABSENT'}
  if((Sha $source) -cne $row[($kind+'_sha256')]){throw 'FIXED_ISOLATE_CHANGED'}
  $leaves+=,@{source=$source;target=$target;sha256=(Sha $source);bytes=(Get-Item -LiteralPath $source).Length;kind=$kind;domain=$row.domain;before='ABSENT'}
 }
}
if($leaves.Count -ne 6 -or @($leaves.target|Select-Object -Unique).Count -ne 6){throw 'EXACT_SIX_NEW_LEAVES_REQUIRED'}
$ordered=@($leaves|Where-Object {$_.kind -ne 'png'})+@($leaves|Where-Object {$_.kind -eq 'png'})
$auth=$taskDir+'/two_png_six_leaf_authorization.json'
NewJson $auth @{approved_by_root=$true;status='SIX_EXACT_NEW_MEDIA_LEAVES_ONLY';actual_report_sha256=(Sha $actual);ordered_targets=$ordered;runtime_adoption=$false;main_project_import=$false}
$written=@()
foreach($leaf in $ordered){
 [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($leaf.target))
 $inputStream=[IO.File]::OpenRead($leaf.source)
 try{$outputStream=[IO.File]::Open($leaf.target,[IO.FileMode]::CreateNew);try{$inputStream.CopyTo($outputStream)}finally{$outputStream.Dispose()}}finally{$inputStream.Dispose()}
 if((Sha $leaf.target) -cne $leaf.sha256 -or (Get-Item -LiteralPath $leaf.target).Length -ne $leaf.bytes){throw 'STOP_PARTIAL_NEW_COPY_NO_OVERWRITE'}
 $written+=,@{path=$leaf.target;sha256=$leaf.sha256;bytes=$leaf.bytes;ticks=[string](Get-Item -LiteralPath $leaf.target).LastWriteTimeUtc.Ticks}
}
$receipt=$taskDir+'/two_png_six_leaf_actual.json'
NewJson $receipt @{passed=$true;status='SIX_EXACT_NEW_MEDIA_LEAVES_ADDED_NOT_RUNTIME_BINDING';authorization_sha256=(Sha $auth);written=$written;main_project_import=$false;old_sources_overwritten=0}
@{receipt=$receipt;sha256=(Sha $receipt);new_leaves=6}|ConvertTo-Json -Compress
