$ErrorActionPreference = 'Stop'
$taskRoot = 'F:\Code\RPG_GAME'
$outputPath = Join-Path $taskRoot 'game\build\joint_v9e_ROOT250_full_authorization_20261007.json'
if (Test-Path -LiteralPath $outputPath) { throw 'Execution authorization already exists' }
$taskAuth = Get-Content -LiteralPath (Join-Path $taskRoot 'game\build\joint_v9d_ROOT229_reviewed_FULL_candidate_authorization_20261004.json') -Raw | ConvertFrom-Json
$regionalAuth = Get-Content -LiteralPath (Join-Path $taskRoot 'game\build\joint_v9e_ROOT248_regional_authorization_20261005.json') -Raw | ConvertFrom-Json
$regionalPath = 'res://build/world_map_v15_coherent_whole_v9c_regional/v9d_broad_soft/1791137714_2690526/result.json'
$regionalDisk = Join-Path $taskRoot ('game\' + $regionalPath.Substring(6).Replace('/', '\'))
$regionalSHA = 'fe50ec4312753bd62eee0e4c62a1944dfb29859e6f339e04282dc05864f960d0'
if ((Get-FileHash -LiteralPath $regionalDisk -Algorithm SHA256).Hash.ToLowerInvariant() -ne $regionalSHA) { throw 'Reviewed regional bytes changed' }
$regional = Get-Content -LiteralPath $regionalDisk -Raw | ConvertFrom-Json
$after = Get-Content -LiteralPath (Join-Path $taskRoot 'game\build\joint_world_luoyang_20261003_qa\248_v9e_dedup_two_fresh_whole_six_regional_GPU\after.json') -Raw | ConvertFrom-Json
if ($after.actual_os_exit -ne 0 -or $after.source_changes.Count -ne 0 -or $after.player_file_changes.Count -ne 0) { throw 'Regional execution not clean' }
if ($regional.status -ne 'V9C_REGIONAL_TWO_WORLD_FIVE_ROLE_REPEAT_TECHNICAL_PASS_REQUIRES_ROOT_VISUAL_NOT_FULL' -or $regional.input_hashes_unchanged_after -ne $true -or $regional.alpha_union.passed -ne $true) { throw 'Regional evidence failed' }
$taskAuth.input_sha256 = $regionalAuth.input_sha256
$taskAuth.input_sha256 | Add-Member -NotePropertyName $regionalPath -NotePropertyValue $regionalSHA
$count = 0
foreach ($entry in $taskAuth.input_sha256.PSObject.Properties) {
 if (-not $entry.Name.StartsWith('res://') -or $entry.Name.Contains('..')) { throw ('Invalid input '+$entry.Name) }
 $diskPath = Join-Path $taskRoot ('game\'+$entry.Name.Substring(6).Replace('/', '\'))
 if ((Get-FileHash -LiteralPath $diskPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $entry.Value) { throw ('Input changed: '+$entry.Name) }
 $count++
}
$taskAuth.builder_path = 'res://scripts/dev/build_world_map_v15_coherent_whole_v9e_full_proposal.gd'
$taskAuth.builder_sha256 = 'dcda6d3227cad5fd646b6fa3390cae5c4f71354fec1adf15552a12188a8d0121'
$taskAuth.template_status = 'ROOT_CURRENT_V9E_FULL_CANDIDATE_CAPTURE_ONLY'
$taskAuth.regional_visual_review = [ordered]@{
 approved=$true; approved_by='root'; scope=$regional.scope
 result_path=$regionalPath; result_sha256=$regionalSHA
 candidate_full_builder=@{path=$taskAuth.builder_path;sha256=$taskAuth.builder_sha256}
 root_review_notes='ROOT actually viewed all six current primary ground PNGs and six component composites on 2026-10-07. Actual regional OS0, no ERROR/SCRIPT/SHADER errors, source and fifteen player paths unchanged. Field textures distinguish cultivated rows, green meadow, pale mineral soil, dark damp mud, neutral snow and calm rivers. Meadow remains sparse, snow platforms and 8px bank steps remain visible; wet areas are soil film rather than real water pools. These limits require final whole-map/Field review. This review authorizes current full candidate export only, not formal adoption.'
}
$taskAuth.instructions = 'Capture the current V9E candidate with original coordinate15, approved RF640, 2687 bodies, all18 sampler bindings, two fresh worlds/five roles/two draws,64 chunks and112 independent seams. Keep all current source hashes, raw outputs and logs. No publication or formal writes.'
$taskAuth | Add-Member -NotePropertyName material_revision_identity -NotePropertyValue 'V9E_SNOW_EXPOSURE_DAMP_FILM_DEPTH_WATER_VISUAL_EXPERIMENT'
[System.IO.File]::WriteAllText($outputPath, ($taskAuth | ConvertTo-Json -Depth 50), [System.Text.UTF8Encoding]::new($false))
[ordered]@{path=$outputPath;sha256=(Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash;actual_checked_inputs=$count;scope=$taskAuth.scope;allow_full=$taskAuth.allow_full64;allow_formal=$false} | ConvertTo-Json
