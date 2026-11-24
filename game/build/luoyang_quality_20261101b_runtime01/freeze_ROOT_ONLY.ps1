param(
    [switch]$IncludeDecor,
    [switch]$ReplaceCandidateFreeze
)
$ErrorActionPreference = 'Stop'
$qualityGameRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$qualityOutput = Join-Path $PSScriptRoot 'source_pins_READY.json'
function Local([string]$path) {
    if (-not $path.StartsWith('res://') -or $path.Contains('..')) { throw "Invalid resource path: $path" }
    $absolute = [IO.Path]::GetFullPath((Join-Path $qualityGameRoot $path.Substring(6)))
    if (-not $absolute.StartsWith($qualityGameRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Path outside game' }
    return $absolute
}
function Sha([string]$path) { return (Get-FileHash -LiteralPath (Local $path) -Algorithm SHA256).Hash.ToLowerInvariant() }
function Require-Pin([string]$path, [string]$expected) {
    if ((Sha $path) -ne $expected) { throw "Exact current source refused: $path" }
}
$qualityField = 'res://build/luoyang_regions_20261027d_source01/region_field.gd'
$qualityManifest = 'res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json'
Require-Pin $qualityField 'fdb375d92f1590be44288708bc697f2cb780e81584557027c5396508f73de5e5'
Require-Pin $qualityManifest 'af1bb975b0603e2d735890ff89fa60c8e2100ccb0a7565fc1211ca1794d866be'
$qualityProject = [IO.File]::ReadAllText((Local 'res://project.godot'))
$qualityAutoload = 'SceneArtQualityRuntime="*res://build/luoyang_quality_20261101b_runtime01/scene_art_quality_runtime.gd"'
if (($qualityProject -split "`r?`n" | Where-Object { $_ -eq $qualityAutoload }).Count -ne 1) { throw 'Root must add exactly one intended autoload line before freezing.' }
$qualityRequiredBins = [ordered]@{
    luoyang_estate_region_27d = '26918ba3c0198f1dcf74dcacf41c24ff2a0eeaf4b7c58964f45db4ea089daf8c'
    luoyang_civic_market_region_27d = 'e197c636d7a0ff5c151dfc83834dd40f7ab3613b7d6347b591442666ad7be130'
    luoyang_temple_region_27d = '70b37efd015a4b3f297036aabc20fae9ed4c1c9db7641e4417ed32f7cf2f4948'
    yihongyuan27n_interior = '4871b3e428bedd5c0c4c06882d5ebe36cc1660824100adb648027f82dec31d65'
}
$qualityCurrent = Get-Content -Raw -LiteralPath (Local $qualityManifest) | ConvertFrom-Json
$qualityBindings = [ordered]@{}
$qualityPaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
@(
    'res://project.godot',
    'res://build/luoyang_quality_20261101b_runtime01/scene_art_quality_runtime.gd',
    'res://build/luoyang_quality_20261101b_runtime01/freeze_ROOT_ONLY.ps1',
    'res://build/luoyang_quality_20261101b_runtime01/capture_before_ROOT_ONLY.ps1',
    'res://build/luoyang_quality_20261101b_runtime01/final_guard_ROOT_ONLY.ps1',
    'res://build/luoyang_quality_20261101b_runtime01/guard_facts_ROOT_ONLY.ps1',
    'res://build/luoyang_quality_20261101b_runtime01/qa_finite_ROOT_ONLY.gd',
    'res://build/luoyang_quality_20261101b_ground01/ground_visual.gd',
    'res://build/luoyang_quality_20261101b_ground01/curb_transition.gdshader',
    'res://build/luoyang_quality_20261101b_runtime01/qa_ground_residual03_ROOT_ONLY.gd',
    'res://build/luoyang_quality_20261101b_runtime01/qa_ground_residual04_ROOT_ONLY.gd',
    'res://build/luoyang_quality_20261101b_seated01/live_seated_view.gd',
    'res://build/luoyang_quality_20261101b_seated01/elder_front_pose.tres',
    'res://build/luoyang_quality_20261101b_seated01/woman_front_pose.tres',
    'res://scripts/field/npc_node.gd', 'res://scenes/npc_node.tscn',
    $qualityField, $qualityManifest,
    'res://build/luoyang_regions_20261027d_source01/region_session.gd',
    'res://build/luoyang_regions_20261027d_source01/region_compiler.gd',
    'res://build/luoyang_regions_20261027d_source01/router_region_dispatch.gd',
    'res://build/luoyang_garden_city_minimap_20261030b_system01/garden_visual.gd',
    'res://build/luoyang_garden_city_minimap_20261030b_system01/visual_paths.json',
    'res://build/luoyang_garden_city_minimap_20261030b_system01/city_minimap.gd',
    'res://build/luoyang_city_visual_minimap_20261030c_system01/visual_cache.gd',
    'res://build/city_visual_diversity_20261031c/district_visuals.gd',
    'res://build/city_visual_diversity_20261031c/district_patches.json'
) | ForEach-Object { [void]$qualityPaths.Add($_) }
foreach ($id in $qualityRequiredBins.Keys) {
    $binding = $qualityCurrent.compiled_bindings.$id
    if ($binding.sha256 -ne $qualityRequiredBins[$id]) { throw "Current binding refused: $id" }
    Require-Pin $binding.path $qualityRequiredBins[$id]
    $qualityBindings[$id] = [ordered]@{ path = $binding.path; sha256 = $binding.sha256; bytes = $binding.bytes }
}
# Freeze all ten actual bins for independent no-change checks, not republishing.
foreach ($property in $qualityCurrent.compiled_bindings.PSObject.Properties) { [void]$qualityPaths.Add($property.Value.path) }
$qualityTextures = [Collections.Generic.List[string]]::new()
$qualityTextures.Add('res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png')
$qualityTextures.Add('res://art/modules/miao_town_20261029f/ground.png')
$qualityTextures.Add('res://art/characters/npc_inn_tea_guest_left_seated_idle_down_25d_4f_v2_runtime.png')
$qualityTextures.Add('res://art/characters/npc_inn_tea_guest_right_seated_idle_down_25d_4f_v2_runtime.png')
if ($IncludeDecor) {
    $qualityDecorBinding = 'res://build/luoyang_quality_20261101b_decor01/decor_binding.json'
    $qualityDecor = Get-Content -Raw -LiteralPath (Local $qualityDecorBinding) | ConvertFrom-Json
    if ($qualityDecor.schema -ne 'YIHONG_WALL_VIEW_V1' -or $qualityDecor.sealed_by_root_after_media_import -ne $true) { throw 'Decor binding is not Root-sealed after actual media import.' }
    if ($qualityDecor.media.path -ne 'res://art/modules/luoyang_quality_20261101b/salon_wall_v1.png' -or @($qualityDecor.media.source_sha256.PSObject.Properties).Count -ne 3) { throw 'Root-approved wall requires its complete exact three-media binding.' }
    [void]$qualityPaths.Add('res://build/luoyang_quality_20261101b_decor01/live_decor_view.gd')
    [void]$qualityPaths.Add($qualityDecorBinding)
    foreach ($property in $qualityDecor.media.source_sha256.PSObject.Properties) { Require-Pin $property.Name $property.Value; [void]$qualityPaths.Add($property.Name) }
    if ($qualityDecor.floor_rug.enabled -ne $true -or $qualityDecor.floor_rug.media.path -ne 'res://art/modules/luoyang_quality_20261101b/salon_rug_v1.png' -or @($qualityDecor.floor_rug.media.source_sha256.PSObject.Properties).Count -ne 3) { throw 'Root-approved rug requires its complete exact three-media binding.' }
    foreach ($property in $qualityDecor.floor_rug.media.source_sha256.PSObject.Properties) { Require-Pin $property.Name $property.Value; [void]$qualityPaths.Add($property.Name) }
    $qualityTextures.Add('res://art/modules/luoyang_quality_20261101b/salon_wall_v1.png')
    $qualityTextures.Add('res://art/modules/luoyang_quality_20261101b/salon_rug_v1.png')
    $qualityTextures.Add('res://art/modules/luoyang_assembled_interiors_20261016g/shell_inn_hall_v1.png')
}
foreach ($texture in $qualityTextures) {
    [void]$qualityPaths.Add($texture); [void]$qualityPaths.Add($texture + '.import')
    $importText = [IO.File]::ReadAllText((Local ($texture + '.import')))
    $match = [regex]::Match($importText, '(?m)^path="(res://\.godot/imported/[^"\r\n]+\.ctex)"\r?$')
    if (-not $match.Success) { throw "Actual imported GPU path missing: $texture" }
    [void]$qualityPaths.Add($match.Groups[1].Value)
}
$qualityPins = [ordered]@{}
foreach ($path in ($qualityPaths | Sort-Object)) { $qualityPins[$path] = Sha $path }
$qualityDocument = [ordered]@{
    schema = 'SCENE_ART_QUALITY_20261101B_INDEPENDENT_V1'; ready = $true
    ground_helper = 'res://build/luoyang_quality_20261101b_ground01/ground_visual.gd'
    seated_helper = 'res://build/luoyang_quality_20261101b_seated01/live_seated_view.gd'
    decor_helper = 'res://build/luoyang_quality_20261101b_decor01/live_decor_view.gd'
    decor_enabled = [bool]$IncludeDecor; region_bindings = $qualityBindings; source_pins = $qualityPins
    policy = 'Independent view source FIRST/FINAL only; original Region lease and ten bins are unchanged. No inherited ART/Field PASS.'
}
if (Test-Path -LiteralPath $qualityOutput) {
    if (-not $ReplaceCandidateFreeze) { throw 'Existing freeze preserved. Use explicit -ReplaceCandidateFreeze only after reviewing new candidate changes.' }
    $qualityOldHash = (Get-FileHash -LiteralPath $qualityOutput -Algorithm SHA256).Hash.ToLowerInvariant()
    $qualityArchive = Join-Path $PSScriptRoot ('source_pins_BEFORE_' + $qualityOldHash + '.json')
    if (-not (Test-Path -LiteralPath $qualityArchive)) { [IO.File]::WriteAllBytes($qualityArchive, [IO.File]::ReadAllBytes($qualityOutput)) }
}
$qualityJson = ($qualityDocument | ConvertTo-Json -Depth 30) -replace "`r`n", "`n"
[IO.File]::WriteAllText($qualityOutput, $qualityJson.TrimEnd() + "`n", [Text.UTF8Encoding]::new($false))
Get-Item -LiteralPath $qualityOutput | Select-Object FullName, Length
Get-FileHash -LiteralPath $qualityOutput -Algorithm SHA256
