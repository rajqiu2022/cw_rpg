$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$src='F:/Code/RPG_GAME/game/build/luoyang_city_revision_20261024b_qa01/market_mask_prior26_f32_bits_NOTREADY'
$dst='F:/Code/RPG_GAME/game/build/luoyang_city_revision_20261024b_root01/market_prior_bits_READY'
if(Test-Path -LiteralPath $dst){throw 'PRESERVE_EXISTING_ROOT_STAGE'}
function Hash([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
if((Hash "$src/oracle_NOTREADY.gd") -cne '4a564d3e3f706f16268274c1d054989319aa42f6bcedcc842a359c51d7b24aa7'){throw 'ORACLE_SOURCE_CHANGED'}
if((Hash "$src/fixture_NOTREADY.json") -cne 'aba632005937a05d6414195b7220b8ae1b8f60db2405942ab3f1afc61904b53e'){throw 'FIXTURE_SOURCE_CHANGED'}
New-Item -ItemType Directory -Path $dst | Out-Null
Copy-Item -LiteralPath "$src/project.godot" -Destination "$dst/project.godot"
$fixture=Get-Content -Raw -LiteralPath "$src/fixture_NOTREADY.json" | ConvertFrom-Json
$fixture.ready=$true
$fixture.status='ROOT_FIXED26_DOMAIN_BITS_GATE_REMAINING_PRIOR_READY'
$fixture.blockers=@()
$utf=[Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText("$dst/fixture_READY.json",($fixture|ConvertTo-Json -Depth 30)+"`n",$utf)
$key=Get-Content -Raw -LiteralPath "$src/oracle_NOTREADY.gd"
$key=$key.Replace('const READY=false','const READY=true').Replace("$src/fixture_NOTREADY.json","$dst/fixture_READY.json").Replace('aba632005937a05d6414195b7220b8ae1b8f60db2405942ab3f1afc61904b53e',(Hash "$dst/fixture_READY.json")).Replace("$src/output_NOTREADY","$dst/output")
[IO.File]::WriteAllText("$dst/oracle_READY.gd",$key,$utf)
@{script_sha256=(Hash "$dst/oracle_READY.gd");fixture_sha256=(Hash "$dst/fixture_READY.json");project_sha256=(Hash "$dst/project.godot");destination=$dst}|ConvertTo-Json
