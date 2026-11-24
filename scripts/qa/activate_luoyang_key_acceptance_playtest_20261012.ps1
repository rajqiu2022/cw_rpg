#requires -Version 7.5
<# No engine launch and no old six-stage approval. Root supplies a SHA-bound small
proof: scope/user_authorized/full_release; source_sha256 map of res:// or repo
paths (exclude four canonical targets); candidate_sha256/layout_sha256 maps;
player_files (the fixed 15 original records); geometry_results (headless/gpu,
path/sha256/actual_os_exit/root_reviewed); key_acceptance explicitly delegates
remaining gameplay/current-save acceptance to USER_MANUAL, never a fake PASS.
Optional partial_actual binds after/stderr paths+SHA and the actual parent -1.
Activate: -Action Activate -ApprovalPath <json> -ApprovalSha256 <SHA256>
Rollback: -Action Rollback -JournalPath <printed journal> -JournalSha256 <SHA256>
Only four canonical .tres may change. No layout, player, world or source writes.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Activate','Rollback')][string]$Action,
    [string]$ApprovalPath, [string]$ApprovalSha256,
    [string]$JournalPath, [string]$JournalSha256
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$scope = 'USER_AUTHORIZED_KEY_ACCEPTANCE_PLAYTEST_NOT_FULL_RELEASE'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$game = Join-Path $repo 'game'
$recoveryRoot = Join-Path $game 'build/luoyang_key_acceptance_playtest_cutover_20261012'
$originals = [ordered]@{
    ch4_s0_luoyang_gate='b967c347e745e6f05d51a8f596fde4744571f5d459279467c706e66d9be24bd1'
    ch4_s1_luoyang_yamen='7bed5d322d583c9c7bf4e392f3f4c75ffb0577db24bb9e6237a4ae3aa0808b01'
    ch4_s2_canal_docks='81850afd0877bba70e2ed0786fe4e81570faee8e06e827561349988f9c4d41a5'
    ch4_s3_luoyang_market='5cd76d0c0a0c54358f50b341186c5ea078a7d20657c97dc15ef15027755661ab'
}
$protected = [ordered]@{
    'res://data/scenes/world_map_jianghu.tres'='838380fdb05d08b4b521d92efb12a13369358090740dc5c7d4cb7c9ec6f4c015'
    'res://data/config/outskirts_native_adoption.json'='203c9f08e941908ace3e8d56e18a15963e3a60859c04741b04e28a968386d0ff'
}
function Require($condition,[string]$message) { if (-not $condition) { throw $message } }
function HashBytes([byte[]]$bytes) { return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant() }
function RepoPath([string]$path) {
    Require (-not [string]::IsNullOrWhiteSpace($path) -and $path -notmatch '(^|[\\/])\.\.([\\/]|$)') 'Empty/traversing path'
    $value = if ($path.StartsWith('res://')) { Join-Path $game $path.Substring(6) } elseif ($path.StartsWith('repo://')) { Join-Path $repo $path.Substring(7) } elseif ([IO.Path]::IsPathRooted($path)) { $path } else { Join-Path $repo $path }
    $value = [IO.Path]::GetFullPath($value)
    Require ($value.StartsWith($repo+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) "Outside project: $path"
    return $value
}
function CheckHash([string]$path,$expected) {
    Require ($expected -is [string] -and $expected -cmatch '^[0-9a-fA-F]{64}$') "Malformed SHA: $path"
    Require ((Get-FileHash -LiteralPath (RepoPath $path) -Algorithm SHA256).Hash.ToLowerInvariant() -ceq $expected.ToLowerInvariant()) "Changed/missing file: $path"
}
function ReadJson([string]$path) { return [IO.File]::ReadAllText($path) | ConvertFrom-Json -AsHashtable -DateKind String }
function SaveJournal($value) {
    [IO.File]::WriteAllText($script:journalFile,($value | ConvertTo-Json -Depth 30)+"`n",[Text.UTF8Encoding]::new($false))
    Write-Host "JOURNAL $script:journalFile SHA256=$((Get-FileHash -LiteralPath $script:journalFile).Hash) STATE=$($value.state)"
}
function Players {
    $playerRoot = Join-Path ([Environment]::GetFolderPath('ApplicationData')) 'Godot/app_userdata/云影侠传'
    $rows = @()
    foreach ($slot in 0..4) { foreach ($suffix in @('','.bak','.tmp')) {
        $path = Join-Path $playerRoot "save_$slot.json$suffix"
        $row = [ordered]@{path=$path;exists=[IO.File]::Exists($path)}
        if ($row.exists) { $f=Get-Item -LiteralPath $path; $row.sha256=(Get-FileHash -LiteralPath $path).Hash; $row.bytes=$f.Length; $row.utc_ticks=$f.LastWriteTimeUtc.Ticks.ToString([Globalization.CultureInfo]::InvariantCulture) }
        $rows += $row
    } }
    return ,$rows
}
function CheckPlayers($expected) {
    $now = Players
    Require ($expected -is [array] -and $expected.Count -eq 15) 'Exactly 15 player records required'
    for ($i=0;$i -lt 15;$i++) {
        $a=$expected[$i]; $b=$now[$i]
        Require ($a -is [Collections.IDictionary] -and $a.path -ceq $b.path -and $a.exists -is [bool] -and $a.exists -eq $b.exists) "Player path/existence changed: $i"
        if ($b.exists) { Require ($a.sha256 -is [string] -and $a.sha256.ToLowerInvariant() -ceq $b.sha256.ToLowerInvariant() -and $a.bytes -eq $b.bytes -and $a.utc_ticks -is [string] -and $a.utc_ticks -ceq $b.utc_ticks) "Player bytes/ticks changed: $($b.path)" }
    }
}
function CheckProtected { foreach ($p in $protected.Keys) { CheckHash $p $protected[$p] } }
function CheckSources($proof) {
    Require ($proof.source_sha256 -is [Collections.IDictionary]) 'Source snapshot required'
    $boundPaths=@{}
    foreach ($p in $proof.source_sha256.Keys) {
        $boundPaths[(RepoPath $p)]=$true
        foreach ($id in $originals.Keys) { Require ((RepoPath $p) -ine (RepoPath "res://data/scenes/$id.tres")) 'Canonical write targets must not be in immutable source map' }
        CheckHash $p $proof.source_sha256[$p]
    }
    foreach ($required in @('res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','res://scripts/city/luoyang_layered_v3_contract.gd','res://scripts/field/field_walkable_controller.gd','res://scripts/field/player.gd','scripts/qa/activate_luoyang_key_acceptance_playtest_20261012.ps1')) { Require ($boundPaths.ContainsKey((RepoPath $required))) "Required source identity absent: $required" }
}
function CheckReceipt($receipt,[bool]$geometry) {
    Require ($receipt -is [Collections.IDictionary] -and $receipt.actual_os_exit -is [long] -and $receipt.actual_os_exit -eq 0 -and $receipt.root_reviewed -is [bool] -and $receipt.root_reviewed) 'Actual natural0 root-reviewed receipt required'
    CheckHash $receipt.path $receipt.sha256
    $result=ReadJson (RepoPath $receipt.path)
    Require ($result.complete -is [bool] -and $result.complete -and $result.failures -is [long] -and $result.failures -eq 0) 'Bound actual result incomplete/failed'
    if ($geometry) { Require ($result.scope -ceq 'LUOYANG_ENCLOSURE_V11_CITY_ONLY_FRESH_ACTUAL' -and $result.mode.phase -ceq 'geometry' -and $result.mode.candidate -is [bool] -and $result.mode.candidate) 'Geometry candidate receipt identity changed' }
}
function LockedHash($stream) { $stream.Position=0; return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($stream)).ToLowerInvariant() }
function LockedWrite($stream,[byte[]]$bytes) {
    $stream.Position=0; $stream.SetLength(0); $stream.Write($bytes,0,$bytes.Length); $stream.Flush($true)
    $stream.Position=0; $actual=[byte[]]::new($bytes.Length); $stream.ReadExactly($actual,0,$actual.Length)
    Require ($stream.Length -eq $bytes.Length -and [Collections.StructuralComparisons]::StructuralEqualityComparer.Equals($actual,$bytes)) 'Canonical exact byte readback differs'
}
$streams=@{}; $oldBuffers=@{}; $newBuffers=@{}; $entries=@{}; $journal=$null; $writeStarted=$false
try {
    CheckProtected
    $playersAtStart=Players
    if ($Action -eq 'Activate') {
        Require ([string]::IsNullOrWhiteSpace($JournalPath) -and [string]::IsNullOrWhiteSpace($JournalSha256)) 'Activation and rollback arguments cannot mix'
        CheckHash $ApprovalPath $ApprovalSha256
        $proof=ReadJson (RepoPath $ApprovalPath)
        Require ($proof.scope -ceq $scope -and $proof.user_authorized -is [bool] -and $proof.user_authorized -and $proof.full_release -is [bool] -and -not $proof.full_release) 'User key-acceptance playtest authority only; not full release'
        CheckSources $proof; CheckPlayers $proof.player_files
        Require ($proof.geometry_results -is [array] -and $proof.geometry_results.Count -eq 2) 'Two current geometry receipts required'
        $seen=@{}; foreach ($g in $proof.geometry_results) { Require ($g.backend -in @('headless','gpu') -and -not $seen.ContainsKey($g.backend)) 'Duplicate/unknown geometry backend'; $seen[$g.backend]=$true; CheckReceipt $g $true }
        $key=$proof.key_acceptance
        Require ($key -is [Collections.IDictionary] -and $key.scope -is [string] -and $key.scope -ceq 'ROOT_REVIEWED_GEOMETRY_AND_COMPLETED_PORTAL_CASES_REST_USER_PLAYTEST' -and $key.root_reviewed -is [bool] -and $key.root_reviewed -and $key.remaining_acceptance -is [string] -and $key.remaining_acceptance -ceq 'USER_MANUAL' -and $key.full_gameplay_claim -is [bool] -and -not $key.full_gameplay_claim -and $key.current_save_read_claim -is [bool] -and -not $key.current_save_read_claim) 'Explicit root-reviewed limited acceptance/rest user playtest required; no full gameplay/current-save claim'
        $partial=$null
        if ($proof.Contains('partial_actual')) {
            $partial=$proof.partial_actual
            Require ($partial -is [Collections.IDictionary] -and $partial.actual_os_exit -is [long] -and $partial.actual_os_exit -eq -1) 'Partial actual parent exit must remain -1, not a full PASS'
            CheckHash $partial.after_path $partial.after_sha256; CheckHash $partial.stderr_path $partial.stderr_sha256
            $partialAfter=ReadJson (RepoPath $partial.after_path)
            Require ($partialAfter.actual_os_exit -is [long] -and $partialAfter.actual_os_exit -eq -1) 'Bound partial after record must preserve actual -1'
        }
        Require ($proof.candidate_sha256 -is [Collections.IDictionary] -and $proof.candidate_sha256.Count -eq 4 -and $proof.layout_sha256 -is [Collections.IDictionary] -and $proof.layout_sha256.Count -eq 4) 'Exact four candidate/layout tables required'
        $directory=Join-Path $recoveryRoot ([datetime]::UtcNow.ToString('yyyyMMddTHHmmssfffffffZ')+'_'+[guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($directory) | Out-Null
        [IO.File]::WriteAllText((Join-Path $directory '.gdignore'),'', [Text.UTF8Encoding]::new($false))
        $script:journalFile=Join-Path $directory 'journal.json'
        foreach ($id in $originals.Keys) {
            $target="res://data/scenes/$id.tres"; $candidate="res://data/scenes/luoyang_enclosure_v11_candidates/$id.tres"; $layout="res://data/maps/luoyang_enclosure_v11_candidates/${id}_layout.tres"
            CheckHash $target $originals[$id]; CheckHash $candidate $proof.candidate_sha256[$candidate]; CheckHash $layout $proof.layout_sha256[$layout]
            $oldBuffers[$target]=[IO.File]::ReadAllBytes((RepoPath $target)); $newBuffers[$target]=[IO.File]::ReadAllBytes((RepoPath $candidate))
            Require ((HashBytes $oldBuffers[$target]) -ceq $originals[$id] -and (HashBytes $newBuffers[$target]) -ceq $proof.candidate_sha256[$candidate].ToLowerInvariant()) 'Captured old/new buffer differs from approval'
            $text=[Text.Encoding]::UTF8.GetString($newBuffers[$target])
            Require ($text.Contains('scene_id = &"'+$id+'"') -and $text.Contains('path="'+$layout+'"') -and $text.Contains('metadata/city_enclosure_manifest_sha = "')) 'Candidate scene/layout/enclosure identity absent'
            $backup=Join-Path $directory "original_$id.tres"; [IO.File]::WriteAllBytes($backup,$oldBuffers[$target]); CheckHash $backup $originals[$id]
            $entries[$target]=@{backup_path=$backup;original_sha256=$originals[$id];activated_sha256=(HashBytes $newBuffers[$target]);candidate_path=$candidate;required_layout_path=$layout;required_layout_sha256=$proof.layout_sha256[$layout]}
        }
        # Recheck all immutable proof sources and exact buffers immediately before
        # the write batch. Subsequent writes use ONLY these captured byte arrays.
        CheckHash $ApprovalPath $ApprovalSha256; CheckSources $proof; CheckProtected; CheckPlayers $playersAtStart
        foreach ($target in $entries.Keys) { CheckHash $entries[$target].candidate_path $entries[$target].activated_sha256; CheckHash $entries[$target].required_layout_path $entries[$target].required_layout_sha256 }
        $journal=@{schema=1;scope=$scope;state='PREPARED';full_release=$false;formal_no_flags_smoke='NOT_RUN';approval_path=(RepoPath $ApprovalPath);approval_sha256=$ApprovalSha256;geometry_results=$proof.geometry_results;key_acceptance=$key;partial_actual=$partial;targets=$entries;player_files=$playersAtStart;protected=$protected;expected_changes=@($entries.Keys);old_six_satisfied=$false}
        SaveJournal $journal
    } else {
        Require ([string]::IsNullOrWhiteSpace($ApprovalPath) -and [string]::IsNullOrWhiteSpace($ApprovalSha256)) 'Rollback does not accept activation proof'
        CheckHash $JournalPath $JournalSha256; $script:journalFile=RepoPath $JournalPath
        Require ($script:journalFile.StartsWith($recoveryRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -and [IO.Path]::GetFileName($script:journalFile) -ceq 'journal.json') 'Rollback requires retained scoped journal'
        $journal=ReadJson $script:journalFile
        Require ($journal.scope -ceq $scope -and $journal.full_release -eq $false -and $journal.targets.Count -eq 4) 'Not a four-city key-playtest journal'
        $entries=$journal.targets
        foreach ($id in $originals.Keys) {
            $target="res://data/scenes/$id.tres"; $entry=$entries[$target]; $backup=Join-Path ([IO.Path]::GetDirectoryName($script:journalFile)) "original_$id.tres"
            Require ($entry.original_sha256 -ceq $originals[$id] -and $entry.backup_path -ceq $backup -and $entry.activated_sha256 -cmatch '^[0-9a-f]{64}$') 'Recovery original/new identity unbound'
            CheckHash $backup $originals[$id]; $oldBuffers[$target]=[IO.File]::ReadAllBytes($backup)
            Require ((HashBytes $oldBuffers[$target]) -ceq $originals[$id]) 'Captured recovery buffer changed after SHA check'
        }
    }
    # Lock all four files before any canonical write, preventing a concurrent
    # canonical edit between SHA check and write. Unknown content is never erased.
    foreach ($id in $originals.Keys) {
        $target="res://data/scenes/$id.tres"; $stream=[IO.File]::Open((RepoPath $target),[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None); $streams[$target]=$stream
        $sha=LockedHash $stream
        Require ($sha -ceq $entries[$target].original_sha256 -or ($Action -eq 'Rollback' -and $sha -ceq $entries[$target].activated_sha256)) 'Canonical changed since approval; unrelated edit preserved'
    }
    CheckProtected; CheckPlayers $playersAtStart
    $writeStarted=$true
    foreach ($target in $streams.Keys) { LockedWrite $streams[$target] $(if ($Action -eq 'Activate') { $newBuffers[$target] } else { $oldBuffers[$target] }) }
    CheckProtected; CheckPlayers $playersAtStart
    $journal.state=if ($Action -eq 'Activate') { 'ACTIVATED_USER_PLAYTEST_FORMAL_SMOKE_PENDING' } else { 'ROLLED_BACK' }
    SaveJournal $journal
    Write-Host "$scope $Action completed; only four canonical scenes changed; old six NOT satisfied."
} catch {
    $primary=$_.Exception.Message
    if ($writeStarted) {
        $recovered=$true
        foreach ($target in $streams.Keys) {
            try { $sha=LockedHash $streams[$target]; Require ($sha -ceq $entries[$target].original_sha256 -or $sha -ceq $entries[$target].activated_sha256) 'Unknown canonical content; preserve for manual recovery'; LockedWrite $streams[$target] $oldBuffers[$target] } catch { $recovered=$false }
        }
        $journal.state=if ($recovered) { 'ROLLED_BACK_AFTER_FAILURE' } else { 'RECOVERY_REQUIRED_UNKNOWN_BYTES_PRESERVED' }; $journal.failure=$primary
        try { SaveJournal $journal } catch { Write-Warning 'Journal update failed; retained backups remain at printed directory' }
    }
    throw "Key-playtest cutover refused/failed: $primary"
} finally { foreach ($stream in $streams.Values) { $stream.Dispose() } }
