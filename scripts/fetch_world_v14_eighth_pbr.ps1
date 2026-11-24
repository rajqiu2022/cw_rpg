param()

$ErrorActionPreference = 'Stop'
$asset = 'aerial_grass_rock'
$assetRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../game/art/external/polyhaven/world_terrain_v14_eighth'))
$directory = Join-Path $assetRoot $asset
$agentName = 'CloudShadowRPG-AssetPipeline/1.0 (+https://github.com/rajqiu2022/cw_rpg)'
New-Item -ItemType Directory -Path $directory -Force | Out-Null
$infoText = (& curl.exe --fail --silent --show-error --user-agent $agentName ('https://api.polyhaven.com/info/' + $asset)) -join "`n"
if ($LASTEXITCODE -ne 0) { throw 'Official information API failed' }
$info = $infoText | ConvertFrom-Json
if ($info.type -ne 1 -or $info.dimensions[0] -ne 15000 -or $info.dimensions[1] -ne 15000) { throw 'Unexpected physical texture contract' }
$api = 'https://api.polyhaven.com/files/' + $asset
$apiText = (& curl.exe --fail --silent --show-error --user-agent $agentName $api) -join "`n"
if ($LASTEXITCODE -ne 0) { throw 'Official files API failed' }
$files = $apiText | ConvertFrom-Json
$records = @()
$channelKeys = @{ diff = 'Diffuse'; nor_gl = 'nor_gl'; arm = 'arm' }
foreach ($channel in @('diff','nor_gl','arm')) {
    $file = $files.($channelKeys[$channel]).'2k'.jpg
    if ($null -eq $file) { throw "Missing official channel: $channel" }
    $uri = [Uri]$file.url
    $filename = [IO.Path]::GetFileName($uri.AbsolutePath)
    if ($uri.Scheme -ne 'https' -or $uri.Host -ne 'dl.polyhaven.org' -or $filename -ne ($asset + '_' + $channel + '_2k.jpg')) { throw 'Unexpected official asset URL' }
    $destination = Join-Path $directory $filename
    $expected = ([string]$file.md5).ToLowerInvariant()
    if (Test-Path -LiteralPath $destination) {
        if ((Get-FileHash -LiteralPath $destination -Algorithm MD5).Hash.ToLowerInvariant() -ne $expected -or (Get-Item -LiteralPath $destination).Length -ne [long]$file.size) { throw 'Existing bytes differ; refusing overwrite' }
    } else {
        $partial = $destination + '.fetch-20261002.partial'
        if (Test-Path -LiteralPath $partial) { throw 'Prior partial retained; refusing overwrite' }
        & curl.exe --fail --location --silent --show-error --retry 2 --retry-delay 1 --max-time 180 --user-agent $agentName --output $partial $uri.AbsoluteUri
        if ($LASTEXITCODE -ne 0) { throw 'Download failed; partial retained' }
        if ((Get-FileHash -LiteralPath $partial -Algorithm MD5).Hash.ToLowerInvariant() -ne $expected -or (Get-Item -LiteralPath $partial).Length -ne [long]$file.size) { throw 'Official MD5/size mismatch; partial retained' }
        Move-Item -LiteralPath $partial -Destination $destination
    }
    $records += [ordered]@{ channel = $channel; resolution = '2k'; format = 'jpg'; url = $uri.AbsoluteUri; path = ('res://art/external/polyhaven/world_terrain_v14_eighth/' + $asset + '/' + $filename); size = (Get-Item -LiteralPath $destination).Length; official_md5 = $expected; md5_verified = $true; sha256 = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant(); color_space = $(if ($channel -eq 'diff') { 'sRGB' } else { 'linear data' }) }
    Write-Output ("VERIFIED {0} {1} {2} bytes" -f $asset, $channel, (Get-Item -LiteralPath $destination).Length)
}
$metadata = [ordered]@{ asset = $asset; provider = 'Poly Haven'; author = 'Rob Tuytel'; official_page = 'https://polyhaven.com/a/aerial_grass_rock'; official_info_api = 'https://api.polyhaven.com/info/aerial_grass_rock'; official_files_api = $api; license = 'CC0-1.0'; license_url = 'https://polyhaven.com/license'; verified_date = '2026-10-02'; physical_width_m = 15.0; physical_height_m = 15.0; physical_width_source = 'Official info API dimensions [15000,15000] millimeters'; usage = 'Physical 15m tileable mid-scale terrain PBR candidate, not a model UV atlas'; approved_for_production = $false; channels = $records; network = 'Public official API/download URLs; no account, key, fee or runtime API dependency'; arm_channels = 'R ambient occlusion, G roughness, B metallic' }
# Generated provenance, not a hand-maintained asset document.
[IO.File]::WriteAllText((Join-Path $directory 'SOURCE.json'), ($metadata | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
