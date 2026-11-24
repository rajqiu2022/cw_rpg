param(
 [Parameter(Mandatory=$true)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$ClosureSha256,
 [string]$Closure=(Join-Path $PSScriptRoot '../luoyang_navigation_docks_20261101d_successor03/candidate_closure_READY.json'),
 [string]$Output=(Join-Path $PSScriptRoot 'capture_two_ACTUAL.json')
)
$ErrorActionPreference='Stop'
$threeGame=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$threeGuard=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../city_navigation_20261101d_guard01'))
$threeBeforePath=Join-Path $threeGuard 'capture_before_ACTUAL.json'
$threePriorPath=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../city_navigation_20261101d_supplement02/capture_targets_ACTUAL.json'))
if((Get-FileHash -LiteralPath $Closure -Algorithm SHA256).Hash.ToLowerInvariant() -cne $ClosureSha256.ToLowerInvariant() -or $ClosureSha256.ToLowerInvariant() -cne '8f31c3ea81b4b82a06a9eb99c88478ba3277d3ad2747ce2c36e72adf41af2de4'){throw 'ROOT_EXPLICIT_TWO_AC_SUCCESSOR03_CLOSURE_REQUIRED'}
if((Get-FileHash -LiteralPath $threeBeforePath -Algorithm SHA256).Hash.ToLowerInvariant() -cne 'eea89408e036ffcde39c315cead06714decb4edb46ccc555f600c2ec8078f77b'){throw 'ORIGINAL113_CAPTURE_CHANGED'}
if((Get-FileHash -LiteralPath $threePriorPath -Algorithm SHA256).Hash.ToLowerInvariant() -cne '9201d551d9c144f994d950bf7f0d16b10f9ccbafe465edeb2fd02ffa1743c392'){throw 'PRESERVE_FRESH21_CAPTURE'}
$threeBefore=Get-Content -LiteralPath $threeBeforePath -Raw|ConvertFrom-Json
$threePrior=Get-Content -LiteralPath $threePriorPath -Raw|ConvertFrom-Json
$threeHelpers=Join-Path $threeGuard 'guard_helpers_ROOT_ONLY.ps1'
$threeHelperKey='res://build/city_navigation_20261101d_guard01/guard_helpers_ROOT_ONLY.ps1'
if((Get-FileHash -LiteralPath $threeHelpers -Algorithm SHA256).Hash.ToLowerInvariant() -cne $threeBefore.before_facts.$threeHelperKey.sha256){throw 'ORIGINAL_HELPER_CHANGED'}
. $threeHelpers
$threeOutput=Assert-CityNavNewOutput $Output $PSScriptRoot
$threeClosure=Get-Content -LiteralPath $Closure -Raw|ConvertFrom-Json
if($threeClosure.schema -ne 'CITYNAV_DOCKS_20261101D_EXACT9_SNAPSHOTS_TWO_TARGET_SUCCESSOR03_V1' -or @($threeClosure.actual_targets).Count -ne 2 -or @($threeClosure.exact9_added).Count -ne 9 -or $threeClosure.actual_C_count -ne 2583 -or $threeClosure.previous_B_expected_count -ne 2574 -or $threeClosure.virtual_B_expected_count -ne 2583 -or @($threeClosure.new_runtime_sources.PSObject.Properties).Count -ne 0){throw 'FINITE_EXACT9_TWO_AC_SUCCESSOR_REQUIRED'}
$threeSecond=Get-Content -LiteralPath $threePrior.closure_path -Raw|ConvertFrom-Json
if((Get-CityNavSourceFact $threePrior.closure_path).sha256 -cne '1ca6d7cff41408c42e0153e155787df170479a5189fcaf00f6cee6e014f13124'){throw 'ORIGINAL21_CLOSURE_CHANGED'}
$threeHunks=[IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $Closure) 'all_source_hunks_READY.json'))
if((Get-CityNavSourceFact $threeHunks).sha256 -cne '845efe861b735668ac64133ad203c0f67facba176c0e0fa16a849c33e1923839'){throw 'EXACT03_HUNKS_REQUIRED'}
$threeManifestPath=Resolve-CityNavSource $threeBefore.candidate_manifest $threeGame
if((Get-CityNavSourceFact $threeManifestPath).sha256 -cne '760534d8b33534c083d8e5537bb8e4287daf66409f7fddc5fb081090b22f1fa2'){throw 'PRESERVE_EXPLICIT96_ART_SUCCESSOR'}
$threeManifest=Get-Content -LiteralPath $threeManifestPath -Raw|ConvertFrom-Json
$threeExpected=[ordered]@{
 'res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/manifest.json'='1ce6ccbc184c730775500d0c70cc45d498c5ac68ccf824afcc7d18ced2489941'
 'res://scripts/city/luoyang_docks_workyard_index_20261019ac.gd'='01fbaa67c4d66824e1cc6bfb69b865a7c436ec60f645bcd15c7b9b6ea96c1958'
}
$threeFacts=[ordered]@{};$threeBackups=[ordered]@{};$threeCandidateFacts=[ordered]@{};$threeOrdinal=0
foreach($row in $threeClosure.actual_targets){
 $key=[string]$row.res_path
 if(-not $threeExpected.Contains($key) -or $threeFacts.Contains($key) -or $null -ne $threeBefore.before_facts.PSObject.Properties[$key] -or $null -ne $threeManifest.source_pins.PSObject.Properties[$key]){throw 'EXACT_TWO_OUTSIDE113_96_REQUIRED'}
 $priorRows=@($threeSecond.actual_targets|Where-Object{$_.res_path -ceq $key})
 if($priorRows.Count -ne 1 -or $row.before_sha256 -cne $threeExpected[$key] -or $row.before_sha256 -cne $priorRows[0].after_sha256 -or $row.before_bytes -ne $priorRows[0].after_bytes){throw 'STAGE3_BEFORE_MUST_EQUAL_APPROVED21_AFTER'}
 $absolute=Resolve-CityNavSource $key $threeGame;$fact=Get-CityNavSourceFact $absolute
 if($fact.sha256 -cne $row.before_sha256 -or $fact.bytes -ne $row.before_bytes -or $fact.stable -ne $true){throw ('FRESH_CAPTURE_MUST_PRECEDE_TWO03_WRITES:'+ $key)}
 $snapshot=Get-CityNavSourceFact (Resolve-CityNavSource $row.stage2_full_before_snapshot $threeGame)
 if($snapshot.sha256 -cne $fact.sha256 -or $snapshot.bytes -ne $fact.bytes){throw 'STAGE2_FULL_SNAPSHOT_EXACT_CURRENT_REQUIRED'}
 $candidate=Get-CityNavSourceFact (Resolve-CityNavSource $row.candidate $threeGame)
 if($candidate.sha256 -cne $row.after_sha256 -or $candidate.bytes -ne $row.after_bytes){throw 'EXACT_TWO03_REVIEW_CANDIDATES_REQUIRED'}
 $threeOrdinal++;$name=('{0:D2}_' -f $threeOrdinal)+[IO.Path]::GetFileName($absolute)+'.stage3_before_EXACT'
 $backup=Assert-CityNavNewOutput (Join-Path $PSScriptRoot $name) $PSScriptRoot
 $readStream=[IO.File]::OpenRead($absolute);$writeStream=[IO.File]::Open($backup,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$readStream.CopyTo($writeStream)}finally{$readStream.Dispose();$writeStream.Dispose()}
 [IO.File]::SetLastWriteTimeUtc($backup,[DateTime]::new([long]$fact.utc_ticks,[DateTimeKind]::Utc))
 $backupFact=Get-CityNavSourceFact $backup
 if(-not(Test-CityNavSourceSame $fact $backupFact) -or -not(Test-CityNavSourceSame $fact (Get-CityNavSourceFact $absolute))){throw 'FRESH03_FULL_BACKUP_STABILITY_REQUIRED'}
 $threeFacts[$key]=$fact;$threeBackups[$key]=[ordered]@{path=$backup;fact=$backupFact};$threeCandidateFacts[$key]=$candidate
}
$threeSnapshotFacts=[ordered]@{}
foreach($row in $threeClosure.exact9_added){$value=Get-CityNavSourceFact (Resolve-CityNavSource $row.path $threeGame);if($value.sha256 -cne $row.actual -or $value.stable -ne $true){throw 'EXACT_NINE_APPROVED_ROUTER_SNAPSHOT_HASHES_REQUIRED'};$threeSnapshotFacts[$row.path]=$value}
$threeDiagPath=Resolve-CityNavSource $threeClosure.actual_Root_diagnostic $threeGame
if((Get-CityNavSourceFact $threeDiagPath).sha256 -cne $threeClosure.actual_Root_diagnostic_sha256){throw 'PRESERVE_REAL115984_C2583_EVIDENCE'}
$threeResult=[ordered]@{
 schema='CITY_NAVIGATION_20261101D_FRESH2_SUPPLEMENT03_V1';captured_successfully=$true;captured_utc=[DateTime]::UtcNow.ToString('o')
 closure_path=[IO.Path]::GetFullPath($Closure);closure_fact=(Get-CityNavSourceFact $Closure);hunks_path=$threeHunks;hunks_fact=(Get-CityNavSourceFact $threeHunks)
 original_capture_path=$threeBeforePath;original_capture_sha256='eea89408e036ffcde39c315cead06714decb4edb46ccc555f600c2ec8078f77b'
 prior21_capture_path=$threePriorPath;prior21_capture_sha256='9201d551d9c144f994d950bf7f0d16b10f9ccbafe465edeb2fd02ffa1743c392'
 target_count=2;before_facts=$threeFacts;full_backups=$threeBackups;candidate_facts=$threeCandidateFacts
 targets_are_subset_of21=$true;distinct_authorized_old_target_count_still21=21;intersects113=0;intersects96=0
 exact9_approved_snapshot_facts=$threeSnapshotFacts;actual_diagnostic_path=$threeDiagPath;actual_diagnostic_fact=(Get-CityNavSourceFact $threeDiagPath)
 candidate96_manifest_fact=(Get-CityNavSourceFact $threeManifestPath);capture_script_fact=(Get-CityNavSourceFact $PSCommandPath)
 save_metadata_passes=0;save_content_reads=0;save_hashes=0;save_writes=0;save_deserializations=0;old_source_writes=0;engine_runs=0;original_baselines_rewritten=$false;automatic_restore=$false
 authorization='FRESH_BEFORE_ONLY; Root separately approves exact two stage3afters; final02mustnotrun; original113final only once at final03'
}
Write-CityNavNewJson $threeOutput $threeResult
[ordered]@{path=$threeOutput;sha256=(Get-CityNavSourceFact $threeOutput).sha256;fresh_targets=2;full_backups=2;distinct_old_targets_still21=21;approved_snapshots=9;save_metadata_passes=0}|ConvertTo-Json -Depth 3
