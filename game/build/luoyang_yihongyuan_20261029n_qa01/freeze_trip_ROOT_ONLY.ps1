$ErrorActionPreference='Stop'
$qa='F:/Code/RPG_GAME/game/build/luoyang_yihongyuan_20261029n_qa01'
$repo='F:/Code/RPG_GAME'
$b=Get-Content "$qa/baseline_before_ACTUAL.json" -Raw | ConvertFrom-Json
$a=Get-Content "$repo/game/build/luoyang_yihongyuan_20261029n_system01/closure_READY01/auth_READY.json" -Raw | ConvertFrom-Json
function Fact([string]$p){
 if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}}
 $i=Get-Item -LiteralPath $p
 return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}
}
function EqualFact($x,$y){return $x.exists -eq $y.exists -and (!$x.exists -or ($x.sha256 -eq $y.sha256 -and $x.bytes -eq $y.bytes -and $x.utc_ticks -eq $y.utc_ticks))}
function NewJson([string]$p,$v){$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew);try{$u=[Text.UTF8Encoding]::new($false);$z=$u.GetBytes(($v | ConvertTo-Json -Depth 30)+"`n");$s.Write($z,0,$z.Length)}finally{$s.Dispose()}}
$fixed=[ordered]@{};$all=[ordered]@{}
foreach($section in @($a.sources,$a.new_modules)){
 foreach($p in $section.PSObject.Properties){$f=Fact "$repo/$($p.Name)";if($f.sha256 -ne $p.Value.sha256 -or $f.bytes -ne $p.Value.bytes){throw "AUTH $($p.Name)"};$all[$p.Name]=$f;$fixed['res://'+$p.Name.Substring(5)]=$f.sha256}
}
foreach($p in $b.protected_sources.PSObject.Properties){$f=Fact "$repo/$($p.Name)";if(!(EqualFact $f $p.Value)){throw "PROTECTED $($p.Name)"};$all[$p.Name]=$f;$fixed['res://'+$p.Name.Substring(5)]=$f.sha256}
foreach($p in $b.exact_backups){if(!(EqualFact (Fact $p.path) $p.fact)){throw "BACKUP $($p.path)"}}
$saves=[ordered]@{}
foreach($p in $b.registered_save_paths.PSObject.Properties){$f=Fact $p.Name;if(!(EqualFact $f $p.Value)){throw "SAVE_EXTERNAL_CHANGE $($p.Name)"};$saves[$p.Name]=$f}
$extra=@('game/data/scenes/yihongyuan27n_interior.tres','game/art/maps/luoyang_yihongyuan_20261029n/yihongyuan_exterior_v1.png')
$promotion=Get-Content "$qa/art_promotion_ROOT_ACTUAL.json" -Raw | ConvertFrom-Json
foreach($p in $promotion.promoted){if(!(EqualFact (Fact $p.path) $p.fact)){throw 'ART_LEAF'};$extra+=$p.path.Substring($repo.Length+1)}
foreach($p in $extra){$f=Fact "$repo/$p";if(!$f.exists){throw "MISSING $p"};$all[$p]=$f;$fixed['res://'+$p.Substring(5)]=$f.sha256}
$fixture=[ordered]@{
 ready=$true;scope='ONLY_THIS_BUILDING; direct legal Market setup, not World travel; two native screenshots'
 market_legacy_setup_uv=@(.75,.85);market_arrival_foot=@(4520,4560);exterior_region='luoyang_civic_market_region_27d'
 outside_steps=@(@{id='SE_TO_DOOR_AXIS';key=68;ticks=86;end=@(5208,4560)},@{id='NORTH_TO_REAL_DOOR';key=87;ticks=47;end=@(5208,4184)})
 body_points=@(@{id='LEFT_SOLID_BASE';foot=@(4902.0197,4059.2077);clear=$false},@{id='RIGHT_SOLID_BASE';foot=@(5650.8997,4082.2501);clear=$false},@{id='CENTRAL_APRON';foot=@(5206.18017578125,4185);clear=$true})
 entrance_portal_id='enter_yihongyuan27n';room_id='yihongyuan27n_interior';room_arrival_foot=@(768,850)
 room_to_keeper_steps=@(@{id='HALL_CENTRAL_NORTH';key=87;ticks=33;end=@(768,586)},@{id='COUNTER_FRONT';key=68;ticks=48;end=@(1152,586)})
 keeper_id='yihongyuan27n_matron';keeper_name='掌事';keeper_portrait='res://art/modules/redrock_luoyang_standard_20261028b/keeper_portrait.png'
 keeper_lines=@('坐吧，茶水在桌上。过道留宽些，伙计端着热壶来回走。')
 room_to_exit_steps=@(@{id='COUNTER_TO_CENTRE';key=65;ticks=48;end=@(768,586)},@{id='EXIT_ZONE_NOT_SOURCE_SPAWN';key=83;ticks=41;end=@(768,914)})
 exit_portal_id='yihongyuan27n_exit';authored_return_foot=@(5206.18017578125,4280)
 fixed_sources=$fixed;registered_save_paths=@($saves.Keys)
 inherited_publication='58540:33/0; not replayed';original_publication_failure='133240:YIHONG_COUNTER_FRONT retained'
}
NewJson "$qa/trip_READY.json" $fixture
$scriptBytes=[IO.File]::ReadAllBytes("$qa/trip_DRAFT.gd")
$stream=[IO.File]::Open("$qa/trip_READY.gd",[IO.FileMode]::CreateNew);try{$stream.Write($scriptBytes,0,$scriptBytes.Length)}finally{$stream.Dispose()}
NewJson "$qa/trip_freeze_ROOT_ACTUAL.json" ([ordered]@{status='FROZEN_LOCAL_BUILDING_ONLY';sources=$all;exact_backups=$b.exact_backups;saves=$saves;script=(Fact "$qa/trip_READY.gd");fixture=(Fact "$qa/trip_READY.json");engine_calls=0;production_writes=0;save_writes=0;processes_stopped=0})
Get-FileHash -LiteralPath "$qa/trip_READY.gd","$qa/trip_READY.json","$qa/trip_freeze_ROOT_ACTUAL.json" -Algorithm SHA256 | Select-Object Path,Hash | ConvertTo-Json
