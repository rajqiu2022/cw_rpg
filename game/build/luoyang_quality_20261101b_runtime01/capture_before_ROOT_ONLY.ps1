param([string]$Output = (Join-Path $PSScriptRoot 'capture_before_ACTUAL.json'))
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'guard_facts_ROOT_ONLY.ps1')
$qualityOutput = Assert-QualityNewOutput $Output $PSScriptRoot
$qualityGame = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$qualityRepo = [IO.Path]::GetFullPath((Join-Path $qualityGame '..'))
$qualityPriorPath = Join-Path $qualityGame 'build/riverside_visual_20261101a_source01/final_guard_ACTUAL.json'
$qualityPrior = Get-Content -Raw -LiteralPath $qualityPriorPath | ConvertFrom-Json
if ($qualityPrior.passed -ne $true -or @($qualityPrior.save_facts.PSObject.Properties).Count -ne 171) { throw 'PRIOR_20261101A_PASSED_GUARD_WITH171_METADATA_REQUIRED' }
$qualityProject = Join-Path $qualityGame 'project.godot'
$qualityProjectText = [IO.File]::ReadAllText($qualityProject)
if ($qualityProjectText -match '(?m)^SceneArtQualityRuntime=') { throw 'CAPTURE_MUST_PRECEDE_THE_ONLY_AUTHORIZED_AUTOLOAD_LINE' }
$qualityPaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
function Add-QualityGamePath([string]$Relative) {
    $absolute = [IO.Path]::GetFullPath((Join-Path $qualityGame $Relative)).Replace('\','/')
    if (-not $absolute.StartsWith($qualityGame.Replace('\','/') + '/', [StringComparison]::OrdinalIgnoreCase)) { throw 'BOUNDED_PROTECTED_PATH_OUTSIDE_GAME' }
    [void]$qualityPaths.Add($absolute)
}
# Retain the finite 11-01a source boundary (41 facts), rehash it fresh; never
# traverse/re-hash its historical 3236-source ancestor or user directories.
foreach ($property in $qualityPrior.facts.PSObject.Properties) {
    if (-not $property.Name.StartsWith($qualityGame.Replace('\','/') + '/', [StringComparison]::OrdinalIgnoreCase)) { throw 'PRIOR_BOUNDED_GAME_SOURCE_ONLY' }
    [void]$qualityPaths.Add($property.Name.Replace('\','/'))
}
@(
    'build/luoyang_regions_20261027d_source01/region_field.gd',
    'build/luoyang_regions_20261027d_source01/region_entry.gd',
    'build/luoyang_regions_20261027d_source01/region_session.gd',
    'build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json',
    'build/luoyang_regions_20261027d_source01/router_region_dispatch.gd',
    'scripts/autoload/scene_router.gd',
    'scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd',
    'scripts/city/luoyang_enclosure_v11_candidate_contract.gd',
    'scripts/city/luoyang_precomputed_bundle_20261018r.gd',
    'scripts/city/luoyang_precomputed_bundle_index_20261018r.gd',
    'scripts/city/luoyang_execution_authority_20261022ap.gd',
    'scripts/city/luoyang_execution_index_20261022ap.gd',
    'data/maps/luoyang_full_city_20261022ap/execution_successor.json',
    'data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json',
    'scripts/adventure/adventure_runtime.gd', 'scripts/adventure/adventure_minimap.gd',
    'build/adventure_world_20261031f_system01/world_links.gd',
    'build/world_coast_20261031h_system01/world_v16_scene03.tres',
    'build/world_coast_20261031h_system01/world_v16_layout02.tres',
    'build/world_coast_20261031h_system01/world_v16_stream02.tres',
    'scripts/world/world_v15_visible_stream_20261018r.gd',
    'scripts/world/world_v15_stream_overlap_20261018r.gd',
    'scripts/world/v15_modular_overlap.gd'
) | ForEach-Object { Add-QualityGamePath $_ }
$qualityRegion = Get-Content -Raw -LiteralPath (Join-Path $qualityGame 'build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json') | ConvertFrom-Json
if (@($qualityRegion.compiled_bindings.PSObject.Properties).Count -ne 10) { throw 'EXACT_TEN_CURRENT_REGION_BINS_REQUIRED' }
foreach ($property in $qualityRegion.compiled_bindings.PSObject.Properties) {
    if (-not $property.Value.path.StartsWith('res://')) { throw 'REGION_BINDING_PATH' }
    Add-QualityGamePath $property.Value.path.Substring(6)
}
$qualityWorldPath = Join-Path $qualityGame 'art/maps/world_coast_20261031h/candidate02/runtime_contract03.json'
$qualityWorld = Get-Content -Raw -LiteralPath $qualityWorldPath | ConvertFrom-Json
if ($qualityWorld.coordinate_version -ne 16 -or @($qualityWorld.changed_cells).Count -ne 14) { throw 'CURRENT_WORLD16_FINITE14_CELL_CONTRACT_REQUIRED' }
foreach ($path in @($qualityWorld.geometry.rf_path, $qualityWorld.geometry.mesh_path)) { Add-QualityGamePath $path.Substring(6) }
foreach ($cell in $qualityWorld.changed_cells) {
    Add-QualityGamePath $cell.nav_path.Substring(6)
    Add-QualityGamePath $cell.visual_path.Substring(6)
}
$qualityBefore = [ordered]@{}
foreach ($path in ($qualityPaths | Sort-Object)) {
    if ($path -eq $qualityProject.Replace('\','/')) { continue }
    $fact = Get-QualityFact $path
    if (-not $fact.exists -or -not $fact.stable_during_hash) { throw ('PROTECTED_SOURCE_MISSING_OR_UNSTABLE:' + $path) }
    $qualityBefore[$path] = $fact
}
$qualityProjectBefore = Get-QualityFact $qualityProject
$qualityBackup = Assert-QualityNewOutput (Join-Path $PSScriptRoot 'project_BEFORE.godot') $PSScriptRoot
[IO.File]::WriteAllBytes($qualityBackup, [IO.File]::ReadAllBytes($qualityProject))
[IO.File]::SetLastWriteTimeUtc($qualityBackup, [DateTime]::new([long]$qualityProjectBefore.utc_ticks, [DateTimeKind]::Utc))
$qualityBackupFact = Get-QualityFact $qualityBackup
if (-not (Test-QualityFactSame $qualityProjectBefore (Get-QualityFact $qualityProject)) -or -not (Test-QualityFactSame $qualityProjectBefore $qualityBackupFact)) { throw 'EXACT_PROJECT_BYTE_AND_UTC_TICKS_BACKUP_REFUSED' }
$qualitySaves = [ordered]@{}; $qualityChangedSincePrior = @()
foreach ($property in $qualityPrior.save_facts.PSObject.Properties) {
    if (-not $property.Name.Replace('\','/').StartsWith('C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/', [StringComparison]::OrdinalIgnoreCase)) { throw 'REGISTERED_SAVE_METADATA_PATH_DOMAIN' }
    $now = Get-QualityFact $property.Name
    if (-not $now.stable_during_hash) { throw ('SAVE_CHANGED_DURING_METADATA_HASH_NO_RESTORE:' + $property.Name) }
    $qualitySaves[$property.Name] = $now
    if (-not (Test-QualityFactSame $now $property.Value)) { $qualityChangedSincePrior += [ordered]@{path=$property.Name;historical=$property.Value;fresh_before=$now;policy='EXTERNAL_BEFORE_CAPTURE_RETAINED_NO_RESTORE'} }
}
$qualityResult = [ordered]@{
    captured_successfully=$true;scope='BOUNDED_FRESH_OLD_SOURCES_PLUS171_SAVE_METADATA_NOT3236_REHASH'
    captured_utc=[DateTime]::UtcNow.ToString('o');prior_guard_path=$qualityPriorPath.Replace('\','/');prior_guard_fact=(Get-QualityFact $qualityPriorPath)
    prior_3236_credit='HISTORICAL_ONLY_NOT_REHASHED_OR_REAPPROVED'
    only_authorized_old_target=$qualityProject.Replace('\','/');authorized_project_before=$qualityProjectBefore
    project_backup_path=$qualityBackup.Replace('\','/');project_backup_fact=$qualityBackupFact
    allowed_autoload_line='SceneArtQualityRuntime="*res://build/luoyang_quality_20261101b_runtime01/scene_art_quality_runtime.gd"'
    frozen_before_facts=$qualityBefore;frozen_source_count=$qualityBefore.Count
    save_facts=$qualitySaves;save_count=$qualitySaves.Count;absent_save_count=@($qualitySaves.Values|Where-Object{-not $_.exists}).Count
    retained_prior_external_save_history=$qualityPrior.retained_user_save_changes_before_capture
    fresh_save_changes_since_prior_guard=$qualityChangedSincePrior
    old_guard_edits=0;engine_runs=0;process_control=0;production_writes=0;save_deserializations=0;save_writes=0;automatic_restore=$false
}
Write-QualityNewJson $qualityOutput $qualityResult
[ordered]@{output=$qualityOutput;sha256=(Get-QualityFact $qualityOutput).sha256;frozen_sources=$qualityBefore.Count;saves=$qualitySaves.Count;absent=$qualityResult.absent_save_count;external_save_changes_since_prior=$qualityChangedSincePrior.Count}|ConvertTo-Json
