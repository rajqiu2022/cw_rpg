param(
    [Parameter(Mandatory=$true)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$BeforeSha256,
    [string]$Before = (Join-Path $PSScriptRoot 'capture_before_ACTUAL.json'),
    [string]$Expected = (Join-Path $PSScriptRoot 'source_pins_READY.json'),
    [string]$Output = (Join-Path $PSScriptRoot 'final_guard_ACTUAL.json')
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'guard_facts_ROOT_ONLY.ps1')
$qualityOutput = Assert-QualityNewOutput $Output $PSScriptRoot
if ((Get-QualityFact $Before).sha256 -ne $BeforeSha256.ToLowerInvariant()) { throw 'ROOT_EXACT_CAPTURE_REPORT_SHA_REQUIRED' }
$qualityBefore = Get-Content -Raw -LiteralPath $Before | ConvertFrom-Json
$qualityExpected = Get-Content -Raw -LiteralPath $Expected | ConvertFrom-Json
if ($qualityBefore.captured_successfully -ne $true -or $qualityBefore.save_count -ne 171 -or @($qualityBefore.save_facts.PSObject.Properties).Count -ne 171) { throw 'FRESH_CAPTURE_WITH171_SAVE_METADATA_REQUIRED' }
if ($qualityExpected.schema -ne 'SCENE_ART_QUALITY_20261101B_INDEPENDENT_V1' -or $qualityExpected.ready -ne $true) { throw 'SEPARATE_ROOT_SOURCE_FREEZE_REQUIRED' }
$qualityErrors = [Collections.Generic.List[string]]::new()
$qualityFacts = [ordered]@{}; $qualitySaves = [ordered]@{}; $qualityNew = [ordered]@{}
foreach ($property in $qualityBefore.frozen_before_facts.PSObject.Properties) {
    $now = Get-QualityFact $property.Name; $qualityFacts[$property.Name] = $now
    if (-not (Test-QualityFactSame $property.Value $now)) { $qualityErrors.Add('FROZEN_OLD_SOURCE_SHA_BYTES_EXACT_UTC_TICKS:' + $property.Name) }
}
$qualityProject = [string]$qualityBefore.only_authorized_old_target
$qualityProjectAfter = Get-QualityFact $qualityProject
$qualityBackup = Get-QualityFact $qualityBefore.project_backup_path
if (-not (Test-QualityFactSame $qualityBefore.project_backup_fact $qualityBackup) -or -not (Test-QualityFactSame $qualityBefore.authorized_project_before $qualityBackup)) { $qualityErrors.Add('PROJECT_EXACT_BACKUP_SHA_BYTES_TICKS_CHANGED') }
$qualityHook = [string]$qualityBefore.allowed_autoload_line
$qualityAfterBytes = [IO.File]::ReadAllBytes($qualityProject)
$qualityAfterText = [Text.Encoding]::UTF8.GetString($qualityAfterBytes)
$qualityOldBytes = [IO.File]::ReadAllBytes($qualityBefore.project_backup_path)
$qualityLines = @($qualityAfterText -split '\r?\n' | Where-Object { $_ -eq $qualityHook })
$qualityAutoloadSection = [regex]::Match($qualityAfterText, '(?ms)^\[autoload\]\r?\n(?<body>.*?)(?=^\[|\z)').Groups['body'].Value
$qualityExactInsideAutoload = @($qualityAutoloadSection -split '\r?\n' | Where-Object { $_ -eq $qualityHook }).Count -eq 1
$qualityRemovedLine = $false; $qualityInverseMatches = $false
if ($qualityLines.Count -eq 1 -and $qualityExactInsideAutoload) {
    foreach ($ending in @("`r`n", "`n")) {
        $needle = $qualityHook + $ending
        $index = $qualityAfterText.IndexOf($needle, [StringComparison]::Ordinal)
        if ($index -lt 0) { continue }
        $inverse = $qualityAfterText.Remove($index, $needle.Length)
        $inverseBytes = [Text.Encoding]::UTF8.GetBytes($inverse)
        if ([Convert]::ToBase64String($inverseBytes) -eq [Convert]::ToBase64String($qualityOldBytes)) { $qualityRemovedLine=$true; $qualityInverseMatches=$true; break }
    }
}
if (-not $qualityRemovedLine -or -not $qualityInverseMatches) { $qualityErrors.Add('PROJECT_NOT_EXACTLY_ONE_AUTHORIZED_AUTOLOAD_LINE_BYTE_INVERSE') }
$qualityExpectedProjectSha = $qualityExpected.source_pins.'res://project.godot'
if (-not $qualityProjectAfter.stable_during_hash -or $qualityProjectAfter.sha256 -ne $qualityExpectedProjectSha) { $qualityErrors.Add('PROJECT_AFTER_NOT_SEPARATELY_ROOT_FROZEN_SHA') }
foreach ($property in $qualityBefore.save_facts.PSObject.Properties) {
    $now = Get-QualityFact $property.Name; $qualitySaves[$property.Name] = $now
    if (-not (Test-QualityFactSame $property.Value $now)) { $qualityErrors.Add('SAVE_METADATA_CHANGED_NO_DESERIALIZATION_NO_RESTORE:' + $property.Name) }
}
$qualityGame = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
foreach ($property in $qualityExpected.source_pins.PSObject.Properties) {
    if (-not $property.Name.StartsWith('res://') -or $property.Name.Contains('..')) { $qualityErrors.Add('NEW_FREEZE_PATH_DOMAIN:' + $property.Name); continue }
    $absolute = [IO.Path]::GetFullPath((Join-Path $qualityGame $property.Name.Substring(6)))
    if (-not $absolute.StartsWith($qualityGame + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { $qualityErrors.Add('NEW_FREEZE_OUTSIDE_GAME'); continue }
    $now = Get-QualityFact $absolute; $qualityNew[$absolute.Replace('\','/')] = $now
    if (-not $now.exists -or -not $now.stable_during_hash -or $now.sha256 -ne $property.Value) { $qualityErrors.Add('SEPARATELY_FROZEN_INPUT_SHA:' + $property.Name) }
}
$qualityResult = [ordered]@{
    passed=($qualityErrors.Count -eq 0);scope='ONE_PROJECT_AUTOLOAD_LINE_PLUS_BOUNDED_FRESH_OLD_SOURCES_AND171_SAVE_METADATA_NOT3236_REHASH'
    finished_utc=[DateTime]::UtcNow.ToString('o');before_path=$Before;before_sha256=$BeforeSha256.ToLowerInvariant();source_freeze_path=$Expected;source_freeze_fact=(Get-QualityFact $Expected)
    authorized_change_count=1;authorized_project=[ordered]@{path=$qualityProject;before=$qualityBefore.authorized_project_before;after=$qualityProjectAfter;expected_after_sha256=$qualityExpectedProjectSha;exact_one_line_byte_inverse=$qualityInverseMatches}
    facts=$qualityFacts;frozen_source_count=$qualityFacts.Count;save_facts=$qualitySaves;save_count=$qualitySaves.Count;absent_save_count=@($qualitySaves.Values|Where-Object{-not $_.exists}).Count
    project_backup_fact=$qualityBackup;independent_source_pin_facts=$qualityNew;independent_source_pin_count=$qualityNew.Count
    retained_prior_external_save_history=$qualityBefore.retained_prior_external_save_history;retained_fresh_pre_capture_external_save_changes=$qualityBefore.fresh_save_changes_since_prior_guard
    prior3236_credit='HISTORICAL_ONLY_NOT_REHASHED_NOT_NEWLY_APPROVED';errors=@($qualityErrors)
    old_guard_edits=0;engine_runs=0;process_control=0;production_writes=0;save_deserializations=0;save_writes=0;automatic_restore=$false
}
Write-QualityNewJson $qualityOutput $qualityResult
[ordered]@{passed=$qualityResult.passed;errors=@($qualityErrors);frozen=$qualityFacts.Count;saves=$qualitySaves.Count;absent=$qualityResult.absent_save_count;source_pins=$qualityNew.Count;output=$qualityOutput;sha256=(Get-QualityFact $qualityOutput).sha256}|ConvertTo-Json -Depth 5
if ($qualityErrors.Count -gt 0) { exit 1 }
