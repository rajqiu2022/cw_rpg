param(
 [Parameter(Mandatory=$true)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$AuthorizationSha256,
 [string]$Authorization=(Join-Path $PSScriptRoot 'ROOT_AUTHORIZATION_REVIEW_READY.json'),
 [string]$Output=(Join-Path $PSScriptRoot 'final_guard_ACTUAL.json')
)
$ErrorActionPreference='Stop'
$finalGame=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$finalGuard=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../city_navigation_20261101d_guard01'))
$finalOriginalCapture=Join-Path $finalGuard 'capture_before_ACTUAL.json'
if((Get-FileHash -LiteralPath $finalOriginalCapture -Algorithm SHA256).Hash.ToLowerInvariant() -cne 'eea89408e036ffcde39c315cead06714decb4edb46ccc555f600c2ec8078f77b'){throw 'ORIGINAL113_CAPTURE_UNCHANGED_REQUIRED'}
$finalBefore=Get-Content -LiteralPath $finalOriginalCapture -Raw|ConvertFrom-Json
$finalHelper=Join-Path $finalGuard 'guard_helpers_ROOT_ONLY.ps1'
$finalHelperKey='res://build/city_navigation_20261101d_guard01/guard_helpers_ROOT_ONLY.ps1'
if((Get-FileHash -LiteralPath $finalHelper -Algorithm SHA256).Hash.ToLowerInvariant() -cne $finalBefore.before_facts.$finalHelperKey.sha256){throw 'ORIGINAL_HELPER_CHANGED'}
. $finalHelper
$finalOutput=Assert-CityNavNewOutput $Output $PSScriptRoot
$finalAuthFact=Get-CityNavSourceFact $Authorization
if($finalAuthFact.sha256 -cne $AuthorizationSha256.ToLowerInvariant()){throw 'ROOT_EXPLICIT_AUTHORIZATION_SHA_REQUIRED'}
$finalAuth=Get-Content -LiteralPath $Authorization -Raw|ConvertFrom-Json
if($finalAuth.schema -ne 'CITY_NAVIGATION_20261101D_STAGE3_AUTHORIZATION_V1' -or $finalAuth.root_approved -ne $true -or @($finalAuth.old_target_deltas).Count -ne 21 -or $finalAuth.candidate_leaf_count -ne 96){throw 'ROOT_APPROVED21_PLUS_ONE_NEW_ART_LEAF_REQUIRED'}
$finalErrors=@();$finalPreflight=$null;$finalPreflightFact=$null;$finalInherited=$null;$finalInheritedFact=$null;$finalInheritedExit=$null
$finalPreflightOutput=Assert-CityNavNewOutput (Join-Path $PSScriptRoot 'source_preflight_ACTUAL.json') $PSScriptRoot
# Source-only Python preflight never accesses registered userdata paths.
& python (Join-Path $PSScriptRoot 'verify_successors_ROOT_ONLY.py') --authorization $Authorization --authorization-sha256 $AuthorizationSha256 --output $finalPreflightOutput | Out-Host
if($LASTEXITCODE -ne 0 -or -not(Test-Path -LiteralPath $finalPreflightOutput)){$finalErrors+='SOURCE_STAGE1_STAGE2_STAGE3_21_OR_ART96_PREFLIGHT_FAILED'}
else{
 $finalPreflight=Get-Content -LiteralPath $finalPreflightOutput -Raw|ConvertFrom-Json
 $finalPreflightFact=Get-CityNavSourceFact $finalPreflightOutput
 if($finalPreflight.passed -ne $true -or $finalPreflight.source_count -ne 21 -or $finalPreflight.new_runtime_source_count -ne 3 -or $finalPreflight.save_metadata_passes -ne 0 -or $finalPreflight.stage3_target_count -ne 2 -or $finalPreflight.stage3_capture_executed -ne $false){$finalErrors+='SOURCE_PREFLIGHT_SCOPE_REQUIRED'}
}
if($finalErrors.Count -eq 0){
 # DO NOT invoke supplement01final: its stage1after is now the stage2before.
 # Call only the original unmodified113guard once, with Root's explicit new
 # 96manifestSHA. It verifies all113 immutable facts, exactprojectinverse,
 # all96currentleaves and the sole final171metadata pass; no save content.
 $finalInheritedOutput=Assert-CityNavNewOutput (Join-Path $finalGuard 'final_guard_inherited_supplement03_ACTUAL.json') $finalGuard
 $finalOriginalScript=Join-Path $finalGuard 'final_guard_ROOT_ONLY.ps1'
 $finalShell=(Get-Process -Id $PID).Path
 & $finalShell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $finalOriginalScript -BeforeSha256 $finalAuth.original_capture_sha256 -CandidateManifestSha256 $finalAuth.candidate_manifest_after_sha256 -ProjectAfterSha256 $finalAuth.project_after_sha256 -Before $finalOriginalCapture -Output $finalInheritedOutput | Out-Host
 $finalInheritedExit=$LASTEXITCODE
 if(Test-Path -LiteralPath $finalInheritedOutput){$finalInherited=Get-Content -LiteralPath $finalInheritedOutput -Raw|ConvertFrom-Json;$finalInheritedFact=Get-CityNavSourceFact $finalInheritedOutput}
 if($finalInheritedExit -ne 0 -or $null -eq $finalInherited -or $finalInherited.passed -ne $true -or $finalInherited.source_count -ne 113 -or $finalInherited.candidate_leaf_count -ne 96 -or $finalInherited.save_count -ne 171 -or $finalInherited.absent_save_count -ne 9){$finalErrors+='ORIGINAL113_96_171_FINAL_GUARD_FAILED'}
}
$finalResult=[ordered]@{
 schema='CITY_NAVIGATION_20261101D_STAGE3_FINITE_FINAL_V1';passed=($finalErrors.Count -eq 0);finished_utc=[DateTime]::UtcNow.ToString('o')
 authorization_path=[IO.Path]::GetFullPath($Authorization);authorization_fact=$finalAuthFact;authorization_sha256=$AuthorizationSha256.ToLowerInvariant()
 original_capture_sha256=$finalAuth.original_capture_sha256;quarter01_capture_sha256=$finalAuth.quarter01_capture_sha256;supplement02_capture_sha256=$finalAuth.supplement02_capture_sha256
 original_immutable_source_count=113;supplement_distinct_source_count=21;source_count=134;quarter01_targets_are_subset_of21=$true;quarter_two_stage_chain_count=2;AC_third_stage_subset_count=2;stage3_fresh_capture_executed=$false
 source_preflight=$finalPreflight;source_preflight_fact=$finalPreflightFact;inherited_original_final=$finalInherited;inherited_original_final_fact=$finalInheritedFact;inherited_exit_code=$finalInheritedExit
 allowed_old_changes=@('res://project.godot')+@($finalAuth.old_target_deltas|ForEach-Object{$_.path});old_canonical_target_count=21
 candidate_leaf_count=96;new_additional_runtime_leaf_count=3;amended_new_art_leaf_count=1;candidate_manifest_original_sha256=$finalAuth.candidate_manifest_before_sha256;candidate_manifest_approved_after_sha256=$finalAuth.candidate_manifest_after_sha256
 candidate_manifest_original_bytes_archived=$true;candidate_unchanged_other_leaf_count=95;art_samepath_only_single_depth_flag=$true
 original113_guard_invocations=if($null -ne $finalInherited){1}else{0};quarter01_final_invocations=0
 save_facts=if($null -ne $finalInherited){$finalInherited.save_facts}else{$null};save_count=if($null -ne $finalInherited){$finalInherited.save_count}else{0};absent_save_count=if($null -ne $finalInherited){$finalInherited.absent_save_count}else{0}
 save_metadata_passes_this_wrapper=0;save_metadata_passes_final_inherited=if($null -ne $finalInherited){$finalInherited.save_metadata_passes_this_script}else{0};save_metadata_passes_total=if($null -ne $finalInherited){$finalInherited.save_metadata_passes_total}else{1}
 save_content_reads=0;save_hashes=0;save_writes=0;save_deserializations=0;automatic_restore=$false;old_guard_edits=0;original_baseline_rewritten=$false;engine_runs=0;old_source_writes=0;errors=$finalErrors
 final_successor_script_fact=(Get-CityNavSourceFact $PSCommandPath)
}
Write-CityNavNewJson $finalOutput $finalResult
[ordered]@{passed=$finalResult.passed;path=$finalOutput;sha256=(Get-CityNavSourceFact $finalOutput).sha256;original113=113;distinct_supplement21=21;source_count=134;quarter_two_stage=2;candidate_leaves=96;extra_runtime_leaves=3;art_leaf_delta=1;saves=$finalResult.save_count;errors=$finalErrors}|ConvertTo-Json -Depth 4
if($finalErrors.Count -ne 0){exit 1}
