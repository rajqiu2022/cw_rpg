$ErrorActionPreference='Stop'
$taskRoot='F:\Code\RPG_GAME'
$qaRoot=Join-Path $taskRoot 'game/build/major_cities_20261028_qa04'
$candidate='game/build/bianzhou_city_20261028_system04/'
$pins=[ordered]@{
 ($candidate+'city_author.gd')='422dd31ea43624bc1bfd9036166d2d594f790195bc12b4d029a9286a760e5d74'
 ($candidate+'completion_binding_BUILD.json')='bcb3569b401e1f77ea24c4245c873639147291b5f80811bc7f5c992bcb4ca61c'
 ($candidate+'gate_binding_BUILD.json')='727ae6c24e18caf9684de1d9df2103340f64aaf11f28996b0cfd94af977b9233'
}
function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function WriteNew([string]$p,[byte[]]$bytes){$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()}}
$fixed=[ordered]@{}
foreach($p in $pins.Keys){if((Sha (Join-Path $taskRoot $p)) -ne $pins[$p]){throw "Freeze source mismatch: $p"};$fixed['res://'+$p.Substring(5)]=$pins[$p]}
$prior='res://build/major_cities_20261028_qa04/source_before/game/build/bianzhou_city_20261028_system01/city_author.gd'
$fixed[$prior]=Sha (Join-Path $taskRoot ('game/'+$prior.Substring(6)))
$completion=Get-Content -LiteralPath (Join-Path $taskRoot ($candidate+'completion_binding_BUILD.json')) -Raw|ConvertFrom-Json
$gate=Get-Content -LiteralPath (Join-Path $taskRoot ($candidate+'gate_binding_BUILD.json')) -Raw|ConvertFrom-Json
$art='res://build/major_cities_20261028_art04/selected_four_native_binding_PROPOSAL.json';$fixed[$art]=Sha (Join-Path $taskRoot ('game/'+$art.Substring(6)))
$routes=@(
 @{id='01_south_to08_north_with_honest_trader_detour';points=@(@(3072,5910),@(3072,530),@(3150,530),@(3150,380),@(3072,380),@(3072,245.76))},
 @{id='02_04_07_north_cross';points=@(@(260,2100),@(5880,2100))},
 @{id='01_02_03_04_06_south_cross';points=@(@(260,4456),@(5880,4456))},
 @{id='05_04_06_west_ring_inside_wall';points=@(@(1450,1000),@(1450,4970))},
 @{id='07_03_01_east_ring_inside_wall';points=@(@(4510,1000),@(4510,4970))},
 @{id='05_west_home_to_cross';points=@(@(620,1958),@(1280,1958),@(1280,2100))},
 @{id='05_east_home_to_cross';points=@(@(2020,1958),@(2710,1958),@(2710,2100))},
 @{id='07_book_notice_court_to_cross';points=@(@(3910,1788),@(4350,1788),@(4350,2100))},
 @{id='07_original_board_approach';points=@(@(3600,2140),@(3600,2020))},
 @{id='03_post_front_to_ring';points=@(@(5240,2818),@(5240,3000),@(4510,3000))},
 @{id='03_original_guide_approach';points=@(@(4780,3000),@(4780,2890))},
 @{id='03_post_shed_side_court';points=@(@(5550,3520),@(5550,3600),@(5900,3600),@(5900,3000),@(4510,3000))},
 @{id='01_southeast_cart_court';points=@(@(5300,4970),@(4510,4970),@(4510,4456))},
 @{id='06_workshop_to_cross';points=@(@(1600,4868),@(1285,4868),@(1285,4456),@(1450,4456))},
 @{id='04_cargo_service_with_new_patrol_detour';points=@(@(1280,2780),@(1360,2780),@(1360,4200),@(1280,4200))}
)
$connections=@()
foreach($side in @('north','south')){
 $connections+=@{id=$side+'_west_horizontal_join';a=$side+'_true_wall_west_0';b=$side+'_true_wall_west_1'}
 $connections+=@{id=$side+'_east_horizontal_join';a=$side+'_true_wall_east_0';b=$side+'_true_wall_east_1'}
 $connections+=@{id=$side+'_west_gate_join';a=$side+'_true_wall_west_1';b=$side+'_gate_west_wing'}
 $connections+=@{id=$side+'_east_gate_join';a=$side+'_true_wall_east_0';b=$side+'_gate_east_wing'}
}
foreach($side in @('west','east')){
 $parts=@($gate.blockers|Where-Object {$_.id -like ($side+'_wall_*')})
 for($i=0;$i -lt $parts.Count-1;$i++){$connections+=@{id=$side+'_native_segment_'+$i;a=$parts[$i].id;b=$parts[$i+1].id}}
 $cornerIndex=if($side -eq 'west'){'0'}else{'1'}
 $connections+=@{id=$side+'_north_corner';a='north_true_wall_'+$side+'_'+$cornerIndex;b=$side+'_wall_north_complete_cap'}
 $connections+=@{id=$side+'_south_corner';a='south_true_wall_'+$side+'_'+$cornerIndex;b=$side+'_wall_south_complete_cap'}
}
$fixture=[ordered]@{ready=$true;media_status='PENDING_RGBA_IMPORT';scope='Candidate Author mathematics only; no formal Field/PNG loaded and no art/gameplay admission';baseline='res://build/major_cities_20261028_qa04/baseline_before_ACTUAL.json';author='res://build/bianzhou_city_20261028_system04/city_author.gd';prior_author=$prior;gate_binding='res://build/bianzhou_city_20261028_system04/gate_binding_BUILD.json';completion_binding='res://build/bianzhou_city_20261028_system04/completion_binding_BUILD.json';fixed_sources=$fixed;domain_count=134;npc_count=44;patrol_count=6;source_contracts=$completion.assets;unaffected_feet=@(@(3072,5910),@(3072,6020),@(3102.72,245.76),@(3072,4900),@(4510,3000));v1_feet=@(@(.505,.9),@(.5,.18),@(.3,.52),@(.8,.52));routes=$routes;wall_connections=$connections}
foreach($p in $pins.Keys){if((Sha (Join-Path $taskRoot $p)) -ne $pins[$p]){throw 'Source changed while freezing.'}}
$json=Join-Path $qaRoot 'completion_geometry_READY.json';$gd=Join-Path $qaRoot 'completion_geometry_READY.gd'
WriteNew $json ([Text.UTF8Encoding]::new($false).GetBytes(($fixture|ConvertTo-Json -Depth 30)+"`n"))
WriteNew $gd ([IO.File]::ReadAllBytes((Join-Path $qaRoot 'completion_geometry_DRAFT.gd')))
[ordered]@{script=$gd;sha256=(Sha $gd);fixture=$json;fixture_sha256=(Sha $json);routes=$routes.Count;wall_connections=$connections.Count;engine_calls=0}|ConvertTo-Json -Compress
