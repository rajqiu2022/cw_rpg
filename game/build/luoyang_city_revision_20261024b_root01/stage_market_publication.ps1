$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$src='F:/Code/RPG_GAME/game/build/luoyang_city_space_20261024b_source01'
$dst='F:/Code/RPG_GAME/game/build/luoyang_city_revision_20261024b_root01/market_publication_READY'
$res='res://build/luoyang_city_revision_20261024b_root01/market_publication_READY'
$prior='F:/Code/RPG_GAME/game/build/luoyang_city_revision_20261024b_root01/market_prior_bits_READY/output/result.json'
function Hash([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
if(Test-Path -LiteralPath $dst){throw 'PRESERVE_READY_STAGE'}
if((Hash "$src/publish_market_replan_interaction_successor03_NOTRUN.gd") -cne '3e5007dd87928a295fd9018d7f0f80188846ecb9afdae5351466e3bb7c2a725d'){throw 'PUBLISHER_CHANGED'}
if((Hash "$src/publication_input_interaction_successor03_NOTREADY.json") -cne '48a3920d65a36e73f08fd003ef1bff3f69bff07291af895cffd92bbdc066abe2'){throw 'INPUT_CHANGED'}
if((Hash $prior) -cne 'f6da34fe376826c66f5ea56e697df681d628375f6efcff057ac623084a71e7f9'){throw 'PRIOR_CHANGED'}
$actual=Get-Content -Raw -LiteralPath $prior|ConvertFrom-Json
if(!$actual.complete -or $actual.failures -ne 0 -or $actual.native_packet_decodes -ne 0 -or $actual.prior.changed_pixels -ne 93774){throw 'INDEPENDENT_PRIOR_NOT_COMPLETE'}
New-Item -ItemType Directory -Path $dst | Out-Null
$utf=[Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText("$dst/independent_prior.json",($actual.prior|ConvertTo-Json -Depth 15)+"`n",$utf)
$config=Get-Content -Raw -LiteralPath "$src/publication_input_interaction_successor03_NOTREADY.json"|ConvertFrom-Json -AsHashtable
foreach($flag in @('ready','root_run_authorized','asset_geometry_ready','independent_mask_prior_ready')){$config[$flag]=$true}
$config.status='ROOT_FIXED_CURRENT23_TO_MARKET_BLOCK_NATIVE_PUBLICATION_READY'
$config.blockers=@()
$config.pixel_prior_path="$res/independent_prior.json"
$config.source_pins["$res/independent_prior.json"]=(Hash "$dst/independent_prior.json")
$config.source_pins['res://build/luoyang_city_revision_20261024b_root01/market_prior_bits_READY/output/result.json']=(Hash $prior)
[IO.File]::WriteAllText("$dst/input_READY.json",($config|ConvertTo-Json -Depth 40)+"`n",$utf)
$key=Get-Content -Raw -LiteralPath "$src/publish_market_replan_interaction_successor03_NOTRUN.gd"
$key=$key.Replace('const READY=false','const READY=true').Replace('res://build/luoyang_city_space_20261024b_source01/publication_input_interaction_successor03_NOTREADY.json',"$res/input_READY.json").Replace('PENDING_ROOT_FROZEN_INPUT',(Hash "$dst/input_READY.json")).Replace('res://build/luoyang_city_space_20261024b_source01/native_publication_interaction_NOTRUN/','res://build/luoyang_city_revision_20261024b_root01/market_publication_READY/output/')
[IO.File]::WriteAllText("$dst/publish_READY.gd",$key,$utf)
@{script_sha256=(Hash "$dst/publish_READY.gd");input_sha256=(Hash "$dst/input_READY.json");prior_sha256=(Hash "$dst/independent_prior.json");production_writes=0}|ConvertTo-Json
