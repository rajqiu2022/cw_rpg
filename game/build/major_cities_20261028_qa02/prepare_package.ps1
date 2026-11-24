$ErrorActionPreference='Stop'
$taskRoot='F:\Code\RPG_GAME';$qaRoot=Join-Path $taskRoot 'game\build\major_cities_20261028_qa02'
$baseline=Get-Content -LiteralPath (Join-Path $qaRoot 'baseline_before_ACTUAL.json') -Raw | ConvertFrom-Json
function Fact([string]$Path){if(-not [IO.File]::Exists($Path)){return [ordered]@{exists=$false}};$item=Get-Item -LiteralPath $Path;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant();bytes=$item.Length;utc_ticks=$item.LastWriteTimeUtc.Ticks.ToString()}}
function WriteNew([string]$Path,$Data){$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($Data|ConvertTo-Json -Depth 18)+"`n");$stream=[IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}}
$author='game/build/bianzhou_city_20261028_system01/city_author.gd'
$expected='e73afc79a79d085bf387faa59eecb6d0e80037310ca18d40edd08189421076c1'
if((Fact (Join-Path $taskRoot $author)).sha256 -ne $expected){throw 'Final deployed Author is not E73AFC79.'}
$fixed=[ordered]@{}
foreach($property in $baseline.sources12.PSObject.Properties){$now=Fact (Join-Path $taskRoot $property.Name);if($property.Name -ne $author -and $now.sha256 -ne $property.Value.sha256){throw "Unexpected source change: $($property.Name)"};$fixed['res://'+$property.Name.Substring(5)]=$now.sha256}
$goods=@('game/art/modules/luoyang_assembled_interiors_20261016g/grain_sack_stack_v1.png','game/art/modules/luoyang_assembled_interiors_20261016g/cloth_roll_rack_v1.png','game/art/modules/luoyang_assembled_interiors_20261016g/wood_handcart_v1.png','game/art/modules/luoyang_district_life_20261016f/stock_crate.png')
$facts=[ordered]@{}
foreach($relative in $goods){$local=Join-Path $taskRoot $relative;$facts[$relative]=Fact $local;$facts[$relative+'.import']=Fact ($local+'.import');if([IO.File]::Exists($local+'.import')){$match=[regex]::Match([IO.File]::ReadAllText($local+'.import'),'(?m)^path="(res://[^\r\n"]+)"');if($match.Success){$leaf='game/'+$match.Groups[1].Value.Substring(6);$facts[$leaf]=Fact (Join-Path $taskRoot $leaf)}}}
if($facts.Count -ne 12){throw 'Expected exactly four shipped PNG/import/compiled triplets.'}
WriteNew (Join-Path $qaRoot 'goods_media_pre_now_ACTUAL.json') ([ordered]@{status='FOUR_REUSED_GOODS_PRE_NOW_FACTS_ONLY';utc=[DateTime]::UtcNow.ToString('o');facts=$facts;media_writes=0;engine_runs=0})
$bounds=[ordered]@{'grain_sack_stack_v1.png'=@(231,778,1076,133);'cloth_roll_rack_v1.png'=@(122,839,1289,114);'wood_handcart_v1.png'=@(139,306,1259,512);'stock_crate.png'=@(21.25,70.7600065469792,80.4299316704323,32.33996582031)}
$fixture=[ordered]@{
 ready=$true;whole_seconds=60;entry_seconds=20;max_png=1;city_id='openworld_bianzhou_city';city_field='res://build/bianzhou_city_20261028_system01/bianzhou_field.gd';size=@(6144,6144)
 author='res://build/bianzhou_city_20261028_system01/city_author.gd';prior_author='res://build/major_cities_20261028_qa02/source_before/game/build/bianzhou_city_20261028_system01/city_author.gd';baseline='res://build/major_cities_20261028_qa02/baseline_before_ACTUAL.json';fixed_sources=$fixed
 public_setup_foot=@(1450,2720);first_street_route=(,@(1450,4290));second_street_route=@(@(1450,3750),@(1280,3750),@(1280,2780),@(1280,4200))
 retained_feet=@(@(3072,5910),@(3072,6020),@(3102.72,245.76),@(1450,2720),@(1450,4290),@(1280,3750),@(1280,2780),@(1280,4200),@(1850,3000),@(1850,4190),@(2730,3180))
 affected_npc_ids=@('bianzhou_life_10','bianzhou_life_11','bianzhou_life_20','bianzhou_merchant');source_bounds_by_file=$bounds
 oracle_scope='Only 16 new occupancy rows; Art-approved source bounds transformed by explicit foot/scale, first registered lane for saved28 conflicts, unaffected28 UV identity, v1 then same delta, unknown versions reject. No assertion that every old safe pixel stays safe.'
 actual_status='NOT_RUN_USER_GAME_REMAINS_OPEN; GPU and detailed street views may be handed to user.'
}
WriteNew (Join-Path $qaRoot 'two_streets_READY.json') $fixture
$metadata=[ordered]@{author_sha256=$expected;script_sha256=(Fact (Join-Path $qaRoot 'two_streets_READY.gd')).sha256;fixture_sha256=(Fact (Join-Path $qaRoot 'two_streets_READY.json')).sha256;source_count=$fixed.Count;old_media_facts=48;new_goods_media_facts=$facts.Count;engine_runs=0;canonical_writes=0;save_writes=0}
WriteNew (Join-Path $qaRoot 'package_frozen_ACTUAL.json') $metadata
$metadata|ConvertTo-Json -Compress
