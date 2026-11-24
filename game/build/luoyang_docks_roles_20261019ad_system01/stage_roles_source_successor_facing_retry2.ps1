param([string]$AdmissionPath,[string]$AdmissionSHA,[string]$Workspace='F:\Code\RPG_GAME')
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
# NEW-only mechanical publication. Inputs must be frozen AFTER actual art/import.
# Does not run an engine, gather actual collector paths, deploy or touch saves.
$gameRoot=Join-Path $Workspace 'game'
$package='res://build/luoyang_docks_roles_20261019ad_system01/'
$stageRoot=Join-Path $gameRoot ($package.Substring(6)+'staged')
if(Test-Path -LiteralPath $stageRoot){throw 'STAGED_EXISTS_PRESERVE_EVIDENCE'}
function Disk([string]$p){if(!$p.StartsWith('res://') -or $p.Contains('..')){throw 'BAD_RESOURCE_PATH'};return Join-Path $gameRoot $p.Substring(6)}
function Sha([string]$p){return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function CheckHash([string]$p,[string]$s){if($s -notmatch '^[0-9a-f]{64}$' -or (Sha (Disk $p)) -cne $s){throw "SOURCE_CHANGED:$p"}}
function J([string]$p){return Get-Content -Raw -LiteralPath (Disk $p)|ConvertFrom-Json -AsHashtable}
function Clone($v){return $v|ConvertTo-Json -Depth 100 -Compress|ConvertFrom-Json -AsHashtable}
function Canon($v){if($v -is [Collections.IDictionary]){$o=[ordered]@{};foreach($k in @($v.Keys|Sort-Object -CaseSensitive)){$o[$k]=Canon $v[$k]};return $o};if($v -is [array]){return ,@($v|ForEach-Object{Canon $_})};return $v}
function Same($a,$b){return ((Canon $a)|ConvertTo-Json -Depth 100 -Compress) -ceq ((Canon $b)|ConvertTo-Json -Depth 100 -Compress)}
function IsTrue($v){return $v -is [bool] -and $v -eq $true}
function W([string]$rel,[string]$text){$p=[IO.Path]::GetFullPath((Join-Path $stageRoot $rel));if(!$p.StartsWith($stageRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'WRITE_OUTSIDE_NEW_STAGE'};[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($p))|Out-Null;[IO.File]::WriteAllText($p,$text,[Text.UTF8Encoding]::new($false));return $p}
function WJ([string]$rel,$v){return W $rel (($v|ConvertTo-Json -Depth 100)+"`n")}
function AddExact($map,[string]$p,[string]$s){if($map.Contains($p) -and $map[$p] -cne $s){throw "SOURCE_COLLISION:$p"};$map[$p]=$s}
function CloseImports($map){foreach($p in @($map.Keys)){$ip=$p+'.import';if(!(Test-Path -LiteralPath (Disk $ip))){continue};AddExact $map $ip (Sha (Disk $ip));$remap=[regex]::Match([IO.File]::ReadAllText((Disk $ip)),'(?ms)^\[remap\]\r?\n(.*?)(?=^\[|\z)').Groups[1].Value;foreach($m in [regex]::Matches($remap,'(?m)^path[^=\r\n]*="([^"]+)"\r?$')){$rp=$m.Groups[1].Value;AddExact $map $rp (Sha (Disk $rp))}};return $map}
if([string]::IsNullOrWhiteSpace($AdmissionPath) -or [string]::IsNullOrWhiteSpace($AdmissionSHA)){throw 'ACTUAL_FROZEN_ADMISSION_PATH_AND_SHA_REQUIRED_NO_OUTPUT'}
$AdmissionSHA=$AdmissionSHA.ToLowerInvariant();CheckHash $AdmissionPath $AdmissionSHA
$admission=J $AdmissionPath
if($admission.schema_version -is [bool] -or $admission.schema_version -ne 1 -or $admission.status -cne 'ROOT_APPROVED_ACTUAL_AD_ROLES_IMPORT_SOURCE_INPUT' -or $admission.scene_id -cne 'ch4_s2_canal_docks' -or !(IsTrue $admission.root_approved_same_person_and_four_authored_phase_cells) -or !(IsTrue $admission.root_confirmed_main_import_promotion) -or $admission.loop_motion_observed -isnot [bool] -or $admission.loop_motion_observed -ne $false){throw 'ADMISSION_NOT_READY_NO_OUTPUT'}
$B='res://scripts/city/luoyang_precomputed_bundle_20261018r.gd'
$H='res://scripts/city/luoyang_harbour_life_runtime_20261016.gd'
$BI='res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd'
$AI='res://scripts/city/luoyang_docks_district08_index_20261019aa.gd'
$CI='res://scripts/city/luoyang_docks_workyard_index_20261019ac.gd'
$DI='res://scripts/city/luoyang_docks_roles_index_20261019ad.gd'
$module='res://scripts/city/luoyang_docks_roles_20261019ad.gd'
$roleManifestPath='res://data/luoyang_docks_roles_20261019ad/manifest.json'
$templeHelper='res://scripts/city/luoyang_temple_assembly_20261016.gd'
$oldTempleBinding='res://build/luoyang_docks_district08_runtime_20261019ab_source01/staged/temple_binding.json'
$newTempleBinding=$package+'staged/temple_binding.json'
$oldRoot='res://data/maps/luoyang_layout_bundle_20261018t_retry2/'
$aaManifestPath='res://data/maps/luoyang_docks_district08_20261019aa/runtime/ch4_s2_canal_docks/manifest.json'
$acManifestPath='res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/manifest.json'
$docks='ch4_s2_canal_docks'
$priorPackage='res://build/luoyang_docks_workyard_20261019ac_source01/staged_retry1/'
$baselinePath=$priorPackage+'expected_sources_true.json'
$pins=@{
 $B='62f2166a39857a911c5e2b07abfaa6de057a6f5d03ddc5b3eb897e0430bfd631'
 $H='f20e9acb1fe4030af3de929b1c9390f243855d9e20ed20c877a5e68dd9201b6a'
 $BI='6700aadd853753ee35b8964d9952cde0d0d8d7667d955dbfddd4ac8b51cf34c7'
 $AI='0550a184e989073774e0ad1974ea7a90b17ac3f5560c0f30a525fd2736298c44'
 $CI='aae3e942acab88f372ca3dbeaab902fdfabecb4058e3a053ddf12b5fc33a3372'
 $DI='de05ee25b4141ee5cc87af5cdaf32472490ae164f01b9b6a37ddf13a6239b11c'
 $module='68caa52589abbb0a2ccc1527e05e85dd1dccf3e8efaafec1135615527c7d6641'
 ($package+'Docks_roles_facing_candidate.gd')='3741bfd1b01a045e0ea262ddd7f2725480bbfe19235adc844fc2f368012690df'
 $roleManifestPath='4f1175df859e092160754f90360505a2c5d70f82c9e783e83bb5b017ad668719'
 $templeHelper='54e99f7731129451f06a6ba8e722c79e7d1e46181775d646f0c28f524ae5514c'
 $oldTempleBinding='20664837923f2fc75f693efa3319b5448eb70ac7614ecbcd2520a44a6d299b16'
 $baselinePath='ff37a55cb21306db85c83c9859b83d673ddb160f2d702aa7d8e675c8b615e362'
 ($package+'Bundle_candidate.gd')='f8e6cd4e2cbd752581a8b4fc9386266d5da66b04623163fdaf2174f9b6aa8969'
 ($package+'Harbour_candidate.gd')='4323f9350c55d18df998dcdfdbb980bf0d681859822b723fdd2fca86c9dcbf0e'
 'res://scripts/city/luoyang_harbour_life_crowd_retry3_20261016.gd'='1aaea6ca19ab8abb1f164b155f24ac8a11ca43e7e4d73b1fa4fd899937b5e83b'
 'res://scripts/city/luoyang_docks_office_roles_20261016h.gd'='627920a95b7352f2913d074df38a9ad6de1afcd9da0ae73d81477f6e03662f6e'
 'res://data/maps/luoyang_docks_office_20261016h/author.json'='dc8d7ae836735f349360ca0bd69cc0290ebc6461470e7bd3af359ded568ec9e7'
 'res://scripts/field/field_walkable_controller.gd'='f4be15c219c7873ae37d918c3b989bbbfabf4b782b4ee5711bbf9d6b2c0900ee'
 'res://scripts/field/npc_node.gd'='67c0f3deafef65445918b5815f4acdcb4cc577206248f20cd67a998930d00bea'
 'res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd'='fc9339579a0091936cf1bb747e84667e017d0eb57ffd025918023601afc51da9'
 'res://data/luoyang_culture_integration_20261019x/runtime_contract.json'='da49fe454e9ab975485e75e96772834f2a8c312463cf96bff8aceb6c0d050c1f'
}
foreach($p in $pins.Keys){CheckHash $p $pins[$p]}
$oldCityPins=@{
 ch4_s0_luoyang_gate='d364b02bf239b858a17821cde1d8546ef5816d1f7f38bf5c915f0e3ecfa5aced'
 ch4_s1_luoyang_yamen='8965d925a5f70db53c04eb0b032c628384b5ca032daceca6c2eb73530ef4763e'
 ch4_s2_canal_docks='ccc3d87e7e77222ce3496050ad0d4db9efeab16dd7c161df9170132480ee242b'
 ch4_s3_luoyang_market='2b77be55cfd96ca0ec393678eb52fa96445fd7de8b9ea74adc2ad8ea31612294'
 AA='20fd71879b487dc9e1f6eb39e23c6f58c9ef38e8803653d7ffac451d0189ad8d'
 AC='187bb616c28bf9867dd10dc41b0ceaac4a6692fbffad3dcf678cb25e1271a5f8'
}
$manifestPaths=@{AA=$aaManifestPath;AC=$acManifestPath}
foreach($id in @('ch4_s0_luoyang_gate','ch4_s1_luoyang_yamen',$docks,'ch4_s3_luoyang_market')){$manifestPaths[$id]=$oldRoot+$id+'/manifest.json'}
foreach($key in $manifestPaths.Keys){CheckHash $manifestPaths[$key] $oldCityPins[$key]}
$allIds=@('harbour_life_docks_rope_carrier','harbour_life_docks_southern_carrier','harbour_life_docks_west_carrier','harbour_life_docks_store_attendant','harbour_life_docks_rope_seller')
$carrierIds=@($allIds[0..2]);$selected=@($admission.approved_role_ids)
if(!(Same @($selected|Sort-Object -CaseSensitive) @($carrierIds|Sort-Object -CaseSensitive)) -and !(Same @($selected|Sort-Object -CaseSensitive) @($allIds|Sort-Object -CaseSensitive))){throw 'ONLY_ROOT_APPROVED_THREE_CARRIERS_OR_ALL_FIVE_SCOPE'}
$artRef=$admission.art_admission;$importRef=$admission.import_proof
if(!(IsTrue $artRef.approved) -or $artRef.path -isnot [string] -or $importRef.path -isnot [string]){throw 'ACTUAL_ART_IMPORT_REFERENCE_REQUIRED'}
CheckHash $artRef.path ([string]$artRef.sha256).ToLowerInvariant();CheckHash $importRef.path ([string]$importRef.sha256).ToLowerInvariant()
$importProof=J $importRef.path
if($importProof.scope -cne 'AD_ONLY_NEW_ROLE_PNG_ISOLATED_IMPORT_NOT_MAIN_PROJECT_OR_FIELD' -or !(IsTrue $importProof.passed) -or $importProof.failures.Count -ne 0 -or !(Same $importProof.source_first $importProof.source_final)){throw 'ACTUAL_ISOLATED_IMPORT_FACTS_REFUSED'}
$artRoot='res://art/characters/luoyang_docks_roles_20261019ad/'
$portraitRoot='res://art/characters/portraits/luoyang_docks_roles_20261019ad/'
$dialogRoot='res://data/dialogs/luoyang_docks_roles_20261019ad/'
$dialogHashes=@{carrier_daily='ae59e7717061e95344b841aa04158a177fb051d313734a972c52b1dabd7c3eaf';west_porter_daily='769676bd2d754cc0891f73edef8d45a56cf78a9ce0f6d93ae910c590b4208056';store_attendant_daily='42f66207a11c3330d0aeb7eca457c5960cb2e7274546fd79dbaefe395cbada43';rope_seller_daily='c8125325aa4345eae3492bd749b0797512e80c5008014edb7fdcf78b43f1cddb'}
$roles=@();$textures=@{};$roleSources=@{}
foreach($id in $allIds){if($id -cnotin $selected){continue};$moving=$id -cin $carrierIds;$family=if($moving){'strong_carrier'}elseif($id -ceq $allIds[3]){'store_attendant'}else{'rope_seller'};$daily=if($id -cin @($allIds[0],$allIds[1])){'carrier_daily'}elseif($id -ceq $allIds[2]){'west_porter_daily'}else{$family+'_daily'}
 $idle=$artRoot+'npc_docks_'+$family+'_idle_down_1f_v1_runtime.png';$walk=if($moving){$artRoot+'npc_docks_strong_carrier_walk_right_4f_v1_runtime.png'}else{''};$portrait=$portraitRoot+'portrait_docks_'+$family+'_v1.png'
 $rolePatch=@{sprite_path=$idle;walk_sprite_path=$walk;portrait_path=$portrait};if($moving){$rolePatch['invert_patrol_facing']=$false};$roles+=@{npc_id=$id;patch=$rolePatch;ambient_dialog='luoyang_docks_roles_20261019ad/'+$daily}
 $textures[$idle]=@(160,160);if($moving){$textures[$walk]=@(640,160)};$textures[$portrait]=@(512,512)
 $dp=$dialogRoot+$daily+'.tres';CheckHash $dp $dialogHashes[$daily];AddExact $roleSources $dp $dialogHashes[$daily]
}
if($textures.Count -ne $(if($selected.Count -eq 3){3}else{7}) -or $importProof.rows.Count -ne $textures.Count){throw 'EXACT_SELECTED_TEXTURE_SET_REQUIRED'}
$importSeen=@{}
foreach($row in $importProof.rows){
 if($row.texture -isnot [string] -or !$textures.Contains($row.texture) -or $importSeen.Contains($row.texture) -or !(IsTrue $row.full_rgba_exact) -or !(IsTrue $row.params23) -or !(IsTrue $row.zero_mipmaps) -or $row.detect3d_compress_to -is [bool] -or $row.detect3d_compress_to -is [string] -or $row.detect3d_compress_to -ne 0 -or $row.import_path -cne ($row.texture+'.import') -or !$row.compiled_path.StartsWith('res://.godot/imported/') -or !$row.compiled_path.EndsWith('.ctex')){throw 'EXACT_IMPORT_ROW_REFUSED'}
 $size=@($row.size);$wanted=$textures[$row.texture];if($size.Count -ne 2 -or $size[0] -is [bool] -or $size[1] -is [bool] -or $size[0] -is [string] -or $size[1] -is [string] -or [double]$size[0] -ne $wanted[0] -or [double]$size[1] -ne $wanted[1]){throw 'EXACT_TEXTURE_DIMENSIONS_REFUSED'}
 foreach($pair in @(@($row.texture,$row.source_sha256),@($row.import_path,$row.import_sha256),@($row.compiled_path,$row.compiled_sha256))){$s=([string]$pair[1]).ToLowerInvariant();CheckHash $pair[0] $s;AddExact $roleSources $pair[0] $s}
 $importSeen[$row.texture]=$true
}
foreach($p in @('res://scripts/city/luoyang_harbour_life_crowd_retry3_20261016.gd','res://scripts/city/luoyang_docks_office_roles_20261016h.gd','res://data/maps/luoyang_docks_office_20261016h/author.json')){AddExact $roleSources $p $pins[$p]}
foreach($p in $admission.extra_immutable_source_sha256.Keys){$s=([string]$admission.extra_immutable_source_sha256[$p]).ToLowerInvariant();CheckHash $p $s;AddExact $roleSources $p $s}
AddExact $roleSources $AdmissionPath $AdmissionSHA;AddExact $roleSources $artRef.path ([string]$artRef.sha256).ToLowerInvariant();AddExact $roleSources $importRef.path ([string]$importRef.sha256).ToLowerInvariant()
$roleSources=CloseImports $roleSources
foreach($p in $roleSources.Keys){if($p -in @($module,$DI,$roleManifestPath,$B,$H,$BI,$AI,$CI,$templeHelper) -or $p -in $manifestPaths.Values){throw 'ROLE_MANIFEST_MUTABLE_OR_SELF_CYCLE'};CheckHash $p $roleSources[$p]}
# No stage output is created before all actual proof/media/old-parent guards pass.
$roleManifest=@{schema_version=1;status='READY_SOURCE_BOUND_DOCKS_ROLES';scene_id=$docks;roles=$roles;source_sha256=$roleSources;evidence=@{art_admission=@{path=$artRef.path;sha256=([string]$artRef.sha256).ToLowerInvariant()};import_proof=@{path=$importRef.path;sha256=([string]$importRef.sha256).ToLowerInvariant()}};scope=@{selected_exact_ids=$selected;deferred_ids=@($allIds|Where-Object{$_ -cnotin $selected});three_carriers_share_one_new_work_identity=$true;geometry_navigation_native_29_unchanged=$true;original_six_routes_and_native_bodies_unchanged=$true;daily_dialogs_no_task_effects=$true;not_yet_Field_or_formal_acceptance=$true;same_person_and_four_authored_phase_cells_approved=$true;loop_motion_observed=$false;actual_Field_motion_acceptance_pending=$true;carrier_authored_walk_faces='right';only_three_new_carrier_mirroring_adapted=$true;carrier_invert_patrol_facing=$false}}
$roleFile=WJ 'roles_manifest.json' $roleManifest;$roleSHA=Sha $roleFile
$indexOld=[IO.File]::ReadAllText((Disk $DI));if([regex]::Matches($indexOld,'PENDING_AD_ART_AND_DIALOG_SOURCE_PUBLICATION').Count -ne 1 -or [regex]::Matches($indexOld,'const FORMAL_ENABLED := false').Count -ne 1){throw 'AD_PENDING_FALSE_AUTHORITY_CHANGED'}
$indexFalse=$indexOld.Replace('PENDING_AD_ART_AND_DIALOG_SOURCE_PUBLICATION',$roleSHA);$indexTrue=$indexFalse.Replace('const FORMAL_ENABLED := false','const FORMAL_ENABLED := true')
if($indexTrue.Replace('const FORMAL_ENABLED := true','const FORMAL_ENABLED := false') -cne $indexFalse){throw 'AD_TRUE_SOLE_BOOL_INVERSE'}
$diFalseFile=W 'AD_index_false_candidate.gd' $indexFalse;$diTrueFile=W 'AD_index_true_candidate.gd' $indexTrue;$diFalseSHA=Sha $diFalseFile;$diTrueSHA=Sha $diTrueFile
$newCode=@{$B=$pins[$package+'Bundle_candidate.gd'];$H=$pins[$package+'Harbour_candidate.gd']}
$templeOld=J $oldTempleBinding;$templeNew=Clone $templeOld
if($templeOld.source_delta[$H] -cne $pins[$H]){throw 'TEMPLE_H_PREDECESSOR_CHANGED'}
$templeNew.source_delta[$H]=$newCode[$H]
$templeNew['docks_roles_ad_source_successor']=@{prior_path=$oldTempleBinding;prior_sha256=$pins[$oldTempleBinding];changed_source=$H;old_sha256=$pins[$H];new_sha256=$newCode[$H];geometry_assets_publication_first_final_unchanged=$true}
$templeInverse=Clone $templeNew;$templeInverse.Remove('docks_roles_ad_source_successor')|Out-Null;$templeInverse.source_delta[$H]=$pins[$H]
if(!(Same $templeInverse $templeOld)){throw 'TEMPLE_WHOLE_INVERSE_FAILED'}
$bindingFile=WJ 'temple_binding.json' $templeNew;$bindingSHA=Sha $bindingFile
$helperOld=[IO.File]::ReadAllText((Disk $templeHelper));$helperNew=$helperOld.Replace($oldTempleBinding,$newTempleBinding).Replace($pins[$oldTempleBinding],$bindingSHA)
if($helperNew.Replace($newTempleBinding,$oldTempleBinding).Replace($bindingSHA,$pins[$oldTempleBinding]) -cne $helperOld -or $helperNew -ceq $helperOld){throw 'TEMPLE_ONLY_TWO_LITERALS_INVERSE'}
$helperFile=W 'Temple_helper_candidate.gd' $helperNew;$helperSHA=Sha $helperFile
$deps=Clone $roleSources;AddExact $deps $module $pins[$package+'Docks_roles_facing_candidate.gd'];AddExact $deps $roleManifestPath $roleSHA
function ChangeManifest($old,[string]$priorSHA,[bool]$isDocks){
 $next=Clone $old;$changes=[ordered]@{};$updates=Clone $newCode
 if($old.legacy_source_sha256.Contains($templeHelper)){$updates[$templeHelper]=$helperSHA;$updates[$newTempleBinding]=$bindingSHA}
 if($isDocks){foreach($p in $deps.Keys){AddExact $updates $p $deps[$p]}}
 foreach($p in $updates.Keys){
  if($old.artifacts.Contains($p)){if($old.artifacts[$p] -cne $updates[$p]){throw 'IMMUTABLE_ARTIFACT_DEPENDENCY_COLLISION'};continue}
  $category=if($old.legacy_source_sha256.Contains($p)){'legacy_source_sha256'}elseif($old.runtime_authority_sha256.Contains($p)){'runtime_authority_sha256'}else{'legacy_source_sha256'}
  $exists=$old[$category].Contains($p);if(!$exists -and $newCode.Contains($p)){continue}
  $prior=if($exists){$old[$category][$p]}else{$null}
  if($newCode.Contains($p) -and $prior -cne $pins[$p]){throw 'OWNED_RUNTIME_PREDECESSOR_CHANGED'}
  if($exists -and $prior -ceq $updates[$p]){continue}
  $changes[$p]=@{category=$category;existed=$exists;old_sha256=$prior;new_sha256=$updates[$p]};$next[$category][$p]=$updates[$p]
 }
 $next['docks_roles_ad_source_successor']=@{prior_sha256=$priorSHA;source_changes=$changes;independent_baseline_path=$baselinePath;independent_baseline_sha256=$pins[$baselinePath];native_artifacts_geometry_and_publication_unchanged=$true}
 $inverse=Clone $next;$inverse.Remove('docks_roles_ad_source_successor')|Out-Null
 foreach($p in $changes.Keys){$d=$changes[$p];if($d.existed){$inverse[$d.category][$p]=$d.old_sha256}else{$inverse[$d.category].Remove($p)|Out-Null}}
 if(!(Same $inverse $old) -or !(Same $next.artifacts $old.artifacts)){throw 'SIX_MANIFEST_WHOLE_INVERSE_FAILED'}
 foreach($p in $old.artifacts.Keys){CheckHash $p $old.artifacts[$p]}
 return @{manifest=$next;changes=$changes}
}
$facts=@{}
foreach($key in @($manifestPaths.Keys|Sort-Object -CaseSensitive)){$path=$manifestPaths[$key];$old=J $path;$fact=ChangeManifest $old $oldCityPins[$key] ($key -in @($docks,'AA','AC'));$file=WJ ($key+'/manifest.json') $fact.manifest;$fact['target']=$path;$fact['sha256']=Sha $file;$fact['candidate_path']=$package+'staged/'+$key+'/manifest.json';$facts[$key]=$fact}
$biOld=[IO.File]::ReadAllText((Disk $BI));$biNew=$biOld
foreach($key in @('ch4_s0_luoyang_gate','ch4_s1_luoyang_yamen',$docks,'ch4_s3_luoyang_market')){if([regex]::Matches($biNew,$oldCityPins[$key]).Count -ne 1){throw 'UNIQUE_BI_PIN_REQUIRED'};$biNew=$biNew.Replace($oldCityPins[$key],$facts[$key].sha256)}
$biInverse=$biNew;foreach($key in @('ch4_s0_luoyang_gate','ch4_s1_luoyang_yamen',$docks,'ch4_s3_luoyang_market')){$biInverse=$biInverse.Replace($facts[$key].sha256,$oldCityPins[$key])};if($biInverse -cne $biOld){throw 'BI_FOUR_LITERAL_INVERSE'}
$biFile=W 'Bundle_index_candidate.gd' $biNew;$biSHA=Sha $biFile
$otherIndexFacts=@{}
foreach($pair in @(@($AI,'AA'),@($CI,'AC'))){$p=$pair[0];$key=$pair[1];$old=[IO.File]::ReadAllText((Disk $p));if([regex]::Matches($old,$oldCityPins[$key]).Count -ne 1 -or [regex]::Matches($old,'const FORMAL_ENABLED=true').Count -ne 1){throw 'EXISTING_TRUE_INDEX_PREDECESSOR_CHANGED'};$next=$old.Replace($oldCityPins[$key],$facts[$key].sha256);if($next.Replace($facts[$key].sha256,$oldCityPins[$key]) -cne $old){throw 'EXISTING_INDEX_ONLY_ONE_LITERAL_INVERSE'};$file=W ($key+'_index_candidate.gd') $next;$otherIndexFacts[$p]=@{file=$file;sha256=(Sha $file);candidate_path=$package+'staged/'+$key+'_index_candidate.gd'}}
$authority=@{$BI=$biSHA;$AI=$otherIndexFacts[$AI].sha256;$CI=$otherIndexFacts[$CI].sha256;$DI=$diFalseSHA}
function FromManifest($m,[string]$mp,[string]$ms,[bool]$isDocks,[string]$adHash){$set=Clone $m.legacy_source_sha256;foreach($cat in @('runtime_authority_sha256','artifacts')){foreach($p in $m[$cat].Keys){AddExact $set $p $m[$cat][$p]}};AddExact $set $BI $biSHA;AddExact $set $mp $ms;if($isDocks){foreach($p in @($AI,$CI)){AddExact $set $p $authority[$p]};AddExact $set $DI $adHash};if(!(Same (CloseImports (Clone $set)) $set)){throw 'EXISTING_IMPORT_REMAP_CLOSURE_MISSING'};return $set}
$base=J $baselinePath
if($base.source_sha256.Count -ne 1481 -or $base.source_sha256[$B] -cne $pins[$B] -or $base.source_sha256[$H] -cne $pins[$H] -or $base.source_sha256[$acManifestPath] -cne $oldCityPins.AC){throw 'INDEPENDENT_AC1481_BASELINE_CHANGED'}
$disabled=Clone $base.source_sha256
foreach($p in $facts.AC.changes.Keys){$disabled[$p]=$facts.AC.changes[$p].new_sha256}
foreach($p in $authority.Keys){$disabled[$p]=$authority[$p]};$disabled[$acManifestPath]=$facts.AC.sha256
if(!(Same (FromManifest $facts.AC.manifest $acManifestPath $facts.AC.sha256 $true $diFalseSHA) $disabled)){throw 'AD_FALSE_INDEPENDENT_SET_EQUATION'}
$candidate=Clone $disabled;$formal=Clone $disabled;$formal[$DI]=$diTrueSHA
if(!(Same (FromManifest $facts.AC.manifest $acManifestPath $facts.AC.sha256 $true $diTrueSHA) $formal)){throw 'AD_TRUE_INDEPENDENT_SET_EQUATION'}
$inverse=Clone $disabled;$inverse.Remove($DI)|Out-Null
foreach($p in $facts.AC.changes.Keys){$d=$facts.AC.changes[$p];if($d.existed){$inverse[$p]=$d.old_sha256}else{$inverse.Remove($p)|Out-Null}}
foreach($p in @($BI,$AI,$CI,$acManifestPath)){$inverse[$p]=$base.source_sha256[$p]}
if(!(Same $inverse $base.source_sha256)){throw 'AC1481_WHOLE_SOURCE_MAP_INVERSE'}
$formalInverse=Clone $formal;$formalInverse[$DI]=$diFalseSHA;if(!(Same $formalInverse $candidate)){throw 'AD_TRUE_ONLY_EXTERNAL_INDEX_HASH'}
$mapFacts=@{}
foreach($phase in @('false','candidate','true')){$map=if($phase -ceq 'true'){$formal}else{$disabled};$file=WJ ('expected_sources_'+$phase+'.json') @{status='INDEPENDENT_AC1481_PLUS_FINITE_AD_PRESENTATION_SOURCE_DELTA';phase=$phase;baseline_path=$baselinePath;baseline_sha256=$pins[$baselinePath];source_sha256=$map};$mapFacts[$phase]=@{path=$package+'staged/expected_sources_'+$phase+'.json';sha256=(Sha $file);count=$map.Count;whole_inverse=$true}}
$otherMapPins=@{ch4_s0_luoyang_gate='aff3954f647340528713ac25512e310e6cbab5343e6a952d125530cdbcc79b30';ch4_s1_luoyang_yamen='2d9aa38820a0cce113596a5b05c3f001bafb6b61e55a3465d553bcf2b54d4852';ch4_s3_luoyang_market='3f009486a487255657d00ff5c0c0c852834ea90587a47a6afa8461dd2d23906d'}
foreach($id in $otherMapPins.Keys){$path=$priorPackage+$id+'/expected_sources.json';CheckHash $path $otherMapPins[$id];$old=J $path;$next=Clone $old.source_sha256;foreach($p in $facts[$id].changes.Keys){$next[$p]=$facts[$id].changes[$p].new_sha256};$next[$BI]=$biSHA;$next[$facts[$id].target]=$facts[$id].sha256
 if(!(Same (FromManifest $facts[$id].manifest $facts[$id].target $facts[$id].sha256 $false '') $next)){throw 'OTHER_CITY_INDEPENDENT_SET_EQUATION'}
 foreach($p in $next.Keys){if($p -cne $newTempleBinding -and $p -match 'docks_roles_20261019ad|docks_roles_index_20261019ad'){throw 'OTHER_CITY_AD_SOURCE_LEAK'}}
 $back=Clone $next;foreach($p in $facts[$id].changes.Keys){$d=$facts[$id].changes[$p];if($d.existed){$back[$p]=$d.old_sha256}else{$back.Remove($p)|Out-Null}};$back[$BI]=$old.source_sha256[$BI];$back[$facts[$id].target]=$old.source_sha256[$facts[$id].target];if(!(Same $back $old.source_sha256)){throw 'OTHER_CITY_WHOLE_SOURCE_INVERSE'}
 $file=WJ ($id+'/expected_sources.json') @{status='INDEPENDENT_AC_BASELINE_ONLY_OWNED_RUNTIME_TEMPLE_SOURCE_SUCCESSION';baseline_path=$path;baseline_sha256=$otherMapPins[$id];source_sha256=$next};$mapFacts[$id]=@{path=$package+'staged/'+$id+'/expected_sources.json';sha256=(Sha $file);count=$next.Count;whole_inverse=$true}}
$targets=@(@{target=$module;old_sha256=$pins[$module];candidate_path=$package+'Docks_roles_facing_candidate.gd';candidate_sha256=$pins[$package+'Docks_roles_facing_candidate.gd']},@{target=$B;old_sha256=$pins[$B];candidate_path=$package+'Bundle_candidate.gd';candidate_sha256=$newCode[$B]},@{target=$H;old_sha256=$pins[$H];candidate_path=$package+'Harbour_candidate.gd';candidate_sha256=$newCode[$H]},@{target=$templeHelper;old_sha256=$pins[$templeHelper];candidate_path=$package+'staged/Temple_helper_candidate.gd';candidate_sha256=$helperSHA},@{target=$BI;old_sha256=$pins[$BI];candidate_path=$package+'staged/Bundle_index_candidate.gd';candidate_sha256=$biSHA},@{target=$DI;old_sha256=$pins[$DI];candidate_path=$package+'staged/AD_index_false_candidate.gd';candidate_sha256=$diFalseSHA},@{target=$roleManifestPath;old_sha256=$pins[$roleManifestPath];candidate_path=$package+'staged/roles_manifest.json';candidate_sha256=$roleSHA})
foreach($p in $otherIndexFacts.Keys){$f=$otherIndexFacts[$p];$targets+=@{target=$p;old_sha256=$pins[$p];candidate_path=$f.candidate_path;candidate_sha256=$f.sha256}}
foreach($key in $facts.Keys){$f=$facts[$key];$targets+=@{target=$f.target;old_sha256=$oldCityPins[$key];candidate_path=$f.candidate_path;candidate_sha256=$f.sha256}}
$patch="*** Begin Patch`n";foreach($t in $targets|Where-Object target -like '*.gd'){$lines=@(& git -c core.autocrlf=false diff --no-index --unified=3 -- (Disk $t.target) (Disk $t.candidate_path));if($LASTEXITCODE -ne 1){throw 'CODE_DIFF_REQUIRED'};$patch+='*** Update File: '+(Disk $t.target).Replace('\','/')+"`n";$hunk=$false;foreach($line in $lines){if($line.StartsWith('@@')){$hunk=$true;$patch+="@@`n"}elseif($hunk){if($line.StartsWith('\ No newline')){throw 'CODE_NEWLINE_DOMAIN_CHANGED'};$patch+=$line+"`n"}}};$patchFile=W 'minimal_false_code_deployment.apply_patch' ($patch+"*** End Patch`n")
$flipFile=W 'sole_bool_true_after_candidate.apply_patch' ("*** Begin Patch`n*** Update File: "+(Disk $DI).Replace('\','/')+"`n@@`n-const FORMAL_ENABLED := false`n+const FORMAL_ENABLED := true`n*** End Patch`n")
$receipt=@{status='STAGED_ONLY_NOT_DEPLOYED';approved_role_ids=$selected;unique_new_pngs=$textures.Count;targets=$targets;new_files=@{$newTempleBinding=@{candidate_path=$newTempleBinding;sha256=$bindingSHA}};maps=$mapFacts;roles_manifest_sha256=$roleSHA;AD_index_false_sha256=$diFalseSHA;AD_index_true_sha256=$diTrueSHA;six_manifest_whole_inverses=$true;all_18_original_native_artifacts_and_geometry_unchanged=$true;temple_whole_and_two_literal_inverse=$true;independent_AC1481_source_map_whole_inverse=$true;false_and_flag_candidate_source_maps_equal=$true;formal_only_external_AD_index_hash=$true;all_import_remap_closure_checked=$true;other_three_cities_AD_compile_sources_absent=$true;C_Field_NPC_GS_Router_x_immutable_authors_unchanged=$true;input_path=$AdmissionPath;input_sha256=$AdmissionSHA;code_patch_sha256=(Sha $patchFile);sole_bool_patch_sha256=(Sha $flipFile);no_engine_collector_canonical_or_save_writes=$true}
WJ 'stage_receipt.json' $receipt|Out-Null
$receipt|ConvertTo-Json -Depth 12
