$ErrorActionPreference='Stop'
$taskRoot='F:\Code\RPG_GAME';$qaRoot=Join-Path $taskRoot 'game/build/major_cities_20261028_qa04'
function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function WriteNew([string]$p,[byte[]]$bytes){$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()}}
$plan=Get-Content -LiteralPath (Join-Path $taskRoot 'game/build/bianzhou_city_20261028_system06/qa_compatible_authorized_sources_FINAL.json') -Raw|ConvertFrom-Json
$fixed=[ordered]@{};foreach($group in @($plan.sources,$plan.new_modules)){foreach($p in $group.PSObject.Properties){$fixed['res://'+$p.Name.Substring(5)]=$p.Value.sha256}}
$fixed['res://build/major_cities_20261028_qa01/bianzhou_bounded_DRAFT.gd']='ccf485cd4f7f6ac20a527f30ead59bb185c0d8636705d3e73ea7cb3892ffce19'
foreach($p in $fixed.Keys){if((Sha (Join-Path $taskRoot ('game/'+$p.Substring(6)))) -cne $fixed[$p]){throw "Root must deploy final source first: $p"}}
$fixture=[ordered]@{ready=$true;whole_seconds=30;entry_seconds=20;max_png=1;city_id='openworld_bianzhou_city';city_field='res://build/bianzhou_city_20261028_system01/bianzhou_field.gd';baseline='res://build/major_cities_20261028_qa04/baseline_before_ACTUAL.json';fixed_sources=$fixed;road_layers=[ordered]@{axis0=-998;west_ring0=-999;housing_lane0=-1000};actor_camera_writes=0;input_allowed=$false;overview_allowed=$false}
$json=Join-Path $qaRoot 'road_layer_READY.json';$gd=Join-Path $qaRoot 'road_layer_READY.gd'
WriteNew $json ([Text.UTF8Encoding]::new($false).GetBytes(($fixture|ConvertTo-Json -Depth 15)+"`n"));WriteNew $gd ([IO.File]::ReadAllBytes((Join-Path $qaRoot 'road_layer_DRAFT.gd')))
[ordered]@{script=$gd;sha256=(Sha $gd);fixture_sha256=(Sha $json);frozen_sources=$fixed.Count;engine_calls=0}|ConvertTo-Json -Compress
