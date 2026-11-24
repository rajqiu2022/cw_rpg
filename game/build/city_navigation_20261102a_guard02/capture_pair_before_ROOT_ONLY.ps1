param(
 [string]$Capture=(Join-Path $PSScriptRoot '../city_navigation_20261102a_guard01/capture_before_ACTUAL.json'),
 [string]$Output=(Join-Path $PSScriptRoot 'pair_capture_before_ACTUAL.json')
)
$ErrorActionPreference='Stop'
$pairCaptureSHA='d815b040e06e20890dcecd686b47b382e74b1879601cc4dd5f8c31ff09bdc94c'
if((Get-FileHash -LiteralPath $Capture -Algorithm SHA256).Hash.ToLowerInvariant() -cne $pairCaptureSHA){throw 'ORIGINAL_D815_CAPTURE_REQUIRED_NO_REBASE'}
$pairCap=Get-Content -LiteralPath $Capture -Raw|ConvertFrom-Json
$pairKey='res://build/city_navigation_20261101d_candidate01/navigation_pairs.gd'
if($pairCap.finite_deduplicated_source_count -ne 208 -or @($pairCap.immutable134_paths) -ccontains $pairKey){throw 'PAIR_MUST_BE_CAPTURED208_NOT_CANONICAL134'}
$pairBefore=$pairCap.before_source_facts.$pairKey
if($pairBefore.sha256 -cne 'b48aedb56b37226a5f0131778a34b7e20724044acfc7c0f89688abb3cc91b99e'){throw 'EXACT_B48_PAIR_BEFORE_REQUIRED'}
if((Get-FileHash -LiteralPath $pairCap.established_guard_helper_path -Algorithm SHA256).Hash.ToLowerInvariant() -cne $pairCap.established_guard_helper_fact.sha256){throw 'UNCHANGED_METADATA_HELPER_REQUIRED'}
. $pairCap.established_guard_helper_path
$pairGame=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$pairSource=Resolve-CityNavSource $pairKey $pairGame
$pairFresh=Get-CityNavSourceFact $pairSource
if(-not(Test-CityNavSourceSame $pairFresh $pairBefore)){throw 'PAIR_SHA_BYTES_TICKS_MUST_EQUAL_ORIGINAL208_BEFORE'}
$pairOutput=Assert-CityNavNewOutput $Output $PSScriptRoot
$pairBackup=Assert-CityNavNewOutput (Join-Path $PSScriptRoot 'navigation_pairs_before_EXACT.gd.source') $PSScriptRoot
$pairReader=[IO.File]::OpenRead($pairSource)
$pairWriter=[IO.File]::Open($pairBackup,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$pairReader.CopyTo($pairWriter)}finally{$pairReader.Dispose();$pairWriter.Dispose()}
[IO.File]::SetLastWriteTimeUtc($pairBackup,[DateTime]::new([long]$pairFresh.utc_ticks,[DateTimeKind]::Utc))
$pairBackupFact=Get-CityNavSourceFact $pairBackup
if(-not(Test-CityNavSourceSame $pairFresh $pairBackupFact) -or -not(Test-CityNavSourceSame $pairFresh (Get-CityNavSourceFact $pairSource))){throw 'EXACT_PAIR_FULL_BACKUP_AND_STABLE_SOURCE_REQUIRED'}
$pairResult=[ordered]@{
 schema='CITY_NAVIGATION_ROADMOUTHS_20261102A_PAIR_SUPPLEMENT_CAPTURE_V1';captured_successfully=$true
 original_capture_path=[IO.Path]::GetFullPath($Capture);original_capture_sha256=$pairCaptureSHA
 target=$pairKey;before_fact=$pairFresh;full_backup=[ordered]@{path=$pairBackup;fact=$pairBackupFact}
 exact_original208_fact=$true;original208_capture_rewritten=$false;old134_overlap=0
 scope='Only yamen_artisan/a mouth720970->720840 and arrival824970->824840; retired original720970 retained; remaining21endpoint values exact. This capture grants no source writes.'
 save_metadata_passes=0;save_content_reads=0;save_hashes=0;save_writes=0;engine_runs=0;source_writes=0
 capture_script_fact=(Get-CityNavSourceFact $PSCommandPath)
}
Write-CityNavNewJson $pairOutput $pairResult
[ordered]@{path=$pairOutput;sha256=(Get-CityNavSourceFact $pairOutput).sha256;target=$pairKey;full_backups=1;original208_fact_exact=$true;save_metadata_passes=0}|ConvertTo-Json -Depth 3
