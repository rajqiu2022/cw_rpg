$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$src='F:/Code/RPG_GAME/game/build/luoyang_city_space_20261024b_source01'
$dst='F:/Code/RPG_GAME/game/build/luoyang_city_revision_20261024b_root01/market_detours06_READY'
$res='res://build/luoyang_city_revision_20261024b_root01/market_detours06_READY'
function Hash([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
if(Test-Path -LiteralPath $dst){throw 'PRESERVE_READY'}
if((Hash "$src/publish_market_route_detours_successor06_NOTRUN.gd") -cne '75956bc2d2f0ec88a12653b1c8f7741e07845734b2edb77b3b7e9e01c8cbbc5b'){throw 'KEY_CHANGED'}
if((Hash "$src/publication_input_route_detours_successor06_NOTREADY.json") -cne 'a37a6e2ff95bd54fbdf3277a931f04234fa2debb086cd09d1f8d70b951c8c861'){throw 'INPUT_CHANGED'}
New-Item -ItemType Directory -Path $dst | Out-Null
$utf=[Text.UTF8Encoding]::new($false)
$config=Get-Content -Raw -LiteralPath "$src/publication_input_route_detours_successor06_NOTREADY.json"|ConvertFrom-Json -AsHashtable
$config.ready=$true;$config.root_run_authorized=$true
$config.status='ROOT_ONLY_TWO_ROUTE_DETOURS_RESIDUAL_PUBLICATION_READY'
$config.blockers=@()
[IO.File]::WriteAllText("$dst/input_READY.json",($config|ConvertTo-Json -Depth 40)+"`n",$utf)
$key=Get-Content -Raw -LiteralPath "$src/publish_market_route_detours_successor06_NOTRUN.gd"
$key=$key.Replace('const READY=false','const READY=true').Replace('res://build/luoyang_city_space_20261024b_source01/publication_input_route_detours_successor06_NOTREADY.json',"$res/input_READY.json").Replace('a37a6e2ff95bd54fbdf3277a931f04234fa2debb086cd09d1f8d70b951c8c861',(Hash "$dst/input_READY.json")).Replace('res://build/luoyang_city_space_20261024b_source01/native_publication_detours06_NOTRUN/',"$res/output/").Replace('res://build/luoyang_city_space_20261024b_source01/route_diagnostic_detours06_NOTRUN/result.json',"$res/diagnostics/result.json")
[IO.File]::WriteAllText("$dst/publish_READY.gd",$key,$utf)
@{script_sha256=(Hash "$dst/publish_READY.gd");input_sha256=(Hash "$dst/input_READY.json")}|ConvertTo-Json
