[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$guardRepo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd('\','/')
$guardSource = [IO.Path]::GetFullPath((Join-Path $guardRepo 'game/art/maps/world_map_v14'))
$guardParent = [IO.Path]::GetFullPath((Join-Path $guardRepo 'game/build/world_map_v14_ninth_v9_guard_height_failed'))
$guardTarget = [IO.Path]::GetFullPath((Join-Path $guardParent 'original_out'))
foreach ($checkedPath in @($guardSource,$guardParent,$guardTarget)) {
    if (-not $checkedPath.StartsWith($guardRepo + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Archive escaped repository.' }
}
if (Test-Path -LiteralPath $guardParent) { throw 'Previous evidence cannot be overwritten.' }
$guardMain = Join-Path $guardRepo 'game/scripts/dev/build_world_map_native_full_v14.gd'
$guardFormal = Join-Path $guardRepo 'game/data/scenes/world_map_jianghu.tres'
$guardExpected = '06EB481E20A5A55CFA2CD66FCBEE4A7D0109412ACD9A6BD251B45D6D948363E1'
if ((Get-FileHash -LiteralPath $guardMain).Hash -cne $guardExpected) { throw 'Executed builder changed.' }
if ((Get-FileHash -LiteralPath $guardFormal).Hash -cne '09FA89449B1792063E66AD488AA2F60671AA00DA2193E5C68ACB861DF14D71D5') { throw 'Formal map changed.' }
$guardManifest = Get-Content -Raw -LiteralPath (Join-Path $guardSource 'manifest.json') | ConvertFrom-Json
if ($guardManifest.capture_iteration -ne 9 -or $guardManifest.production_approved -ne $false -or $guardManifest.status -ne 'ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA' -or $guardManifest.executed_builder_sha256.ToUpperInvariant() -cne $guardExpected) { throw 'Wrong unapproved capture.' }
$guardLedger = @(Get-ChildItem -LiteralPath $guardSource -Recurse -File -Force | ForEach-Object {
    [PSCustomObject]@{ relative_path=$_.FullName.Substring($guardSource.Length+1).Replace('\','/'); sha256=(Get-FileHash -LiteralPath $_.FullName).Hash; bytes=$_.Length }
})
New-Item -ItemType Directory -Path $guardParent | Out-Null
Copy-Item -LiteralPath $guardMain -Destination (Join-Path $guardParent 'executed_builder.gd')
Copy-Item -LiteralPath (Join-Path $guardRepo 'game/scripts/dev/world_map_v14_ninth_native_surface.gd') -Destination (Join-Path $guardParent 'executed_material_helper.gd')
Copy-Item -LiteralPath (Join-Path $guardRepo 'game/build/world_v14_qa_B6F045_before_guard_fixture.gd') -Destination (Join-Path $guardParent 'actual_failed_guard_qa_B6F045.gd')
Copy-Item -LiteralPath (Join-Path $guardRepo 'game/build/world_map_v14_qa/north_guard_binding_1790942327/result.json') -Destination (Join-Path $guardParent 'actual_failed_guard_result.json')
# Only the explicitly resolved candidate folder moves; all bytes remain recoverable.
Move-Item -LiteralPath $guardSource -Destination $guardTarget
$guardMismatch = @($guardLedger | Where-Object {
    $movedFile = Join-Path $guardTarget $_.relative_path
    -not (Test-Path -LiteralPath $movedFile -PathType Leaf) -or (Get-FileHash -LiteralPath $movedFile).Hash -cne $_.sha256
})
if ($guardMismatch.Count -ne 0) { throw 'Archived bytes differ.' }
$guardEvidence = [ordered]@{
    scope='UNAPPROVED_CAPTURE_REAL_GUARD_HEIGHT_FAILURE'; capture_exit_code=0; import_exit_code=0; publisher_candidate_exit_code=0
    actual_guard_qa=[ordered]@{ exit_code=1; checks=1596; failures=3; actual_bad_bed_vertices=2; maximum_rf_height_error_m=0.00036301980413; permitted_error_m=0.0001 }
    separate_json_precision_fixture=[ordered]@{ exit_code=0; checks=96; failures=0; scope='JSON_SERIALIZATION_ONLY_NOT_GEOMETRY_APPROVAL' }
    source=$guardSource; target=$guardTarget; file_count=$guardLedger.Count; hash_mismatches=0; recoverable=$true
    executed_builder_sha256=$guardExpected; formal_sha256=(Get-FileHash -LiteralPath $guardFormal).Hash; files=$guardLedger
}
[IO.File]::WriteAllText((Join-Path $guardParent 'archive_evidence.json'),($guardEvidence | ConvertTo-Json -Depth 7),[Text.UTF8Encoding]::new($false))
[PSCustomObject]@{ archived_files=$guardLedger.Count; verified_mismatches=0; target=$guardTarget; formal_unchanged=$true } | ConvertTo-Json
