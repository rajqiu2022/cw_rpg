param([Parameter(Mandatory=$true)][string]$OutputKey,[Parameter(Mandatory=$true)][string]$DeploymentReceipt,[Parameter(Mandatory=$true)][string]$DeploymentSHA)
$ErrorActionPreference='Stop'
$game='F:/Code/RPG_GAME/game';$base=Join-Path $game 'build/luoyang_city_revision_20261025h_qa01';$q='res://build/luoyang_city_revision_20261025h_qa01/'
function Sha($p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function From-Res($p){if(-not $p.StartsWith('res://')-or $p.Contains('..')){throw 'Fixed res path only'};Join-Path $game $p.Substring(6)}
function Assert-Hash($p,$s){if((Sha (From-Res $p))-ne $s.ToLowerInvariant()){throw "Frozen source drift $p"}}
if($OutputKey-notmatch '^[a-z][a-z0-9_]{0,40}$' -or $DeploymentSHA-notmatch '^[0-9a-fA-F]{64}$'){throw 'Root exact NEW output and deployment pin'}
$out=Join-Path $base ('garden_ready/'+$OutputKey);if(Test-Path -LiteralPath $out){throw 'Preserve previous keys'}
$seedPath='res://build/luoyang_city_revision_20261025h_source01/Garden_bridge_source_seed_NOT_RUNTIME.json';$seedSHA='716c944492474201b9b69c89b6e9480f3be1bb3a9e84284d4a9a9d1ee177b6c6'
Assert-Hash $seedPath $seedSHA;Assert-Hash $DeploymentReceipt $DeploymentSHA
$seed=Get-Content -LiteralPath (From-Res $seedPath) -Raw|ConvertFrom-Json -AsHashtable
if($seed.expected_family_sources.Count-ne 458 -or $seed.expected_family_count-ne 458 -or $seed.actual_Field_pass-ne $false){throw 'Independent final458 Source seed only'}
$formalFamily='res://scripts/city/luoyang_quarters_family_20261022ap.gd';$formalNG='res://scripts/city/luoyang_quarters_native_geometry_20261022ap.gd';$formalField='res://scripts/field/field_walkable_controller.gd'
Assert-Hash $formalFamily $seed.family_sha256;Assert-Hash $formalNG $seed.native_geometry_sha256
$parent=$q+'garden02_NOTREADY.gd';$parentSHA='8ce48c8157f2285a2cc0b2c5db8e616fb58239f7c890ad4be2ce20c5f13ed6bf';Assert-Hash $parent $parentSHA
$artRoot='res://build/luoyang_garden_river_20261025h_source01/overview02_ROOT_READY/output/52272/'
$artPNG=$artRoot+'garden_river_bridge_tea_overview.png';$artPNG_SHA='ee5fa97708c33b34a869ce9a0d00dacfd39b1e9bbe18507443eb68c56eed2e5a'
$artReceipt=$artRoot+'result.json';$artReceiptSHA='111e004158c3e1489e562db9ef911e000f6dc44027ad3e6a54a700aa0a97753a'
Assert-Hash $artPNG $artPNG_SHA
Assert-Hash $artReceipt $artReceiptSHA
# All458 values are consumed passively from natural production FIRST/FINAL.
# Own pins remain finite; do not replay the whole native packet/image domain.
$sources=@{};$sources[$seedPath]=$seedSHA;$sources[$seed.expected_family_map.path]=$seed.expected_family_map.sha256
$sources[$formalFamily]=$seed.family_sha256;$sources[$formalNG]=$seed.native_geometry_sha256;$sources[$formalField]='fcc943fe3d188da41097ca20b9abd912a9a6dc32e09ba43f15691aa30f8ef4f0';$sources[$parent]=$parentSHA
$sources[$seed.scene_path]=$seed.scene_sha256;$sources[$seed.layout_path]=$seed.layout_sha256;$sources[$seed.front_atlas.path]=$seed.front_atlas.sha256;$sources[$artPNG]=$artPNG_SHA;$sources[$artReceipt]=$artReceiptSHA
foreach($p in @($seed.bridge_png,($seed.bridge_png+'.import'))){if(-not $seed.expected_family_sources.ContainsKey($p)){throw 'Bridge media source tuple absent'};$sources[$p]=$seed.expected_family_sources[$p]}
foreach($p in $sources.Keys){Assert-Hash $p $sources[$p]}
[IO.Directory]::CreateDirectory($out)|Out-Null
function New-File($name,$text){$p=Join-Path $out $name;if(Test-Path -LiteralPath $p){throw 'NEW outputs only'};[IO.File]::WriteAllText($p,$text,[Text.UTF8Encoding]::new($false));$p}
$fixture=[ordered]@{ready=$true;formal_deployed=$true;whole_ms=60000;entry_ms=20000;max_pictures=0;source_sha256=$sources;source_seed=@{path=$seedPath;sha256=$seedSHA};deployment=@{path=$DeploymentReceipt;sha256=$DeploymentSHA.ToLowerInvariant()};scene_path=$seed.scene_path;layout_path=$seed.layout_path;expected_family_sources=$seed.expected_family_sources;approach_px=$seed.source_approach_px;approach_uv=$seed.approachUV;approach_position_px=$seed.approach_position;midpoint_px=$seed.midpoint;end_px=$seed.end_position;bridge_png=$seed.bridge_png;bridge_position_px=$seed.bridge_position_px;bridge_scale=$seed.bridge_scale;rail_position_px=$seed.rail_position_px;rail_scale=$seed.rail_scale;inherited_source_art_receipt=$artReceipt;inherited_source_art_PNG=@{path=$artPNG;sha256=$artPNG_SHA};ART_meaning='Root and QA approved only native bridge/two landings/water-under-bridge/pavilion and tea-house proportions; no Garden-wide or city density admission'}
$fp=New-File 'fixture_READY.json' (($fixture|ConvertTo-Json -Depth 32)+"`n");$fres=$q+'garden_ready/'+$OutputKey+'/fixture_READY.json';$fsha=Sha $fp
$old=[IO.File]::ReadAllText((From-Res $parent));$new=$old.Replace('const READY25H=false','const READY25H=true').Replace('PENDING_SOURCE25H_GARDEN_FINAL_FIXTURE_SHA',$fsha).Replace('PENDING_SOURCE25H_GARDEN_FINAL_FIXTURE',$fres).Replace('/garden02_output/','/garden_ready/'+$OutputKey+'/output/').Replace('25H_GARDEN02_ZERO_PNG_HARDFALSE_FINAL_SOURCE_PENDING','25H_GARDEN_NEW_REAL_BRIDGE_ZERO_PNG_FINITE_ONLY')
$kp=New-File 'garden_READY.gd' $new
$dp=New-File 'mechanical_whole_inverse.json' ((@{status='DATA_LITERALS_READY_OUTPUT_ONLY_PARSED_GARDEN02_BEHAVIOR_RETAINED';parent_path=$parent;parent_sha256=$parentSHA;child_path=$q+'garden_ready/'+$OutputKey+'/garden_READY.gd';child_sha256=Sha $kp;old_text=$old;new_text=$new;reverse_old_text=$new;reverse_new_text=$old;engine_calls=0;formal_writes=0;old_native_or_pixels_replayed=0}|ConvertTo-Json -Depth 6)+"`n")
@{key=$q+'garden_ready/'+$OutputKey+'/garden_READY.gd';key_sha256=Sha $kp;fixture_sha256=$fsha;inverse_sha256=Sha $dp;actual_pngs=0;engine_calls=0}|ConvertTo-Json
