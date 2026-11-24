# Mechanical producer-evidence preparation ONLY. Never approves or activates.
# Do not run until the producer has reviewed every raw GPU screenshot.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RunEvidence,
    [Parameter(Mandatory)][string]$ReviewedImageIndex,
    [Parameter(Mandatory)][string]$AuthorizationDocument,
    [Parameter(Mandatory)][string]$AuthorizationSha256,
    [Parameter(Mandatory)][string]$QaOutput,
    [Parameter(Mandatory)][string]$VisualOutput
)

# Input schema 1 (canonical res:// / repo:// keys, no absolute paths):
# RunEvidence: {schema_version:1,scope:"FULL",capture_iteration:9,
#   runs:{headless,gpu}}. Each run is a producer-recorded finished process:
#   {scope:"FULL",completed:true,exit_code:0,checks:<actual>,failures:0,
#    script_path,script_sha256,actual_sources:{exact seven fixed keys:SHA},
#    log_path,log_sha256,stderr_path,stderr_sha256,result_path,result_sha256}.
# ReviewedImageIndex: {schema_version:1,scope:"FULL",capture_iteration:9,
#   producer_review_complete:true,reviewer:<named actual producer>,verdict:"PASS",
#   visual_approved:true,production_approved:true,unresolved_findings:[],
#   authorization:{path:<AuthorizationDocument>,sha256:<AuthorizationSha256>},
#   images:{EVERY raw GPU PNG key:{sha256,verdict:"PASS",regions:[],
#     portal_ids:[],categories:[]}}}. Aggregate annotations must cover exact
#   9 regions, 16 portal IDs and 8 actual FULL-picture categories.
#   supplemental_category_reviews:{same_band_npc:{path,sha256,...}} binds a
#   separate root-reviewed attachment: schema_version1/capture_iteration9,
#   scope SUPPLEMENTAL_NPC_VISUAL_REVIEW/producer_review_complete true/
#   named same reviewer/PASS; FULL normal_patrol_same_band.json path/SHA and
#   full_read true, separate actual case JSON path/SHA/full_read true, distinct
#   raw front/behind PNG path/SHA/PASS/case ID with actual finite same-band
#   footlines/current-frame positive alpha/full-foot/physics/order evidence.
#   This is never added to the FULL PNG set or attributed to a region image.
#   The ninth category is credited ONLY after this independent attachment gate.
#   No generated verdict template.
# AuthorizationDocument must be an existing repo://docs/*.md file whose SHA
# the producer supplied; this tool neither creates nor interprets authorization.
# Output paths must be distinct NEW res://build/world_map_v14_qa/.../*.json.
# Output schema matches approve_world_v14_production.ps1; preparation is NOT
# acceptance. The producer still independently invokes the approval gate later.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..')).TrimEnd('\','/')
$gameRoot = Join-Path $repoRoot 'game'
$approvalTool = 'repo://scripts/approve_world_v14_production.ps1'
$approvalToolSha = 'a5ded9983986a509e4e53fcdaf657e5d6c9583f6a701fa8f5e825fc1766ecf1e'
$fullTest = 'res://tests/test_world_map_v14_production_20261002.gd'
$sourceKeys = @(
    'res://scripts/dev/build_world_map_native_full_v14.gd',
    'res://scripts/dev/build_world_map_native_full_v14_ninth_draft.gd',
    'res://scripts/dev/world_map_v14_ninth_native_surface.gd',
    'res://scripts/field/field_walkable_controller.gd',
    'res://scripts/world/v14_modular_overlap.gd',
    $fullTest,
    'res://tests/helpers/v14_alpha_domain_interval_proof.gd'
)
$portalIds = @('yanmen_pass','huashan','wudang','gufeng','lingyue','bianzhou','luoyang','xiangzhou','jinling','east_sea_port','bailu_ferry','lieyun_valley','mingwu','linxi_village','zhuwei_village','qinghe_town')
$categories = @('terrain','water_banks','bridge_decks_rails','landmark_arrivals','native_props_front_back','vegetation','same_band_npc','ghost_overlap','map_overview')
$regions = @(); foreach ($row in 0..2) { foreach ($col in 0..2) { $regions += "r${row}c${col}" } }
$trackedEvidence = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)

function Resolve-Key([string]$Key) {
    if ($Key.StartsWith('res://',[StringComparison]::Ordinal)) { $rootPath=$gameRoot; $relative=$Key.Substring(6) }
    elseif ($Key.StartsWith('repo://',[StringComparison]::Ordinal)) { $rootPath=$repoRoot; $relative=$Key.Substring(7) }
    else { throw "Noncanonical evidence key: $Key" }
    if ([string]::IsNullOrWhiteSpace($relative) -or $relative.Contains('\') -or $relative.Contains(':') -or $relative.StartsWith('/') -or ($relative.Split('/') | Where-Object { $_ -in @('..','.','') })) { throw "Unsafe evidence key: $Key" }
    $path=[IO.Path]::GetFullPath((Join-Path $rootPath $relative))
    if (-not $path.StartsWith($rootPath.TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw "Escaped evidence root: $Key" }
    $cursor=$rootPath
    foreach ($part in $relative.Split('/')) {
        $cursor=Join-Path $cursor $part
        if ((Test-Path -LiteralPath $cursor) -and (((Get-Item -Force -LiteralPath $cursor).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) { throw "Linked evidence path: $Key" }
    }
    return $path
}
function Sha([string]$Key) {
    $path=Resolve-Key $Key
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing evidence: $Key" }
    return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
}
function Object-Json([string]$Key) {
    $object=Get-Content -Raw -LiteralPath (Resolve-Key $Key) | ConvertFrom-Json
    if ($null -eq $object -or $object -isnot [PSCustomObject]) { throw "Expected JSON object: $Key" }
    return $object
}
function Member($Object,[string]$Name) {
    if ($null -eq $Object -or $Object -isnot [PSCustomObject] -or $null -eq $Object.PSObject.Properties[$Name]) { throw "Missing required field: $Name" }
    return ,$Object.PSObject.Properties[$Name].Value
}
function Text($Object,[string]$Name,[string]$Expected) {
    $value=Member $Object $Name
    if ($value -isnot [string] -or $value -cne $Expected) { throw "Wrong text field: $Name" }
}
function True-Field($Object,[string]$Name) {
    $value=Member $Object $Name
    if ($value -isnot [bool] -or -not $value) { throw "Explicit true required: $Name" }
}
function Number($Object,[string]$Name,[double]$Expected) {
    $value=Member $Object $Name
    if ($value -is [string] -or $value -is [bool] -or $value -isnot [ValueType] -or [double]::IsNaN([double]$value) -or [double]::IsInfinity([double]$value) -or [double]$value -ne $Expected) { throw "Wrong numeric field: $Name" }
}
function Positive-Integer($Object,[string]$Name) {
    $value=Member $Object $Name
    if ($value -is [string] -or $value -is [bool] -or $value -isnot [ValueType] -or [double]::IsNaN([double]$value) -or [double]::IsInfinity([double]$value) -or [double]$value -le 0 -or [double]$value -ne [Math]::Floor([double]$value)) { throw "Positive integer required: $Name" }
    return [long]$value
}
function Hash-Map($Object) {
    if ($Object -isnot [PSCustomObject]) { throw 'Expected exact hash-map object.' }
    $map=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
    foreach ($property in $Object.PSObject.Properties) {
        if ($property.Value -isnot [string] -or $property.Value -cnotmatch '^[0-9a-fA-F]{64}$') { throw "Invalid SHA: $($property.Name)" }
        $map.Add($property.Name,$property.Value.ToLowerInvariant())
    }
    return ,$map
}
function Same-Hashes($Expected,$Actual,[string]$Label) {
    if ($Expected.Count -ne $Actual.Count) { throw "$Label key count mismatch." }
    foreach ($key in $Actual.Keys) { if (-not $Expected.ContainsKey($key) -or $Expected[$key] -cne $Actual[$key]) { throw "$Label key/SHA mismatch: $key" } }
}
function Same-Set($Values,[string[]]$Expected,[string]$Label) {
    if ($Values -isnot [Array] -or $Values.Count -ne $Expected.Count) { throw "$Label incomplete." }
    $set=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($value in $Values) { if ($value -isnot [string] -or -not $set.Add($value)) { throw "$Label duplicate/non-string." } }
    foreach ($value in $Expected) { if (-not $set.Contains($value)) { throw "$Label missing $value" } }
}
function Track([string]$Key,[string]$ExpectedSha) {
    if ($ExpectedSha -cnotmatch '^[0-9a-fA-F]{64}$' -or (Sha $Key) -cne $ExpectedSha.ToLowerInvariant()) { throw "Stale/missing evidence: $Key" }
    if ($trackedEvidence.ContainsKey($Key) -and $trackedEvidence[$Key] -cne $ExpectedSha.ToLowerInvariant()) { throw "Contradictory evidence SHA: $Key" }
    $trackedEvidence[$Key]=$ExpectedSha.ToLowerInvariant()
}
function Catalog-Audit {
    if ((Sha $approvalTool) -cne $approvalToolSha) { throw 'Approval tool source changed; independently review/update explicit pin first.' }
    # ONLY its read-only mode, with no dossiers/Approve/activation arguments.
    $auditText=@(& (Resolve-Key $approvalTool) -AuditOnly) -join "`n"
    $audit=$auditText | ConvertFrom-Json
    Text $audit 'mode' 'AUDIT_ONLY'
    Text $audit 'capture_approval' 'NOT_REVIEWED'
    $catalog=Hash-Map (Member $audit 'asset_sha256')
    Number $audit 'key_count' $catalog.Count
    if ($catalog.Count -eq 0) { throw 'Empty asset catalog.' }
    return ,$catalog
}
function Output-Path([string]$Key) {
    if (-not $Key.StartsWith('res://build/world_map_v14_qa/',[StringComparison]::Ordinal) -or -not $Key.EndsWith('.json',[StringComparison]::Ordinal)) { throw 'Dossier output must be a new QA build JSON, not production data.' }
    $path=Resolve-Key $Key
    if (Test-Path -LiteralPath $path) { throw "Refusing dossier overwrite: $Key" }
    if (-not (Test-Path -LiteralPath ([IO.Path]::GetDirectoryName($path)) -PathType Container)) { throw "Output parent must already exist: $Key" }
    return $path
}
function Write-New($Object,[string]$Path) {
    $json=$Object | ConvertTo-Json -Depth 30
    $bytes=[Text.UTF8Encoding]::new($false).GetBytes($json)
    $stream=[IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try { $stream.Write($bytes,0,$bytes.Length); $stream.Flush($true) } finally { $stream.Dispose() }
    if ([IO.File]::ReadAllText($Path,[Text.Encoding]::UTF8) -cne $json) { throw "Dossier exact readback failed: $Path" }
    $parsed=[IO.File]::ReadAllText($Path,[Text.Encoding]::UTF8) | ConvertFrom-Json
    if ($null -eq $parsed -or $parsed -isnot [PSCustomObject]) { throw "Written dossier is not JSON: $Path" }
}


function Validate-SupplementalNpc([string]$ReviewKey,[string]$GpuDirectory,[string]$NamedReviewer,$FullImages) {
 Track $ReviewKey (Sha $ReviewKey)
 $npc=Object-Json $ReviewKey
 Number $npc 'schema_version' 1; Number $npc 'capture_iteration' 9; Text $npc 'scope' 'SUPPLEMENTAL_NPC_VISUAL_REVIEW'; Text $npc 'reviewer' $NamedReviewer; True-Field $npc 'producer_review_complete'; Text $npc 'verdict' 'PASS'
 $regression=Member $npc 'regression'; Text $regression 'path' ($GpuDirectory+'normal_patrol_same_band.json'); True-Field $regression 'full_read'; Track (Member $regression 'path') (Member $regression 'sha256')
 $patrol=Object-Json (Member $regression 'path'); Text $patrol 'scope' 'FULL_WORLD_MAP_PRODUCTION'; Number $patrol 'capture_iteration' 9
 [void](Positive-Integer $patrol 'behind_count'); [void](Positive-Integer $patrol 'front_count')
 $rows=Member $patrol 'records'; if ($rows -isnot [Array] -or $rows.Count -eq 0) { throw 'Actual FULL patrol JSON has no records.' }
 foreach ($row in $rows) { True-Field $row 'correct_order'; True-Field $row 'body_rectangles_clear' }
 $evidence=Member $npc 'evidence'; True-Field $evidence 'full_read'
 $caseKey=Member $evidence 'path'
 if ($caseKey -isnot [string] -or -not $caseKey.StartsWith('res://build/') -or -not $caseKey.EndsWith('.json')) { throw 'Independent actual NPC case evidence required.' }
 Track $caseKey (Member $evidence 'sha256'); $cases=Member (Object-Json $caseKey) 'cases'
 $npcImages=Member $npc 'images'; if ($npcImages -isnot [Array] -or $npcImages.Count -lt 2) { throw 'Separate NPC front/behind pictures required.' }
 $relations=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
 $keys=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
 foreach ($entry in $npcImages) {
  $key=Member $entry 'path'; Text $entry 'verdict' 'PASS'
  if ($key -isnot [string] -or -not $key.StartsWith('res://build/') -or -not $key.EndsWith('.png') -or $FullImages.ContainsKey($key) -or -not $keys.Add($key)) { throw 'Supplement must be separate actual raw PNGs, never substitute/add FULL images.' }
  Track $key (Member $entry 'sha256'); $relation=Member $entry 'relation'
  if ($relation -isnot [string] -or $relation -cnotin @('front','behind')) { throw 'Supplement NPC relation missing.' }
  $caseId=Member $entry 'evidence_case_id'
  if ($caseId -isnot [string] -or [string]::IsNullOrWhiteSpace($caseId)) { throw 'Supplement picture lacks actual case binding.' }
  $case=Member $cases $caseId; Text $case 'image_path' $key; Text $case 'image_sha256' ((Member $entry 'sha256').ToLowerInvariant()); Text $case 'relation' $relation
  foreach ($field in @('full_foot_clear','physical_clear','correct_order')) { True-Field $case $field }
  [void](Positive-Integer $case 'current_alpha_hits')
  $frame=Member $case 'current_frame'
  if ($frame -is [string] -or $frame -is [bool] -or $frame -isnot [ValueType] -or [double]::IsNaN([double]$frame) -or [double]::IsInfinity([double]$frame) -or [double]$frame -lt 0 -or [double]$frame -ne [Math]::Floor([double]$frame)) { throw 'Actual current animation frame missing.' }
  foreach ($field in @('actor_foot_y','npc_foot_y')) { $v=Member $case $field; if ($v -is [bool] -or $v -is [string] -or $v -isnot [ValueType] -or [double]::IsNaN([double]$v) -or [double]::IsInfinity([double]$v)) { throw 'Actual finite footline missing.' } }
  $actor=[double](Member $case 'actor_foot_y'); $npcFoot=[double](Member $case 'npc_foot_y')
  if ([Math]::Floor($actor/8) -ne [Math]::Floor($npcFoot/8) -or ($relation -eq 'front' -and $actor -le $npcFoot) -or ($relation -eq 'behind' -and $actor -ge $npcFoot)) { throw 'Actual feet do not establish stated SAME-BAND front/behind.' }
  $stream=[IO.File]::OpenRead((Resolve-Key $key))
  try { $signature=New-Object byte[] 8; if ($stream.Read($signature,0,8) -ne 8 -or [BitConverter]::ToString($signature) -cne '89-50-4E-47-0D-0A-1A-0A') { throw 'Supplement file is not PNG bytes.' } } finally { $stream.Dispose() }
  [void]$relations.Add($relation)
 }
 Same-Set @($relations) @('front','behind') 'Actual reviewed supplemental NPC relations'
 return [ordered]@{path=$ReviewKey;sha256=(Sha $ReviewKey);kind='SEPARATE_REVIEWED_CURRENT_FRAME_NPC_PICTURES_AND_FULL_PATROL_JSON_NOT_FULL_RUN_OR_REGION_SCREENSHOT';regression=$regression;evidence=$evidence;images=$npcImages}
}

$qaPath=Output-Path $QaOutput
$visualPath=Output-Path $VisualOutput
if ($qaPath -ieq $visualPath) { throw 'QA and visual output paths must be different.' }
foreach ($inputKey in @($RunEvidence,$ReviewedImageIndex,$AuthorizationDocument)) {
    $inputPath=Resolve-Key $inputKey
    if ($inputPath -ieq $qaPath -or $inputPath -ieq $visualPath) { throw 'Output cannot replace an input.' }
}
if (-not $AuthorizationDocument.StartsWith('repo://docs/',[StringComparison]::Ordinal) -or -not $AuthorizationDocument.EndsWith('.md',[StringComparison]::Ordinal)) { throw 'Actual producer authorization must be docs Markdown.' }
Track $AuthorizationDocument $AuthorizationSha256
Track $RunEvidence (Sha $RunEvidence)
Track $ReviewedImageIndex (Sha $ReviewedImageIndex)
$runDescriptor=Object-Json $RunEvidence
$review=Object-Json $ReviewedImageIndex
foreach ($object in @($runDescriptor,$review)) { Number $object 'schema_version' 1; Number $object 'capture_iteration' 9; Text $object 'scope' 'FULL' }
True-Field $review 'producer_review_complete'
True-Field $review 'visual_approved'
True-Field $review 'production_approved'
Text $review 'verdict' 'PASS'
$findings=Member $review 'unresolved_findings'
if ($findings -isnot [Array] -or $findings.Count -ne 0) { throw 'Producer review retains unresolved findings.' }
$reviewer=Member $review 'reviewer'
if ($reviewer -isnot [string] -or [string]::IsNullOrWhiteSpace($reviewer)) { throw 'Actual named producer reviewer required.' }
$authorization=Member $review 'authorization'
Text $authorization 'path' $AuthorizationDocument
Text $authorization 'sha256' $AuthorizationSha256.ToLowerInvariant()
$catalog=Catalog-Audit
$actualSources=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
foreach ($key in $sourceKeys) { $actualSources.Add($key,(Sha $key)); Track $key $actualSources[$key] }
$manifest=Object-Json 'res://art/maps/world_map_v14/manifest.json'
$source=Object-Json 'res://art/maps/world_map_v14/source_contract.json'
Number $source 'schema_version' 14; Text $source 'status' 'ART_ASSETS_READY'
$worldSize=Member $source 'world_size'
if ($worldSize -isnot [Array] -or $worldSize.Count -ne 2) { throw 'Source world dimensions missing.' }
for ($axis=0; $axis -lt 2; $axis++) {
    $value=$worldSize[$axis]
    if ($value -is [string] -or $value -is [bool] -or $value -isnot [ValueType] -or [double]::IsNaN([double]$value) -or [double]::IsInfinity([double]$value) -or [double]$value -ne @(4608,3072)[$axis]) { throw 'Source world dimensions mismatch.' }
}
$sourcePortalIds=@(); foreach ($portal in (Member $source 'portals')) { $sourcePortalIds += Member $portal 'id' }
Same-Set $sourcePortalIds $portalIds 'Actual sixteen source portals'
Number $manifest 'capture_iteration' 9; Text $manifest 'version' 'world_v14'
Text $manifest 'status' 'PRODUCTION_APPROVED'
True-Field $manifest 'visual_approved'; True-Field $manifest 'production_approved'
if ((Member $manifest 'current_outputs_not_ready') -isnot [bool] -or (Member $manifest 'current_outputs_not_ready')) { throw 'Capture outputs are not ready.' }
Text $manifest 'executed_builder_path' $sourceKeys[0]
Text $manifest 'ninth_material_helper_path' $sourceKeys[2]
if ((Member $manifest 'executed_builder_sha256').ToLowerInvariant() -cne $actualSources[$sourceKeys[0]] -or $actualSources[$sourceKeys[0]] -cne $actualSources[$sourceKeys[1]] -or (Member $manifest 'ninth_material_helper_sha256').ToLowerInvariant() -cne $actualSources[$sourceKeys[2]]) { throw 'Actual captured source is not current frozen production source.' }
$runs=[ordered]@{}
$runInput=Member $runDescriptor 'runs'
Same-Set @($runInput.PSObject.Properties.Name) @('headless','gpu') 'Exactly two full runs'
$gpuDirectory=''
$gpuScreenshotCount=0
foreach ($mode in @('headless','gpu')) {
    $run=Member $runInput $mode
    Text $run 'scope' 'FULL'; True-Field $run 'completed'; Number $run 'exit_code' 0; Number $run 'failures' 0
    $checks=Positive-Integer $run 'checks'
    Text $run 'script_path' $fullTest
    Text $run 'script_sha256' $actualSources[$fullTest]
    Same-Hashes (Hash-Map (Member $run 'actual_sources')) $actualSources "$mode actual executed seven sources"
    foreach ($kind in @('log','stderr','result')) {
        $key=Member $run ($kind+'_path')
        if ($key -isnot [string] -or -not $key.StartsWith('res://build/',[StringComparison]::Ordinal) -or ($kind -eq 'result' -and -not $key.EndsWith('/result.json',[StringComparison]::Ordinal)) -or ($kind -ne 'result' -and -not $key.EndsWith('.log',[StringComparison]::Ordinal))) { throw "Wrong $mode $kind evidence path." }
        Track $key (Member $run ($kind+'_sha256'))
    }
    if ((Member $run 'log_path') -ceq (Member $run 'stderr_path')) { throw 'stdout/stderr must be independent captured files.' }
    $stdout=Get-Content -Raw -LiteralPath (Resolve-Key (Member $run 'log_path'))
    $stderr=Get-Content -Raw -LiteralPath (Resolve-Key (Member $run 'stderr_path'))
    if (($stdout+"`n"+$stderr) -match '(?im)^\s*(?:SCRIPT ERROR:|SHADER ERROR:|ERROR:)|shader compilation failed|assertion failed') { throw "Actual engine error in $mode logs; no dossier output." }
    $resultKey=Member $run 'result_path'
    $result=Object-Json $resultKey
    Text $result 'scope' 'FULL_WORLD_MAP_PRODUCTION'; Text $result 'stage' 'candidate-before-cutover'
    Number $result 'capture_iteration' 9; Number $result 'checks' $checks; Number $result 'failures' 0
    foreach ($field in @('player_saves_unchanged','player_saves_unchanged_before_cleanup','player_saves_unchanged_after_cleanup','test_owned_cleanup_completed','exit_cursor_textures_released','schema_ready')) { True-Field $result $field }
    True-Field (Member $result 'exit_audio') 'released'
    Number $result 'actual_portal_input_count' 16; Number $result 'actual_open_seam_input_count' 12
    $footCenters=Positive-Integer $result 'full_foot_centers'
    $outputDirectory=Member $result 'output_dir'
    if ($outputDirectory -isnot [string] -or $outputDirectory -cne $resultKey.Substring(0,$resultKey.LastIndexOf('/')+1)) { throw 'Result output directory mismatch.' }
    if ($mode -eq 'headless') { Text $result 'renderer' 'headless'; Number $result 'screenshots' 0 }
    else {
        $renderer=Member $result 'renderer'
        if ($renderer -isnot [string] -or [string]::IsNullOrWhiteSpace($renderer) -or $renderer -eq 'headless') { throw 'GPU evidence is not actual GPU.' }
        $gpuScreenshotCount=Positive-Integer $result 'screenshots'; $gpuDirectory=$outputDirectory
    }
    $summary=[regex]::Matches($stdout,'(?m)^\[WorldV14Production\] stage=candidate-before-cutover checks=(\d+) failures=(\d+) captures=(\d+) fullfoot_centers=(\d+) portals_input=(\d+) seams_input=(\d+) output=([^\r\n]+)\r?$')
    if ($summary.Count -ne 1 -or [long]$summary[0].Groups[1].Value -ne $checks -or [long]$summary[0].Groups[2].Value -ne 0 -or [long]$summary[0].Groups[3].Value -ne [long](Member $result 'screenshots') -or [long]$summary[0].Groups[4].Value -ne $footCenters -or [long]$summary[0].Groups[5].Value -ne 16 -or [long]$summary[0].Groups[6].Value -ne 12 -or $summary[0].Groups[7].Value -cne $outputDirectory) { throw "$mode real completion/result mismatch." }
    $runs[$mode]=[ordered]@{scope='FULL';exit_code=0;failures=0;checks=$checks;script_path=$fullTest;script_sha256=$actualSources[$fullTest];log_path=(Member $run 'log_path');log_sha256=(Member $run 'log_sha256');stderr_path=(Member $run 'stderr_path');stderr_sha256=(Member $run 'stderr_sha256');result_path=$resultKey;result_sha256=(Member $run 'result_sha256')}
}
if ((Member (Member $runInput 'headless') 'result_path') -ceq (Member (Member $runInput 'gpu') 'result_path')) { throw 'Headless and GPU cannot share a result.' }
$images=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
foreach ($file in Get-ChildItem -LiteralPath (Resolve-Key $gpuDirectory.TrimEnd('/')) -File -Filter '*.png') {
    $key=$gpuDirectory+$file.Name
    $hash=Sha $key; Track $key $hash; $images.Add($key,$hash)
    $stream=[IO.File]::OpenRead((Resolve-Key $key))
    try { $signature=New-Object byte[] 8; if ($stream.Read($signature,0,8) -ne 8 -or [BitConverter]::ToString($signature) -cne '89-50-4E-47-0D-0A-1A-0A') { throw "Not actual PNG: $key" } } finally { $stream.Dispose() }
}
if ($images.Count -lt 9 -or $images.Count -ne $gpuScreenshotCount) { throw 'Actual full screenshot directory/count incomplete.' }
$reviewImages=Member $review 'images'
if ($reviewImages -isnot [PSCustomObject] -or @($reviewImages.PSObject.Properties).Count -ne $images.Count) { throw 'Review must include ALL actual GPU PNGs, not a chosen subset.' }
$coveredRegions=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$coveredPortals=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$coveredCategories=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$verdicts=[ordered]@{}
foreach ($key in ($images.Keys | Sort-Object -CaseSensitive)) {
    $entry=Member $reviewImages $key
    Text $entry 'sha256' $images[$key]; Text $entry 'verdict' 'PASS'
    # Copy ONLY a supplied, exact SHA-bound explicit PASS, never infer from logs.
    $verdicts[$key]=Member $entry 'verdict'
    foreach ($pair in @(@('regions',$regions,$coveredRegions),@('portal_ids',$portalIds,$coveredPortals),@('categories',$categories,$coveredCategories))) {
        $values=Member $entry $pair[0]
        if ($values -isnot [Array]) { throw "Review annotation must be an array: $key/$($pair[0])" }
        $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        foreach ($value in $values) {
            if ($value -isnot [string] -or $value -cnotin $pair[1] -or -not $seen.Add($value)) { throw "Unknown/duplicate annotation: $key/$value" }
            if ($pair[0] -eq 'categories' -and $value -ceq 'same_band_npc') { throw 'FULL PNG must not claim the JSON-only patrol regression picture; require separate actual NPC pictures.' }
            [void]$pair[2].Add($value)
        }
    }
}
Same-Set @($coveredRegions) $regions 'Nine visually reviewed regions'
Same-Set @($coveredPortals) $portalIds 'Sixteen visually reviewed portals'
Same-Set @($coveredCategories) @($categories | Where-Object { $_ -cne 'same_band_npc' }) 'Eight actually reviewed FULL picture categories'
$attachments=Member $review 'supplemental_category_reviews'
Same-Set @($attachments.PSObject.Properties.Name) @('same_band_npc') 'Exact independent supplemental category'
$attachment=Member $attachments 'same_band_npc'
$attachmentKey=Member $attachment 'path'
Track $attachmentKey (Member $attachment 'sha256')
$verifiedSupplement=Validate-SupplementalNpc $attachmentKey $gpuDirectory $reviewer $images
[void]$coveredCategories.Add('same_band_npc')
Same-Set @($coveredCategories) $categories 'Full pictures plus independently reviewed actual same-band NPC attachment'
$coverage=[ordered]@{regions=$regions;portal_ids=$portalIds;categories=$categories}
Same-Hashes $catalog (Catalog-Audit) 'Final audited asset catalog'
foreach ($key in $trackedEvidence.Keys) { if ((Sha $key) -cne $trackedEvidence[$key]) { throw "Evidence changed during preparation: $key" } }
# Recheck exact directory keyset, rejecting even a racing added/removed image.
$finalImages=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
foreach ($file in Get-ChildItem -LiteralPath (Resolve-Key $gpuDirectory.TrimEnd('/')) -File -Filter '*.png') { $key=$gpuDirectory+$file.Name; $finalImages.Add($key,(Sha $key)) }
Same-Hashes $images $finalImages 'Final complete screenshot directory'
$qa=[ordered]@{schema_version=1;scope='FULL';capture_iteration=9;technical_approved=$true;asset_sha256=$catalog;actual_sources=$actualSources;runs=$runs;images_sha256=$images;coverage=$coverage;unresolved_findings=@();producer_run_evidence=[ordered]@{path=$RunEvidence;sha256=$trackedEvidence[$RunEvidence]};supplemental_category_reviews=[ordered]@{same_band_npc=$verifiedSupplement}}
Write-New $qa $qaPath
$visual=[ordered]@{schema_version=1;scope='FULL';capture_iteration=9;verdict=(Member $review 'verdict');visual_approved=(Member $review 'visual_approved');production_approved=(Member $review 'production_approved');qa_dossier_sha256=(Sha $QaOutput);asset_sha256=$catalog;images_sha256=$images;image_verdicts=$verdicts;unresolved_findings=@();authorization=[ordered]@{path=$AuthorizationDocument;sha256=$AuthorizationSha256.ToLowerInvariant()};reviewer=$reviewer;producer_review_index=[ordered]@{path=$ReviewedImageIndex;sha256=$trackedEvidence[$ReviewedImageIndex]};supplemental_category_reviews=[ordered]@{same_band_npc=$verifiedSupplement}}
Write-New $visual $visualPath
Write-Output 'WORLD_V14_DOSSIERS_PREPARED_ONLY_NOT_ACCEPTED_NOT_ACTIVATED'
Write-Output "QA=$QaOutput SHA=$(Sha $QaOutput)"
Write-Output "VISUAL=$VisualOutput SHA=$(Sha $VisualOutput)"
