[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$archiveRepo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd('\','/')
$archiveSource = [IO.Path]::GetFullPath((Join-Path $archiveRepo 'game/art/maps/world_map_v14'))
$archiveParent = [IO.Path]::GetFullPath((Join-Path $archiveRepo 'game/build/world_map_v14_ninth_v8b_visual_failed'))
$archiveTarget = [IO.Path]::GetFullPath((Join-Path $archiveParent 'original_out'))
foreach ($candidatePath in @($archiveSource,$archiveParent,$archiveTarget)) {
    if (-not $candidatePath.StartsWith($archiveRepo + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Archive escaped exact repository root.' }
}
if (Test-Path -LiteralPath $archiveParent) { throw 'Existing evidence cannot be overwritten.' }
$archiveMain = Join-Path $archiveRepo 'game/scripts/dev/build_world_map_native_full_v14.gd'
$archiveFormal = Join-Path $archiveRepo 'game/data/scenes/world_map_jianghu.tres'
$archiveExpected = '11D1A583116D10F1F38C5FBAE7FCB845245B44ECD42F00A29A8A6F27DBEF3B1C'
if ((Get-FileHash -LiteralPath $archiveMain -Algorithm SHA256).Hash -cne $archiveExpected) { throw 'Wrong actual executed builder.' }
if ((Get-FileHash -LiteralPath $archiveFormal -Algorithm SHA256).Hash -cne '09FA89449B1792063E66AD488AA2F60671AA00DA2193E5C68ACB861DF14D71D5') { throw 'Formal map changed before archive.' }
$archiveManifest = Get-Content -Raw -LiteralPath (Join-Path $archiveSource 'manifest.json') | ConvertFrom-Json
if ($archiveManifest.capture_iteration -ne 9 -or $archiveManifest.production_approved -ne $false -or $archiveManifest.status -ne 'ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA' -or $archiveManifest.executed_builder_sha256.ToUpperInvariant() -cne $archiveExpected) { throw 'Not the exact unapproved v8b capture.' }
$archiveLedger = @(Get-ChildItem -LiteralPath $archiveSource -Recurse -File -Force | ForEach-Object {
    [PSCustomObject]@{ relative_path=$_.FullName.Substring($archiveSource.Length+1).Replace('\','/'); sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash; bytes=$_.Length }
})
New-Item -ItemType Directory -Path $archiveParent | Out-Null
Copy-Item -LiteralPath $archiveMain -Destination (Join-Path $archiveParent 'executed_builder.gd')
Copy-Item -LiteralPath (Join-Path $archiveRepo 'game/scripts/dev/world_map_v14_ninth_native_surface.gd') -Destination (Join-Path $archiveParent 'executed_material_helper.gd')
Copy-Item -LiteralPath (Join-Path $archiveRepo 'game/build/world_map_v14_qa_75F6_ninth_v8b_frozen_snapshot.gd') -Destination (Join-Path $archiveParent 'actual_failed_full_qa_75F6.gd')
# Only this verified candidate directory moves, recoverably. No deletion.
Move-Item -LiteralPath $archiveSource -Destination $archiveTarget
$archiveMismatch = @($archiveLedger | Where-Object {
    $movedFile = Join-Path $archiveTarget $_.relative_path
    -not (Test-Path -LiteralPath $movedFile -PathType Leaf) -or (Get-FileHash -LiteralPath $movedFile -Algorithm SHA256).Hash -cne $_.sha256
})
if ($archiveMismatch.Count -ne 0) { throw 'Archive exact byte verification failed.' }
$archiveEvidence = [ordered]@{
    scope='UNAPPROVED_FULL_CAPTURE_WITH_ACTUAL_VISUAL_AND_FIELD_FAILURES'; capture_exit_code=0; import_exit_code=0; publisher_candidate_exit_code=0
    visual_verdict='FAIL: northeast transparent water has domain-edge sky-composite straight blue patch; external wet receiver guard required'
    actual_full_qa=[ordered]@{ executed_test_sha256='75f60e6d58fabf9f3dbeb98f517c9894e587f17e56faF1d0a2eE8f8A9E432DCB9'; exit_code=1; checks=103554; failures=80; result='res://build/world_map_v14_qa/candidate_headless_1790938119/result.json' }
    source=$archiveSource; target=$archiveTarget; file_count=$archiveLedger.Count; hash_mismatches=0; recoverable=$true
    executed_builder_sha256=$archiveExpected; formal_sha256=(Get-FileHash -LiteralPath $archiveFormal -Algorithm SHA256).Hash; files=$archiveLedger
}
[IO.File]::WriteAllText((Join-Path $archiveParent 'archive_evidence.json'),($archiveEvidence | ConvertTo-Json -Depth 7),[Text.UTF8Encoding]::new($false))
[PSCustomObject]@{ archived_files=$archiveLedger.Count; verified_mismatches=0; target=$archiveTarget; formal_unchanged=$true } | ConvertTo-Json
