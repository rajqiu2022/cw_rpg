param(
    [switch]$ReplaceExistingFreeze,
    [string]$ApprovedFieldSha256 = '15517292104b7e4d8695fd0eb5e6ff36b7a897d8119ce22997537fc62eae6eeb'
)
$ErrorActionPreference = 'Stop'
if ($ApprovedFieldSha256 -cnotmatch '^[0-9a-f]{64}$') { throw 'ApprovedFieldSha256 must be an explicit lowercase SHA256 from Root-approved mechanical wall successor evidence, never inferred from the current disk.' }
$gaitGameRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$gaitOutput = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'source_pins_READY.json'))
function Local-Gait([string]$path) {
    if (-not $path.StartsWith('res://') -or $path.Contains('..')) { throw "Invalid source: $path" }
    $resolved = [IO.Path]::GetFullPath((Join-Path $gaitGameRoot $path.Substring(6)))
    if (-not $resolved.StartsWith($gaitGameRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Source outside game' }
    return $resolved
}
function Gait-Sha([string]$path) { return (Get-FileHash -LiteralPath (Local-Gait $path) -Algorithm SHA256).Hash.ToLowerInvariant() }
function Require-Gait-Pin([string]$path, [string]$sha) {
    if ((Gait-Sha $path) -ne $sha) { throw "Reviewed exact source changed: $path" }
}
$gaitSelf = 'res://build/npc_gait_20261101c_candidate01/npc_gait_runtime.gd'
$gaitProject = [IO.File]::ReadAllText((Local-Gait 'res://project.godot'))
$gaitHook = '(?m)^NPCGaitRuntime="\*res://build/npc_gait_20261101c_candidate01/npc_gait_runtime\.gd"\r?$'
if ([regex]::Matches($gaitProject, $gaitHook).Count -ne 1) { throw 'Root must register the exact one-line NPCGaitRuntime hook before freezing.' }
$gaitReviewed = [ordered]@{
    $gaitSelf = '7ff3a81d5ba474c78f23773f90c2f701906f6517227d5e3df873792e880e4830'
    'res://build/npc_gait_20261101c_candidate01/distance_phase.gd' = '5b5d0bd8e85fae36ec77926f9aeee6b946a06b8896f730e271417aeb4579b67c'
    'res://build/npc_gait_20261101c_candidate01/gait_rules.json' = '933bbd6d3069e4495afc19c4668e74b4ec2dee5c30dbb9185bb95383f203db11'
    'res://scripts/field/npc_node.gd' = '67c0f3deafef65445918b5815f4acdcb4cc577206248f20cd67a998930d00bea'
    'res://art/characters/luoyang_city_finish_20261025i/guard_young_bluegrey_walk4_v1_runtime160.png' = '4e2a8cf7a787c20301150d4cead0a14d4c6b65ec4a2a8db3dfe5008f527a05fa'
    'res://art/characters/luoyang_city_finish_20261025i/guard_young_bluegrey_walk4_v1_runtime160.png.import' = 'b04829c820ebaff489d0d8ac699c3eda20a18974f5da244ffbeec994cbf75ce3'
    'res://.godot/imported/guard_young_bluegrey_walk4_v1_runtime160.png-33c6cf258dde86fa8b2ee4355fbcd0b6.ctex' = '4258e742a6229240fbf75a7ccb4923b8fc14e7abaab5e6f17fce55c3a630d3eb'
    'res://art/characters/luoyang_city_finish_20261025i/guard_veteran_ochre_walk4_v1_runtime160.png' = 'e43c9214233d6717b0c278cbbaceb89104254e50135755b1c50e771af1295761'
    'res://art/characters/luoyang_city_finish_20261025i/guard_veteran_ochre_walk4_v1_runtime160.png.import' = 'f15b55c05b184e76c3a0dbce8eb28b698f9bfa134f40c52e5f066626ed981e7f'
    'res://.godot/imported/guard_veteran_ochre_walk4_v1_runtime160.png-6a912af0e576bb94f34274c0eb5fea3c.ctex' = 'de6dd496b8dd4368da665ad574e798b7fef3f2c819e8224eda9b9c984d355c12'
}
$gaitPipeline = [ordered]@{
    # Default is the reviewed old Field. Root may supply only its explicitly
    # approved wall mechanical-successor SHA; do not derive it from actual bytes.
    'res://scripts/field/field_walkable_controller.gd' = $ApprovedFieldSha256
    'res://build/luoyang_city_finish_20261025i_source01/runtime_READY01/ambient18_runtime_READY.gd' = 'e482fc0043a16c6a873941b1c5706819618896209cbc753ef1535e2231b7a787'
    'res://build/luoyang_city_finish_20261025i_system01/ambient18_visual_contract02_NOTREADY.json' = '0a65ecd3a2a6150c1080eb86cdb31a5657331d948e9d2776bc74db3e4336da25'
}
foreach ($entry in $gaitReviewed.GetEnumerator()) { Require-Gait-Pin $entry.Key $entry.Value }
foreach ($entry in $gaitPipeline.GetEnumerator()) { Require-Gait-Pin $entry.Key $entry.Value }
# Exact static equivalent of runtime.source_paths(): 4 executable/rules leaves
# plus four existing walk PNG/import/actualctex triples. No old FIRST writes.
$gaitPaths = @(
    $gaitSelf,
    'res://build/npc_gait_20261101c_candidate01/distance_phase.gd',
    'res://build/npc_gait_20261101c_candidate01/gait_rules.json',
    'res://scripts/field/npc_node.gd',
    'res://art/characters/street_expansion_v2/npc_escort_guard_walk_right_8f_v1_runtime.png',
    'res://art/characters/street_expansion_v2/npc_escort_guard_walk_right_8f_v1_runtime.png.import',
    'res://.godot/imported/npc_escort_guard_walk_right_8f_v1_runtime.png-26049427850b181f9b666a67cc0aa828.ctex',
    'res://art/characters/street_expansion_v1/npc_street_merchant_right_walk_8f_v3_runtime.png',
    'res://art/characters/street_expansion_v1/npc_street_merchant_right_walk_8f_v3_runtime.png.import',
    'res://.godot/imported/npc_street_merchant_right_walk_8f_v3_runtime.png-35fc077f791e3c458a9bc26919d739dd.ctex',
    'res://art/characters/luoyang_city_finish_20261025i/guard_young_bluegrey_walk4_v1_runtime160.png',
    'res://art/characters/luoyang_city_finish_20261025i/guard_young_bluegrey_walk4_v1_runtime160.png.import',
    'res://.godot/imported/guard_young_bluegrey_walk4_v1_runtime160.png-33c6cf258dde86fa8b2ee4355fbcd0b6.ctex',
    'res://art/characters/luoyang_city_finish_20261025i/guard_veteran_ochre_walk4_v1_runtime160.png',
    'res://art/characters/luoyang_city_finish_20261025i/guard_veteran_ochre_walk4_v1_runtime160.png.import',
    'res://.godot/imported/guard_veteran_ochre_walk4_v1_runtime160.png-6a912af0e576bb94f34274c0eb5fea3c.ctex'
)
if ($gaitPaths.Count -ne 16 -or @($gaitPaths | Select-Object -Unique).Count -ne 16) { throw 'Exact sixteen runtime leaves required.' }
$gaitRules = Get-Content -LiteralPath (Local-Gait 'res://build/npc_gait_20261101c_candidate01/gait_rules.json') -Raw | ConvertFrom-Json
foreach ($entry in $gaitRules.walk_assets.PSObject.Properties) {
    $gaitImport = [IO.File]::ReadAllText((Local-Gait ($entry.Name + '.import')))
    $gaitMatch = [regex]::Match($gaitImport, '(?m)^path="(res://\.godot/imported/[^"\r\n]+\.ctex)"\r?$')
    if (-not $gaitMatch.Success -or $gaitMatch.Groups[1].Value -notin $gaitPaths) { throw 'Actual GPU import target not in the exact sixteen leaves.' }
}
$gaitPins = [ordered]@{}
foreach ($path in ($gaitPaths | Sort-Object)) { $gaitPins[$path] = Gait-Sha $path }
$gaitQaPins = [ordered]@{}
foreach ($entry in $gaitPipeline.GetEnumerator()) { $gaitQaPins[$entry.Key] = $entry.Value }
foreach ($path in @(
    'res://build/npc_gait_20261101c_candidate01/freeze_ROOT_ONLY.ps1',
    'res://build/npc_gait_20261101c_qa01/parse_pure_ROOT_ONLY.gd',
    'res://build/npc_gait_20261101c_qa01/gate_finite_ROOT_ONLY.gd',
    'res://build/npc_gait_20261101c_qa01/gate_inputs_ROOT_READY.json',
    'res://scripts/autoload/scene_router.gd', 'res://data/scenes/ch4_s0_luoyang_gate.tres',
    'res://scripts/autoload/dialog_player.gd', 'res://scripts/ui/dialog_box.gd'
)) { $gaitQaPins[$path] = Gait-Sha $path }
$gaitDocument = [ordered]@{
    schema = 'NPC_GAIT_RUNTIME_20261101C_INDEPENDENT_V1'; ready = $true
    source_pins = $gaitPins; qa_pins = $gaitQaPins
    verified_last_consumer_pipeline = $gaitPipeline
    hook_registration = ('NPCGaitRuntime="*' + $gaitSelf + '"')
    project_sha256_at_root_freeze = Gait-Sha 'res://project.godot'
    policy = 'Independent sixteen-leaf gait source proof only; not an old Luoyang source_first successor or source-key insertion. Root-only QA remains pending.'
}
if (-not $gaitOutput.StartsWith($PSScriptRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Manifest target outside candidate directory.' }
if (Test-Path -LiteralPath $gaitOutput) {
    if (-not $ReplaceExistingFreeze) { throw 'Existing freeze preserved. Explicit -ReplaceExistingFreeze archives its exact bytes before writing the new freeze.' }
    $gaitPriorSha = (Get-FileHash -LiteralPath $gaitOutput -Algorithm SHA256).Hash.ToLowerInvariant()
    $gaitArchive = Join-Path $PSScriptRoot ('source_pins_BEFORE_' + $gaitPriorSha + '.json')
    if (Test-Path -LiteralPath $gaitArchive) {
        if ((Get-FileHash -LiteralPath $gaitArchive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $gaitPriorSha) { throw 'Existing immutable prior freeze archive is corrupt; not overwriting.' }
    } else { [IO.File]::WriteAllBytes($gaitArchive, [IO.File]::ReadAllBytes($gaitOutput)) }
}
$gaitJson = ($gaitDocument | ConvertTo-Json -Depth 30) -replace "`r`n", "`n"
[IO.File]::WriteAllText($gaitOutput, $gaitJson.TrimEnd() + "`n", [Text.UTF8Encoding]::new($false))
[pscustomobject]@{ path = $gaitOutput; sha256 = (Get-FileHash -LiteralPath $gaitOutput).Hash.ToLowerInvariant(); runtime_leaves = $gaitPins.Count; qa_leaves = $gaitQaPins.Count; engine_calls = 0; old_source_first_writes = 0 } | ConvertTo-Json
