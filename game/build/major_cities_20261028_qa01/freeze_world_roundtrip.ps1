$ErrorActionPreference='Stop'
$taskRoot='F:\Code\RPG_GAME'
$qaRoot=Join-Path $taskRoot 'game\build\major_cities_20261028_qa01'
$prior=Get-Content -LiteralPath (Join-Path $qaRoot 'bianzhou_north_south_residual02_READY.json') -Raw | ConvertFrom-Json
$entryRes='res://build/bianzhou_city_20261028_system01/router_entry.gd'
$entryExpected='71ae33ca5ffa7754a20e6c2108d2982bd883ab0e2537adc8dda5493b07d78a99'
$fixed=[ordered]@{}
foreach ($property in $prior.fixed_sources.PSObject.Properties) {
    $local=Join-Path $taskRoot ('game\'+$property.Name.Substring(6).Replace('/','\'))
    $hash=(Get-FileHash -LiteralPath $local -Algorithm SHA256).Hash.ToLowerInvariant()
    $expected=if($property.Name -eq $entryRes){$entryExpected}else{$property.Value}
    if($hash -ne $expected){throw "Unexpected source difference: $($property.Name)"}
    $fixed[$property.Name]=$hash
}
if($fixed.Count -ne 20){throw 'Only the existing 20 current-source paths are permitted.'}
$fixture=[ordered]@{
    ready=$true;whole_seconds=60;entry_seconds=20;max_png=0
    city_id='openworld_bianzhou_city';city_field='res://build/bianzhou_city_20261028_system01/bianzhou_field.gd'
    size=@(6144,6144);public_setup_foot=@(3072,6020);expected_city_foot=@(3072,5910)
    world_portal_uv=@(0.61848956,0.26817358);world_authored_target_uv=@(0.535,0.9)
    baseline='res://build/major_cities_20261028_qa01/baseline_before_ACTUAL.json';fixed_sources=$fixed
    scenario='Explicit public native south setup establishes local28 through normal Entry; Space to real v15 World gateway then immediate Space back, no version dictionary injection or actor teleport.'
}
$fixturePath=Join-Path $qaRoot 'bianzhou_world_roundtrip_READY.json'
$receiptPath=Join-Path $qaRoot 'world_roundtrip_frozen_ACTUAL.json'
foreach($path in @($fixturePath,$receiptPath)){if([IO.File]::Exists($path)){throw "Preserve prior frozen file: $path"}}
function Write-NewTaskBytes([string]$Path,[byte[]]$Bytes){
    $stream=[IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try{$stream.Write($Bytes,0,$Bytes.Length)}finally{$stream.Dispose()}
}
$utf8=[Text.UTF8Encoding]::new($false)
Write-NewTaskBytes $fixturePath $utf8.GetBytes(($fixture|ConvertTo-Json -Depth 12)+"`n")
$scriptPath=Join-Path $qaRoot 'bianzhou_world_roundtrip_READY.gd'
$receipt=[ordered]@{
    status='ONLY_WORLD_LEGACY_UV_WITH_EXISTING28_BRANCH_READY'
    script_path='res://build/major_cities_20261028_qa01/bianzhou_world_roundtrip_READY.gd'
    script_sha256=(Get-FileHash -LiteralPath $scriptPath -Algorithm SHA256).Hash.ToLowerInvariant()
    fixture_sha256=(Get-FileHash -LiteralPath $fixturePath -Algorithm SHA256).Hash.ToLowerInvariant()
    fixed_sources_count=20;only_source_change=$entryRes;canonical_writes=0;save_writes=0;engine_runs=0
    utc=[DateTime]::UtcNow.ToString('o')
}
Write-NewTaskBytes $receiptPath $utf8.GetBytes(($receipt|ConvertTo-Json -Depth 12)+"`n")
Write-Output ($receipt|ConvertTo-Json -Depth 12)
