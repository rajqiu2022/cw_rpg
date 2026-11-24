param(
    [string]$OutputName = 'baseline_before_ACTUAL.json',
    [string[]]$AdditionalTargets = @()
)
$ErrorActionPreference = 'Stop'
$taskRoot = 'F:\Code\RPG_GAME'
$qaRoot = Join-Path $taskRoot 'game\build\major_cities_20261028_qa01'
$priorPath = Join-Path $taskRoot 'game\build\luoyang_city_finish_20261025i_source01\region_visual_finish_repair04\current_B78D_backup27_ROOT_ACTUAL.json'
$outputPath = Join-Path $qaRoot $OutputName
if ($OutputName -ne [IO.Path]::GetFileName($OutputName) -or [IO.File]::Exists($outputPath)) { throw 'A new independent output filename is required.' }
$prior = Get-Content -LiteralPath $priorPath -Raw | ConvertFrom-Json
$savePaths = @($prior.save15.PSObject.Properties | ForEach-Object { $_.Name })
if ($savePaths.Count -ne 15) { throw 'Expected exactly the 15 previously registered save paths.' }
$targets = @(
    (Join-Path $taskRoot 'game\data\scenes\openworld_bianzhou_city.tres'),
    (Join-Path $taskRoot 'game\scripts\autoload\scene_router.gd')
) + $AdditionalTargets
$canonicalFacts = [ordered]@{}
$saveFacts = [ordered]@{}
$backups = @()
function Get-TaskFileFact([string]$FilePath) {
    if (-not [IO.File]::Exists($FilePath)) { return [ordered]@{exists=$false} }
    $item = Get-Item -LiteralPath $FilePath
    return [ordered]@{
        exists=$true
        sha256=(Get-FileHash -LiteralPath $FilePath -Algorithm SHA256).Hash.ToLowerInvariant()
        bytes=$item.Length
        utc_ticks=$item.LastWriteTimeUtc.Ticks.ToString()
    }
}
foreach ($target in ($targets | Select-Object -Unique)) {
    $fullPath = [IO.Path]::GetFullPath($target)
    if (-not $fullPath.StartsWith($taskRoot + '\', [StringComparison]::OrdinalIgnoreCase)) { throw "Target outside workspace: $fullPath" }
    $fact = Get-TaskFileFact $fullPath
    if (-not $fact.exists) { throw "Canonical target missing: $fullPath" }
    $canonicalFacts[$fullPath] = $fact
    $relative = $fullPath.Substring($taskRoot.Length + 1)
    $backupPath = Join-Path (Join-Path $qaRoot ($OutputName + '_backups')) $relative
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($backupPath)) | Out-Null
    $inputStream = [IO.File]::Open($fullPath, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
    try {
        $backupStream = [IO.File]::Open($backupPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try { $inputStream.CopyTo($backupStream) } finally { $backupStream.Dispose() }
    } finally { $inputStream.Dispose() }
    [IO.File]::SetLastWriteTimeUtc($backupPath, [DateTime]::new([long]$fact.utc_ticks, [DateTimeKind]::Utc))
    $backupFact = Get-TaskFileFact $backupPath
    if ($backupFact.sha256 -ne $fact.sha256 -or $backupFact.bytes -ne $fact.bytes -or $backupFact.utc_ticks -ne $fact.utc_ticks) { throw 'Backup differs from its exact source fact.' }
    $backups += [ordered]@{source=$fullPath; path=$backupPath; fact=$backupFact}
}
foreach ($savePath in $savePaths) { $saveFacts[$savePath] = Get-TaskFileFact $savePath }
$processes = @(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'" | Select-Object ProcessId,Name,CommandLine)
$result = [ordered]@{
    status='SMALL_BIANZHOU_BASELINE_ONLY'
    captured_utc=[DateTime]::UtcNow.ToString('o')
    save_path_source=$priorPath
    save_path_source_sha256=(Get-FileHash -LiteralPath $priorPath -Algorithm SHA256).Hash.ToLowerInvariant()
    canonical_targets=$canonicalFacts
    save15=$saveFacts
    exact_full_backups=$backups
    godot_processes=$processes
    editor51856_present=(@($processes | Where-Object ProcessId -eq 51856).Count -eq 1)
    save_content_parsed=$false
    canonical_writes=0
    save_writes=0
    engine_calls=0
    processes_stopped=0
}
$json = $result | ConvertTo-Json -Depth 12
$encoded = [Text.UTF8Encoding]::new($false).GetBytes($json + "`n")
$outputStream = [IO.File]::Open($outputPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
try { $outputStream.Write($encoded, 0, $encoded.Length) } finally { $outputStream.Dispose() }
Write-Output ([ordered]@{output=$outputPath; sha256=(Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash.ToLowerInvariant(); canonical_count=$canonicalFacts.Count; saves=$saveFacts.Count; backups=$backups.Count; editor51856=$result.editor51856_present} | ConvertTo-Json -Compress)
