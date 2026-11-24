param([string]$PreparedPath,[string]$PreparedSHA,[string]$Workspace='F:\Code\RPG_GAME')
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
# Root-only preparation, NOT engine/import/verification/promotion. Copies only
# frozen build-candidate PNG bytes into this isolated project. All three main
# targets remain absent so the open editor cannot auto-import the PNG early.
$gameRoot=Join-Path $Workspace 'game'
$isolate=Join-Path $gameRoot 'build/luoyang_shore_market_20261020ae_system01/isolate_wet_only'
function Disk([string]$p){if(!$p.StartsWith('res://') -or $p.Contains('..')){throw 'RESOURCE_PATH'};return Join-Path $gameRoot $p.Substring(6)}
function Sha([string]$p){return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function IsTrue($v){return $v -is [bool] -and $v -eq $true}
function Json($v){return $v|ConvertTo-Json -Depth 20 -Compress}
if(!$PreparedPath -or $PreparedSHA -cnotmatch '^[0-9a-f]{64}$'){throw 'FROZEN_PREPARED_REQUIRED_NO_OUTPUT'}
$preparedDisk=Disk $PreparedPath
if((Sha $preparedDisk) -cne $PreparedSHA){throw 'PREPARED_SHA'}
$spec=Get-Content -Raw -LiteralPath $preparedDisk|ConvertFrom-Json -AsHashtable
if($spec.status -cne 'AE_WET_ONLY_PNG_READY_FOR_ISOLATED_IMPORT' -or $spec.schema_version -ne 1 -or $spec.schema_version -is [bool]){throw 'PENDING_SOURCE_NO_OUTPUT'}
$wanted=@('wet_shore')
if(!(IsTrue $spec.root_approved_clean_wet_derivative) -or (Json @($spec.approved_docks_kinds)) -cne (Json $wanted) -or $spec.textures.Count -ne 1 -or $spec.textures[0].visual_kind -cne 'wet_shore'){throw 'EXACT_SINGLE_NEW_WET_TEXTURE_NO_PRIOR_THREE'}
$project=Join-Path $isolate 'project.godot'
if((Sha $project) -cne $spec.project_sha256){throw 'ISOLATE_PROJECT_SHA'}
$receiptPath=Join-Path $isolate 'seed_receipt.json'
if(Test-Path -LiteralPath $receiptPath){throw 'SEED_RECEIPT_EXISTS_DO_NOT_REIMPORT'}
$plans=@();$seen=@{}
foreach($item in $spec.textures){
 $path=$item.texture
 if($path -isnot [string] -or !$path.StartsWith('res://art/modules/luoyang_shore_market_20261020ae/') -or !$path.EndsWith('.png') -or $path.Contains('..') -or $path -cnotmatch '^[a-zA-Z0-9_./:-]+$' -or $seen.Contains($path)){throw 'EXACT_NEW_TEXTURE_PATH'};$seen[$path]=$true
 if($item.size.Count -ne 2){throw 'DIMENSIONS'};foreach($n in $item.size){if($n -is [bool] -or $n -is [string] -or $null -eq $n -or [double]$n -le 0 -or [math]::Truncate([double]$n) -ne [double]$n){throw 'EXACT_INTEGRAL_DIMENSIONS'}}
 if($item.source_sha256 -cnotmatch '^[0-9a-f]{64}$' -or $item.rgba_sha256 -cnotmatch '^[0-9a-f]{64}$'){throw 'FROZEN_SOURCE_AND_RGBA_SHA'}
 $candidatePath=$item.candidate_path;if($candidatePath -isnot [string] -or !$candidatePath.StartsWith('res://build/luoyang_shore_market_20261020ae_') -or !$candidatePath.EndsWith('.png') -or $candidatePath.Contains('..')){throw 'FROZEN_BUILD_CANDIDATE_PATH_REQUIRED'};$mainPNG=Disk $path;$source=Disk $candidatePath;if((Sha $source) -cne $item.source_sha256){throw 'BUILD_CANDIDATE_PNG_NOT_FROZEN'}
 $md5=[Security.Cryptography.MD5]::Create();try{$digest=[Convert]::ToHexString($md5.ComputeHash([Text.Encoding]::UTF8.GetBytes($path))).ToLowerInvariant()}finally{$md5.Dispose()}
 $compiled='res://.godot/imported/'+[IO.Path]::GetFileName($path)+'-'+$digest+'.ctex'
 if($item.compiled_path -cne $compiled){throw 'EXACT_FULL_RESOURCE_PATH_MD5'}
 $target=[IO.Path]::GetFullPath((Join-Path $isolate $path.Substring(6)))
 if(!$target.StartsWith($isolate+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'OUTSIDE_ISOLATE'}
 if((Test-Path -LiteralPath $target) -or (Test-Path -LiteralPath ($target+'.import')) -or (Test-Path -LiteralPath (Join-Path $isolate $compiled.Substring(6)))){throw 'ISOLATE_NEW_TEXTURE_OR_IMPORT_ALREADY_EXISTS'}
 if((Test-Path -LiteralPath $mainPNG) -or (Test-Path -LiteralPath ($mainPNG+'.import')) -or (Test-Path -LiteralPath (Disk $compiled))){throw 'MAIN_PNG_IMPORT_OR_CTEX_ALREADY_EXISTS_STOP_FOR_ROOT_REVIEW'}
 $plans+=@{source=$source;candidate_path=$candidatePath;target=$target;texture=$path;source_sha256=$item.source_sha256;compiled_path=$compiled;visual_kind=$item.visual_kind}
}
$params=@'
[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=false
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=0
'@
foreach($plan in $plans){
 [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($plan.target))|Out-Null
 Copy-Item -LiteralPath $plan.source -Destination $plan.target
 if((Sha $plan.target) -cne $plan.source_sha256){throw 'NEW_PNG_COPY_SHA'}
 $sidecar="[remap]`n`nimporter=`"texture`"`ntype=`"CompressedTexture2D`"`npath=`""+$plan.compiled_path+"`"`nmetadata={`n`"vram_texture`": false`n}`n`n[deps]`n`nsource_file=`""+$plan.texture+"`"`ndest_files=[`""+$plan.compiled_path+"`"]`n`n"+$params+"`n"
 [IO.File]::WriteAllText($plan.target+'.import',$sidecar,[Text.UTF8Encoding]::new($false))
}
$receipt=@{status='NEW_ISOLATE_SEED_ONLY_NOT_IMPORTED_OR_VERIFIED';prepared_path=$PreparedPath;prepared_sha256=$PreparedSHA;project_sha256=$spec.project_sha256;selected_visual_kinds=$wanted;plans=$plans;main_imports_unchanged=$true;engine_started=$false}
[IO.File]::WriteAllText($receiptPath,($receipt|ConvertTo-Json -Depth 10)+"`n",[Text.UTF8Encoding]::new($false))
$receipt|ConvertTo-Json -Depth 5
