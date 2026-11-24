$ErrorActionPreference='Stop'
$taskRoot='F:\Code\RPG_GAME';$qaRoot=Join-Path $taskRoot 'game/build/major_cities_20261028_qa04'
function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function WriteNew([string]$p,[byte[]]$bytes){$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()}}
$old=Get-Content -LiteralPath (Join-Path $qaRoot 'completion_geometry_READY.json') -Raw|ConvertFrom-Json
$fixed=[ordered]@{};foreach($p in $old.fixed_sources.PSObject.Properties){$fixed[$p.Name]=$p.Value}
$completion='res://build/bianzhou_city_20261028_system04/completion_binding_BUILD.json'
$fixed[$completion]='4769f05b5a687265edfb7861fcfe0016d1ceaf2107c7eb8c7bce50d9ac6b43f4'
$base='res://build/major_cities_20261028_qa04/completion_geometry_READY.gd';$fixed[$base]='969c521b2e36d5e73dafdc89e9d78196144c8b83cd82ff5e117fbd334b3c3961'
$result='res://build/major_cities_20261028_qa04/actual/122144/geometry_result.json';$fixed[$result]=Sha (Join-Path $taskRoot ('game/'+$result.Substring(6)))
foreach($p in $fixed.Keys){if((Sha (Join-Path $taskRoot ('game/'+$p.Substring(6)))) -ne $fixed[$p]){throw "Exact source changed: $p"}}
$lanes=[ordered]@{};foreach($id in @('city_yard_tree_18','city_yard_tree_19','city_yard_tree_20','city_yard_tree_21','north_road_travel_cart')){$lanes[$id]=@(3072,650)}
foreach($id in @('checkpoint_waiting_cart','checkpoint_luggage_sacks')){$lanes[$id]=@(1450,4970)}
$fixture=[ordered]@{ready=$true;media_status='PENDING_RGBA_IMPORT';author=$old.author;gate_binding=$old.gate_binding;baseline=$old.baseline;inherited_result=$result;fixed_sources=$fixed;corrected_lanes=$lanes}
$json=Join-Path $qaRoot 'geometry_residual_READY.json';$gd=Join-Path $qaRoot 'geometry_residual_READY.gd'
WriteNew $json ([Text.UTF8Encoding]::new($false).GetBytes(($fixture|ConvertTo-Json -Depth 15)+"`n"));WriteNew $gd ([IO.File]::ReadAllBytes((Join-Path $qaRoot 'geometry_residual_DRAFT.gd')))
[ordered]@{script=$gd;sha256=(Sha $gd);fixture_sha256=(Sha $json);engine_calls=0}|ConvertTo-Json -Compress
