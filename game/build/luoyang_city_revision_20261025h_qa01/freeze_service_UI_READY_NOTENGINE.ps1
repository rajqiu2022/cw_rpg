param([Parameter(Mandatory=$true)][string]$OutputKey,[switch]$FormalDeployed,[string]$DeploymentReceipt='', [string]$DeploymentSHA='')
$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$game=Join-Path $repo 'game';$base=Join-Path $game 'build/luoyang_city_revision_20261025h_qa01';$q='res://build/luoyang_city_revision_20261025h_qa01/'
if($OutputKey -notmatch '^[a-z][a-z0-9_]{0,40}$'){throw 'Finite NEW key only'}
$out=Join-Path $base ('service_UI_ready/'+$OutputKey);if(Test-Path -LiteralPath $out){throw 'Preserve prior freeze'}
function Sha($p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function From-Res($p){if(-not $p.StartsWith('res://') -or $p.Contains('..')){throw 'Exact res path'};Join-Path $game $p.Substring(6)}
function Assert-Hash($p,$h){if((Sha $p)-ne $h.ToLowerInvariant()){throw "Frozen byte drift $p"}}
function New-File($name,$s){$p=Join-Path $out $name;if(Test-Path -LiteralPath $p){throw 'NEW outputs only'};[IO.File]::WriteAllText($p,$s,[Text.UTF8Encoding]::new($false));$p}
$seedPath='res://build/luoyang_city_revision_20261025h_source01/services_READY02_four_room_source_seed_NOT_RUNTIME.json'
$seedSHA='23cfe26e7309461440eb42f5eded872b4a1481482449fd8171bbc33ba1f61a12';Assert-Hash (From-Res $seedPath) $seedSHA
$seed=Get-Content -LiteralPath (From-Res $seedPath) -Raw|ConvertFrom-Json -AsHashtable
$runtime='res://build/luoyang_indoor_services_20261025h_system01/runtime_READY02/services_runtime_READY.gd';$runtimeSHA='f898f4b3860dda07bdfc95d62c1b08e30889b89b93843bf9a24d808e8a433fc8'
$g='res://scripts/city/luoyang_assembled_interiors_20261016g.gd';$gSHA='537ca3d782a97144a19c6f22683833f4541640deb4a8fc981dafe3a790d09105'
$field='res://scripts/field/field_walkable_controller.gd';$fieldSHA='fcc943fe3d188da41097ca20b9abd912a9a6dc32e09ba43f15691aa30f8ef4f0'
if($seed.runtime.path-ne $runtime -or $seed.runtime.sha256-ne $runtimeSHA -or $seed.rows.Count-ne 4){throw 'Exact independent READY02 seed'}
$pins=@{'common_ui02_NOTREADY.gd'='b68662b73bfe7ded0a6cc223207ecb889f2c6dee84932ffdee69d6f13d76e00f';'ui_adapter01_NOTREADY.gd'='47ced78943c2d10d3d78fd06991dc5d9bc38dc37ec178cdd9e3353fb24d818ed';'service_oracle_NOTREADY.gd'='9a391dae4d2769e8d20f2a6f1918888f5660e1644be8681f8c427a15487ef444';'shops03_NOTREADY.gd'='b80db079cb08ee3ec8e1761b8df25e552b87e683f8b3a86b8f47b676c3156486';'inn05_NOTREADY.gd'='b8e6cbfd45e7db42b977578127746da99d4a0a75dc9899f6d25a2fb47510428d'}
foreach($name in $pins.Keys){Assert-Hash (Join-Path $base $name) $pins[$name]}
$rows=@();foreach($r in $seed.rows){
 if($r.expected_service_sources.Count -ne $r.source_scope_count -or $r.expected_service_sources[$runtime]-ne $runtimeSHA -or $r.runtime_path-ne $runtime){throw 'Exact seed scope/self'}
 foreach($pair in @(@('approach_position_px','approach_position'),@('npc_position_px','npc_position'),@('npc_body_size_px','body_size'),@('npc_body_shape_offset_px','shape_offset'),@('npc_body_position_px','body_position'))){if($r.ContainsKey($pair[0])){throw 'No alias collision'};$r[$pair[0]]=$r[$pair[1]]}
 $rows+=,$r
}
if(($rows|Where-Object role -eq 'pawn').source_npc_foot_px[0]-ne 1000 -or ($rows|Where-Object role -eq 'pawn').source_approach_px[1]-ne 650){throw 'New pawn front, no old grille pose'}
$dep=@{formal_deployed=[bool]$FormalDeployed;path=$DeploymentReceipt;sha256=$DeploymentSHA.ToLowerInvariant()}
if($FormalDeployed){if($DeploymentReceipt-eq '' -or $DeploymentSHA -notmatch '^[0-9a-fA-F]{64}$'){throw 'Root exact actual deployment receipt required'};Assert-Hash (From-Res $DeploymentReceipt) $DeploymentSHA}
[IO.Directory]::CreateDirectory($out)|Out-Null
$changes=@();$result=@()
foreach($kind in @('shops','inn')){
 $selected=@($rows);if($kind-eq 'inn'){$selected=@($rows|Where-Object{$_.role-in @('inn','smith')})}
 $sources=@{};$sources[$seedPath]=$seedSHA;$sources[$runtime]=$runtimeSHA;$sources[$g]=$gSHA;$sources[$field]=$fieldSHA
 foreach($name in @('common_ui02_NOTREADY.gd','ui_adapter01_NOTREADY.gd','service_oracle_NOTREADY.gd')){$sources[$q+$name]=$pins[$name]}
 foreach($row in $selected){foreach($p in $row.expected_service_sources.Keys){$h=$row.expected_service_sources[$p];if($sources.ContainsKey($p)-and $sources[$p]-ne $h){throw 'Scope collision'};$sources[$p]=$h};$sources[$row.scene_path]=$row.scene_sha256;$sources[$row.layout_path]=$row.layout_sha256;$sources[$row.room_author_path]=$row.room_author_sha256}
 foreach($p in $sources.Keys){if($FormalDeployed -or ($p-ne $g -and $p-ne $field)){Assert-Hash (From-Res $p) $sources[$p]}}
 $fixture=[ordered]@{ready=[bool]$FormalDeployed;formal_deployed=[bool]$FormalDeployed;status='SOURCE_DERIVED_FOUR_KEEPER_UI_EXPECTATION_NO_RUNTIME_BACKFILL';scope=$kind;whole_ms=60000;entry_ms=20000;max_pictures=1;runtime_path=$runtime;source_seed=@{path=$seedPath;sha256=$seedSHA};source_sha256=$sources;deployment=$dep}
 if($kind-eq 'shops'){$fixture.rooms=$rows;$parent='shops03_NOTREADY.gd';$outputOld='/shops03_output/';$scopeOld='25H_SHOPS03_HARDFALSE_SOURCE_FINAL_PENDING'}
 else{$fixture.inn=@($rows|Where-Object role -eq 'inn')[0];$fixture.owner_change_target=@($rows|Where-Object role -eq 'smith')[0];$fixture.meal_price=5;$fixture.lodging_price=20;$fixture.full_party_policy='NO_CHARGE_REJECT';$parent='inn05_NOTREADY.gd';$outputOld='/inn05_output/';$scopeOld='25H_INN05_HARDFALSE_FINAL_SOURCE_PENDING'}
 $fp=New-File ($kind+'_fixture.json') (($fixture|ConvertTo-Json -Depth 32)+"`n");$fres=$q+'service_UI_ready/'+$OutputKey+'/'+$kind+'_fixture.json';$fsha=Sha $fp
 $old=[IO.File]::ReadAllText((Join-Path $base $parent));$new=$old
 $pending=if($kind-eq 'shops'){'PENDING_SOURCE25H_FOUR_ROOM_FIXTURE'}else{'PENDING_SOURCE25H_INN_FINAL_FIXTURE'}
 if($new.Split('const READY25H=false',[StringSplitOptions]::None).Count-ne 2){throw 'Exact parent readiness'}
 $new=$new.Replace('const READY25H=false','const READY25H='+([bool]$FormalDeployed).ToString().ToLowerInvariant()).Replace($pending+'_SHA',$fsha).Replace($pending,$fres)
 $new=$new.Replace($outputOld,'/service_UI_ready/'+$OutputKey+'/'+$kind+'_output/').Replace($scopeOld,'25H_'+$kind.ToUpperInvariant()+'_FINITE_REAL_UI_SOURCE_READY02')
 $key=New-File ($kind+'_READY.gd') $new
 $changes+=@{parent=$q+$parent;parent_sha256=$pins[$parent];child=$q+'service_UI_ready/'+$OutputKey+'/'+$kind+'_READY.gd';child_sha256=Sha $key;old_text=$old;new_text=$new;reverse_old_text=$new;reverse_new_text=$old}
 $result+=@{kind=$kind;key=$changes[-1].child;sha256=$changes[-1].child_sha256;fixture=$fres;fixture_sha256=$fsha;formal_deployed=[bool]$FormalDeployed}
}
$inverse=New-File 'mechanical_whole_inverse.json' ((@{status='ONLY_SOURCE_ALIASES_READY_FIXTURE_OUTPUT_LABEL_NO_FUNCTION_CHANGES';source_seed=@{path=$seedPath;sha256=$seedSHA};deployment=$dep;changes=$changes;engine_calls=0;formal_writes=0;old_pure28_replayed=$false}|ConvertTo-Json -Depth 32)+"`n")
@{result=$result;inverse_sha256=Sha $inverse;source_derived=$true;engine_calls=0}|ConvertTo-Json -Depth 6
