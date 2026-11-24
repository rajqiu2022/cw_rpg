param([string]$Workspace='F:\Code\RPG_GAME')
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
# Retry1: exact JSON integral floating numbers canonicalize to int64 only for comparison. Bool and fractional numbers remain untouched.
# NEW-only mechanical staging. No engine, live metadata or executable writes.
$game=Join-Path $Workspace 'game'
$pkg='res://build/luoyang_market_two_shops_20261021ao_system01/'
$outPath=$pkg+'staged_retry1/'
$stageInputPath=$pkg+'source_staging_input_READY.json'
$priorPath='res://build/luoyang_estate_courtyard_20261021an_system01/arrival_compiled_geometry_retry1/staged/receipt.json'
$B='res://scripts/city/luoyang_precomputed_bundle_20261018r.gd'
$G='res://scripts/city/luoyang_assembled_interiors_20261016g.gd'
$BI='res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd'
$EI='res://scripts/city/luoyang_estate_index_20261021am.gd'
$AI='res://scripts/city/luoyang_market_two_shops_index_20261021ao.gd'
$FamilyManifestPath='res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json'
$REG='res://data/maps/luoyang_estate_rooms_20261021am/registry.json'
$SNAP=$pkg+'before/registry_AN_167F.json'
$AO='res://data/maps/luoyang_market_two_shops_20261021ao/runtime/ch4_s3_luoyang_market/manifest.json'
$T='res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s3_luoyang_market/manifest.json'
$IDS=@('ch4_s0_luoyang_gate','ch4_s1_luoyang_yamen','ch4_s2_canal_docks','ch4_s3_luoyang_market')
function Disk([string]$p){if(!$p.StartsWith('res://') -or $p.Contains('..')){throw "RESOURCE_PATH:$p"};Join-Path $game $p.Substring(6)}
function SHA([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function Check([string]$p,[string]$h){if($h -cnotmatch '^[0-9a-f]{64}$' -or (SHA (Disk $p)) -cne $h){throw "SOURCE_CHANGED:$p"}}
function J([string]$p){Get-Content -Raw -LiteralPath (Disk $p)|ConvertFrom-Json -AsHashtable}
function Clone($v){$v|ConvertTo-Json -Depth 100 -Compress|ConvertFrom-Json -AsHashtable}
function Canon($v){if($v -is [Collections.IDictionary]){$r=[ordered]@{};foreach($k in @($v.Keys|Sort-Object -CaseSensitive)){$r[$k]=Canon $v[$k]};return $r};if($v -is [array]){return ,@($v|ForEach-Object{Canon $_})};if(($v -is [double] -or $v -is [single]) -and [double]::IsFinite([double]$v) -and [Math]::Floor([double]$v) -eq [double]$v -and [decimal]$v -ge [decimal][long]::MinValue -and [decimal]$v -le [decimal][long]::MaxValue){return [long]$v};return $v}
function Same($a,$b){((Canon $a)|ConvertTo-Json -Depth 100 -Compress) -ceq ((Canon $b)|ConvertTo-Json -Depth 100 -Compress)}
function W([string]$name,[string]$text){$p=Disk ($outPath+$name);if(Test-Path -LiteralPath $p){throw "NO_OVERWRITE:$p"};[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($p))|Out-Null;[IO.File]::WriteAllText($p,$text,[Text.UTF8Encoding]::new($false));return $outPath+$name}
function WJ([string]$name,$value){W $name (($value|ConvertTo-Json -Depth 100)+"`n")}
if(Test-Path -LiteralPath (Disk $outPath)){throw 'NEW_STAGE_ONLY'}
$stageInput=J $stageInputPath
if($stageInput.status -cne 'READY_AO_ACTUAL_GEOMETRY_AND_THREE_TEXTURE_IMPORTS'){throw 'ACTUAL_INPUT_PENDING'}
Check $priorPath $stageInput.prior_receipt_sha256
$prior=J $priorPath
foreach($row in $prior.targets){Check $row.target $row.candidate_sha256}
Check $stageInput.publication.path $stageInput.publication.sha256
$pub=J $stageInput.publication.path
if(!$pub.passed -or !$pub.published -or $pub.native_count -ne 24 -or $pub.district_count -ne 36 -or !$pub.geometry.passed -or !$pub.geometry.full87517 -or !$pub.mask_delta.passed -or !$pub.two_room_returns.ok -or !$pub.two_room_returns.all_twelve_whole_inverse -or !(Same $pub.source_first $pub.source_final)){throw 'EXACT_ACTUAL_PUBLICATION'}
foreach($p in $pub.source_first.Keys){Check $p $pub.source_first[$p]}
foreach($p in $pub.artifacts.Keys){Check $p $pub.artifacts[$p]}
foreach($p in $pub.two_room_returns.artifacts.Keys){Check $p $pub.two_room_returns.artifacts[$p]}
Check ($pkg+'author_READY.json') '227735f42114e843e62109b127a3c57d4a7b9ffdb4e545799ba9d50dc77cc849'
$author=J ($pkg+'author_READY.json')
$targets=[Collections.Generic.List[object]]::new();$changed=[ordered]@{}
function Target([string]$target,[string]$old,[string]$file){if($old -ceq 'ABSENT'){if(Test-Path -LiteralPath (Disk $target)){throw "EXPECTED_ABSENT:$target"}}else{Check $target $old};$row=@{target=$target;old_sha256=$old;candidate_path=$file;candidate_sha256=SHA (Disk $file)};$targets.Add($row);$changed[$target]=@{old=$old;next=$row.candidate_sha256};return $row}
foreach($row in $stageInput.code_rows){Check $row.candidate_path $row.candidate_sha256;$null=Target $row.target $row.old_sha256 $row.candidate_path}
if($targets.Count -ne 2 -or !$changed.Contains($B) -or !$changed.Contains($G)){throw 'ONLY_TWO_FUNCTIONAL_EXECUTABLES'}
$null=Target $REG '167f4a16816224974f4c41b1b753cf7257bfdd8a9f096dbc0c79351c93b88d4c' $pub.two_room_returns.registry_candidate_path
$registry=J $pub.two_room_returns.registry_candidate_path
$snap=J $SNAP
$regInverse=Clone $registry;$regInverse.Remove('ao_return_successor')
foreach($id in $registry.ao_return_successor.room_ids){$regInverse.rooms[$id]=Clone $registry.rooms[$id].ao_parent_row}
if(!(Same $regInverse $snap) -or $registry.rooms.Count -ne 12){throw 'EXACT_TWO_ROOM_REGISTRY_WHOLE_INVERSE'}
# Family consumes B/G, its current registry and the one new immutable parent.
# It does not acquire all two-shop media, CPU history or room235 sources.
$fmOld=SHA (Disk $FamilyManifestPath);$fm=J $FamilyManifestPath;$fmParent=Clone $fm
foreach($p in @($B,$G,$REG)){
 if($fm.source_sha256[$p] -cne $changed[$p].old){throw "FAMILY_PRIOR_PIN:$p"};$fm.source_sha256[$p]=$changed[$p].next
}
foreach($p in @($B,$G)){if($fm.runtime_source_successions[$p].next -cne $changed[$p].old){throw 'FAMILY_RUNTIME_SUCCESSION_PRIOR'};$fm.runtime_source_successions[$p].next=$changed[$p].next}
$fm.registry_sha256=$changed[$REG].next
if($fm.source_sha256.Contains($SNAP)){throw 'NEW_PARENT_SNAPSHOT_LEAF_ONLY'}
$fm.source_sha256[$SNAP]='167f4a16816224974f4c41b1b753cf7257bfdd8a9f096dbc0c79351c93b88d4c'
$fm.ao_two_shop_source_successor=@{prior_family_manifest_sha256=$fmOld;registry_old=$changed[$REG].old;registry_next=$changed[$REG].next;unchanged_estate_geometry_and_mansion=$true;new_source_only=$SNAP}
$fmBack=Clone $fm;$fmBack.Remove('ao_two_shop_source_successor');$fmBack.source_sha256.Remove($SNAP)
foreach($p in @($B,$G,$REG)){$fmBack.source_sha256[$p]=$changed[$p].old}
foreach($p in @($B,$G)){$fmBack.runtime_source_successions[$p].next=$changed[$p].old}
$fmBack.registry_sha256=$changed[$REG].old
if(!(Same $fmBack $fmParent) -or $fm.source_sha256.Count -ne ($fmParent.source_sha256.Count+1)){throw 'FAMILY_ONLY_327_PLUS_ONE_WHOLE_INVERSE'}
$fmFile=WJ 'estate_manifest.json' $fm;$null=Target $FamilyManifestPath $fmOld $fmFile
$eiOld=SHA (Disk $EI);$eiText=[IO.File]::ReadAllText((Disk $EI))
if(!$eiText.Contains('const FORMAL_ENABLED=true') -or [regex]::Matches($eiText,$fmOld).Count -ne 1){throw 'FAMILY_CURRENT_TRUE_INDEX'}
$eiFile=W 'estate_index_true.gd' ($eiText.Replace($fmOld,$changed[$FamilyManifestPath].next));$null=Target $EI $eiOld $eiFile
# Fixed actual texture proof inputs: one two-PNG run and one independent walk.
$media=[ordered]@{};$proofs=[ordered]@{}
foreach($proof in $stageInput.import_proofs){
 Check $proof.path $proof.sha256;$r=J $proof.path
 if(!$r.passed -or $r.failures.Count -ne 0 -or !(Same $r.source_first $r.source_final)){throw "IMPORT_PROOF_FALSE_OR_UNSTABLE:$($proof.path)"}
 foreach($p in $r.source_first.Keys){
  if(!$p.StartsWith('res://')){throw 'ISOLATED_SOURCE_DOMAIN'}
  $isolated=$proof.isolate_root+$p.Substring(6);Check $isolated $r.source_first[$p]
  if($p -in @('res://prepared_READY.json','res://project.godot','res://verify_two_frontages_READY.gd','res://verify_one_walk_READY.gd')){$proofs[$isolated]=$r.source_first[$p]}
 }
 foreach($row in $r.rows){
  if(!$row.full_rgba_exact -or !$row.params23 -or !$row.zero_mipmaps -or $row.detect3d_compress_to -ne 0 -or $media.Contains($row.texture)){throw 'EXACT_IMPORTED_RGBA23_NO_MIP_NO_DUPLICATE'}
  foreach($pair in @(@($row.texture,$row.source_sha256),@($row.import_path,$row.import_sha256),@($row.compiled_path,$row.compiled_sha256))){Check $pair[0] $pair[1];$media[$pair[0]]=$pair[1]}
 }
 $proofs[$proof.path]=$proof.sha256
}
$textures=@($author.assets.apothecary.texture,$author.assets.study.texture,$pub.walk_candidate.future_path)
if($stageInput.import_proofs.Count -ne 2 -or $media.Count -ne 9){throw 'TWO_ACTUAL_RUNS_THREE_TEXTURE_TRIPLES_ONLY'}
foreach($p in $textures){if(!$media.Contains($p)){throw "ACTUAL_TEXTURE_MISSING:$p"}}
if($media[$pub.walk_candidate.future_path] -cne $pub.walk_candidate.sha256){throw 'PUBLISHED_MASK_IMPORTED_EXACT'}
# Shared room hash-domain additions are not recursively loaded Texture inputs.
$shared=[ordered]@{$SNAP='167f4a16816224974f4c41b1b753cf7257bfdd8a9f096dbc0c79351c93b88d4c'}
foreach($id in $registry.ao_return_successor.room_ids){foreach($p in $registry.rooms[$id].source_sha256.Keys){$shared[$p]=$registry.rooms[$id].source_sha256[$p]}}
$runtime=[ordered]@{}
foreach($p in $pub.source_first.Keys){$runtime[$p]=$pub.source_first[$p]}
foreach($p in $pub.artifacts.Keys){$runtime[$p]=$pub.artifacts[$p]}
foreach($p in $media.Keys){$runtime[$p]=$media[$p]}
foreach($p in $proofs.Keys){$runtime[$p]=$proofs[$p]}
$runtime[$stageInput.publication.path]=$stageInput.publication.sha256
# No runtime will replay the CPU source-first old B/current registry hash.
foreach($p in $changed.Keys){if($runtime.Contains($p)){$runtime[$p]=$changed[$p].next};if($shared.Contains($p)){$shared[$p]=$changed[$p].next}}
function AddLeaf($m,[string]$p,[string]$h,$delta){
 if($p -ceq $AI -or $p -ceq $AO -or $p -ceq $BI -or $p -ceq $EI){throw "EXTERNAL_AUTHORITY_CYCLE:$p"}
 foreach($kind in @('legacy_source_sha256','runtime_authority_sha256','artifacts')){if($m[$kind].Contains($p)){
  $old=$m[$kind][$p];if($old -ceq $h){return};if(!$changed.Contains($p) -or $changed[$p].old -cne $old -or $changed[$p].next -cne $h){throw "UNAUTHORIZED_EXISTING_PIN:$p"}
  $delta.Add(@{kind=$kind;path=$p;old=$old;next=$h;existed=$true});$m[$kind][$p]=$h;return
 }}
 $kind=if($p.StartsWith('res://data/maps/luoyang_layout_bundle_20261018t_retry2/') -or $p.StartsWith('res://data/maps/luoyang_layout_rooms_20261018t/')){'runtime_authority_sha256'}else{'legacy_source_sha256'}
 $m[$kind][$p]=$h;$delta.Add(@{kind=$kind;path=$p;old=$null;next=$h;existed=$false})
}
$manifestProof=[ordered]@{};$manifestData=[ordered]@{}
foreach($row in @($prior.targets|Where-Object {$_.target.EndsWith('/manifest.json') -and $_.target -cne $FamilyManifestPath})){
 Check $row.target $row.candidate_sha256;$m=J $row.target;$parent=Clone $m;$delta=[Collections.Generic.List[object]]::new()
 foreach($p in @($B,$G,$REG,$FamilyManifestPath)){foreach($kind in @('legacy_source_sha256','runtime_authority_sha256')){if($m[$kind].Contains($p)){AddLeaf $m $p $changed[$p].next $delta}}}
 if($m.scene_id -cne 'ch4_s0_luoyang_gate'){foreach($p in $shared.Keys){AddLeaf $m $p $shared[$p] $delta}}
 if($m.scene_id -ceq 'ch4_s3_luoyang_market'){foreach($p in $runtime.Keys){AddLeaf $m $p $runtime[$p] $delta}}
 $m.ao_source_successor=@{status='EXACT_TWO_SHOP_SOURCE_EPOCH';prior_manifest_sha256=$row.candidate_sha256;delta=$delta;old_geometry_and_three_native_artifacts_unchanged=$true}
 $back=Clone $m;$back.Remove('ao_source_successor');foreach($d in $delta){if($d.existed){$back[$d.kind][$d.path]=$d.old}else{$back[$d.kind].Remove($d.path)}}
 if(!(Same $back $parent) -or !(Same $m.artifacts $parent.artifacts) -or !(Same $m.layout_proof $parent.layout_proof)){throw 'SIX_OLD_MANIFESTS_WHOLE_INVERSE_AND_18_ARTIFACTS'}
 $file=WJ ('manifests/'+$targets.Count+'.json') $m;$null=Target $row.target $row.candidate_sha256 $file
 $manifestProof[$row.target]=@{whole_inverse=$true;source_delta=$delta;geometry_native_unchanged=$true};$manifestData[$row.target]=$m
}
if($manifestProof.Count -ne 6){throw 'EXACT_SIX_EXISTING_MANIFESTS'}
# Active AO keeps its old T native parent as runtime authority, not a legacy
# ROOT exception; its own new native artifacts remain exactly three.
$active=Clone $manifestData[$T];$activeParent=Clone $active
$active.geometry_proof_basis='AO_EXACT_SHARED_FRONTAGE_AND_WALL_TO_TWO_SHOPS'
$active.author_path=$pkg+'author_READY.json';$active.author_sha256='227735f42114e843e62109b127a3c57d4a7b9ffdb4e545799ba9d50dc77cc849'
$active.ao_exact_two_for_two=$true;$active.mask_sha256=$pub.walk_candidate.rgba_sha256
foreach($p in $active.artifacts.Keys){$active.runtime_authority_sha256[$p]=$active.artifacts[$p]}
foreach($p in $pub.artifacts.Keys){$active.legacy_source_sha256.Remove($p);$active.runtime_authority_sha256.Remove($p)}
$active.artifacts=Clone $pub.artifacts
$active.layout_proof=@{passed=$true;full87517=$true;parent_full_proof_snapshot=$author.parent_geometry_proof_manifest_path;parent_full_proof_sha256=$author.parent_geometry_proof_manifest_sha256;affected_and_new_only=Clone $pub.geometry;full_RGBA_local_inverse=Clone $pub.mask_delta;old_unchanged_routes_inherited_not_retested=$true}
$active.ao_geometry_publication=@{path=$stageInput.publication.path;sha256=$stageInput.publication.sha256;native24=$true;district36=$true;all_twelve_room_inverse=$true;old_other18_city_artifacts_unchanged=$true;not_full_city_geometry_rerun=$true}
$activeFile=WJ 'ao_manifest.json' $active;$null=Target $AO 'ABSENT' $activeFile
$aiTemplate=[IO.File]::ReadAllText((Disk ($pkg+'AO_index_candidate_PENDING.gd')))
if([regex]::Matches($aiTemplate,'PENDING_FINAL_SOURCE_MANIFEST').Count -ne 1 -or !$aiTemplate.Contains('const FORMAL_ENABLED=false')){throw 'EXACT_AO_INDEX_TEMPLATE'}
$aiFalseText=$aiTemplate.Replace('PENDING_FINAL_SOURCE_MANIFEST',$changed[$AO].next)
$aiFalse=W 'ao_index_false.gd' $aiFalseText
$aiTrue=W 'ao_index_true.gd' ($aiFalseText.Replace('const FORMAL_ENABLED=false','const FORMAL_ENABLED=true'))
$null=Target $AI 'ABSENT' $aiTrue
foreach($path in @($BI,'res://scripts/city/luoyang_docks_district08_index_20261019aa.gd','res://scripts/city/luoyang_docks_workyard_index_20261019ac.gd')){
 $oldSha=SHA (Disk $path);$old=[IO.File]::ReadAllText((Disk $path));$next=$old
 foreach($p in $manifestProof.Keys){if($next.Contains($changed[$p].old)){$next=$next.Replace($changed[$p].old,$changed[$p].next)}}
 if($next -ceq $old){throw 'INDEX_REQUIRED_FINITE_MANIFEST_LITERAL'}
 $back=$next;foreach($p in $manifestProof.Keys){$back=$back.Replace($changed[$p].next,$changed[$p].old)}
 if($back -cne $old){throw 'INDEX_WHOLE_BYTE_TEXT_INVERSE'}
 $file=W ('code/'+[IO.Path]::GetFileName($path)) $next;$null=Target $path $oldSha $file
}
if($targets.Count -ne 16){throw 'EXACT_SIXTEEN_TARGETS'}
# Four independent old source maps plus finite declared changes. Only Market
# replaces its authoritative manifest identity; the other three native sets stay.
$maps=[ordered]@{}
foreach($id in $IDS){
 $oldRow=$prior.independent_expected_maps[$id];Check $oldRow.true_path $oldRow.true_sha256;$oldMap=J $oldRow.true_path
 $entry=@($prior.targets|Where-Object {$_.target.EndsWith('/'+$id+'/manifest.json') -and $_.target.Contains('luoyang_layout_bundle_')})[0]
 if($id -ceq 'ch4_s2_canal_docks'){$entry=@($prior.targets|Where-Object {$_.target.Contains('luoyang_docks_workyard_') -and $_.target.EndsWith('/manifest.json')})[0]}
 $cfg=$manifestData[$entry.target]
 function Expected($cfg,[string]$self,[string]$selfSha,[string]$aiSha){$v=[ordered]@{};foreach($kind in @('legacy_source_sha256','runtime_authority_sha256','artifacts')){foreach($p in $cfg[$kind].Keys){$v[$p]=$cfg[$kind][$p]}};foreach($p in $oldMap.source_sha256.Keys){if($p -in @($BI,$EI,'res://scripts/city/luoyang_docks_district08_index_20261019aa.gd','res://scripts/city/luoyang_docks_workyard_index_20261019ac.gd','res://scripts/city/luoyang_docks_roles_index_20261019ad.gd','res://scripts/city/luoyang_docks_shore_index_20261020ae.gd','res://scripts/city/luoyang_market_ground_index_20261020ae.gd')){$v[$p]=if($changed.Contains($p)){$changed[$p].next}else{$oldMap.source_sha256[$p]}}};$v[$self]=$selfSha;$v[$AI]=$aiSha;return $v}
 $falseMap=Clone $oldMap;$falseMap.source_sha256=Expected $cfg $entry.target $changed[$entry.target].next (SHA (Disk $aiFalse))
 $trueMap=Clone $falseMap;$trueMap.source_sha256[$AI]=$changed[$AI].next
 if($id -ceq 'ch4_s3_luoyang_market'){$trueMap.source_sha256=Expected $active $AO $changed[$AO].next $changed[$AI].next}
 # Independent finite inverse: every removed/replaced old source is an
 # explicit authorized metadata target or Market's replaced authority leaf.
 foreach($p in $oldMap.source_sha256.Keys){foreach($candidate in @($falseMap,$trueMap)){
  if(!$candidate.source_sha256.Contains($p)){if($id -cne 'ch4_s3_luoyang_market' -or $p -cne $T -or $candidate -eq $falseMap){throw "UNAUTHORIZED_SOURCE_REMOVAL:$p"};continue}
  if($candidate.source_sha256[$p] -cne $oldMap.source_sha256[$p] -and (!$changed.Contains($p) -or $changed[$p].old -cne $oldMap.source_sha256[$p] -or $candidate.source_sha256[$p] -cne $changed[$p].next)){throw "UNAUTHORIZED_SOURCE_REPLACEMENT:$p"}
 }}
 foreach($candidate in @($falseMap,$trueMap)){foreach($p in $candidate.source_sha256.Keys){
  if(!$oldMap.source_sha256.Contains($p) -and $p -cne $AI -and $p -cne $AO -and !$runtime.Contains($p) -and !$shared.Contains($p)){throw "UNDECLARED_NEW_SOURCE:$p"}
  # Mirror C's one-level sidecar/remap rule without collecting any scene.
  $side=$p+'.import';if(Test-Path -LiteralPath (Disk $side)){
   if(!$candidate.source_sha256.Contains($side)){throw "DECLARED_SOURCE_IMPORT_MISSING:$side"}
   $remap=[IO.File]::ReadAllText((Disk $side));foreach($match in [regex]::Matches($remap,'(?m)^path(?:\.[A-Za-z0-9_]+)?="(res://[^"\r\n]+)"\r?$')){if(!$candidate.source_sha256.Contains($match.Groups[1].Value)){throw "DECLARED_IMPORT_REMAP_MISSING:$p"}}
  }
 }}
 $fp=WJ ('maps/'+$id+'_false.json') $falseMap;$tp=WJ ('maps/'+$id+'_true.json') $trueMap
 $maps[$id]=@{false_path=$fp;false_sha256=SHA (Disk $fp);false_count=$falseMap.source_sha256.Count;true_path=$tp;true_sha256=SHA (Disk $tp);count=$trueMap.source_sha256.Count;prior_true_path=$oldRow.true_path;prior_true_sha256=$oldRow.true_sha256;old_plus_finite_delta=$true}
}
$patch="*** Begin Patch`n"
foreach($row in $targets){if($row.old_sha256 -ceq 'ABSENT'){$patch+='*** Add File: '+(Disk $row.target).Replace('\','/')+"`n";foreach($line in ([IO.File]::ReadAllText((Disk $row.candidate_path)).TrimEnd("`r","`n") -split "`n")){$patch+='+'+$line.TrimEnd("`r")+"`n"};continue};$diff=@(& git diff --no-index --no-color --text --unified=3 -- (Disk $row.target) (Disk $row.candidate_path) 2>$null);if($LASTEXITCODE -gt 1){throw 'READ_ONLY_DIFF_FAILED'};$patch+='*** Update File: '+(Disk $row.target).Replace('\','/')+"`n";$activeHunk=$false;foreach($line in $diff){if($line.StartsWith('@@')){$patch+="@@`n";$activeHunk=$true;continue};if($activeHunk -and !$line.StartsWith('\ No newline')){$patch+=$line+"`n"}}}
$patch+="*** End Patch`n";$patchFile=W 'canonical_deployment.apply_patch' $patch
$receipt=@{status='AO_EXACT_TWO_SHOP_SOURCE_SUCCESSOR_READY_NOT_DEPLOYED';prior_receipt=$priorPath;publication=$stageInput.publication;targets=$targets;changed_sources=$changed;patch_path=$patchFile;patch_sha256=SHA (Disk $patchFile);independent_expected_maps=$maps;existing_six_manifest_inverse=$manifestProof;all18_old_city_artifacts_and_proofs_unchanged=$true;new_AO_artifacts=$pub.artifacts;two_room_registry_whole_inverse=$true;other10_rooms_including_AN_mansion_unchanged=$true;family_source_count=$fm.source_sha256.Count;family_source_old_count=$fmParent.source_sha256.Count;AO_index_true_sha256=$changed[$AI].next;AO_index_false_path=$aiFalse;AO_index_false_sha256=SHA (Disk $aiFalse);import_proofs=$stageInput.import_proofs;media_triples=$media;shared_room_source_count=$shared.Count;Market_runtime_source_count=$runtime.Count;single_batch_true_deployment_required=$true;false_only_compile_or_collector_not_old_Market_door_runtime_credit=$true;no_engine_geometry_or_import_or_canonical_write=$true}
$file=WJ 'receipt.json' $receipt
Write-Output (@{receipt=$file;sha256=SHA (Disk $file);targets=$targets.Count;maps=$maps;patch=$patchFile;patch_sha256=SHA (Disk $patchFile)}|ConvertTo-Json -Depth 8)
