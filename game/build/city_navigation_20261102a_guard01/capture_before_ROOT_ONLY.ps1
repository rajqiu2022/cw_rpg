param(
 [Parameter(Mandatory=$true)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$PriorGuardSha256,
 [string]$PriorGuard=(Join-Path $PSScriptRoot '../city_navigation_20261101d_supplement03/final_guard_ACTUAL.json'),
 [string]$Output=(Join-Path $PSScriptRoot 'capture_before_ACTUAL.json')
)
$ErrorActionPreference='Stop'
$roadGame=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$roadExpectedPrior='158d1d015c3f6a3830eab97cbe36c50c71cb38d6186da31c34f17f267e98258b'
if($PriorGuardSha256.ToLowerInvariant() -cne $roadExpectedPrior -or (Get-FileHash -LiteralPath $PriorGuard -Algorithm SHA256).Hash.ToLowerInvariant() -cne $roadExpectedPrior){throw 'ROOT_EXPLICIT_ACCEPTED11D_FINAL158D_REQUIRED'}
$roadPrior=Get-Content -LiteralPath $PriorGuard -Raw|ConvertFrom-Json
if($roadPrior.passed -ne $true -or $roadPrior.source_count -ne 134 -or $roadPrior.save_count -ne 171 -or @($roadPrior.save_facts.PSObject.Properties).Count -ne 171){throw 'ACCEPTED134_AND_REGISTERED171_PATH_SET_REQUIRED'}
$roadOriginalFacts=$roadPrior.inherited_original_final.facts
$roadSupplementFacts=$roadPrior.source_preflight.source_after_facts
if(@($roadOriginalFacts.PSObject.Properties).Count -ne 113 -or @($roadSupplementFacts.PSObject.Properties).Count -ne 21){throw 'EXACT113_PLUS_DISTINCT21_CURRENT_SOURCE_FACTS_REQUIRED'}
$roadPrior134=[ordered]@{}
foreach($property in @($roadOriginalFacts.PSObject.Properties)+@($roadSupplementFacts.PSObject.Properties)){
 if($roadPrior134.Contains($property.Name)){throw '134_FACT_SET_MUST_NOT_DOUBLE_COUNT_STAGED_SUBSETS'}
 $roadPrior134[$property.Name]=$property.Value
}
$roadHelperPath=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../city_navigation_20261101d_guard01/guard_helpers_ROOT_ONLY.ps1'))
$roadHelperKey='res://build/city_navigation_20261101d_guard01/guard_helpers_ROOT_ONLY.ps1'
if((Get-FileHash -LiteralPath $roadHelperPath -Algorithm SHA256).Hash.ToLowerInvariant() -cne $roadPrior134[$roadHelperKey].sha256){throw 'UNCHANGED_ESTABLISHED_GUARD_HELPER_REQUIRED'}
. $roadHelperPath
$roadOutput=Assert-CityNavNewOutput $Output $PSScriptRoot
$roadManifestKey='res://build/city_navigation_20261101d_candidate01/source_pins_READY.json'
$roadManifestPath=Resolve-CityNavSource $roadManifestKey $roadGame
if((Get-FileHash -LiteralPath $roadManifestPath -Algorithm SHA256).Hash.ToLowerInvariant() -cne '760534d8b33534c083d8e5537bb8e4287daf66409f7fddc5fb081090b22f1fa2'){throw 'CURRENT760534_MANIFEST_BEFORE_REQUIRED'}
$roadManifest=Get-Content -LiteralPath $roadManifestPath -Raw|ConvertFrom-Json
if($roadManifest.ready -ne $true -or @($roadManifest.source_pins.PSObject.Properties).Count -ne 96){throw 'CURRENT_ROOT_FROZEN96_REQUIRED'}
$roadMutable=[ordered]@{
 $roadManifestKey='760534d8b33534c083d8e5537bb8e4287daf66409f7fddc5fb081090b22f1fa2'
 'res://build/city_navigation_20261101d_candidate01/mouth_visual.gd'='985a3d3d1bdfd1c047637a3e68921fbdf9b36ec82b7f204577337244ecf96323'
 'res://build/city_navigation_20261101d_candidate01/mouth_shoulder.gdshader'='0b46ee80cb134347e00f2116dd3d4bf0b5617e6358b7fe07c4d71e2b35fa9ecd'
}
$roadGround=[ordered]@{
 'res://art/modules/miao_town_20261029f/ground.png'='7dac9c249212fde5cbda1d005b0915a2e6ca3f86e2b465667edc088e1334ed7e'
 'res://art/modules/miao_town_20261029f/ground.png.import'='699fca6d0fae3327060ea7cc59111fea6e5133b83eba4edce9739ef40b2c1061'
 'res://.godot/imported/ground.png-f9185ad954bdaa371273ad0152373913.ctex'='c52a4325c66e7ce2723b82940a0a9d27f7c8a1edd1e309463742f498a2f9739f'
}
$roadPaths=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach($key in $roadPrior134.Keys){[void]$roadPaths.Add($key)}
foreach($property in $roadManifest.source_pins.PSObject.Properties){[void]$roadPaths.Add($property.Name)}
foreach($key in $roadMutable.Keys){if($roadPrior134.Contains($key)){throw 'EXPECTED_NO134_CANONICAL_MUTABLE_TARGET_OVERLAP'};[void]$roadPaths.Add($key)}
foreach($key in $roadGround.Keys){[void]$roadPaths.Add($key)}
$roadFacts=[ordered]@{}
foreach($key in ($roadPaths|Sort-Object)){
 $fact=Get-CityNavSourceFact (Resolve-CityNavSource $key $roadGame)
 if($fact.stable -ne $true){throw ('SOURCE_UNSTABLE_DURING_FINITE_CAPTURE:'+ $key)}
 $roadFacts[$key]=$fact
}
$roadHistoricalSourceMetadata=@()
foreach($key in $roadPrior134.Keys){
 $fresh=$roadFacts[$key];$old=$roadPrior134[$key]
 if($fresh.sha256 -cne $old.sha256 -or $fresh.bytes -ne $old.bytes){throw ('PREEXISTING134_CONTENT_DIFFERENCE_NEEDS_ROOT_REVIEW_NO_REBASE:'+ $key)}
 if($fresh.utc_ticks -cne $old.utc_ticks){$roadHistoricalSourceMetadata+=[ordered]@{path=$key;prior=$old;fresh_before=$fresh;policy='BEFORE_BATCH_METADATA_DIFFERENCE_KEEP_CURRENT_NO_RESTORE'}}
}
foreach($property in $roadManifest.source_pins.PSObject.Properties){if($roadFacts[$property.Name].sha256 -cne $property.Value){throw ('CURRENT96_LEAF_BEFORE_MISMATCH:'+ $property.Name)}}
foreach($key in $roadMutable.Keys){if($roadFacts[$key].sha256 -cne $roadMutable[$key]){throw ('EXACT_THREE_MUTABLE_BEFORES_REQUIRED:'+ $key)}}
foreach($key in $roadGround.Keys){if($roadFacts[$key].sha256 -cne $roadGround[$key]){throw ('EXACT_APPROVED_EXISTING_GROUND_MEDIA_REQUIRED:'+ $key)}}
$roadBackups=[ordered]@{}
foreach($key in $roadMutable.Keys){
 $name=if($key -ceq $roadManifestKey){'manifest96_before_EXACT.json'}elseif($key.EndsWith('/mouth_visual.gd')){'mouth_visual_before_EXACT.gd.source'}else{'mouth_shoulder_before_EXACT.gdshader.source'}
 $backup=Assert-CityNavNewOutput (Join-Path $PSScriptRoot $name) $PSScriptRoot
 $source=Resolve-CityNavSource $key $roadGame
 $reader=[IO.File]::OpenRead($source);$writer=[IO.File]::Open($backup,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$reader.CopyTo($writer)}finally{$reader.Dispose();$writer.Dispose()}
 [IO.File]::SetLastWriteTimeUtc($backup,[DateTime]::new([long]$roadFacts[$key].utc_ticks,[DateTimeKind]::Utc))
 $backupFact=Get-CityNavSourceFact $backup
 if(-not(Test-CityNavSourceSame $roadFacts[$key] $backupFact) -or -not(Test-CityNavSourceSame $roadFacts[$key] (Get-CityNavSourceFact $source))){throw ('EXACT_THREE_FULL_BACKUPS_REQUIRED:'+ $key)}
 $roadBackups[$key]=[ordered]@{path=$backup;fact=$backupFact}
}
# Exactly one filesystem metadata lookup per registered savepath. No source
# hashing function is ever called on userdata; no content read/deserialization.
$roadSaves=[ordered]@{};$roadSaveHistory=@()
foreach($property in ($roadPrior.save_facts.PSObject.Properties|Sort-Object Name)){
 $value=Get-CityNavSaveMetadata $property.Name
 $roadSaves[$property.Name]=$value
 if(-not(Test-CityNavMetadataSame $property.Value $value)){$roadSaveHistory+=[ordered]@{path=$property.Name;historical_metadata=$property.Value;fresh_before_metadata=$value;policy='USER_EXTERNAL_BEFORE_BATCH_KEEP_FRESH_CURRENT_NO_RESTORE'}}
}
if($roadSaves.Count -ne 171){throw 'EXACT_REGISTERED171_METADATA_PATH_SET_REQUIRED'}
$roadGroundFacts=[ordered]@{};foreach($key in $roadGround.Keys){$roadGroundFacts[$key]=$roadFacts[$key]}
$roadResult=[ordered]@{
 schema='CITY_NAVIGATION_ROADMOUTHS_20261102A_FINITE_CAPTURE_V1';captured_successfully=$true;captured_utc=[DateTime]::UtcNow.ToString('o')
 prior_guard_path=[IO.Path]::GetFullPath($PriorGuard);prior_guard_sha256=$roadExpectedPrior;prior_guard_fact=(Get-CityNavSourceFact $PriorGuard)
 immutable134_paths=@($roadPrior134.Keys);immutable134_count=134;before_source_facts=$roadFacts;finite_deduplicated_source_count=$roadFacts.Count
 current_manifest_path=$roadManifestKey;manifest_before_sha256=$roadMutable[$roadManifestKey];manifest_before_source_pins=$roadManifest.source_pins;manifest_before_leaf_count=96
 allowed_prospective_mutable_paths=@($roadMutable.Keys);full_backups=$roadBackups;full_backup_count=3
 approved_existing_ground_source_sha256=$roadGround;existing_ground_source_facts=$roadGroundFacts;existing_ground_leaf_count=3
 immutable_old_leaf_count_if_both_helpers_change=94;candidate_manifest_after_leaf_count_if_only_ground3_added=99
 save_facts=$roadSaves;save_count=171;absent_save_count=@($roadSaves.Values|Where-Object{-not $_.exists}).Count;save_metadata_passes=1
 historical_save_metadata_differences_preserved=$roadSaveHistory;historical_source_metadata_differences_preserved=$roadHistoricalSourceMetadata
 established_guard_helper_path=$roadHelperPath;established_guard_helper_fact=(Get-CityNavSourceFact $roadHelperPath);capture_script_fact=(Get-CityNavSourceFact $PSCommandPath)
 save_content_reads=0;save_hashes=0;save_writes=0;save_deserializations=0;automatic_restore=$false;engine_runs=0;process_control=0;old_source_writes=0;old_guards_invoked=0
 authorization='BEFORE_CAPTURE_ONLY; Root separately approves exact2helperafters/99manifest after normal-camera sample. No Router/Region/NAV/action/arrival/source-closure writes.'
}
Write-CityNavNewJson $roadOutput $roadResult
[ordered]@{path=$roadOutput;sha256=(Get-CityNavSourceFact $roadOutput).sha256;immutable_old_sources=134;before_runtime_leaves=96;finite_deduplicated_sources=$roadFacts.Count;full_backups=3;ground_leaves=3;saves=171;absent=$roadResult.absent_save_count;save_metadata_passes=1;old_source_writes=0}|ConvertTo-Json -Depth 3
