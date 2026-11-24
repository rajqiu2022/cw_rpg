param([switch]$Promote,[string]$AuthorizationPath,[string]$AuthorizationSha)
$ErrorActionPreference = 'Stop'
$RepoRoot = 'F:\Code\RPG_GAME'
$GameRoot = 'F:\Code\RPG_GAME\game'
$IsolationRoot = 'F:\Code\RPG_GAME\game\build\luoyang_city_full_rollout_20261022ap_qa01\isolate_examiner_portrait_ready01'
$TemplatePath = 'F:\Code\RPG_GAME\game\build\luoyang_city_full_rollout_20261022ap_qa01\examiner_portrait_three_leaf_pre_authorization_TEMPLATE.json'
$TemplateSha = 'd806e0c44c5ca90fa74418774c487558ad5c07f6333f8df0108585c5fbb493e7'
$ResultPath = Join-Path $IsolationRoot 'ap_full_examiner_portrait_import_result_36012.json'
$ResultSha = 'ee97525951a2160b8c2bd75e5e8f30273ac38362083ca4bded6b6afb87004d05'
$AdmissionPath = 'F:\Code\RPG_GAME\game\build\luoyang_city_full_rollout_20261022ap_root01\portrait_ui_finite_admission_READY.json'
$AdmissionSha = 'd2c8470d07e834771954f8b7e2dd64ebcbeec859a417e737d29d7d9a6f47d016'
$RawPath = 'F:\Code\RPG_GAME\assets\raw\luoyang_city_finish_20261022ap\portrait_luoyang_examiner_mature_same_sprite_20261022ap_v1.png'
$RawSha = '4fba998b313e66b60f62804ea8968b25742dc5825a76921743265e6a26031dcc'
function ExactHash([string]$Path,[string]$Expected) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf) -or (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() -cne $Expected) { throw ('Fixed source SHA differs: ' + $Path) }
}
ExactHash $TemplatePath $TemplateSha
ExactHash $ResultPath $ResultSha
ExactHash $AdmissionPath $AdmissionSha
ExactHash $RawPath $RawSha
$Template = Get-Content -LiteralPath $TemplatePath -Raw | ConvertFrom-Json
$Result = Get-Content -LiteralPath $ResultPath -Raw | ConvertFrom-Json
$Admission = Get-Content -LiteralPath $AdmissionPath -Raw | ConvertFrom-Json
if ($Result.passed -ne $true -or $Result.checks -ne 59 -or @($Result.failures).Count -ne 0 -or @($Result.rows).Count -ne 1) { throw 'Exact isolated36012 result required' }
if ($Admission.approved_by_root -ne $true -or $Admission.source_sha256 -cne $RawSha -or $Admission.complete_A1_ten_percent_padding_pass -ne $false) { throw 'Only Root full-canvas UI fit admission, never sprite padding' }
$Row = $Result.rows[0]
if ($Row.texture -cne 'res://art/portraits/luoyang_city_finish_20261022ap/examiner_mature_v1.png' -or $Row.source_sha256 -cne $RawSha -or $Row.rgba_sha256 -cne '1b762b4007103e92eab904c9d6271ab6188e440bd20e4a410691dc413f9a7187' -or @($Row.size).Count -ne 2 -or $Row.size[0] -ne 1254 -or $Row.size[1] -ne 1254 -or $Row.full_rgba_exact -ne $true -or $Row.params23 -ne $true -or $Row.zero_mipmaps -ne $true -or $Row.detect3d_compress_to -ne 0) { throw 'Original1254 fullRGBA/23/mip0/detect0 proof differs' }
$Paths = @($Row.import_path,$Row.compiled_path,$Row.texture)
$Hashes = @('284ed8f2af70e4b9d499fb561cb0ab88f299394690f6c9baf1b99149d85ee2b1','b3140dfd0ebea21c80bab0f310802ffc2e85907a386ea4c614879442f2436cac',$RawSha)
if ($Row.import_sha256 -cne $Hashes[0] -or $Row.compiled_sha256 -cne $Hashes[1] -or $Paths[0] -cne ($Row.texture + '.import') -or $Paths[1] -cne 'res://.godot/imported/examiner_mature_v1.png-25f2af75a741a5e611494715946e4a2e.ctex') { throw 'Exact imported remap identity differs' }
if (@($Template.targets).Count -ne 3 -or (($Template.order -join ',') -cne 'import,ctex,png')) { throw 'Exact three-leaf ordered template' }
$Operations = @()
for ($Index=0;$Index -lt 3;$Index++) {
    if ($Template.targets[$Index].path -cne $Paths[$Index] -or $Template.targets[$Index].before -cne 'ABSENT' -or $Template.targets[$Index].after_sha256 -cne $Hashes[$Index]) { throw 'Exact template row differs' }
    $Source = [System.IO.Path]::GetFullPath((Join-Path $IsolationRoot $Paths[$Index].Substring(6)))
    $Target = [System.IO.Path]::GetFullPath((Join-Path $GameRoot $Paths[$Index].Substring(6)))
    if (-not $Source.StartsWith($IsolationRoot + '\',[System.StringComparison]::OrdinalIgnoreCase) -or -not $Target.StartsWith($GameRoot + '\',[System.StringComparison]::OrdinalIgnoreCase)) { throw 'Validated absolute copy path containment' }
    ExactHash $Source $Hashes[$Index]
    if (Test-Path -LiteralPath $Target) { throw ('Canonical ABSENT target already exists: ' + $Target) }
    $Operations += [pscustomobject]@{source=$Source;target=$Target;res_path=$Paths[$Index];before='ABSENT';after_sha256=$Hashes[$Index]}
}
if ($Promote) {
    if ([string]::IsNullOrWhiteSpace($AuthorizationPath) -or $AuthorizationSha -cnotmatch '^[0-9a-fA-F]{64}$') { throw 'Root NEW exact authorization path/SHA required before promotion' }
    $AuthAbsolute = [System.IO.Path]::GetFullPath($AuthorizationPath)
    if (-not $AuthAbsolute.StartsWith($RepoRoot + '\',[System.StringComparison]::OrdinalIgnoreCase)) { throw 'Root authorization must be inside exact workspace' }
    ExactHash $AuthAbsolute $AuthorizationSha.ToLowerInvariant()
    $Auth = Get-Content -LiteralPath $AuthAbsolute -Raw | ConvertFrom-Json
    if ($Auth.status -cne 'ROOT_AUTHORIZED_EXACT_THREE_ABSENT_EXAMINER_MEDIA' -or $Auth.approved_by_root -ne $true -or $Auth.template_sha256 -cne $TemplateSha -or $Auth.root_finite_admission_sha256 -cne $AdmissionSha -or $Auth.actual_isolated_import_result_sha256 -cne $ResultSha -or (($Auth.order -join ',') -cne 'import,ctex,png') -or @($Auth.targets).Count -ne 3) { throw 'Root authorization does not match frozen three-leaf scope' }
    for ($Index=0;$Index -lt 3;$Index++) {
        if ($Auth.targets[$Index].path -cne $Paths[$Index] -or $Auth.targets[$Index].before -cne 'ABSENT' -or $Auth.targets[$Index].after_sha256 -cne $Hashes[$Index]) { throw 'Unauthorized media leaf row' }
    }
    foreach ($Operation in $Operations) {
        if (Test-Path -LiteralPath $Operation.target) { throw 'Race: canonical target no longer ABSENT, no overwrite' }
        $Directory = [System.IO.Path]::GetDirectoryName($Operation.target)
        if (-not (Test-Path -LiteralPath $Directory)) { New-Item -ItemType Directory -Path $Directory | Out-Null }
        # Atomic fail-if-exists copy: metadata then compiled bytes, PNG last.
        [System.IO.File]::Copy($Operation.source,$Operation.target,$false)
        ExactHash $Operation.target $Operation.after_sha256
    }
    foreach ($Operation in $Operations) { ExactHash $Operation.source $Operation.after_sha256; ExactHash $Operation.target $Operation.after_sha256 }
    ExactHash $RawPath $RawSha
    ExactHash $ResultPath $ResultSha
    ExactHash $AdmissionPath $AdmissionSha
    ExactHash $AuthAbsolute $AuthorizationSha.ToLowerInvariant()
}
[pscustomobject]@{status=if($Promote){'ROOT_THREE_ABSENT_EXAMINER_MEDIA_PROMOTED_EXACT_BYTES_NO_ENGINE'}else{'READONLY_PROMOTION_PLAN_REQUIRES_NEW_ROOT_AUTHORIZATION'};operations=$Operations;template_sha256=$TemplateSha;actual_import_result_sha256=$ResultSha;root_finite_admission_sha256=$AdmissionSha;raw_modified=$false;engine_or_reimport_executed=$false;runtime_code_sourceclosure_or_UI_acceptance=$false} | ConvertTo-Json -Depth 7
