$ErrorActionPreference = 'Stop'
$repo = 'F:/Code/RPG_GAME'
$out = Join-Path $repo 'game/build/riverside_visual_20261101a_source01'
$priorPath = Join-Path $repo 'game/build/world_coast_20261031h_qa01/final_guard39_ACTUAL.json'
$prior = Get-Content -LiteralPath $priorPath -Raw | ConvertFrom-Json
function Get-Fact([string]$path) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return [ordered]@{exists=$false} }
    $a = Get-Item -LiteralPath $path
    $len = $a.Length; $ticks = $a.LastWriteTimeUtc.Ticks.ToString()
    $sha = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    $b = Get-Item -LiteralPath $path
    return [ordered]@{exists=$true;bytes=$len;utc_ticks=$ticks;sha256=$sha;stable_during_hash=($len -eq $b.Length -and $ticks -eq $b.LastWriteTimeUtc.Ticks.ToString())}
}
$targets = @('game/build/adventure_world_20261031f_system01/world_links.gd','game/scripts/adventure/adventure_runtime.gd')
$facts = [ordered]@{}; $backups = [ordered]@{}
foreach ($rel in $targets) {
    $path = Join-Path $repo $rel
    $facts[$path.Replace('\','/')] = Get-Fact $path
    $dest = Join-Path $out ('before/' + $rel)
    New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force | Out-Null
    Copy-Item -LiteralPath $path -Destination $dest
    $backups[$dest.Replace('\','/')] = Get-Fact $dest
    if ($backups[$dest.Replace('\','/')].sha256 -ne $facts[$path.Replace('\','/')].sha256) { throw 'BACKUP_MISMATCH' }
}
$saveFacts = [ordered]@{}; $saveChangedSincePrior = @()
foreach ($prop in $prior.facts.PSObject.Properties) {
    if (-not $prop.Name.StartsWith('C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/')) { continue }
    $now = Get-Fact $prop.Name
    $saveFacts[$prop.Name] = $now
    if (($now | ConvertTo-Json -Compress) -ne ($prop.Value | ConvertTo-Json -Compress)) { $saveChangedSincePrior += $prop.Name }
}
if ($saveFacts.Count -ne 171) { throw ('EXPECTED_171_SAVE_METADATA_GOT_' + $saveFacts.Count) }
$absent = [ordered]@{}
foreach ($path in $prior.expected_absent_save_paths) { $absent[$path] = Get-Fact $path }
$needles = @('res://build/adventure_world_20261031f_system01/world_links.gd','res://scripts/adventure/adventure_runtime.gd','52c780a8a83691183888fe78930004c67b5c7ef95faf4521243f03e967756c8f','892507132063f814fce7d68b80d49f75452e9adbf944c799b07e4477afd17412')
$hits = @(); $scanned = 0
foreach ($prop in $prior.facts.PSObject.Properties) {
    if (-not $prop.Name.StartsWith($repo + '/game/')) { continue }
    if ([IO.Path]::GetExtension($prop.Name) -notin @('.gd','.json','.tres','.tscn','.godot')) { continue }
    if (-not $prop.Value.exists -or $prop.Value.bytes -gt 2097152) { continue }
    $source = [IO.File]::ReadAllText($prop.Name)
    $scanned++
    $found = @($needles | Where-Object { $source.Contains($_) })
    if ($found.Count) { $hits += [ordered]@{path=$prop.Name;needles=$found} }
}
$report = [ordered]@{
    status='BOUNDED_TWO_TARGET_FRESH_BEFORE_WITH_PRIOR3236_HISTORICAL_REUSE';captured_utc=[DateTime]::UtcNow.ToString('o')
    prior_guard_path=$priorPath;prior_guard_sha256=(Get-Fact $priorPath).sha256;prior_source_count=3236;prior_source_credit='HISTORICAL_ONLY_NOT_FRESH_REHASHED'
    initial_capture_assertion_failure='First invocation counted existing saves only: 162; stopped before report. Prior save_count171 includes162existing+9absent. Corrected to include all171 metadata facts; no production or save writes.'
    authorized_old_targets=$targets;before=$facts;backups=$backups;save_count=$saveFacts.Count;save_facts=$saveFacts;save_changed_since_prior=$saveChangedSincePrior
    absent_facts=$absent;bounded_text_files_scanned=$scanned;bounded_reference_hits=$hits
    production_writes=0;engine_runs=0;process_control=0;save_deserializations=0;save_writes=0;automatic_restore=$false
}
$json = $report | ConvertTo-Json -Depth 12
[IO.File]::WriteAllText((Join-Path $out 'before_ACTUAL.json'),$json,[Text.UTF8Encoding]::new($false))
[ordered]@{status=$report.status;old_target_count=$facts.Count;save_count=$saveFacts.Count;save_changed_since_prior=$saveChangedSincePrior.Count;absent_count=$absent.Count;text_scanned=$scanned;reference_hits=$hits;output=(Join-Path $out 'before_ACTUAL.json')} | ConvertTo-Json -Depth 5
