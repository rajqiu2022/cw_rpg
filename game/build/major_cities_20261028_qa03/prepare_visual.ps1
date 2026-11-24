$ErrorActionPreference='Stop'
$taskRoot='F:\Code\RPG_GAME';$qaRoot=Join-Path $taskRoot 'game\build\major_cities_20261028_qa03'
$before=Get-Content -LiteralPath (Join-Path $taskRoot 'game\build\major_cities_20261028_qa02\baseline_before_ACTUAL.json') -Raw|ConvertFrom-Json
function Fact([string]$p){$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant();bytes=$i.Length;utc_ticks=$i.LastWriteTimeUtc.Ticks.ToString()}}
function WriteNew([string]$p,$data){$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($data|ConvertTo-Json -Depth 16)+"`n");$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew);try{$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()}}
$expected=@{'game/build/bianzhou_city_20261028_system01/city_author.gd'='f1cc4bff9401b1f8ba52b461f64fa178d49aa1f4bf57d24e24ceda985cf1821f';'game/build/bianzhou_city_20261028_system01/bianzhou_field.gd'='27e8f4ce2e1669ff4ef1816a1e39134e710f5eee18210f32e4f4095f01fa8831'}
$fixed=[ordered]@{}
foreach($p in $before.sources12.PSObject.Properties){$now=Fact (Join-Path $taskRoot $p.Name);$wanted=if($expected.ContainsKey($p.Name)){$expected[$p.Name]}else{$p.Value.sha256};if($now.sha256 -ne $wanted){throw "Unexpected source: $($p.Name)"};$fixed['res://'+$p.Name.Substring(5)]=$now.sha256}
$protected=[ordered]@{};$entry='game/build/bianzhou_city_20261028_system01/router_entry.gd';$protected[$entry]=Fact (Join-Path $taskRoot $entry)
if($protected[$entry].sha256 -ne '71ae33ca5ffa7754a20e6c2108d2982bd883ab0e2537adc8dda5493b07d78a99'){throw 'Explicit Entry protection differs.'}
$fixed['res://'+$entry.Substring(5)]=$protected[$entry].sha256
foreach($relative in @('game/art/characters/npc_duqingshan_v3_idle_down_25d_4f.png','game/art/characters/portrait_duqingshan_steady.png')){
 $local=Join-Path $taskRoot $relative;$protected[$relative]=Fact $local;$protected[$relative+'.import']=Fact ($local+'.import')
 $m=[regex]::Match([IO.File]::ReadAllText($local+'.import'),'(?m)^path="(res://[^\r\n"]+)"');if(-not $m.Success){throw 'Missing declared media import.'};$leaf='game/'+$m.Groups[1].Value.Substring(6);$protected[$leaf]=Fact (Join-Path $taskRoot $leaf)
}
foreach($p in $protected.GetEnumerator()){$fixed['res://'+$p.Key.Substring(5)]=$p.Value.sha256}
WriteNew (Join-Path $qaRoot 'protected_visual_pre_ACTUAL.json') ([ordered]@{facts=$protected;entry_count=1;media_leaves=6;engine_runs=0;media_writes=0})
$prior='game/build/major_cities_20261028_qa02/actual/15480/result.json'
$fixture=[ordered]@{
 ready=$true;whole_seconds=30;entry_seconds=20;max_png=1;city_id='openworld_bianzhou_city';size=@(6144,6144);setup=@(1450,4290);short_walk_end=@(1450,4322)
 field='res://build/bianzhou_city_20261028_system01/bianzhou_field.gd';baseline='res://build/major_cities_20261028_qa02/baseline_before_ACTUAL.json';fixed_sources=$fixed
 inherited_actual=@{path='res://'+$prior.Substring(5);sha256=(Fact (Join-Path $taskRoot $prior)).sha256;checks=1213;whole_pass_preserved=$true;not_replayed=$true}
 craftsmen=@(
 @{id='bianzhou_life_14';foot=@(1200,4570);sprite='res://art/characters/npc_duqingshan_v3_idle_down_25d_4f.png';portrait='res://art/characters/portrait_duqingshan_steady.png';replaced_placeholder=$true},
 @{id='bianzhou_life_15';foot=@(2500,4680);sprite='res://art/characters/street_expansion_v1/npc_street_merchant_idle_down_4f_v3_runtime.png';portrait='res://art/characters/portraits/street_expansion_v1/portrait_street_merchant_v1.png';replaced_placeholder=$false}
 )
}
WriteNew (Join-Path $qaRoot 'craftsman_visual_READY.json') $fixture
$meta=[ordered]@{script='res://build/major_cities_20261028_qa03/craftsman_visual_READY.gd';script_sha256=(Fact (Join-Path $qaRoot 'craftsman_visual_READY.gd')).sha256;fixture_sha256=(Fact (Join-Path $qaRoot 'craftsman_visual_READY.json')).sha256;sources=12;entry=1;media_leaves=6;engine_runs=0;canonical_writes=0;save_writes=0}
WriteNew (Join-Path $qaRoot 'frozen_ACTUAL.json') $meta
$meta|ConvertTo-Json -Compress
