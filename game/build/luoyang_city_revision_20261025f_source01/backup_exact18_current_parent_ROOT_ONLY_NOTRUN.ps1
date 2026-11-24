# Root-only exact18 old backup. No Stage/import/engine/canonical writes.
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$gameRoot=[IO.Path]::GetFullPath([IO.Path]::Combine($PSScriptRoot,'..','..'))
if (-not [IO.File]::Exists([IO.Path]::Combine($gameRoot,'project.godot'))) { throw 'EXACT_GAME_ROOT_REQUIRED' }
function Read-Bytes([string]$literal) { return ,([IO.File]::ReadAllBytes($literal)) }
function SHA-Bytes([byte[]]$bytes) {
    $hasher=[Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($hasher.ComputeHash($bytes))).Replace('-','').ToLowerInvariant() }
    finally { $hasher.Dispose() }
}
function Resolve-Res([string]$res) {
    if (-not $res.StartsWith('res://') -or $res.Contains('..')) { throw 'EXACT_RES_PATH_REQUIRED' }
    $resolved=[IO.Path]::GetFullPath([IO.Path]::Combine($gameRoot,$res.Substring(6).Replace('/',[IO.Path]::DirectorySeparatorChar)))
    if (-not $resolved.StartsWith($gameRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'RES_OUTSIDE_GAME' }
    return $resolved
}
function Assert-Under([string]$path,[string]$parent) {
    if (-not $path.StartsWith($parent+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'BACKUP_OUTSIDE_EXCLUSIVE_PREFIX' }
}
$scopePath=Join-Path $PSScriptRoot 'street_materials18_scope_PREPARATION.json'
$scopeSHA='c6920eb563c899186b3091cf2acb69cc70d592ec394e7603c49585671ef4428b'
$scopeBytes=Read-Bytes $scopePath
if ((SHA-Bytes $scopeBytes) -ne $scopeSHA) { throw 'FIXED_SCOPE_SHA_REQUIRED' }
$scope=[Text.Encoding]::UTF8.GetString($scopeBytes) | ConvertFrom-Json
if ($scope.status -ne 'SOURCE25F_EXACT18_CURRENT_EE47_PARENT_SCOPE_ONLY_NOT_STAGE' -or $scope.target_count -ne 18 -or @($scope.targets).Count -ne 18 -or $scope.partition.GD -ne 7 -or $scope.partition.JSON -ne 11) { throw 'EXACT18_SCOPE_REQUIRED' }
$rootNS=Resolve-Res 'res://build/luoyang_city_revision_20261025f_root01'
$backupPrefix=Resolve-Res 'res://build/luoyang_city_revision_20261025f_root01/predeploy18_backup'
$receiptPath=Join-Path $rootNS 'predeploy18_backup_receipt.json'
Assert-Under $backupPrefix $rootNS
if ([IO.File]::Exists($receiptPath) -or [IO.Directory]::Exists($receiptPath)) { throw 'NEW_RECEIPT_MUST_BE_ABSENT' }
if ([IO.Directory]::Exists($backupPrefix) -or [IO.File]::Exists($backupPrefix)) { throw 'NEW_BACKUP_PREFIX_MUST_BE_ABSENT' }
$guardPath=Resolve-Res $scope.parent_postguard.path
$guardBytes=Read-Bytes $guardPath
if ((SHA-Bytes $guardBytes) -ne $scope.parent_postguard.sha256) { throw 'FIXED_POSTGUARD_SHA_REQUIRED' }
$guard=[Text.Encoding]::UTF8.GetString($guardBytes) | ConvertFrom-Json
if ($guard.passed -ne $true -or @($guard.backups_current).Count -ne 98) { throw 'ORIGINAL_98_BACKUP_DOMAIN_REQUIRED' }
$oldBackupPaths=@($guard.backups_current | ForEach-Object { [IO.Path]::GetFullPath([string]$_.path) })
$seen=@{}; $prepared=@(); $written=@(); $started=[DateTime]::UtcNow.ToString('o')
# Complete preflight before the first new directory/file write.
foreach ($row in $scope.targets) {
    $res=[string]$row.target
    if ($seen.ContainsKey($res)) { throw 'DUPLICATE_TARGET' }
    $seen[$res]=$true
    $source=Resolve-Res $res
    $destination=Resolve-Res ([string]$row.backup_candidate_path)
    $expectedDestination=[IO.Path]::GetFullPath([IO.Path]::Combine($backupPrefix,$res.Substring(6).Replace('/',[IO.Path]::DirectorySeparatorChar)))
    Assert-Under $destination $backupPrefix
    if ($destination -ne $expectedDestination -or $oldBackupPaths -contains $destination) { throw 'EXACT_NEW_BACKUP_TARGET_REQUIRED_NO_OLD98_OVERWRITE' }
    if ([IO.File]::Exists($destination) -or [IO.Directory]::Exists($destination)) { throw 'ALL_18_NEW_BACKUP_TARGETS_MUST_BE_ABSENT' }
    $immutable=Resolve-Res ([string]$row.immutable_old)
    $immutableBytes=Read-Bytes $immutable
    if ((SHA-Bytes $immutableBytes) -ne $row.old_sha256 -or $immutableBytes.LongLength -ne $row.old_bytes) { throw ('FIXED_IMMUTABLE_OLD_MISMATCH '+$res) }
    $before=Get-Item -LiteralPath $source
    $ticks=$before.LastWriteTimeUtc.Ticks.ToString()
    $bytes=Read-Bytes $source
    $after=Get-Item -LiteralPath $source
    if ((SHA-Bytes $bytes) -ne $row.old_sha256 -or $bytes.LongLength -ne $row.old_bytes -or $after.Length -ne $bytes.LongLength -or $after.LastWriteTimeUtc.Ticks.ToString() -ne $ticks) { throw ('CURRENT_MUST_EQUAL_FIXED_OLD_AND_STABLE '+$res) }
    $prepared+=@{ target=$res; path=$source; sha256=[string]$row.old_sha256; bytes=[long]$row.old_bytes; source_ticks=$ticks; backup=$destination; body=$bytes }
}
if ($prepared.Count -ne 18) { throw 'COMPLETE18_PREFLIGHT_REQUIRED' }
# Every destination is exclusive CreateNew; even a race cannot overwrite it.
[void][IO.Directory]::CreateDirectory($backupPrefix)
foreach ($row in $prepared) {
    $parent=[IO.Path]::GetDirectoryName($row.backup)
    Assert-Under $row.backup $backupPrefix
    [void][IO.Directory]::CreateDirectory($parent)
    $stream=[IO.File]::Open($row.backup,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try { $stream.Write($row.body,0,$row.body.Length);$stream.Flush($true) } finally { $stream.Dispose() }
    $check=Read-Bytes $row.backup
    if ((SHA-Bytes $check) -ne $row.sha256 -or $check.LongLength -ne $row.bytes) { throw ('NEW_BACKUP_BYTE_VERIFY_FAILED '+$row.target) }
    $sourceCheck=Read-Bytes $row.path
    $sourceStat=Get-Item -LiteralPath $row.path
    if ((SHA-Bytes $sourceCheck) -ne $row.sha256 -or $sourceCheck.LongLength -ne $row.bytes -or $sourceStat.LastWriteTimeUtc.Ticks.ToString() -ne $row.source_ticks) { throw ('SOURCE_CHANGED_DURING_BACKUP_KEEP_PARTIAL_NEW_FILES '+$row.target) }
    $backupStat=Get-Item -LiteralPath $row.backup
    $written+=[ordered]@{ target=$row.target; path=$row.path; backup=$row.backup; sha256=$row.sha256; bytes=$row.bytes; source_ticks=$row.source_ticks; backup_sha256=(SHA-Bytes $check); backup_ticks=$backupStat.LastWriteTimeUtc.Ticks.ToString() }
}
$receipt=[ordered]@{ status='EXACT18_CURRENT_EE47_PARENT_BACKED_UP_NO_CANONICAL_WRITES';passed=$true;count=18;targets=@($written);scope_path='res://build/luoyang_city_revision_20261025f_source01/street_materials18_scope_PREPARATION.json';scope_sha256=$scopeSHA;parent_stage_sha256='8ea2ed3e987510ace0ef772e4f683468b714e77c6648f7c086e234520f9bd826';parent_deployment_sha256='ee47ad85fadce157fb805a039f734b8fcd1d4eb05d54a6d197ab539a93c20f89';fresh_observation_sha256='e92b03c9ca2e5e5a95bfc8f8bf1451e8550a5d841a366bc2c1c2c0d738775a22';old98_backups_not_written=$true;started_utc=$started;finished_utc=[DateTime]::UtcNow.ToString('o');Stage_calls=0;engine_calls=0;canonical_writes=0;save_writes=0;processes_stopped=0 }
$json=$receipt | ConvertTo-Json -Depth 10
$utf8=New-Object Text.UTF8Encoding($false)
$receiptBytes=$utf8.GetBytes($json+"`n")
$stream=[IO.File]::Open($receiptPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try { $stream.Write($receiptBytes,0,$receiptBytes.Length);$stream.Flush($true) } finally { $stream.Dispose() }
[ordered]@{ receipt=$receiptPath;sha256=(SHA-Bytes $receiptBytes);count=18;canonical_writes=0 } | ConvertTo-Json -Compress
