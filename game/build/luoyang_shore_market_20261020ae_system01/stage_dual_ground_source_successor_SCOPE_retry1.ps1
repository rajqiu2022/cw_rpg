param([string]$AdmissionPath,[string]$AdmissionSHA,[string]$Workspace='F:\Code\RPG_GAME')
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
# NEW-only metadata stage. Root must freeze actual ART/import + approved code first.
# Never runs an engine/collector, deploys, imports, or writes any old proof/save.
$gameRoot=Join-Path $Workspace 'game'
$pkg='res://build/luoyang_shore_market_20261020ae_system01/'
$stageRoot=Join-Path $gameRoot ($pkg.Substring(6)+'staged')
function Disk([string]$p){if(!$p.StartsWith('res://') -or $p.Contains('..')){throw 'RESOURCE_PATH'};return Join-Path $gameRoot $p.Substring(6)}
function Sha([string]$p){return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function Check([string]$p,[string]$s){if($s -cnotmatch '^[0-9a-f]{64}$' -or (Sha (Disk $p)) -cne $s){throw "SOURCE_CHANGED:$p"}}
function J([string]$p){return Get-Content -Raw -LiteralPath (Disk $p)|ConvertFrom-Json -AsHashtable}
function Clone($v){return $v|ConvertTo-Json -Depth 100 -Compress|ConvertFrom-Json -AsHashtable}
function Canon($v){if($v -is [Collections.IDictionary]){$o=[ordered]@{};foreach($k in @($v.Keys|Sort-Object -CaseSensitive)){$o[$k]=Canon $v[$k]};return $o};if($v -is [array]){return ,@($v|ForEach-Object{Canon $_})};return $v}
function Same($a,$b){return ((Canon $a)|ConvertTo-Json -Depth 100 -Compress) -ceq ((Canon $b)|ConvertTo-Json -Depth 100 -Compress)}
function True($v){return $v -is [bool] -and $v -eq $true}
function NumericPair($a,$b){if($a -isnot [array] -or $b -isnot [array] -or $a.Count -ne 2 -or $b.Count -ne 2){return $false};foreach($i in @(0,1)){if($a[$i] -is [bool] -or $a[$i] -is [string] -or $b[$i] -is [bool] -or $b[$i] -is [string] -or $null -eq $a[$i] -or $null -eq $b[$i] -or [double]$a[$i] -ne [double]$b[$i]){return $false}};return $true}
function AddExact($m,[string]$p,[string]$s){if($m.Contains($p) -and $m[$p] -cne $s){throw "SOURCE_COLLISION:$p"};$m[$p]=$s}
function W([string]$r,[string]$s){$p=[IO.Path]::GetFullPath((Join-Path $stageRoot $r));if(!$p.StartsWith($stageRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'WRITE_OUTSIDE_NEW_STAGE'};[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($p))|Out-Null;[IO.File]::WriteAllText($p,$s,[Text.UTF8Encoding]::new($false));return $p}
function WJ([string]$r,$v){return W $r (($v|ConvertTo-Json -Depth 100)+"`n")}
function ClosedImports($m){$result=Clone $m;foreach($p in @($m.Keys)){$ip=$p+'.import';if(!(Test-Path -LiteralPath (Disk $ip))){continue};AddExact $result $ip (Sha (Disk $ip));$text=[IO.File]::ReadAllText((Disk $ip));$remap=[regex]::Match($text,'(?ms)^\[remap\]\r?\n(.*?)(?=^\[|\z)').Groups[1].Value;foreach($hit in [regex]::Matches($remap,'(?m)^path[^=\r\n]*="([^"]+)"\r?$')){$rp=$hit.Groups[1].Value;AddExact $result $rp (Sha (Disk $rp))}};return $result}
if(Test-Path -LiteralPath $stageRoot){throw 'STAGED_EXISTS_PRESERVE_EVIDENCE'}
if(!$AdmissionPath -or !$AdmissionSHA){throw 'PENDING_ACTUAL_FROZEN_ADMISSION_NO_OUTPUT'}
Check $AdmissionPath $AdmissionSHA
$admission=J $AdmissionPath
if($admission.status -cne 'ROOT_APPROVED_AE_DUAL_GROUND_ACTUAL_SOURCE_INPUT' -or !(True $admission.geometry_unchanged) -or !(True $admission.main_new_imports_promoted) -or $admission.areas.Count -ne 2 -or $admission.code_candidates.Count -ne 3){throw 'PENDING_OR_UNAPPROVED_INPUT_NO_OUTPUT'}
$dockKinds=@($admission.approved_docks_kinds)
$twoKinds=@('cart_ruts','mooring_rope');$threeKinds=@('cart_ruts','mooring_rope','wet_shore')
if(!(Same @($dockKinds|Sort-Object -CaseSensitive) @($twoKinds|Sort-Object -CaseSensitive)) -and !(Same @($dockKinds|Sort-Object -CaseSensitive) @($threeKinds|Sort-Object -CaseSensitive))){throw 'EXACT_ROOT_APPROVED_TWO_OR_THREE_DOCKS_KINDS'}
if($dockKinds -ccontains 'wet_shore' -and !(True $admission.root_approved_clean_wet_derivative)){throw 'WET_REQUIRES_SEPARATE_EXPLICIT_ROOT_ADMISSION'}
$dock='ch4_s2_canal_docks';$market='ch4_s3_luoyang_market';$gate='ch4_s0_luoyang_gate';$yamen='ch4_s1_luoyang_yamen'
$B='res://scripts/city/luoyang_precomputed_bundle_20261018r.gd';$D='res://scripts/city/luoyang_district_life_20261016f.gd';$WATER='res://scripts/city/luoyang_harbour_water_patch_20261016.gd'
$BI='res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd';$AI='res://scripts/city/luoyang_docks_district08_index_20261019aa.gd';$CI='res://scripts/city/luoyang_docks_workyard_index_20261019ac.gd';$DI='res://scripts/city/luoyang_docks_roles_index_20261019ad.gd'
$roots=@{original='res://data/maps/luoyang_layout_bundle_20261018t_retry2/';AA='res://data/maps/luoyang_docks_district08_20261019aa/runtime/';AC='res://data/maps/luoyang_docks_workyard_20261019ac/runtime/'}
$prior='res://build/luoyang_docks_roles_20261019ad_system01/staged/'
$oldCode=@{$B='f8e6cd4e2cbd752581a8b4fc9386266d5da66b04623163fdaf2174f9b6aa8969';$D='0137393f3715558887f0c69598c4346e5a2e9cd9b1b9c1091f85ea12a0f6afea';$WATER='fa857da43bba211d18722358600cf479bd45f071d59efe12b0112013608c0cc2'}
$oldManifest=@{$gate='d1e7bef2f0967fa19fe434d099f8b06a50109a28ea821292df2bd79886f4fd3c';$yamen='e3593d8c011151c0aedf7c56f4897dceac4c1df12823bb12fa49339d70d5da6e';$dock='e364aef0c82f188a5bd92cce52a42d7ee9b789bb5e3288314b4f0a5d641d7d50';$market='19ae8d4445447ec2cfb2ebccb3364714c755a76fa4b1fa80ac9aa160f77a31fb';AA='233edb57548ed9a9e4aac70402c78e2bf2df5125bf99bcada5ae2941156a7d5c';AC='8ba25ab336ec0f70d53efb72d659235b220b9607d4d8ad05a39768868812314a'}
$baseline=@{$dock=@{path=$prior+'expected_sources_true.json';sha='7616845d1038235fc0a16d3c4106f324677d15e45f21ceb7a61618b7129645ff';count=1499};$market=@{path=$prior+$market+'/expected_sources.json';sha='7c7c3aee80d3d195ad9da934983ba053b7ac2ef2e46b8486c95210a0a252a6d5';count=1242};$gate=@{path=$prior+$gate+'/expected_sources.json';sha='c78a002cd7777084e99a6055c54c859a9838b100fd85a4cabd8c5f5d14de1116';count=709};$yamen=@{path=$prior+$yamen+'/expected_sources.json';sha='3a0dca8d725893d7c07a688c8980dcc3ec0c6ddf5ce7d4565e892246fd06ab98';count=1034}}
$indexPins=@{$BI='28d0da1833ca669ff08dcdc26d28fec826928897dcc3783a94f2881e5698df6f';$AI='36592f50fd217b3a6cc84921b2661654c2c8565875754a76d36020c34aedd7ea';$CI='8fb405d37522d2bae6812980f072ebc059980bc222969638441a5dd5c69b1ad2';$DI='7c8c1646e208aec2e77af6a4559a9846f73683bb864e5ec05a10947b0a2836b8'}
foreach($p in $indexPins.Keys){Check $p $indexPins[$p]}
$newCode=@{};$targets=@();$areaFacts=@{};$sharedProofs=@{}
foreach($p in $oldCode.Keys){Check $p $oldCode[$p];if(!$admission.code_candidates.Contains($p)){throw 'EXACT_THREE_CODE_TARGETS'};$r=$admission.code_candidates[$p];Check $r.path $r.sha256;if($r.sha256 -ceq $oldCode[$p]){throw 'MISSING_AUTHORED_CODE_CHANGE'};$newCode[$p]=$r.sha256;$targets+=@{target=$p;old_sha256=$oldCode[$p];candidate_path=$r.path;candidate_sha256=$r.sha256}}
foreach($row in $admission.areas){
 $id=$row.scene_id;if($id -cnotin @($dock,$market) -or $areaFacts.Contains($id)){throw 'EXACT_DOCKS_AND_MARKET_AREAS'}
 $family=if($id -ceq $dock){'docks_shore'}else{'market_ground'};$module='res://scripts/city/luoyang_'+$family+'_20261020ae.gd';$index='res://scripts/city/luoyang_'+$family+'_index_20261020ae.gd';$manifest='res://data/maps/luoyang_'+$family+'_20261020ae/manifest.json'
 foreach($r in @($row.manifest,$row.helper,$row.art_admission,$row.import_proof,$row.index_template)){Check $r.path $r.sha256}
 if($row.helper_target -cne $module -or $row.index_target -cne $index -or $row.manifest_target -cne $manifest){throw 'EXACT_AREA_CANONICAL_TARGETS'}
 foreach($p in @($module,$index,$manifest)){if(Test-Path -LiteralPath (Disk $p)){throw 'NEW_AREA_TARGET_ALREADY_EXISTS'}}
 $spec=J $row.manifest.path;$art=J $row.art_admission.path;$proof=J $row.import_proof.path
 if($spec.status -cne 'READY_VISUAL_ONLY_SOURCE_BOUND' -or $spec.scene_id -cne $id -or !(True $spec.geometry_unchanged) -or !(NumericPair $spec.design_size_px @(3072,2048)) -or $spec.overlays.Count -lt 1 -or $spec.overlays.Count -gt $(if($id -ceq $dock){16}else{8}) -or $spec.textures.Count -ne $(if($id -ceq $dock){$dockKinds.Count}else{1})){throw 'PENDING_OR_WRONG_VISUAL_SPEC'}
 if(!(True $art.approved) -or $art.scene_id -cne $id -or !(True $art.visual_only_no_new_rigid_body) -or !(Same $art.overlays $spec.overlays)){throw 'EXACT_ROOT_ART_LAYOUT_REQUIRED'}
 if(!(True $proof.passed) -or $proof.failures.Count -ne 0 -or !(Same $proof.source_first $proof.source_final)){throw 'ACTUAL_ISOLATED_IMPORT_PROOF'}
 $wantedKinds=if($id -ceq $dock){$dockKinds}else{@('market_wear')}
 $actualKinds=@($spec.textures.Values|ForEach-Object{$_.visual_kind})
 if(!(Same @($actualKinds|Sort-Object -CaseSensitive) @($wantedKinds|Sort-Object -CaseSensitive))){throw 'EXACT_SELECTED_VISUAL_KIND_SET'}
 $used=@{};foreach($entry in $spec.overlays){if($entry.Count -ne 7 -or !$spec.textures.Contains($entry.texture) -or $used.Contains($entry.id)){throw 'EXACT_SEVEN_KEY_LAYOUT_ROWS'};$used[$entry.id]=$true}
 foreach($path in $spec.textures.Keys){$matches=@($proof.rows|Where-Object texture -CEQ $path);if($matches.Count -ne 1){throw 'EXACT_IMPORT_TEXTURE_ROW'};$ir=$matches[0];$tr=$spec.textures[$path];if(!(True $ir.full_rgba_exact) -or !(True $ir.params23) -or !(True $ir.zero_mipmaps) -or $ir.detect3d_compress_to -is [bool] -or $ir.detect3d_compress_to -is [string] -or $ir.detect3d_compress_to -ne 0 -or $ir.import_path -cne ($path+'.import') -or !(NumericPair $ir.size $tr.size_px) -or $ir.rgba_sha256 -cne $tr.rgba_sha256){throw 'EXACT_RGBA23_MIP0_ROW'}
  foreach($pair in @(@($path,$ir.source_sha256),@($ir.import_path,$ir.import_sha256),@($ir.compiled_path,$ir.compiled_sha256))){Check $pair[0] $pair[1];if($spec.source_sha256[$pair[0]] -cne $pair[1]){throw 'TEXTURE_THREE_LEAVES_MISSING_FROM_SPEC'}}
 }
 foreach($p in $spec.source_sha256.Keys){if($p -cin @($module,$index,$manifest)){throw 'AREA_SELF_HASH_CYCLE'};Check $p $spec.source_sha256[$p]}
 foreach($r in @($row.art_admission,$row.import_proof)){if($spec.source_sha256[$r.path] -cne $r.sha256){throw 'ART_IMPORT_NOT_IN_IMMUTABLE_SOURCE_SET'}}
 if(!(Same (ClosedImports $spec.source_sha256) $spec.source_sha256)){throw 'EXPLICIT_EXISTING_IMPORT_REMAP_LEAF_MISSING'}
 $deps=Clone $spec.source_sha256;AddExact $deps $module $row.helper.sha256;AddExact $deps $manifest $row.manifest.sha256
 $template=[IO.File]::ReadAllText((Disk $row.index_template.path));if([regex]::Matches($template,'const FORMAL_ENABLED=false').Count -ne 1 -or [regex]::Matches($template,'PENDING_ART_LAYOUT_AND_ISOLATED_IMPORT').Count -ne 1 -or !$template.Contains($manifest)){throw 'FALSE_INDEX_TEMPLATE'}
 $indexFalseText=$template.Replace('PENDING_ART_LAYOUT_AND_ISOLATED_IMPORT',$row.manifest.sha256);$indexTrueText=$indexFalseText.Replace('const FORMAL_ENABLED=false','const FORMAL_ENABLED=true')
 if($indexTrueText.Replace('const FORMAL_ENABLED=true','const FORMAL_ENABLED=false') -cne $indexFalseText){throw 'INDEX_SOLE_BOOL_INVERSE'}
 $ff=W ($id+'/index_false.gd') $indexFalseText;$tf=W ($id+'/index_true.gd') $indexTrueText
 $areaFacts[$id]=@{module=$module;index=$index;manifest=$manifest;deps=$deps;import_proof=$row.import_proof;false_sha=(Sha $ff);true_sha=(Sha $tf);false_candidate=$pkg+'staged/'+$id+'/index_false.gd';true_candidate=$pkg+'staged/'+$id+'/index_true.gd'}
 $targets+=@{target=$module;old_sha256='ABSENT';candidate_path=$row.helper.path;candidate_sha256=$row.helper.sha256},@{target=$manifest;old_sha256='ABSENT';candidate_path=$row.manifest.path;candidate_sha256=$row.manifest.sha256},@{target=$index;old_sha256='ABSENT';candidate_path=$areaFacts[$id].false_candidate;candidate_sha256=$areaFacts[$id].false_sha}
}
# Explicit PENDING admission status is rejected before any output. Preserve any
# later partial stage if a supposedly approved input fails a strict assertion.
if($areaFacts[$dock].import_proof.path -ceq $areaFacts[$market].import_proof.path -and $areaFacts[$dock].import_proof.sha256 -ceq $areaFacts[$market].import_proof.sha256){$sharedProofs[$areaFacts[$dock].import_proof.path]=$areaFacts[$dock].import_proof.sha256}
$manifestPaths=@{AA=$roots.AA+$dock+'/manifest.json';AC=$roots.AC+$dock+'/manifest.json'};foreach($id in @($gate,$yamen,$dock,$market)){$manifestPaths[$id]=$roots.original+$id+'/manifest.json'}
$facts=@{}
foreach($key in $manifestPaths.Keys){
 $mp=$manifestPaths[$key];Check $mp $oldManifest[$key];$old=J $mp;$next=Clone $old;$changes=@{};$updates=Clone $newCode
 $id=if($key -cin @('AA','AC')){$dock}else{$key};if($areaFacts.Contains($id)){foreach($p in $areaFacts[$id].deps.Keys){AddExact $updates $p $areaFacts[$id].deps[$p]}}
 foreach($p in $updates.Keys){
  if($old.artifacts.Contains($p)){if($old.artifacts[$p] -cne $updates[$p]){throw 'IMMUTABLE_ARTIFACT_COLLISION'};continue}
  $cat=if($old.legacy_source_sha256.Contains($p)){'legacy_source_sha256'}elseif($old.runtime_authority_sha256.Contains($p)){'runtime_authority_sha256'}else{'legacy_source_sha256'};$ex=$old[$cat].Contains($p)
  if(!$ex -and $newCode.Contains($p)){continue};$before=if($ex){$old[$cat][$p]}else{$null}
  if($newCode.Contains($p) -and $before -cne $oldCode[$p]){throw 'OWNED_RUNTIME_PREDECESSOR'}
  if($ex -and $before -ceq $updates[$p]){continue};$changes[$p]=@{category=$cat;existed=$ex;old_sha256=$before;new_sha256=$updates[$p]};$next[$cat][$p]=$updates[$p]
 }
 $next['shore_market_ae_source_successor']=@{prior_sha256=$oldManifest[$key];source_changes=$changes;geometry_native_and_publication_first_final_unchanged=$true}
 $back=Clone $next;$back.Remove('shore_market_ae_source_successor')|Out-Null;foreach($p in $changes.Keys){$r=$changes[$p];if($r.existed){$back[$r.category][$p]=$r.old_sha256}else{$back[$r.category].Remove($p)|Out-Null}}
 if(!(Same $back $old) -or !(Same $old.artifacts $next.artifacts)){throw 'SIX_MANIFEST_WHOLE_INVERSE'};foreach($p in $old.artifacts.Keys){Check $p $old.artifacts[$p]}
 $file=WJ ($key+'/manifest.json') $next;$facts[$key]=@{manifest=$next;changes=$changes;sha=(Sha $file);target=$mp;candidate=$pkg+'staged/'+$key+'/manifest.json'}
 $targets+=@{target=$mp;old_sha256=$oldManifest[$key];candidate_path=$facts[$key].candidate;candidate_sha256=$facts[$key].sha}
}
$authority=@{};$biOld=[IO.File]::ReadAllText((Disk $BI));$biNew=$biOld
foreach($key in @($gate,$yamen,$dock,$market)){if([regex]::Matches($biNew,$oldManifest[$key]).Count -ne 1){throw 'BI_UNIQUE_OLD_PIN'};$biNew=$biNew.Replace($oldManifest[$key],$facts[$key].sha)}
$back=$biNew;foreach($key in @($gate,$yamen,$dock,$market)){$back=$back.Replace($facts[$key].sha,$oldManifest[$key])};if($back -cne $biOld){throw 'BI_ONLY_FOUR_PIN_INVERSE'}
$biFile=W 'Bundle_index.gd' $biNew;$authority[$BI]=Sha $biFile;$targets+=@{target=$BI;old_sha256=(Sha (Disk $BI));candidate_path=$pkg+'staged/Bundle_index.gd';candidate_sha256=$authority[$BI]}
foreach($pair in @(@($AI,'AA'),@($CI,'AC'))){$p=$pair[0];$key=$pair[1];$old=[IO.File]::ReadAllText((Disk $p));if([regex]::Matches($old,$oldManifest[$key]).Count -ne 1){throw 'AA_AC_UNIQUE_OLD_PIN'};$next=$old.Replace($oldManifest[$key],$facts[$key].sha);if($next.Replace($facts[$key].sha,$oldManifest[$key]) -cne $old){throw 'AA_AC_ONLY_ONE_PIN_INVERSE'};$f=W ($key+'_index.gd') $next;$authority[$p]=Sha $f;$targets+=@{target=$p;old_sha256=(Sha (Disk $p));candidate_path=$pkg+'staged/'+$key+'_index.gd';candidate_sha256=$authority[$p]}}
function FromManifest($fact,[string]$id,[bool]$formal){$m=$fact.manifest;$set=Clone $m.legacy_source_sha256;foreach($cat in @('runtime_authority_sha256','artifacts')){foreach($p in $m[$cat].Keys){AddExact $set $p $m[$cat][$p]}};AddExact $set $BI $authority[$BI];AddExact $set $fact.target $fact.sha;if($id -ceq $dock){AddExact $set $AI $authority[$AI];AddExact $set $CI $authority[$CI];AddExact $set $DI (Sha (Disk $DI))};if($areaFacts.Contains($id)){$a=$areaFacts[$id];AddExact $set $a.index $(if($formal){$a.true_sha}else{$a.false_sha})};if(!(Same (ClosedImports $set) $set)){throw 'FINAL_IMPORT_REMAP_CLOSURE'};return $set}
$maps=@{}
foreach($id in @($gate,$yamen,$dock,$market)){
 $base=$baseline[$id];Check $base.path $base.sha;$old=J $base.path;if($old.source_sha256.Count -ne $base.count){throw 'INDEPENDENT_AD_BASELINE_COUNT'};$fact=if($id -ceq $dock){$facts.AC}else{$facts[$id]}
 $expected=Clone $old.source_sha256;foreach($p in $fact.changes.Keys){$expected[$p]=$fact.changes[$p].new_sha256};$expected[$BI]=$authority[$BI];$expected[$fact.target]=$fact.sha
 if($id -ceq $dock){$expected[$AI]=$authority[$AI];$expected[$CI]=$authority[$CI]};if($areaFacts.Contains($id)){$expected[$areaFacts[$id].index]=$areaFacts[$id].false_sha}
 if(!(Same (FromManifest $fact $id $false) $expected)){throw 'INDEPENDENT_FALSE_SOURCE_SET_EQUATION'}
 $back=Clone $expected;if($areaFacts.Contains($id)){$back.Remove($areaFacts[$id].index)|Out-Null};foreach($p in $fact.changes.Keys){$r=$fact.changes[$p];if($r.existed){$back[$p]=$r.old_sha256}else{$back.Remove($p)|Out-Null}};foreach($p in @($BI,$fact.target)){$back[$p]=$old.source_sha256[$p]};if($id -ceq $dock){foreach($p in @($AI,$CI)){$back[$p]=$old.source_sha256[$p]}};if(!(Same $back $old.source_sha256)){throw 'WHOLE_INDEPENDENT_SOURCE_INVERSE'}
 foreach($other in @($dock,$market)){if($id -ceq $other){continue};foreach($p in @($areaFacts[$other].deps.Keys)+@($areaFacts[$other].index)){if($sharedProofs.Contains($p) -and $areaFacts.Contains($id) -and $expected[$p] -ceq $sharedProofs[$p]){continue};if($expected.Contains($p) -and !$old.source_sha256.Contains($p)){throw 'CROSS_CITY_NEW_AE_COMPILE_OR_MEDIA_LEAK'}}}
 foreach($phase in $(if($areaFacts.Contains($id)){@('false','true')}else{@('false')})){$set=Clone $expected;if($phase -ceq 'true'){$set[$areaFacts[$id].index]=$areaFacts[$id].true_sha;if(!(Same (FromManifest $fact $id $true) $set)){throw 'TRUE_ONLY_EXTERNAL_INDEX_EQUATION'}};$f=WJ ($id+'/expected_sources_'+$phase+'.json') @{status='INDEPENDENT_AD_PLUS_FINITE_AE_VISUAL_ONLY_SUCCESSION';phase=$phase;baseline_path=$base.path;baseline_sha256=$base.sha;source_sha256=$set};$maps[$id+'_'+$phase]=@{path=$pkg+'staged/'+$id+'/expected_sources_'+$phase+'.json';sha256=(Sha $f);count=$set.Count}}
}
$patch="*** Begin Patch`n";foreach($t in $targets|Where-Object target -like '*.gd'){$patch+= $(if($t.old_sha256 -ceq 'ABSENT'){'*** Add File: '}else{'*** Update File: '})+(Disk $t.target).Replace('\','/')+"`n";if($t.old_sha256 -ceq 'ABSENT'){foreach($line in [IO.File]::ReadAllText((Disk $t.candidate_path)).TrimEnd("`n").Split("`n")){$patch+='+'+$line+"`n"};continue};$lines=@(& git -c core.autocrlf=false diff --no-index --unified=3 -- (Disk $t.target) (Disk $t.candidate_path));if($LASTEXITCODE -ne 1){throw 'CODE_DIFF_REQUIRED'};$started=$false;foreach($line in $lines){if($line.StartsWith('@@')){$started=$true;$patch+="@@`n"}elseif($started){if($line.StartsWith('\ No newline')){throw 'NEWLINE_DOMAIN_CHANGED'};$patch+=$line+"`n"}}}
$pf=W 'minimal_false_code_deployment.apply_patch' ($patch+"*** End Patch`n")
$flip="*** Begin Patch`n";foreach($id in @($dock,$market)){$flip+='*** Update File: '+(Disk $areaFacts[$id].index).Replace('\','/')+"`n@@`n-const FORMAL_ENABLED=false`n+const FORMAL_ENABLED=true`n"};$ff=W 'two_bool_true_after_candidate.apply_patch' ($flip+"*** End Patch`n")
WJ 'stage_receipt.json' @{status='STAGED_ONLY_NOT_DEPLOYED';input_path=$AdmissionPath;input_sha256=$AdmissionSHA;targets=$targets;maps=$maps;areas=$areaFacts;six_manifest_whole_inverses=$true;all_18_native_artifacts_unchanged=$true;four_independent_whole_source_inverses=$true;two_formal_maps_only_their_external_index_changed=$true;no_cross_city_new_helper_media_leak=$true;temple_H_Field_C_Router_NPC_GS_x_unchanged=$true;code_patch_sha256=(Sha $pf);sole_two_bool_patch_sha256=(Sha $ff);no_engine_collector_canonical_or_save_writes=$true}|Out-Null
