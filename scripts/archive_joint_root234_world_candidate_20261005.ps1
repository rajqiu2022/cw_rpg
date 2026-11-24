param([switch]$Archive)
$ErrorActionPreference = 'Stop'
$taskWorkspace = 'F:\Code\RPG_GAME'
$taskArchive = 'F:\Code\RPG_GAME\game\build\world_v9c_ROOT234_before_v9e_material_20261005_01'
$taskArt = 'F:\Code\RPG_GAME\game\art\maps\world_map_v15_complete_v9c'
$taskSource = 'F:\Code\RPG_GAME\game\data\maps\world_map_v15_complete_v9c_source.json'
foreach ($taskPath in @($taskWorkspace,$taskArt,$taskSource)) {
    $taskResolved = (Resolve-Path -LiteralPath $taskPath).ProviderPath
    if ($taskResolved -ne $taskPath) { throw "Unexpected resolved path: $taskResolved" }
}
if (-not $taskArt.StartsWith($taskWorkspace + '\game\art\maps\') -or -not $taskSource.StartsWith($taskWorkspace + '\game\data\maps\')) { throw 'Candidate targets escape their exact scopes.' }
if (Test-Path -LiteralPath $taskArchive) { throw 'Archive already exists; never overwrite it.' }
$taskExpected = @{
    $taskSource = '79FFAC820DD6A2F475B4595475D0535B9DE0B3C29FB21DB03E77BC1FA73273FD'
    ($taskArt + '\art_contract.json') = '2F73E1880DAA33124E0A555416C7077C841A1266E13EBE0C7F89AEBFEF357683'
    ($taskArt + '\whole_actual_capture.json') = '789EE9798146A9A35D1FC1FE8221B8BAD0010BC3E200DD9B00E4D62F2A3A932C'
}
foreach ($taskPath in $taskExpected.Keys) {
    if ((Get-FileHash -LiteralPath $taskPath -Algorithm SHA256).Hash -ne $taskExpected[$taskPath]) { throw "ROOT234 bytes differ: $taskPath" }
}
$taskFiles = @(Get-ChildItem -LiteralPath $taskArt -File -Recurse | ForEach-Object {
    [pscustomobject]@{ Relative = $_.FullName.Substring($taskArt.Length + 1); Bytes = $_.Length; Sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
})
if ($taskFiles.Count -eq 0) { throw 'No actual art files found.' }
if (-not $Archive) {
    [pscustomobject]@{ Scope = 'READ_ONLY_EXACT_ROOT234_ARCHIVE_PREFLIGHT'; FileCount = $taskFiles.Count; Bytes = ($taskFiles | Measure-Object Bytes -Sum).Sum; SourceSha256 = $taskExpected[$taskSource]; Targets = @($taskArt,$taskSource); Destination = $taskArchive } | ConvertTo-Json
    exit 0
}
# Recoverable same-volume candidate handoff; no deletion, formal files untouched.
New-Item -ItemType Directory -Path $taskArchive | Out-Null
Move-Item -LiteralPath $taskArt -Destination ($taskArchive + '\world_map_v15_complete_v9c')
Move-Item -LiteralPath $taskSource -Destination ($taskArchive + '\world_map_v15_complete_v9c_source.json')
foreach ($taskFile in $taskFiles) {
    $taskMoved = $taskArchive + '\world_map_v15_complete_v9c\' + $taskFile.Relative
    if (-not (Test-Path -LiteralPath $taskMoved) -or (Get-Item -LiteralPath $taskMoved).Length -ne $taskFile.Bytes -or (Get-FileHash -LiteralPath $taskMoved -Algorithm SHA256).Hash -ne $taskFile.Sha256) { throw "Recoverable archive verification failed: $taskMoved" }
}
if ((Get-FileHash -LiteralPath ($taskArchive + '\world_map_v15_complete_v9c_source.json')).Hash -ne $taskExpected[$taskSource]) { throw 'Archived source differs.' }
[pscustomobject]@{ Scope = 'RECOVERABLE_CANDIDATE_HANDOFF_NOT_FORMAL_CUTOVER'; ArchivedFiles = $taskFiles.Count; SourceSha256 = $taskExpected[$taskSource]; Destination = $taskArchive; Verification = 'ALL_BYTES_SHA256_EXACT'; FormalFilesTouched = $false } | ConvertTo-Json
