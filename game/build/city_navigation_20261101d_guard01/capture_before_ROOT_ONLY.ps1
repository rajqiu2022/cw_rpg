param(
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$PlanSha256,
    [string]$Plan = (Join-Path $PSScriptRoot 'guard_plan_READY.json'),
    [string]$Output = (Join-Path $PSScriptRoot 'capture_before_ACTUAL.json')
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'guard_helpers_ROOT_ONLY.ps1')
$navOutput = Assert-CityNavNewOutput $Output $PSScriptRoot
$navGame = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$navPlanFact = Get-CityNavSourceFact $Plan
if ($navPlanFact.sha256 -cne $PlanSha256.ToLowerInvariant()) { throw 'ROOT_EXPLICIT_PLAN_SHA_REQUIRED' }
$navPlan = Get-Content -LiteralPath $Plan -Raw | ConvertFrom-Json
if ($navPlan.schema -ne 'CITY_NAVIGATION_20261101D_FINITE_GUARD_PLAN_V1' -or $navPlan.allowed_autoload_line -cne $CityNavHook -or @($navPlan.controls).Count -lt 35 -or @($navPlan.controls).Count -gt 50 -or @($navPlan.region_bins).Count -ne 10) { throw 'FINITE_PLAN_SCOPE_REQUIRED' }
$navPriorPath = Resolve-CityNavSource $navPlan.prior_guard $navGame
if ((Get-CityNavSourceFact $navPriorPath).sha256 -cne '26df2620f9cb1238fab7be85243bfcce9b539c3369bb0ff87187a8fabfa7f806' -or $navPlan.prior_guard_sha256 -cne '26df2620f9cb1238fab7be85243bfcce9b539c3369bb0ff87187a8fabfa7f806') { throw 'EXACT_ACCEPTED_11C_GUARD_REQUIRED' }
$navPrior = Get-Content -LiteralPath $navPriorPath -Raw | ConvertFrom-Json
if ($navPrior.passed -ne $true -or $navPrior.save_count -ne 171 -or @($navPrior.save_facts.PSObject.Properties).Count -ne 171) { throw 'REGISTERED171_PATH_SET_REQUIRED' }
$navProject = Resolve-CityNavSource 'res://project.godot' $navGame
if ([IO.File]::ReadAllText($navProject) -match '(?m)^CityNavigationRuntime=') { throw 'CAPTURE_MUST_PRECEDE_NEW_AUTOLOAD_HOOK' }
$navPaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($path in @($navPlan.controls) + @($navPlan.region_bins) + @($navPlan.guard_files)) { [void]$navPaths.Add([string]$path) }
$navRuntime = [ordered]@{}
foreach ($binding in $navPlan.independent_runtime_manifests) {
    $absolute = Resolve-CityNavSource $binding.path $navGame
    $fact = Get-CityNavSourceFact $absolute
    if ($fact.sha256 -cne $binding.sha256) { throw ('EXACT_PRIOR_RUNTIME_MANIFEST_REQUIRED:'+$binding.path) }
    $manifest = Get-Content -LiteralPath $absolute -Raw | ConvertFrom-Json
    if ($manifest.ready -ne $true -or @($manifest.source_pins.PSObject.Properties).Count -ne $binding.leaf_count) { throw 'FROZEN60_AND16_RUNTIME_LEAVES_REQUIRED' }
    $navRuntime[$binding.path] = [ordered]@{sha256=$binding.sha256;leaf_count=$binding.leaf_count;expected_source_pins=$manifest.source_pins}
    foreach ($leaf in $manifest.source_pins.PSObject.Properties) {
        [void]$navPaths.Add($leaf.Name)
        if ($leaf.Name -ne 'res://project.godot' -and (Get-CityNavSourceFact (Resolve-CityNavSource $leaf.Name $navGame)).sha256 -cne $leaf.Value) { throw ('PRIOR_RUNTIME_LEAF_CHANGED:'+$leaf.Name) }
    }
}
$navFacts = [ordered]@{}
foreach ($path in ($navPaths | Sort-Object)) {
    $fact = Get-CityNavSourceFact (Resolve-CityNavSource $path $navGame)
    if ($fact.stable -ne $true) { throw ('SOURCE_CHANGED_DURING_CAPTURE:'+$path) }
    $navFacts[$path] = $fact
}
$navBackupPath = Assert-CityNavNewOutput (Join-Path $PSScriptRoot 'project_before_EXACT.godot') $PSScriptRoot
$navProjectBefore = $navFacts['res://project.godot']
$sourceStream = [IO.File]::OpenRead($navProject)
$targetStream = [IO.File]::Open($navBackupPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try { $sourceStream.CopyTo($targetStream) } finally { $sourceStream.Dispose();$targetStream.Dispose() }
[IO.File]::SetLastWriteTimeUtc($navBackupPath,[DateTime]::new([long]$navProjectBefore.utc_ticks,[DateTimeKind]::Utc))
$navBackupFact = Get-CityNavSourceFact $navBackupPath
if (-not (Test-CityNavSourceSame $navProjectBefore $navBackupFact) -or -not (Test-CityNavSourceSame $navProjectBefore (Get-CityNavSourceFact $navProject))) { throw 'PROJECT_EXACT_BEFORE_BACKUP_REQUIRED' }
$navSaves = [ordered]@{}; $navHistory = @()
foreach ($property in ($navPrior.save_facts.PSObject.Properties | Sort-Object Name)) {
    $metadata = Get-CityNavSaveMetadata $property.Name
    $navSaves[$property.Name] = $metadata
    if (-not (Test-CityNavMetadataSame $property.Value $metadata)) { $navHistory += [ordered]@{path=$property.Name;historical_metadata=[ordered]@{exists=$property.Value.exists;bytes=$property.Value.bytes;utc_ticks=$property.Value.utc_ticks};fresh_before_metadata=$metadata;policy='USER_EXTERNAL_BEFORE_CAPTURE_KEEP_CURRENT_NO_RESTORE'} }
}
if ($navSaves.Count -ne 171 -or @($navSaves.Values | Where-Object {-not $_.exists}).Count -ne 9) { throw 'EXPECTED171_WITH9_ABSENT_METADATA_REQUIRED' }
$navResult = [ordered]@{
    schema='CITY_NAVIGATION_20261101D_FINITE_CAPTURE_V1';captured_successfully=$true;captured_utc=[DateTime]::UtcNow.ToString('o')
    plan_path=[IO.Path]::GetFullPath($Plan);plan_fact=$navPlanFact;prior_guard_path=$navPriorPath;prior_guard_sha256=$navPlan.prior_guard_sha256
    scope='EXPLICIT45_CONTROLS_10_BINS_PLUS_EXISTING60_AND16_RUNTIME_LEAVES_DEDUP_NOT183_OR3236'
    control_count=@($navPlan.controls).Count;region_bin_count=10;source_count=$navFacts.Count;before_facts=$navFacts;independent_runtime_manifests=$navRuntime
    allowed_autoload_line=$CityNavHook;project_backup_path=$navBackupPath;project_backup_fact=$navBackupFact;candidate_manifest=$navPlan.candidate_manifest
    save_facts=$navSaves;save_count=171;absent_save_count=9;save_metadata_passes=1;save_content_reads=0;save_hashes=0;save_writes=0;save_deserializations=0;automatic_restore=$false
    historical_metadata_differences_preserved=$navHistory;engine_runs=0;process_control=0;old_source_writes=0;old_guard_edits=0
}
Write-CityNavNewJson $navOutput $navResult
[ordered]@{path=$navOutput;sha256=(Get-CityNavSourceFact $navOutput).sha256;controls=$navResult.control_count;sources=$navFacts.Count;bins=10;runtime_leaves=@(60,16);saves=171;absent=9;save_content_reads=0;save_hashes=0}|ConvertTo-Json -Depth 3
