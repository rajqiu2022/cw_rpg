$ErrorActionPreference='Stop'
$game=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
function Abs([string]$p){return (Join-Path $game $p.Substring(6)).Replace('\','/')}
$N='res://build/luoyang_market_courtyard_links_20261025g_system01/'
$rows=@(
 @($N+'author_courtyard_links02_NOTREADY.json','e91631e6b5c5f44a4bbe7d67c1a2519c498ff9e403d9452e2484274dc8032cad'),
 @('res://build/luoyang_city_blocks_20261024e_system01/author_market_block07_paper_foot_NOTREADY.json','de1911cceb5fb10e6b3b1aba1fa6d9d34057358841febdd285d25a1a1eb65e95'),
 @('res://build/luoyang_city_blocks_20261024e_system01/publication04/output/9720/components_FIXED_NOT_RUNTIME.json','cafee170b4e33b159c8ad769e96ceeb97987d70eb561ee9b5049a8e25e827194'),
 @('res://build/luoyang_city_blocks_20261024e_system01/publication04/output/9720/render_projection.bin','294c4ffdcad625e2a299959b8dc2be2328980a3946316d016f37793dbef112c6'),
 @('res://build/luoyang_city_blocks_20261024e_system01/publication04/output/9720/geometry.bin','05c6caad893e1a60abed8ffd37ef072fea89c3c2ac9a257b93c59cddb2a9752d'),
 @('res://build/luoyang_city_blocks_20261024e_system01/publication04/output/9720/walk_overlay.png','051ac64ff157f1cc7ae4ab2abb4b03f650d8da74bd15bf5ff528164d5bfdc9d4'),
 @('res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/ch4_s3_luoyang_market/raw_walk.png','0dc78a4affde8a13d1d2f58385b4ac5da102b1718f8e5b48d12dd066b0dedcfa'),
 @('res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision4/author_READY.json','c2aa48ec6fe654f85e17be9081ca86c748fffe2506581405c4df4ec0b15add69'),
 @('res://data/maps/luoyang_assembled_interiors_20261016g/herbal_shop_author.json','705f77c096ced3efc5aad5fe77e658b8ae66a2d6ce81dc59f8aa1e485dc3d92a'),
 @('res://build/luoyang_estate_courtyard_20261021ak_system01/author_READY.json','c21097071d8a13ee9e427309a9203fe74ae28250eb36d067c2a101e08185de55'),
 @('res://build/luoyang_estate_courtyard_20261021ak_system01/candidate_art/corridor.png','a335bb05e3155a1933314525824b90eba098bbd878f1f85d1db60889a549388d'),
 @('res://art/modules/luoyang_estate_components_20261021am/corridor.png','a335bb05e3155a1933314525824b90eba098bbd878f1f85d1db60889a549388d'),
 @('res://build/luoyang_city_revision_20261024e_source01/finite_Field_source_seed_READY_FOR_ROOT_REVIEW.json','0a7786276b871f63c9203d4cc0a0ecd641defcd4f2664cda3910773c7d391d88')
)
$pins=@{};foreach($r in $rows){$p=Abs $r[0];if((Get-FileHash -LiteralPath $p).Hash.ToLowerInvariant()-cne$r[1]){throw ('fixed pin '+$r[0])};$pins[$p]=$r[1]}
$doc=@{ready=$false;whole_ms=60000;game_root=$game.Replace('\','/');author=(Abs $rows[0][0]);parent_author=(Abs $rows[1][0]);parent_geometry=(Abs $rows[4][0]);parent_walk=(Abs $rows[5][0]);raw_walk=(Abs $rows[6][0]);cloth_donor=(Abs $rows[7][0]);herb_donor=(Abs $rows[8][0]);corridor_donor=(Abs $rows[9][0]);NPC_seed=(Abs $rows[12][0]);pins=$pins;maximum_local_union_pixels=500000;output_prefix=(Abs 'res://build/luoyang_city_revision_20261025g_qa01/prior01_output/');source_donor_only_not_System_pure=$true;geometry_decodes=1;parent_and_raw_PNG_decodes=2;assets_PNG_decodes=0;old87517_global_replay=0;old_doors_material55_portraits_replay=0;root_only_engine=$true;expected_child_RGBA_sha256='UNKNOWN_UNTIL_ROOT_NATIVE_LOCAL_ORACLE';changed_pixels=$null;union_visited_pixels=$null}
$out=Join-Path $PSScriptRoot 'prior01_INPUT_NOTREADY.json';if(Test-Path -LiteralPath $out){throw 'new namespace only'};[IO.File]::WriteAllText($out,($doc|ConvertTo-Json -Depth 30),[Text.UTF8Encoding]::new($false));@{path=$out;sha256=(Get-FileHash $out).Hash.ToLowerInvariant();pin_count=$pins.Count;engine_calls=0}|ConvertTo-Json -Compress
