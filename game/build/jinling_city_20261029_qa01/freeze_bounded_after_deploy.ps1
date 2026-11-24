param([Parameter(Mandatory=$true)][string]$AuthorizationJson)
$ErrorActionPreference='Stop'
$taskRoot='F:\Code\RPG_GAME';$qaRoot=Join-Path $taskRoot 'game/build/jinling_city_20261029_qa01'
function ResolveFactPath([string]$p){if($p.StartsWith('res://')){return Join-Path $taskRoot ('game/'+$p.Substring(6))};if([IO.Path]::IsPathRooted($p)){return $p};return Join-Path $taskRoot $p}
function Fact([string]$p){$p=ResolveFactPath $p;if(-not [IO.File]::Exists($p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant();bytes=$i.Length;utc_ticks=$i.LastWriteTimeUtc.Ticks.ToString()}}
function Same($a,$b){return $a.exists -eq $b.exists -and (-not $a.exists -or ($a.sha256 -ceq $b.sha256 -and $a.bytes -eq $b.bytes -and $a.utc_ticks -ceq $b.utc_ticks))}
function WriteNew([string]$p,[byte[]]$bytes){$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()}}
$fixturePath=Join-Path $qaRoot 'jinling_bounded_READY.json';$scriptPath=Join-Path $qaRoot 'jinling_bounded_READY.gd'
if([IO.File]::Exists($fixturePath) -or [IO.File]::Exists($scriptPath)){throw 'READY is CreateNew only; preserve original package.'}
$baseline=Get-Content -LiteralPath (Join-Path $qaRoot 'baseline_before_ACTUAL.json') -Raw|ConvertFrom-Json
$auth=Get-Content -LiteralPath (ResolveFactPath $AuthorizationJson) -Raw|ConvertFrom-Json
$sources=[ordered]@{};$hashes=[ordered]@{}
foreach($entry in $baseline.sources.PSObject.Properties){
 $now=Fact $entry.Name;$permit=$auth.sources.PSObject.Properties[$entry.Name]
 if($null -eq $permit){if(-not (Same $now $entry.Value)){throw "Unauthorized baseline source changed: $($entry.Name)"}}
 elseif(-not $now.exists -or $now.sha256 -cne $permit.Value.sha256 -or $now.bytes -ne $permit.Value.bytes){throw "Authorized source not exactly deployed: $($entry.Name)"}
 $sources[$entry.Name]=$now;$hashes[(ResolveFactPath $entry.Name)]=$now.sha256
}
foreach($entry in $auth.sources.PSObject.Properties){if($null -eq $baseline.sources.PSObject.Properties[$entry.Name]){throw "Authorization outside bounded old source scope: $($entry.Name)"}}
foreach($entry in $auth.new_modules.PSObject.Properties){$now=Fact $entry.Name;if(-not $now.exists -or $now.sha256 -cne $entry.Value.sha256 -or $now.bytes -ne $entry.Value.bytes){throw "New candidate not final: $($entry.Name)"};$sources[$entry.Name]=$now;$hashes[(ResolveFactPath $entry.Name)]=$now.sha256}
$water=Get-Content -LiteralPath (Join-Path $taskRoot 'game/build/jinling_city_20261029_art01/water_promotion_ROOT_ACTUAL.json') -Raw|ConvertFrom-Json
if($water.status -cne 'PASS_THREE_NEW_WATER_LEAVES' -or @($water.facts.PSObject.Properties).Count -ne 3){throw 'Only the existing promoted three water leaves are accepted.'}
foreach($entry in $water.facts.PSObject.Properties){if(-not (Same (Fact $entry.Name) $entry.Value)){throw "Promoted water leaf changed: $($entry.Name)"}}
foreach($entry in $baseline.related_original_media.PSObject.Properties){if(-not (Same (Fact $entry.Name) $entry.Value)){throw "Original related media changed: $($entry.Name)"}}
$saves=[ordered]@{};foreach($entry in $baseline.save15.PSObject.Properties){$saves[$entry.Name]=Fact $entry.Name}
$spec=[ordered]@{
 ready=$true;whole_seconds=90;entry_seconds=20;max_png=1
 baseline='res://build/jinling_city_20261029_qa01/baseline_before_ACTUAL.json'
 source_facts=$sources;fixed_sources=$hashes;save15=$saves;new_water_facts=$water.facts
 authorization_sha256=(Fact $AuthorizationJson).sha256
 world_id='world_map_jianghu';world_size=@(12288,8192);world_setup_foot=@(8100,6492.0938)
 city_id='openworld_jinling_city';city_field='res://build/jinling_city_20261029_system01/jinling_field.gd'
 author='res://build/jinling_city_20261029_system01/city_author.gd';size=@(5632,4096);city_arrival_foot=@(2816,3920)
 live_foot_method='is_jinling_foot_safe_native'
 bridge_probes=@(
  @{id='west';safe=@(@(1536,1980),@(1536,2300),@(1536,2660));water=(,@(900,2300))},
  @{id='east';safe=@(@(4096,1980),@(4096,2300),@(4096,2660));water=(,@(2816,2300))}
 )
 route_to_guide=@(@(2816,3900),@(1536,3900),@(1536,1980),@(4500,1980),@(4500,1950))
 guide=@{npc_id='jinling_water_patrol';name='金陵水巡';dialog_id='openworld_jinling_guide';hero_name='冷孤云';hero_portrait='res://art/characters/protagonist_portrait.png';hero_text='叨扰了，这一带平日可还安稳？'}
 route_to_merchant=@(@(4500,1980),@(2590,1980),@(2590,1950))
 merchant=@{npc_id='jinling_merchant';name='绸缎商人';action='shop:lingyue_pavilion'}
 route_to_capture=@(@(2590,1980),@(1536,1980),@(1536,2300))
 route_to_world_exit=@(@(1536,3900),@(2816,3900),@(2816,4000))
 default_world_travel_claim=$false;qa_actor_pose_writes=0;qa_game_camera_writes=0;local_version_dict_writes=0
 route_distance_native_px=12568;nominal_movement_seconds_at_480=26.1833333333
}
WriteNew $scriptPath ([IO.File]::ReadAllBytes((Join-Path $qaRoot 'jinling_bounded_DRAFT.gd')))
WriteNew $fixturePath ([Text.UTF8Encoding]::new($false).GetBytes(($spec|ConvertTo-Json -Depth 30)+"`n"))
[ordered]@{script=$scriptPath;script_sha256=(Fact $scriptPath).sha256;fixture=$fixturePath;fixture_sha256=(Fact $fixturePath).sha256;source_count=$sources.Count;engine_calls=0;save_writes=0}|ConvertTo-Json -Compress
