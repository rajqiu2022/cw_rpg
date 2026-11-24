[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$archiveRepo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd('\','/')
$archiveSource = [IO.Path]::GetFullPath((Join-Path $archiveRepo 'game/art/maps/world_map_v14'))
$archiveParent = [IO.Path]::GetFullPath((Join-Path $archiveRepo 'game/build/world_map_v14_ninth_v7_technical_unpublished'))
$archiveTarget = Join-Path $archiveParent 'original_out'
foreach ($candidatePath in @($archiveSource, $archiveParent, $archiveTarget)) {
    if (-not $candidatePath.StartsWith($archiveRepo + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Archive target outside workspace' }
}
if (Test-Path -LiteralPath $archiveParent) { throw 'Archive already exists; never overwrite evidence' }
$archiveMain = Join-Path $archiveRepo 'game/scripts/dev/build_world_map_native_full_v14.gd'
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $archiveMain).Hash -ne 'B869816D3ED25B75BA68BA92E3533C11DD09502769C3A5C270CC96A91DD02BD9') { throw 'Wrong executed main source' }
$archiveFormal = Join-Path $archiveRepo 'game/data/scenes/world_map_jianghu.tres'
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $archiveFormal).Hash -ne '09FA89449B1792063E66AD488AA2F60671AA00DA2193E5C68ACB861DF14D71D5') { throw 'Formal changed before archive' }
$archiveManifest = Get-Content -Raw -LiteralPath (Join-Path $archiveSource 'manifest.json') | ConvertFrom-Json
if ($archiveManifest.capture_iteration -ne 9 -or $archiveManifest.production_approved -ne $false -or $archiveManifest.status -ne 'ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA') { throw 'Not the unapproved ninth v7 capture' }
$archiveLedger = @(Get-ChildItem -LiteralPath $archiveSource -File -Recurse | ForEach-Object {
    [PSCustomObject]@{ relative_path = $_.FullName.Substring($archiveSource.Length + 1).Replace('\','/'); sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash; bytes = $_.Length }
})
New-Item -ItemType Directory -Path $archiveParent | Out-Null
Copy-Item -LiteralPath $archiveMain -Destination (Join-Path $archiveParent 'executed_builder.gd')
Copy-Item -LiteralPath (Join-Path $archiveRepo 'game/build/world_map_v14_ninth_v7_executed_helper.gd') -Destination (Join-Path $archiveParent 'executed_helper.gd')
Copy-Item -LiteralPath (Join-Path $archiveRepo 'game/build/world_map_v14_qa_AC522_ninth_frozen_snapshot.gd') -Destination (Join-Path $archiveParent 'unexecuted_full_qa_source.gd')
foreach ($prefix in @('world_map_v14_ninth_v7_source_plan_root','world_map_v14_capture_ninth_v7_root','world_map_v14_import_ninth_v7_root','world_map_v14_publish_ninth_v7_root')) {
    foreach ($suffix in @('.log','.err.log','.engine.log')) {
        $archiveLog = Join-Path $archiveRepo ('game/build/' + $prefix + $suffix)
        if (Test-Path -LiteralPath $archiveLog) { Copy-Item -LiteralPath $archiveLog -Destination (Join-Path $archiveParent ($prefix + $suffix)) }
    }
}
Move-Item -LiteralPath $archiveSource -Destination $archiveTarget
$archiveMismatch = @($archiveLedger | Where-Object {
    $movedFile = Join-Path $archiveTarget $_.relative_path
    -not (Test-Path -LiteralPath $movedFile -PathType Leaf) -or (Get-FileHash -Algorithm SHA256 -LiteralPath $movedFile).Hash -ne $_.sha256
})
if ($archiveMismatch.Count -ne 0) { throw 'Archive byte verification failed' }
$archiveEvidence = [ordered]@{
    scope = 'FULL_CAPTURE_ONLY_NOT_FIELD_OR_VISUAL_APPROVED'; capture_exit_code = 0; import_exit_code = 0; publisher_exit_code = 1
    publisher_rejection = 'Unsafe authored portal gufeng: repaired route end differs from actual source portal anchor'; visual_verdict = 'FAIL: exposed straight cut RockFace proxy sides/bases'
    source = $archiveSource; target = $archiveTarget; file_count = $archiveLedger.Count; hash_mismatches = 0
    executed_builder_sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $archiveMain).Hash
    formal_sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $archiveFormal).Hash; recoverable = $true; files = $archiveLedger
}
[IO.File]::WriteAllText((Join-Path $archiveParent 'archive_evidence.json'), ($archiveEvidence | ConvertTo-Json -Depth 6), [Text.UTF8Encoding]::new($false))
[PSCustomObject]@{ archived_files = $archiveLedger.Count; verified_mismatches = 0; target = $archiveTarget; formal_unchanged = $true } | ConvertTo-Json
