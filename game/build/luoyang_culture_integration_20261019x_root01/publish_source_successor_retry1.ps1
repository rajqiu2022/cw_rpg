param([Parameter(Mandatory=$true)][string]$ClosurePath)
$ErrorActionPreference = 'Stop'
$projectRoot = 'F:/Code/RPG_GAME/game'
$evidenceRoot = "$projectRoot/build/luoyang_culture_integration_20261019x_root01"
$beforeRoot = "$evidenceRoot/before"
$stageRoot = "$evidenceRoot/staged_retry1"
$fieldPath = 'res://scripts/field/field_walkable_controller.gd'
$templePath = 'res://scripts/city/luoyang_temple_assembly_20261016.gd'
$oldFieldSha = '34081bd719470b53aa4b418e1772d7a11c2a6fe0573d735537ce8d58338a19b9'
$ids = @('ch4_s0_luoyang_gate','ch4_s1_luoyang_yamen','ch4_s2_canal_docks','ch4_s3_luoyang_market')
function LocalPath([string]$path) {
    if (-not $path.StartsWith('res://') -or $path.Contains('..')) { throw "Unsafe source path: $path" }
    return "$projectRoot/" + $path.Substring(6)
}
function Sha([string]$path) { return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() }
function JsonText($value) { return ConvertTo-Json -InputObject $value -Depth 100 -Compress }
function WriteJson([string]$path,$value) {
    [System.IO.File]::WriteAllText($path,(ConvertTo-Json -InputObject $value -Depth 100)+"`n",[System.Text.UTF8Encoding]::new($false))
}
if (Test-Path -LiteralPath $stageRoot) { throw 'Staging already exists; preserve it and use an explicit successor, not overwrite.' }
New-Item -ItemType Directory -Path $stageRoot | Out-Null
$closure = Get-Content -LiteralPath $ClosurePath -Raw | ConvertFrom-Json -AsHashtable
if (-not $closure.source_sha256 -or $closure.source_sha256.Count -lt 30) { throw 'Expected explicit complete integration source map.' }
foreach ($path in $closure.source_sha256.Keys) {
    if ((Sha (LocalPath $path)) -cne $closure.source_sha256[$path].ToLowerInvariant()) { throw "Frozen integration source changed: $path" }
}
$newFieldSha = Sha (LocalPath $fieldPath)
if ($newFieldSha -ceq $oldFieldSha) { throw 'No Field integration source change.' }
$oldTemple = [System.IO.File]::ReadAllText("$beforeRoot/temple_helper.gd.source")
if ((Sha (LocalPath $templePath)) -cne (Sha "$beforeRoot/temple_helper.gd.source")) { throw 'Temple changed after backup.' }
$oldBinding = Get-Content -LiteralPath "$beforeRoot/temple_binding.json" -Raw | ConvertFrom-Json -AsHashtable
$newBinding = Get-Content -LiteralPath "$beforeRoot/temple_binding.json" -Raw | ConvertFrom-Json -AsHashtable
$newBinding.id = 'luoyang_temple_culture_field_source_successor_20261019x'
$newBinding.source_delta[$fieldPath] = $newFieldSha
foreach ($path in $closure.source_sha256.Keys) { $newBinding.source_delta[$path] = $closure.source_sha256[$path].ToLowerInvariant() }
$newBinding.culture_source_successor = [ordered]@{
    prior_path='res://build/luoyang_culture_integration_20261019x_root01/before/temple_binding.json'
    prior_sha256=(Sha "$beforeRoot/temple_binding.json")
    changed_field_old_sha256=$oldFieldSha
    changed_field_new_sha256=$newFieldSha
    geometry_assets_publication_unchanged=$true
    scope='Explicit Field and cultural source closure only; no new temple geometry proof'
}
$bindingRelative = 'res://build/luoyang_culture_integration_20261019x_root01/temple_binding_retry1.json'
if (Test-Path -LiteralPath "$evidenceRoot/temple_binding_retry1.json") { throw 'Preserve prior retry1 binding.' }
WriteJson "$evidenceRoot/temple_binding_retry1.json" $newBinding
$newBindingSha = Sha "$evidenceRoot/temple_binding_retry1.json"
$oldBindLine = 'const BIND_PATH="res://build/luoyang_layout_quest_20261018t_layout_source01/runtime_v2/temple_successor_binding_v2.json"'
$oldShaLine = 'const BIND_SHA="83578bbe72adf19ea1b7139952d3b3675ae27087fe0bb433db0439c1e60d93ae"'
if (-not $oldTemple.Contains($oldBindLine) -or -not $oldTemple.Contains($oldShaLine)) { throw 'Unexpected prior helper template.' }
$newTemple = $oldTemple.Replace($oldBindLine,"const BIND_PATH=`"$bindingRelative`"").Replace($oldShaLine,"const BIND_SHA=`"$newBindingSha`"")
if ($newTemple.Replace("const BIND_PATH=`"$bindingRelative`"",$oldBindLine).Replace("const BIND_SHA=`"$newBindingSha`"",$oldShaLine) -cne $oldTemple) { throw 'Helper inverse differs outside two constants.' }
[System.IO.File]::WriteAllText("$stageRoot/temple_helper.gd",$newTemple,[System.Text.UTF8Encoding]::new($false))
$newTempleSha = Sha "$stageRoot/temple_helper.gd"
$indexText = [System.IO.File]::ReadAllText("$beforeRoot/bundle_index.gd.source")
$rows = @()
foreach ($id in $ids) {
    $beforeFile = "$beforeRoot/${id}_manifest.json"
    $target = "$projectRoot/data/maps/luoyang_layout_bundle_20261018t_retry2/$id/manifest.json"
    if ((Sha $target) -cne (Sha $beforeFile)) { throw "Manifest changed before controlled successor: $id" }
    $prior = Get-Content -LiteralPath $beforeFile -Raw | ConvertFrom-Json -AsHashtable
    $next = Get-Content -LiteralPath $beforeFile -Raw | ConvertFrom-Json -AsHashtable
    if ($id -ceq 'ch4_s1_luoyang_yamen') {
        # The unchanged Yamen runtime collector did not previously include Field.
        # Add it explicitly, while retaining its historical publication pins.
        if ($prior.legacy_source_sha256.Contains($fieldPath) -or $prior.publication_source_first[$fieldPath] -cne $oldFieldSha -or $prior.publication_source_final[$fieldPath] -cne $oldFieldSha) { throw 'Unexpected Yamen prior collector/publication domain.' }
    } elseif ($prior.legacy_source_sha256[$fieldPath] -cne $oldFieldSha) { throw "Prior Field pin not approved: $id" }
    $deltas = [ordered]@{}
    $additions = [ordered]@{}
    $updates = [ordered]@{}
    $updates[$fieldPath] = $newFieldSha
    foreach ($path in $closure.source_sha256.Keys) { $updates[$path] = $closure.source_sha256[$path].ToLowerInvariant() }
    # Only return targets previously owned the live temple helper closure.
    if ($prior.legacy_source_sha256.Contains($templePath)) { $updates[$templePath] = $newTempleSha; $updates[$bindingRelative] = $newBindingSha }
    foreach ($path in $updates.Keys) {
        if ($prior.legacy_source_sha256.Contains($path)) {
            $old = $prior.legacy_source_sha256[$path]
            if ($old -cne $updates[$path]) {
                if ($path -cne $fieldPath -and $path -cne $templePath) { throw "Unapproved existing leaf change: $path" }
                $deltas[$path] = [ordered]@{old_sha256=$old;new_sha256=$updates[$path]}
            }
        } else { $additions[$path] = $updates[$path] }
        $next.legacy_source_sha256[$path] = $updates[$path]
    }
    $next.culture_integration_successor = [ordered]@{schema='EXPLICIT_CULTURE_SOURCE_SUCCESSOR_20261019X';prior_manifest_path="res://build/luoyang_culture_integration_20261019x_root01/before/${id}_manifest.json";prior_manifest_sha256=(Sha $beforeFile);source_delta=$deltas;added_source_sha256=$additions;geometry_and_publication_unchanged=$true}
    $inverse = (JsonText $next) | ConvertFrom-Json -AsHashtable
    [void]$inverse.Remove('culture_integration_successor')
    foreach ($path in $deltas.Keys) { $inverse.legacy_source_sha256[$path] = $deltas[$path].old_sha256 }
    foreach ($path in $additions.Keys) { [void]$inverse.legacy_source_sha256.Remove($path) }
    if ((JsonText $inverse) -cne (JsonText $prior)) { throw "Whole semantic inverse differs: $id" }
    foreach ($artifact in $prior.artifacts.Keys) { if ((Sha (LocalPath $artifact)) -cne $prior.artifacts[$artifact]) { throw "Historical native artifact changed: $artifact" } }
    $stagedFile = "$stageRoot/${id}_manifest.json"
    WriteJson $stagedFile $next
    $oldManifestSha = Sha $beforeFile
    $newManifestSha = Sha $stagedFile
    if (-not $indexText.Contains($oldManifestSha)) { throw "Index did not own prior manifest: $id" }
    $indexText = $indexText.Replace($oldManifestSha,$newManifestSha)
    $rows += [ordered]@{id=$id;prior_sha256=$oldManifestSha;new_sha256=$newManifestSha;source_delta=$deltas;added_source_sha256=$additions;whole_semantic_inverse=$true;native_artifacts_same=$true}
}
[System.IO.File]::WriteAllText("$stageRoot/bundle_index.gd",$indexText,[System.Text.UTF8Encoding]::new($false))
WriteJson "$evidenceRoot/source_successor_plan_retry1.json" ([ordered]@{scope='SOURCE_METADATA_ONLY_NO_GEOMETRY_RECOMPUTE';rows=$rows;temple_binding_path=$bindingRelative;temple_binding_sha256=$newBindingSha;temple_helper_sha256=$newTempleSha;index_sha256=(Sha "$stageRoot/bundle_index.gd");deployed=$false})
Write-Output (JsonText ([ordered]@{staged=$true;rows=$rows.Count;temple_helper_sha256=$newTempleSha;index_sha256=(Sha "$stageRoot/bundle_index.gd");deployed=$false}))
