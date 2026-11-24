[CmdletBinding()]
param([switch]$Apply)
# Root-only exact-byte mechanical installation of already-authored candidates.
# No semantic edits, engine launch, process stop, rollback, or real-save APIs.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'USE_BUNDLED_PWSH7' }
$taskRepo = 'F:/Code/RPG_GAME'
$taskGame = [IO.Path]::GetFullPath($taskRepo + '/game')
$taskSystem = $taskGame + '/build/world_coast_20261031h_system03'
$taskSealed = $taskSystem + '/sealed_candidate03'
$taskReceiptPath = $taskSealed + '/receipt_REVIEW_ONLY.json'
$taskReceiptPin = '8e61ae93e1b11e51d983300fe64ad3dd651ff1515d972df2ff8f19ac484a43ef'
$taskChecker = $taskSystem + '/check_apply03_READONLY.py'
$taskCheckerPin = '638a59b247aae02adac06733d8874930ee4c8a6a7decba025169de83104569a9'
$taskPython = 'C:/Users/rajqiu/AppData/Local/Programs/Python/Python312/python.exe'
$taskResultPath = $taskSystem + '/apply03_ACTUAL_receipt.json'
function Get-ExactSha([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}
function Resolve-ExactGameUri([string]$Uri) {
    if (-not $Uri.StartsWith('res://') -or $Uri.Split('/') -contains '..') { throw 'EXACT_RESOURCE_URI_REQUIRED' }
    $taskResolved = [IO.Path]::GetFullPath($taskGame + '/' + $Uri.Substring(6))
    if (-not $taskResolved.StartsWith($taskGame + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'RESOURCE_ESCAPED_GAME' }
    return $taskResolved
}
if ((Get-ExactSha $taskReceiptPath) -cne $taskReceiptPin -or (Get-ExactSha $taskChecker) -cne $taskCheckerPin) { throw 'ROOT_EXACT_SEALED_RECEIPT_OR_CHECKER_CHANGED' }
if (Test-Path -LiteralPath $taskResultPath) { throw 'PREVIOUS_APPLY_RESULT_RETAINED_DO_NOT_REAPPLY' }
$taskReceipt = [IO.File]::ReadAllText($taskReceiptPath) | ConvertFrom-Json -AsHashtable
if ($taskReceipt.target_count -ne 37 -or $taskReceipt.targets.Count -ne 37) { throw 'EXACT37_REQUIRED' }
$taskExpectedPath = $taskSystem + '/SourceExpected03_ROOT_APPROVED.json'
if ((Get-ExactSha $taskExpectedPath) -cne $taskReceipt.source_expected_sha256) { throw 'ROOT_APPROVED_EXPECTATION_CHANGED' }
$taskExpected = [IO.File]::ReadAllText($taskExpectedPath) | ConvertFrom-Json -AsHashtable
if ($taskExpected.approved_by -cne 'root' -or $taskExpected.status -cne 'ROOT_APPROVED_EXACT_CANDIDATE_INPUTS') { throw 'ROOT_APPROVAL_REQUIRED' }
& $taskPython $taskChecker --phase before --receipt-sha $taskReceiptPin
if ($LASTEXITCODE -ne 0) { throw 'INDEPENDENT_BEFORE_CHECK_FAILED' }
$taskCopies = @()
foreach ($taskRow in $taskReceipt.targets) {
    if (-not $taskRow.path.StartsWith('game/')) { throw 'TARGET_OUTSIDE_GAME' }
    $taskUri = 'res://' + $taskRow.path.Substring(5)
    $taskSource = [IO.Path]::GetFullPath($taskSealed + '/copies/' + $taskRow.path)
    $taskTarget = Resolve-ExactGameUri $taskUri
    if (-not $taskSource.StartsWith([IO.Path]::GetFullPath($taskSealed + '/copies') + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'SOURCE_ESCAPED_COPIES' }
    if ((Get-ExactSha $taskTarget) -cne $taskRow.before_sha256 -or (Get-ExactSha $taskSource) -cne $taskRow.candidate_sha256) { throw 'LAST_MOMENT_TARGET_OR_CANDIDATE_DIFF' }
    $taskCopies += [ordered]@{uri=$taskUri;source=$taskSource;target=$taskTarget;before_sha256=$taskRow.before_sha256;candidate_sha256=$taskRow.candidate_sha256;before_bytes=(Get-Item -LiteralPath $taskTarget).Length;before_utc_ticks=(Get-Item -LiteralPath $taskTarget).LastWriteTimeUtc.Ticks}
}
if (($taskCopies.uri | Select-Object -Unique).Count -ne 37) { throw 'TARGETS_NOT_UNIQUE' }
$taskSnapshots = @()
foreach ($taskSourceUri in $taskExpected.snapshot_paths.Keys) {
    $taskSnapshotUri = [string]$taskExpected.snapshot_paths[$taskSourceUri]
    if (-not $taskSnapshotUri.StartsWith('res://build/luoyang_world_coast_20261031h_snapshot03/')) { throw 'EXACT_NEW_SNAPSHOT_NAMESPACE_REQUIRED' }
    $taskTarget = Resolve-ExactGameUri $taskSnapshotUri
    $taskSource = [IO.Path]::GetFullPath($taskSealed + '/new_snapshots/game/' + $taskSnapshotUri.Substring(6))
    if (Test-Path -LiteralPath $taskTarget) { throw 'NEW_SNAPSHOT_ALREADY_EXISTS' }
    if ((Get-ExactSha $taskSource) -cne $taskReceipt.new_snapshot_pins[$taskSnapshotUri]) { throw 'NEW_SNAPSHOT_SOURCE_DIFF' }
    $taskSnapshots += [ordered]@{uri=$taskSnapshotUri;source=$taskSource;target=$taskTarget;sha256=$taskReceipt.new_snapshot_pins[$taskSnapshotUri]}
}
if ($taskSnapshots.Count -ne 2) { throw 'EXACT_TWO_NEW_SNAPSHOTS_REQUIRED' }
if (-not $Apply) {
    Write-Output 'ROOT_ONLY_APPLY03_DRY_READONLY_PASS old37 exact, new2 absent; no writes.'
    exit 0
}
$taskGodot = @(Get-CimInstance Win32_Process | Where-Object { $_.Name -match '(?i)^Godot.*\.exe$' -and $_.ProcessId -ne 51856 })
if ($taskGodot.Count -gt 0) { throw 'GODOT_PROCESS_OTHER_THAN_PRESERVED_EDITOR_PRESENT_NO_WRITES' }
# Recheck all old targets immediately before the first copy. A partial error is
# retained, never auto-restored over user changes and never reported complete.
foreach ($taskCopy in $taskCopies) { if ((Get-ExactSha $taskCopy.target) -cne $taskCopy.before_sha256 -or (Get-ExactSha $taskCopy.source) -cne $taskCopy.candidate_sha256) { throw 'PRECOMMIT_SOURCE_DIFFERENCE_NO_WRITES' } }
foreach ($taskCopy in $taskSnapshots) { if (Test-Path -LiteralPath $taskCopy.target) { throw 'PRECOMMIT_NEW_SNAPSHOT_EXISTS_NO_WRITES' } }
foreach ($taskCopy in $taskSnapshots) {
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($taskCopy.target))
    Copy-Item -LiteralPath $taskCopy.source -Destination $taskCopy.target
    if ((Get-ExactSha $taskCopy.target) -cne $taskCopy.sha256) { throw 'PARTIAL_SNAPSHOT_COPY_RETAINED' }
}
foreach ($taskCopy in $taskCopies) {
    Copy-Item -LiteralPath $taskCopy.source -Destination $taskCopy.target -Force
    if ((Get-ExactSha $taskCopy.target) -cne $taskCopy.candidate_sha256) { throw 'PARTIAL_TARGET_COPY_RETAINED' }
}
& $taskPython $taskChecker --phase after --receipt-sha $taskReceiptPin
if ($LASTEXITCODE -ne 0) { throw 'POST_APPLY_CHECK_FAILED_PARTIAL_OUTPUTS_RETAINED' }
$taskResult = [ordered]@{status='ROOT_EXACT_BYTE_MECHANICAL_APPLY37_PLUS2_COMPLETE_NOT_ENGINE_QA';sealed_receipt_sha256=$taskReceiptPin;apply_script_sha256=(Get-ExactSha $PSCommandPath);targets=$taskCopies;snapshots=$taskSnapshots;applied_utc=[DateTime]::UtcNow.ToString('o');engine_launches=0;process_stops=0;real_save_API_calls=0;actual_C_collector_B_describe_pending=$true}
$taskBytes = [Text.UTF8Encoding]::new($false).GetBytes(($taskResult | ConvertTo-Json -Depth 12) + "`n")
$taskFile = [IO.File]::Open($taskResultPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
try { $taskFile.Write($taskBytes,0,$taskBytes.Length) } finally { $taskFile.Dispose() }
Write-Output ('ROOT_APPLY03_COMPLETE receipt=' + $taskResultPath + ' sha256=' + (Get-ExactSha $taskResultPath))
