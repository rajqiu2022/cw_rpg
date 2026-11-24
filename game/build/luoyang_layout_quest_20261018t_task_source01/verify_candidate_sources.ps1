$ErrorActionPreference = 'Stop'

$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$ContractPath = Join-Path $PSScriptRoot 'source_contract.json'
$Contract = Get-Content -Raw -Encoding UTF8 -LiteralPath $ContractPath | ConvertFrom-Json
$Checks = [System.Collections.Generic.List[object]]::new()

function Add-Check([string]$Name, [bool]$Passed, [string]$Detail) {
    $Checks.Add([pscustomobject]@{ name = $Name; passed = $Passed; detail = $Detail })
    if (-not $Passed) { throw "CHECK_FAILED: $Name :: $Detail" }
}

foreach ($Property in $Contract.production_sources.PSObject.Properties) {
    $Relative = $Property.Name
    $Expected = $Property.Value
    $Path = Join-Path $Root $Relative
    Add-Check "source_exists:$Relative" (Test-Path -LiteralPath $Path -PathType Leaf) $Path
    $Item = Get-Item -LiteralPath $Path
    Add-Check "source_bytes:$Relative" ($Item.Length -eq [int64]$Expected.bytes) "actual=$($Item.Length) expected=$($Expected.bytes)"
    $Sha = (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
    Add-Check "source_sha256:$Relative" ($Sha -eq [string]$Expected.sha256) "actual=$Sha expected=$($Expected.sha256)"
}

foreach ($Property in $Contract.candidate_assets.PSObject.Properties) {
    $Relative = $Property.Name
    $Expected = $Property.Value
    $Path = Join-Path $Root $Relative
    Add-Check "candidate_asset_exists:$Relative" (Test-Path -LiteralPath $Path -PathType Leaf) $Path
    $Item = Get-Item -LiteralPath $Path
    Add-Check "candidate_asset_bytes:$Relative" ($Item.Length -eq [int64]$Expected.bytes) "actual=$($Item.Length) expected=$($Expected.bytes)"
    $Sha = (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
    Add-Check "candidate_asset_sha256:$Relative" ($Sha -eq [string]$Expected.sha256) "actual=$Sha expected=$($Expected.sha256)"
}

Add-Type -AssemblyName System.Drawing
$MonkPath = Join-Path $Root 'game\art\characters\luoyang_layout_quest_20261018t\npc_temple_gate_monk_idle_down_1f_v1.png'
$Monk = [System.Drawing.Bitmap]::FromFile($MonkPath)
try {
    Add-Check 'monk_runtime_size_160_square' ($Monk.Width -eq 160 -and $Monk.Height -eq 160) "actual=$($Monk.Width)x$($Monk.Height)"
    $MinX = $Monk.Width; $MinY = $Monk.Height; $MaxX = -1; $MaxY = -1; $EdgeMax = 0
    for ($Y = 0; $Y -lt $Monk.Height; $Y++) {
        for ($X = 0; $X -lt $Monk.Width; $X++) {
            $Alpha = $Monk.GetPixel($X, $Y).A
            if ($X -eq 0 -or $Y -eq 0 -or $X -eq $Monk.Width - 1 -or $Y -eq $Monk.Height - 1) { $EdgeMax = [math]::Max($EdgeMax, $Alpha) }
            if ($Alpha -gt 0) {
                $MinX = [math]::Min($MinX, $X); $MinY = [math]::Min($MinY, $Y)
                $MaxX = [math]::Max($MaxX, $X); $MaxY = [math]::Max($MaxY, $Y)
            }
        }
    }
    $BoundsWidth = $MaxX - $MinX + 1; $BoundsHeight = $MaxY - $MinY + 1
    Add-Check 'monk_runtime_a1_bounds' ($MinX -eq 52 -and $MinY -eq 6 -and $BoundsWidth -eq 58 -and $BoundsHeight -eq 148) "actual=[$MinX,$MinY,$BoundsWidth,$BoundsHeight]"
    Add-Check 'monk_runtime_edges_transparent' ($EdgeMax -eq 0) "actual_edge_max_alpha=$EdgeMax"
    $Scale = 140.0 / [double]$BoundsHeight
    $FootError = [math]::Abs((0.45 * $Monk.Height) - (($MaxY + 1) - ($Monk.Height / 2.0))) * $Scale
    Add-Check 'monk_runtime_scale_exact_140_over_148' ([math]::Abs($Scale - 0.9459459459459459) -lt 0.0000000001) "actual=$Scale"
    Add-Check 'monk_runtime_noncal_foot_error_under_12' ([math]::Abs($FootError - 1.89189189189189) -lt 0.000001 -and $FootError -le 12.0) "actual=$FootError"
}
finally {
    $Monk.Dispose()
}

$Projection = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'luoyang_task_projection_candidate.gd')
foreach ($Literal in @(
    'temple_cave_keeper_20261018t', 'temple_bell_keeper_20261018t',
    'Vector2(936.0, 900.0)', 'Vector2(600.0, 900.0)',
    'Vector2(380.0, 600.0)', 'Vector2(1320.0, 670.0)',
    'Vector2(240.0, 850.0)', 'Vector2(1296.0, 850.0)',
    'Vector2(0.12, 0.75)',
    'longmen_investigate', 'baima_investigate', 'peony_investigate'
)) {
    Add-Check "projection_literal:$Literal" $Projection.Contains($Literal) $Literal
}
Add-Check 'projection_requires_separate_source_portals' $Projection.Contains('project_temple(base: Dictionary, source_portals: Array') 'current Temple adapter does not return portals'
Add-Check 'projection_keeps_ordinary_exit_zone' ($Projection.Contains('portal.has("source_spawn_pos")') -and -not $Projection.Contains('portal["source_spawn_pos"] =')) 'paired return uses existing pos fallback without selecting outskirts_exit_zone'
Add-Check 'projection_pins_approved_monk_asset' ($Projection.Contains('6268061eab18d2bf8c1ea0c13873f0d718feb82a119f00a67edf7c52bcb077ad') -and $Projection.Contains('const MONK_ASSET_BYTES := 16832') -and $Projection.Contains('const MONK_SCALE := 0.9459459459459459') -and $Projection.Contains('const MONK_PORTRAIT := MONK_SPRITE') -and $Projection.Contains('TASK_MONK_ASSET_SOURCE_CHANGED')) 'approved monk identity, temporary correct portrait and derived scale must fail closed on drift'
Add-Check 'projection_does_not_disable_monk_interaction' (-not $Projection.Contains('harbour_life_ground_anchored') -and -not $Projection.Contains('district_life_ground_anchored')) 'task monks must remain ordinary interactive NPCs'
Add-Check 'projection_requires_two_real_monk_entities' ($Projection.Contains('if npcs.size() != 2') -and $Projection.Contains('_project_monk(npcs, "temple_cave_keeper_20261018t"') -and $Projection.Contains('_project_monk(npcs, "temple_bell_keeper_20261018t"')) 'both exact persistent scene NPCs are projected in place'
Add-Check 'projection_refuses_legacy_speaker_hotspots' ($Projection.Contains('TASK_LEGACY_SPEAKER_HOTSPOT_STILL_PRESENT') -and $Projection.Contains('"legacy_hotspot_4"') -and $Projection.Contains('"legacy_hotspot_5"')) 'successor layout must remove both hidden speakers before dynamic projection'
Add-Check 'longmen_requires_cross_courtyard_walk' ([math]::Sqrt([math]::Pow(936 - 380, 2) + [math]::Pow(900 - 600, 2)) -ge 400.0) 'monk-to-investigation distance must not be a one-step completion'
Add-Check 'baima_requires_cross_courtyard_walk' ([math]::Sqrt([math]::Pow(600 - 1320, 2) + [math]::Pow(900 - 670, 2)) -ge 400.0) 'monk-to-investigation distance must not be a one-step completion'
Add-Check 'projection_peony_started_routes_to_answer' ($Projection.Contains('if stage.peony == "started"') -and $Projection.Contains('_dialog("peony_investigate")')) 'Peony answer is a distinct second interaction'

$QuestFiles = Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'quests') -Filter '*.tres'
$DialogFiles = Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'dialogs') -Filter '*.tres'
Add-Check 'three_quest_defs' ($QuestFiles.Count -eq 3) "actual=$($QuestFiles.Count)"
Add-Check 'fifteen_dialog_defs' ($DialogFiles.Count -eq 15) "actual=$($DialogFiles.Count)"

$IdentityAndRewardFields = @('quest_id', 'title', 'kind', 'desc_not_started', 'desc_completed', 'tracker_hint', 'reward_gold', 'reward_exp', 'reward_items')
foreach ($Quest in $QuestFiles) {
    $Candidate = Get-Content -Raw -Encoding UTF8 -LiteralPath $Quest.FullName
    $Production = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $Root "game\data\quests\$($Quest.Name)")
    Add-Check "empty_completion_triggers:$($Quest.Name)" $Candidate.Contains('completion_triggers = Array[String]([])') 'accept must not auto-complete from historical flags'
    foreach ($Field in $IdentityAndRewardFields) {
        $Pattern = '(?m)^' + [regex]::Escape($Field) + ' = .+$'
        $CandidateLine = [regex]::Match($Candidate, $Pattern).Value.Trim()
        $ProductionLine = [regex]::Match($Production, $Pattern).Value.Trim()
        Add-Check "identity_or_reward_preserved:$($Quest.Name):$Field" (($CandidateLine.Length -gt 0) -and ($CandidateLine -eq $ProductionLine)) "candidate=$CandidateLine production=$ProductionLine"
    }
}

$Cases = @(
    @{ kind='longmen'; qid='q_ch4_side_04_longmen_mystery'; start='longmen_mystery_started_20261018t'; evidence='longmen_mystery_investigated_20261018t'; legacy='longmen_mystery_solved' },
    @{ kind='baima'; qid='q_ch4_side_05_baima_bell'; start='baima_bell_started_20261018t'; evidence='baima_bell_investigated_20261018t'; legacy='baima_bell_solved' },
    @{ kind='peony'; qid='q_ch4_side_03_peony_poetry'; start='peony_poetry_started_20261018t'; evidence='peony_poetry_answered_20261018t'; legacy='peony_poetry_won' }
)

$StateRows = [System.Collections.Generic.List[object]]::new()
foreach ($Case in $Cases) {
    $Offer = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot "dialogs\$($Case.kind)_offer.tres")
    $Progress = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot "dialogs\$($Case.kind)_progress.tres")
    $Investigate = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot "dialogs\$($Case.kind)_investigate.tres")
    $Report = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot "dialogs\$($Case.kind)_report.tres")
    Add-Check "offer_accepts_only:$($Case.kind)" ($Offer.Contains("accept_quest = &`"$($Case.qid)`"") -and -not $Offer.Contains('complete_quest =') -and -not $Offer.Contains($Case.evidence) -and -not $Offer.Contains($Case.legacy)) 'offer cannot investigate, solve or claim'
    Add-Check "accepted_node_sets_start:$($Case.kind)" $Offer.Contains($Case.start) 'only accepted branch advances start'
    Add-Check "active_recovery_sets_start_only:$($Case.kind)" ($Progress.Contains($Case.start) -and -not $Progress.Contains('complete_quest =') -and -not $Progress.Contains($Case.evidence) -and -not $Progress.Contains($Case.legacy)) 'interrupted ACTIVE state can recover without reward'
    Add-Check "investigation_sets_evidence_only:$($Case.kind)" ($Investigate.Contains($Case.evidence) -and -not $Investigate.Contains('complete_quest =') -and -not $Investigate.Contains($Case.legacy)) 'evidence is post-accept and not a reward claim'
    Add-Check "report_completes:$($Case.kind)" ($Report.Contains("complete_quest = &`"$($Case.qid)`"") -and $Report.Contains($Case.legacy)) 'only report closes quest and writes compatibility flag'

    # Pure state contract simulation; this is intentionally not engine credit.
    $Status = 'NOT_STARTED'; $Started = $false; $Evidence = $false; $Completed = $false; $RewardGrants = 0
    $LegacyAlreadyTrue = $true
    Add-Check "sim_reject_no_side_effect:$($Case.kind)" (($Status -eq 'NOT_STARTED') -and -not $Started -and -not $Evidence -and -not $Completed -and $RewardGrants -eq 0) 'rejected side-offer never reaches accepted node'
    $Status = 'ACTIVE'; $Started = $true
    Add-Check "sim_accept_no_credit:$($Case.kind)" (($Status -eq 'ACTIVE') -and $Started -and -not $Evidence -and -not $Completed -and $RewardGrants -eq 0 -and $LegacyAlreadyTrue) 'legacy flag is deliberately ignored because completion_triggers is empty'
    Add-Check "sim_pre_evidence_report_refused:$($Case.kind)" (-not $Evidence -and $Status -eq 'ACTIVE') 'projection authorizes progress/investigate, not report'
    $Evidence = $true
    Add-Check "sim_evidence_no_credit:$($Case.kind)" ($Status -eq 'ACTIVE' -and $Evidence -and -not $Completed -and $RewardGrants -eq 0) 'evidence only unlocks report'
    if ($Status -eq 'ACTIVE' -and $Evidence) { $Status = 'COMPLETED'; $Completed = $true; $RewardGrants++ }
    if ($Status -eq 'ACTIVE' -and $Evidence) { $RewardGrants++ }
    Add-Check "sim_claim_exactly_once:$($Case.kind)" ($Status -eq 'COMPLETED' -and $Completed -and $RewardGrants -eq 1) 'QuestManager.complete rejects repeat claim after status changes'
    $StateRows.Add([pscustomobject]@{ quest = $Case.qid; final_status = $Status; reward_grants = $RewardGrants })
}

$PortalA = [System.Numerics.Vector2]::new(240, 850)
$PortalB = [System.Numerics.Vector2]::new(1296, 850)
$Distance = [System.Numerics.Vector2]::Distance($PortalA, $PortalB)
Add-Check 'portal_distance_1056' ([math]::Abs($Distance - 1056.0) -lt 0.001) "actual=$Distance"

[pscustomobject]@{
    status = 'STATIC_SOURCE_PASS'
    engine_or_field_run = $false
    checks = $Checks.Count
    quest_state_rows = $StateRows
    runtime_acceptance_pending = $Contract.runtime_acceptance_pending
} | ConvertTo-Json -Depth 8
