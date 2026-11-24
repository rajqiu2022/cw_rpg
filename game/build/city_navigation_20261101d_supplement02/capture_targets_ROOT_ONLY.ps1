param(
 [Parameter(Mandatory=$true)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$ClosureSha256,
 [string]$Closure=(Join-Path $PSScriptRoot '../luoyang_navigation_docks_20261101d_successor02/candidate_closure_READY.json'),
 [string]$Output=(Join-Path $PSScriptRoot 'capture_targets_ACTUAL.json')
)
$ErrorActionPreference='Stop'
$capGame=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$capGuard=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../city_navigation_20261101d_guard01'))
$capBeforePath=Join-Path $capGuard 'capture_before_ACTUAL.json'
$capQuarterPath=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../city_navigation_20261101d_supplement01/capture_two_ACTUAL.json'))
if((Get-FileHash -LiteralPath $Closure -Algorithm SHA256).Hash.ToLowerInvariant() -cne $ClosureSha256.ToLowerInvariant() -or $ClosureSha256.ToLowerInvariant() -cne '1ca6d7cff41408c42e0153e155787df170479a5189fcaf00f6cee6e014f13124'){throw 'ROOT_EXPLICIT_FINITE21_CLOSURE_SHA_REQUIRED'}
if((Get-FileHash -LiteralPath $capBeforePath -Algorithm SHA256).Hash.ToLowerInvariant() -cne 'eea89408e036ffcde39c315cead06714decb4edb46ccc555f600c2ec8078f77b'){throw 'ORIGINAL113_CAPTURE_CHANGED'}
if((Get-FileHash -LiteralPath $capQuarterPath -Algorithm SHA256).Hash.ToLowerInvariant() -cne 'd834f1985068307cefb6805cad8c391cae1ae036d1f33dd2078ce170a0dd29d3'){throw 'QUARTER01_CAPTURE_CHANGED'}
$capBefore=Get-Content -LiteralPath $capBeforePath -Raw|ConvertFrom-Json
$capQuarter=Get-Content -LiteralPath $capQuarterPath -Raw|ConvertFrom-Json
$capHelper=Join-Path $capGuard 'guard_helpers_ROOT_ONLY.ps1'
$capHelperKey='res://build/city_navigation_20261101d_guard01/guard_helpers_ROOT_ONLY.ps1'
if((Get-FileHash -LiteralPath $capHelper -Algorithm SHA256).Hash.ToLowerInvariant() -cne $capBefore.before_facts.$capHelperKey.sha256){throw 'ORIGINAL_HELPER_CHANGED'}
. $capHelper
$capOutput=Assert-CityNavNewOutput $Output $PSScriptRoot
$capClosure=Get-Content -LiteralPath $Closure -Raw|ConvertFrom-Json
if($capClosure.schema -ne 'CITYNAV_DOCKS_20261101D_OFFLINE_CANDIDATE_CLOSURE_V1' -or @($capClosure.actual_targets).Count -ne 21 -or $capClosure.canonical_writes -ne 0){throw 'EXACT21_OFFLINE_CLOSURE_REQUIRED'}
$capHunks=[IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $Closure) 'all_source_hunks_READY.json'))
if((Get-CityNavSourceFact $capHunks).sha256 -cne '89ae2339fc231d72431651b97b55579efdefe2f39733441f14ad69925747081b'){throw 'EXACT_REVIEWED21_HUNK_PROOF_REQUIRED'}
$capManifestPath=Resolve-CityNavSource $capBefore.candidate_manifest $capGame
$capManifestFact=Get-CityNavSourceFact $capManifestPath
if($capManifestFact.sha256 -cne '64b80a6d4c930aec98fb214084ba6dd838cebfa5ff13d498c88c6999262c21e4'){throw 'PRESERVE_FROZEN96_MANIFEST'}
$capManifest=Get-Content -LiteralPath $capManifestPath -Raw|ConvertFrom-Json
if($capManifest.ready -ne $true -or @($capManifest.source_pins.PSObject.Properties).Count -ne 96){throw 'EXACT_FROZEN96_REQUIRED'}
$capQuarterAfter=[ordered]@{
 'res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json'='11583a13e6f0baf3e32f8675398033b49dc58d1314899dfc3d3cfb3e3acce9ec'
 'res://scripts/city/luoyang_quarters_index_20261022ap.gd'='9d534fb69605ed3e4e2e78481ac11549f680637fd46dddc9aa5b62e3e908e1c8'
}
$capSeen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$capFacts=[ordered]@{};$capBackups=[ordered]@{};$capCandidates=[ordered]@{};$capQuarterChains=[ordered]@{};$capOrdinal=0
foreach($row in $capClosure.actual_targets){
 $key=[string]$row.res_path
 if(-not $capSeen.Add($key) -or $null -ne $capBefore.before_facts.PSObject.Properties[$key] -or $null -ne $capManifest.source_pins.PSObject.Properties[$key]){throw ('TARGET_DUPLICATE_OR_INTERSECTS113_96:'+ $key)}
 if($row.in_frozen96 -ne $false -or $row.in_original113 -ne $false){throw 'RECEIPT_INTERSECTION_CLAIM_MISMATCH'}
 $absolute=Resolve-CityNavSource $key $capGame
 if([IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $capGame) $row.path)) -cne $absolute){throw 'CANONICAL_RES_PATH_PAIR_MISMATCH'}
 $fact=Get-CityNavSourceFact $absolute
 if($fact.sha256 -cne $row.before_sha256 -or $fact.bytes -ne $row.before_bytes -or $fact.stable -ne $true){throw ('CAPTURE_MUST_PRECEDE_EXACT21_WRITES:'+ $key)}
 $candidateFact=Get-CityNavSourceFact (Resolve-CityNavSource $row.candidate $capGame)
 if($candidateFact.sha256 -cne $row.after_sha256 -or $candidateFact.bytes -ne $row.after_bytes -or $candidateFact.stable -ne $true){throw ('EXACT21_REVIEW_CANDIDATE_CHANGED:'+ $key)}
 if($capQuarterAfter.Contains($key)){
   if($row.before_sha256 -cne $capQuarterAfter[$key]){throw 'QUARTER_SECOND_STAGE_BEFORE_MUST_EQUAL_STAGE1_AFTER'}
   $qBackup=$capQuarter.full_backups.$key
   if(-not(Test-CityNavSourceSame $qBackup.fact (Get-CityNavSourceFact $qBackup.path))){throw 'PRESERVE_QUARTER01_FULL_BEFORE_BACKUP'}
   $capQuarterChains[$key]=[ordered]@{stage1_before=$capQuarter.before_facts.$key;stage1_backup=$qBackup;stage1_after_sha256=$capQuarterAfter[$key];stage2_before=$fact;stage2_after_sha256=$row.after_sha256}
 }
 $capOrdinal++
 $name=('{0:D2}_' -f $capOrdinal)+[IO.Path]::GetFileName($absolute)+'.before_EXACT'
 $backup=Assert-CityNavNewOutput (Join-Path $PSScriptRoot $name) $PSScriptRoot
 $inStream=[IO.File]::OpenRead($absolute);$outStream=[IO.File]::Open($backup,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$inStream.CopyTo($outStream)}finally{$inStream.Dispose();$outStream.Dispose()}
 [IO.File]::SetLastWriteTimeUtc($backup,[DateTime]::new([long]$fact.utc_ticks,[DateTimeKind]::Utc))
 $backupFact=Get-CityNavSourceFact $backup
 if(-not(Test-CityNavSourceSame $fact $backupFact) -or -not(Test-CityNavSourceSame $fact (Get-CityNavSourceFact $absolute))){throw ('FRESH21_FULL_BACKUP_STABILITY_REQUIRED:'+ $key)}
 $capFacts[$key]=$fact;$capBackups[$key]=[ordered]@{path=$backup;fact=$backupFact};$capCandidates[$key]=$candidateFact
}
if($capQuarterChains.Count -ne 2){throw 'EXACT_TWO_QUARTER_CONTINUOUS_CHAINS_REQUIRED'}
$capNewFacts=[ordered]@{}
foreach($property in $capClosure.new_runtime_sources.PSObject.Properties){
 $fact=Get-CityNavSourceFact (Resolve-CityNavSource $property.Name $capGame)
 if($fact.sha256 -cne [string]$property.Value -or $fact.stable -ne $true){throw 'EXACT_THREE_NEW_RUNTIME_LEAVES_REQUIRED'}
 $capNewFacts[$property.Name]=$fact
}
if($capNewFacts.Count -ne 3){throw 'EXACT3_NEW_RUNTIME_SOURCE_COUNT'}
$capGuardFacts=[ordered]@{}
foreach($name in @('guard_helpers_ROOT_ONLY.ps1','capture_before_ROOT_ONLY.ps1','final_guard_ROOT_ONLY.ps1')){
 $key='res://build/city_navigation_20261101d_guard01/'+$name;$fact=Get-CityNavSourceFact (Join-Path $capGuard $name)
 if(-not(Test-CityNavSourceSame $capBefore.before_facts.$key $fact)){throw 'ORIGINAL_THREE_GUARDS_CHANGED'}
 $capGuardFacts[$key]=$fact
}
$capResult=[ordered]@{
 schema='CITY_NAVIGATION_20261101D_FRESH21_SUPPLEMENT02_V1';captured_successfully=$true;captured_utc=[DateTime]::UtcNow.ToString('o')
 closure_path=[IO.Path]::GetFullPath($Closure);closure_fact=(Get-CityNavSourceFact $Closure);hunks_path=$capHunks;hunks_fact=(Get-CityNavSourceFact $capHunks)
 original_capture_path=$capBeforePath;original_capture_sha256='eea89408e036ffcde39c315cead06714decb4edb46ccc555f600c2ec8078f77b';original_source_count=113
 quarter01_capture_path=$capQuarterPath;quarter01_capture_sha256='d834f1985068307cefb6805cad8c391cae1ae036d1f33dd2078ce170a0dd29d3';quarter_two_stage_chains=$capQuarterChains
 target_count=21;before_facts=$capFacts;full_backups=$capBackups;reviewed_candidate_facts=$capCandidates
 intersects_original113=0;intersects_frozen96=0;intersects_quarter01=2;new_runtime_source_facts=$capNewFacts;new_runtime_source_count=3
 candidate_manifest_path=$capManifestPath;candidate_manifest_fact=$capManifestFact;original_guard_file_facts=$capGuardFacts
 capture_script_fact=(Get-CityNavSourceFact $PSCommandPath);save_metadata_passes=0;save_content_reads=0;save_hashes=0;save_writes=0;save_deserializations=0;old_source_writes=0;engine_runs=0;original_baseline_rewritten=$false;automatic_restore=$false
 authorization='CAPTURE_ONLY_NOT_WRITE_AUTHORITY; Root reviews exact21after separately; Quarter01final must not run against stage2after'
}
Write-CityNavNewJson $capOutput $capResult
[ordered]@{path=$capOutput;sha256=(Get-CityNavSourceFact $capOutput).sha256;targets=21;backups=21;intersects113=0;intersects96=0;quarter_two_stage=2;new_runtime_leaves=3;save_metadata_passes=0}|ConvertTo-Json -Depth 3
