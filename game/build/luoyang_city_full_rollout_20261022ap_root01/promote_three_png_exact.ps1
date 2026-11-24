param([switch]$Promote)
$ErrorActionPreference = 'Stop'
# Root-only, absent-only, exact nine media leaves. This does not enable AP.
$GameRoot = 'F:\Code\RPG_GAME\game'
$IsolateRoot = Join-Path $GameRoot 'build\luoyang_city_full_rollout_20261022ap_qa01\isolate_three_ready01'
$ReportPath = Join-Path $IsolateRoot 'ap_three_new_png_import_result_112496.json'
$ReportSha = '263051c466b992d41bf1d5e53a35ddac2e3d5ab18e134d9cfa1db2028e701c2f'
$Authorization = Join-Path $GameRoot 'build\luoyang_city_full_rollout_20261022ap_root01\three_png_nine_leaf_preadd_authorization.json'
$Receipt = Join-Path $GameRoot 'build\luoyang_city_full_rollout_20261022ap_root01\three_png_nine_leaf_promotion_actual.json'
if ((Get-FileHash -LiteralPath $ReportPath).Hash.ToLowerInvariant() -cne $ReportSha) { throw 'Frozen actual import report changed' }
$Report = Get-Content -LiteralPath $ReportPath -Raw | ConvertFrom-Json
if (-not $Report.passed -or $Report.checks -ne 153 -or @($Report.rows).Count -ne 3) { throw 'Actual three PNG import not passed' }
$Leaves = @()
foreach ($Row in $Report.rows) {
    if ($Row.visual_kind -notin @('sign','bridge','pavilion') -or $Row.texture -cne ('res://art/modules/luoyang_full_city_20261022ap/' + $Row.visual_kind + '.png')) { throw 'Scope identity' }
    foreach ($Pair in @(@($Row.compiled_path,$Row.compiled_sha256),@($Row.import_path,$Row.import_sha256),@($Row.texture,$Row.source_sha256))) {
        $Relative = $Pair[0].Substring(6)
        $Source = [IO.Path]::GetFullPath((Join-Path $IsolateRoot $Relative))
        $Target = [IO.Path]::GetFullPath((Join-Path $GameRoot $Relative))
        if (-not $Source.StartsWith($IsolateRoot + '\',[StringComparison]::OrdinalIgnoreCase) -or -not $Target.StartsWith($GameRoot + '\',[StringComparison]::OrdinalIgnoreCase) -or $Relative.Contains('..')) { throw 'Path escape' }
        if (Test-Path -LiteralPath $Target) { throw ('Not absent: ' + $Target) }
        if ((Get-FileHash -LiteralPath $Source).Hash.ToLowerInvariant() -cne $Pair[1]) { throw 'Imported source changed' }
        $Leaves += [pscustomobject]@{source=$Source;target=$Target;before='ABSENT';sha256=$Pair[1];bytes=(Get-Item -LiteralPath $Source).Length}
    }
}
if ($Leaves.Count -ne 9 -or @($Leaves.target | Select-Object -Unique).Count -ne 9) { throw 'Exactly nine unique leaves' }
if (-not $Promote) { $Leaves | ConvertTo-Json -Depth 6; exit 0 }
if ((Test-Path -LiteralPath $Authorization) -or (Test-Path -LiteralPath $Receipt)) { throw 'Preserve prior authorization or receipt' }
$Permit = [ordered]@{approved_by_root=$true;status='ROOT_EXACT_NINE_NEW_MEDIA_LEAVES_PREAUTHORIZED';actual_import_report=$ReportPath;actual_report_sha256=$ReportSha;leaves=$Leaves;canonical_scripts_or_indices_changed=$false;formal_AP_enabled=$false;old_sources_or_saves_modified=$false}
$Permit | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Authorization -Encoding utf8NoBOM
# Authorization exists before any destination creation. All compiled/sidecars precede raw PNGs.
foreach ($Leaf in @($Leaves | Where-Object { -not $_.target.EndsWith('.png') }) + @($Leaves | Where-Object { $_.target.EndsWith('.png') })) {
    if (Test-Path -LiteralPath $Leaf.target) { throw 'Destination changed after preflight' }
    $Parent = Split-Path -Parent $Leaf.target
    if (-not (Test-Path -LiteralPath $Parent)) { New-Item -ItemType Directory -Path $Parent | Out-Null }
    Copy-Item -LiteralPath $Leaf.source -Destination $Leaf.target
    if ((Get-FileHash -LiteralPath $Leaf.target).Hash.ToLowerInvariant() -cne $Leaf.sha256) { throw 'Promoted bytes differ' }
}
[ordered]@{status='NINE_EXACT_MEDIA_LEAVES_PROMOTED_NO_AP_INDEX';passed=$true;authorization_sha256=(Get-FileHash -LiteralPath $Authorization).Hash.ToLowerInvariant();leaves=$Leaves;old_sources_or_saves_modified=$false} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Receipt -Encoding utf8NoBOM
Get-FileHash -LiteralPath $Authorization,$Receipt
