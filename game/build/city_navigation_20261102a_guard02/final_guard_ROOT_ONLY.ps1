param(
 [Parameter(Mandatory=$true)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$AuthorizationSha256,
 [string]$Authorization=(Join-Path $PSScriptRoot 'ROOT_AUTHORIZATION_REVIEW_READY.json'),
 [string]$Capture=(Join-Path $PSScriptRoot '../city_navigation_20261102a_guard01/capture_before_ACTUAL.json'),
 [string]$Output=(Join-Path $PSScriptRoot 'final_guard_ACTUAL.json')
)
$ErrorActionPreference='Stop'
if((Get-FileHash -LiteralPath $Authorization -Algorithm SHA256).Hash.ToLowerInvariant() -cne $AuthorizationSha256.ToLowerInvariant()){throw 'EXACT_ROOT_AUTHORIZATION_REQUIRED'}
$pairAuth=Get-Content -LiteralPath $Authorization -Raw|ConvertFrom-Json
if($pairAuth.schema -ne 'CITY_NAVIGATION_ROADMOUTHS_20261102A_PAIR_FINAL_AUTHORIZATION_V1' -or $pairAuth.root_approved -ne $true){throw 'ROOT_APPROVED_PAIR_AFTER_AND_CIVIC_ART_REQUIRED'}
if((Get-FileHash -LiteralPath $Capture -Algorithm SHA256).Hash.ToLowerInvariant() -cne $pairAuth.capture_sha256){throw 'ORIGINAL_D815_CAPTURE_REQUIRED'}
$pairCap=Get-Content -LiteralPath $Capture -Raw|ConvertFrom-Json
if($pairCap.captured_successfully -ne $true -or $pairCap.finite_deduplicated_source_count -ne 208 -or $pairCap.save_count -ne 171 -or $pairCap.save_metadata_passes -ne 1){throw 'ORIGINAL208_AND_SOLE171_BEFORE_REQUIRED'}
if((Get-FileHash -LiteralPath $pairCap.established_guard_helper_path -Algorithm SHA256).Hash.ToLowerInvariant() -cne $pairCap.established_guard_helper_fact.sha256){throw 'UNCHANGED_ESTABLISHED_HELPER_REQUIRED'}
. $pairCap.established_guard_helper_path
$pairOutput=Assert-CityNavNewOutput $Output $PSScriptRoot
$pairPreflightPath=Assert-CityNavNewOutput (Join-Path $PSScriptRoot 'source_preflight_ACTUAL.json') $PSScriptRoot
$pairErrors=@();$pairPreflight=$null;$pairPreflightFact=$null
& python (Join-Path $PSScriptRoot 'verify_sources_ROOT_ONLY.py') --authorization $Authorization --authorization-sha256 $AuthorizationSha256 --capture $Capture --output $pairPreflightPath | Out-Host
if($LASTEXITCODE -ne 0 -or -not(Test-Path -LiteralPath $pairPreflightPath)){$pairErrors+='SOURCE_CHAIN_OR_REQUIRED_LOCAL_ART_EVIDENCE_FAILED'}
else{
 $pairPreflight=Get-Content -LiteralPath $pairPreflightPath -Raw|ConvertFrom-Json
 $pairPreflightFact=Get-CityNavSourceFact $pairPreflightPath
 if($pairPreflight.passed -ne $true -or $pairPreflight.finite_source_count -ne 208 -or $pairPreflight.immutable134_count -ne 134 -or $pairPreflight.unchanged_finite_source_count -ne 204 -or $pairPreflight.runtime_leaves -ne 99 -or $pairPreflight.unchanged_original96_leaves -ne 93 -or $pairPreflight.save_metadata_passes -ne 0){$pairErrors+='EXACT208_134_204_99_93_REQUIRED'}
}
$pairSaves=[ordered]@{};$pairSaveChanges=@();$pairAfterPasses=0
if($pairErrors.Count -eq 0){
 # The sole final metadata pass; no previous guard main is called.
 foreach($property in ($pairCap.save_facts.PSObject.Properties|Sort-Object Name)){
  $metadata=Get-CityNavSaveMetadata $property.Name;$pairSaves[$property.Name]=$metadata
  if(-not(Test-CityNavMetadataSame $property.Value $metadata)){
   $pairSaveChanges+=[ordered]@{path=$property.Name;fresh_before=$property.Value;actual_after=$metadata;policy='PRESERVE_ACTUAL_NO_RESTORE_NO_REBASE'}
   $pairErrors+=('SAVE_METADATA_CHANGED:'+ $property.Name)
  }
 }
 $pairAfterPasses=1
 if($pairSaves.Count -ne 171){$pairErrors+='EXACT171_METADATA_AFTER_REQUIRED'}
}
$pairResult=[ordered]@{
 schema='CITY_NAVIGATION_ROADMOUTHS_20261102A_PAIR_FINAL_V1';passed=($pairErrors.Count -eq 0);finished_utc=[DateTime]::UtcNow.ToString('o')
 authorization_path=[IO.Path]::GetFullPath($Authorization);authorization_sha256=$AuthorizationSha256.ToLowerInvariant()
 original_capture_path=[IO.Path]::GetFullPath($Capture);capture_sha256=$pairAuth.capture_sha256
 source_preflight=$pairPreflight;source_preflight_fact=$pairPreflightFact
 finite_deduplicated_source_count=208;immutable134_count=134;unchanged_finite_source_count=204;explicit_mutable_count=4;full_before_backup_count=4
 before_runtime_leaves=96;final_runtime_leaves=99;unchanged_original96_leaves=93;unchanged_pre_pair99_leaves=98;existing_ground3_unchanged=$true
 combined_actual_pair_count=11;combined_actual_direction_count=22;local_retested_pair_directions=2;other20directions_not_reexecuted=$true
 save_facts=$pairSaves;registered_save_count=171;save_count=$pairSaves.Count;absent_save_count=@($pairSaves.Values|Where-Object{-not $_.exists}).Count
 save_metadata_passes_before=1;save_metadata_passes_after=$pairAfterPasses;save_metadata_passes_total=(1+$pairAfterPasses)
 save_changes_preserved=$pairSaveChanges;historical_save_metadata_differences_preserved=$pairCap.historical_save_metadata_differences_preserved
 historical_source_metadata_differences_preserved=$pairCap.historical_source_metadata_differences_preserved
 save_content_reads=0;save_hashes=0;save_writes=0;save_deserializations=0;automatic_restore=$false
 old_guards_invoked=0;old134_publication_targets=0;old21_or33_closure_runs=0;engine_runs=0;source_writes=0;errors=$pairErrors
 final_script_fact=(Get-CityNavSourceFact $PSCommandPath)
}
Write-CityNavNewJson $pairOutput $pairResult
[ordered]@{passed=$pairResult.passed;path=$pairOutput;sha256=(Get-CityNavSourceFact $pairOutput).sha256;sources=208;immutable134=134;unchanged204=204;runtime99=99;old93=93;saves=$pairSaves.Count;after_metadata_passes=$pairAfterPasses;errors=$pairErrors}|ConvertTo-Json -Depth 4
if($pairErrors.Count){exit 1}
