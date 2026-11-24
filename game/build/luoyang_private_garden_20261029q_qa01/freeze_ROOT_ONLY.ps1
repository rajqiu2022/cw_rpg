param([Parameter(Mandatory=$true)][string]$Auth)
$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/luoyang_private_garden_20261029q_qa01"
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
function Same($a,$v){return $a.exists -eq $v.exists -and (!$a.exists -or ($a.sha256 -eq $v.sha256 -and $a.bytes -eq $v.bytes -and $a.utc_ticks -eq $v.utc_ticks))}
function NewJson([string]$p,$v){$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($v | ConvertTo-Json -Depth 25)+"`n");$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()}}
$b=Get-Content "$qa/baseline_before_ACTUAL.json" -Raw | ConvertFrom-Json
$field=Get-Content "$qa/field_before_SUPPLEMENT.json" -Raw | ConvertFrom-Json
$parent=Get-Content "$qa/parallel_parent_before_SUPPLEMENT.json" -Raw | ConvertFrom-Json
$media=Get-Content "$qa/media_after_import_SUPPLEMENT.json" -Raw | ConvertFrom-Json
$a=Get-Content -LiteralPath $Auth -Raw | ConvertFrom-Json
$authorized=@{};foreach($section in @($a.sources,$a.new_modules)){foreach($p in $section.PSObject.Properties){$authorized[$p.Name]=$p.Value}}
$fieldPath='game/build/luoyang_regions_20261027d_source01/region_field.gd'
if(@($a.sources.PSObject.Properties).Count -ne 12){throw 'EXACT12_TARGETS_REQUIRED'}
foreach($p in $a.sources.PSObject.Properties){if($null -eq $b.sources.($p.Name) -and $p.Name -ne $fieldPath){throw "UNPLANNED_TARGET:$($p.Name)"}}
$all=[ordered]@{};$fixed=[ordered]@{};$external=[ordered]@{};$saves=[ordered]@{}
foreach($section in @($b.sources,$b.protected_sources)){
 foreach($p in $section.PSObject.Properties){$f=Fact "$repo/$($p.Name)";if(!$authorized.ContainsKey($p.Name) -and !(Same $f $p.Value)){throw "LOCAL_PROTECTION:$($p.Name)"};$all[$p.Name]=$f}
}
foreach($path in $authorized.Keys){$f=Fact "$repo/$path";if($f.sha256 -ne $authorized[$path].sha256 -or $f.bytes -ne $authorized[$path].bytes){throw "AUTH:$path"};$all[$path]=$f}
foreach($p in $media.facts.PSObject.Properties){$f=Fact "$repo/$($p.Name)";if(!(Same $f $p.Value)){throw "MEDIA:$($p.Name)"};$all[$p.Name]=$f}
$backups=@($b.exact_backups)+@($field)+@($parent.exact_backups)
foreach($p in $backups){if(!(Same (Fact $p.path) $p.fact)){throw "BACKUP:$($p.path)"}}
foreach($p in $parent.registered_save_paths.PSObject.Properties){$f=Fact $p.Name;if(!(Same $f $p.Value)){throw "NEW_EXTERNAL_SAVE_PRESERVE_AND_REPORT:$($p.Name)"};$saves[$p.Name]=$f}
foreach($p in $b.external_parallel_sources.PSObject.Properties){$external[$p.Name]=Fact "$repo/$($p.Name)"}
foreach($path in $all.Keys){$fixed['res://'+$path.Substring(5)]=$all[$path].sha256}
# Plain finite keyboard segments, rounded to the arrival's 8px grid. Split
# diagonal garden bends into <=32px pieces; no adaptive controller/teleport.
$script:cx=1536;$script:cy=1450;$script:steps=[Collections.Generic.List[object]]::new()
function Axis([int]$x,[int]$y,[string]$label){
 if($x -ne $script:cx){$dx=$x-$script:cx;$script:steps.Add(@{id=$label+'_x';key=$(if($dx -gt 0){68}else{65});ticks=[int]([Math]::Abs($dx)/8);end=@($x,$script:cy)});$script:cx=$x}
 if($y -ne $script:cy){$dy=$y-$script:cy;$script:steps.Add(@{id=$label+'_y';key=$(if($dy -gt 0){83}else{87});ticks=[int]([Math]::Abs($dy)/8);end=@($script:cx,$y)});$script:cy=$y}
}
function To([int]$x,[int]$y,[string]$label,[string]$capture=''){
 $sx=$script:cx;$sy=$script:cy;$n=if($sx -ne $x -and $sy -ne $y){[int][Math]::Ceiling([Math]::Max([Math]::Abs($x-$sx),[Math]::Abs($y-$sy))/32)}else{1}
 for($i=1;$i -le $n;$i++){$tx=[int](1536+8*[Math]::Floor((($sx+($x-$sx)*$i/$n)-1536)/8+.5));$ty=[int](1450+8*[Math]::Floor((($sy+($y-$sy)*$i/$n)-1450)/8+.5));Axis $tx $ty ($label+'_'+$i)}
 if($capture){$script:steps[$script:steps.Count-1].capture=$capture}
}
To 1536 1138 'rear_link';To 1536 434 'pond_east_bank' 'pond_side';To 1128 298 'west_north_curve';To 744 298 'west_north';To 528 434 'west_upper_curve';To 528 1034 'west_bank';To 744 1138 'west_lower_curve';To 1536 1138 'west_return';To 2360 1138 'east_lower_path';To 2560 1034 'east_flower_curve' 'east_flowers';To 2360 1138 'east_flower_return';To 1536 1138 'return_axis';To 1536 1450 'new_rear_portal'
$fixture=[ordered]@{ready=$true;scope='Single formal hall north/private garden loop/new back entrance/hall south return; two garden images, no prior matrices';source_region='luoyang_estate_region_27d';source_logical='luoyang_estate_riverside_20261021ai';legacy_estate_uv=@(.5,.947265625);room_id='estate27d_living_hall';hall_north_id='estate27d_living_hall_rear_door';hall_south_id='estate27d_living_hall_exit';garden_back_id='estate27q_hall_rear_door';garden_arrival=@(1536,1450);new_block_old_safe=@(950,700);old_block_still_rejected=@(2407,681);body_blocks=@(@{id='native_water_and_bank';foot=@(950,700)},@{id='high_peony_stone_base';foot=@(1980,592)},@{id='new_south_tree_trunks';foot=@(2400,970)});garden_steps=@($script:steps.ToArray());room_exit_steps=@(@{id='north_to_west_aisle';key=65;ticks=39;end=@(648,240)},@{id='south_west_aisle';key=83;ticks=118;end=@(648,1184)},@{id='south_axis';key=68;ticks=39;end=@(960,1184)},@{id='original_south_door';key=83;ticks=15;end=@(960,1304)});fixed_sources=$fixed;registered_save_paths=@($saves.Keys)}
NewJson "$qa/garden_READY.json" $fixture
$text=[IO.File]::ReadAllText("$qa/garden_DRAFT.gd").Replace("`r`n","`n").TrimEnd([char[]]"`r`n")+"`n";$bytes=[Text.UTF8Encoding]::new($false).GetBytes($text);$s=[IO.File]::Open("$qa/garden_READY.gd",[IO.FileMode]::CreateNew);try{$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()}
NewJson "$qa/freeze_ROOT_ACTUAL.json" ([ordered]@{status='FROZEN_LOCAL_GARDEN_ONLY_WITH_RECORDED_PARALLEL_SOURCES';sources=$all;exact_backups=$backups;saves=$saves;external_run_before=$external;external_historical=$b.external_parallel_sources;external_policy='Record only, never restore or treat as this task writes';parallel_parent=(Fact "$qa/parallel_parent_before_SUPPLEMENT.json");script=(Fact "$qa/garden_READY.gd");fixture=(Fact "$qa/garden_READY.json");auth=(Fact $Auth);engine_calls=0;production_writes=0;save_writes=0})
Get-FileHash -LiteralPath "$qa/garden_READY.gd","$qa/garden_READY.json","$qa/freeze_ROOT_ACTUAL.json" | Select-Object Path,Hash | ConvertTo-Json
