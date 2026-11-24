$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME'; $game=Join-Path $repo 'game'
$q='res://build/luoyang_city_revision_20261025g_qa01/'
$s='res://build/luoyang_city_revision_20261025g_source01/'
$n='res://build/luoyang_market_courtyard_links_20261025g_system01/'
function Abs([string]$path){if($path.StartsWith('res://')){return Join-Path $game $path.Substring(6)};return $path}
function Pin([string]$path,[string]$expected){$raw=[IO.File]::ReadAllBytes((Abs $path));if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($raw)).ToLowerInvariant() -ne $expected){throw "Pin $path"};return [Text.Encoding]::UTF8.GetString($raw)}
function WriteNew([string]$path,[object]$value){$a=Abs $path;if(Test-Path -LiteralPath $a){throw "Preserve $path"};$text=($value|ConvertTo-Json -Depth 100)+"`n";[IO.File]::WriteAllText($a,$text,[Text.UTF8Encoding]::new($false));return @{path=$path;sha256=(Get-FileHash -LiteralPath $a -Algorithm SHA256).Hash.ToLowerInvariant()}}
$stagePin=@{path=$s+'outputs/root_market_courtyard45_exact32_stage02/receipt.json';sha256='c972f71442cc6573d8e55a92bf0ce875039879be651dd30e3fd32df585d97396'}
$stage=(Pin $stagePin.path $stagePin.sha256)|ConvertFrom-Json -AsHashtable
if($stage.status -ne 'MARKET_COURTYARD45_EXACT32_STAGED_NOT_DEPLOYED' -or $stage.targets.Count -ne 32 -or $stage.target_partition.patch_count -ne 17 -or $stage.target_partition.copy_count -ne 15){throw 'Stage schema'}
$mapPin=@{path=$stage.nodes.expected_ch4_s3_luoyang_market_true.path;sha256=$stage.nodes.expected_ch4_s3_luoyang_market_true.sha256}
$map=(Pin $mapPin.path $mapPin.sha256)|ConvertFrom-Json -AsHashtable
if($map.source_sha256.Count -ne 1900 -or $mapPin.sha256 -ne '195f682da24af94d6f99783b605ab8c5bddb12ea1f763f69be96d77b619b4953'){throw 'Independent1900'}
$seedPin=@{path=$s+'finite_four_render_source_seed_NOTREADY.json';sha256='e19e46025dfd2b45adee02e00e67a8b230f135dff00bdbc0b8c8ca8c18f0708c'}
$seed=(Pin $seedPin.path $seedPin.sha256)|ConvertFrom-Json -AsHashtable
if($seed.expected_render4.Count -ne 4 -or $seed.actual_publisher_or_runtime_values_used -ne $false -or $seed.independent_prior.sha256 -ne '4fe0b510d4200243a9f7f935888c5b97e98122439de30d4aafac28d92501f8c5'){throw 'Independentfourrender'}
$runtime=$n+'runtime02_READY/market_courtyard_session_READY.gd';$binding=$n+'runtime02_READY/binding_READY.json'
if($map.source_sha256[$runtime] -ne '4922879a8734c95ec308b6cb7ff4b026695f07bb2c48a86928a7fea07a46fc6d' -or $map.source_sha256[$binding] -ne '3e316674ce6f72bb434618fbf8ce3c4551c74a230ecbb097cf55ecc499c08c04'){throw 'Finalhelper'}
$sources=[ordered]@{}
foreach($path in @($runtime,$binding,'res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','res://scripts/field/field_walkable_controller.gd',$seed.author.path)) {if(-not $map.source_sha256.Contains($path)){throw "Map missing $path"};$sources[$path]=$map.source_sha256[$path]}
$sources[$seedPin.path]=$seedPin.sha256;$sources[$seed.independent_prior.path]=$seed.independent_prior.sha256
$sources[$stagePin.path]=$stagePin.sha256;$sources[$mapPin.path]=$mapPin.sha256
$field=[ordered]@{status='ROOT_REVIEW_FINAL_STAGE02_EXPECTATION_FORMAL_DEPLOYMENT_PENDING';ready=$false;formal_deployed=$false;stage=$stagePin;deployment=$null;independent_map=$mapPin;independent_four_render_seed=$seedPin;scene_id='ch4_s3_luoyang_market';whole_ms=60000;entry_ms=20000;max_pictures=1;expected_city_count=1900;expected_city_sources=$map.source_sha256;runtime_path=$runtime;binding_path=$binding;mask_path=$n+'publication03/output/115716/walk_overlay.png';source_sha256=$sources;expected_new_render=$seed.expected_render4;inspection_starts=@(@(1720,1384),@(2660,1384));Root_authorized_inspection_position_writes=2;paths=@(@(@(1720,1384),@(1720,1340)),@(@(2660,1384),@(2660,1340)));no_continuous_default_to_inspection_travel_credit=$true;no_new_loading_performance_credit=$true;old_material_room_route_portrait_global_raster_replay=0;NPC_camera_speed_body_writes=0}
$guard=[ordered]@{status='ROOT_REVIEW_GUARD_FINAL_STAGE02_DEPLOYMENT_PENDING';ready=$false;formal_deployed=$false;fresh=@{path=$s+'fresh_current25g_READONLY.json';sha256='4b8b0fbf7a7577ea0119cf1a7a9500cf87844f6ca07df4488266bd8c651a4e55'};scope=@{path=$s+'courtyard45_exact32_scope_PREPARATION.json';sha256='823dcc493006e0a439dc4f4caa1ce8a1ad6b029fb9c3e8f847620731defac4d5'};backup32=@{path=$s+'predeploy32_backup_receipt.json';sha256='207a8da07bb9991bcb0f017a482d208da46a8759d082c94b899b2a106fc63a21'};mask_admission=@{path='res://build/luoyang_city_revision_20261025g_root01/mask_import_admission.json';sha256='10fbd028728cc849e1c8b40b0d3c23dcd76f2c8e37480bfb7f341a6bfb5baa54'};stage=$stagePin;deployment=$null;target_count=32;fixed_current_target_count=33;observed_count=2121;save_count=15;full_backup_count=148;admitted_media_count=8}
$parentPath='res://build/luoyang_city_revision_20261025f_qa01/guard18_NOTREADY.py'
$parent=Pin $parentPath 'c5e2e6a05a39cc9adc5e63159385ccbc5e5588ccfb3ff70178c30af7fd2b4b9a'
$childPath=$q+'guard32_NOTREADY.py';$child=Pin $childPath 'eb33b3284db5b9dd107d94c88341eeb23517bf8a4c3ce4536d7eaaf259366518'
$inverse=@{status='COMPLETE_QA_ONLY_GUARD_WHOLE_BYTE_REPLACEMENT_NOT_EXECUTED';parent=@{path=$parentPath;sha256='c5e2e6a05a39cc9adc5e63159385ccbc5e5588ccfb3ff70178c30af7fd2b4b9a'};child=@{path=$childPath;sha256='eb33b3284db5b9dd107d94c88341eeb23517bf8a4c3ce4536d7eaaf259366518'};old_text=$parent;new_text=$child;reverse_old_text=$child;reverse_new_text=$parent;formal_writes=0;guard_calls=0;engine_calls=0}
WriteNew ($q+'Field01_NOTREADY/fixture_stage02_NOTREADY.json') $field
WriteNew ($q+'guard32_fixture_stage02_NOTREADY.json') $guard
WriteNew ($q+'guard32_whole_byte_delta_NOTRUN.json') $inverse
