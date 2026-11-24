$ErrorActionPreference='Stop'
$game='F:/Code/RPG_GAME/game';$base=Join-Path $game 'build/luoyang_city_revision_20261025h_qa01';$q='res://build/luoyang_city_revision_20261025h_qa01/';$keyName='remaining02';$out=Join-Path $base ('service_UI_ready/'+$keyName)
if(Test-Path -LiteralPath $out){throw 'NEW keys only'}
function Sha($p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function Path-Res($p){if(-not $p.StartsWith('res://')-or $p.Contains('..')){throw 'Exact res path'};Join-Path $game $p.Substring(6)}
function Assert-Pin($p,$h){if((Sha (Path-Res $p))-ne $h){throw "Frozen byte drift $p"}}
$newPins=@{'common_ui03_NOTREADY.gd'='e03386f44fb323256ee810cfae17cc8c51ca6fe20a94f1a3c0ed33c2855e5daa';'ui_adapter02_NOTREADY.gd'='9bfd2e99ea315e98da7d0c9d21b6e015ba4b22fb48f510ec989fbf44439679af';'shops04_remainder_NOTREADY.gd'='2f847f8ae7bdc4b8b3dc189f4ad21a0a3df826bd484874db76db9257bc5227a2';'inn06_remainder_NOTREADY.gd'='6aa24ecdefa237dfc1f6bd6e17ffe8c820a4cb41d6c5b531b83c168ddf74694c'}
foreach($name in $newPins.Keys){Assert-Pin ($q+$name) $newPins[$name]}
[IO.Directory]::CreateDirectory($out)|Out-Null
function New-File($name,$text){$p=Join-Path $out $name;if(Test-Path -LiteralPath $p){throw 'Preserve existing'};[IO.File]::WriteAllText($p,$text,[Text.UTF8Encoding]::new($false));$p}
$diff=@();$result=@()
foreach($kind in @('shops','inn')){
 $oldFixture=$q+'service_UI_ready/formal01/'+$kind+'_fixture.json';$oldSHA=if($kind-eq 'shops'){'41bfa6e75e1c052dbea2556033a704de2dc46f767e99f90a457e326f8e586132'}else{'f9c2d0536f2e2c76ca654e176f7df80f396e93502eee015ba244a1d91307c8f4'}
 Assert-Pin $oldFixture $oldSHA;$fixture=Get-Content -LiteralPath (Path-Res $oldFixture) -Raw|ConvertFrom-Json -AsHashtable
 if($fixture.ready-ne $true -or $fixture.formal_deployed-ne $true){throw 'Prior actual formal fixture only'}
 if($kind-eq 'shops'){$fixture.rooms=@($fixture.rooms|Where-Object{$_.role-ne 'inn'});if($fixture.rooms.Count-ne 3){throw 'Exactly pawn/herbal/smith remaining'};$parent='shops04_remainder_NOTREADY.gd';$pending='PENDING_SOURCE25H_FOUR_ROOM_FIXTURE';$outputOld='/shops04_remainder_output/'}
 else{$parent='inn06_remainder_NOTREADY.gd';$pending='PENDING_SOURCE25H_INN_FINAL_FIXTURE';$outputOld='/inn06_remainder_output/'}
 $fixture.source_sha256.Remove($q+'common_ui02_NOTREADY.gd');$fixture.source_sha256.Remove($q+'ui_adapter01_NOTREADY.gd')
 $fixture.source_sha256[$q+'common_ui03_NOTREADY.gd']=$newPins['common_ui03_NOTREADY.gd'];$fixture.source_sha256[$q+'ui_adapter02_NOTREADY.gd']=$newPins['ui_adapter02_NOTREADY.gd']
 $fixture.source_static_camera=@{design_size=@(1536,1024);viewport=@(1920,1080);world_size=@(1920,1280);zoom=1;scroll_camera=$false;world_position=@(0,-100);world_scale=@(1,1);Camera2D='NULL';source='Fixed Field._should_scroll_camera/_setup_world_camera and source four-room1536x1024/cover1920x1280'}
 $fixture.inherited_actual71508=@{report=$q+'service_UI_ready/formal01/shops_output/71508_2834/result.json';whole_status='FAIL_RETAINED_CAMERA_ORACLE_ONLY';passed_components=@('inn8_source_actor_hero_menu_leave','pawn91_source_actor_body_hero_menu');not_new_credit=$true}
 foreach($p in $fixture.source_sha256.Keys){Assert-Pin $p $fixture.source_sha256[$p]}
 Assert-Pin $fixture.deployment.path $fixture.deployment.sha256
 $fp=New-File ($kind+'_fixture.json') (($fixture|ConvertTo-Json -Depth 32)+"`n");$fres=$q+'service_UI_ready/'+$keyName+'/'+$kind+'_fixture.json';$fsha=Sha $fp
 $old=[IO.File]::ReadAllText((Join-Path $base $parent));$new=$old.Replace('const READY25H=false','const READY25H=true').Replace($pending+'_SHA',$fsha).Replace($pending,$fres).Replace($outputOld,'/service_UI_ready/'+$keyName+'/'+$kind+'_output/')
 $new=$new.Replace('25H_SHOPS04_REMAINDER_HARDFALSE_FINAL_PENDING','25H_THREE_SHOPS_REMAINING_STATIC_SOURCE_CAMERA').Replace('25H_INN06_REMAINDER_HARDFALSE_FINAL_PENDING','25H_INN_SERVICES_REMAINING_STATIC_SOURCE_CAMERA')
 $kp=New-File ($kind+'_READY.gd') $new
 $diff+=@{parent=$q+$parent;parent_sha256=$newPins[$parent];child=$q+'service_UI_ready/'+$keyName+'/'+$kind+'_READY.gd';child_sha256=Sha $kp;old_text=$old;new_text=$new;reverse_old_text=$new;reverse_new_text=$old}
 $result+=@{kind=$kind;key=$diff[-1].child;sha256=$diff[-1].child_sha256;fixture_sha256=$fsha}
}
$dp=New-File 'whole_byte_inverse.json' ((@{status='ROOT_APPROVED_CAMERA_REMAINDER_DATA_ONLY_READY';changes=$diff;production_writes=0;engine_calls=0;whole_ms=60000;entry_ms=20000;max_images=2;original71508_whole_FAIL_preserved=$true;pure28_replayed=$false}|ConvertTo-Json -Depth 9)+"`n")
@{keys=$result;inverse_sha256=Sha $dp;engine_calls=0}|ConvertTo-Json -Depth 5
