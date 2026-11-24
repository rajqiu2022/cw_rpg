param(
    [Parameter(Mandatory=$true)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$BeforeSha256,
    [string]$Before = (Join-Path $PSScriptRoot 'capture_before_ACTUAL.json'),
    [string]$Output = (Join-Path $PSScriptRoot 'supplement02_capture_ACTUAL.json')
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'guard_helpers_ROOT_ONLY.ps1')
$suppOutput = Assert-GateNewOutput $Output $PSScriptRoot
$suppGame = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$suppExpectedParent = '5d6f11d35c377f1ce2742c339ce0fc4fbc35a22d7883a513501ac6b09fcf1670'
if ($BeforeSha256.ToLowerInvariant() -ne $suppExpectedParent -or (Get-GateFact $Before).sha256 -ne $suppExpectedParent) { throw 'EXACT_ORIGINAL183_CAPTURE_REQUIRED_NO_REBASE' }
$suppParent = Get-Content -LiteralPath $Before -Raw | ConvertFrom-Json
if ($suppParent.captured_successfully -ne $true -or $suppParent.source_count -ne 183) { throw 'ORIGINAL_FRESH183_SCHEMA_REQUIRED' }
$suppTargets = @(
    'res://build/three_towns_world_20261029j_system01/native_sources.json',
    'res://build/three_towns_world_20261029j_system01/town_registry.gd'
)
$suppFacts = [ordered]@{}; $suppBackups = [ordered]@{}
foreach ($relative in $suppTargets) {
    $absolute = Get-GateAbsolute $relative $suppGame
    if ($absolute -in $suppParent.strict_immutable_paths -or $absolute -in $suppParent.potential_old_targets) { throw 'SUPPLEMENT_EXPECTS_PREVIOUSLY_DEFAULT_IMMUTABLE_NON_STRICT_TWO_TARGETS_ONLY' }
    $original = $suppParent.before_facts.PSObject.Properties[$absolute]
    if ($null -eq $original) { throw ('SUPPLEMENT_TARGET_NOT_IN_ORIGINAL183:' + $absolute) }
    $now = Get-GateFact $absolute
    if (-not (Test-GateFactSame $original.Value $now)) { throw ('SUPPLEMENT_MUST_PRECEDE_ANY_WRITE_AND_MATCH_ORIGINAL183_NO_REBASE:' + $absolute) }
    $suppFacts[$absolute] = $now
    $backup = Copy-GateExactBackup $absolute (Join-Path $PSScriptRoot ('supplement02_backups/' + $relative.Substring(6))) $PSScriptRoot
    if (-not (Test-GateFactSame $now $backup.fact)) { throw 'SUPPLEMENT_FULL_BEFORE_BACKUP_NOT_EXACT' }
    $suppBackups[$absolute] = $backup
}
foreach ($absolute in $suppFacts.Keys) { if (-not (Test-GateFactSame $suppFacts[$absolute] (Get-GateFact $absolute))) { throw ('SUPPLEMENT_SOURCE_CHANGED_DURING_CAPTURE:' + $absolute) } }
$suppResult = [ordered]@{
    schema='GATE_GAIT_20261101C_SUPPLEMENT02_CAPTURE_V1';captured_successfully=$true;captured_utc=[DateTime]::UtcNow.ToString('o')
    parent_capture_path=[IO.Path]::GetFullPath($Before).Replace('\','/');parent_capture_sha256=$suppExpectedParent
    scope='EXACT_TWO_EXISTING183_NATIVE_SOURCE_PIN_TARGETS_ONLY_FRESH_BEFORE_AND_FULL_BACKUPS_NOT_REBASE'
    targets=$suppTargets;target_count=2;before_facts=$suppFacts;backups=$suppBackups;backup_count=2
    original183_capture_rewritten=$false;original_guard_rewritten=$false;strict_immutable_paths_changed=$false
    old_after_authorization='NONE_FROM_THIS_CAPTURE_ROOT_MUST_APPROVE_EXACT_TWO_AFTER_ROWS_SEPARATELY'
    engine_runs=0;production_writes=0;save_reads=0;save_deserializations=0;save_writes=0;automatic_restore=$false
}
Write-GateNewJson $suppOutput $suppResult
[ordered]@{path=$suppOutput;sha256=(Get-GateFact $suppOutput).sha256;targets=2;full_backups=2;parent_capture_sha256=$suppExpectedParent}|ConvertTo-Json
