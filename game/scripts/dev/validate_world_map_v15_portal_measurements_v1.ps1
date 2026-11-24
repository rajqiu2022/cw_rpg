param([string]$RepositoryRoot = (Join-Path $PSScriptRoot '../../..'))
# Read-only CPU integrity check. Exit 0 validates recorded RGBA samples and
# algebra, NOT navigation, collision, root visual approval or playable portals.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$taskRoot = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$gameRoot = Join-Path $taskRoot 'game'
$measurementPath = Join-Path $gameRoot 'data/maps/world_map_v15_portal_measurements_v1.json'
$contract = Get-Content -LiteralPath $measurementPath -Raw | ConvertFrom-Json
$checks = 0
function Assert-Measurement([bool]$Condition, [string]$Message) {
    $script:checks++
    if (-not $Condition) { throw $Message }
}
function Resolve-Resource([string]$ResourcePath) {
    Assert-Measurement ($ResourcePath.StartsWith('res://')) ('Non-resource path: ' + $ResourcePath)
    $resolved = [IO.Path]::GetFullPath((Join-Path $gameRoot $ResourcePath.Substring(6)))
    Assert-Measurement ($resolved.StartsWith($gameRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) 'Resource leaves game root'
    return $resolved
}
function Assert-Pair($Actual, $Expected, [string]$Message, [double]$Tolerance = 0.00001) {
    Assert-Measurement ($Actual.Count -eq 2 -and $Expected.Count -eq 2) $Message
    for ($axis = 0; $axis -lt 2; $axis++) {
        Assert-Measurement ([double]::IsFinite([double]$Actual[$axis]) -and [math]::Abs([double]$Actual[$axis] - [double]$Expected[$axis]) -le $Tolerance) $Message
    }
}
Assert-Measurement ($contract.schema_version -eq 1 -and $contract.world_version -eq 15) 'Wrong measurement schema'
Assert-Measurement ($contract.status -eq 'SOURCE_RGBA_MEASUREMENT_ONLY_NOT_PUBLISHABLE' -and -not $contract.production_approved -and -not $contract.runtime_eligible) 'Measurement cannot approve runtime'
Assert-Measurement ($contract.inventory.current_total -eq 16 -and $contract.inventory.new_sect_compounds -eq 5 -and $contract.inventory.legacy_landmarks -eq 11 -and $contract.inventory.preexisting_semantics_missing_count -eq 13) 'Stale doorway inventory'
Assert-Measurement ($contract.measurement.alpha_is_not_navigation -and -not $contract.measurement.image_modified) 'RGBA evidence may not replace navigation'
$sourceReview = $contract.root_source_threshold_review
Assert-Measurement ($sourceReview.status -eq 'SOURCE_THRESHOLD_DIRECTION_PASS' -and $sourceReview.reviewer -eq 'root' -and $sourceReview.review_date -eq '2026-10-03' -and $sourceReview.source_bindings.Count -eq 16) 'Root source-direction review must remain separately scoped'
$binding = $contract.geography_binding
foreach ($kind in @('source', 'forecast')) {
    $path = Resolve-Resource $binding.($kind + '_path')
    Assert-Measurement ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -eq $binding.($kind + '_sha256')) ('Changed frozen geography ' + $kind)
}
$forecast = Get-Content -LiteralPath (Resolve-Resource $binding.forecast_path) -Raw | ConvertFrom-Json
$seen = @{}
Assert-Measurement ($contract.landmarks.Count -eq 16) 'Exactly sixteen measurements required'
foreach ($entry in $contract.landmarks) {
    Assert-Measurement (-not $seen.ContainsKey($entry.id)) ('Duplicate doorway ' + $entry.id)
    $seen[$entry.id] = $true
    $reviewBinding = @($sourceReview.source_bindings | Where-Object id -eq $entry.id)
    Assert-Measurement ($reviewBinding.Count -eq 1 -and $reviewBinding[0].source -eq $entry.source -and $reviewBinding[0].source_sha256 -eq $entry.source_sha256) ('Root reviewed source binding changed ' + $entry.id)
    Assert-Measurement ($entry.status -eq 'SYSTEM_ACTUAL_RGBA_THRESHOLD_MEASURED_REQUIRES_ROOT_REVIEW' -and $entry.doorstep_visual_review_status -eq 'PENDING_ROOT_REVIEW' -and -not $entry.runtime_eligible) ('Cannot self-approve ' + $entry.id)
    Assert-Measurement ($entry.world_navigation_full17_status -eq 'NOT_RUN' -and $entry.normal_space_and_mouse_status -eq 'NOT_RUN' -and $null -eq $entry.interaction_polygon_px -and $null -eq $entry.solid_polygons_px) ('Cannot invent world passage evidence ' + $entry.id)
    $sourcePath = Resolve-Resource $entry.source
    Assert-Measurement ((Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash -eq $entry.source_sha256) ('Changed RGBA source ' + $entry.id)
    $copyPath = Resolve-Resource $entry.runtime_texture
    Assert-Measurement ((Get-FileHash -LiteralPath $copyPath -Algorithm SHA256).Hash -eq $entry.source_sha256) ('Runtime original-alpha copy differs ' + $entry.id)
    $bitmap = [Drawing.Bitmap]::new($sourcePath)
    try {
        Assert-Pair @($bitmap.Width, $bitmap.Height) $entry.source_size_px ('Actual source size ' + $entry.id)
        $scale = [double]$entry.render_size_px[0] / $bitmap.Width
        Assert-Measurement ($scale -gt 0) ('Nonpositive thumbnail scale ' + $entry.id)
        Assert-Pair $entry.render_size_px @(($bitmap.Width * $scale), ($bitmap.Height * $scale)) ('Uniform source aspect ' + $entry.id)
        $uv = @(([double]$entry.source_doorstep_px[0] / $bitmap.Width), ([double]$entry.source_doorstep_px[1] / $bitmap.Height))
        Assert-Pair $entry.source_doorstep_uv $uv ('Actual source doorstep UV ' + $entry.id)
        Assert-Measurement ($entry.source_full17_alpha_samples.Count -eq 17) ('Full seventeen source samples ' + $entry.id)
        $minimum = 255
        for ($index = 0; $index -lt 17; $index++) {
            $offsetX = 0.0; $offsetY = 0.0
            if ($index -gt 0) {
                $angle = 2 * [math]::PI * ($index - 1) / 16
                $offsetX = 10 * [math]::Cos($angle) / $scale
                $offsetY = 6 * [math]::Sin($angle) / $scale
            }
            $x = [int][math]::Round($entry.source_doorstep_px[0] + $offsetX, 0, [MidpointRounding]::AwayFromZero)
            $y = [int][math]::Round($entry.source_doorstep_px[1] + $offsetY, 0, [MidpointRounding]::AwayFromZero)
            Assert-Measurement ($x -ge 0 -and $y -ge 0 -and $x -lt $bitmap.Width -and $y -lt $bitmap.Height) ('Shoe leaves original source ' + $entry.id)
            $record = $entry.source_full17_alpha_samples[$index]
            Assert-Pair $record.pixel @($x, $y) ('Inverse-scale shoe pixel ' + $entry.id)
            $alpha = [int]$bitmap.GetPixel($x, $y).A
            Assert-Measurement ($alpha -eq $record.alpha_byte -and $alpha -ge 128) ('Recorded source alpha changed ' + $entry.id)
            $minimum = [math]::Min($minimum, $alpha)
        }
        Assert-Measurement ($minimum -eq $entry.source_full17_min_alpha) ('Recorded alpha minimum ' + $entry.id)
        $click = $entry.source_click_px
        Assert-Measurement ($click.Count -eq 2 -and $click[0] -ge 0 -and $click[1] -ge 0 -and $click[0] -lt $bitmap.Width -and $click[1] -lt $bitmap.Height) ('Click outside actual source ' + $entry.id)
        Assert-Measurement ([int]$bitmap.GetPixel($click[0], $click[1]).A -eq $entry.source_click_alpha_byte -and $entry.source_click_alpha_byte -ge 128) ('Actual click source alpha ' + $entry.id)
        $anchor = @($forecast.anchors | Where-Object id -eq $entry.id)
        Assert-Measurement ($anchor.Count -eq 1 -and $anchor[0].target_scene -eq $entry.target_scene) ('Frozen forecast identity ' + $entry.id)
        Assert-Pair $entry.planned_source_XZ_foot_px $anchor[0].source_XZ_foot_px ('Frozen source XZ ' + $entry.id)
        Assert-Pair $entry.planned_world_door_foot_px $anchor[0].projected_door_foot_px ('Frozen projected forecast ' + $entry.id)
        Assert-Measurement ([math]::Abs([double]$entry.forecast_height_m - [double]$anchor[0].height_m) -lt 0.000001) ('Frozen height ' + $entry.id)
        # Forecast points contain native float32 projection rounding; no new
        # terrain sampling or regenerated coordinates are introduced here.
        $world = $entry.planned_world_door_foot_px
        $center = @(([double]$world[0] - (($uv[0] - .5) * $entry.render_size_px[0])), ([double]$world[1] - (($uv[1] - .5) * $entry.render_size_px[1])))
        Assert-Pair $entry.planned_sprite_center_px $center ('Centered original-alpha transform ' + $entry.id)
        $worldClick = @(($center[0] + (($click[0] / $bitmap.Width - .5) * $entry.render_size_px[0])), ($center[1] + (($click[1] / $bitmap.Height - .5) * $entry.render_size_px[1])))
        Assert-Pair $entry.planned_world_click_px $worldClick ('Same-sprite click transform ' + $entry.id)
        Assert-Pair $entry.planned_portal_pos @(($world[0] / 12288), ($world[1] / 8192)) ('Shared planned return/Space anchor ' + $entry.id)
        Write-Output ('RGBA_MEASUREMENT {0} foot={1},{2} minA={3} inverse_source_radius={4:N4},{5:N4} root_source_direction=PASS runtime_doorstep_review=PENDING nav=NOT_RUN input=NOT_RUN' -f $entry.id, $entry.source_doorstep_px[0], $entry.source_doorstep_px[1], $minimum, (10 / $scale), (6 / $scale))
    } finally { $bitmap.Dispose() }
}
Write-Output ('V15_PORTAL_MEASUREMENT_INTEGRITY checks={0} doors=16 production_approved=false runtime_eligible=false NO_GODOT_NO_NAVIGATION_CLAIM' -f $checks)
