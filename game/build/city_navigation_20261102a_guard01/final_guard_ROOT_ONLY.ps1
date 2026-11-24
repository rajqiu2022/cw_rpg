param(
 [Parameter(Mandatory=$true)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$AuthorizationSha256,
 [string]$Authorization=(Join-Path $PSScriptRoot 'ROOT_AUTHORIZATION_REVIEW_READY.json'),
 [string]$Capture=(Join-Path $PSScriptRoot 'capture_before_ACTUAL.json'),
 [string]$Output=(Join-Path $PSScriptRoot 'final_guard_ACTUAL.json')
)
$ErrorActionPreference='Stop'
if((Get-FileHash -LiteralPath $Authorization -Algorithm SHA256).Hash.ToLowerInvariant() -cne $AuthorizationSha256.ToLowerInvariant()){throw 'ROOT_EXPLICIT_COMPLETED_AUTHORIZATION_SHA_REQUIRED'}
$mouthAuth=Get-Content -LiteralPath $Authorization -Raw|ConvertFrom-Json
if($mouthAuth.schema -ne 'CITY_NAVIGATION_ROADMOUTHS_20261102A_FINAL_AUTHORIZATION_V1' -or $mouthAuth.root_approved -ne $true){throw 'ROOT_APPROVED_FINAL_AFTERS_AND_ART_REQUIRED'}
if((Get-FileHash -LiteralPath $Capture -Algorithm SHA256).Hash.ToLowerInvariant() -cne $mouthAuth.capture_sha256){throw 'EXACT_D815_FRESH_CAPTURE_REQUIRED'}
$mouthCapture=Get-Content -LiteralPath $Capture -Raw|ConvertFrom-Json
if($mouthCapture.schema -ne 'CITY_NAVIGATION_ROADMOUTHS_20261102A_FINITE_CAPTURE_V1' -or $mouthCapture.captured_successfully -ne $true -or $mouthCapture.save_count -ne 171 -or $mouthCapture.save_metadata_passes -ne 1 -or $mouthCapture.finite_deduplicated_source_count -ne 208){throw 'ORIGINAL208_171_SINGLE_BEFORE_CAPTURE_REQUIRED'}
$mouthHelpers=$mouthCapture.established_guard_helper_path
if((Get-FileHash -LiteralPath $mouthHelpers -Algorithm SHA256).Hash.ToLowerInvariant() -cne $mouthCapture.established_guard_helper_fact.sha256){throw 'UNCHANGED_ESTABLISHED_METADATA_HELPERS_REQUIRED'}
# Definitions only: no priorcapture/final/publication script is invoked.
. $mouthHelpers
$mouthOutput=Assert-CityNavNewOutput $Output $PSScriptRoot
$mouthPreflightPath=Assert-CityNavNewOutput (Join-Path $PSScriptRoot 'source_preflight_ACTUAL.json') $PSScriptRoot
$mouthErrors=@();$mouthPreflight=$null;$mouthPreflightFact=$null
& python (Join-Path $PSScriptRoot 'verify_sources_ROOT_ONLY.py') --authorization $Authorization --authorization-sha256 $AuthorizationSha256 --capture $Capture --output $mouthPreflightPath | Out-Host
if($LASTEXITCODE -ne 0 -or -not(Test-Path -LiteralPath $mouthPreflightPath)){$mouthErrors+='FINITE_SOURCE_STAGE_OR_REQUIRED_NORMAL_EVIDENCE_FAILED'}
else{
 $mouthPreflight=Get-Content -LiteralPath $mouthPreflightPath -Raw|ConvertFrom-Json
 $mouthPreflightFact=Get-CityNavSourceFact $mouthPreflightPath
 if($mouthPreflight.passed -ne $true -or $mouthPreflight.finite_source_count -ne 208 -or $mouthPreflight.immutable134_count -ne 134 -or $mouthPreflight.sample_and_final_manifest_leaf_count -ne 99 -or $mouthPreflight.unchanged_old_leaf_count -ne 94 -or $mouthPreflight.save_metadata_passes -ne 0){$mouthErrors+='EXACT208_134_99_94_SOURCE_PREFLIGHT_REQUIRED'}
}
$mouthSaves=[ordered]@{};$mouthSaveChanges=@();$mouthAfterMetadataPasses=0
if($mouthErrors.Count -eq 0){
 # Sole final userdata access: exactly oneGet-Item per registeredpath through
 # existing metadata helper. Never open/read/hash/deserialize/write/restore.
 foreach($property in ($mouthCapture.save_facts.PSObject.Properties|Sort-Object Name)){
   $metadata=Get-CityNavSaveMetadata $property.Name
   $mouthSaves[$property.Name]=$metadata
   if(-not(Test-CityNavMetadataSame $property.Value $metadata)){
     $mouthSaveChanges+=[ordered]@{path=$property.Name;fresh_before=$property.Value;actual_after=$metadata;policy='KEEP_ACTUAL_EXTERNAL_DIFFERENCE_NO_RESTORE_NO_REBASE'}
     $mouthErrors+=('SAVE_METADATA_CHANGED:'+ $property.Name)
   }
 }
 $mouthAfterMetadataPasses=1
 if($mouthSaves.Count -ne 171){$mouthErrors+='EXACT_REGISTERED171_METADATA_AFTER_REQUIRED'}
}
$mouthResult=[ordered]@{
 schema='CITY_NAVIGATION_ROADMOUTHS_20261102A_FINITE_FINAL_V1';passed=($mouthErrors.Count -eq 0);finished_utc=[DateTime]::UtcNow.ToString('o')
 authorization_path=[IO.Path]::GetFullPath($Authorization);authorization_sha256=$AuthorizationSha256.ToLowerInvariant();capture_path=[IO.Path]::GetFullPath($Capture);capture_sha256=$mouthAuth.capture_sha256
 prior_guard_path=$mouthCapture.prior_guard_path;prior_guard_sha256=$mouthAuth.prior_guard_sha256;prior_guard_invocations=0
 source_preflight=$mouthPreflight;source_preflight_fact=$mouthPreflightFact;immutable134_count=134;finite_deduplicated_source_count=208;unchanged_finite_source_count=205
 allowed_mutable_paths=$mouthCapture.allowed_prospective_mutable_paths;full_before_backup_count=3;sample_manifest_archive_count=1
 runtime_manifest_stages=@($mouthAuth.manifest_before_sha256,$mouthAuth.sample_stage.manifest_sha256,$mouthAuth.manifest_after_sha256)
 before_runtime_leaves=96;sample_runtime_leaves=99;final_runtime_leaves=99;unchanged_old_runtime_leaves=94;existing_added_media_leaves=3
 new_true_legs=14;inherited_true_legs=8;combined_actual_pair_count=11;combined_actual_direction_count=22;travel_not_reexecuted_by_guard=$true
 save_facts=$mouthSaves;registered_save_count=171;save_count=$mouthSaves.Count;absent_save_count=@($mouthSaves.Values|Where-Object{-not $_.exists}).Count
 save_metadata_passes_before=1;save_metadata_passes_after=$mouthAfterMetadataPasses;save_metadata_passes_total=(1+$mouthAfterMetadataPasses)
 save_changes_preserved=$mouthSaveChanges;historical_save_metadata_differences_preserved=$mouthCapture.historical_save_metadata_differences_preserved;historical_source_metadata_differences_preserved=$mouthCapture.historical_source_metadata_differences_preserved
 save_content_reads=0;save_hashes=0;save_writes=0;save_deserializations=0;automatic_restore=$false;old_source_publication_targets=0;old21_or33_closure_runs=0;engine_runs=0;process_control=0;old_source_writes=0;errors=$mouthErrors
 final_script_fact=(Get-CityNavSourceFact $PSCommandPath)
}
Write-CityNavNewJson $mouthOutput $mouthResult
[ordered]@{passed=$mouthResult.passed;path=$mouthOutput;sha256=(Get-CityNavSourceFact $mouthOutput).sha256;finite_sources=208;old134=134;runtime99=99;unchanged_old94=94;saves=$mouthSaves.Count;metadata_after_passes=$mouthAfterMetadataPasses;errors=$mouthErrors}|ConvertTo-Json -Depth 4
if($mouthErrors.Count -ne 0){exit 1}
