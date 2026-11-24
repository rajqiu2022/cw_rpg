$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$game='F:/Code/RPG_GAME/game'
$isolate='F:/Code/RPG_GAME/assets/staging/luoyang_market_walk_20261024b_import'
$res='res://build/luoyang_city_revision_20261024b_root01/market_detours06_READY/output/walk.png'
$original=Join-Path $game $res.Substring(6)
$template='F:/Code/RPG_GAME/assets/staging/luoyang_two_complete_shops_isolated_import_20261024b/verify_READY.gd'
$profile="$game/data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/walk.png.import"
function Hash([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
if(Test-Path -LiteralPath $isolate){throw 'PRESERVE_EXISTING_ISOLATE'}
if((Hash $original) -cne 'dbec7c022f3d0e6e2478488caf6f9f1a56475ecde22019da4006f49fa027e0d1'){throw 'NEW_NATIVE_WALK_CHANGED'}
if((Hash $template) -cne 'f37b510ff7df642c9f8aec90f60535015ce701b0fcca07e43174c7d0ce89e1d7'){throw 'TEMPLATE_CHANGED'}
if((Hash $profile) -cne '57708a5974aa2e941fa3f4fb9d2368f63ae606c9ab044a9aa7ae64c0313dba15'){throw 'PROFILE_CHANGED'}
$md5=[Convert]::ToHexString([Security.Cryptography.MD5]::HashData([Text.Encoding]::UTF8.GetBytes($res))).ToLowerInvariant()
$compiled="res://.godot/imported/walk.png-$md5.ctex"
$absent=@("$original.import",(Join-Path $game $compiled.Substring(6)))
foreach($p in $absent){if(Test-Path -LiteralPath $p){throw "ONLY_NEW_LEAVES_REQUIRED:$p"}}
$utf=[Text.UTF8Encoding]::new($false)
function NewText([string]$relative,[string]$content){$p=Join-Path $isolate $relative;if(Test-Path -LiteralPath $p){throw 'NO_OVERWRITE'};[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($p))|Out-Null;[IO.File]::WriteAllText($p,$content,$utf)}
function Fact([string]$p){$f=Get-Item -LiteralPath $p;@{sha256=(Hash $p);bytes=$f.Length;ticks=[string]$f.LastWriteTimeUtc.Ticks}}
$texture=@{domain='market_walk';png=$res;png_sha256=(Hash $original);decoded_RGBA_sha256='2042da8017350c45ce4c6de5002931324c2bd62a024315c0ec3173f9c57242a8';source_size=@(3072,2048);compiled=$compiled;sidecar="$res.import"}
$expected=@{market_walk=$texture.Clone()};$expected.market_walk.Remove('domain');$expected.market_walk.Remove('compiled');$expected.market_walk.Remove('sidecar')
NewText 'project.godot' "config_version=5`n`n[application]`nconfig/name=`"Luoyang Single New Market Walk Import 20261024b`"`n`n[rendering]`nrenderer/rendering_method=`"gl_compatibility`"`nrenderer/rendering_method.mobile=`"gl_compatibility`"`n"
$pngTarget=Join-Path $isolate $res.Substring(6)
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($pngTarget))|Out-Null
Copy-Item -LiteralPath $original -Destination $pngTarget
$profileText=Get-Content -Raw -LiteralPath $profile
$params=$profileText.Substring($profileText.IndexOf('[params]')+8)
$seed="[remap]`n`nimporter=`"texture`"`ntype=`"CompressedTexture2D`"`npath=`"$compiled`"`nmetadata={`n`"vram_texture`": false`n}`n`n[deps]`n`nsource_file=`"$res`"`ndest_files=[`"$compiled`"]`n`n[params]$params"
NewText ($res.Substring(6)+'.import') $seed
$protected=@{};foreach($p in @($original,$template,$profile)){$protected[$p]=(Fact $p)}
$manifest=@{status='EXACT_SINGLE_NEW_MARKET_WALK_ISOLATED_IMPORT_PREPARED';textures=@($texture);project_sha256=(Hash "$isolate/project.godot");protected_main_sources=$protected;main_new_absent_targets=$absent;production_promoted=$false}
NewText 'prepared_READY.json' (($manifest|ConvertTo-Json -Depth 20)+"`n")
$key=Get-Content -Raw -LiteralPath $template
$start=$key.IndexOf('const EXPECTED: Dictionary=');$end=$key.IndexOf("`nconst PARAMS:",$start)
$key=$key.Substring(0,$start)+'const EXPECTED: Dictionary='+($expected|ConvertTo-Json -Depth 10)+$key.Substring($end)
$key=$key.Replace('5fe0e961788181638b338caebfb354a35fe709e341a890a98917e1a18cff2596',(Hash "$isolate/prepared_READY.json")).Replace('EXACT_TWO_COMPLETE_SHOPS_ISOLATED_IMPORT_PREPARED','EXACT_SINGLE_NEW_MARKET_WALK_ISOLATED_IMPORT_PREPARED').Replace('main_six_absent_targets','main_new_absent_targets').Replace('spec.textures.size()==2','spec.textures.size()==1').Replace('seen.size()==2','seen.size()==1').Replace('two_complete_shops_import_result_','single_market_walk_import_result_').Replace('ONLY_TWO_COMPLETE_SHOPS_ISOLATED_FULL_RGBA_NOT_RUNTIME_OR_GEOMETRY','ONLY_SINGLE_NEW_MARKET_WALK_FULL_RGBA_NOT_RUNTIME_OR_ART').Replace('TWO_SHOPS_IMPORT','MARKET_WALK_IMPORT').Replace('Exact two complete shop PNGs only','Only one new Market walk PNG').Replace('Exactly two independently expected PNGs verified','Only one source-prior walk verified').Replace('Main six targets','Main two NEW media leaves')
NewText 'verify_READY.gd' $key
@{isolate=$isolate;prepared_sha256=(Hash "$isolate/prepared_READY.json");verifier_sha256=(Hash "$isolate/verify_READY.gd");compiled=$compiled;main_new_absent_targets=$absent;engine_calls=0}|ConvertTo-Json -Depth 5
