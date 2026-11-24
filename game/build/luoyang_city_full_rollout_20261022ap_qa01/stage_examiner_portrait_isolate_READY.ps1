param([switch]$Stage)
$ErrorActionPreference = 'Stop'
# Root-only mechanical same-respath copy. No engine/import/canonical/saved-user path.
$RepositoryRoot = 'F:\Code\RPG_GAME'
$IsolationRoot = 'F:\Code\RPG_GAME\game\build\luoyang_city_full_rollout_20261022ap_qa01\isolate_examiner_portrait_ready01'
$PreparedPath = Join-Path $IsolationRoot 'prepared_READY.json'
$PreparedSha = '4ed0ea9c68b1a50f05e3f22ebab3bf227f5feec0c1004233467d3d572603c156'
if ((Resolve-Path -LiteralPath $RepositoryRoot).Path -cne $RepositoryRoot) { throw 'Repository absolute identity mismatch' }
if ((Resolve-Path -LiteralPath $IsolationRoot).Path -cne $IsolationRoot) { throw 'Isolation absolute identity mismatch' }
if ((Get-FileHash -LiteralPath $PreparedPath -Algorithm SHA256).Hash.ToLowerInvariant() -cne $PreparedSha) { throw 'Prepared fixed SHA changed' }
$Spec = Get-Content -LiteralPath $PreparedPath -Raw | ConvertFrom-Json
if ($Spec.status -cne 'AP_EXACT_ONE_FULL_EXAMINER_UI_PORTRAIT_READY_FOR_ISOLATED_IMPORT' -or @($Spec.textures).Count -ne 1) { throw 'Exact one complete original UI portrait only' }
if ((Get-FileHash -LiteralPath (Join-Path $IsolationRoot 'project.godot') -Algorithm SHA256).Hash.ToLowerInvariant() -cne $Spec.project_sha256) { throw 'No-autoload project changed' }
$Targets = @{
    examiner_mature_portrait='res://art/portraits/luoyang_city_finish_20261022ap/examiner_mature_v1.png'
}
foreach ($Proof in $Spec.provenance) {
    $ProofPath = [System.IO.Path]::GetFullPath($Proof.path)
    if (-not $ProofPath.StartsWith($RepositoryRoot + '\',[System.StringComparison]::OrdinalIgnoreCase)) { throw 'Actual publication proof escapes workspace' }
    if ((Get-FileHash -LiteralPath $ProofPath -Algorithm SHA256).Hash.ToLowerInvariant() -cne $Proof.sha256) { throw 'Fixed actual publication proof changed' }
}
$Operations = @()
$Seen = @{}
foreach ($Row in $Spec.textures) {
    if ($Row.visual_kind -cne 'examiner_mature_portrait' -or $Seen.ContainsKey($Row.visual_kind)) { throw 'One unique fixed full portrait identity' }
    $Seen[$Row.visual_kind] = $true
    $ExpectedTexture = $Targets[$Row.visual_kind]
    if ($Row.texture -cne $ExpectedTexture) { throw 'Exact same-respath target identity' }
    foreach ($CanonicalLeaf in @($Row.texture, ($Row.texture + '.import'), $Row.compiled_path)) {
        $CanonicalPath = [System.IO.Path]::GetFullPath((Join-Path (Join-Path $RepositoryRoot 'game') $CanonicalLeaf.Substring(6)))
        if (Test-Path -LiteralPath $CanonicalPath) { throw ('Canonical promotion target must remain ABSENT: ' + $CanonicalPath) }
    }
    $SeedSource = Join-Path $IsolationRoot ('seeds\' + $Row.visual_kind + '.png.import.seed')
    foreach ($Candidate in @(
        @{ source=$SeedSource; target=($Row.texture + '.import'); sha=$Row.seed_sha256; kind='seed' },
        @{ source=$Row.candidate_path; target=$Row.texture; sha=$Row.source_sha256; kind='png' }
    )) {
        $SourcePath = [System.IO.Path]::GetFullPath($Candidate.source)
        $TargetPath = [System.IO.Path]::GetFullPath((Join-Path $IsolationRoot $Candidate.target.Substring(6)))
        if (-not $SourcePath.StartsWith($RepositoryRoot + '\',[System.StringComparison]::OrdinalIgnoreCase)) { throw 'Read source escapes exact workspace' }
        if (-not $TargetPath.StartsWith($IsolationRoot + '\',[System.StringComparison]::OrdinalIgnoreCase)) { throw 'Copy target escapes isolated project' }
        if (Test-Path -LiteralPath $TargetPath) { throw ('NEW absent-only target exists: ' + $TargetPath) }
        if ((Get-FileHash -LiteralPath $SourcePath -Algorithm SHA256).Hash.ToLowerInvariant() -cne $Candidate.sha) { throw ('Fixed source SHA changed: ' + $SourcePath) }
        $Operations += [pscustomobject]@{ source=$SourcePath; target=$TargetPath; sha256=$Candidate.sha; kind=$Candidate.kind }
    }
}
if ($Seen.Count -ne 1 -or $Operations.Count -ne 2) { throw 'Only one full-original portrait seed+PNG pair' }
if ($Stage) {
    # Seed is installed first, PNG last; editor of main project is never invoked.
    foreach ($Kind in @('seed','png')) {
        foreach ($Operation in @($Operations | Where-Object { $_.kind -ceq $Kind })) {
            $DirectoryPath = [System.IO.Path]::GetDirectoryName($Operation.target)
            if (-not (Test-Path -LiteralPath $DirectoryPath)) { New-Item -ItemType Directory -Path $DirectoryPath | Out-Null }
            Copy-Item -LiteralPath $Operation.source -Destination $Operation.target -ErrorAction Stop
            if ((Get-FileHash -LiteralPath $Operation.target -Algorithm SHA256).Hash.ToLowerInvariant() -cne $Operation.sha256) { throw 'Copied exact bytes mismatch' }
        }
    }
}
[pscustomobject]@{ status=if($Stage){'ONE_FULL_UI_PORTRAIT_AND_SEED_STAGED_NO_ENGINE_NO_CANONICAL'}else{'READONLY_COPY_PLAN_ONLY'}; isolated_project=$IsolationRoot; prepared_sha256=$PreparedSha; operations=$Operations; canonical_write=$false; import_executed=$false } | ConvertTo-Json -Depth 6
