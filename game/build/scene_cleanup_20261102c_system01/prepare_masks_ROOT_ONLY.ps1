param([Parameter(Mandatory=$true)][string]$Publication)
$ErrorActionPreference='Stop'
$taskRoot='F:/Code/RPG_GAME'
$taskDir='game/build/scene_cleanup_20261102c_system01'
$isolate="$taskRoot/$taskDir/mask_import_ROOT"
$result=Get-Content -Raw -LiteralPath $Publication|ConvertFrom-Json
if(-not $result.passed -or $result.retired_actual_owners -ne 28){throw 'Actual six-bundle immutable publication required'}
$utf8=[Text.UTF8Encoding]::new($false,$true)
$profile="$taskRoot/game/data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/walk.png.import"
if((Get-FileHash -LiteralPath $profile).Hash.ToLowerInvariant() -cne '57708a5974aa2e941fa3f4fb9d2368f63ae606c9ab044a9aa7ae64c0313dba15'){throw 'Original lossless23 import profile differs'}
$profileText=[IO.File]::ReadAllText($profile)
$params=$profileText.Substring($profileText.IndexOf('[params]'))
$leaves=@()
foreach($entry in $result.records.PSObject.Properties){
    $row=$entry.Value
    if($row.kind -ne 'LEGACY'){continue}
    if(-not $row.whole_RGBA_inverse -or -not $row.whole_typed_inverse){throw 'Exact typed and RGBA inverse required'}
    $path=$row.mask.path
    $physical="$taskRoot/game/"+$path.Substring(6)
    if((Get-FileHash -LiteralPath $physical).Hash.ToLowerInvariant() -cne $row.mask.sha256){throw 'New NAV mask differs'}
    $compiled='res://.godot/imported/walk_overlay.png-'+[Convert]::ToHexString([Security.Cryptography.MD5]::HashData([Text.Encoding]::UTF8.GetBytes($path))).ToLowerInvariant()+'.ctex'
    $sidecar="[remap]`nimporter=`"texture`"`ntype=`"CompressedTexture2D`"`npath=`"$compiled`"`nmetadata={`n`"vram_texture`": false`n}`n`n[deps]`nsource_file=`"$path`"`ndest_files=[`"$compiled`"]`n`n$params"
    $mirror="$isolate/"+$path.Substring(6)
    if(Test-Path -LiteralPath $mirror){throw 'Immutable mask mirror already exists'}
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($mirror))|Out-Null
    Copy-Item -LiteralPath $physical -Destination $mirror
    [IO.File]::WriteAllBytes(($mirror+'.import'),$utf8.GetBytes($sidecar))
    $leaves+=@{scene=$entry.Name;source=$path;source_sha256=$row.mask.sha256;RGBA_sha256=$row.mask.RGBA_sha256;sidecar=($path+'.import');compiled=$compiled}
}
if($leaves.Count -ne 3){throw 'Exactly three new NAV masks required'}
$plan=[ordered]@{isolate=$isolate;leaves=$leaves;new_import_leaves=6;canonical_writes=0;engine_runs=0}
$planPath="$taskRoot/$taskDir/mask_import_plan_READY.json"
if(Test-Path -LiteralPath $planPath){throw 'Immutable import plan exists'}
[IO.File]::WriteAllBytes($planPath,$utf8.GetBytes(($plan|ConvertTo-Json -Depth 6)+"`n"))
$plan|ConvertTo-Json -Depth 6
