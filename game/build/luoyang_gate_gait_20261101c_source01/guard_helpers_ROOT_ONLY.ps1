# Definitions only; metadata reads and new evidence-directory writes when called.
$GateExactHook = 'NPCGaitRuntime="*res://build/npc_gait_20261101c_candidate01/npc_gait_runtime.gd"'
function Get-GateFact([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return [ordered]@{exists=$false;bytes=$null;utc_ticks=$null;sha256=$null;stable_during_hash=$true}
    }
    $first = Get-Item -LiteralPath $Path
    $size = $first.Length; $ticks = $first.LastWriteTimeUtc.Ticks.ToString()
    $digest = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    $last = Get-Item -LiteralPath $Path
    return [ordered]@{exists=$true;bytes=$size;utc_ticks=$ticks;sha256=$digest;stable_during_hash=($size -eq $last.Length -and $ticks -eq $last.LastWriteTimeUtc.Ticks.ToString())}
}
function Test-GateFactSame($First, $Second) {
    return $null -ne $First -and $null -ne $Second -and $First.exists -eq $Second.exists -and $First.bytes -eq $Second.bytes -and $First.utc_ticks -eq $Second.utc_ticks -and $First.sha256 -eq $Second.sha256 -and $First.stable_during_hash -eq $true -and $Second.stable_during_hash -eq $true
}
function Get-GateAbsolute([string]$Path, [string]$Game) {
    if ($Path.StartsWith('res://', [StringComparison]::Ordinal)) { $Path = Join-Path $Game $Path.Substring(6) }
    if (-not [IO.Path]::IsPathRooted($Path)) { throw ('ABSOLUTE_OR_RES_PATH_REQUIRED:' + $Path) }
    $absolute = [IO.Path]::GetFullPath($Path).Replace('\','/')
    $prefix = [IO.Path]::GetFullPath($Game).Replace('\','/').TrimEnd('/') + '/'
    if (-not $absolute.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw ('OUTSIDE_FINITE_GAME_DOMAIN:' + $Path) }
    return $absolute
}
function Assert-GateNewOutput([string]$Path, [string]$Directory) {
    $absolute = [IO.Path]::GetFullPath($Path)
    $prefix = [IO.Path]::GetFullPath($Directory).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
    if (-not $absolute.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'NEW_SOURCE01_EVIDENCE_DIRECTORY_ONLY' }
    if (Test-Path -LiteralPath $absolute) { throw ('PRIOR_EVIDENCE_PRESERVED:' + $absolute) }
    return $absolute
}
function Write-GateNewJson([string]$Path, $Value) {
    $json = (($Value | ConvertTo-Json -Depth 40) -replace "`r`n", "`n").TrimEnd() + "`n"
    $stream = [IO.File]::Open($Path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try { $bytes = [Text.UTF8Encoding]::new($false).GetBytes($json); $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Dispose() }
}
function Copy-GateExactBackup([string]$Source, [string]$Destination, [string]$EvidenceDirectory) {
    $target = Assert-GateNewOutput $Destination $EvidenceDirectory
    $before = Get-GateFact $Source
    if (-not $before.exists -or -not $before.stable_during_hash) { throw ('EXISTING_STABLE_BACKUP_SOURCE_REQUIRED:' + $Source) }
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
    $sourceStream = [IO.File]::OpenRead($Source)
    $targetStream = [IO.File]::Open($target, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try { $sourceStream.CopyTo($targetStream) } finally { $sourceStream.Dispose(); $targetStream.Dispose() }
    [IO.File]::SetLastWriteTimeUtc($target, [DateTime]::new([long]$before.utc_ticks, [DateTimeKind]::Utc))
    $backupFact = Get-GateFact $target
    if (-not (Test-GateFactSame $before $backupFact) -or -not (Test-GateFactSame $before (Get-GateFact $Source))) { throw ('EXACT_BACKUP_FAILED_SOURCE_OR_COPY_CHANGED:' + $Source) }
    return [ordered]@{path=$target.Replace('\','/');fact=$backupFact}
}
function Test-GateProjectInverse([string]$Project, [string]$Backup) {
    $currentBytes = [IO.File]::ReadAllBytes($Project)
    $oldBytes = [IO.File]::ReadAllBytes($Backup)
    $current = [Text.Encoding]::UTF8.GetString($currentBytes)
    if (@($current -split '\r?\n' | Where-Object { $_ -eq $GateExactHook }).Count -ne 1) { return $false }
    $section = [regex]::Match($current, '(?ms)^\[autoload\]\r?\n(?<body>.*?)(?=^\[|\z)').Groups['body'].Value
    if (@($section -split '\r?\n' | Where-Object { $_ -eq $GateExactHook }).Count -ne 1) { return $false }
    foreach ($ending in @("`r`n", "`n")) {
        $needle = $GateExactHook + $ending
        $index = $current.IndexOf($needle, [StringComparison]::Ordinal)
        if ($index -lt 0) { continue }
        $inverse = [Text.Encoding]::UTF8.GetBytes($current.Remove($index, $needle.Length))
        if ([Convert]::ToBase64String($inverse) -ceq [Convert]::ToBase64String($oldBytes)) { return $true }
    }
    return $false
}
