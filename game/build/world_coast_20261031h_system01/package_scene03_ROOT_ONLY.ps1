[CmdletBinding()]
param([switch]$Publish)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$workspace = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$utf8 = New-Object System.Text.UTF8Encoding($false)
$newSceneUri = 'res://build/world_coast_20261031h_system01/world_v16_scene03.tres'
$oldSceneUri = 'res://build/world_coast_20261031h_system01/world_v16_scene02.tres'
$oldManifestUri = 'res://art/maps/world_coast_20261031h/candidate02/runtime_contract.json'
$newManifestUri = 'res://art/maps/world_coast_20261031h/candidate02/runtime_contract03.json'
$proofUri = 'res://art/maps/world_coast_20261031h/candidate02/runtime_contract03_diff_proof.json'
function Resolve-Resource([string]$Uri) {
    if (-not $Uri.StartsWith('res://') -or $Uri.Contains('..')) { throw 'Only fixed project resource paths are accepted.' }
    return [System.IO.Path]::GetFullPath((Join-Path $workspace ($Uri.Substring(6).Replace('/', [System.IO.Path]::DirectorySeparatorChar))))
}
function Get-Sha([string]$Path) { return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant() }
function Get-TextSha([string]$Text) {
    $hash = [System.Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($hash.ComputeHash($utf8.GetBytes($Text))).Replace('-', '').ToLowerInvariant() }
    finally { $hash.Dispose() }
}
$pins = [ordered]@{
    $oldManifestUri = 'f4c592117bfc2a1350674f2b26f79b633e82c6bbc5ee00d42b4d79d06635db89'
    $oldSceneUri = '2efadd3d8e7681877b69acbf9a41c2e4cb9d3f377f410506035d9142484c675b'
    'res://build/world_coast_20261031h_system01/world_v16_layout02.tres' = '231e6221b774dac7564ce70d54bea14c559087d397e8dc2c7015c3886dd33822'
    'res://build/world_coast_20261031h_system01/world_v16_stream02.tres' = 'b702d0632dc50c1e98b12d925110332dafb122fecf4fa41ca5ada8203fe8fe3f'
    'res://scripts/domain/scene_script.gd' = 'e01a01ba69d13492441960972109d32ba0c62b1e0e881c5b805b11b73cb41bef'
    'res://data/dialogs/ch7_route_choice.tres' = '46d010f799ed78ae29a0f31f2cf88f06038ba00dba57e5453154e5f0bc76273b'
}
foreach ($uri in $pins.Keys) {
    if ((Get-Sha (Resolve-Resource $uri)) -ne $pins[$uri]) { throw "Frozen source differs: $uri" }
}
foreach ($uri in @($newManifestUri, $proofUri)) {
    if (Test-Path -LiteralPath (Resolve-Resource $uri)) { throw "NEW output already exists; no overwrite: $uri" }
}
function Get-SceneFields([string]$Path) {
    $text = [System.IO.File]::ReadAllText($Path, $utf8)
    $start = $text.LastIndexOf('[resource]', [StringComparison]::Ordinal)
    if ($start -lt 0) { throw "Missing Scene resource block: $Path" }
    $refs = @{}
    foreach ($match in [regex]::Matches($text, '\[ext_resource\s+type="[^"]+"\s+path="([^"]+)"\s+id="([^"]+)"\]')) {
        $refs[$match.Groups[2].Value] = $match.Groups[1].Value
    }
    $fields = [ordered]@{}
    foreach ($line in ($text.Substring($start) -split '\r?\n')) {
        if ($line -notmatch '^([^=]+?)\s*=\s*(.*)$') { continue }
        $key = $Matches[1].Trim(); $value = $Matches[2].Trim()
        if ($fields.Contains($key)) { throw "Duplicate Scene field: $key" }
        if ($value -match '^ExtResource\("([^"]+)"\)$') { $value = 'RESOURCE:' + $refs[$Matches[1]] }
        $fields[$key] = $value
    }
    return ,$fields
}
$newScenePath = Resolve-Resource $newSceneUri
$oldFields = Get-SceneFields (Resolve-Resource $oldSceneUri)
$newFields = Get-SceneFields $newScenePath
if (($oldFields.Keys -join '|') -cne ($newFields.Keys -join '|')) { throw 'Scene stored field set/order differs.' }
$scalarFields = @()
foreach ($key in $oldFields.Keys) {
    if ($key -in @('map_layout', 'streamed_background')) { continue }
    if ($oldFields[$key] -cne $newFields[$key]) { throw "Scene scalar/resource semantics differ: $key" }
    $scalarFields += $key
}
if ($newFields.map_layout -cne 'RESOURCE:res://build/world_coast_20261031h_system01/world_v16_layout02.tres') { throw 'Scene03 layout is not the exact external layout02 resource.' }
if ($newFields.streamed_background -cne 'RESOURCE:res://build/world_coast_20261031h_system01/world_v16_stream02.tres') { throw 'Scene03 stream is not the exact external stream02 resource.' }
$newSceneText = [System.IO.File]::ReadAllText($newScenePath, $utf8)
if ($newSceneText.Contains('[sub_resource')) { throw 'Thin Scene03 must not embed subresources.' }
$newSceneSha = Get-Sha $newScenePath
$oldManifestPath = Resolve-Resource $oldManifestUri
$oldText = [System.IO.File]::ReadAllText($oldManifestPath, $utf8)
$oldData = $oldText | ConvertFrom-Json
if ($oldData.scene_path -cne $oldSceneUri -or $oldData.scene_sha256 -cne $pins[$oldSceneUri]) { throw 'Original manifest Scene02 binding differs.' }
$pathPattern = '("scene_path"\s*:\s*)"' + [regex]::Escape($oldSceneUri) + '"'
$shaPattern = '("scene_sha256"\s*:\s*)"' + $pins[$oldSceneUri] + '"'
if ([regex]::Matches($oldText, $pathPattern).Count -ne 1 -or [regex]::Matches($oldText, $shaPattern).Count -ne 1) { throw 'Exactly one source scene path/SHA pair required.' }
$newText = [regex]::Replace($oldText, $pathPattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $m.Groups[1].Value + '"' + $newSceneUri + '"' })
$newText = [regex]::Replace($newText, $shaPattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $m.Groups[1].Value + '"' + $newSceneSha + '"' })
$newData = $newText | ConvertFrom-Json
$changedKeys = @()
foreach ($property in $oldData.PSObject.Properties) {
    $key = $property.Name
    $before = ConvertTo-Json -InputObject $property.Value -Depth 100 -Compress
    $after = ConvertTo-Json -InputObject $newData.$key -Depth 100 -Compress
    if ($before -cne $after) { $changedKeys += $key }
}
if ((($changedKeys | Sort-Object) -join '|') -cne 'scene_path|scene_sha256') { throw 'Manifest mutation exceeded the two allowed Scene binding fields.' }
$inverse = $newText.Replace('"' + $newSceneUri + '"', '"' + $oldSceneUri + '"').Replace('"' + $newSceneSha + '"', '"' + $pins[$oldSceneUri] + '"')
if ((Get-TextSha $inverse) -cne $pins[$oldManifestUri]) { throw 'Exact byte-inverse does not recover the original manifest.' }
$newManifestSha = Get-TextSha $newText
$proof = [ordered]@{
    schema = 'WORLD_COAST_V16_SCENE03_METADATA_ONLY_PROOF_1'
    old_manifest = @{ path=$oldManifestUri; sha256=$pins[$oldManifestUri] }
    new_manifest = @{ path=$newManifestUri; sha256=$newManifestSha }
    allowed_changed_top_keys = @('scene_path','scene_sha256')
    actual_changed_top_keys = $changedKeys
    inverse_after_exact_two_field_restore_sha256 = Get-TextSha $inverse
    source_graph_changed = $false
    layout_stream_RF_mesh_NAV_PNG_changed = $false
    no_engine_or_image_processing = $true
    old_scene = @{ path=$oldSceneUri; sha256=$pins[$oldSceneUri] }
    new_thin_scene = @{ path=$newSceneUri; sha256=$newSceneSha; bytes=(Get-Item -LiteralPath $newScenePath).Length; embedded_subresources=0 }
    compared_scene_scalar_and_dialog_script_fields = $scalarFields
    external_layout = @{ path='res://build/world_coast_20261031h_system01/world_v16_layout02.tres'; sha256=$pins['res://build/world_coast_20261031h_system01/world_v16_layout02.tres'] }
    external_stream = @{ path='res://build/world_coast_20261031h_system01/world_v16_stream02.tres'; sha256=$pins['res://build/world_coast_20261031h_system01/world_v16_stream02.tres'] }
    unchanged_source_pins = $pins
    packager_sha256 = Get-Sha $PSCommandPath
    standalone_ResourceLoader_path_identity = 'REQUIRES_ROOT_HEADLESS_BIND; text-only proof does not claim runtime identity'
    production_approved = $false
}
if ($Publish) {
    [System.IO.File]::WriteAllBytes((Resolve-Resource $newManifestUri), $utf8.GetBytes($newText))
    [System.IO.File]::WriteAllBytes((Resolve-Resource $proofUri), $utf8.GetBytes((ConvertTo-Json -InputObject $proof -Depth 100) + "`n"))
    if ((Get-Sha (Resolve-Resource $newManifestUri)) -cne $newManifestSha) { throw 'New metadata write verification failed; partial NEW outputs retained.' }
    foreach ($uri in $pins.Keys) { if ((Get-Sha (Resolve-Resource $uri)) -cne $pins[$uri]) { throw "Frozen source changed during packaging: $uri" } }
    Write-Output "SCENE03_METADATA_COMPLETE manifest_sha256=$newManifestSha scene_sha256=$newSceneSha"
    Write-Output "proof_sha256=$(Get-Sha (Resolve-Resource $proofUri))"
} else {
    Write-Output "SCENE03_METADATA_DRY_READONLY_PASS future_manifest_sha256=$newManifestSha scene_sha256=$newSceneSha"
}
