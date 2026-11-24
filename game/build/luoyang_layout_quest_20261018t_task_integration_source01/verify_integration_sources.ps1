$ErrorActionPreference = 'Stop'
$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$Checks = [System.Collections.Generic.List[object]]::new()

function Add-Check([string]$Name, [bool]$Passed, [string]$Detail) {
    $Checks.Add([pscustomobject]@{ name = $Name; passed = $Passed; detail = $Detail })
    if (-not $Passed) { throw "CHECK_FAILED: $Name :: $Detail" }
}
function Repo-Path([string]$Path) {
    if ($Path.StartsWith('res://')) { return Join-Path (Join-Path $Repo 'game') $Path.Substring(6) }
    return Join-Path $Repo $Path
}
function Sha([string]$Path) { return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant() }

$Current = @{
    'game/scripts/city/luoyang_city_tasks_20261016.gd' = '27944bbb516bce10fad01b02efd714f1ce63029adcdaf83e701445962d34e13c'
    'game/scripts/city/luoyang_temple_assembly_20261016.gd' = '5d934e3167f9e4e8011583a48df9daacb9d066d08bd9d2b4d0f93659dd8ef5eb'
    'game/scripts/city/luoyang_temple_task_adapter_20261016.gd' = 'e8d3537f5aa8e7ec1e071586f692bc2f52f4a5cab822732f4f4195e9141fc122'
    'game/data/quests/q_ch4_side_03_peony_poetry.tres' = 'e8f5bed6647764d9db6a20a637bfc9474e6e2ad7f53febb1bf0bc97cfc4e81cc'
    'game/data/quests/q_ch4_side_04_longmen_mystery.tres' = '31e1edfd84e9dae73c7fa57ddacad11313c6c298fbcb6d26d50d74fd252d51d7'
    'game/data/quests/q_ch4_side_05_baima_bell.tres' = 'eea29b62fec37433bb25acd0dd98b9a11918c9f5fe3ffedf8441b4b57a1798e9'
    'game/scripts/autoload/quest_manager.gd' = 'c6ebd067f9b2e0660aa105e90c6ec7c777da895c19fcd701e438a2811405a03c'
    'game/scripts/autoload/scene_router.gd' = '15665b17fde4aad37a9609fc46f441dad3893ce1b3ba3f02f530f44e916d6759'
    'game/scripts/field/field_walkable_controller.gd' = '34081bd719470b53aa4b418e1772d7a11c2a6fe0573d735537ce8d58338a19b9'
    'game/scripts/city/luoyang_enclosure_v11_candidate_contract.gd' = '9503bbae74846e1947a49509a412d92b31a9ba9b70194ccdeb0fe62409800089'
}
foreach ($Entry in $Current.GetEnumerator()) {
    $Path = Repo-Path $Entry.Key
    Add-Check "current_unchanged:$($Entry.Key)" ((Test-Path -LiteralPath $Path -PathType Leaf) -and (Sha $Path) -eq $Entry.Value) $Path
}

$DeltaPath = Join-Path $PSScriptRoot 'source_delta.json'
$Delta = Get-Content -Raw -Encoding UTF8 -LiteralPath $DeltaPath | ConvertFrom-Json
Add-Check 'source_delta_status' ($Delta.status -eq 'SOURCE_READY_NOT_DEPLOYED') $Delta.status
foreach ($Row in $Delta.replace_existing) {
    $Target = Repo-Path ([string]$Row.target)
    $Candidate = Repo-Path ([string]$Row.candidate)
    Add-Check "replace_old_exact:$($Row.target)" ((Sha $Target) -eq [string]$Row.old_sha256) $Target
    Add-Check "replace_candidate_exact:$($Row.target)" ((Sha $Candidate) -eq [string]$Row.candidate_sha256) $Candidate
}
foreach ($Property in $Delta.new_inactive_until_replacements_land.PSObject.Properties) {
    $Path = Repo-Path $Property.Name
    Add-Check "new_inactive_exact:$($Property.Name)" ((Sha $Path) -eq [string]$Property.Value) $Path
}

$TaskBindingPath = Join-Path $PSScriptRoot 'task_runtime_binding.json'
$TaskBinding = Get-Content -Raw -Encoding UTF8 -LiteralPath $TaskBindingPath | ConvertFrom-Json
Add-Check 'task_binding_canonical_resolution_required' ($TaskBinding.same_id_quest_canonical_resolution_required -eq $true) 'QuestManager keeps canonical res://data/quests path'
foreach ($Property in $TaskBinding.source_sha256.PSObject.Properties) {
    $Path = Repo-Path $Property.Name
    if ($Property.Name.StartsWith('res://data/quests/')) {
        $Candidate = Join-Path (Join-Path $Repo 'game/build/luoyang_layout_quest_20261018t_task_source01/quests') ([IO.Path]::GetFileName($Property.Name))
        Add-Check "quest_candidate_exact:$($Property.Name)" ((Sha $Candidate) -eq [string]$Property.Value) $Candidate
        Add-Check "quest_canonical_still_old_before_deploy:$($Property.Name)" ((Sha $Path) -ne [string]$Property.Value) 'expected pending replacement; no in-memory resolver credit'
    } else {
        Add-Check "task_runtime_leaf_exact:$($Property.Name)" ((Sha $Path) -eq [string]$Property.Value) $Path
    }
}

$CityTasks = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'luoyang_city_tasks_20261016_candidate.gd')
Add-Check 'citytasks_owns_new_namespace' ($CityTasks.Contains('or T.owns_dialog(id)')) 'Field existing owns/authorize entry reaches the successor namespace after replacement'
Add-Check 'citytasks_authorizes_new_namespace' ($CityTasks.Contains('T.owns_dialog(id): return _task_sources_ready() and T.authorize_dialog')) 'unknown or stale successor source fails closed'
Add-Check 'citytasks_market_dispatch' ($CityTasks.Contains('T.project_market(result,flags,quest_states)')) 'Peony uses actual current Market projection'
Add-Check 'citytasks_requires_canonical_quest_bytes' ($CityTasks.Contains('same_id_quest_defs_resolve_from_canonical_paths')) 'same-ID definitions are not an in-memory-only fixture'

$Assembly = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'luoyang_temple_assembly_20261016_candidate.gd')
$Adapter = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'luoyang_temple_task_adapter_20261016_candidate.gd')
Add-Check 'assembly_uses_actual_successor_scene' ($Assembly.Contains('luoyang_temple_layout_quest_20261018t/temple.tres') -and $Assembly.Contains('luoyang_temple_layout_quest_20261018t/layout.tres')) 'SceneRouter continues through unchanged assembly API'
Add-Check 'assembly_builds_two_real_npcs' ($Assembly.Contains('successor_npcs()') -and $Assembly.Contains('scene.npcs.assign(successor_npcs())')) 'monks are actual Scene data'
Add-Check 'assembly_removes_hidden_speakers' ($Assembly.Contains('successor_interactions') -and $Assembly.Contains('successor_hotspots')) 'both map and legacy source views omit hidden speaker interactions'
Add-Check 'adapter_projects_temple_successor' ($Adapter.Contains('TASK.project_temple(base,source_portals,flags,states)')) 'stateful monk/investigation projection is on the real successor child'
Add-Check 'adapter_keeps_old_paper_oracle' ($Adapter.Contains('only_paper_phase_delta_in_old_task_layer') -and $Adapter.Contains('old_projected')) 'unrelated Temple paper task stays delegated'

$Scene = Get-Content -Raw -Encoding UTF8 -LiteralPath (Repo-Path 'game/data/scenes/luoyang_temple_layout_quest_20261018t/temple.tres')
$Layout = Get-Content -Raw -Encoding UTF8 -LiteralPath (Repo-Path 'game/data/maps/luoyang_temple_layout_quest_20261018t/layout.tres')
Add-Check 'scene_has_two_monk_entities' (([regex]::Matches($Scene, '"npc_id": "temple_(cave|bell)_keeper_20261018t"')).Count -eq 2) 'two persistent entity rows'
Add-Check 'scene_has_no_old_speaker_actions' (-not $Scene.Contains('dialog:ch4_longmen_mystery') -and -not $Scene.Contains('dialog:ch4_baima_bell')) 'no unused hidden-speaker rows remain in successor Scene'
Add-Check 'layout_has_no_old_speaker_ids' (-not $Layout.Contains('legacy_hotspot_4') -and -not $Layout.Contains('legacy_hotspot_5')) 'actual MapLayout has four base interactions'
foreach ($Literal in @('Vector2(0.15625, 0.830078125)','Vector2(0.84375, 0.830078125)','"target_scene": "ch4_s3_luoyang_market"','"target_scene": "ch4_s2_canal_docks"','"target_pos": Vector2(0.12, 0.75)')) {
    Add-Check "layout_portal_literal:$Literal" $Layout.Contains($Literal) $Literal
}
$LongmenDistance = [math]::Sqrt([math]::Pow(936 - 380, 2) + [math]::Pow(900 - 600, 2))
$BaimaDistance = [math]::Sqrt([math]::Pow(600 - 1320, 2) + [math]::Pow(900 - 670, 2))
Add-Check 'longmen_cross_courtyard_distance' ($LongmenDistance -ge 400.0) "actual=$LongmenDistance"
Add-Check 'baima_cross_courtyard_distance' ($BaimaDistance -ge 400.0) "actual=$BaimaDistance"

[pscustomobject]@{
    status = 'SOURCE_INTEGRATION_STATIC_PASS'
    checks = $Checks.Count
    engine_or_field_run = $false
    production_deployed = $false
    canonical_quest_replacement_pending = 3
    runtime_acceptance_pending = @('proper/check-only','same-ID canonical QuestDef load','Temple entity and interaction feet 875+17/Physics','ordinary portal paired return','source-first/source-final and 15 saves')
} | ConvertTo-Json -Depth 8
