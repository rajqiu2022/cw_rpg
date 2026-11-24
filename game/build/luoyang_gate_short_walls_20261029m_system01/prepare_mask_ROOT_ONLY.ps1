param()
$ErrorActionPreference='Stop'
$taskRoot='F:/Code/RPG_GAME'
$taskOut='game/build/luoyang_gate_short_walls_20261029m_system01'
$isolate="$taskRoot/$taskOut/mask_import_ROOT"
$publication=Get-Content -Raw -LiteralPath "$taskRoot/$taskOut/output/132376/result.json"|ConvertFrom-Json
if(-not $publication.passed -or $publication.checks -ne 16 -or $publication.changed_mask_pixels -ne 2530 -or -not $publication.whole_RGBA_inverse){throw 'Exact Root publication required'}
$sourcePath=$publication.mask.path
$physical="$taskRoot/game/"+$sourcePath.Substring(6)
if((Get-FileHash -LiteralPath $physical -Algorithm SHA256).Hash.ToLowerInvariant() -cne $publication.mask.sha256){throw 'PNG source pin differs'}
$compiled='res://.godot/imported/walk_overlay.png-'+[Convert]::ToHexString([Security.Cryptography.MD5]::HashData([Text.Encoding]::UTF8.GetBytes($sourcePath))).ToLowerInvariant()+'.ctex'
$utf8=[Text.UTF8Encoding]::new($false,$true)
$profile="$taskRoot/game/data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/walk.png.import"
if((Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash.ToLowerInvariant() -cne '57708a5974aa2e941fa3f4fb9d2368f63ae606c9ab044a9aa7ae64c0313dba15'){throw 'Exact lossless 23-param profile changed'}
$profileText=[IO.File]::ReadAllText($profile)
$params=$profileText.Substring($profileText.IndexOf('[params]'))
$sidecar="[remap]`nimporter=`"texture`"`ntype=`"CompressedTexture2D`"`npath=`"$compiled`"`nmetadata={`n`"vram_texture`": false`n}`n`n[deps]`nsource_file=`"$sourcePath`"`ndest_files=[`"$compiled`"]`n`n$params"
$mirror="$isolate/"+$sourcePath.Substring(6)
if(Test-Path -LiteralPath $mirror){throw 'Preserve previous isolate; source already exists'}
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($mirror))|Out-Null
Copy-Item -LiteralPath $physical -Destination $mirror
[IO.File]::WriteAllBytes(($mirror+'.import'),$utf8.GetBytes($sidecar))
$plan=[ordered]@{isolate=$isolate;source_png=$sourcePath;png_sha256=$publication.mask.sha256;RGBA_sha256=$publication.mask.RGBA_sha256;sidecar=($sourcePath+'.import');compiled=$compiled;new_import_leaves=2;canonical_writes=0;engine_runs=0;params_profile_sha256='57708a5974aa2e941fa3f4fb9d2368f63ae606c9ab044a9aa7ae64c0313dba15'}
$planPath="$taskRoot/$taskOut/mask_import_plan_READY.json"
if(Test-Path -LiteralPath $planPath){throw 'Immutable import plan exists'}
[IO.File]::WriteAllBytes($planPath,$utf8.GetBytes(($plan|ConvertTo-Json -Depth 6)+"`n"))
$plan|ConvertTo-Json -Depth 6
