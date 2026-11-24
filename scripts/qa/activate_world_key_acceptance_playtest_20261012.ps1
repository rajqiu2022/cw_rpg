#requires -Version 7.5
<# Root-only, reversible WORLD ONLY local playtest deployment. No engine launch.
Proof: scope/user_authorized/full_release; key_acceptance (root_reviewed=true,
remaining_acceptance=USER_MANUAL, full_gameplay_claim=false); source_sha256 map
(exclude canonical world, include this script/contract/Field/Player/immutable
candidate+layout+stream+source+manifest); player_files (15 exact original rows).
Optional key_result binds a natural0 complete zero-failure actual receipt.
Activate: -Action Activate -ApprovalPath <json> -ApprovalSha256 <SHA256>
Rollback: -Action Rollback -JournalPath <printed journal> -JournalSha256 <SHA256>
Only world_map_jianghu.tres changes. Cities, outskirts and saves are protected.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Activate','Rollback')][string]$Action,
    [string]$ApprovalPath, [string]$ApprovalSha256,
    [string]$JournalPath, [string]$JournalSha256
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$scope='USER_AUTHORIZED_WORLD_KEY_ACCEPTANCE_PLAYTEST_NOT_FULL_RELEASE'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$game=Join-Path $repo 'game'
$recoveryRoot=Join-Path $game 'build/world_key_acceptance_playtest_cutover_20261012'
$target='res://data/scenes/world_map_jianghu.tres'
$originalSha='838380fdb05d08b4b521d92efb12a13369358090740dc5c7d4cb7c9ec6f4c015'
$formalSha='685876ac86cb3b739f9b51be12da60e4a125480c715da2d08f9b486d76e5a046'
$candidate='res://data/scenes/world_map_jianghu_v15.tres'
$fixed=[ordered]@{
    'res://data/scenes/world_map_jianghu_v15.tres'='31c5034e44092f146879e45715b97425c6e899e8ef1c375c94f03b2a35fc9065'
    'res://data/maps/world_map_jianghu_layout_v15.tres'='aeae58273fed2bbfd8145347bab75fbbd934ac2c4efd0f622edb7fa7b1c9f072'
    'res://data/background_sets/world_map_jianghu_v15_streamed.tres'='3536182ec4eba967e8cd6b5da6b8ca6bb44072022f342d190eb807995a772400'
    'res://data/maps/world_map_v15_complete_v9c_source.json'='85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f'
    'res://art/maps/world_map_v15_complete_v9c/art_contract.json'='1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a'
}
$protected=[ordered]@{
    'res://data/scenes/ch4_s0_luoyang_gate.tres'='872b4ff502f4f8c88eb238a25e3bcdfcb37bec5f71d2e84906ad53f751c90e17'
    'res://data/scenes/ch4_s1_luoyang_yamen.tres'='5a0c1124a4166087573a1d4d6bc217e496251856cb88a60b6f78ba04019c12f5'
    'res://data/scenes/ch4_s2_canal_docks.tres'='51527c472d4c4ce33e00f1a07754411cc433f770c5882614187f165a7834b34d'
    'res://data/scenes/ch4_s3_luoyang_market.tres'='3d4d7fb941845c9220b27adf726160704cb9e3e2713ac4f58322c2e90f3e2660'
    'res://data/config/outskirts_native_adoption.json'='203c9f08e941908ace3e8d56e18a15963e3a60859c04741b04e28a968386d0ff'
}
function Require($condition,[string]$message) { if (-not $condition) { throw $message } }
function HashBytes([byte[]]$bytes) { [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant() }
function RepoPath([string]$path) {
    Require (-not [string]::IsNullOrWhiteSpace($path) -and $path -notmatch '(^|[\\/])\.\.([\\/]|$)') 'Empty/traversing path'
    $value=if ($path.StartsWith('res://')) { Join-Path $game $path.Substring(6) } elseif ($path.StartsWith('repo://')) { Join-Path $repo $path.Substring(7) } elseif ([IO.Path]::IsPathRooted($path)) { $path } else { Join-Path $repo $path }
    $value=[IO.Path]::GetFullPath($value)
    Require ($value.StartsWith($repo+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) "Outside project: $path"
    $value
}
function CheckHash([string]$path,$expected) {
    Require ($expected -is [string] -and $expected -cmatch '^[0-9a-fA-F]{64}$') "Malformed SHA: $path"
    Require ((Get-FileHash -LiteralPath (RepoPath $path)).Hash.ToLowerInvariant() -ceq $expected.ToLowerInvariant()) "Changed/missing: $path"
}
function ReadJson([string]$path) { [IO.File]::ReadAllText($path) | ConvertFrom-Json -AsHashtable -DateKind String }
function Players {
    $rows=@(); $dir=Join-Path ([Environment]::GetFolderPath('ApplicationData')) 'Godot/app_userdata/云影侠传'
    foreach ($slot in 0..4) { foreach ($suffix in @('','.bak','.tmp')) {
        $path=Join-Path $dir "save_$slot.json$suffix"; $row=[ordered]@{path=$path;exists=[IO.File]::Exists($path)}
        if ($row.exists) { $f=Get-Item -LiteralPath $path; $row.sha256=(Get-FileHash -LiteralPath $path).Hash; $row.bytes=$f.Length; $row.utc_ticks=$f.LastWriteTimeUtc.Ticks.ToString([Globalization.CultureInfo]::InvariantCulture) }
        $rows+=$row
    } }; return ,$rows
}
function CheckPlayers($expected) {
    $now=Players; Require ($expected -is [array] -and $expected.Count -eq 15) 'Exactly 15 player records required'
    for ($i=0;$i -lt 15;$i++) {
        $a=$expected[$i];$b=$now[$i]
        Require ($a -is [Collections.IDictionary] -and $a.path -ceq $b.path -and $a.exists -is [bool] -and $a.exists -eq $b.exists) "Player identity changed: $i"
        if ($b.exists) { Require ($a.sha256 -is [string] -and $a.sha256.ToLowerInvariant() -ceq $b.sha256.ToLowerInvariant() -and $a.bytes -eq $b.bytes -and $a.utc_ticks -is [string] -and $a.utc_ticks -ceq $b.utc_ticks) "Player bytes/ticks changed: $i" }
    }
}
function CheckProtected { foreach ($p in $protected.Keys) { CheckHash $p $protected[$p] } }
function CheckSources($proof) {
    Require ($proof.source_sha256 -is [Collections.IDictionary]) 'Fresh immutable source snapshot required'
    $paths=@{}
    foreach ($p in $proof.source_sha256.Keys) {
        $full=RepoPath $p; Require ($full -ine (RepoPath $target)) 'World write target must not be an immutable source'
        $paths[$full]=$true; CheckHash $p $proof.source_sha256[$p]
    }
    $required=@($fixed.Keys)+@('res://scripts/world/world_map_v15_contract.gd','res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','res://scripts/field/field_walkable_controller.gd','res://scripts/field/player.gd','scripts/qa/activate_world_key_acceptance_playtest_20261012.ps1')
    foreach ($p in $required) { Require ($paths.ContainsKey((RepoPath $p))) "Required source absent: $p" }
    foreach ($p in $fixed.Keys) { CheckHash $p $fixed[$p] }
}
function SaveJournal($value) {
    [IO.File]::WriteAllText($script:journalFile,($value|ConvertTo-Json -Depth 20)+"`n",[Text.UTF8Encoding]::new($false))
    Write-Host "JOURNAL $script:journalFile SHA256=$((Get-FileHash -LiteralPath $script:journalFile).Hash) STATE=$($value.state)"
}
function LockedHash($file) { $file.Position=0; [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($file)).ToLowerInvariant() }
function LockedWrite($file,[byte[]]$bytes) {
    $file.Position=0;$file.SetLength(0);$file.Write($bytes,0,$bytes.Length);$file.Flush($true)
    $file.Position=0;$actual=[byte[]]::new($bytes.Length);$file.ReadExactly($actual,0,$actual.Length)
    Require ($file.Length -eq $bytes.Length -and [Collections.StructuralComparisons]::StructuralEqualityComparer.Equals($actual,$bytes)) 'World exact byte readback differs'
}
$file=$null;$journal=$null;$writeStarted=$false;$oldBytes=$null;$newBytes=$null
try {
    CheckProtected; $playersAtStart=Players
    if ($Action -eq 'Activate') {
        Require ([string]::IsNullOrWhiteSpace($JournalPath) -and [string]::IsNullOrWhiteSpace($JournalSha256)) 'Do not mix activate/rollback'
        CheckHash $ApprovalPath $ApprovalSha256;$proof=ReadJson (RepoPath $ApprovalPath)
        Require ($proof.scope -ceq $scope -and $proof.user_authorized -is [bool] -and $proof.user_authorized -and $proof.full_release -is [bool] -and -not $proof.full_release) 'Explicit user WORLD key-playtest authority required'
        $key=$proof.key_acceptance
        Require ($key -is [Collections.IDictionary] -and $key.scope -is [string] -and $key.scope -ceq 'ROOT_REVIEWED_WORLD_KEY_ACCEPTANCE_REST_USER_PLAYTEST' -and $key.root_reviewed -is [bool] -and $key.root_reviewed -and $key.remaining_acceptance -is [string] -and $key.remaining_acceptance -ceq 'USER_MANUAL' -and $key.full_gameplay_claim -is [bool] -and -not $key.full_gameplay_claim) 'Limited reviewed acceptance/manual remainder required; no full gameplay claim'
        if ($proof.Contains('key_result')) {
            $r=$proof.key_result;Require ($r -is [Collections.IDictionary] -and $r.actual_os_exit -is [long] -and $r.actual_os_exit -eq 0 -and $r.root_reviewed -is [bool] -and $r.root_reviewed) 'Optional actual receipt must be natural0/reviewed'
            CheckHash $r.path $r.sha256;$actual=ReadJson (RepoPath $r.path)
            Require ($actual.complete -is [bool] -and $actual.complete -and $actual.failures -is [long] -and $actual.failures -eq 0) 'Optional actual key receipt incomplete/failed'
        }
        CheckSources $proof;CheckPlayers $proof.player_files;CheckHash $target $originalSha
        $oldBytes=[IO.File]::ReadAllBytes((RepoPath $target));$candidateBytes=[IO.File]::ReadAllBytes((RepoPath $candidate))
        Require ((HashBytes $oldBytes) -ceq $originalSha -and (HashBytes $candidateBytes) -ceq $fixed[$candidate]) 'Captured old/candidate bytes changed'
        $text=[Text.Encoding]::UTF8.GetString($candidateBytes);$oldID='scene_id = &"world_map_jianghu_v15"';$newID='scene_id = &"world_map_jianghu"'
        Require (([regex]::Matches($text,[regex]::Escape($oldID))).Count -eq 1) 'Exactly one authored candidate identity required'
        $newBytes=[Text.Encoding]::UTF8.GetBytes($text.Replace($oldID,$newID));Require ((HashBytes $newBytes) -ceq $formalSha) 'Identity-only formal buffer differs'
        $directory=Join-Path $recoveryRoot ([datetime]::UtcNow.ToString('yyyyMMddTHHmmssfffffffZ')+'_'+[guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($directory)|Out-Null;[IO.File]::WriteAllText((Join-Path $directory '.gdignore'),'', [Text.UTF8Encoding]::new($false))
        $backup=Join-Path $directory 'original_world_map_jianghu.tres';[IO.File]::WriteAllBytes($backup,$oldBytes);CheckHash $backup $originalSha
        $script:journalFile=Join-Path $directory 'journal.json'
        $journal=@{schema=1;scope=$scope;state='PREPARED';target=$target;backup_path=$backup;original_sha256=$originalSha;activated_sha256=$formalSha;candidate_path=$candidate;candidate_sha256=$fixed[$candidate];identity_only_change=$true;world_coordinate_version=15;full_release=$false;old_six_satisfied=$false;formal_smoke='NOT_RUN';key_acceptance=$key;approval_path=(RepoPath $ApprovalPath);approval_sha256=$ApprovalSha256;protected=$protected;player_files=$playersAtStart;expected_changes=@($target)}
        if ($proof.Contains('key_result')) { $journal.key_result=$proof.key_result }
        SaveJournal $journal
        CheckHash $ApprovalPath $ApprovalSha256;CheckSources $proof;CheckProtected;CheckPlayers $playersAtStart
    } else {
        Require ([string]::IsNullOrWhiteSpace($ApprovalPath) -and [string]::IsNullOrWhiteSpace($ApprovalSha256)) 'Rollback does not accept activation proof'
        CheckHash $JournalPath $JournalSha256;$script:journalFile=RepoPath $JournalPath
        Require ($script:journalFile.StartsWith($recoveryRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -and [IO.Path]::GetFileName($script:journalFile) -ceq 'journal.json') 'Only scoped retained journal allowed'
        $journal=ReadJson $script:journalFile;$backup=Join-Path ([IO.Path]::GetDirectoryName($script:journalFile)) 'original_world_map_jianghu.tres'
        Require ($journal.schema -eq 1 -and $journal.scope -ceq $scope -and $journal.target -ceq $target -and $journal.original_sha256 -ceq $originalSha -and $journal.activated_sha256 -ceq $formalSha -and $journal.backup_path -ceq $backup) 'Recovery identity unbound'
        CheckHash $backup $originalSha;$oldBytes=[IO.File]::ReadAllBytes($backup);Require ((HashBytes $oldBytes) -ceq $originalSha) 'Captured backup changed'
    }
    $file=[IO.File]::Open((RepoPath $target),[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    $sha=LockedHash $file;Require ($sha -ceq $originalSha -or ($Action -eq 'Rollback' -and $sha -ceq $formalSha)) 'Stale/unrelated canonical world; preserved'
    if ($Action -eq 'Activate') { CheckHash $ApprovalPath $ApprovalSha256;CheckSources $proof }
    CheckProtected;CheckPlayers $playersAtStart;$writeStarted=$true
    LockedWrite $file $(if ($Action -eq 'Activate') { $newBytes } else { $oldBytes })
    CheckProtected;CheckPlayers $playersAtStart
    $journal.state=if ($Action -eq 'Activate') { 'WORLD_ACTIVATED_USER_PLAYTEST_FORMAL_SMOKE_PENDING' } else { 'ROLLED_BACK' };SaveJournal $journal
    Write-Host "$scope $Action completed: only canonical world changed; no old six/full release claim."
} catch {
    $primary=$_.Exception.Message
    if ($writeStarted) {
        $recovered=$false
        try { $sha=LockedHash $file;Require ($sha -ceq $originalSha -or $sha -ceq $formalSha) 'Unknown partial/unrelated bytes preserved';LockedWrite $file $oldBytes;$recovered=$true } catch { }
        $journal.state=if ($recovered) { 'ROLLED_BACK_AFTER_FAILURE' } else { 'RECOVERY_REQUIRED_UNKNOWN_BYTES_PRESERVED' };$journal.failure=$primary
        try { SaveJournal $journal } catch { Write-Warning 'Journal update failed; exact backup retained' }
    }
    throw "WORLD ONLY cutover refused/failed: $primary"
} finally { if ($null -ne $file) { $file.Dispose() } }
