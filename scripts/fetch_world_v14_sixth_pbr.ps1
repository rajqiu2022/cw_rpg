param([ValidateSet('rock_01','leafy_grass','forest_ground_04','brown_mud_03')][string[]]$Assets = @('rock_01','leafy_grass','forest_ground_04','brown_mud_03'))

$ErrorActionPreference = 'Stop'
$assetRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../game/art/external/polyhaven/world_terrain_v14_sixth'))
$agentName = 'CloudShadowRPG-AssetPipeline/1.0 (+https://github.com/rajqiu2022/cw_rpg)'
$physicalWidths = @{ rock_01 = 1.5; leafy_grass = 2.0; forest_ground_04 = 3.2; brown_mud_03 = 1.3 }
$channelKeys = @{ diff = 'Diffuse'; nor_gl = 'nor_gl'; arm = 'arm' }

foreach ($asset in $Assets) {
    $directory = [IO.Path]::GetFullPath((Join-Path $assetRoot $asset))
    if (-not $directory.StartsWith($assetRoot + [IO.Path]::DirectorySeparatorChar)) { throw 'Asset path escaped approved directory' }
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    $api = 'https://api.polyhaven.com/files/' + $asset
    $apiText = (& curl.exe --fail --silent --show-error --user-agent $agentName $api) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw "Official files API failed: $asset" }
    $files = $apiText | ConvertFrom-Json
    $records = @()
    foreach ($channel in @('diff','nor_gl','arm')) {
        $file = $files.($channelKeys[$channel]).'2k'.jpg
        if ($null -eq $file) { throw "Official 2k JPG channel missing: $asset $channel" }
        $uri = [Uri]$file.url
        if ($uri.Scheme -ne 'https' -or $uri.Host -ne 'dl.polyhaven.org') { throw 'Unexpected asset host' }
        $filename = [IO.Path]::GetFileName($uri.AbsolutePath)
        if ($filename -ne ($asset + '_' + $channel + '_2k.jpg')) { throw 'Official filename does not match selected channel' }
        $destination = Join-Path $directory $filename
        $expected = ([string]$file.md5).ToLowerInvariant()
        if (Test-Path -LiteralPath $destination) {
            if ((Get-FileHash -LiteralPath $destination -Algorithm MD5).Hash.ToLowerInvariant() -ne $expected) { throw "Existing asset differs; refusing overwrite: $destination" }
        } else {
            $partial = $destination + '.fetch-20261002.partial'
            if (Test-Path -LiteralPath $partial) { throw "Prior partial retained; refusing overwrite: $partial" }
            & curl.exe --fail --location --silent --show-error --retry 2 --retry-delay 1 --max-time 180 --user-agent $agentName --output $partial $uri.AbsoluteUri
            if ($LASTEXITCODE -ne 0) { throw "Download failed, partial retained: $partial" }
            if ((Get-FileHash -LiteralPath $partial -Algorithm MD5).Hash.ToLowerInvariant() -ne $expected -or (Get-Item -LiteralPath $partial).Length -ne [long]$file.size) { throw "Official MD5/size mismatch; partial retained: $partial" }
            Move-Item -LiteralPath $partial -Destination $destination
        }
        $records += [ordered]@{ channel = $channel; resolution = '2k'; format = 'jpg'; url = $uri.AbsoluteUri; path = ('res://art/external/polyhaven/world_terrain_v14_sixth/' + $asset + '/' + $filename); size = (Get-Item -LiteralPath $destination).Length; official_md5 = $expected; md5_verified = $true; sha256 = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant(); color_space = $(if ($channel -eq 'diff') { 'sRGB' } else { 'linear data' }) }
        Write-Output ("VERIFIED {0} {1} {2} bytes" -f $asset, $channel, (Get-Item -LiteralPath $destination).Length)
    }
    $metadata = [ordered]@{ asset = $asset; provider = 'Poly Haven'; official_page = ('https://polyhaven.com/a/' + $asset); official_files_api = $api; license = 'CC0-1.0'; license_url = 'https://polyhaven.com/license'; verified_date = '2026-10-02'; physical_width_m = $physicalWidths[$asset]; physical_width_source = 'Official asset page'; usage = 'Tileable terrain PBR, candidate for sixth world material preview; not a model UV atlas'; approved_for_production = $false; channels = $records; network = 'Public official API/download URLs; no account, key, fee or runtime API dependency'; arm_channels = 'R ambient occlusion, G roughness, B metallic' }
    # This is generated provenance, not a hand-maintained asset document.
    $json = $metadata | ConvertTo-Json -Depth 8
    [IO.File]::WriteAllText((Join-Path $directory 'SOURCE.json'), $json, [Text.UTF8Encoding]::new($false))
}
