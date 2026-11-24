# Definitions only. Source hashes are workspace-only; save facts never read content.
$CityNavHook = 'CityNavigationRuntime="*res://build/city_navigation_20261101d_candidate01/city_navigation_runtime.gd"'
function Resolve-CityNavSource([string]$Path, [string]$Game) {
    if (-not $Path.StartsWith('res://', [StringComparison]::Ordinal) -or $Path.Contains('..')) { throw ('FINITE_RES_SOURCE_REQUIRED:' + $Path) }
    $absolute = [IO.Path]::GetFullPath((Join-Path $Game $Path.Substring(6)))
    $prefix = [IO.Path]::GetFullPath($Game).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
    if (-not $absolute.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'SOURCE_OUTSIDE_GAME' }
    return $absolute
}
function Get-CityNavSourceFact([string]$Path) {
    $first = Get-Item -LiteralPath $Path -ErrorAction Stop
    if ($first.PSIsContainer) { throw 'SOURCE_LEAF_REQUIRED' }
    $bytes = $first.Length; $ticks = $first.LastWriteTimeUtc.Ticks.ToString()
    $hash = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    $last = Get-Item -LiteralPath $Path -ErrorAction Stop
    return [ordered]@{exists=$true;bytes=$bytes;utc_ticks=$ticks;sha256=$hash;stable=($bytes -eq $last.Length -and $ticks -ceq $last.LastWriteTimeUtc.Ticks.ToString())}
}
function Get-CityNavSaveMetadata([string]$Path) {
    # Exactly one Get-Item per registered path. No OpenRead/Get-Content/hash.
    $normalized = [IO.Path]::GetFullPath($Path).Replace('\','/')
    if (-not $normalized.StartsWith('C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/', [StringComparison]::OrdinalIgnoreCase)) { throw ('REGISTERED_APP_USERDATA_ONLY:' + $Path) }
    $entry = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
    if ($null -eq $entry) { return [ordered]@{exists=$false;bytes=$null;utc_ticks=$null} }
    if ($entry.PSIsContainer) { throw 'REGISTERED_SAVE_LEAF_ONLY' }
    return [ordered]@{exists=$true;bytes=$entry.Length;utc_ticks=$entry.LastWriteTimeUtc.Ticks.ToString()}
}
function Test-CityNavMetadataSame($A, $B) {
    return $null -ne $A -and $null -ne $B -and $A.exists -eq $B.exists -and $A.bytes -eq $B.bytes -and $A.utc_ticks -ceq $B.utc_ticks
}
function Test-CityNavSourceSame($A, $B) {
    return (Test-CityNavMetadataSame $A $B) -and $A.sha256 -ceq $B.sha256 -and $A.stable -eq $true -and $B.stable -eq $true
}
function Assert-CityNavNewOutput([string]$Path, [string]$Directory) {
    $absolute = [IO.Path]::GetFullPath($Path)
    $prefix = [IO.Path]::GetFullPath($Directory).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
    if (-not $absolute.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'NEW_GUARD01_EVIDENCE_ONLY' }
    if (Test-Path -LiteralPath $absolute) { throw ('PRESERVE_PRIOR_EVIDENCE:' + $absolute) }
    return $absolute
}
function Write-CityNavNewJson([string]$Path, $Data) {
    $json = (($Data | ConvertTo-Json -Depth 70) -replace "`r`n", "`n").TrimEnd() + "`n"
    $stream = [IO.File]::Open($Path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try { $bytes = [Text.UTF8Encoding]::new($false).GetBytes($json); $stream.Write($bytes,0,$bytes.Length) } finally { $stream.Dispose() }
}
function Test-CityNavProjectInverse([string]$Project, [string]$Backup) {
    $actual = [IO.File]::ReadAllText($Project)
    $priorBytes = [IO.File]::ReadAllBytes($Backup)
    if (@($actual -split '\r?\n' | Where-Object {$_ -match '^CityNavigationRuntime='}).Count -ne 1 -or @($actual -split '\r?\n' | Where-Object {$_ -ceq $CityNavHook}).Count -ne 1) { return $false }
    $section = [regex]::Match($actual,'(?ms)^\[autoload\]\r?\n(?<body>.*?)(?=^\[|\z)').Groups['body'].Value
    if (@($section -split '\r?\n' | Where-Object {$_ -ceq $CityNavHook}).Count -ne 1) { return $false }
    foreach ($ending in @("`r`n","`n")) {
        $needle = $CityNavHook + $ending
        $index = $actual.IndexOf($needle,[StringComparison]::Ordinal)
        if ($index -lt 0) { continue }
        $inverse = [Text.UTF8Encoding]::new($false).GetBytes($actual.Remove($index,$needle.Length))
        if ([Convert]::ToBase64String($inverse) -ceq [Convert]::ToBase64String($priorBytes)) { return $true }
    }
    return $false
}
