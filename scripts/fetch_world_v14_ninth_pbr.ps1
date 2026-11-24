param()

$ErrorActionPreference = 'Stop'
$asset = 'grass_ground'
$directory = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../game/art/external/polyhaven/world_terrain_v14_ninth/grass_ground'))
$agentName = 'CloudShadowRPG-AssetPipeline/1.0 (+https://github.com/rajqiu2022/cw_rpg)'
New-Item -ItemType Directory -Path $directory -Force | Out-Null
$info = Invoke-RestMethod -Uri ('https://api.polyhaven.com/info/' + $asset) -UserAgent $agentName
if ($info.type -ne 1 -or [Math]::Abs($info.dimensions[0] - 2510) -gt 0.01 -or [Math]::Abs($info.dimensions[1] - 2510) -gt 0.01 -or $null -eq $info.authors.'Charlotte Baglioni') { throw 'Unexpected physical texture/author contract' }
$files = Invoke-RestMethod -Uri ('https://api.polyhaven.com/files/' + $asset) -UserAgent $agentName
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
    $records += [ordered]@{ channel = $channel; path = ('res://art/external/polyhaven/world_terrain_v14_ninth/' + $asset + '/' + $filename); url = $uri.AbsoluteUri; size = (Get-Item -LiteralPath $destination).Length; official_md5 = $expected; md5_verified = $true; sha256 = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant(); color_space = $(if ($channel -eq 'diff') { 'sRGB' } else { 'linear data' }) }
    Write-Output ("VERIFIED {0} {1} {2} bytes" -f $asset, $channel, (Get-Item -LiteralPath $destination).Length)
}
$metadata = [ordered]@{ asset = $asset; provider = 'Poly Haven'; author = 'Charlotte Baglioni'; official_page = 'https://polyhaven.com/a/grass_ground'; official_info_api = 'https://api.polyhaven.com/info/grass_ground'; official_files_api = 'https://api.polyhaven.com/files/grass_ground'; license = 'CC0-1.0'; license_url = 'https://polyhaven.com/license'; verified_date = '2026-10-02'; physical_width_m = 2.51; physical_height_m = 2.51; physical_width_source = 'Official info API dimensions approximately [2510,2510] millimeters'; usage = 'Physical grass terrain PBR candidate, visual quality not yet approved'; approved_for_production = $false; channels = $records; network = 'Public official API/download URLs; no account, key, fee or runtime API dependency'; arm_channels = 'R ambient occlusion, G roughness, B metallic' }
# Machine-generated provenance from verified official responses.
[IO.File]::WriteAllText((Join-Path $directory 'SOURCE.json'), ($metadata | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
