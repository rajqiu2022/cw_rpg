$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$src='F:/Code/RPG_GAME/game/build/luoyang_city_revision_20261024b_qa01/market_mask_prior26_explicit_keys_NOTREADY'
$dst='F:/Code/RPG_GAME/game/build/luoyang_city_revision_20261024b_root01/market_prior26_READY'
if(Test-Path -LiteralPath $dst){throw 'PRESERVE_EXISTING_ROOT_STAGE'}
function Hash([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
if((Hash "$src/oracle_NOTREADY.gd") -cne 'bd46b891b7f62b872538fd468532cd1631ca3582bcf5b0e5456697158e4da224'){throw 'ORACLE_SOURCE_CHANGED'}
if((Hash "$src/fixture_NOTREADY.json") -cne '7390c0fb4819a91d8c2802261175e3105a4b18ba2c559eb53b502ed9e0d18846'){throw 'FIXTURE_SOURCE_CHANGED'}
New-Item -ItemType Directory -Path $dst | Out-Null
Copy-Item -LiteralPath "$src/project.godot" -Destination "$dst/project.godot"
$fixture=Get-Content -Raw -LiteralPath "$src/fixture_NOTREADY.json" | ConvertFrom-Json
$fixture.ready=$true
$fixture.status='ROOT_FIXED26_DOMAIN_INDEPENDENT_PRIOR_READY'
$fixture.blockers=@()
$utf=[Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText("$dst/fixture_READY.json",($fixture|ConvertTo-Json -Depth 30)+"`n",$utf)
$key=Get-Content -Raw -LiteralPath "$src/oracle_NOTREADY.gd"
$key=$key.Replace('const READY=false','const READY=true').Replace("$src/fixture_NOTREADY.json","$dst/fixture_READY.json").Replace('7390c0fb4819a91d8c2802261175e3105a4b18ba2c559eb53b502ed9e0d18846',(Hash "$dst/fixture_READY.json")).Replace("$src/output_NOTREADY","$dst/output")
[IO.File]::WriteAllText("$dst/oracle_READY.gd",$key,$utf)
@{script_sha256=(Hash "$dst/oracle_READY.gd");fixture_sha256=(Hash "$dst/fixture_READY.json");project_sha256=(Hash "$dst/project.godot");destination=$dst}|ConvertTo-Json
