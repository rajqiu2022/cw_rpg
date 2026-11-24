$ErrorActionPreference='Stop'
# Only mechanical NEW QA fixture/template freezing. No engine/canonical/save writes.
$game=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
function Abs([string]$p){if(-not $p.StartsWith('res://')){throw 'res path required'};return Join-Path $game $p.Substring(6)}
function ReadPinned([string]$p,[string]$sha){$a=Abs $p;if((Get-FileHash -LiteralPath $a).Hash.ToLowerInvariant() -cne $sha){throw ('pin '+$p)};return Get-Content -Raw -LiteralPath $a | ConvertFrom-Json -AsHashtable}
function WriteNew([string]$p,[string]$text){$a=Abs $p;if(Test-Path -LiteralPath $a){throw ('never overwrite '+$p)};[IO.File]::WriteAllText($a,$text,[Text.UTF8Encoding]::new($false));return (Get-FileHash -LiteralPath $a).Hash.ToLowerInvariant()}
$stagePath='res://build/luoyang_city_revision_20261024e_source01/outputs/root_prewarm8_profile04_exact29_stage02/receipt.json'
$stageSha='3a67564ee7ef2bb8cc70e2d0b28688eabb54c4a2be53e26cc509f70bfa410e98'
$deployPath='res://build/luoyang_city_revision_20261024e_root01/prewarm_profile29_deployed_actual.json'
$deploySha='fe1549455424f80f4cdd6325402b6816aad861388b2a2e49b16a9c8c91c6b0bb'
$stage=ReadPinned $stagePath $stageSha
$deploy=ReadPinned $deployPath $deploySha
if($stage.status -cne 'PREWARM8_PROFILE04_EXACT29_STAGED_NOT_DEPLOYED' -or $stage.targets.Count -ne 29){throw 'wrong independent29 receipt'}
function MapNode([string]$key){$n=$stage.nodes[$key];$map=ReadPinned $n.path $n.sha256;if($null -eq $map.source_sha256 -or $null -eq $n.value.source_sha256){throw 'map missing'};$ks=@($map.source_sha256.Keys|Sort-Object);$nk=@($n.value.source_sha256.Keys|Sort-Object);if(($ks-join "`n") -cne ($nk-join "`n")){throw 'whole key domain mismatch'};foreach($p in $ks){if($map.source_sha256[$p] -cne $n.value.source_sha256[$p]){throw ('map value '+$p)}};return @{path=$n.path;sha256=$n.sha256;sources=$map.source_sha256}}
$gate=MapNode 'expected_ch4_s0_luoyang_gate_true'
$market=MapNode 'expected_ch4_s3_luoyang_market_true'
$helper='res://build/luoyang_loading_20261024e_perf01/candidate04/gate_source_prewarm04.gd'
$purpose='res://build/luoyang_city_blocks_20261024e_system01/market_purpose_layer04_readable_profiles_NOTREADY.gd'
$spec='res://build/luoyang_city_blocks_20261024e_system01/market_five_use_spec04_readable_profiles_NOTREADY.json'
$core=@('res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','res://scripts/field/field_walkable_controller.gd','res://scripts/autoload/scene_router.gd','res://scripts/city/luoyang_environment_layer_20261022ap.gd',$helper)
foreach($map in @($gate,$market)){if($map.sources[$helper] -cne 'd81ecdbb6e333886f50ad19aea8612791d64eee47300088521a9a7dac4b31778'){throw 'helper04 absent/wrong'};foreach($p in $core){if(-not $map.sources.ContainsKey($p)){throw 'missing core'};if((Get-FileHash -LiteralPath (Abs $p)).Hash.ToLowerInvariant() -cne $map.sources[$p]){throw ('not deployed core '+$p)}}}
if($market.sources[$purpose] -cne 'd9a9975b69f9ead39dc813a50379c65714931fe01d9580196b8d993518a80890' -or $market.sources[$spec] -cne 'dda3588304159d2f2272854632eb695640ae79201ef94e65aa77cd04f2cf95b7'){throw 'profile04 exact source required'}
$bench=ReadPinned 'res://build/luoyang_loading_20261024e_perf01/benchmark04_NOTREADY/benchmark_fixture_NOTREADY.json' '40928759b45acf2f1703a14ba3d199e402985e65c907f907a47ee1a8f6ffde6e'
$bench.expected_gate_sources=$gate.sources;$bench.source_sha256=@{};foreach($p in $core){$bench.source_sha256[$p]=$gate.sources[$p]}
$bench.expected_source_stage_receipt=@{path=$stagePath;sha256=$stageSha;map_path=$gate.path;map_sha256=$gate.sha256};$bench.deployment_receipt=@{path=$deployPath;sha256=$deploySha};$bench.ready=$true;$bench.formal_deployed=$true;$bench.status='ROOT_DEPLOYED_EXACT29_HELPER04_WORLD_GATE_FIRST_DRAW_FRAME_GAP'
$profile=@{ready=$true;formal_deployed=$true;status='ROOT_DEPLOYED_EXACT29_PROFILE04_NATURAL_MARKET_IMAGE_ONLY';scene_id='ch4_s3_luoyang_market';whole_ms=60000;entry_ms=20000;max_pictures=1;expected_city_count=$market.sources.Count;expected_city_sources=$market.sources;source_sha256=@{};expected_source_stage_receipt=@{path=$stagePath;sha256=$stageSha;map_path=$market.path;map_sha256=$market.sha256};deployment_receipt=@{path=$deployPath;sha256=$deploySha};old_routes_or_NPC_entities_doors_replayed=$false;no_new_default_performance_credit=$true}
foreach($p in @($core+$purpose+$spec+'res://build/luoyang_city_blocks_20261024e_system01/market_use_union01_NOTREADY.gdshader')){if(-not $market.sources.ContainsKey($p)){throw ('profile source missing '+$p)};$profile.source_sha256[$p]=$market.sources[$p]}
$outGate='res://build/luoyang_city_revision_20261024e_qa01/world_gate07_PREWARM8_READY/'
$outProfile='res://build/luoyang_city_revision_20261024e_qa01/market_profile07_ONLY_READY/'
foreach($p in @($outGate,$outProfile)){if(Test-Path -LiteralPath (Abs $p)){throw 'NEW directories only'}}
$gateTemplate='res://build/luoyang_city_revision_20261024e_qa01/world_gate07_FRAME_GAP_NOTREADY/test_NOTREADY.gd'
$profileTemplate='res://build/luoyang_city_revision_20261024e_qa01/market_profile07_ONLY_NOTREADY/test_NOTREADY.gd'
foreach($r in @(@($gateTemplate,'b29104ddedea051947497fa44ea76256875ebc31364edf61d15599a0e22f4680'),@($profileTemplate,'3cf411c091435d67c102fdb37a88ddddd404eb315ce224104ff02128ba5496e4'))){if((Get-FileHash -LiteralPath (Abs $r[0])).Hash.ToLowerInvariant() -cne $r[1]){throw 'template changed'}}
# All semantic inputs pinned/validated before any output. This is mechanical data/template projection.
foreach($p in @($outGate,$outProfile)){$null=New-Item -ItemType Directory -Path (Abs $p)}
$gateFixtureSha=WriteNew ($outGate+'fixture_READY.json') ($bench|ConvertTo-Json -Depth 100)
$profileFixtureSha=WriteNew ($outProfile+'fixture_READY.json') ($profile|ConvertTo-Json -Depth 100)
function FreezeScript([string]$template,[string]$dest,$reps){$old=[IO.File]::ReadAllText((Abs $template));$new=$old;foreach($r in $reps){if(([regex]::Matches($new,[regex]::Escape($r.old))).Count -ne 1){throw 'nonunique replacement'};$new=$new.Replace($r.old,$r.new)};$back=$new;for($i=$reps.Count-1;$i -ge 0;$i--){$back=$back.Replace($reps[$i].new,$reps[$i].old)};if($back -cne $old){throw 'whole text inverse'};return @{sha256=(WriteNew $dest $new);parent_path=$template;parent_sha256=(Get-FileHash -LiteralPath (Abs $template)).Hash.ToLowerInvariant();hunks=$reps;whole_inverse=$true}}
$gr=@(@{old='const BENCH_READY := false';new='const BENCH_READY := true'},@{old='res://build/luoyang_city_revision_20261024e_qa01/world_gate07_FRAME_GAP_NOTREADY/fixture_PENDING_SOURCE_ADOPTION.json';new=($outGate+'fixture_READY.json')},@{old='PENDING_SOURCE_BOUND_HELPER04_MAP_AND_ROOT_DEPLOYMENT';new=$gateFixtureSha})
$pr=@(@{old='const PROFILE_READY := false';new='const PROFILE_READY := true'},@{old='res://build/luoyang_city_revision_20261024e_qa01/market_profile07_ONLY_NOTREADY/fixture_PENDING_FINAL_DEPLOYMENT.json';new=($outProfile+'fixture_READY.json')},@{old='PENDING_EXACT29_SOURCE_MAP_AND_ROOT_DEPLOYMENT';new=$profileFixtureSha})
$gScript=FreezeScript $gateTemplate ($outGate+'test_READY.gd') $gr
$pScript=FreezeScript $profileTemplate ($outProfile+'test_READY.gd') $pr
$proof=@{status='ROOT_DEPLOYED_EXACT29_TWO_FINITE_QA_KEYS_READY_NO_ENGINE';stage=@{path=$stagePath;sha256=$stageSha};deployment=@{path=$deployPath;sha256=$deploySha};Gate=@{fixture_sha256=$gateFixtureSha;map_path=$gate.path;map_sha256=$gate.sha256;count=$gate.sources.Count;script=$gScript};MarketProfile=@{fixture_sha256=$profileFixtureSha;map_path=$market.path;map_sha256=$market.sha256;count=$market.sources.Count;script=$pScript};whole_ms=60000;entry_ms=20000;engine_runs=0;formal_writes=0;prior11_193274_and1_575388_preserved=$true}
$proofSha=WriteNew ($outGate+'whole_byte_delta_and_fixture_provenance_READY.json') ($proof|ConvertTo-Json -Depth 50)
@{Gate_script_sha256=$gScript.sha256;Gate_fixture_sha256=$gateFixtureSha;MarketProfile_script_sha256=$pScript.sha256;MarketProfile_fixture_sha256=$profileFixtureSha;proof_sha256=$proofSha;Gate_count=$gate.sources.Count;Market_count=$market.sources.Count}|ConvertTo-Json -Compress
