# Explicit producer-review recording ONLY. No approvals/activation/engine calls.
[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$HeadlessResult,
 [Parameter(Mandatory)][string]$HeadlessStdout,
 [Parameter(Mandatory)][string]$HeadlessStderr,
 [Parameter(Mandatory)][string]$GpuResult,
 [Parameter(Mandatory)][string]$GpuStdout,
 [Parameter(Mandatory)][string]$GpuStderr,
 [Parameter(Mandatory)][string]$ExecutedSourcesRecord,
 [Parameter(Mandatory)][string[]]$ReviewedContactIndexes,
 [Parameter(Mandatory)][string[]]$PassedPageIds,
 [string[]]$ReviewedFullResolutionFiles=@(),
 [Parameter(Mandatory)][string]$SupplementalNpcReview,
 [Parameter(Mandatory)][switch]$ProducerVisualPass,
 [Parameter(Mandatory)][string]$Reviewer,
 [Parameter(Mandatory)][string]$AuthorizationDocument,
 [Parameter(Mandatory)][string]$AuthorizationSha256,
 [Parameter(Mandatory)][string]$RunEvidenceOutput,
 [Parameter(Mandatory)][string]$ReviewedImageIndexOutput
)
# Inputs use canonical res:// / repo:// keys. Contact indexes may contain actual
# absolute paths, canonicalized ONLY inside the repository, no symlink traversal.
# PassedPageIds: "<contact index key>#<1-based page>". Require the EXACT complete
# page set for every supplied index. Each index must bind current original SHA.
# Extra full-resolution files are an EXPLICIT root-viewed current FULL PNG list.
#
# ExecutedSourcesRecord is actual root launch/exit evidence, not made here:
# {schema_version:1,scope:"FULL",capture_iteration:9,runs:{headless,gpu}}.
# Each {completed:true,exit_code:0,actual_sources:{exact fixed7 keys:SHA},
# result_path,result_sha256,log_path,log_sha256,stderr_path,stderr_sha256}.
#
# SupplementalNpcReview root-written AFTER actual full JSON and image review:
# {schema_version:1,scope:"SUPPLEMENTAL_NPC_VISUAL_REVIEW",capture_iteration:9,
# producer_review_complete:true,verdict:"PASS",reviewer:<same named root>,
# regression:{path:<FULL GPU dir/normal_patrol_same_band.json>,sha256,full_read:true},
# evidence:{path:<independent actual NPC case JSON>,sha256,full_read:true},
# images:[{path:<independent raw PNG>,sha256,relation:"front"|"behind",
# verdict:"PASS",evidence_case_id:<key in evidence.cases>}]}
# Actual case JSON {cases:{id:{image_path,image_sha256,relation,actor_foot_y,
# npc_foot_y,current_alpha_hits,current_frame,full_foot_clear:true,
# physical_clear:true,correct_order:true}}}. Both relations required, finite
# actual same-band feet, positive CURRENT alpha. Not full animation coverage.
# The attachment is never a second FULL run and never added to FULL PNG keyset.
#
# Two NEW outputs res://build/world_map_v14_qa/.../*.json; parents must exist.
# No manifest/canonical/player/acceptance/doc/existing-evidence writes.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repoRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..')).TrimEnd('\','/')
$gameRoot=Join-Path $repoRoot 'game'
$fullTest='res://tests/test_world_map_v14_production_20261002.gd'
$sourceKeys=@('res://scripts/dev/build_world_map_native_full_v14.gd','res://scripts/dev/build_world_map_native_full_v14_ninth_draft.gd','res://scripts/dev/world_map_v14_ninth_native_surface.gd','res://scripts/field/field_walkable_controller.gd','res://scripts/world/v14_modular_overlap.gd',$fullTest,'res://tests/helpers/v14_alpha_domain_interval_proof.gd')
$portalIds=@('yanmen_pass','huashan','wudang','gufeng','lingyue','bianzhou','luoyang','xiangzhou','jinling','east_sea_port','bailu_ferry','lieyun_valley','mingwu','linxi_village','zhuwei_village','qinghe_town')
$trackedEvidence=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)

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

function Canonical-Key([string]$Path) {
 if ($Path.StartsWith('res://') -or $Path.StartsWith('repo://')) { [void](Resolve-Key $Path); return $Path }
 if (-not [IO.Path]::IsPathRooted($Path)) { throw 'Contact path must be canonical or absolute.' }
 $absolute=[IO.Path]::GetFullPath($Path)
 foreach ($pair in @(@($gameRoot,'res://'),@($repoRoot,'repo://'))) {
  $prefix=$pair[0]+[IO.Path]::DirectorySeparatorChar
  if ($absolute.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) { $key=$pair[1]+$absolute.Substring($prefix.Length).Replace('\','/'); [void](Resolve-Key $key); return $key }
 }
 throw 'Contact file escaped repository.'
}
function New-Output([string]$Key) {
 if (-not $Key.StartsWith('res://build/world_map_v14_qa/') -or -not $Key.EndsWith('.json')) { throw 'Only NEW QA build JSON outputs allowed.' }
 $path=Resolve-Key $Key
 if (Test-Path -LiteralPath $path) { throw "Refusing overwrite: $Key" }
 if (-not (Test-Path -LiteralPath ([IO.Path]::GetDirectoryName($path)) -PathType Container)) { throw 'Output parent must exist.' }
 return $path
}
function Write-New($Object,[string]$Path) {
 $json=$Object | ConvertTo-Json -Depth 30; $bytes=[Text.UTF8Encoding]::new($false).GetBytes($json)
 $stream=[IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try { $stream.Write($bytes,0,$bytes.Length); $stream.Flush($true) } finally { $stream.Dispose() }
 if ([IO.File]::ReadAllText($Path,[Text.Encoding]::UTF8) -cne $json -or ([IO.File]::ReadAllText($Path,[Text.Encoding]::UTF8) | ConvertFrom-Json) -isnot [PSCustomObject]) { throw 'Exact JSON readback failed.' }
}
function Validate-Run([string]$Mode,[string]$ResultKey,[string]$LogKey,[string]$ErrKey,$Sources,$Recorded) {
 True-Field $Recorded 'completed'; Number $Recorded 'exit_code' 0
 Same-Hashes (Hash-Map (Member $Recorded 'actual_sources')) $Sources "$Mode actual seven launch sources"
 foreach ($pair in @(@('result',$ResultKey),@('log',$LogKey),@('stderr',$ErrKey))) { Text $Recorded ($pair[0]+'_path') $pair[1]; Track $pair[1] (Member $Recorded ($pair[0]+'_sha256')) }
 if ($LogKey -ceq $ErrKey -or -not $ResultKey.EndsWith('/result.json') -or -not $LogKey.EndsWith('.log') -or -not $ErrKey.EndsWith('.log')) { throw 'Independent raw logs and actual result required.' }
 foreach ($key in @($ResultKey,$LogKey,$ErrKey)) { if (-not $key.StartsWith('res://build/')) { throw 'Run evidence must be build artifacts.' } }
 $result=Object-Json $ResultKey
 Text $result 'scope' 'FULL_WORLD_MAP_PRODUCTION'; Text $result 'stage' 'candidate-before-cutover'; Number $result 'capture_iteration' 9; Number $result 'failures' 0
 $checks=Positive-Integer $result 'checks'; $feet=Positive-Integer $result 'full_foot_centers'
 foreach ($field in @('schema_ready','player_saves_unchanged','player_saves_unchanged_before_cleanup','player_saves_unchanged_after_cleanup','test_owned_cleanup_completed','exit_cursor_textures_released')) { True-Field $result $field }
 True-Field (Member $result 'exit_audio') 'released'; Number $result 'actual_portal_input_count' 16; Number $result 'actual_open_seam_input_count' 12
 $directory=Member $result 'output_dir'
 if ($directory -isnot [string] -or $directory -cne $ResultKey.Substring(0,$ResultKey.LastIndexOf('/')+1)) { throw 'Actual output path mismatch.' }
 if ($Mode -eq 'headless') { Text $result 'renderer' 'headless'; Number $result 'screenshots' 0 }
 elseif ((Member $result 'renderer') -isnot [string] -or [string]::IsNullOrWhiteSpace((Member $result 'renderer')) -or (Member $result 'renderer') -eq 'headless') { throw 'GPU result is not actual GPU.' }
 $stdout=Get-Content -Raw -LiteralPath (Resolve-Key $LogKey); $stderr=Get-Content -Raw -LiteralPath (Resolve-Key $ErrKey)
 if (($stdout+[Environment]::NewLine+$stderr) -match '(?im)^\s*(?:SCRIPT ERROR:|SHADER ERROR:|ERROR:)|shader compilation failed|assertion failed') { throw "Actual $Mode engine error." }
 $summary=[regex]::Matches($stdout,'(?m)^\[WorldV14Production\] stage=candidate-before-cutover checks=(\d+) failures=(\d+) captures=(\d+) fullfoot_centers=(\d+) portals_input=(\d+) seams_input=(\d+) output=([^\r\n]+)\r?$')
 if ($summary.Count -ne 1 -or [long]$summary[0].Groups[1].Value -ne $checks -or [long]$summary[0].Groups[2].Value -ne 0 -or [long]$summary[0].Groups[3].Value -ne [long](Member $result 'screenshots') -or [long]$summary[0].Groups[4].Value -ne $feet -or [long]$summary[0].Groups[5].Value -ne 16 -or [long]$summary[0].Groups[6].Value -ne 12 -or $summary[0].Groups[7].Value -cne $directory) { throw 'Finished FULL result/log mismatch.' }
 return [ordered]@{scope='FULL';completed=$true;exit_code=(Member $Recorded 'exit_code');checks=$checks;failures=(Member $result 'failures');script_path=$fullTest;script_sha256=$Sources[$fullTest];actual_sources=$Sources;log_path=$LogKey;log_sha256=(Sha $LogKey);stderr_path=$ErrKey;stderr_sha256=(Sha $ErrKey);result_path=$ResultKey;result_sha256=(Sha $ResultKey)}
}
function Annotations([string]$Name) {
 $regions=@(); $portals=@(); $kinds=@()
 if ($Name -cmatch '^region_(r[0-2]c[0-2])\.png$') { $regions=@($Matches[1]); $kinds=@('terrain') }
 elseif ($Name -cmatch '^(portal|wall_stop)_(.+)\.png$') { if ($Matches[2] -cnotin $portalIds) { throw 'Unknown portal screenshot.' }; $portals=@($Matches[2]); $kinds=@('landmark_arrivals') }
 elseif ($Name -cmatch '^boundary_horizontal_([12])_([0-2])\.png$') { $row=[int]$Matches[1]; $col=[int]$Matches[2]; $regions=@(('r'+($row-1)+'c'+$col),('r'+$row+'c'+$col)); $kinds=@('terrain') }
 elseif ($Name -cmatch '^boundary_vertical_([0-2])_([12])\.png$') { $row=[int]$Matches[1]; $col=[int]$Matches[2]; $regions=@(('r'+$row+'c'+($col-1)),('r'+$row+'c'+$col)); $kinds=@('terrain') }
 elseif ($Name -cmatch '^bridge[0-4]_(exit|return)\.png$') { $kinds=@('bridge_decks_rails','water_banks') }
 elseif ($Name -cmatch '^depth_(.+)_(front|behind)\.png$') { $id=$Matches[1]; $kinds=@('native_props_front_back','ghost_overlap'); if ($id -cmatch '^native_(tree_|pine_|herb|grove)') { $kinds+=@('vegetation') } }
 elseif ($Name -ceq 'mature_canopy_performance_station.png') { $kinds=@('vegetation') }
 elseif ($Name -ceq 'ghost_transparent_rectangle.png') { $kinds=@('ghost_overlap') }
 elseif ($Name -ceq 'overview_M.png') { $kinds=@('map_overview') }
 # Every unknown/battle PNG still requires review, but no invented category.
 return [ordered]@{regions=$regions;portal_ids=$portals;categories=$kinds}
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

if (-not $ProducerVisualPass.IsPresent -or [string]::IsNullOrWhiteSpace($Reviewer)) { throw 'Actual reviewer and explicit ProducerVisualPass required.' }
$runPath=New-Output $RunEvidenceOutput; $reviewPath=New-Output $ReviewedImageIndexOutput
if ($runPath -ieq $reviewPath) { throw 'Distinct NEW outputs required.' }
if (-not $AuthorizationDocument.StartsWith('repo://docs/') -or -not $AuthorizationDocument.EndsWith('.md')) { throw 'Existing producer authorization Markdown required.' }
Track $AuthorizationDocument $AuthorizationSha256; Track $ExecutedSourcesRecord (Sha $ExecutedSourcesRecord)
$manifestKey='res://art/maps/world_map_v14/manifest.json'; $manifest=Object-Json $manifestKey; Track $manifestKey (Sha $manifestKey)
Text $manifest 'status' 'PRODUCTION_APPROVED'; Number $manifest 'capture_iteration' 9; True-Field $manifest 'visual_approved'; True-Field $manifest 'production_approved'
if ((Member $manifest 'current_outputs_not_ready') -isnot [bool] -or (Member $manifest 'current_outputs_not_ready')) { throw 'Current outputs not ready.' }
$sources=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
foreach ($key in $sourceKeys) { $sources.Add($key,(Sha $key)); Track $key $sources[$key] }
Text $manifest 'executed_builder_path' $sourceKeys[0]; Text $manifest 'ninth_material_helper_path' $sourceKeys[2]
if ((Member $manifest 'executed_builder_sha256').ToLowerInvariant() -cne $sources[$sourceKeys[0]] -or $sources[$sourceKeys[0]] -cne $sources[$sourceKeys[1]] -or (Member $manifest 'ninth_material_helper_sha256').ToLowerInvariant() -cne $sources[$sourceKeys[2]]) { throw 'Actual captured source differs.' }
$launch=Object-Json $ExecutedSourcesRecord; Number $launch 'schema_version' 1; Number $launch 'capture_iteration' 9; Text $launch 'scope' 'FULL'
$launchRuns=Member $launch 'runs'; Same-Set @($launchRuns.PSObject.Properties.Name) @('headless','gpu') 'Actual launch runs'
$runs=[ordered]@{headless=(Validate-Run 'headless' $HeadlessResult $HeadlessStdout $HeadlessStderr $sources (Member $launchRuns 'headless'));gpu=(Validate-Run 'gpu' $GpuResult $GpuStdout $GpuStderr $sources (Member $launchRuns 'gpu'))}
if ($HeadlessResult -ceq $GpuResult) { throw 'Distinct completed FULL results required.' }
$gpu=Object-Json $GpuResult; $gpuDir=Member $gpu 'output_dir'
$raw=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
foreach ($file in Get-ChildItem -LiteralPath (Resolve-Key $gpuDir.TrimEnd('/')) -File -Filter '*.png') { $key=$gpuDir+$file.Name; $raw.Add($key,(Sha $key)); Track $key $raw[$key] }
if ($raw.Count -lt 9) { throw 'Actual screenshot set incomplete.' }; Number $gpu 'screenshots' $raw.Count
$passed=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($id in $PassedPageIds) { if (-not $passed.Add($id)) { throw 'Duplicate explicit reviewed page.' } }
$expected=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$covered=[Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
$contactRecords=@(); $seenIndexes=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($indexKey in $ReviewedContactIndexes) {
 if (-not $seenIndexes.Add($indexKey) -or -not $indexKey.EndsWith('/index.json')) { throw 'Contact index invalid/repeated.' }
 $index=Object-Json $indexKey; Track $indexKey (Sha $indexKey)
 Text $index 'purpose' 'VISUAL_REVIEW_AID_ONLY_NOT_A_VERDICT'; True-Field $index 'original_images_unmodified'
 if ((Canonical-Key (Member $index 'source')).TrimEnd('/') -cne $gpuDir.TrimEnd('/')) { throw 'Contact index belongs to a different FULL run.' }
 $pages=Member $index 'pages'; $entries=Member $index 'images'
 if ($pages -isnot [Array] -or $pages.Count -eq 0 -or $entries -isnot [Array]) { throw 'Actual contact pages/entries missing.' }; Number $index 'image_count' $entries.Count
 for ($page=1; $page -le $pages.Count; $page++) { $id=$indexKey+'#'+$page; if (-not $expected.Add($id) -or -not $passed.Contains($id)) { throw "Explicit reviewed PASS missing: $id" }; $pageKey=Canonical-Key $pages[$page-1]; Track $pageKey (Sha $pageKey) }
 $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal); $nonemptyPages=[Collections.Generic.HashSet[int]]::new()
 foreach ($entry in $entries) {
  $key=Canonical-Key (Member $entry 'path'); if (-not $raw.ContainsKey($key) -or -not $seen.Add($key)) { throw 'Stale/foreign/duplicate contact raw PNG.' }
  Text $entry 'sha256' $raw[$key]; $page=Positive-Integer $entry 'contact_page'
  if ($page -gt $pages.Count) { throw 'Contact page out of range.' }; [void]$nonemptyPages.Add([int]$page)
  if (-not $covered.ContainsKey($key)) { $covered.Add($key,[Collections.Generic.List[object]]::new()) }
  $pageKey=Canonical-Key $pages[$page-1]
  $covered[$key].Add([ordered]@{kind='explicit_root_reviewed_contact_page';index_path=$indexKey;index_sha256=(Sha $indexKey);page=$page;page_path=$pageKey;page_sha256=(Sha $pageKey)})
 }
 if ($nonemptyPages.Count -ne $pages.Count) { throw 'Empty contact page cannot count as review.' }
 $contactRecords+=@([ordered]@{path=$indexKey;sha256=(Sha $indexKey);passed_page_ids=@(1..$pages.Count)})
}
Same-Set @($passed) @($expected) 'Exact explicitly reviewed page set'
$fullRecords=@(); $seenFull=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($key in $ReviewedFullResolutionFiles) {
 if (-not $raw.ContainsKey($key) -or -not $seenFull.Add($key)) { throw 'Foreign/duplicate full-resolution review file.' }
 if (-not $covered.ContainsKey($key)) { $covered.Add($key,[Collections.Generic.List[object]]::new()) }
 $record=[ordered]@{kind='explicit_root_full_resolution_review';path=$key;sha256=$raw[$key]}; $covered[$key].Add($record); $fullRecords+=@($record)
}
if ($covered.Count -ne $raw.Count) { throw 'New/omitted raw PNG lacks explicit review; refusing outputs.' }
foreach ($key in $raw.Keys) { if (-not $covered.ContainsKey($key)) { throw "Unreviewed raw image: $key" } }
$images=[ordered]@{}
foreach ($key in ($raw.Keys | Sort-Object -CaseSensitive)) { $a=Annotations ([IO.Path]::GetFileName((Resolve-Key $key))); $images[$key]=[ordered]@{sha256=$raw[$key];verdict='PASS';regions=$a.regions;portal_ids=$a.portal_ids;categories=$a.categories;producer_review_evidence=@($covered[$key])} }
$supplement=Validate-SupplementalNpc $SupplementalNpcReview $gpuDir $Reviewer $raw
$r=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal); $p=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal); $c=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($entry in $images.Values) { foreach ($v in $entry.regions) { [void]$r.Add($v) }; foreach ($v in $entry.portal_ids) { [void]$p.Add($v) }; foreach ($v in $entry.categories) { [void]$c.Add($v) } }
$regions=@(); foreach ($row in 0..2) { foreach ($col in 0..2) { $regions+=('r'+$row+'c'+$col) } }
$pictureCategories=@('terrain','water_banks','bridge_decks_rails','landmark_arrivals','native_props_front_back','vegetation','ghost_overlap','map_overview')
Same-Set @($r) $regions 'Actual nine region image names'; Same-Set @($p) $portalIds 'Actual sixteen portal image names'; Same-Set @($c) $pictureCategories 'Actual eight FULL picture categories'
foreach ($key in $trackedEvidence.Keys) { if ((Sha $key) -cne $trackedEvidence[$key]) { throw "Changed input: $key" } }
$final=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
foreach ($file in Get-ChildItem -LiteralPath (Resolve-Key $gpuDir.TrimEnd('/')) -File -Filter '*.png') { $key=$gpuDir+$file.Name; $final.Add($key,(Sha $key)) }; Same-Hashes $raw $final 'Unmodified entire FULL PNG keyset'
$runOutput=[ordered]@{schema_version=1;scope='FULL';capture_iteration=9;runs=$runs;producer_execution_record=[ordered]@{path=$ExecutedSourcesRecord;sha256=(Sha $ExecutedSourcesRecord)}}
$reviewOutput=[ordered]@{schema_version=1;scope='FULL';capture_iteration=9;producer_review_complete=$ProducerVisualPass.IsPresent;reviewer=$Reviewer;verdict='PASS';visual_approved=$ProducerVisualPass.IsPresent;production_approved=$ProducerVisualPass.IsPresent;unresolved_findings=@();authorization=[ordered]@{path=$AuthorizationDocument;sha256=$AuthorizationSha256.ToLowerInvariant()};images=$images;reviewed_contact_indexes=$contactRecords;reviewed_full_resolution_files=$fullRecords;supplemental_category_reviews=[ordered]@{same_band_npc=$supplement}}
Write-New $runOutput $runPath; Write-New $reviewOutput $reviewPath
Write-Output 'WORLD_V14_PRODUCER_INPUTS_RECORDED_ONLY_NOT_DOSSIERS_NOT_ACCEPTED_NOT_ACTIVATED'

