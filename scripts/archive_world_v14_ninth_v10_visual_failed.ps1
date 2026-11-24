[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$visualRepo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd('\','/')
$visualSource = [IO.Path]::GetFullPath((Join-Path $visualRepo 'game/art/maps/world_map_v14'))
$visualParent = [IO.Path]::GetFullPath((Join-Path $visualRepo 'game/build/world_map_v14_ninth_v10_forest_scale_visual_failed'))
$visualTarget = [IO.Path]::GetFullPath((Join-Path $visualParent 'original_out'))
foreach ($checkedPath in @($visualSource,$visualParent,$visualTarget)) {
    if (-not $checkedPath.StartsWith($visualRepo + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Archive escaped repository.' }
}
if (Test-Path -LiteralPath $visualParent) { throw 'Existing recoverable evidence cannot be overwritten.' }
$visualMain = Join-Path $visualRepo 'game/scripts/dev/build_world_map_native_full_v14.gd'
$visualFormal = Join-Path $visualRepo 'game/data/scenes/world_map_jianghu.tres'
$visualExpected = '111CCFF5C6A360D0088CFAD14535AD3CE541233B5E7851C22506939E74FA128A'
if ((Get-FileHash -LiteralPath $visualMain).Hash -cne $visualExpected) { throw 'Executed builder changed.' }
if ((Get-FileHash -LiteralPath $visualFormal).Hash -cne '09FA89449B1792063E66AD488AA2F60671AA00DA2193E5C68ACB861DF14D71D5') { throw 'Formal map changed.' }
$visualManifest = Get-Content -Raw -LiteralPath (Join-Path $visualSource 'manifest.json') | ConvertFrom-Json
if ($visualManifest.capture_iteration -ne 9 -or $visualManifest.production_approved -ne $false -or $visualManifest.status -ne 'ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA' -or $visualManifest.executed_builder_sha256.ToUpperInvariant() -cne $visualExpected) { throw 'Wrong unapproved capture.' }
$visualLedger = @(Get-ChildItem -LiteralPath $visualSource -Recurse -File -Force | ForEach-Object {
    [PSCustomObject]@{ relative_path=$_.FullName.Substring($visualSource.Length+1).Replace('\','/'); sha256=(Get-FileHash -LiteralPath $_.FullName).Hash; bytes=$_.Length }
})
New-Item -ItemType Directory -Path $visualParent | Out-Null
Copy-Item -LiteralPath $visualMain -Destination (Join-Path $visualParent 'executed_builder.gd')
Copy-Item -LiteralPath (Join-Path $visualRepo 'game/scripts/dev/build_world_map_native_full_v14_ninth_draft.gd') -Destination (Join-Path $visualParent 'executed_ninth_builder.gd')
Copy-Item -LiteralPath (Join-Path $visualRepo 'game/scripts/dev/world_map_v14_ninth_native_surface.gd') -Destination (Join-Path $visualParent 'executed_material_helper.gd')
# Resolve and validate the one candidate folder before this recoverable move.
Move-Item -LiteralPath $visualSource -Destination $visualTarget
$visualMismatch = @($visualLedger | Where-Object {
    $movedFile = Join-Path $visualTarget $_.relative_path
    -not (Test-Path -LiteralPath $movedFile -PathType Leaf) -or (Get-FileHash -LiteralPath $movedFile).Hash -cne $_.sha256
})
if ($visualMismatch.Count -ne 0) { throw 'Archived bytes differ.' }
$visualEvidence = [ordered]@{
    scope='UNAPPROVED_CAPTURE_VISUAL_FAILURE_FOREST_SCALE_AND_TRANSPARENT_HALOS'
    capture_exit_code=0; import_exit_code=0; publisher_candidate_exit_code=0
    root_visual_verdict='FAIL'; formal_activated=$false; production_approved=$false
    independent_guard_geometry=[ordered]@{ checks=1596; failures=0; exit_code=0; scope='LIMITED_GUARD_NOT_FULL_FIELD' }
    latest_original35=[ordered]@{ checks=5568; failures=1; exit_code=1; scope='FOCUSED_ORIGINAL35_NOT_FULL'; result='game/build/world_map_v14_qa/original35_alpha_1790948050/result.json' }
    source=$visualSource; target=$visualTarget; file_count=$visualLedger.Count; hash_mismatches=0; recoverable=$true
    executed_builder_sha256=$visualExpected; formal_sha256=(Get-FileHash -LiteralPath $visualFormal).Hash; files=$visualLedger
}
[IO.File]::WriteAllText((Join-Path $visualParent 'archive_evidence.json'),($visualEvidence | ConvertTo-Json -Depth 7),[Text.UTF8Encoding]::new($false))
[PSCustomObject]@{ archived_files=$visualLedger.Count; verified_mismatches=0; target=$visualTarget; formal_unchanged=$true } | ConvertTo-Json
