# Shared read-only metadata helpers. Dot-source only from this new directory.
function Get-QualityFact([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return [ordered]@{exists=$false;bytes=$null;utc_ticks=$null;sha256=$null;stable_during_hash=$true}
    }
    $first = Get-Item -LiteralPath $Path
    $bytes = $first.Length; $ticks = $first.LastWriteTimeUtc.Ticks.ToString()
    $sha = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    $last = Get-Item -LiteralPath $Path
    return [ordered]@{exists=$true;bytes=$bytes;utc_ticks=$ticks;sha256=$sha;stable_during_hash=($bytes -eq $last.Length -and $ticks -eq $last.LastWriteTimeUtc.Ticks.ToString())}
}
function Test-QualityFactSame($First, $Second) {
    return $null -ne $First -and $null -ne $Second -and $First.exists -eq $Second.exists -and $First.bytes -eq $Second.bytes -and $First.utc_ticks -eq $Second.utc_ticks -and $First.sha256 -eq $Second.sha256 -and $First.stable_during_hash -eq $true -and $Second.stable_during_hash -eq $true
}
function Assert-QualityNewOutput([string]$Path, [string]$Directory) {
    $absolute = [IO.Path]::GetFullPath($Path)
    $prefix = [IO.Path]::GetFullPath($Directory).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
    if (-not $absolute.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'NEW_RUNTIME_DIRECTORY_OUTPUT_ONLY' }
    if (Test-Path -LiteralPath $absolute) { throw ('EXISTING_EVIDENCE_PRESERVED:' + $absolute) }
    return $absolute
}
function Write-QualityNewJson([string]$Path, $Value) {
    if (Test-Path -LiteralPath $Path) { throw 'NO_EVIDENCE_OVERWRITE' }
    $json = ($Value | ConvertTo-Json -Depth 30) -replace "`r`n", "`n"
    [IO.File]::WriteAllText($Path, $json.TrimEnd() + "`n", [Text.UTF8Encoding]::new($false))
}
