param(
    [Parameter(Mandatory=$true)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$BeforeSha256,
    [Parameter(Mandatory=$true)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$AuthorizationSha256,
    [Parameter(Mandatory=$true)][string]$Authorization,
    [string]$Before = (Join-Path $PSScriptRoot 'capture_before_ACTUAL.json'),
    [string]$Output = (Join-Path $PSScriptRoot 'final_guard_ACTUAL.json')
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'guard_helpers_ROOT_ONLY.ps1')
$gateOutput = Assert-GateNewOutput $Output $PSScriptRoot
if ((Get-GateFact $Before).sha256 -ne $BeforeSha256.ToLowerInvariant()) { throw 'ROOT_EXACT_FRESH_CAPTURE_SHA_REQUIRED' }
if ((Get-GateFact $Authorization).sha256 -ne $AuthorizationSha256.ToLowerInvariant()) { throw 'ROOT_EXACT_AUTHORIZATION_FILE_SHA_REQUIRED' }
$gateBefore = Get-Content -LiteralPath $Before -Raw | ConvertFrom-Json
$gateAuth = Get-Content -LiteralPath $Authorization -Raw | ConvertFrom-Json
if ($gateBefore.captured_successfully -ne $true -or $gateBefore.schema -ne 'GATE_GAIT_20261101C_CAPTURE_V1' -or $gateBefore.save_count -ne 171 -or @($gateBefore.save_facts.PSObject.Properties).Count -ne 171) { throw 'FRESH_VALID_CAPTURE171_REQUIRED' }
if ($gateAuth.schema -ne 'GATE_GAIT_20261101C_AUTHORIZATION_V1' -or $gateAuth.root_approved -ne $true -or $gateAuth.capture_sha256 -ne $BeforeSha256.ToLowerInvariant()) { throw 'SEPARATE_ROOT_APPROVED_AFTER_LIST_FOR_THIS_CAPTURE_REQUIRED' }
$gateGame = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
if (-not (Test-GateFactSame $gateBefore.plan_fact (Get-GateFact $gateBefore.plan_path))) { throw 'CAPTURE_PLAN_CHANGED' }
$gatePlan = Get-Content -LiteralPath $gateBefore.plan_path -Raw | ConvertFrom-Json
if ($gateBefore.allowed_autoload_line -cne $GateExactHook -or $gatePlan.allowed_autoload_line -cne $GateExactHook -or $gateAuth.project.autoload_line -cne $GateExactHook) { throw 'ONLY_THE_FIXED_NPC_GAIT_HOOK_IS_AUTHORIZED' }
$gatePotential = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$gateStrict = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($path in $gateBefore.potential_old_targets) { [void]$gatePotential.Add((Get-GateAbsolute $path $gateGame)) }
foreach ($path in $gateBefore.strict_immutable_paths) { [void]$gateStrict.Add((Get-GateAbsolute $path $gateGame)) }
$gateAllowed = @{}
foreach ($row in @($gateAuth.approved_old_changes)) {
    $path = Get-GateAbsolute $row.path $gateGame
    if (-not $gatePotential.Contains($path) -or $gateStrict.Contains($path) -or $gateAllowed.ContainsKey($path)) { throw ('TARGET_NOT_IN_CAPTURED_POTENTIAL_DOMAIN_OR_IS_STRICT:' + $path) }
    $captured = $gateBefore.before_facts.PSObject.Properties[$path]
    if ($null -eq $captured -or $row.before_sha256 -ne $captured.Value.sha256 -or $row.before_bytes -ne $captured.Value.bytes) { throw ('AFTER_AUTHORIZATION_NOT_BOUND_TO_FRESH_BEFORE:' + $path) }
    if ($row.after_sha256 -notmatch '^[a-fA-F0-9]{64}$' -or $null -eq $row.after_bytes -or [long]$row.after_bytes -lt 0 -or [string]::IsNullOrWhiteSpace([string]$row.reason)) { throw ('EXACT_AFTER_SHA_BYTES_REASON_REQUIRED:' + $path) }
    $gateAllowed[$path] = $row
}
$gateProject = Get-GateAbsolute 'res://project.godot' $gateGame
if ((Get-GateAbsolute $gateAuth.project.path $gateGame) -ne $gateProject -or $gateAuth.project.after_sha256 -notmatch '^[a-fA-F0-9]{64}$' -or $null -eq $gateAuth.project.after_bytes) { throw 'ROOT_EXACT_PROJECT_AFTER_SHA_AND_BYTES_REQUIRED' }
$gateErrors = [Collections.Generic.List[string]]::new()
$gateFacts = [ordered]@{}; $gateChanges = @(); $gateUnchangedAuthorized = @()
foreach ($property in $gateBefore.before_facts.PSObject.Properties) {
    $path = Get-GateAbsolute $property.Name $gateGame
    $now = Get-GateFact $path; $gateFacts[$path] = $now
    if ($gateAllowed.ContainsKey($path)) {
        $approved = $gateAllowed[$path]
        if (-not $now.exists -or -not $now.stable_during_hash -or $now.sha256 -ne $approved.after_sha256.ToLowerInvariant() -or $now.bytes -ne $approved.after_bytes) { $gateErrors.Add('APPROVED_TARGET_ACTUAL_NOT_EXACT_AFTER:' + $path) }
        if (Test-GateFactSame $property.Value $now) { $gateUnchangedAuthorized += $path }
        else { $gateChanges += [ordered]@{path=$path;before=$property.Value;after=$now;approved_after_sha256=$approved.after_sha256.ToLowerInvariant();reason=$approved.reason} }
    } elseif (-not (Test-GateFactSame $property.Value $now)) {
        $gateErrors.Add('UNAUTHORIZED_CAPTURED_SOURCE_METADATA_CHANGE:' + $path)
    }
}
$gateBackupFacts = [ordered]@{}
foreach ($property in $gateBefore.backups.PSObject.Properties) {
    $backup = $property.Value; $now = Get-GateFact $backup.path
    $gateBackupFacts[$property.Name] = [ordered]@{path=$backup.path;fact=$now}
    if (-not (Test-GateFactSame $backup.fact $now)) { $gateErrors.Add('EXACT_BEFORE_BACKUP_CHANGED:' + $property.Name) }
}
$gateProjectFact = Get-GateFact $gateProject
$gateProjectBackup = $gateBefore.backups.PSObject.Properties[$gateProject].Value
$gateProjectInverse = $false
if ($gateProjectFact.exists) { $gateProjectInverse = Test-GateProjectInverse $gateProject $gateProjectBackup.path }
if (-not $gateProjectInverse) { $gateErrors.Add('PROJECT_NOT_EXACT_ONE_NPC_GAIT_AUTOLOAD_LINE_BYTE_INVERSE') }
if (-not $gateProjectFact.stable_during_hash -or $gateProjectFact.sha256 -ne $gateAuth.project.after_sha256.ToLowerInvariant() -or $gateProjectFact.bytes -ne $gateAuth.project.after_bytes) { $gateErrors.Add('PROJECT_NOT_ROOT_SEPARATELY_APPROVED_EXACT_AFTER') }
$gateSaves = [ordered]@{}
foreach ($property in $gateBefore.save_facts.PSObject.Properties) {
    $now = Get-GateFact $property.Name; $gateSaves[$property.Name] = $now
    if (-not (Test-GateFactSame $property.Value $now)) { $gateErrors.Add('SAVE_METADATA_CHANGED_KEEP_ACTUAL_NO_RESTORE:' + $property.Name) }
}
$gateManifestPath = Get-GateAbsolute $gatePlan.npc_manifest $gateGame
$gateManifestFact = Get-GateFact $gateManifestPath
$gateNpcFacts = [ordered]@{}
if ($gateAuth.npc_manifest_sha256 -notmatch '^[a-fA-F0-9]{64}$' -or -not $gateManifestFact.exists -or -not $gateManifestFact.stable_during_hash -or $gateManifestFact.sha256 -ne $gateAuth.npc_manifest_sha256.ToLowerInvariant()) {
    $gateErrors.Add('NPC_MANIFEST_NOT_ROOT_APPROVED_SHA')
} else {
    $manifest = Get-Content -LiteralPath $gateManifestPath -Raw | ConvertFrom-Json
    $expectedNpcKeys = @($gatePlan.npc_sixteen_leaves | Sort-Object)
    $actualNpcKeys = @($manifest.source_pins.PSObject.Properties.Name | Sort-Object)
    if ($manifest.schema -ne $gatePlan.npc_manifest_schema -or $manifest.ready -ne $true -or $actualNpcKeys.Count -ne 16 -or [string]::Join("`n", $expectedNpcKeys) -cne [string]::Join("`n", $actualNpcKeys)) {
        $gateErrors.Add('NPC_RUNTIME_MUST_HAVE_EXACT_REVIEWED16_KEYSET_READY')
    } else {
        foreach ($property in $manifest.source_pins.PSObject.Properties) {
            $path = Get-GateAbsolute $property.Name $gateGame
            $fact = Get-GateFact $path; $gateNpcFacts[$path] = $fact
            if (-not $fact.exists -or -not $fact.stable_during_hash -or $property.Value -notmatch '^[a-fA-F0-9]{64}$' -or $fact.sha256 -ne $property.Value.ToLowerInvariant()) { $gateErrors.Add('NPC_RUNTIME16_LEAF_SHA_CHANGED:' + $property.Name) }
        }
        if ($manifest.hook_registration -cne $GateExactHook -or $manifest.project_sha256_at_root_freeze -ne $gateProjectFact.sha256) { $gateErrors.Add('NPC_MANIFEST_EXACT_PROJECT_HOOK_FREEZE_REQUIRED') }
    }
}
# Only explicitly approved new leaves/reports are read, never scan a proof pool.
$gateNewFacts = [ordered]@{}
foreach ($property in $gateAuth.new_source_pins.PSObject.Properties) {
    $path = Get-GateAbsolute $property.Name $gateGame
    $fact = Get-GateFact $path; $gateNewFacts[$path] = $fact
    if (-not $fact.exists -or -not $fact.stable_during_hash -or $property.Value -notmatch '^[a-fA-F0-9]{64}$' -or $fact.sha256 -ne $property.Value.ToLowerInvariant()) { $gateErrors.Add('EXPLICIT_NEW_SOURCE_PIN_CHANGED:' + $property.Name) }
}
$gatePublisherFacts = [ordered]@{}
if (@($gateAuth.publisher_reports).Count -lt 1) { $gateErrors.Add('EXPLICIT_PUBLISHER_OUTPUT_REPORT_PIN_REQUIRED') }
foreach ($row in @($gateAuth.publisher_reports)) {
    $path = Get-GateAbsolute $row.path $gateGame
    if ($gatePublisherFacts.Contains($path) -or $row.sha256 -notmatch '^[a-fA-F0-9]{64}$') { throw 'EXACT_NON_DUPLICATE_PUBLISHER_REPORT_REQUIRED' }
    $fact = Get-GateFact $path; $gatePublisherFacts[$path] = $fact
    if (-not $fact.exists -or -not $fact.stable_during_hash -or $fact.sha256 -ne $row.sha256.ToLowerInvariant()) { $gateErrors.Add('PUBLISHER_OUTPUT_REPORT_SHA_CHANGED:' + $path) }
}
$gateResult = [ordered]@{
    schema='GATE_GAIT_20261101C_FINAL_GUARD_V1';passed=($gateErrors.Count -eq 0);finished_utc=[DateTime]::UtcNow.ToString('o')
    scope='FINITE_CAPTURE_DOMAIN_ALL_DIFFERENCES_ATTRIBUTED_TO_ROOT_ACTUAL_AFTER_LIST_NOT_ALL97_IMMUTABLE_NOT3236_REHASH'
    before_path=$Before;before_sha256=$BeforeSha256.ToLowerInvariant();authorization_path=$Authorization;authorization_sha256=$AuthorizationSha256.ToLowerInvariant()
    project=[ordered]@{path=$gateProject;before=$gateBefore.project_before;after=$gateProjectFact;exact_one_line_byte_inverse=$gateProjectInverse}
    approved_old_target_count=$gateAllowed.Count;actual_authorized_old_change_count=$gateChanges.Count;actual_authorized_old_changes=$gateChanges;approved_targets_unchanged=$gateUnchangedAuthorized
    facts=$gateFacts;source_count=$gateFacts.Count;backup_facts=$gateBackupFacts;backup_count=$gateBackupFacts.Count
    inherited11b_60_pin_paths_protected_with_only_project_exception=$true
    npc_manifest=[ordered]@{path=$gateManifestPath;fact=$gateManifestFact};npc_sixteen_leaf_facts=$gateNpcFacts;npc_leaf_count=$gateNpcFacts.Count
    explicit_new_source_pin_facts=$gateNewFacts;publisher_report_facts=$gatePublisherFacts
    save_facts=$gateSaves;save_count=$gateSaves.Count;absent_save_count=@($gateSaves.Values | Where-Object {-not $_.exists}).Count
    retained_prior_external_save_history=$gateBefore.retained_prior_external_save_history;retained_fresh_pre_capture_source_changes=$gateBefore.fresh_source_changes_since_prior;retained_fresh_pre_capture_save_changes=$gateBefore.fresh_save_changes_since_prior
    prior3236_credit='HISTORICAL_ONLY_NOT_REHASHED_OR_REAPPROVED';errors=@($gateErrors)
    old_guard_edits=0;engine_runs=0;process_control=0;guard_production_writes=0;save_deserializations=0;save_writes=0;automatic_restore=$false
}
Write-GateNewJson $gateOutput $gateResult
[ordered]@{passed=$gateResult.passed;errors=@($gateErrors);approved_old_targets=$gateAllowed.Count;actual_old_changes=$gateChanges.Count;source_count=$gateFacts.Count;saves=$gateSaves.Count;absent=$gateResult.absent_save_count;npc_leaves=$gateNpcFacts.Count;output=$gateOutput;sha256=(Get-GateFact $gateOutput).sha256}|ConvertTo-Json -Depth 5
if ($gateErrors.Count -gt 0) { exit 1 }
