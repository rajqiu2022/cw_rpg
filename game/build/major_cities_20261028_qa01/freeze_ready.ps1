param([string]$ClosureReceipt = 'F:\Code\RPG_GAME\game\build\bianzhou_city_20261028_system01\source_closure04_READY\receipt.json')
$ErrorActionPreference = 'Stop'
$taskRoot = 'F:\Code\RPG_GAME'
$qaRoot = Join-Path $taskRoot 'game\build\major_cities_20261028_qa01'
$systemRoot = Join-Path $taskRoot 'game\build\bianzhou_city_20261028_system01'
$closure = Get-Content -LiteralPath $ClosureReceipt -Raw | ConvertFrom-Json
if ($closure.targets.Count -ne 9) { throw 'Expected the final exact nine canonical targets; do not use old five-target closures.' }
foreach ($entry in $closure.targets) {
    $live = Join-Path $taskRoot $entry.target
    $hash = (Get-FileHash -LiteralPath $live -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -ne $entry.new_sha256) { throw "Wait for Root deployment: $($entry.target)" }
}
$draftScript = Join-Path $qaRoot 'bianzhou_bounded_DRAFT.gd'
$scriptHash = (Get-FileHash -LiteralPath $draftScript -Algorithm SHA256).Hash.ToLowerInvariant()
if ($scriptHash -ne 'ccf485cd4f7f6ac20a527f30ead59bb185c0d8636705d3e73ea7cb3892ffce19') { throw 'The actual parsed QA script changed; no inherited parse credit.' }
$sources = @(
    'game/build/bianzhou_city_20261028_system01/city_author.gd',
    'game/build/bianzhou_city_20261028_system01/router_entry.gd',
    'game/build/bianzhou_city_20261028_system01/bianzhou_field.gd',
    'game/build/bianzhou_city_20261028_system01/bianzhou_field.tscn',
    'game/build/bianzhou_city_20261028_system01/bianzhou_scene.gd',
    'game/build/bianzhou_city_20261028_system01/gate_binding_BUILD.json',
    'game/build/bianzhou_city_20261028_lore01/ambient_dialogues.json',
    'game/build/major_cities_20261028_art01/reuse_resources.json'
)
$sources += @($closure.targets | ForEach-Object { $_.target })
$gate = Get-Content -LiteralPath (Join-Path $systemRoot 'gate_binding_BUILD.json') -Raw | ConvertFrom-Json
$newMedia = @($gate.objects | ForEach-Object { $_.texture } | Where-Object { $_ -like 'res://art/maps/bianzhou_southgate_20261028/*' } | Select-Object -Unique)
if ($newMedia.Count -ne 3) { throw 'Expected the three actual new gate PNGs.' }
$sources += @($newMedia | ForEach-Object { 'game/' + $_.Substring(6) })
$fixed = [ordered]@{}
foreach ($relative in $sources) {
    $path = Join-Path $taskRoot $relative
    $resPath = 'res://' + $relative.Substring(5).Replace('\','/')
    $fixed[$resPath] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
}
if ($fixed.Count -ne 20) { throw 'Expected eight actual candidates, nine canonical targets and three PNGs.' }
$fixture = Get-Content -LiteralPath (Join-Path $qaRoot 'bianzhou_bounded_DRAFT.json') -Raw | ConvertFrom-Json
$fixture.ready = $true
$fixture.fixed_sources = $fixed
$fixturePath = Join-Path $qaRoot 'bianzhou_bounded_READY.json'
$scriptPath = Join-Path $qaRoot 'bianzhou_bounded_READY.gd'
$receiptPath = Join-Path $qaRoot 'ready_frozen_ACTUAL.json'
foreach ($path in @($fixturePath,$scriptPath,$receiptPath)) { if ([IO.File]::Exists($path)) { throw "Keep prior frozen file: $path" } }
function Write-NewTaskBytes([string]$Path, [byte[]]$Bytes) {
    $stream = [IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try { $stream.Write($Bytes,0,$Bytes.Length) } finally { $stream.Dispose() }
}
$utf8 = [Text.UTF8Encoding]::new($false)
Write-NewTaskBytes $fixturePath $utf8.GetBytes(($fixture | ConvertTo-Json -Depth 20) + "`n")
Write-NewTaskBytes $scriptPath ([IO.File]::ReadAllBytes($draftScript))
$actualScriptHash = (Get-FileHash -LiteralPath $scriptPath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actualScriptHash -ne $scriptHash) { throw 'Byte copy did not preserve the parsed script.' }
$receipt = [ordered]@{
    status='ROOT_DEPLOYED_NINE_TARGETS_QA_READY'; script_path='res://build/major_cities_20261028_qa01/bianzhou_bounded_READY.gd'; script_sha256=$actualScriptHash
    fixture_path='res://build/major_cities_20261028_qa01/bianzhou_bounded_READY.json'; fixture_sha256=(Get-FileHash -LiteralPath $fixturePath -Algorithm SHA256).Hash.ToLowerInvariant()
    fixed_sources=$fixed; count=20; closure_receipt=$ClosureReceipt; closure_receipt_sha256=(Get-FileHash -LiteralPath $ClosureReceipt -Algorithm SHA256).Hash.ToLowerInvariant(); parsed_script_inherited_byte_identical=$true; engine_runs=0; canonical_writes=0; save_writes=0; utc=[DateTime]::UtcNow.ToString('o')
}
Write-NewTaskBytes $receiptPath $utf8.GetBytes(($receipt | ConvertTo-Json -Depth 12) + "`n")
Write-Output ($receipt | ConvertTo-Json -Depth 12)
