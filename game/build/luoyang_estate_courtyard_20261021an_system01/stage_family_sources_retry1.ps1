param([Parameter(Mandatory=$true)][string]$AdmissionPath,[Parameter(Mandatory=$true)][string]$AdmissionSHA,[string]$Workspace='F:\Code\RPG_GAME')
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
# ROOT mechanical staging only: no canonical writes, engine, import or deployment.
$game=Join-Path $Workspace 'game'
$pkg='res://build/luoyang_estate_courtyard_20261021an_system01/'
$out=Join-Path $game ($pkg.Substring(6)+'staged_retry1')
function Disk([string]$p){if(!$p.StartsWith('res://') -or $p.Contains('..')){throw 'RESOURCE_PATH'};Join-Path $game $p.Substring(6)}
function SHA([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function Check([string]$p,[string]$h){if($h -cnotmatch '^[0-9a-f]{64}$' -or (SHA (Disk $p)) -cne $h){throw "SOURCE_CHANGED:$p"}}
function J([string]$p){Get-Content -Raw -LiteralPath (Disk $p)|ConvertFrom-Json -AsHashtable}
function Clone($v){$v|ConvertTo-Json -Depth 100 -Compress|ConvertFrom-Json -AsHashtable}
function Canon($v){if($v -is [Collections.IDictionary]){$r=[ordered]@{};foreach($k in @($v.Keys|Sort-Object -CaseSensitive)){$r[$k]=Canon $v[$k]};return $r};if($v -is [array]){return ,@($v|ForEach-Object{Canon $_})};return $v}
function Same($a,$b){((Canon $a)|ConvertTo-Json -Depth 100 -Compress) -ceq ((Canon $b)|ConvertTo-Json -Depth 100 -Compress)}
function W([string]$name,[string]$text){$p=Join-Path $out $name;[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($p))|Out-Null;[IO.File]::WriteAllText($p,$text,[Text.UTF8Encoding]::new($false));return $p}
function WJ([string]$name,$v){W $name (($v|ConvertTo-Json -Depth 100)+"`n")}
function LF([string]$s){$s.Replace("`r`n","`n").TrimEnd("`r","`n")+"`n"}
function Put($m,[string]$p,[string]$h){if($m.Contains($p) -and $m[$p] -cne $h){throw "SOURCE_COLLISION:$p"};$m[$p]=$h}
if(Test-Path -LiteralPath $out){throw 'NEW_STAGE_ONLY_PRESERVE_OLD_OUTCOME'}
Check $AdmissionPath $AdmissionSHA
$a=J $AdmissionPath
if($a.status -cne 'ROOT_APPROVED_AN_COMPLETE_SOURCE_STAGING' -or $a.code_rows.Count -ne 5 -or $a.baselines.Count -ne 4){throw 'ROOT_APPROVED_COMPLETE_INPUT_REQUIRED'}
Check $a.publication.path $a.publication.sha256
$pub=J $a.publication.path
if(!$pub.passed -or !(Same $pub.source_first $pub.source_final) -or !$pub.runtime_native.ok -or !$pub.mansion_return.ok -or !$pub.mansion_return.all_twelve_whole_inverse){throw 'NATIVE_AND_ONE_ROOM_ACTUAL_PUBLICATION_REQUIRED'}
Check $a.geometry.path $a.geometry.sha256
$geometry=J $a.geometry.path
if(!$geometry.passed -or !(Same $geometry.source_first $geometry.source_final)){throw 'FINAL_ART_GEOMETRY_REQUIRED'}
$targets=[Collections.Generic.List[object]]::new();$owned=[ordered]@{};$inputs=[ordered]@{};$patchTargets=[Collections.Generic.List[object]]::new()
function StageTarget([string]$target,[string]$old,[string]$file){if($old -ceq 'ABSENT'){if(Test-Path -LiteralPath (Disk $target)){throw "TARGET_MUST_BE_ABSENT:$target"}}else{Check $target $old};$r=@{target=$target;old_sha256=$old;candidate_path='res://'+$file.Substring($game.Length+1).Replace('\','/');candidate_sha256=SHA $file};$targets.Add($r);return $r}
foreach($row in $a.code_rows){
 Check $row.target $row.old_sha256;Check $row.candidate $row.candidate_sha256
 if($row.target -notin @('res://scripts/city/luoyang_precomputed_bundle_20261018r.gd','res://scripts/city/luoyang_assembled_interiors_20261016g.gd','res://scripts/city/luoyang_layout_room_index_20261018t.gd','res://scripts/autoload/scene_router.gd','res://scripts/city/luoyang_estate_family_20261021am.gd')){throw 'EXACT_FIVE_EXECUTABLE_TARGETS'}
 if($owned.Contains($row.target)){throw 'DUPLICATE_CODE_TARGET'}
 $text=LF ([IO.File]::ReadAllText((Disk $row.candidate)));$file=W ('code/'+[IO.Path]::GetFileName($row.target)) $text
 $r=StageTarget $row.target $row.old_sha256 $file;$owned[$row.target]=@{old=$row.old_sha256;next=$r.candidate_sha256};$patchTargets.Add($r)
 $inputs[$row.candidate]=$row.candidate_sha256
}
$router='res://scripts/autoload/scene_router.gd';$coor='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';$contract='res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
$oldContract='da49fe454e9ab975485e75e96772834f2a8c312463cf96bff8aceb6c0d050c1f';$oldCoor='fc9339579a0091936cf1bb747e84667e017d0eb57ffd025918023601afc51da9'
Check $contract $oldContract;Check $coor $oldCoor
$oldText=[IO.File]::ReadAllText((Disk $contract));if([regex]::Matches($oldText,$owned[$router].old).Count -ne 1){throw 'CONTRACT_ROUTER_ONE_LITERAL'}
$newText=$oldText.Replace($owned[$router].old,$owned[$router].next)
if($newText.Replace($owned[$router].next,$owned[$router].old) -cne $oldText){throw 'CONTRACT_WHOLE_TEXT_INVERSE'}
$contractFile=W 'runtime_contract.json' $newText;$r=StageTarget $contract $oldContract $contractFile;$owned[$contract]=@{old=$oldContract;next=$r.candidate_sha256}
$oldText=[IO.File]::ReadAllText((Disk $coor));if([regex]::Matches($oldText,$oldContract).Count -ne 1){throw 'COORDINATOR_ONE_CONTRACT_CONSTANT'}
$coorFile=W 'code/luoyang_cultural_sidequests_coordinator_20261019x.gd' (LF ($oldText.Replace($oldContract,$owned[$contract].next)))
$r=StageTarget $coor $oldCoor $coorFile;$owned[$coor]=@{old=$oldCoor;next=$r.candidate_sha256};$patchTargets.Add($r)
$temple='res://scripts/city/luoyang_temple_assembly_20261016.gd';$oldTemple='29d1a997ae1e456e0099d4e5fa6d6311b644136df09d9e091ea3a08897e12189'
$oldBinding='res://build/luoyang_docks_roles_20261019ad_system01/staged/temple_binding.json';$oldBindingSHA='2f38f051569f10b7dd85347f988ae0fea860d7539abdc933a1a194aa7adcb3f9'
Check $temple $oldTemple;Check $oldBinding $oldBindingSHA
$binding=J $oldBinding;$oldBindingData=Clone $binding
foreach($p in @($router,$coor,$contract)){if($binding.source_delta[$p] -cne $owned[$p].old){throw "TEMPLE_OLD_SOURCE:$p"};$binding.source_delta[$p]=$owned[$p].next}
$binding.source_delta[$oldBinding]=$oldBindingSHA
$binding['an_source_successor']=@{prior_path=$oldBinding;prior_sha256=$oldBindingSHA;changed_owned_sources=@($router,$coor,$contract);geometry_artifact_proof_unchanged=$true}
$back=Clone $binding;$back.Remove('an_source_successor');$back.source_delta.Remove($oldBinding);foreach($p in @($router,$coor,$contract)){$back.source_delta[$p]=$owned[$p].old};if(!(Same $back $oldBindingData)){throw 'TEMPLE_BINDING_WHOLE_INVERSE'}
$bindingFile=WJ 'temple_binding.json' $binding;$bindingPath=$pkg+'staged_retry1/temple_binding.json';$bindingSHA=SHA $bindingFile
$oldText=[IO.File]::ReadAllText((Disk $temple));$templeText=$oldText.Replace('const BIND_PATH="'+$oldBinding+'"','const BIND_PATH="'+$bindingPath+'"').Replace('const BIND_SHA="'+$oldBindingSHA+'"','const BIND_SHA="'+$bindingSHA+'"')
if($templeText -ceq $oldText -or $templeText.Replace($bindingPath,$oldBinding).Replace($bindingSHA,$oldBindingSHA) -cne $oldText){throw 'TEMPLE_HELPER_ONLY_TWO_CONSTANTS'}
$templeFile=W 'code/luoyang_temple_assembly_20261016.gd' (LF $templeText);$r=StageTarget $temple $oldTemple $templeFile;$owned[$temple]=@{old=$oldTemple;next=$r.candidate_sha256};$patchTargets.Add($r)
$known=[ordered]@{}
foreach($map in @($geometry.source_first,$geometry.artifacts,$pub.source_first,$pub.runtime_native.artifacts,$pub.mansion_return.artifacts)){
 foreach($p in $map.Keys){Put $known $p $map[$p]}
}
foreach($p in $owned.Keys){$known[$p]=$owned[$p].next}
$known[$bindingPath]=$bindingSHA
$estateAudio=[ordered]@{
 'res://art/audio/bgm/bgm_market_lively_v4.wav'='bcfa377279fd29e954e9f70a0d5ed300619d27601b281e097f5f58e8839e701b'
 'res://art/audio/bgm/bgm_market_lively_v4.wav.import'='b63c6a9e52a115a226669f75a64a50d13d181e4588579a797bbbdb808347f08f'
 'res://.godot/imported/bgm_market_lively_v4.wav-3aff0963ce687ac915fd5adbe024616a.sample'='ec97b7d03bdd613edf0a8dd68f2912842ae5afd6dde67cea045203f127d0b48f'
}
if(!(Same $a.estate_runtime_sources $estateAudio)){throw 'EXACT_EXISTING_ESTATE_SCENE_AUDIO_TRIPLE'}
foreach($p in $estateAudio.Keys){Check $p $estateAudio[$p];Put $known $p $estateAudio[$p]}
$runtime=[ordered]@{}
function AddRuntime([string]$p){
 if($runtime.Contains($p)){return};if(!$known.Contains($p)){throw "DEPENDENCY_NOT_IN_INDEPENDENT_PUBLICATION_OR_CODE_FACTS:$p"};$h=$known[$p]
 if(!$owned.Contains($p) -and $p -cne $bindingPath){Check $p $h};Put $runtime $p $h
 if(Test-Path -LiteralPath (Disk ($p+'.import'))){
  $side=$p+'.import';if(!$known.Contains($side)){throw "IMPORT_LEAF_NOT_DECLARED:$side"};AddRuntime $side
  $raw=[IO.File]::ReadAllText((Disk $side))
  $audioRemaps=@{
   'res://art/audio/bgm/wuxia_20261011/city_bianzhou.wav'='res://.godot/imported/city_bianzhou.wav-2afcd34530dbcaa469513a2eb7785eae.sample'
   'res://art/audio/bgm/bgm_market_lively_v4.wav'='res://.godot/imported/bgm_market_lively_v4.wav-3aff0963ce687ac915fd5adbe024616a.sample'
  }
  if($audioRemaps.ContainsKey($p)){
   if($raw -cnotmatch '(?m)^importer="wav"\r?$' -or $raw -cnotmatch '(?m)^type="AudioStreamWAV"\r?$'){throw "EXACT_EXISTING_WAV_IMPORT_TYPE:$p"}
   $m=[regex]::Match($raw,'(?m)^path="(res://[^"\r\n]+\.sample)"\r?$')
   if(!$m.Success -or $m.Groups[1].Value -cne $audioRemaps[$p]){throw "EXACT_EXISTING_WAV_REMAP:$p"}
  }else{
   $m=[regex]::Match($raw,'(?m)^path="(res://[^"\r\n]+\.ctex)"')
   if(!$m.Success){throw "EXACT_TEXTURE_IMPORT_REMAP:$p"}
  }
  AddRuntime $m.Groups[1].Value
 }
 if($p.EndsWith('.tres')){foreach($m in [regex]::Matches([IO.File]::ReadAllText((Disk $p)),'\[ext_resource[^\r\n]*path="(res://[^"\r\n]+)"')){AddRuntime $m.Groups[1].Value}}
}
foreach($p in $pub.runtime_native.runtime_texture_paths){AddRuntime $p};AddRuntime $pub.runtime_native.runtime_walk_path
foreach($p in $pub.runtime_native.artifacts.Keys){AddRuntime $p};foreach($p in $pub.mansion_return.artifacts.Keys){AddRuntime $p}
if($pub.mansion_return.current_source_sha256 -isnot [Collections.IDictionary]){throw 'ONE_ROOM_CURRENT_CONSUMED_SOURCE_MAP_REQUIRED'}
foreach($p in $pub.mansion_return.current_source_sha256.Keys){if(!$known.Contains($p) -or $known[$p] -cne $pub.mansion_return.current_source_sha256[$p]){throw "ROOM_CURRENT_SOURCE_NOT_IN_INDEPENDENT_PUBLICATION:$p"};AddRuntime $p}
foreach($p in $owned.Keys){AddRuntime $p};AddRuntime $bindingPath
foreach($p in $a.runtime_program_sources){AddRuntime $p}
AddRuntime 'res://art/audio/bgm/bgm_market_lively_v4.wav'
Put $runtime $a.geometry.path $a.geometry.sha256
Put $runtime $a.publication.path $a.publication.sha256
foreach($p in $a.provenance_sources.Keys){Check $p $a.provenance_sources[$p];Put $runtime $p $a.provenance_sources[$p]}
$familyIndex='res://scripts/city/luoyang_estate_index_20261021am.gd';$familyRoot='res://data/maps/luoyang_estate_courtyard_20261021am/';$familyManifest=$familyRoot+'manifest.json'
if($runtime.Contains($familyIndex) -or $runtime.Contains($familyManifest)){throw 'FAMILY_SELF_CYCLE'}
$family=@{schema_version=1;status='ROOT_ADMITTED_AM_ESTATE_FAMILY';scene_id='luoyang_estate_riverside_20261021ai';mansion_id='luoyang_functional_mansion_candidate_20261016';market_foot_px=$a.market_foot_px;registry_path=$pub.mansion_return.registry_path;registry_sha256=$pub.mansion_return.registry_sha256;source_sha256=$runtime;geometry_receipt=$a.geometry;publication_receipt=$a.publication;runtime_source_successions=$owned;runtime_audio_bindings=@{inherited_mansion_wav='res://art/audio/bgm/wuxia_20261011/city_bianzhou.wav';estate_wav='res://art/audio/bgm/bgm_market_lively_v4.wav';type='AudioStreamWAV';new_png_import_rules_unchanged=$true};historical_publication_sources_not_claimed_current=$pub.source_first;geometry_reused=$true}
$familyFile=WJ 'estate_manifest.json' $family;$familySHA=SHA $familyFile;$null=StageTarget $familyManifest 'ABSENT' $familyFile
Check $familyIndex 'c305bb4faf12d2aa88a2c3fc8bb3c79fda1471fcb27876ed3874d45469872732'
$indexOld=[IO.File]::ReadAllText((Disk $familyIndex));if([regex]::Matches($indexOld,'const MANIFEST_SHA="PENDING"').Count -ne 1 -or !$indexOld.Contains('const FORMAL_ENABLED=false')){throw 'FAMILY_FALSE_INDEX_PARENT'}
$indexFalseFile=W 'code/luoyang_estate_index_20261021am.gd' (LF ($indexOld.Replace('const MANIFEST_SHA="PENDING"','const MANIFEST_SHA="'+$familySHA+'"')))
$r=StageTarget $familyIndex 'c305bb4faf12d2aa88a2c3fc8bb3c79fda1471fcb27876ed3874d45469872732' $indexFalseFile;$patchTargets.Add($r)
$indexTrueFile=W 'estate_index_true.gd' ([IO.File]::ReadAllText($indexFalseFile).Replace('const FORMAL_ENABLED=false','const FORMAL_ENABLED=true'))
$falseSHA=SHA $indexFalseFile;$trueSHA=SHA $indexTrueFile
if([IO.File]::ReadAllText($indexTrueFile).Replace('const FORMAL_ENABLED=true','const FORMAL_ENABLED=false') -cne [IO.File]::ReadAllText($indexFalseFile)){throw 'SOLE_BOOL_INDEX_INVERSE'}
$shared=[ordered]@{};$shared['res://scripts/city/luoyang_estate_family_20261021am.gd']=$owned['res://scripts/city/luoyang_estate_family_20261021am.gd'].next;$shared[$familyManifest]=$familySHA
$familyCompileLeaf='res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/estate_candidate.gd'
if(!$runtime.Contains($familyCompileLeaf)){throw 'FAMILY_PRELOADED_EXECUTABLE_LEAF_REQUIRED'}
Put $shared $familyCompileLeaf $runtime[$familyCompileLeaf]
foreach($p in $pub.mansion_return.artifacts.Keys){Put $shared $p $pub.mansion_return.artifacts[$p]}
foreach($p in $pub.mansion_return.current_source_sha256.Keys){Put $shared $p $pub.mansion_return.current_source_sha256[$p]}
$manifestChanges=[ordered]@{};$manifestResults=[ordered]@{}
foreach($row in $a.city_manifests){
 Check $row.path $row.sha256;$m=J $row.path;$old=Clone $m;$delta=[Collections.Generic.List[object]]::new()
 foreach($p in $owned.Keys){foreach($kind in @('legacy_source_sha256','runtime_authority_sha256')){if($m[$kind].Contains($p)){if($m[$kind][$p] -cne $owned[$p].old){throw "MANIFEST_OLD_OWNED:$p"};$delta.Add(@{kind=$kind;path=$p;old=$m[$kind][$p];next=$owned[$p].next});$m[$kind][$p]=$owned[$p].next}}}
 $add=Clone $shared;if($m.scene_id -ceq 'ch4_s3_luoyang_market'){foreach($p in $runtime.Keys){Put $add $p $runtime[$p]}}
 if($m.legacy_source_sha256.Contains($temple) -or $m.legacy_source_sha256.Contains($oldBinding)){Put $add $bindingPath $bindingSHA}
 foreach($p in $add.Keys){if($p -ceq $familyIndex){throw 'INDEX_IN_MANIFEST'};if($m.artifacts.Contains($p)){if($m.artifacts[$p] -cne $add[$p]){throw 'ARTIFACT_HASH_COLLISION'};continue};$kind='legacy_source_sha256';if($m.runtime_authority_sha256.Contains($p)){$kind='runtime_authority_sha256'};$exists=$m[$kind].Contains($p);if($exists -and $m[$kind][$p] -cne $add[$p]){if(!$owned.Contains($p)){throw "EXISTING_DEPENDENCY_CHANGED:$p"};continue};if(!$exists){$delta.Add(@{kind=$kind;path=$p;old='ABSENT';next=$add[$p]});$m[$kind][$p]=$add[$p]}}
 $back=Clone $m;for($i=$delta.Count-1;$i -ge 0;$i--){$d=$delta[$i];if($d.old -ceq 'ABSENT'){$back[$d.kind].Remove($d.path)}else{$back[$d.kind][$d.path]=$d.old}};if(!(Same $back $old) -or !(Same $m.artifacts $old.artifacts) -or !(Same $m.layout_proof $old.layout_proof)){throw 'MANIFEST_WHOLE_INVERSE_AND_OLD_PROOF'}
 $file=WJ ('manifests/'+$row.key+'.json') $m;$r=StageTarget $row.path $row.sha256 $file;$manifestResults[$row.path]=$r.candidate_sha256;$manifestChanges[$row.path]=$delta
}
if($a.city_manifests.Count -ne 6){throw 'EXACT_SIX_CITY_MANIFESTS'}
$indexUpdates=[ordered]@{}
foreach($row in $a.city_indices){Check $row.path $row.sha256;$old=[IO.File]::ReadAllText((Disk $row.path));$next=$old
 foreach($m in $a.city_manifests){if($next.Contains($m.sha256)){$next=$next.Replace($m.sha256,$manifestResults[$m.path])}}
 if($next -ceq $old){throw 'INDEX_DID_NOT_INHERIT_OWNED_MANIFEST'}
 $file=W ('code/'+[IO.Path]::GetFileName($row.path)) (LF $next);$r=StageTarget $row.path $row.sha256 $file;$indexUpdates[$row.path]=@{old=$row.sha256;next=$r.candidate_sha256};$patchTargets.Add($r)
}
if($a.city_indices.Count -ne 3){throw 'EXACT_BI_AA_AC_INDICES'}
$maps=[ordered]@{}
foreach($base in $a.baselines){Check $base.path $base.sha256;$old=(J $base.path).source_sha256;$next=Clone $old
 foreach($p in $owned.Keys){if($next.Contains($p)){if($next[$p] -cne $owned[$p].old){throw 'MAP_OLD_OWNED'};$next[$p]=$owned[$p].next}}
 foreach($p in $manifestResults.Keys){if($next.Contains($p)){$next[$p]=$manifestResults[$p]}}
 foreach($p in $indexUpdates.Keys){if($next.Contains($p)){if($next[$p] -cne $indexUpdates[$p].old){throw 'MAP_OLD_INDEX'};$next[$p]=$indexUpdates[$p].next}}
 foreach($p in $shared.Keys){$next[$p]=$shared[$p]}
 if($base.scene_id -ceq 'ch4_s3_luoyang_market'){foreach($p in $runtime.Keys){$next[$p]=$runtime[$p]}}
 if($old.Contains($temple) -or $old.Contains($oldBinding)){$next[$bindingPath]=$bindingSHA}
 $next[$familyIndex]=$falseSHA;$formalMap=Clone $next;$formalMap[$familyIndex]=$trueSHA
 $allowed=[ordered]@{};foreach($set in @($owned,$manifestResults,$indexUpdates,$shared)){foreach($p in $set.Keys){$allowed[$p]=$true}};$allowed[$familyIndex]=$true
 if($base.scene_id -ceq 'ch4_s3_luoyang_market'){foreach($p in $runtime.Keys){$allowed[$p]=$true}}
 if($old.Contains($temple) -or $old.Contains($oldBinding)){$allowed[$bindingPath]=$true}
 $back=Clone $next;foreach($p in $allowed.Keys){if($old.Contains($p)){$back[$p]=$old[$p]}else{$back.Remove($p)}};if(!(Same $back $old)){throw 'INDEPENDENT_OLD_MAP_WHOLE_INVERSE'}
 $falseMap=WJ ('maps/'+$base.scene_id+'_false.json') @{status='AN_INDEPENDENT_OLD_PLUS_FINITE_SOURCE_DELTA';baseline_path=$base.path;baseline_sha256=$base.sha256;source_sha256=$next}
 $trueMap=WJ ('maps/'+$base.scene_id+'_true.json') @{status='AN_SOLE_FAMILY_INDEX_BOOL_SOURCE_SUCCESSOR';baseline_path=$base.path;baseline_sha256=$base.sha256;source_sha256=$formalMap}
 $maps[$base.scene_id]=@{false_path='res://'+$falseMap.Substring($game.Length+1).Replace('\','/');false_sha256=SHA $falseMap;true_path='res://'+$trueMap.Substring($game.Length+1).Replace('\','/');true_sha256=SHA $trueMap;count=$next.Count;old_count=$old.Count}
}
$patch="*** Begin Patch`n"
foreach($row in $patchTargets){$diff=@(& git diff --no-index --no-color --text --unified=3 -- (Disk $row.target) (Disk $row.candidate_path) 2>$null);if($LASTEXITCODE -gt 1){throw 'READ_ONLY_DIFF_FAILED'};$patch+='*** Update File: '+(Disk $row.target).Replace('\','/')+"`n";$active=$false;foreach($line in $diff){if($line.StartsWith('@@')){$patch+="@@`n";$active=$true;continue};if($active -and !$line.StartsWith('\ No newline')){$patch+=$line+"`n"}}}
$patch+="*** End Patch`n";$patchFile=W 'canonical_code_deployment.apply_patch' $patch
$receipt=@{status='AN_STAGED_SOURCE_READY_NOT_DEPLOYED_NOT_FIELD_PASS';admission_path=$AdmissionPath;admission_sha256=$AdmissionSHA;targets=$targets;code_patch_path=$pkg+'staged_retry1/canonical_code_deployment.apply_patch';code_patch_sha256=SHA $patchFile;family_manifest_path=$familyManifest;family_manifest_sha256=$familySHA;family_index_false_sha256=$falseSHA;family_index_true_sha256=$trueSHA;true_index_candidate_path=$pkg+'staged_retry1/estate_index_true.gd';temple_binding_path=$bindingPath;temple_binding_sha256=$bindingSHA;manifest_source_deltas=$manifestChanges;all_six_manifest_whole_inverse=$true;all18_city_native_artifacts_unchanged=$true;independent_expected_maps=$maps;current_runtime_source_count=$runtime.Count;shared_header_room_source_count=$shared.Count;no_actual_collector_backfill=$true;no_engine_or_deployment=$true}
$receiptFile=WJ 'receipt.json' $receipt
Write-Output (@{receipt=$pkg+'staged_retry1/receipt.json';sha256=SHA $receiptFile;targets=$targets.Count;estate_runtime_sources=$runtime.Count;shared_small_sources=$shared.Count;maps=$maps}|ConvertTo-Json -Depth 8)

 -or $raw -cnotmatch '(?m)^type="AudioStreamWAV"\r?
 if($p.EndsWith('.tres')){foreach($m in [regex]::Matches([IO.File]::ReadAllText((Disk $p)),'\[ext_resource[^\r\n]*path="(res://[^"\r\n]+)"')){AddRuntime $m.Groups[1].Value}}
}
foreach($p in $pub.runtime_native.runtime_texture_paths){AddRuntime $p};AddRuntime $pub.runtime_native.runtime_walk_path
foreach($p in $pub.runtime_native.artifacts.Keys){AddRuntime $p};foreach($p in $pub.mansion_return.artifacts.Keys){AddRuntime $p}
if($pub.mansion_return.current_source_sha256 -isnot [Collections.IDictionary]){throw 'ONE_ROOM_CURRENT_CONSUMED_SOURCE_MAP_REQUIRED'}
foreach($p in $pub.mansion_return.current_source_sha256.Keys){if(!$known.Contains($p) -or $known[$p] -cne $pub.mansion_return.current_source_sha256[$p]){throw "ROOM_CURRENT_SOURCE_NOT_IN_INDEPENDENT_PUBLICATION:$p"};AddRuntime $p}
foreach($p in $owned.Keys){AddRuntime $p};AddRuntime $bindingPath
foreach($p in $a.runtime_program_sources){AddRuntime $p}
Put $runtime $a.geometry.path $a.geometry.sha256
Put $runtime $a.publication.path $a.publication.sha256
foreach($p in $a.provenance_sources.Keys){Check $p $a.provenance_sources[$p];Put $runtime $p $a.provenance_sources[$p]}
$familyIndex='res://scripts/city/luoyang_estate_index_20261021am.gd';$familyRoot='res://data/maps/luoyang_estate_courtyard_20261021am/';$familyManifest=$familyRoot+'manifest.json'
if($runtime.Contains($familyIndex) -or $runtime.Contains($familyManifest)){throw 'FAMILY_SELF_CYCLE'}
$family=@{schema_version=1;status='ROOT_ADMITTED_AM_ESTATE_FAMILY';scene_id='luoyang_estate_riverside_20261021ai';mansion_id='luoyang_functional_mansion_candidate_20261016';market_foot_px=$a.market_foot_px;registry_path=$pub.mansion_return.registry_path;registry_sha256=$pub.mansion_return.registry_sha256;source_sha256=$runtime;geometry_receipt=$a.geometry;publication_receipt=$a.publication;runtime_source_successions=$owned;historical_publication_sources_not_claimed_current=$pub.source_first;geometry_reused=$true}
$familyFile=WJ 'estate_manifest.json' $family;$familySHA=SHA $familyFile;$null=StageTarget $familyManifest 'ABSENT' $familyFile
Check $familyIndex 'c305bb4faf12d2aa88a2c3fc8bb3c79fda1471fcb27876ed3874d45469872732'
$indexOld=[IO.File]::ReadAllText((Disk $familyIndex));if([regex]::Matches($indexOld,'const MANIFEST_SHA="PENDING"').Count -ne 1 -or !$indexOld.Contains('const FORMAL_ENABLED=false')){throw 'FAMILY_FALSE_INDEX_PARENT'}
$indexFalseFile=W 'code/luoyang_estate_index_20261021am.gd' (LF ($indexOld.Replace('const MANIFEST_SHA="PENDING"','const MANIFEST_SHA="'+$familySHA+'"')))
$r=StageTarget $familyIndex 'c305bb4faf12d2aa88a2c3fc8bb3c79fda1471fcb27876ed3874d45469872732' $indexFalseFile;$patchTargets.Add($r)
$indexTrueFile=W 'estate_index_true.gd' ([IO.File]::ReadAllText($indexFalseFile).Replace('const FORMAL_ENABLED=false','const FORMAL_ENABLED=true'))
$falseSHA=SHA $indexFalseFile;$trueSHA=SHA $indexTrueFile
if([IO.File]::ReadAllText($indexTrueFile).Replace('const FORMAL_ENABLED=true','const FORMAL_ENABLED=false') -cne [IO.File]::ReadAllText($indexFalseFile)){throw 'SOLE_BOOL_INDEX_INVERSE'}
$shared=[ordered]@{};$shared['res://scripts/city/luoyang_estate_family_20261021am.gd']=$owned['res://scripts/city/luoyang_estate_family_20261021am.gd'].next;$shared[$familyManifest]=$familySHA
$familyCompileLeaf='res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/estate_candidate.gd'
if(!$runtime.Contains($familyCompileLeaf)){throw 'FAMILY_PRELOADED_EXECUTABLE_LEAF_REQUIRED'}
Put $shared $familyCompileLeaf $runtime[$familyCompileLeaf]
foreach($p in $pub.mansion_return.artifacts.Keys){Put $shared $p $pub.mansion_return.artifacts[$p]}
foreach($p in $pub.mansion_return.current_source_sha256.Keys){Put $shared $p $pub.mansion_return.current_source_sha256[$p]}
$manifestChanges=[ordered]@{};$manifestResults=[ordered]@{}
foreach($row in $a.city_manifests){
 Check $row.path $row.sha256;$m=J $row.path;$old=Clone $m;$delta=[Collections.Generic.List[object]]::new()
 foreach($p in $owned.Keys){foreach($kind in @('legacy_source_sha256','runtime_authority_sha256')){if($m[$kind].Contains($p)){if($m[$kind][$p] -cne $owned[$p].old){throw "MANIFEST_OLD_OWNED:$p"};$delta.Add(@{kind=$kind;path=$p;old=$m[$kind][$p];next=$owned[$p].next});$m[$kind][$p]=$owned[$p].next}}}
 $add=Clone $shared;if($m.scene_id -ceq 'ch4_s3_luoyang_market'){foreach($p in $runtime.Keys){Put $add $p $runtime[$p]}}
 if($m.legacy_source_sha256.Contains($temple) -or $m.legacy_source_sha256.Contains($oldBinding)){Put $add $bindingPath $bindingSHA}
 foreach($p in $add.Keys){if($p -ceq $familyIndex){throw 'INDEX_IN_MANIFEST'};if($m.artifacts.Contains($p)){if($m.artifacts[$p] -cne $add[$p]){throw 'ARTIFACT_HASH_COLLISION'};continue};$kind='legacy_source_sha256';if($m.runtime_authority_sha256.Contains($p)){$kind='runtime_authority_sha256'};$exists=$m[$kind].Contains($p);if($exists -and $m[$kind][$p] -cne $add[$p]){if(!$owned.Contains($p)){throw "EXISTING_DEPENDENCY_CHANGED:$p"};continue};if(!$exists){$delta.Add(@{kind=$kind;path=$p;old='ABSENT';next=$add[$p]});$m[$kind][$p]=$add[$p]}}
 $back=Clone $m;for($i=$delta.Count-1;$i -ge 0;$i--){$d=$delta[$i];if($d.old -ceq 'ABSENT'){$back[$d.kind].Remove($d.path)}else{$back[$d.kind][$d.path]=$d.old}};if(!(Same $back $old) -or !(Same $m.artifacts $old.artifacts) -or !(Same $m.layout_proof $old.layout_proof)){throw 'MANIFEST_WHOLE_INVERSE_AND_OLD_PROOF'}
 $file=WJ ('manifests/'+$row.key+'.json') $m;$r=StageTarget $row.path $row.sha256 $file;$manifestResults[$row.path]=$r.candidate_sha256;$manifestChanges[$row.path]=$delta
}
if($a.city_manifests.Count -ne 6){throw 'EXACT_SIX_CITY_MANIFESTS'}
$indexUpdates=[ordered]@{}
foreach($row in $a.city_indices){Check $row.path $row.sha256;$old=[IO.File]::ReadAllText((Disk $row.path));$next=$old
 foreach($m in $a.city_manifests){if($next.Contains($m.sha256)){$next=$next.Replace($m.sha256,$manifestResults[$m.path])}}
 if($next -ceq $old){throw 'INDEX_DID_NOT_INHERIT_OWNED_MANIFEST'}
 $file=W ('code/'+[IO.Path]::GetFileName($row.path)) (LF $next);$r=StageTarget $row.path $row.sha256 $file;$indexUpdates[$row.path]=@{old=$row.sha256;next=$r.candidate_sha256};$patchTargets.Add($r)
}
if($a.city_indices.Count -ne 3){throw 'EXACT_BI_AA_AC_INDICES'}
$maps=[ordered]@{}
foreach($base in $a.baselines){Check $base.path $base.sha256;$old=(J $base.path).source_sha256;$next=Clone $old
 foreach($p in $owned.Keys){if($next.Contains($p)){if($next[$p] -cne $owned[$p].old){throw 'MAP_OLD_OWNED'};$next[$p]=$owned[$p].next}}
 foreach($p in $manifestResults.Keys){if($next.Contains($p)){$next[$p]=$manifestResults[$p]}}
 foreach($p in $indexUpdates.Keys){if($next.Contains($p)){if($next[$p] -cne $indexUpdates[$p].old){throw 'MAP_OLD_INDEX'};$next[$p]=$indexUpdates[$p].next}}
 foreach($p in $shared.Keys){$next[$p]=$shared[$p]}
 if($base.scene_id -ceq 'ch4_s3_luoyang_market'){foreach($p in $runtime.Keys){$next[$p]=$runtime[$p]}}
 if($old.Contains($temple) -or $old.Contains($oldBinding)){$next[$bindingPath]=$bindingSHA}
 $next[$familyIndex]=$falseSHA;$formalMap=Clone $next;$formalMap[$familyIndex]=$trueSHA
 $allowed=[ordered]@{};foreach($set in @($owned,$manifestResults,$indexUpdates,$shared)){foreach($p in $set.Keys){$allowed[$p]=$true}};$allowed[$familyIndex]=$true
 if($base.scene_id -ceq 'ch4_s3_luoyang_market'){foreach($p in $runtime.Keys){$allowed[$p]=$true}}
 if($old.Contains($temple) -or $old.Contains($oldBinding)){$allowed[$bindingPath]=$true}
 $back=Clone $next;foreach($p in $allowed.Keys){if($old.Contains($p)){$back[$p]=$old[$p]}else{$back.Remove($p)}};if(!(Same $back $old)){throw 'INDEPENDENT_OLD_MAP_WHOLE_INVERSE'}
 $falseMap=WJ ('maps/'+$base.scene_id+'_false.json') @{status='AN_INDEPENDENT_OLD_PLUS_FINITE_SOURCE_DELTA';baseline_path=$base.path;baseline_sha256=$base.sha256;source_sha256=$next}
 $trueMap=WJ ('maps/'+$base.scene_id+'_true.json') @{status='AN_SOLE_FAMILY_INDEX_BOOL_SOURCE_SUCCESSOR';baseline_path=$base.path;baseline_sha256=$base.sha256;source_sha256=$formalMap}
 $maps[$base.scene_id]=@{false_path='res://'+$falseMap.Substring($game.Length+1).Replace('\','/');false_sha256=SHA $falseMap;true_path='res://'+$trueMap.Substring($game.Length+1).Replace('\','/');true_sha256=SHA $trueMap;count=$next.Count;old_count=$old.Count}
}
$patch="*** Begin Patch`n"
foreach($row in $patchTargets){$diff=@(& git diff --no-index --no-color --text --unified=3 -- (Disk $row.target) (Disk $row.candidate_path) 2>$null);if($LASTEXITCODE -gt 1){throw 'READ_ONLY_DIFF_FAILED'};$patch+='*** Update File: '+(Disk $row.target).Replace('\','/')+"`n";$active=$false;foreach($line in $diff){if($line.StartsWith('@@')){$patch+="@@`n";$active=$true;continue};if($active -and !$line.StartsWith('\ No newline')){$patch+=$line+"`n"}}}
$patch+="*** End Patch`n";$patchFile=W 'canonical_code_deployment.apply_patch' $patch
$receipt=@{status='AN_STAGED_SOURCE_READY_NOT_DEPLOYED_NOT_FIELD_PASS';admission_path=$AdmissionPath;admission_sha256=$AdmissionSHA;targets=$targets;code_patch_path=$pkg+'staged_retry1/canonical_code_deployment.apply_patch';code_patch_sha256=SHA $patchFile;family_manifest_path=$familyManifest;family_manifest_sha256=$familySHA;family_index_false_sha256=$falseSHA;family_index_true_sha256=$trueSHA;true_index_candidate_path=$pkg+'staged_retry1/estate_index_true.gd';temple_binding_path=$bindingPath;temple_binding_sha256=$bindingSHA;manifest_source_deltas=$manifestChanges;all_six_manifest_whole_inverse=$true;all18_city_native_artifacts_unchanged=$true;independent_expected_maps=$maps;current_runtime_source_count=$runtime.Count;shared_header_room_source_count=$shared.Count;no_actual_collector_backfill=$true;no_engine_or_deployment=$true}
$receiptFile=WJ 'receipt.json' $receipt
Write-Output (@{receipt=$pkg+'staged_retry1/receipt.json';sha256=SHA $receiptFile;targets=$targets.Count;estate_runtime_sources=$runtime.Count;shared_small_sources=$shared.Count;maps=$maps}|ConvertTo-Json -Depth 8)

){throw "EXACT_EXISTING_WAV_IMPORT_TYPE:$p"}
   $m=[regex]::Match($raw,'(?m)^path="(res://[^"\r\n]+\.sample)"\r?
 if($p.EndsWith('.tres')){foreach($m in [regex]::Matches([IO.File]::ReadAllText((Disk $p)),'\[ext_resource[^\r\n]*path="(res://[^"\r\n]+)"')){AddRuntime $m.Groups[1].Value}}
}
foreach($p in $pub.runtime_native.runtime_texture_paths){AddRuntime $p};AddRuntime $pub.runtime_native.runtime_walk_path
foreach($p in $pub.runtime_native.artifacts.Keys){AddRuntime $p};foreach($p in $pub.mansion_return.artifacts.Keys){AddRuntime $p}
if($pub.mansion_return.current_source_sha256 -isnot [Collections.IDictionary]){throw 'ONE_ROOM_CURRENT_CONSUMED_SOURCE_MAP_REQUIRED'}
foreach($p in $pub.mansion_return.current_source_sha256.Keys){if(!$known.Contains($p) -or $known[$p] -cne $pub.mansion_return.current_source_sha256[$p]){throw "ROOM_CURRENT_SOURCE_NOT_IN_INDEPENDENT_PUBLICATION:$p"};AddRuntime $p}
foreach($p in $owned.Keys){AddRuntime $p};AddRuntime $bindingPath
foreach($p in $a.runtime_program_sources){AddRuntime $p}
Put $runtime $a.geometry.path $a.geometry.sha256
Put $runtime $a.publication.path $a.publication.sha256
foreach($p in $a.provenance_sources.Keys){Check $p $a.provenance_sources[$p];Put $runtime $p $a.provenance_sources[$p]}
$familyIndex='res://scripts/city/luoyang_estate_index_20261021am.gd';$familyRoot='res://data/maps/luoyang_estate_courtyard_20261021am/';$familyManifest=$familyRoot+'manifest.json'
if($runtime.Contains($familyIndex) -or $runtime.Contains($familyManifest)){throw 'FAMILY_SELF_CYCLE'}
$family=@{schema_version=1;status='ROOT_ADMITTED_AM_ESTATE_FAMILY';scene_id='luoyang_estate_riverside_20261021ai';mansion_id='luoyang_functional_mansion_candidate_20261016';market_foot_px=$a.market_foot_px;registry_path=$pub.mansion_return.registry_path;registry_sha256=$pub.mansion_return.registry_sha256;source_sha256=$runtime;geometry_receipt=$a.geometry;publication_receipt=$a.publication;runtime_source_successions=$owned;historical_publication_sources_not_claimed_current=$pub.source_first;geometry_reused=$true}
$familyFile=WJ 'estate_manifest.json' $family;$familySHA=SHA $familyFile;$null=StageTarget $familyManifest 'ABSENT' $familyFile
Check $familyIndex 'c305bb4faf12d2aa88a2c3fc8bb3c79fda1471fcb27876ed3874d45469872732'
$indexOld=[IO.File]::ReadAllText((Disk $familyIndex));if([regex]::Matches($indexOld,'const MANIFEST_SHA="PENDING"').Count -ne 1 -or !$indexOld.Contains('const FORMAL_ENABLED=false')){throw 'FAMILY_FALSE_INDEX_PARENT'}
$indexFalseFile=W 'code/luoyang_estate_index_20261021am.gd' (LF ($indexOld.Replace('const MANIFEST_SHA="PENDING"','const MANIFEST_SHA="'+$familySHA+'"')))
$r=StageTarget $familyIndex 'c305bb4faf12d2aa88a2c3fc8bb3c79fda1471fcb27876ed3874d45469872732' $indexFalseFile;$patchTargets.Add($r)
$indexTrueFile=W 'estate_index_true.gd' ([IO.File]::ReadAllText($indexFalseFile).Replace('const FORMAL_ENABLED=false','const FORMAL_ENABLED=true'))
$falseSHA=SHA $indexFalseFile;$trueSHA=SHA $indexTrueFile
if([IO.File]::ReadAllText($indexTrueFile).Replace('const FORMAL_ENABLED=true','const FORMAL_ENABLED=false') -cne [IO.File]::ReadAllText($indexFalseFile)){throw 'SOLE_BOOL_INDEX_INVERSE'}
$shared=[ordered]@{};$shared['res://scripts/city/luoyang_estate_family_20261021am.gd']=$owned['res://scripts/city/luoyang_estate_family_20261021am.gd'].next;$shared[$familyManifest]=$familySHA
$familyCompileLeaf='res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/estate_candidate.gd'
if(!$runtime.Contains($familyCompileLeaf)){throw 'FAMILY_PRELOADED_EXECUTABLE_LEAF_REQUIRED'}
Put $shared $familyCompileLeaf $runtime[$familyCompileLeaf]
foreach($p in $pub.mansion_return.artifacts.Keys){Put $shared $p $pub.mansion_return.artifacts[$p]}
foreach($p in $pub.mansion_return.current_source_sha256.Keys){Put $shared $p $pub.mansion_return.current_source_sha256[$p]}
$manifestChanges=[ordered]@{};$manifestResults=[ordered]@{}
foreach($row in $a.city_manifests){
 Check $row.path $row.sha256;$m=J $row.path;$old=Clone $m;$delta=[Collections.Generic.List[object]]::new()
 foreach($p in $owned.Keys){foreach($kind in @('legacy_source_sha256','runtime_authority_sha256')){if($m[$kind].Contains($p)){if($m[$kind][$p] -cne $owned[$p].old){throw "MANIFEST_OLD_OWNED:$p"};$delta.Add(@{kind=$kind;path=$p;old=$m[$kind][$p];next=$owned[$p].next});$m[$kind][$p]=$owned[$p].next}}}
 $add=Clone $shared;if($m.scene_id -ceq 'ch4_s3_luoyang_market'){foreach($p in $runtime.Keys){Put $add $p $runtime[$p]}}
 if($m.legacy_source_sha256.Contains($temple) -or $m.legacy_source_sha256.Contains($oldBinding)){Put $add $bindingPath $bindingSHA}
 foreach($p in $add.Keys){if($p -ceq $familyIndex){throw 'INDEX_IN_MANIFEST'};if($m.artifacts.Contains($p)){if($m.artifacts[$p] -cne $add[$p]){throw 'ARTIFACT_HASH_COLLISION'};continue};$kind='legacy_source_sha256';if($m.runtime_authority_sha256.Contains($p)){$kind='runtime_authority_sha256'};$exists=$m[$kind].Contains($p);if($exists -and $m[$kind][$p] -cne $add[$p]){if(!$owned.Contains($p)){throw "EXISTING_DEPENDENCY_CHANGED:$p"};continue};if(!$exists){$delta.Add(@{kind=$kind;path=$p;old='ABSENT';next=$add[$p]});$m[$kind][$p]=$add[$p]}}
 $back=Clone $m;for($i=$delta.Count-1;$i -ge 0;$i--){$d=$delta[$i];if($d.old -ceq 'ABSENT'){$back[$d.kind].Remove($d.path)}else{$back[$d.kind][$d.path]=$d.old}};if(!(Same $back $old) -or !(Same $m.artifacts $old.artifacts) -or !(Same $m.layout_proof $old.layout_proof)){throw 'MANIFEST_WHOLE_INVERSE_AND_OLD_PROOF'}
 $file=WJ ('manifests/'+$row.key+'.json') $m;$r=StageTarget $row.path $row.sha256 $file;$manifestResults[$row.path]=$r.candidate_sha256;$manifestChanges[$row.path]=$delta
}
if($a.city_manifests.Count -ne 6){throw 'EXACT_SIX_CITY_MANIFESTS'}
$indexUpdates=[ordered]@{}
foreach($row in $a.city_indices){Check $row.path $row.sha256;$old=[IO.File]::ReadAllText((Disk $row.path));$next=$old
 foreach($m in $a.city_manifests){if($next.Contains($m.sha256)){$next=$next.Replace($m.sha256,$manifestResults[$m.path])}}
 if($next -ceq $old){throw 'INDEX_DID_NOT_INHERIT_OWNED_MANIFEST'}
 $file=W ('code/'+[IO.Path]::GetFileName($row.path)) (LF $next);$r=StageTarget $row.path $row.sha256 $file;$indexUpdates[$row.path]=@{old=$row.sha256;next=$r.candidate_sha256};$patchTargets.Add($r)
}
if($a.city_indices.Count -ne 3){throw 'EXACT_BI_AA_AC_INDICES'}
$maps=[ordered]@{}
foreach($base in $a.baselines){Check $base.path $base.sha256;$old=(J $base.path).source_sha256;$next=Clone $old
 foreach($p in $owned.Keys){if($next.Contains($p)){if($next[$p] -cne $owned[$p].old){throw 'MAP_OLD_OWNED'};$next[$p]=$owned[$p].next}}
 foreach($p in $manifestResults.Keys){if($next.Contains($p)){$next[$p]=$manifestResults[$p]}}
 foreach($p in $indexUpdates.Keys){if($next.Contains($p)){if($next[$p] -cne $indexUpdates[$p].old){throw 'MAP_OLD_INDEX'};$next[$p]=$indexUpdates[$p].next}}
 foreach($p in $shared.Keys){$next[$p]=$shared[$p]}
 if($base.scene_id -ceq 'ch4_s3_luoyang_market'){foreach($p in $runtime.Keys){$next[$p]=$runtime[$p]}}
 if($old.Contains($temple) -or $old.Contains($oldBinding)){$next[$bindingPath]=$bindingSHA}
 $next[$familyIndex]=$falseSHA;$formalMap=Clone $next;$formalMap[$familyIndex]=$trueSHA
 $allowed=[ordered]@{};foreach($set in @($owned,$manifestResults,$indexUpdates,$shared)){foreach($p in $set.Keys){$allowed[$p]=$true}};$allowed[$familyIndex]=$true
 if($base.scene_id -ceq 'ch4_s3_luoyang_market'){foreach($p in $runtime.Keys){$allowed[$p]=$true}}
 if($old.Contains($temple) -or $old.Contains($oldBinding)){$allowed[$bindingPath]=$true}
 $back=Clone $next;foreach($p in $allowed.Keys){if($old.Contains($p)){$back[$p]=$old[$p]}else{$back.Remove($p)}};if(!(Same $back $old)){throw 'INDEPENDENT_OLD_MAP_WHOLE_INVERSE'}
 $falseMap=WJ ('maps/'+$base.scene_id+'_false.json') @{status='AN_INDEPENDENT_OLD_PLUS_FINITE_SOURCE_DELTA';baseline_path=$base.path;baseline_sha256=$base.sha256;source_sha256=$next}
 $trueMap=WJ ('maps/'+$base.scene_id+'_true.json') @{status='AN_SOLE_FAMILY_INDEX_BOOL_SOURCE_SUCCESSOR';baseline_path=$base.path;baseline_sha256=$base.sha256;source_sha256=$formalMap}
 $maps[$base.scene_id]=@{false_path='res://'+$falseMap.Substring($game.Length+1).Replace('\','/');false_sha256=SHA $falseMap;true_path='res://'+$trueMap.Substring($game.Length+1).Replace('\','/');true_sha256=SHA $trueMap;count=$next.Count;old_count=$old.Count}
}
$patch="*** Begin Patch`n"
foreach($row in $patchTargets){$diff=@(& git diff --no-index --no-color --text --unified=3 -- (Disk $row.target) (Disk $row.candidate_path) 2>$null);if($LASTEXITCODE -gt 1){throw 'READ_ONLY_DIFF_FAILED'};$patch+='*** Update File: '+(Disk $row.target).Replace('\','/')+"`n";$active=$false;foreach($line in $diff){if($line.StartsWith('@@')){$patch+="@@`n";$active=$true;continue};if($active -and !$line.StartsWith('\ No newline')){$patch+=$line+"`n"}}}
$patch+="*** End Patch`n";$patchFile=W 'canonical_code_deployment.apply_patch' $patch
$receipt=@{status='AN_STAGED_SOURCE_READY_NOT_DEPLOYED_NOT_FIELD_PASS';admission_path=$AdmissionPath;admission_sha256=$AdmissionSHA;targets=$targets;code_patch_path=$pkg+'staged_retry1/canonical_code_deployment.apply_patch';code_patch_sha256=SHA $patchFile;family_manifest_path=$familyManifest;family_manifest_sha256=$familySHA;family_index_false_sha256=$falseSHA;family_index_true_sha256=$trueSHA;true_index_candidate_path=$pkg+'staged_retry1/estate_index_true.gd';temple_binding_path=$bindingPath;temple_binding_sha256=$bindingSHA;manifest_source_deltas=$manifestChanges;all_six_manifest_whole_inverse=$true;all18_city_native_artifacts_unchanged=$true;independent_expected_maps=$maps;current_runtime_source_count=$runtime.Count;shared_header_room_source_count=$shared.Count;no_actual_collector_backfill=$true;no_engine_or_deployment=$true}
$receiptFile=WJ 'receipt.json' $receipt
Write-Output (@{receipt=$pkg+'staged_retry1/receipt.json';sha256=SHA $receiptFile;targets=$targets.Count;estate_runtime_sources=$runtime.Count;shared_small_sources=$shared.Count;maps=$maps}|ConvertTo-Json -Depth 8)

)
   if(!$m.Success -or $m.Groups[1].Value -cne $audioRemaps[$p]){throw "EXACT_EXISTING_WAV_REMAP:$p"}
  }else{
   $m=[regex]::Match($raw,'(?m)^path="(res://[^"\r\n]+\.ctex)"')
   if(!$m.Success){throw "EXACT_TEXTURE_IMPORT_REMAP:$p"}
  }
  AddRuntime $m.Groups[1].Value
 }
 if($p.EndsWith('.tres')){foreach($m in [regex]::Matches([IO.File]::ReadAllText((Disk $p)),'\[ext_resource[^\r\n]*path="(res://[^"\r\n]+)"')){AddRuntime $m.Groups[1].Value}}
}
foreach($p in $pub.runtime_native.runtime_texture_paths){AddRuntime $p};AddRuntime $pub.runtime_native.runtime_walk_path
foreach($p in $pub.runtime_native.artifacts.Keys){AddRuntime $p};foreach($p in $pub.mansion_return.artifacts.Keys){AddRuntime $p}
if($pub.mansion_return.current_source_sha256 -isnot [Collections.IDictionary]){throw 'ONE_ROOM_CURRENT_CONSUMED_SOURCE_MAP_REQUIRED'}
foreach($p in $pub.mansion_return.current_source_sha256.Keys){if(!$known.Contains($p) -or $known[$p] -cne $pub.mansion_return.current_source_sha256[$p]){throw "ROOM_CURRENT_SOURCE_NOT_IN_INDEPENDENT_PUBLICATION:$p"};AddRuntime $p}
foreach($p in $owned.Keys){AddRuntime $p};AddRuntime $bindingPath
foreach($p in $a.runtime_program_sources){AddRuntime $p}
Put $runtime $a.geometry.path $a.geometry.sha256
Put $runtime $a.publication.path $a.publication.sha256
foreach($p in $a.provenance_sources.Keys){Check $p $a.provenance_sources[$p];Put $runtime $p $a.provenance_sources[$p]}
$familyIndex='res://scripts/city/luoyang_estate_index_20261021am.gd';$familyRoot='res://data/maps/luoyang_estate_courtyard_20261021am/';$familyManifest=$familyRoot+'manifest.json'
if($runtime.Contains($familyIndex) -or $runtime.Contains($familyManifest)){throw 'FAMILY_SELF_CYCLE'}
$family=@{schema_version=1;status='ROOT_ADMITTED_AM_ESTATE_FAMILY';scene_id='luoyang_estate_riverside_20261021ai';mansion_id='luoyang_functional_mansion_candidate_20261016';market_foot_px=$a.market_foot_px;registry_path=$pub.mansion_return.registry_path;registry_sha256=$pub.mansion_return.registry_sha256;source_sha256=$runtime;geometry_receipt=$a.geometry;publication_receipt=$a.publication;runtime_source_successions=$owned;historical_publication_sources_not_claimed_current=$pub.source_first;geometry_reused=$true}
$familyFile=WJ 'estate_manifest.json' $family;$familySHA=SHA $familyFile;$null=StageTarget $familyManifest 'ABSENT' $familyFile
Check $familyIndex 'c305bb4faf12d2aa88a2c3fc8bb3c79fda1471fcb27876ed3874d45469872732'
$indexOld=[IO.File]::ReadAllText((Disk $familyIndex));if([regex]::Matches($indexOld,'const MANIFEST_SHA="PENDING"').Count -ne 1 -or !$indexOld.Contains('const FORMAL_ENABLED=false')){throw 'FAMILY_FALSE_INDEX_PARENT'}
$indexFalseFile=W 'code/luoyang_estate_index_20261021am.gd' (LF ($indexOld.Replace('const MANIFEST_SHA="PENDING"','const MANIFEST_SHA="'+$familySHA+'"')))
$r=StageTarget $familyIndex 'c305bb4faf12d2aa88a2c3fc8bb3c79fda1471fcb27876ed3874d45469872732' $indexFalseFile;$patchTargets.Add($r)
$indexTrueFile=W 'estate_index_true.gd' ([IO.File]::ReadAllText($indexFalseFile).Replace('const FORMAL_ENABLED=false','const FORMAL_ENABLED=true'))
$falseSHA=SHA $indexFalseFile;$trueSHA=SHA $indexTrueFile
if([IO.File]::ReadAllText($indexTrueFile).Replace('const FORMAL_ENABLED=true','const FORMAL_ENABLED=false') -cne [IO.File]::ReadAllText($indexFalseFile)){throw 'SOLE_BOOL_INDEX_INVERSE'}
$shared=[ordered]@{};$shared['res://scripts/city/luoyang_estate_family_20261021am.gd']=$owned['res://scripts/city/luoyang_estate_family_20261021am.gd'].next;$shared[$familyManifest]=$familySHA
$familyCompileLeaf='res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/estate_candidate.gd'
if(!$runtime.Contains($familyCompileLeaf)){throw 'FAMILY_PRELOADED_EXECUTABLE_LEAF_REQUIRED'}
Put $shared $familyCompileLeaf $runtime[$familyCompileLeaf]
foreach($p in $pub.mansion_return.artifacts.Keys){Put $shared $p $pub.mansion_return.artifacts[$p]}
foreach($p in $pub.mansion_return.current_source_sha256.Keys){Put $shared $p $pub.mansion_return.current_source_sha256[$p]}
$manifestChanges=[ordered]@{};$manifestResults=[ordered]@{}
foreach($row in $a.city_manifests){
 Check $row.path $row.sha256;$m=J $row.path;$old=Clone $m;$delta=[Collections.Generic.List[object]]::new()
 foreach($p in $owned.Keys){foreach($kind in @('legacy_source_sha256','runtime_authority_sha256')){if($m[$kind].Contains($p)){if($m[$kind][$p] -cne $owned[$p].old){throw "MANIFEST_OLD_OWNED:$p"};$delta.Add(@{kind=$kind;path=$p;old=$m[$kind][$p];next=$owned[$p].next});$m[$kind][$p]=$owned[$p].next}}}
 $add=Clone $shared;if($m.scene_id -ceq 'ch4_s3_luoyang_market'){foreach($p in $runtime.Keys){Put $add $p $runtime[$p]}}
 if($m.legacy_source_sha256.Contains($temple) -or $m.legacy_source_sha256.Contains($oldBinding)){Put $add $bindingPath $bindingSHA}
 foreach($p in $add.Keys){if($p -ceq $familyIndex){throw 'INDEX_IN_MANIFEST'};if($m.artifacts.Contains($p)){if($m.artifacts[$p] -cne $add[$p]){throw 'ARTIFACT_HASH_COLLISION'};continue};$kind='legacy_source_sha256';if($m.runtime_authority_sha256.Contains($p)){$kind='runtime_authority_sha256'};$exists=$m[$kind].Contains($p);if($exists -and $m[$kind][$p] -cne $add[$p]){if(!$owned.Contains($p)){throw "EXISTING_DEPENDENCY_CHANGED:$p"};continue};if(!$exists){$delta.Add(@{kind=$kind;path=$p;old='ABSENT';next=$add[$p]});$m[$kind][$p]=$add[$p]}}
 $back=Clone $m;for($i=$delta.Count-1;$i -ge 0;$i--){$d=$delta[$i];if($d.old -ceq 'ABSENT'){$back[$d.kind].Remove($d.path)}else{$back[$d.kind][$d.path]=$d.old}};if(!(Same $back $old) -or !(Same $m.artifacts $old.artifacts) -or !(Same $m.layout_proof $old.layout_proof)){throw 'MANIFEST_WHOLE_INVERSE_AND_OLD_PROOF'}
 $file=WJ ('manifests/'+$row.key+'.json') $m;$r=StageTarget $row.path $row.sha256 $file;$manifestResults[$row.path]=$r.candidate_sha256;$manifestChanges[$row.path]=$delta
}
if($a.city_manifests.Count -ne 6){throw 'EXACT_SIX_CITY_MANIFESTS'}
$indexUpdates=[ordered]@{}
foreach($row in $a.city_indices){Check $row.path $row.sha256;$old=[IO.File]::ReadAllText((Disk $row.path));$next=$old
 foreach($m in $a.city_manifests){if($next.Contains($m.sha256)){$next=$next.Replace($m.sha256,$manifestResults[$m.path])}}
 if($next -ceq $old){throw 'INDEX_DID_NOT_INHERIT_OWNED_MANIFEST'}
 $file=W ('code/'+[IO.Path]::GetFileName($row.path)) (LF $next);$r=StageTarget $row.path $row.sha256 $file;$indexUpdates[$row.path]=@{old=$row.sha256;next=$r.candidate_sha256};$patchTargets.Add($r)
}
if($a.city_indices.Count -ne 3){throw 'EXACT_BI_AA_AC_INDICES'}
$maps=[ordered]@{}
foreach($base in $a.baselines){Check $base.path $base.sha256;$old=(J $base.path).source_sha256;$next=Clone $old
 foreach($p in $owned.Keys){if($next.Contains($p)){if($next[$p] -cne $owned[$p].old){throw 'MAP_OLD_OWNED'};$next[$p]=$owned[$p].next}}
 foreach($p in $manifestResults.Keys){if($next.Contains($p)){$next[$p]=$manifestResults[$p]}}
 foreach($p in $indexUpdates.Keys){if($next.Contains($p)){if($next[$p] -cne $indexUpdates[$p].old){throw 'MAP_OLD_INDEX'};$next[$p]=$indexUpdates[$p].next}}
 foreach($p in $shared.Keys){$next[$p]=$shared[$p]}
 if($base.scene_id -ceq 'ch4_s3_luoyang_market'){foreach($p in $runtime.Keys){$next[$p]=$runtime[$p]}}
 if($old.Contains($temple) -or $old.Contains($oldBinding)){$next[$bindingPath]=$bindingSHA}
 $next[$familyIndex]=$falseSHA;$formalMap=Clone $next;$formalMap[$familyIndex]=$trueSHA
 $allowed=[ordered]@{};foreach($set in @($owned,$manifestResults,$indexUpdates,$shared)){foreach($p in $set.Keys){$allowed[$p]=$true}};$allowed[$familyIndex]=$true
 if($base.scene_id -ceq 'ch4_s3_luoyang_market'){foreach($p in $runtime.Keys){$allowed[$p]=$true}}
 if($old.Contains($temple) -or $old.Contains($oldBinding)){$allowed[$bindingPath]=$true}
 $back=Clone $next;foreach($p in $allowed.Keys){if($old.Contains($p)){$back[$p]=$old[$p]}else{$back.Remove($p)}};if(!(Same $back $old)){throw 'INDEPENDENT_OLD_MAP_WHOLE_INVERSE'}
 $falseMap=WJ ('maps/'+$base.scene_id+'_false.json') @{status='AN_INDEPENDENT_OLD_PLUS_FINITE_SOURCE_DELTA';baseline_path=$base.path;baseline_sha256=$base.sha256;source_sha256=$next}
 $trueMap=WJ ('maps/'+$base.scene_id+'_true.json') @{status='AN_SOLE_FAMILY_INDEX_BOOL_SOURCE_SUCCESSOR';baseline_path=$base.path;baseline_sha256=$base.sha256;source_sha256=$formalMap}
 $maps[$base.scene_id]=@{false_path='res://'+$falseMap.Substring($game.Length+1).Replace('\','/');false_sha256=SHA $falseMap;true_path='res://'+$trueMap.Substring($game.Length+1).Replace('\','/');true_sha256=SHA $trueMap;count=$next.Count;old_count=$old.Count}
}
$patch="*** Begin Patch`n"
foreach($row in $patchTargets){$diff=@(& git diff --no-index --no-color --text --unified=3 -- (Disk $row.target) (Disk $row.candidate_path) 2>$null);if($LASTEXITCODE -gt 1){throw 'READ_ONLY_DIFF_FAILED'};$patch+='*** Update File: '+(Disk $row.target).Replace('\','/')+"`n";$active=$false;foreach($line in $diff){if($line.StartsWith('@@')){$patch+="@@`n";$active=$true;continue};if($active -and !$line.StartsWith('\ No newline')){$patch+=$line+"`n"}}}
$patch+="*** End Patch`n";$patchFile=W 'canonical_code_deployment.apply_patch' $patch
$receipt=@{status='AN_STAGED_SOURCE_READY_NOT_DEPLOYED_NOT_FIELD_PASS';admission_path=$AdmissionPath;admission_sha256=$AdmissionSHA;targets=$targets;code_patch_path=$pkg+'staged_retry1/canonical_code_deployment.apply_patch';code_patch_sha256=SHA $patchFile;family_manifest_path=$familyManifest;family_manifest_sha256=$familySHA;family_index_false_sha256=$falseSHA;family_index_true_sha256=$trueSHA;true_index_candidate_path=$pkg+'staged_retry1/estate_index_true.gd';temple_binding_path=$bindingPath;temple_binding_sha256=$bindingSHA;manifest_source_deltas=$manifestChanges;all_six_manifest_whole_inverse=$true;all18_city_native_artifacts_unchanged=$true;independent_expected_maps=$maps;current_runtime_source_count=$runtime.Count;shared_header_room_source_count=$shared.Count;no_actual_collector_backfill=$true;no_engine_or_deployment=$true}
$receiptFile=WJ 'receipt.json' $receipt
Write-Output (@{receipt=$pkg+'staged_retry1/receipt.json';sha256=SHA $receiptFile;targets=$targets.Count;estate_runtime_sources=$runtime.Count;shared_small_sources=$shared.Count;maps=$maps}|ConvertTo-Json -Depth 8)
