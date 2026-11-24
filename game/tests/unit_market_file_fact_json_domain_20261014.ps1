$ErrorActionPreference = 'Stop'
# Source-bound writer-domain model only. No Godot/driver instantiation or file writes.
$qaSource = 'F:/Code/RPG_GAME/game/tests/test_luoyang_market_enrichment_formal_boot_retry5_20261014.gd'
$qaExpectedSHA = '5B7706CE2C2F208ED1FCDEA851B53662EA50026845A5ACE6B47849B055826D71'
if ((Get-FileHash -LiteralPath $qaSource -Algorithm SHA256).Hash -cne $qaExpectedSHA) { throw 'Unbound tested source' }
$qaText = [IO.File]::ReadAllText($qaSource)
foreach ($qaFragment in @('current.size() != 4 or saved.size() != 4', 'typeof(current[key]) != TYPE_INT or typeof(saved[key]) != TYPE_FLOAT', 'float(current[key]) != saved[key]', 'current[key] > 9007199254740991', 'elif not _check(_same_file_fact_json_domain(now,previous)')) {
    if (-not $qaText.Contains($qaFragment)) { throw "Missing exact model branch: $qaFragment" }
}
function New-Fact($exists, $bytes, $sha, $mtime) {
    $qaFact = [System.Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
    $qaFact.Add('exists',$exists); $qaFact.Add('bytes',$bytes); $qaFact.Add('sha256',$sha); $qaFact.Add('mtime_seconds',$mtime)
    return ,$qaFact
}
function Test-Fact($current, $saved) {
    if ($current.Count -ne 4 -or $saved.Count -ne 4) { return $false }
    foreach ($key in @('exists','bytes','sha256','mtime_seconds')) { if (-not $current.ContainsKey($key) -or -not $saved.ContainsKey($key)) { return $false } }
    if ($current['exists'] -isnot [bool] -or $saved['exists'] -isnot [bool] -or $current['exists'] -cne $saved['exists']) { return $false }
    if ($current['sha256'] -isnot [string] -or $saved['sha256'] -isnot [string] -or $current['sha256'] -cne $saved['sha256']) { return $false }
    if ($current['exists']) { if ($current['sha256'] -cnotmatch '^[0-9a-fA-F]{64}$') { return $false } }
    elseif ($current['sha256'] -cne 'ABSENT') { return $false }
    foreach ($key in @('bytes','mtime_seconds')) {
        if ($current[$key] -isnot [long] -or $saved[$key] -isnot [double]) { return $false }
        if ($current[$key] -lt 0 -or $current[$key] -gt 9007199254740991 -or [double]::IsNaN($saved[$key]) -or [double]::IsInfinity($saved[$key]) -or $saved[$key] -lt 0 -or $saved[$key] -gt 9007199254740991) { return $false }
        if ([double]$current[$key] -cne $saved[$key]) { return $false }
    }
    if (-not $current['exists'] -and ($current['bytes'] -ne 0 -or $current['mtime_seconds'] -ne 0)) { return $false }
    return $true
}
$qaHash = 'b4b06110c299bf97dad8eb7134d8b0902135b37bc7c7f4952522ce6f30a5cf23'
$qaCurrent = New-Fact $true ([long]54947) $qaHash ([long]1791524321)
$qaSaved = New-Fact $true ([double]54947) $qaHash ([double]1791524321)
$qaChecks = [System.Collections.Generic.List[object]]::new()
function Check($name,$actual,$expected) { $qaChecks.Add([pscustomobject]@{name=$name; actual=$actual; expected=$expected; passed=($actual -ceq $expected)}) }
Check 'native-int to saved JSON-float exact actual file' (Test-Fact $qaCurrent $qaSaved) $true
Check 'absence exact source fact' (Test-Fact (New-Fact $false ([long]0) 'ABSENT' ([long]0)) (New-Fact $false ([double]0) 'ABSENT' ([double]0))) $true
Check 'fractional bytes rejected, no truncation' (Test-Fact $qaCurrent (New-Fact $true ([double]54947.5) $qaHash ([double]1791524321))) $false
Check 'fractional timestamp rejected, no truncation' (Test-Fact $qaCurrent (New-Fact $true ([double]54947) $qaHash ([double]1791524321.5))) $false
Check 'wrong SHA rejected' (Test-Fact $qaCurrent (New-Fact $true ([double]54947) ('0'*64) ([double]1791524321))) $false
Check 'SHA case mismatch not normalized' (Test-Fact $qaCurrent (New-Fact $true ([double]54947) $qaHash.ToUpperInvariant() ([double]1791524321))) $false
Check 'saved integer is wrong JSON domain' (Test-Fact $qaCurrent (New-Fact $true ([long]54947) $qaHash ([double]1791524321))) $false
Check 'current float is wrong native domain' (Test-Fact (New-Fact $true ([double]54947) $qaHash ([long]1791524321)) $qaSaved) $false
Check 'saved numeric string rejected' (Test-Fact $qaCurrent (New-Fact $true '54947' $qaHash ([double]1791524321))) $false
Check 'bool string rejected' (Test-Fact $qaCurrent (New-Fact 'true' ([double]54947) $qaHash ([double]1791524321))) $false
Check 'NaN rejected' (Test-Fact $qaCurrent (New-Fact $true ([double]::NaN) $qaHash ([double]1791524321))) $false
Check 'infinity rejected' (Test-Fact $qaCurrent (New-Fact $true ([double]::PositiveInfinity) $qaHash ([double]1791524321))) $false
Check 'negative bytes rejected' (Test-Fact (New-Fact $true ([long]-1) $qaHash ([long]1791524321)) (New-Fact $true ([double]-1) $qaHash ([double]1791524321))) $false
Check 'nonexact double integer range rejected' (Test-Fact (New-Fact $true ([long]9007199254740992) $qaHash ([long]1791524321)) (New-Fact $true ([double]9007199254740992) $qaHash ([double]1791524321))) $false
Check 'absent fact cannot retain nonzero bytes' (Test-Fact (New-Fact $false ([long]1) 'ABSENT' ([long]0)) (New-Fact $false ([double]1) 'ABSENT' ([double]0))) $false
$qaExtra = New-Fact $true ([double]54947) $qaHash ([double]1791524321); $qaExtra.Add('ignored',1)
Check 'extra key rejected' (Test-Fact $qaCurrent $qaExtra) $false
$qaMissing = New-Fact $true ([double]54947) $qaHash ([double]1791524321); $qaMissing.Remove('bytes') | Out-Null
Check 'missing key rejected' (Test-Fact $qaCurrent $qaMissing) $false
$qaCase = New-Fact $true ([double]54947) $qaHash ([double]1791524321); $qaCase.Remove('bytes') | Out-Null; $qaCase.Add('Bytes',[double]54947)
Check 'wrong-case field key rejected' (Test-Fact $qaCurrent $qaCase) $false
if ((Get-FileHash -LiteralPath $qaSource -Algorithm SHA256).Hash -cne $qaExpectedSHA) { throw 'Tested source changed' }
$qaFailures = @($qaChecks | Where-Object { -not $_.passed }).Count
[pscustomobject]@{scope='SOURCE_BOUND_FILE_FACT_WRITER_DOMAIN_MODEL_NOT_GODOT_RUNTIME'; sourceSHA=$qaExpectedSHA; checks=$qaChecks.Count; failures=$qaFailures; cases=$qaChecks; files_written=0; Godot_instantiated=$false} | ConvertTo-Json -Depth 6
if ($qaFailures -ne 0) { exit 1 }
exit 0
