param()
$ErrorActionPreference = 'Stop'
$isolatedRoot = [IO.Path]::GetFullPath($PSScriptRoot)
$gameRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$prepared = Get-Content -LiteralPath (Join-Path $isolatedRoot 'prepared2.json') -Raw | ConvertFrom-Json
if ($prepared.scope -ne 'PREPARED2_CITY_WALK_ISOLATED_IMPORT_NOT_APPROVED' -or $prepared.entries.Count -ne 2) { throw 'Unexpected preparation contract' }
$rows = @()
foreach ($row in $prepared.entries) {
    if ($row.path -notmatch '^res://art/maps/luoyang_city_revision(_retry2_20261015|_v1_20261015)/ch4_s[23]_[a-z_]+/walk[.]png$') { throw 'Unexpected resource path' }
    $relative = $row.path.Substring(6)
    $source = [IO.Path]::GetFullPath((Join-Path $gameRoot $relative))
    $destination = [IO.Path]::GetFullPath((Join-Path $isolatedRoot $relative))
    if (-not $source.StartsWith($gameRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or -not $destination.StartsWith($isolatedRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Preparation path escaped its explicit roots' }
    if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne $row.sha256) { throw "Published source PNG changed: $($row.id)" }
    $manifest = [IO.Path]::GetFullPath((Join-Path $repoRoot $row.publication_manifest_path))
    if (-not $manifest.StartsWith($repoRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or (Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash -ne $row.publication_manifest_sha256) { throw 'Publication manifest changed' }
    if (Test-Path -LiteralPath $destination) {
        if ((Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -ne $row.sha256) { throw 'Existing isolated PNG differs; refusing overwrite' }
    } else {
        $parentDirectory = [IO.Path]::GetDirectoryName($destination)
        if (-not (Test-Path -LiteralPath $parentDirectory)) { New-Item -ItemType Directory -Path $parentDirectory | Out-Null }
        Copy-Item -LiteralPath $source -Destination $destination
    }
    if ((Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -ne $row.sha256 -or (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne $row.sha256) { throw 'Source/copy exact byte proof failed' }
    $rows += [pscustomobject]@{ id=$row.id; source=$source; isolated_path=$destination; sha256=(Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash; bytes=(Get-Item -LiteralPath $destination).Length }
}
[pscustomobject]@{ scope='SOURCE_COPY_ONLY_NOT_ENGINE_IMPORT'; passed=$true; rows=$rows; no_game_imports_written=$true } | ConvertTo-Json -Depth 4
