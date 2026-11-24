param(
    [Parameter(Mandatory=$true)][string]$ExpectedAuthorSHA,
    [Parameter(Mandatory=$true)][string]$ExpectedFieldSHA
)
$ErrorActionPreference='Stop'
$taskRoot='F:\Code\RPG_GAME'
$qaRoot=Join-Path $taskRoot 'game\build\major_cities_20261028_qa01'
$authorPath=Join-Path $taskRoot 'game\build\bianzhou_city_20261028_system01\city_author.gd'
$fieldPath=Join-Path $taskRoot 'game\build\bianzhou_city_20261028_system01\bianzhou_field.gd'
if ($ExpectedAuthorSHA -cnotmatch '^[0-9a-f]{64}$' -or $ExpectedFieldSHA -cnotmatch '^[0-9a-f]{64}$') { throw 'Root must supply the final material source SHAs.' }
if ((Get-FileHash -LiteralPath $authorPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $ExpectedAuthorSHA -or (Get-FileHash -LiteralPath $fieldPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $ExpectedFieldSHA) { throw 'Material candidate is not the final Root-frozen source.' }
$originalFixture=Join-Path $qaRoot 'bianzhou_bounded_READY.json'
$fixture=Get-Content -LiteralPath $originalFixture -Raw | ConvertFrom-Json
if (@($fixture.fixed_sources.PSObject.Properties).Count -ne 20) { throw 'Expected only the original bounded 20-source domain.' }
$fixed=[ordered]@{}
foreach ($property in $fixture.fixed_sources.PSObject.Properties) {
    $res=$property.Name
    $local=Join-Path $taskRoot ('game\'+$res.Substring(6).Replace('/','\'))
    $current=(Get-FileHash -LiteralPath $local -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($local -ne $authorPath -and $local -ne $fieldPath -and $current -ne $property.Value) { throw "Unexpected change outside the two approved material sources: $res" }
    $fixed[$res]=$current
}
$fixture.fixed_sources=$fixed
$fixture.max_png=1
$fixture | Add-Member -NotePropertyName public_setup_foot -NotePropertyValue @(3104,246)
$fixture | Add-Member -NotePropertyName expected_original_source_anchor -NotePropertyValue @(3102.72,245.76)
$fixture | Add-Member -NotePropertyName residual_south_before_capture -NotePropertyValue @(@(3072,245.76),@(3072,5390))
$fixture | Add-Member -NotePropertyName residual_south_after_capture -NotePropertyValue (,@(3072,6020))
$priorActual=Join-Path $qaRoot 'actual\46236\result.json'
$fixture | Add-Member -NotePropertyName inherited_prefix -NotePropertyValue ([ordered]@{
    path='res://build/major_cities_20261028_qa01/actual/46236/result.json'
    sha256=(Get-FileHash -LiteralPath $priorActual -Algorithm SHA256).Hash.ToLowerInvariant()
    whole_failed_preserved=$true
    components='Default entry, south short real INPUT, life/guide safe dialogue, original Shop open/close, north outbound arrival only; not the failed return verdict.'
})
$fixturePath=Join-Path $qaRoot 'bianzhou_north_south_residual02_READY.json'
$scriptPath=Join-Path $qaRoot 'bianzhou_north_south_residual02_READY.gd'
$receiptPath=Join-Path $qaRoot 'north_south_residual02_frozen_ACTUAL.json'
foreach ($path in @($fixturePath,$scriptPath,$receiptPath)) { if ([IO.File]::Exists($path)) { throw "Preserve existing frozen file: $path" } }
function Write-NewTaskBytes([string]$Path,[byte[]]$Bytes) {
    $stream=[IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try { $stream.Write($Bytes,0,$Bytes.Length) } finally { $stream.Dispose() }
}
$utf8=[Text.UTF8Encoding]::new($false)
Write-NewTaskBytes $fixturePath $utf8.GetBytes(($fixture | ConvertTo-Json -Depth 20)+"`n")
$draft=Join-Path $qaRoot 'bianzhou_north_south_residual_DRAFT.gd'
Write-NewTaskBytes $scriptPath ([IO.File]::ReadAllBytes($draft))
$receipt=[ordered]@{
    status='NORTH_GENERIC_ANCHOR_AND_SOUTH_WORLD_ONLY_READY'
    script_path='res://build/major_cities_20261028_qa01/bianzhou_north_south_residual02_READY.gd'
    script_sha256=(Get-FileHash -LiteralPath $scriptPath -Algorithm SHA256).Hash.ToLowerInvariant()
    fixture_path='res://build/major_cities_20261028_qa01/bianzhou_north_south_residual02_READY.json'
    fixture_sha256=(Get-FileHash -LiteralPath $fixturePath -Algorithm SHA256).Hash.ToLowerInvariant()
    inherited_helpers_sha256=(Get-FileHash -LiteralPath (Join-Path $qaRoot 'bianzhou_bounded_DRAFT.gd') -Algorithm SHA256).Hash.ToLowerInvariant()
    fixed_sources=$fixed
    canonical_writes=0;save_writes=0;engine_runs=0;utc=[DateTime]::UtcNow.ToString('o')
}
Write-NewTaskBytes $receiptPath $utf8.GetBytes(($receipt | ConvertTo-Json -Depth 12)+"`n")
Write-Output ($receipt | ConvertTo-Json -Depth 12)
