param(
    [Parameter(Mandatory=$true)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$PlanSha256,
    [string]$Plan = (Join-Path $PSScriptRoot 'guard_plan_READY.json'),
    [string]$Output = (Join-Path $PSScriptRoot 'capture_before_ACTUAL.json')
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'guard_helpers_ROOT_ONLY.ps1')
$gateOutput = Assert-GateNewOutput $Output $PSScriptRoot
$gateGame = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$gatePlanFact = Get-GateFact $Plan
if ($gatePlanFact.sha256 -ne $PlanSha256.ToLowerInvariant()) { throw 'ROOT_EXACT_PLAN_SHA_REQUIRED' }
$gatePlan = Get-Content -LiteralPath $Plan -Raw | ConvertFrom-Json
if ($gatePlan.schema -ne 'GATE_GAIT_20261101C_CAPTURE_PLAN_V1' -or $gatePlan.allowed_autoload_line -cne $GateExactHook) { throw 'EXACT_GATE_GAIT_PLAN_AND_HOOK_REQUIRED' }
$gatePriorPath = Get-GateAbsolute $gatePlan.prior_guard $gateGame
if ((Get-GateFact $gatePriorPath).sha256 -ne '87056f24620fcc3d7c8df540265bebc2551895ee044393e440576e21ec7f0d2d') { throw 'EXACT_11B_FINAL_GUARD_REQUIRED' }
$gatePrior = Get-Content -LiteralPath $gatePriorPath -Raw | ConvertFrom-Json
if ($gatePrior.passed -ne $true -or @($gatePrior.facts.PSObject.Properties).Count -ne 97 -or @($gatePrior.independent_source_pin_facts.PSObject.Properties).Count -ne 60 -or @($gatePrior.save_facts.PSObject.Properties).Count -ne 171) { throw 'PRIOR97_SOURCE60_PINS171_SAVE_SCHEMA_REQUIRED' }
$gateProject = Get-GateAbsolute 'res://project.godot' $gateGame
if ([IO.File]::ReadAllText($gateProject) -match '(?m)^NPCGaitRuntime=') { throw 'CAPTURE_MUST_PRECEDE_NPC_GAIT_PROJECT_HOOK' }
$gatePaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$gateStrict = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$gatePotential = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($property in $gatePrior.facts.PSObject.Properties) { [void]$gatePaths.Add((Get-GateAbsolute $property.Name $gateGame)) }
foreach ($property in $gatePrior.independent_source_pin_facts.PSObject.Properties) {
    $path = Get-GateAbsolute $property.Name $gateGame
    [void]$gatePaths.Add($path)
    if ($path -ne $gateProject) { [void]$gateStrict.Add($path) }
}
foreach ($relative in $gatePlan.potential_old_targets) {
    $path = Get-GateAbsolute $relative $gateGame
    if ($gateStrict.Contains($path) -or $path -eq $gateProject) { throw ('POTENTIAL_TARGET_OVERLAPS_STRICT11B_PIN:' + $path) }
    if (-not $gatePotential.Add($path)) { throw 'DUPLICATE_POTENTIAL_TARGET' }
    [void]$gatePaths.Add($path)
}
if ($gatePotential.Count -ne 33) { throw 'EXACT31_PATHS_PLUS_TWO_OLD_HELPERS_REQUIRED' }
foreach ($relative in $gatePlan.additional_protected_sources) {
    $path = Get-GateAbsolute $relative $gateGame
    [void]$gatePaths.Add($path)
    if (-not $gatePotential.Contains($path)) { [void]$gateStrict.Add($path) }
}
$gateCandidate = [ordered]@{}
if (@($gatePlan.npc_sixteen_leaves).Count -ne 16) { throw 'EXACT16_NPC_RUNTIME_LEAVES_REQUIRED' }
foreach ($relative in @($gatePlan.npc_sixteen_leaves) + @($gatePlan.npc_manifest)) {
    $path = Get-GateAbsolute $relative $gateGame
    $fact = Get-GateFact $path
    if (-not $fact.exists -or -not $fact.stable_during_hash) { throw ('NPC_LEAF_MISSING_OR_UNSTABLE:' + $path) }
    $gateCandidate[$path] = $fact
    if (-not $relative.StartsWith('res://build/npc_gait_20261101c_candidate01/')) { [void]$gatePaths.Add($path); [void]$gateStrict.Add($path) }
}
$gateBefore = [ordered]@{}; $gateHistoricalDifferences = @()
foreach ($path in ($gatePaths | Sort-Object)) {
    if ($path -eq $gateProject) { continue }
    $fact = Get-GateFact $path
    if (-not $fact.exists -or -not $fact.stable_during_hash) { throw ('CAPTURE_SOURCE_MISSING_OR_UNSTABLE:' + $path) }
    $gateBefore[$path] = $fact
    $old = $gatePrior.facts.PSObject.Properties[$path]
    if ($null -eq $old) { $old = $gatePrior.independent_source_pin_facts.PSObject.Properties[$path] }
    if ($null -ne $old -and -not (Test-GateFactSame $old.Value $fact)) { $gateHistoricalDifferences += [ordered]@{path=$path;historical=$old.Value;fresh_before=$fact;policy='RECORD_PRE_CAPTURE_DIFFERENCE_NO_RESTORE_NO_HISTORICAL_PASS_CLAIM'} }
}
$gateProjectBefore = Get-GateFact $gateProject
$gateBackups = [ordered]@{}
foreach ($path in @($gatePotential | Sort-Object) + @($gateProject)) {
    $relative = $path.Substring($gateGame.Replace('\','/').TrimEnd('/').Length + 1)
    $backup = Copy-GateExactBackup $path (Join-Path $PSScriptRoot ('old_target_backups/' + $relative)) $PSScriptRoot
    $gateBackups[$path] = $backup
    $fresh = if ($path -eq $gateProject) { $gateProjectBefore } else { $gateBefore[$path] }
    if (-not (Test-GateFactSame $fresh $backup.fact)) { throw ('BACKUP_NOT_EXACT_CAPTURE_FACT:' + $path) }
}
$gateSaves = [ordered]@{}; $gateSaveDifferences = @()
foreach ($property in $gatePrior.save_facts.PSObject.Properties) {
    if (-not $property.Name.Replace('\','/').StartsWith('C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/', [StringComparison]::OrdinalIgnoreCase)) { throw 'REGISTERED_SAVE_PATH_ONLY' }
    $fact = Get-GateFact $property.Name
    if (-not $fact.stable_during_hash) { throw ('SAVE_CHANGED_DURING_CAPTURE_NO_RESTORE:' + $property.Name) }
    $gateSaves[$property.Name] = $fact
    if (-not (Test-GateFactSame $property.Value $fact)) { $gateSaveDifferences += [ordered]@{path=$property.Name;historical=$property.Value;fresh_before=$fact;policy='USER_EXTERNAL_BEFORE_CAPTURE_KEEP_CURRENT_NO_RESTORE'} }
}
foreach ($path in $gateBefore.Keys) { if (-not (Test-GateFactSame $gateBefore[$path] (Get-GateFact $path))) { throw ('SOURCE_CHANGED_DURING_CAPTURE:' + $path) } }
if (-not (Test-GateFactSame $gateProjectBefore (Get-GateFact $gateProject))) { throw 'PROJECT_CHANGED_DURING_CAPTURE' }
$gateResult = [ordered]@{
    captured_successfully=$true;schema='GATE_GAIT_20261101C_CAPTURE_V1';captured_utc=[DateTime]::UtcNow.ToString('o')
    scope='FINITE_CURRENT97_PLUS60_PATHS_PLUS_EXPLICIT_WALL_AND_NPC_LEAVES_NOT3236_REHASH'
    plan_path=[IO.Path]::GetFullPath($Plan).Replace('\','/');plan_fact=$gatePlanFact
    prior_guard_path=$gatePriorPath;prior_guard_sha256=$gatePlan.prior_guard_sha256
    inherited97_path_count=97;inherited60_pin_path_count=60
    project_path=$gateProject;project_before=$gateProjectBefore;allowed_autoload_line=$GateExactHook
    before_facts=$gateBefore;source_count=$gateBefore.Count
    potential_old_targets=@($gatePotential | Sort-Object);potential_old_target_count=$gatePotential.Count
    strict_immutable_paths=@($gateStrict | Sort-Object);backups=$gateBackups;backup_count=$gateBackups.Count
    npc_candidate_before_facts=$gateCandidate;npc_candidate_before_policy='NEW_CANDIDATE_FILES_INFORMATIONAL_UNTIL_ROOT_EXACT_AFTER_FREEZE; EXISTING_NPC_AND_MEDIA_LEAVES_STRICT'
    save_facts=$gateSaves;save_count=$gateSaves.Count;absent_save_count=@($gateSaves.Values | Where-Object {-not $_.exists}).Count
    fresh_source_changes_since_prior=$gateHistoricalDifferences;fresh_save_changes_since_prior=$gateSaveDifferences
    retained_prior_external_save_history=@($gatePrior.retained_prior_external_save_history,$gatePrior.retained_fresh_pre_capture_external_save_changes)
    old_guard_edits=0;engine_runs=0;process_control=0;production_writes=0;save_deserializations=0;save_writes=0;automatic_restore=$false
}
Write-GateNewJson $gateOutput $gateResult
[ordered]@{path=$gateOutput;sha256=(Get-GateFact $gateOutput).sha256;finite_sources=$gateBefore.Count;potential_old_targets=$gatePotential.Count;backups=$gateBackups.Count;saves=$gateSaves.Count;absent=$gateResult.absent_save_count}|ConvertTo-Json
