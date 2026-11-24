param(
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$BeforeSha256,
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$CandidateManifestSha256,
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$ProjectAfterSha256,
    [string]$Before = (Join-Path $PSScriptRoot 'capture_before_ACTUAL.json'),
    [string]$Output = (Join-Path $PSScriptRoot 'final_guard_ACTUAL.json')
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'guard_helpers_ROOT_ONLY.ps1')
$navOutput = Assert-CityNavNewOutput $Output $PSScriptRoot
$navGame = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
if ((Get-CityNavSourceFact $Before).sha256 -cne $BeforeSha256.ToLowerInvariant()) { throw 'ROOT_EXPLICIT_CAPTURE_SHA_REQUIRED' }
$navBefore = Get-Content -LiteralPath $Before -Raw | ConvertFrom-Json
if ($navBefore.schema -ne 'CITY_NAVIGATION_20261101D_FINITE_CAPTURE_V1' -or $navBefore.captured_successfully -ne $true -or $navBefore.save_count -ne 171 -or @($navBefore.save_facts.PSObject.Properties).Count -ne 171 -or $navBefore.allowed_autoload_line -cne $CityNavHook) { throw 'EXACT_FINITE_CAPTURE171_REQUIRED' }
if (-not (Test-CityNavSourceSame $navBefore.plan_fact (Get-CityNavSourceFact $navBefore.plan_path)) -or (Get-CityNavSourceFact $navBefore.prior_guard_path).sha256 -cne $navBefore.prior_guard_sha256) { throw 'PLAN_OR_PRIOR_ACCEPTED_GUARD_CHANGED' }
$navErrors = @(); $navFacts = [ordered]@{}
foreach ($property in $navBefore.before_facts.PSObject.Properties) {
    $fact = Get-CityNavSourceFact (Resolve-CityNavSource $property.Name $navGame)
    $navFacts[$property.Name] = $fact
    if ($property.Name -ne 'res://project.godot' -and -not (Test-CityNavSourceSame $property.Value $fact)) { $navErrors += ('IMMUTABLE_SOURCE_CHANGED:'+$property.Name) }
}
$navProject = Resolve-CityNavSource 'res://project.godot' $navGame
if (-not (Test-CityNavSourceSame $navBefore.project_backup_fact (Get-CityNavSourceFact $navBefore.project_backup_path))) { $navErrors += 'EXACT_PROJECT_BACKUP_CHANGED' }
if ($navFacts['res://project.godot'].sha256 -cne $ProjectAfterSha256.ToLowerInvariant() -or -not (Test-CityNavProjectInverse $navProject $navBefore.project_backup_path)) { $navErrors += 'ONLY_ONE_EXACT_NEW_AUTOLOAD_LINE_BYTE_INVERSE_REQUIRED' }
$navManifestPath = Resolve-CityNavSource $navBefore.candidate_manifest $navGame
$navManifestFact = Get-CityNavSourceFact $navManifestPath
if ($navManifestFact.sha256 -cne $CandidateManifestSha256.ToLowerInvariant()) { throw 'ROOT_EXPLICIT_NEW_CANDIDATE_MANIFEST_SHA_REQUIRED' }
$navManifest = Get-Content -LiteralPath $navManifestPath -Raw | ConvertFrom-Json
if ($navManifest.ready -ne $true -or @($navManifest.source_pins.PSObject.Properties).Count -lt 4) { throw 'NEW_INDEPENDENT_ROOT_READY_LEAF_MANIFEST_REQUIRED' }
$navNewFacts = [ordered]@{}
foreach ($property in $navManifest.source_pins.PSObject.Properties) {
    $fact = Get-CityNavSourceFact (Resolve-CityNavSource $property.Name $navGame)
    $navNewFacts[$property.Name] = $fact
    if ($fact.sha256 -cne ([string]$property.Value).ToLowerInvariant() -or $fact.stable -ne $true) { $navErrors += ('NEW_CANDIDATE_EXACT_LEAF_CHANGED:'+$property.Name) }
}
$navSaves = [ordered]@{}; $navSaveChanges = @()
foreach ($property in ($navBefore.save_facts.PSObject.Properties | Sort-Object Name)) {
    $metadata = Get-CityNavSaveMetadata $property.Name
    $navSaves[$property.Name] = $metadata
    if (-not (Test-CityNavMetadataSame $property.Value $metadata)) { $navSaveChanges += [ordered]@{path=$property.Name;before=$property.Value;after=$metadata;policy='PRESERVE_ACTUAL_EXTERNAL_DIFFERENCE_NO_RESTORE'}; $navErrors += ('SAVE_METADATA_CHANGED:'+$property.Name) }
}
$navResult = [ordered]@{
    schema='CITY_NAVIGATION_20261101D_FINITE_FINAL_V1';passed=($navErrors.Count -eq 0);finished_utc=[DateTime]::UtcNow.ToString('o');before_path=[IO.Path]::GetFullPath($Before);before_sha256=$BeforeSha256.ToLowerInvariant()
    scope=$navBefore.scope;control_count=$navBefore.control_count;region_bin_count=10;source_count=$navFacts.Count;facts=$navFacts;allowed_old_changes=@('res://project.godot');allowed_autoload_line=$CityNavHook
    project_after_sha256=$ProjectAfterSha256.ToLowerInvariant();project_byte_inverse=(-not ($navErrors -contains 'ONLY_ONE_EXACT_NEW_AUTOLOAD_LINE_BYTE_INVERSE_REQUIRED'));project_backup_path=$navBefore.project_backup_path;project_backup_fact=$navBefore.project_backup_fact
    candidate_manifest=$navBefore.candidate_manifest;candidate_manifest_fact=$navManifestFact;candidate_source_pin_facts=$navNewFacts;candidate_leaf_count=$navNewFacts.Count
    independent_runtime_manifests=$navBefore.independent_runtime_manifests;save_facts=$navSaves;save_count=171;absent_save_count=@($navSaves.Values|Where-Object {-not $_.exists}).Count;save_metadata_passes_this_script=1;save_metadata_passes_total=2
    save_content_reads=0;save_hashes=0;save_writes=0;save_deserializations=0;automatic_restore=$false;save_changes_preserved=$navSaveChanges;historical_metadata_differences_preserved=$navBefore.historical_metadata_differences_preserved
    engine_runs=0;process_control=0;old_source_writes=0;old_guard_edits=0;errors=$navErrors
}
Write-CityNavNewJson $navOutput $navResult
[ordered]@{passed=$navResult.passed;path=$navOutput;sha256=(Get-CityNavSourceFact $navOutput).sha256;sources=$navFacts.Count;candidate_leaves=$navNewFacts.Count;saves=171;errors=$navErrors}|ConvertTo-Json -Depth 4
if ($navErrors.Count -ne 0) { exit 1 }
