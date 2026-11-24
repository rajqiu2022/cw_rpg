param(
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$BeforeSha256,
    [string]$Before=(Join-Path $PSScriptRoot '../city_navigation_20261101d_guard01/capture_before_ACTUAL.json'),
    [string]$Output=(Join-Path $PSScriptRoot 'capture_two_ACTUAL.json')
)
$ErrorActionPreference='Stop'
$supGame=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$supGuard=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../city_navigation_20261101d_guard01'))
if ((Get-FileHash -LiteralPath $Before -Algorithm SHA256).Hash.ToLowerInvariant() -cne $BeforeSha256.ToLowerInvariant()) { throw 'ROOT_EXPLICIT_ORIGINAL113_CAPTURE_SHA_REQUIRED' }
$supBefore=Get-Content -LiteralPath $Before -Raw | ConvertFrom-Json
if ($supBefore.schema -ne 'CITY_NAVIGATION_20261101D_FINITE_CAPTURE_V1' -or $supBefore.source_count -ne 113 -or $supBefore.captured_successfully -ne $true) { throw 'ORIGINAL113_BASELINE_REQUIRED' }
$supHelpers=Join-Path $supGuard 'guard_helpers_ROOT_ONLY.ps1'
$supHelperKey='res://build/city_navigation_20261101d_guard01/guard_helpers_ROOT_ONLY.ps1'
if ((Get-FileHash -LiteralPath $supHelpers -Algorithm SHA256).Hash.ToLowerInvariant() -cne $supBefore.before_facts.$supHelperKey.sha256) { throw 'ORIGINAL_HELPER_CHANGED' }
. $supHelpers
$supOutput=Assert-CityNavNewOutput $Output $PSScriptRoot
$supTargets=[ordered]@{
 'res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json'=@('841c9dc0b948326ad249394605a24cf5be6eb5dd2887099e6194a6aee67a9c1e',218285)
 'res://scripts/city/luoyang_quarters_index_20261022ap.gd'=@('ffada93bd159c2f7fd5049219e47d8af9dfe2bb19960db53086a04deea3f9a97',452)
}
$supManifestPath=Resolve-CityNavSource $supBefore.candidate_manifest $supGame
$supManifest=Get-Content -LiteralPath $supManifestPath -Raw | ConvertFrom-Json
if ($supManifest.ready -ne $true -or @($supManifest.source_pins.PSObject.Properties).Count -ne 96) { throw 'EXISTING_FROZEN96_MANIFEST_REQUIRED' }
$supFacts=[ordered]@{};$supBackups=[ordered]@{}
foreach ($key in $supTargets.Keys) {
    if ($null -ne $supBefore.before_facts.PSObject.Properties[$key] -or $null -ne $supManifest.source_pins.PSObject.Properties[$key]) { throw ('SUPPLEMENT_TARGET_ALREADY_IN_STRICT_OR96:'+ $key) }
    $absolute=Resolve-CityNavSource $key $supGame
    $fact=Get-CityNavSourceFact $absolute
    if ($fact.sha256 -cne $supTargets[$key][0] -or $fact.bytes -ne $supTargets[$key][1] -or $fact.stable -ne $true) { throw ('FRESH_BEFORE_EXACT_TWO_REQUIRED:'+ $key) }
    $name=if($key.EndsWith('/manifest.json')){'quarter_manifest_before_EXACT.json'}else{'quarter_index_before_EXACT.gd'}
    $backup=Assert-CityNavNewOutput (Join-Path $PSScriptRoot $name) $PSScriptRoot
    $inputStream=[IO.File]::OpenRead($absolute)
    $outputStream=[IO.File]::Open($backup,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try { $inputStream.CopyTo($outputStream) } finally { $inputStream.Dispose();$outputStream.Dispose() }
    [IO.File]::SetLastWriteTimeUtc($backup,[DateTime]::new([long]$fact.utc_ticks,[DateTimeKind]::Utc))
    $backupFact=Get-CityNavSourceFact $backup
    if (-not(Test-CityNavSourceSame $fact $backupFact) -or -not(Test-CityNavSourceSame $fact (Get-CityNavSourceFact $absolute))) { throw ('EXACT_FRESH_FULL_BACKUP_REQUIRED:'+ $key) }
    $supFacts[$key]=$fact
    $supBackups[$key]=[ordered]@{path=$backup;fact=$backupFact}
}
$supScriptFacts=[ordered]@{}
foreach($name in @('guard_helpers_ROOT_ONLY.ps1','capture_before_ROOT_ONLY.ps1','final_guard_ROOT_ONLY.ps1')) {
    $path=Join-Path $supGuard $name
    $key='res://build/city_navigation_20261101d_guard01/'+$name
    $fact=Get-CityNavSourceFact $path
    if (-not(Test-CityNavSourceSame $supBefore.before_facts.$key $fact)) { throw 'ORIGINAL_THREE_GUARD_FILES_CHANGED' }
    $supScriptFacts[$key]=$fact
}
$supResult=[ordered]@{
 schema='CITY_NAVIGATION_20261101D_FRESH_TWO_SUPPLEMENT_V1';captured_successfully=$true;captured_utc=[DateTime]::UtcNow.ToString('o')
 original_capture_path=[IO.Path]::GetFullPath($Before);original_capture_sha256=$BeforeSha256.ToLowerInvariant();original_source_count=113
 before_facts=$supFacts;target_count=2;full_backups=$supBackups;original_guard_file_facts=$supScriptFacts
 candidate_manifest_path=$supManifestPath;candidate_manifest_fact=(Get-CityNavSourceFact $supManifestPath);candidate_leaf_count=96
 current_project_fact=(Get-CityNavSourceFact (Resolve-CityNavSource 'res://project.godot' $supGame))
 capture_script_fact=(Get-CityNavSourceFact $PSCommandPath)
 original_baseline_rewritten=$false;original_strict_scope_unchanged=$true;save_metadata_passes=0;save_content_reads=0;save_hashes=0;save_writes=0;save_deserializations=0
 old_source_writes=0;engine_runs=0;automatic_restore=$false;authorization='CAPTURE_ONLY_NOT_WRITE_AUTHORITY; Root must separately approve exact two after hashes'
}
Write-CityNavNewJson $supOutput $supResult
[ordered]@{path=$supOutput;sha256=(Get-CityNavSourceFact $supOutput).sha256;target_count=2;backup_count=2;original_sources=113;save_metadata_passes=0;old_source_writes=0}|ConvertTo-Json -Depth 3
