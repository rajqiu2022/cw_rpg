$ErrorActionPreference = 'Stop'
$taskRoot = 'F:\Code\RPG_GAME'
$sourcePath = Join-Path $taskRoot 'game\build\joint_v9d_two_world_six_regional_ROOT_retry_footprint_authorization_20261004.json'
$outputPath = Join-Path $taskRoot 'game\build\joint_v9e_ROOT248_regional_authorization_20261005.json'
if (Test-Path -LiteralPath $outputPath) { throw 'Do not overwrite an execution authorization' }
$taskAuth = Get-Content -LiteralPath $sourcePath -Raw | ConvertFrom-Json
$newPins = [ordered]@{
 'res://scripts/dev/build_world_map_v15_coherent_whole_v9e_full_proposal.gd' = 'dcda6d3227cad5fd646b6fa3390cae5c4f71354fec1adf15552a12188a8d0121'
 'res://scripts/dev/build_world_map_v15_coherent_whole_v9e_regional_proposal.gd' = 'f00e83e40d3c24f1d48ecee959ddbc02bd5791c924af01a897f5a7667dcf9d0f'
 'res://scripts/dev/world_map_v15_v9e_material_refinement_surface.gd' = '3cb4f995cc800482fe859f0424a4839b70097721ec5f11f21e53a7d6ca3253b1'
}
foreach ($entry in $newPins.GetEnumerator()) {
 $taskAuth.input_sha256 | Add-Member -NotePropertyName $entry.Key -NotePropertyValue $entry.Value
}
$count = 0
foreach ($entry in $taskAuth.input_sha256.PSObject.Properties) {
 if (-not $entry.Name.StartsWith('res://') -or $entry.Name.Contains('..')) { throw ('Invalid input ' + $entry.Name) }
 $diskPath = Join-Path $taskRoot ('game\' + $entry.Name.Substring(6).Replace('/', '\'))
 if ((Get-FileHash -LiteralPath $diskPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $entry.Value) { throw ('Actual input SHA differs: ' + $entry.Name) }
 $count++
}
$taskAuth.builder_path = 'res://scripts/dev/build_world_map_v15_coherent_whole_v9e_regional_proposal.gd'
$taskAuth.builder_sha256 = $newPins[$taskAuth.builder_path]
$taskAuth.template_status = 'ROOT_CURRENT_V9E_SOURCE_REVIEW_APPROVED_REGIONAL_EXECUTION_ONLY_NOT_FULL'
$taskAuth.root_current_review = [ordered]@{
 source_review = 'ROOT read both NEW V9E executors completely plus current-run hash dedup delta; all registered assets terminally rehashed, inherited input before-after guards retained. ROOT246 interrupted own process due repeated PBR hashing: actual OS-1, no result/credit. Whole-camera/RF640/18samplers/2687/all-role-two-draw/sixROI/CPU8404992 invariants unchanged.'
 limited_GPU_review = 'ROOT244 eight actual small-camera old/new original ROIs reviewed by ROOT and independent art. Snow neutral gray-white, damp soil brown/blue, calm water. Small-camera ROIs are not whole-camera authority, not FULL or Field credit.'
 actual_limited_report = @{path='res://build/joint_world_luoyang_20261003_qa/v9e_material_preview_1791134913_2418663/result.json';sha256='df18e5b582dbfa5ec9b2602acf78e5bff78b6d1659042a3eb4cc6ba6435df6dd'}
 allow_FULL64 = $false
 allow_formal = $false
 material_revision = 'V9E_SNOW_EXPOSURE_DAMP_FILM_DEPTH_WATER_VISUAL_EXPERIMENT'
 known_visual_limits = 'Axial snow platforms, stepped river banks and mostly even river width remain. This execution is not publication approval.'
}
$taskAuth.instructions = 'Execute ONLY six regional ROIs on two fresh whole-camera worlds with current V9E shader; no old regional/visual/FULL/Field credit. Retain all actual logs and failures. Do not publish or alter formal targets.'
[System.IO.File]::WriteAllText($outputPath, ($taskAuth | ConvertTo-Json -Depth 50), [System.Text.UTF8Encoding]::new($false))
[ordered]@{path=$outputPath;sha256=(Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash;actual_checked_inputs=$count;scope=$taskAuth.scope;allow_full=$false;allow_formal=$false} | ConvertTo-Json
