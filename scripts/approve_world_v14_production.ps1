# Independent producer gate, not an art publisher or test runner.
# Authorization: producer handoff for this file; project role/acceptance policy:
# docs/agent-workflow.md, docs/module-owners.md, docs/world-map-v13-production-plan-20260928.md.
# Default/-AuditOnly is read-only. -Approve never changes manifest, canonical scene,
# player saves, or any art bytes. It refuses incomplete, bounded or stale evidence.
# Dossier schema is documented below the parameters; no approved template is emitted.
[CmdletBinding()]
param(
    [switch]$AuditOnly,
    [switch]$Approve,
    [string]$QaDossier,
    [string]$VisualDossier
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($AuditOnly -and $Approve) { throw 'Choose AuditOnly or Approve, not both.' }

# QA JSON schema 1: scope FULL, capture_iteration 9, technical_approved true,
# asset_sha256 exact full catalog, actual_sources {res://script.gd: sha256},
# runs {headless,gpu}: each {scope:FULL,exit_code:0,failures:0,checks:positive,
# script_path,script_sha256,log_path,log_sha256,stderr_path,stderr_sha256,
# result_path,result_sha256}; images_sha256 maps ALL raw GPU output PNG paths
# to SHA; coverage {regions:[r0c0..r2c2],portal_ids:[all16],categories:[below]},
# unresolved_findings:[] . Both runs must use the actual full production suite.
# Visual JSON schema 1: scope FULL,capture_iteration 9,verdict PASS,
# visual_approved:true,production_approved:true,qa_dossier_sha256,
# asset_sha256 and images_sha256 identical to QA/current bytes,
# image_verdicts {every raw PNG key:PASS},unresolved_findings:[],
# authorization {path:repo://docs/...,sha256:<actual human/producer authorization>},
# reviewer:<nonempty identity>. No technical count implies visual approval.

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd('\','/')
$gameRoot = Join-Path $repoRoot 'game'
$publisherSha = 'f5740d58b42d1fc93a26bbcb7055eb4226c50d7b564212ea0c57d816994d6600'
$legacySha = '09fa89449b1792063e66ad488aa2f60671aa00da2193e5c68acb861df14d71d5'
$approvalKey = 'res://data/maps/world_map_v14_acceptance.json'
$mainBuilder = 'res://scripts/dev/build_world_map_native_full_v14.gd'
$ninthBuilder = 'res://scripts/dev/build_world_map_native_full_v14_ninth_draft.gd'
$ninthHelper = 'res://scripts/dev/world_map_v14_ninth_native_surface.gd'
$fullTest = 'res://tests/test_world_map_v14_production_20261002.gd'
$portalIds = @('yanmen_pass','huashan','wudang','gufeng','lingyue','bianzhou','luoyang','xiangzhou','jinling','east_sea_port','bailu_ferry','lieyun_valley','mingwu','linxi_village','zhuwei_village','qinghe_town')
$categories = @('terrain','water_banks','bridge_decks_rails','landmark_arrivals','native_props_front_back','vegetation','same_band_npc','ghost_overlap','map_overview')

function Resolve-Key([string]$Key) {
    if ($Key.StartsWith('res://',[StringComparison]::Ordinal)) { $root = $gameRoot; $relative = $Key.Substring(6) }
    elseif ($Key.StartsWith('repo://',[StringComparison]::Ordinal)) { $root = $repoRoot; $relative = $Key.Substring(7) }
    else { throw "Noncanonical evidence key: $Key" }
    if ([string]::IsNullOrWhiteSpace($relative) -or $relative.Contains('\') -or $relative.Contains(':') -or $relative.StartsWith('/') -or ($relative.Split('/') | Where-Object { $_ -eq '..' -or $_ -eq '.' -or $_ -eq '' })) { throw "Unsafe evidence key: $Key" }
    $resolved = [IO.Path]::GetFullPath((Join-Path $root $relative))
    if (-not $resolved.StartsWith($root.TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw "Evidence escaped its root: $Key" }
    # Reject link/junction traversal, not only lexical ../ traversal.
    $current = $root
    foreach ($part in $relative.Split('/')) {
        $current = Join-Path $current $part
        if (Test-Path -LiteralPath $current) {
            if (((Get-Item -Force -LiteralPath $current).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Linked evidence is not allowed: $Key" }
        }
    }
    return $resolved
}

function File-Sha([string]$Key) {
    $path = Resolve-Key $Key
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing evidence: $Key" }
    $sha = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($sha -cnotmatch '^[0-9a-f]{64}$') { throw "Invalid SHA: $Key" }
    return $sha
}

function Json-Object([string]$Key) {
    $value = Get-Content -Raw -LiteralPath (Resolve-Key $Key) | ConvertFrom-Json
    if ($null -eq $value -or $value -isnot [PSCustomObject]) { throw "Expected JSON object: $Key" }
    return $value
}

function Member($Object,[string]$Name) {
    if ($null -eq $Object -or $Object -isnot [PSCustomObject] -or $null -eq $Object.PSObject.Properties[$Name]) { throw "Missing dossier field: $Name" }
    return ,$Object.PSObject.Properties[$Name].Value
}

function Require-True($Object,[string]$Name) {
    $value = Member $Object $Name
    if ($value -isnot [bool] -or -not $value) { throw "Explicit true boolean required: $Name" }
}

function Require-Number($Object,[string]$Name,[double]$Expected) {
    $value = Member $Object $Name
    if ($value -is [bool] -or $value -is [string] -or $value -isnot [ValueType] -or [double]::IsNaN([double]$value) -or [double]::IsInfinity([double]$value) -or [double]$value -ne $Expected) { throw "Wrong numeric field: $Name" }
}

function Require-Text($Object,[string]$Name,[string]$Expected) {
    if ((Member $Object $Name) -isnot [string] -or (Member $Object $Name) -cne $Expected) { throw "Wrong status/scope: $Name must be $Expected" }
}

function Empty-Findings($Object) {
    $value = Member $Object 'unresolved_findings'
    if ($value -isnot [Array] -or $value.Count -ne 0) { throw 'Unresolved findings are not empty.' }
}

function Hash-Map($Object) {
    if ($Object -isnot [PSCustomObject]) { throw 'Expected hash-map object.' }
    $map = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
    foreach ($property in $Object.PSObject.Properties) {
        if ($property.Value -isnot [string] -or $property.Value -cnotmatch '^[0-9a-fA-F]{64}$') { throw "Missing/invalid hash for $($property.Name)" }
        $map.Add($property.Name,$property.Value.ToLowerInvariant())
    }
    return ,$map
}

function Same-Hashes($Expected,$Current,[string]$Label) {
    if ($Expected.Count -ne $Current.Count) { throw "$Label keyset size changed." }
    foreach ($key in $Current.Keys) {
        if (-not $Expected.ContainsKey($key) -or $Expected[$key] -cne $Current[$key]) { throw "$Label key/hash mismatch: $key" }
    }
}

function Same-Set($Value,[string[]]$Expected,[string]$Label) {
    if ($Value -isnot [Array] -or $Value.Count -ne $Expected.Count) { throw "$Label coverage incomplete." }
    $set = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($entry in $Value) { if ($entry -isnot [string] -or -not $set.Add($entry)) { throw "$Label duplicate/invalid entry." } }
    foreach ($entry in $Expected) { if (-not $set.Contains($entry)) { throw "$Label missing $entry" } }
}

function Build-Catalog {
    # Explicit independent catalog mirrors reviewed publisher (same fixed keys), never executes/parses
    # its _asset_hashes(), nor accepts keys chosen by a mutable manifest/dossier.
    $keys = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $fixed = @(
        'res://art/maps/world_map_v14/source_contract.json','res://art/maps/world_map_v14/manifest.json',
        'res://data/maps/world_map_jianghu_layout_v14.tres','res://data/background_sets/world_map_jianghu_v14_streamed.tres',
        'res://data/scenes/world_map_jianghu_v14.tres','res://data/maps/world_map_jianghu_legacy_v12_scene.tres',
        'res://data/maps/openworld_bailu_ferry_layout.tres','res://data/maps/openworld_bailu_ferry_layout_before_v14_return_fix_20261002.tres',
        'res://tests/helpers/v14_alpha_domain_interval_proof.gd')
    foreach ($key in $fixed) { [void]$keys.Add($key) }
    foreach ($script in @('world/world_map_v14_contract','world/v14_modular_overlap','dev/publish_world_map_v14','autoload/scene_router','autoload/save_manager','field/field_walkable_controller','field/player','field/npc_node','ui/world_map_panel','ui/result_victory','ui/result_defeat','battle/battle_controller')) { [void]$keys.Add("res://scripts/$script.gd") }
    foreach ($script in @('build_world_map_native_full_v14','build_world_map_native_full_v14_sixth_draft','world_map_v14_sixth_native_surface','build_world_map_native_full_v14_seventh_draft','world_map_v14_seventh_native_surface','build_world_map_native_full_v14_eighth_draft','world_map_v14_eighth_native_surface','build_world_map_native_full_v14_ninth_draft','world_map_v14_ninth_native_surface')) { [void]$keys.Add("res://scripts/dev/$script.gd") }
    foreach ($directory in @('pine_sapling_small','tree_small_02','world_native_v14_ninth/rock_face_01')) { [void]$keys.Add("res://art/external/polyhaven/$directory/SOURCE.json") }
    foreach ($model in @('boulder_01/boulder_01_1k.gltf','shrub_03/shrub_03_1k.gltf','pine_sapling_small/pine_sapling_small_1k.gltf','tree_small_02/tree_small_02_1k.gltf','coastal_cliff_01/coastal_cliff_01_1k.gltf','world_native_v14_ninth/rock_face_01/rock_face_01_1k.gltf')) {
        $key = "res://art/external/polyhaven/$model"
        [void]$keys.Add($key)
        $gltf = Json-Object $key
        foreach ($collection in @('buffers','images')) {
            $items = Member $gltf $collection
            if ($items -isnot [Array] -or $items.Count -eq 0) { throw "Invalid glTF dependency collection: $key/$collection" }
            foreach ($item in $items) {
                $uri = Member $item 'uri'
                if ($uri -isnot [string]) { throw "Non-string glTF URI: $key" }
                if ($uri.StartsWith('data:',[StringComparison]::Ordinal)) { continue }
                if ([string]::IsNullOrWhiteSpace($uri) -or $uri.Contains(':') -or $uri.Contains('\') -or $uri.StartsWith('/') -or ($uri.Split('/') | Where-Object { $_ -eq '..' -or $_ -eq '.' -or $_ -eq '' })) { throw "Unsafe glTF URI: $key : $uri" }
                [void]$keys.Add($key.Substring(0,$key.LastIndexOf('/')+1) + $uri)
            }
        }
    }
    foreach ($directory in @('world_terrain_v14_sixth/rock_01','world_terrain_v14_sixth/leafy_grass','world_terrain_v14_sixth/forest_ground_04','world_terrain_v14_sixth/brown_mud_03','world_terrain_v14_eighth/aerial_grass_rock','world_terrain_v14_ninth/grass_ground')) {
        $base = "res://art/external/polyhaven/$directory"
        [void]$keys.Add("$base/SOURCE.json")
        $name = $directory.Substring($directory.LastIndexOf('/')+1)
        foreach ($channel in @('diff','nor_gl','arm')) { [void]$keys.Add("$base/${name}_${channel}_2k.jpg") }
    }
    $artRoot = Resolve-Key 'res://art/maps/world_map_v14'
    if (-not (Test-Path -LiteralPath $artRoot -PathType Container)) { throw 'Missing production art directory.' }
    foreach ($file in Get-ChildItem -LiteralPath $artRoot -Recurse -File -Force) {
        if ($file.Extension.ToLowerInvariant() -in @('.png','.json','.rf','.rgf','.res','.gdshader')) {
            [void]$keys.Add('res://' + $file.FullName.Substring($gameRoot.Length+1).Replace('\','/'))
        }
    }
    foreach ($relative in @('scripts/fetch_world_v14_sixth_pbr.ps1','scripts/fetch_world_v14_eighth_pbr.ps1','scripts/fetch_world_v14_ninth_pbr.ps1','docs/licensed-world-assets-polyhaven-20260929.md','assets/raw/external/polyhaven/README.md','assets/raw/external/polyhaven/rock_face_01/rock_face_01_1k.gltf','assets/raw/external/polyhaven/rock_face_01/rock_face_01.bin','assets/raw/external/polyhaven/rock_face_01/textures/rock_face_01_arm_1k.jpg','assets/raw/external/polyhaven/rock_face_01/textures/rock_face_01_diff_1k.jpg','assets/raw/external/polyhaven/rock_face_01/textures/rock_face_01_nor_gl_1k.jpg')) { [void]$keys.Add("repo://$relative") }
    $map = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
    foreach ($key in ($keys | Sort-Object -CaseSensitive)) { $map.Add($key,(File-Sha $key)) }
    if ($map['res://scripts/dev/publish_world_map_v14.gd'] -cne $publisherSha) { throw 'Publisher differs from independently reviewed pinned catalog. Review/update helper, do not auto-discover a changed catalog.' }
    if ($map['res://data/maps/world_map_jianghu_legacy_v12_scene.tres'] -cne $legacySha) { throw 'Immutable legacy SceneScript changed.' }
    return ,$map
}

function Validate-Dossiers($Catalog) {
    $qa = Json-Object $QaDossier
    $visual = Json-Object $VisualDossier
    foreach ($dossier in @($qa,$visual)) {
        Require-Number $dossier 'schema_version' 1
        Require-Number $dossier 'capture_iteration' 9
        Require-Text $dossier 'scope' 'FULL'
        Empty-Findings $dossier
        Same-Hashes (Hash-Map (Member $dossier 'asset_sha256')) $Catalog 'Dossier production asset'
    }
    Require-True $qa 'technical_approved'
    Require-True $visual 'visual_approved'
    Require-True $visual 'production_approved'
    Require-Text $visual 'verdict' 'PASS'
    $reviewer = Member $visual 'reviewer'
    if ($reviewer -isnot [string] -or [string]::IsNullOrWhiteSpace($reviewer)) { throw 'Named producer visual reviewer required.' }
    if ((Member $visual 'qa_dossier_sha256') -cne (File-Sha $QaDossier)) { throw 'Visual review does not bind actual QA dossier bytes.' }
    $authorization = Member $visual 'authorization'
    $authorizationPath = Member $authorization 'path'
    if ($authorizationPath -isnot [string] -or -not $authorizationPath.StartsWith('repo://docs/',[StringComparison]::Ordinal) -or -not $authorizationPath.EndsWith('.md',[StringComparison]::Ordinal)) { throw 'Producer authorization must link an actual repository docs Markdown file.' }
    if ((Member $authorization 'sha256') -cne (File-Sha $authorizationPath)) { throw 'Producer authorization document changed/missing.' }
    $source = Json-Object 'res://art/maps/world_map_v14/source_contract.json'
    Require-Number $source 'schema_version' 14
    Require-Text $source 'status' 'ART_ASSETS_READY'
}

function Validate-Production-Proofs($Catalog) {
    # Kept separate to make each evidence boundary inspectable.
    $qa = Json-Object $QaDossier
    $visual = Json-Object $VisualDossier
    $manifest = Json-Object 'res://art/maps/world_map_v14/manifest.json'
    $source = Json-Object 'res://art/maps/world_map_v14/source_contract.json'
    $size = Member $source 'world_size'
    if ($size -isnot [Array] -or $size.Count -ne 2 -or $size[0] -is [string] -or $size[1] -is [string] -or [double]$size[0] -ne 4608 -or [double]$size[1] -ne 3072) { throw 'Wrong source dimensions.' }
    Require-Number $manifest 'capture_iteration' 9
    Require-Text $manifest 'version' 'world_v14'
    Require-Text $manifest 'status' 'PRODUCTION_APPROVED'
    Require-True $manifest 'visual_approved'
    Require-True $manifest 'production_approved'
    $notReady = Member $manifest 'current_outputs_not_ready'
    if ($notReady -isnot [bool] -or $notReady) { throw 'Art outputs still not ready.' }
    Require-Text $manifest 'executed_builder_path' $mainBuilder
    if ((Member $manifest 'executed_builder_sha256').ToLowerInvariant() -cne $Catalog[$mainBuilder] -or $Catalog[$mainBuilder] -cne $Catalog[$ninthBuilder]) { throw 'Actual full capture builder is stale/not ninth source.' }
    Require-Text $manifest 'ninth_material_helper_path' $ninthHelper
    if ((Member $manifest 'ninth_material_helper_sha256').ToLowerInvariant() -cne $Catalog[$ninthHelper]) { throw 'Actual ninth capture helper changed.' }
    $actual = Hash-Map (Member $qa 'actual_sources')
    $expectedSources = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
    foreach ($key in @($mainBuilder,$ninthBuilder,$ninthHelper,'res://scripts/field/field_walkable_controller.gd','res://scripts/world/v14_modular_overlap.gd',$fullTest,'res://tests/helpers/v14_alpha_domain_interval_proof.gd')) { $expectedSources.Add($key,(File-Sha $key)) }
    Same-Hashes $actual $expectedSources 'Actual executed source'
    $runs = Member $qa 'runs'
    $gpuOutput = ''
    $resultEvidence = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
    foreach ($mode in @('headless','gpu')) {
        $run = Member $runs $mode
        Require-Text $run 'scope' 'FULL'
        Require-Number $run 'exit_code' 0
        Require-Number $run 'failures' 0
        $checks = Member $run 'checks'
        if ($checks -is [bool] -or $checks -is [string] -or $checks -isnot [ValueType] -or [double]::IsInfinity([double]$checks) -or [double]::IsNaN([double]$checks) -or [double]$checks -le 0 -or [double]$checks -ne [Math]::Floor([double]$checks)) { throw "No real completed checks: $mode" }
        Require-Text $run 'script_path' $fullTest
        if ((Member $run 'script_sha256') -cne $expectedSources[$fullTest]) { throw "Wrong actual full test SHA: $mode" }
        $logKey = Member $run 'log_path'
        if ($logKey -isnot [string] -or -not $logKey.StartsWith('res://build/',[StringComparison]::Ordinal) -or -not $logKey.EndsWith('.log',[StringComparison]::Ordinal)) { throw "Invalid raw log: $mode" }
        if ((Member $run 'log_sha256') -cne (File-Sha $logKey)) { throw "Missing/stale raw run log: $mode" }
        $resultEvidence.Add($logKey,(File-Sha $logKey))
        $stderrKey = Member $run 'stderr_path'
        if ($stderrKey -isnot [string] -or -not $stderrKey.StartsWith('res://build/',[StringComparison]::Ordinal) -or -not $stderrKey.EndsWith('.log',[StringComparison]::Ordinal)) { throw "Missing raw stderr log: $mode" }
        if ((Member $run 'stderr_sha256') -cne (File-Sha $stderrKey)) { throw "Stale stderr: $mode" }
        $resultEvidence.Add($stderrKey,(File-Sha $stderrKey))
        $stdout = Get-Content -Raw -LiteralPath (Resolve-Key $logKey)
        $stderr = Get-Content -Raw -LiteralPath (Resolve-Key $stderrKey)
        if (($stdout + "`n" + $stderr) -match '(?m)^\s*(?:SCRIPT ERROR:|SHADER ERROR:|ERROR:)') { throw "Engine errors retained in $mode logs; cannot approve." }
        $resultKey = Member $run 'result_path'
        if ($resultKey -isnot [string] -or -not $resultKey.StartsWith('res://build/',[StringComparison]::Ordinal) -or -not $resultKey.EndsWith('/result.json',[StringComparison]::Ordinal)) { throw "Wrong full-suite raw result path: $mode" }
        if ((Member $run 'result_sha256') -cne (File-Sha $resultKey)) { throw "Stale raw result: $mode" }
        $resultEvidence.Add($resultKey,(File-Sha $resultKey))
        $result = Json-Object $resultKey
        Require-Text $result 'scope' 'FULL_WORLD_MAP_PRODUCTION'
        Require-Text $result 'stage' 'candidate-before-cutover'
        Require-Number $result 'capture_iteration' 9
        Require-Number $result 'failures' 0
        Require-Number $result 'checks' ([double]$checks)
        Require-True $result 'player_saves_unchanged'
        Require-True $result 'schema_ready'
        Require-Number $result 'actual_portal_input_count' 16
        Require-Number $result 'actual_open_seam_input_count' 12
        $outputDir = Member $result 'output_dir'
        if ($outputDir -isnot [string] -or $outputDir -cne $resultKey.Substring(0,$resultKey.LastIndexOf('/')+1)) { throw "Result/output location mismatch: $mode" }
        if ($mode -eq 'headless') { Require-Text $result 'renderer' 'headless' }
        elseif ((Member $result 'renderer') -isnot [string] -or (Member $result 'renderer') -eq 'headless') { throw 'GPU full result is not a GPU run.' }
        $completionMatches = [regex]::Matches($stdout,'(?m)^\[WorldV14Production\] stage=candidate-before-cutover checks=(\d+) failures=(\d+) captures=(\d+) fullfoot_centers=(\d+) portals_input=(\d+) seams_input=(\d+) output=([^\r\n]+)\r?$')
        if ($completionMatches.Count -ne 1 -or [long]$completionMatches[0].Groups[1].Value -ne [long]$checks -or [long]$completionMatches[0].Groups[2].Value -ne 0 -or [long]$completionMatches[0].Groups[3].Value -ne [long](Member $result 'screenshots') -or [long]$completionMatches[0].Groups[4].Value -ne [long](Member $result 'full_foot_centers') -or [long]$completionMatches[0].Groups[5].Value -ne 16 -or [long]$completionMatches[0].Groups[6].Value -ne 12 -or $completionMatches[0].Groups[7].Value -cne $outputDir) { throw "Actual full-suite completion log/result mismatch: $mode" }
        if ($mode -eq 'gpu') { $gpuOutput = $outputDir }
    }
    $coverage = Member $qa 'coverage'
    $regions = @(); foreach ($row in 0..2) { foreach ($col in 0..2) { $regions += "r${row}c${col}" } }
    Same-Set (Member $coverage 'regions') $regions 'Nine regions'
    Same-Set (Member $coverage 'portal_ids') $portalIds 'Sixteen portals'
    Same-Set (Member $coverage 'categories') $categories 'Full image categories'
    $images = Hash-Map (Member $qa 'images_sha256')
    if ($images.Count -lt 9) { throw 'Full review must include raw screenshots across all nine regions.' }
    $actualImages = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
    foreach ($file in Get-ChildItem -LiteralPath (Resolve-Key $gpuOutput.TrimEnd('/')) -File -Filter '*.png') {
        $imageKey = $gpuOutput + $file.Name
        $actualImages.Add($imageKey,(File-Sha $imageKey))
    }
    Same-Hashes $images $actualImages 'Complete actual GPU screenshot directory'
    Require-Number (Json-Object (Member (Member $runs 'gpu') 'result_path')) 'screenshots' $images.Count
    foreach ($key in $images.Keys) {
        if (-not $key.StartsWith('res://build/',[StringComparison]::Ordinal) -or -not $key.EndsWith('.png',[StringComparison]::Ordinal)) { throw "Not a raw Field screenshot: $key" }
        if ($images[$key] -cne (File-Sha $key)) { throw "Raw screenshot missing/changed: $key" }
        $stream = [IO.File]::OpenRead((Resolve-Key $key))
        try { $signature = New-Object byte[] 8; if ($stream.Read($signature,0,8) -ne 8 -or [BitConverter]::ToString($signature) -cne '89-50-4E-47-0D-0A-1A-0A') { throw "Not PNG bytes: $key" } } finally { $stream.Dispose() }
    }
    Same-Hashes (Hash-Map (Member $visual 'images_sha256')) $images 'Producer full image'
    $verdicts = Member $visual 'image_verdicts'
    if ($verdicts -isnot [PSCustomObject] -or @($verdicts.PSObject.Properties).Count -ne $images.Count) { throw 'Every raw screenshot needs a separate producer verdict.' }
    foreach ($key in $images.Keys) { Require-Text $verdicts $key 'PASS' }
    return [ordered]@{ qa_dossier_sha256 = File-Sha $QaDossier; visual_dossier_sha256 = File-Sha $VisualDossier; authorization_path = (Member (Member $visual 'authorization') 'path'); authorization_sha256 = (Member (Member $visual 'authorization') 'sha256'); images_sha256 = $images; run_evidence_sha256 = $resultEvidence; test_script_path = $fullTest; test_script_sha256 = $expectedSources[$fullTest] }
}

$catalog = Build-Catalog
if ([string]::IsNullOrWhiteSpace($QaDossier) -xor [string]::IsNullOrWhiteSpace($VisualDossier)) { throw 'Supply both QA and visual dossiers, or neither for catalog-only audit.' }
$proof = $null
if (-not [string]::IsNullOrWhiteSpace($QaDossier)) {
    Validate-Dossiers $catalog
    $proof = Validate-Production-Proofs $catalog
}
if ($Approve -and $null -eq $proof) { throw 'Approve requires genuine FULL QA and separate producer visual dossiers.' }

if (-not $Approve) {
    [ordered]@{ mode = 'AUDIT_ONLY'; capture_approval = $(if ($null -eq $proof) { 'NOT_REVIEWED' } else { 'DOSSIERS_VALIDATED_NOT_WRITTEN' }); publisher_sha256 = $publisherSha; key_count = $catalog.Count; asset_sha256 = $catalog } | ConvertTo-Json -Depth 8
    return
}

# Re-read every asset and proof immediately before writing; owner changes in the
# validation window invalidate acceptance. This is not a substitute for freezing.
Same-Hashes $catalog (Build-Catalog) 'Final production asset'
if ((File-Sha $QaDossier) -cne $proof.qa_dossier_sha256 -or (File-Sha $VisualDossier) -cne $proof.visual_dossier_sha256 -or (File-Sha $proof.authorization_path) -cne $proof.authorization_sha256) { throw 'Dossier/authorization changed during validation.' }
foreach ($key in $proof.images_sha256.Keys) { if ((File-Sha $key) -cne $proof.images_sha256[$key]) { throw "Screenshot changed during validation: $key" } }
foreach ($key in $proof.run_evidence_sha256.Keys) { if ((File-Sha $key) -cne $proof.run_evidence_sha256[$key]) { throw "Raw run evidence changed during validation: $key" } }
if ((File-Sha $proof.test_script_path) -cne $proof.test_script_sha256) { throw 'Actual test source changed during validation.' }
$destination = Resolve-Key $approvalKey
if (Test-Path -LiteralPath $destination) { throw 'Acceptance already exists; refusing overwrite. Producer must explicitly archive/review it separately.' }
$acceptance = [ordered]@{ version = 14; capture_iteration = 9; scope = 'FULL'; technical_approved = $true; visual_approved = $true; asset_sha256 = $catalog; independent_tool_sha256 = (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash.ToLowerInvariant(); proof = $proof; approved_at_utc = [DateTime]::UtcNow.ToString('o'); not_activated = $true }
# CreateNew protects against racing approvals; no .partial/manifest/player writes.
$bytes = [Text.UTF8Encoding]::new($false).GetBytes(($acceptance | ConvertTo-Json -Depth 12))
$output = [IO.File]::Open($destination,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try { $output.Write($bytes,0,$bytes.Length); $output.Flush($true) } finally { $output.Dispose() }
Write-Output 'WORLD_V14_ACCEPTANCE_WRITTEN_NOT_ACTIVATED'
