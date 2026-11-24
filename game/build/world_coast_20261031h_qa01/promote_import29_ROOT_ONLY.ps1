param([Parameter(Mandatory=$true)][string]$ProofPath,[Parameter(Mandatory=$true)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$ProofSHA)
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'USE_BUNDLED_PWSH7'}
$repo='F:/Code/RPG_GAME';$game=$repo+'/game';$dir=$game+'/build/world_coast_20261031h_qa01';$iso=$dir+'/import_isolated02';$report=$dir+'/import29_PROMOTED_ACTUAL.json'
if(Test-Path -LiteralPath $report){throw 'PRESERVE_EXISTING_PROMOTION'}
function Hash-Only([string]$p){$s=[IO.File]::OpenRead($p);try{return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($s)).ToLowerInvariant()}finally{$s.Dispose()}}
function Meta([string]$p){$i=Get-Item -LiteralPath $p;return [ordered]@{sha256=(Hash-Only $p);bytes=[long]$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
$proofFull=[IO.Path]::GetFullPath($ProofPath).Replace('\','/')
if(-not $proofFull.StartsWith($iso+'/decode_actual/') -or [IO.Path]::GetFileName($proofFull) -cne 'result.json' -or (Hash-Only $proofFull) -cne $ProofSHA.ToLowerInvariant()){throw 'EXACT_ISOLATED_DECODE_PROOF_ONLY'}
$preparedPath=$dir+'/import29_PREPARED.json'
if((Hash-Only $preparedPath) -cne 'c85a40f461055d438c61f43275b5e7d26770c4cec01352ce346f30fb52bdd7c9'){throw 'PREPARED29_PIN'}
$prepared=[IO.File]::ReadAllText($preparedPath,[Text.Encoding]::UTF8)|ConvertFrom-Json -AsHashtable;$proof=[IO.File]::ReadAllText($proofFull,[Text.Encoding]::UTF8)|ConvertFrom-Json -AsHashtable
if(-not $proof.passed -or $proof.rows.Count -ne 29 -or $proof.errors.Count -ne 0 -or $proof.fixture_sha256 -cne $prepared.fixture_sha256){throw 'FULL29_ACTUAL_RGBA_PROOF_REQUIRED'}
$byPath=@{};foreach($row in $proof.rows){if($byPath.ContainsKey($row.path)){throw 'DUPLICATE_PROOF_ROW'};$byPath[$row.path]=$row}
$leaves=@();$sourceBefore=[ordered]@{}
foreach($row in $prepared.rows){
 $p=$game+'/'+$row.path.Substring(6);$sourceBefore[$p]=Meta $p
 if($sourceBefore[$p].sha256 -cne $row.sha256 -or $sourceBefore[$p].bytes -ne $row.bytes){throw 'ORIGINAL_PNG_PREPROMOTION_CHANGED'}
 $actual=$byPath[$row.path]
 if(-not $actual.full_RGBA_exact -or $actual.source_RGBA_sha256 -cne $row.rgba_sha256 -or $actual.actual_compiled_RGBA_sha256 -cne $row.rgba_sha256 -or $actual.png_sha256 -cne $row.sha256 -or $actual.compiled_path -cne $row.compiled_path -or $actual.mipmap_count -ne 0){throw 'PROOF_ROW_NOT_EXACT_PREPARED_RGBA'}
 foreach($pair in @(@{relative=($row.path.Substring(6)+'.import');sha256=$actual.import_sha256},@{relative=$row.compiled_path.Substring(6);sha256=$actual.compiled_sha256})){
  $relative=[string]$pair.relative;$sha=[string]$pair.sha256;$src=$iso+'/'+$relative;$dest=$game+'/'+$relative
  if((Test-Path -LiteralPath $dest) -or (Hash-Only $src) -cne $sha){throw ('ABSENT_DEST_AND_EXACT_SOURCE_REQUIRED:'+ $dest)}
  $leaves+=@([ordered]@{source=$src;destination=$dest;sha256=$sha})
 }
}
if($leaves.Count -ne 58){throw 'EXACT58_IMPORT_AND_CTEX_ONLY'}
$installed=[ordered]@{}
foreach($leaf in $leaves){[void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($leaf.destination));[IO.File]::Copy($leaf.source,$leaf.destination,$false);$fact=Meta $leaf.destination;if($fact.sha256 -cne $leaf.sha256){throw 'PROMOTED_LEAF_HASH_DIFF'};$installed[$leaf.destination]=$fact}
$sourceAfter=[ordered]@{}
foreach($p in $sourceBefore.Keys){$sourceAfter[$p]=Meta $p;if($sourceAfter[$p].sha256 -cne $sourceBefore[$p].sha256 -or $sourceAfter[$p].bytes -ne $sourceBefore[$p].bytes -or $sourceAfter[$p].utc_ticks -cne $sourceBefore[$p].utc_ticks){throw 'ORIGINAL_PNG_METADATA_CHANGED'}}
$result=[ordered]@{passed=$true;proof_path=$proofFull;proof_sha256=$ProofSHA.ToLowerInvariant();prepared_sha256='c85a40f461055d438c61f43275b5e7d26770c4cec01352ce346f30fb52bdd7c9';original29_PNG_before=$sourceBefore;original29_PNG_after=$sourceAfter;installed_count=58;installed=$installed;md5_leaves_promoted=0;old_asset_writes=0;full_project_import=$false;engine_runs=0;save_APIs=0;destination_absence_required=$true}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($result|ConvertTo-Json -Depth 12)+[Environment]::NewLine);$f=[IO.File]::Open($report,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);try{$f.Write($bytes,0,$bytes.Length)}finally{$f.Dispose()}
[ordered]@{passed=$true;installed=58;report=$report;sha256=(Hash-Only $report)}|ConvertTo-Json
