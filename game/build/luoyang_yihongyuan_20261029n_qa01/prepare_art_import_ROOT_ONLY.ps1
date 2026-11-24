param([Parameter(Mandatory=$true)][string]$PNG_SHA,[Parameter(Mandatory=$true)][string]$RGBA_SHA,[int]$Width=1441,[int]$Height=1206)
$ErrorActionPreference='Stop'
$taskRoot='F:/Code/RPG_GAME';$gameRoot="$taskRoot/game";$qaRoot="$gameRoot/build/luoyang_yihongyuan_20261029n_qa01";$isolate="$qaRoot/art_import_ROOT"
if($PNG_SHA-cnotmatch'^[a-fA-F0-9]{64}$'-or$RGBA_SHA-cnotmatch'^[a-fA-F0-9]{64}$'-or$Width-ne1441-or$Height-ne1206){throw 'Only final Art-published1441x1206 image and two exact SHA values.'}
$source='res://art/maps/luoyang_yihongyuan_20261029n/yihongyuan_exterior_v1.png';$physical="$gameRoot/"+$source.Substring(6)
function SHA([string]$p){return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function NewBytes([string]$p,[byte[]]$b){[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($p))|Out-Null;$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$s.Write($b,0,$b.Length)}finally{$s.Dispose()}}
if((SHA $physical)-cne$PNG_SHA.ToLowerInvariant()){throw 'Root must first copy exactly the final approved new PNG; no old art writes.'}
$profile="$gameRoot/art/maps/luoyang_city_rebuild_20261027d/spring_house_complete_v1_padded.png.import"
if((SHA $profile)-cne'39618fab9bd5c7007fc2eb0f8442d3bdab09ccb69e2e0d1dc352f3aeee21a284'){throw 'Original Spring exact23-param profile changed'}
$profileText=[IO.File]::ReadAllText($profile);$params=$profileText.Substring($profileText.IndexOf('[params]'))
foreach($required in @('compress/mode=0','mipmaps/generate=false','process/fix_alpha_border=false','process/premult_alpha=false')){if(-not$params.Contains($required)){throw 'Lossless original import profile required'}}
$compiled='res://.godot/imported/yihongyuan_exterior_v1.png-'+[Convert]::ToHexString([Security.Cryptography.MD5]::HashData([Text.Encoding]::UTF8.GetBytes($source))).ToLowerInvariant()+'.ctex'
$sidecar="[remap]`nimporter=`"texture`"`ntype=`"CompressedTexture2D`"`npath=`"$compiled`"`nmetadata={`n`"vram_texture`": false`n}`n`n[deps]`nsource_file=`"$source`"`ndest_files=[`"$compiled`"]`n`n$params"
NewBytes "$isolate/project.godot" ([Text.UTF8Encoding]::new($false).GetBytes("config_version=5`n[application]`nconfig/name=`"Yihongyuan single final exterior import`"`n[rendering]`nrenderer/rendering_method=`"gl_compatibility`"`n"))
NewBytes ("$isolate/"+$source.Substring(6)) ([IO.File]::ReadAllBytes($physical))
NewBytes ("$isolate/"+$source.Substring(6)+'.import') ([Text.UTF8Encoding]::new($false).GetBytes($sidecar))
$templatePath="$qaRoot/art_verify_TEMPLATE.gd";$verifier=[IO.File]::ReadAllText($templatePath).Replace('__PNG_SHA__',$PNG_SHA.ToLowerInvariant()).Replace('__RGBA_SHA__',$RGBA_SHA.ToLowerInvariant()).Replace('__WIDTH__',[string]$Width).Replace('__HEIGHT__',[string]$Height)
NewBytes "$isolate/verify_READY.gd" ([Text.UTF8Encoding]::new($false).GetBytes($verifier))
$plan=[ordered]@{status='ONLY_FINAL_YIHONGYUAN_EXTERIOR_ISOLATE_PREPARED';isolate=$isolate;source_png=$source;png_sha256=$PNG_SHA.ToLowerInvariant();RGBA_sha256=$RGBA_SHA.ToLowerInvariant();width=$Width;height=$Height;sidecar=($source+'.import');compiled=$compiled;md5=($compiled.Substring(0,$compiled.Length-5)+'.md5');profile_path=$profile;profile_sha256=(SHA $profile);verifier_sha256=(SHA "$isolate/verify_READY.gd");template_sha256=(SHA $templatePath);main_PNG_or_old_art_writes=0;main_import_leaf_writes=0;engine_calls=0}
$out="$qaRoot/art_import_prepared_READY.json";NewBytes $out ([Text.UTF8Encoding]::new($false).GetBytes(($plan|ConvertTo-Json -Depth 8)+"`n"));$plan|ConvertTo-Json -Depth 8
