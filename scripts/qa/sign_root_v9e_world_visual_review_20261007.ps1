# Explicit producer signature after ROOT actually reviewed the current images.
# Not a renderer, Field test, technical release approval, or production cutover.
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$DraftPath,[Parameter(Mandatory=$true)][string]$DraftSha256,[switch]$ConfirmRootReviewedCurrentImages)
$ErrorActionPreference='Stop'
if (!$ConfirmRootReviewedCurrentImages) { throw 'Explicit ROOT image-review confirmation is required' }
$taskRoot=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$gameRoot=Join-Path $taskRoot 'game'
function ActualHash([string]$path) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() }
function ResolveResource([string]$path) {
  if (!$path.StartsWith('res://') -or $path.Contains('..') -or $path.Contains('\')) { throw "Invalid resource: $path" }
  $resolved=[IO.Path]::GetFullPath((Join-Path $gameRoot $path.Substring(6)))
  if (!$resolved.StartsWith($gameRoot+[IO.Path]::DirectorySeparatorChar)) { throw 'Escaping resource' }
  $resolved
}
$draftFile=(Resolve-Path -LiteralPath $DraftPath).Path
if (!(ActualHash $draftFile).Equals($DraftSha256,[StringComparison]::OrdinalIgnoreCase)) { throw 'ROOT-selected draft changed' }
$review=Get-Content -LiteralPath $draftFile -Raw | ConvertFrom-Json -AsHashtable -Depth 100
if ($review.status -ne 'DRAFT' -or $review.visual_approved -ne $false -or $review.unsafe_legal_stands.Count -ne 0 -or $review.doors.Count -ne 16 -or $review.negative_count -ne 48 -or $review.all_bound_image_path_count -ne 2777 -or $review.representative_visual_review_unit_count -ne 134) { throw 'Draft not complete/safe/pending' }
foreach ($attention in $review.root_attention) {
  if ($attention.portal_id -ne 'lieyun_valley' -or $attention.issue -ne 'roof_click semantic object is high rock face, not a literal roof') { throw 'Unexpected unresolved root attention' }
}
$required=@{
  'res://data/maps/world_map_v15_complete_v9c_source.json'='85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f'
  'res://art/maps/world_map_v15_complete_v9c/art_contract.json'='1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a'
  'res://art/maps/world_map_v15_complete_v9c/whole_actual_capture.json'='cdd74b329cf84eb24ccd136a5f26afd515795ea612508d197263db31fdcfb851'
}
foreach ($entry in $required.GetEnumerator()) { if ((ActualHash (ResolveResource $entry.Key)) -ne $entry.Value) { throw "Actual final artifact changed: $($entry.Key)" } }
if ($review.source_sha256 -ne $required['res://data/maps/world_map_v15_complete_v9c_source.json'] -or $review.manifest_sha256 -ne $required['res://art/maps/world_map_v15_complete_v9c/art_contract.json'] -or $review.whole_capture_report_sha256 -ne $required['res://art/maps/world_map_v15_complete_v9c/whole_actual_capture.json']) { throw 'Draft final bindings differ' }
foreach ($entry in $review.preparation.current_hashed_inputs_sha256.GetEnumerator()) { if ((ActualHash (ResolveResource $entry.Key)) -ne $entry.Value) { throw "Reviewed input changed: $($entry.Key)" } }
$witnessIndexPath=Join-Path $gameRoot 'build/joint_v9e_world_visual_review_draft_20261007T053338800126Z_6939719d/door_source_witnesses_index.json'
if ((ActualHash $witnessIndexPath) -ne '6f8c8112595fed7d13ed0383ddc3a99a46e453f1dc2d747075cc2376d695ea48') { throw 'Actually viewed witness contact index changed' }
$witnessIndex=Get-Content -Raw -LiteralPath $witnessIndexPath | ConvertFrom-Json -AsHashtable -Depth 30
if ($witnessIndex.pages.Count -ne 4) { throw 'Missing actually viewed witness pages' }
foreach ($page in $witnessIndex.pages) { if ((ActualHash $page.path) -ne $page.sha256) { throw 'Actually viewed witness contact page changed' } }
$witnessRows=$witnessIndex.originals
if ($witnessRows.Count -ne 16) { throw 'Expected16 original-source witness bindings' }
$seenWitness=@{}
foreach ($row in $witnessRows) {
  if ($seenWitness.ContainsKey($row.id) -or !$review.doors.ContainsKey($row.id)) { throw 'Duplicate/unknown source witness' }
  $seenWitness[$row.id]=$true
  $door=$review.doors[$row.id]
  if ($row.source -ne $door.source -or $row.source_sha256 -ne $door.source_sha256 -or (ActualHash (ResolveResource $row.source)) -ne $row.source_sha256) { throw 'Reviewed original source changed' }
  $wall=@($door.input_negative_probes | Where-Object kind -eq 'wall_approach')[0]
  $roof=@($door.input_negative_probes | Where-Object kind -eq 'roof_click')[0]
  if (($row.wall_source_witness_px|ConvertTo-Json -Compress) -ne ($wall.source_witness_px|ConvertTo-Json -Compress) -or ($row.roof_or_highface_source_witness_px|ConvertTo-Json -Compress) -ne ($roof.source_witness_px|ConvertTo-Json -Compress)) { throw 'Reviewed witness coordinate changed' }
}
$groundIndexPath=Join-Path $gameRoot 'build/joint_world_luoyang_20261003_qa/root260_current_v9e_primary_ground64_review/index.json'
$groundIndex=Get-Content -Raw -LiteralPath $groundIndexPath | ConvertFrom-Json -AsHashtable -Depth 30
if ($groundIndex.images.Count -ne 64) { throw 'Ground visual aid is not all64' }
$seenGround=@{}
foreach ($row in $groundIndex.images) {
  $name=[IO.Path]::GetFileName($row.path)
  if ($name -notmatch '^visual_(r\d_c\d)_pass0\.png$') { throw 'Unrecognized reviewed ground' }
  $key=$Matches[1]
  if ($key -notmatch '^r[0-7]_c[0-7]$' -or $seenGround.ContainsKey($key)) { throw 'Ground tile missing/duplicate/outside exact8x8' }
  $seenGround[$key]=$true
  $finalPath='res://art/maps/world_map_v15_complete_v9c/chunks/'+$key+'_visual.png'
  if ((ActualHash $row.path) -ne $row.sha256 -or (ActualHash (ResolveResource $finalPath)) -ne $row.sha256 -or $review.reviewed_assets_sha256[$finalPath] -ne $row.sha256) { throw 'Final ground does not match actually reviewed primary capture' }
}
foreach ($door in $review.doors.Values) {
  if ($door.negative_origin -ne 'INDEPENDENT_ROOT_REVIEW_AUTHORED_NEGATIVES_V1') { throw 'Unexpected captured negative origin' }
  if ($door.input_negative_probes.Count -ne 3) { throw 'Missing negative' }
  foreach ($probe in $door.input_negative_probes) {
    if ($probe.current_CPU_diagnostic.stand.clear -ne $true) { throw 'Unsafe negative actor start' }
    $probe.semantic_review_status='APPROVED'
  }
  $door.status='APPROVED'
}
if ($review.default_spawn.current_CPU_diagnostic.clear -ne $true -or $review.default_spawn.policy -ne 'EXACT_REVIEWED_LINXI_DOOR_V1') { throw 'Unreviewed default spawn' }
$review.default_spawn.approved=$true
$review.default_spawn.status='APPROVED'
$review.status='APPROVED_FOR_CANDIDATE_VISUAL_INTEGRATION_WITH_RECORDED_LIMITS'
$review.visual_approved=$true
$review.production_approved=$false
$review.reviewer='ROOT producer 2026-10-07 current E capture review'
$review.review_method='actual_png_individual_review'
$review.review_execution_status='ROOT_CURRENT_IMAGES_REVIEWED_NOT_FIELD_OR_TECHNICAL_APPROVAL'
foreach ($path in @($review.reviewed_image_status.Keys)) {
  $review.reviewed_image_status[$path]=if ($review.texture_representative_to_aliases.ContainsKey($path)) { 'ROOT_CURRENT_PNG_SHA_CLASS_REPRESENTATIVE_REVIEWED' } elseif ($path -in $review.required_image_groups.textures) { 'EXACT_CURRENT_SHA_ALIAS_OF_ROOT_REVIEWED_PNG_NOT_PLACEMENT_APPROVAL' } else { 'ROOT_CURRENT_CAPTURE_IMAGE_REVIEWED' }
}
$review.ROOT262_texture_review_aid.status='ROOT_CONFIRMED_CURRENT_44_CLASSES_2687_EXACT_BYTE_ALIASES_NOT_OBJECT_PLACEMENT_APPROVAL'
$review.root_signature=[ordered]@{
  signed_utc=[datetime]::UtcNow.ToString('o')
  draft_path=$draftFile
  draft_sha256=(ActualHash $draftFile)
  signing_script_sha256=(ActualHash $PSCommandPath)
  original_witness_review_index_path=$witnessIndexPath
  original_witness_review_index_sha256=(ActualHash $witnessIndexPath)
  actual_review_details=@('All64 primary ground captures viewed across6 contact pages; final64 byte-exact mapping checked at signature.','44 current unique entity PNG classes viewed across4 contact pages; all2687 aliases are exact content hashes, not2687 separately viewed images.','Final overview,9 Source ecology composites and16 final doorway PNGs actually viewed; southern-bamboo auxiliary image excluded from final nine count.','All16 original compound wall and roof/high-face witness contact images reviewed; independent48 intentions remain subject to actual Field negative tests.')
  known_visual_limits=@('Sparse repetitive grass and simple transitional patches remain.','Snow support terraces and8px stepped shore geometry remain visible.','Marsh uses damp mud and herbs, not true standing water pools.','Modular streets retain broad paving and simplified wall segments; not a claim of AAA final art.')
  root_semantic_decision='Lieyun roof_click is an actual visible high rock face, not a literal building roof; Bailu solid witness is the shore post/base. Both remain solid-world interaction negative tests.'
  field_input_approval=$false
  production_cutover_approval=$false
}
$output=Join-Path $gameRoot 'data/maps/world_map_v15_complete_v9c_visual_review.json'
if (Test-Path -LiteralPath $output) { throw 'Existing review must not be overwritten by this signature helper' }
[IO.File]::WriteAllText($output,($review|ConvertTo-Json -Depth 100),[Text.UTF8Encoding]::new($false))
[pscustomobject]@{path=$output;sha256=(ActualHash $output);scope=$review.scope;visual_approved=$true;field_approved=$false;production_approved=$false}|ConvertTo-Json
