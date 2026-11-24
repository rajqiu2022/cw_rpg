param([string]$Workspace='F:\Code\RPG_GAME')
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
# Metadata-only successor. Reuses exact completed code, family manifest and Temple binding.
# No engine, import, geometry, canonical writes or replay of the original stager.
$game=Join-Path $Workspace 'game'
$pkg='res://build/luoyang_estate_courtyard_20261021an_system01/'
$parent=$pkg+'staged_retry2/receipt.json'
$parentSHA='39e1594f0b1e35b4be636555c8cbfb4ccfb86097c892ba387635b1c1b58b47a4'
$inputPath=$pkg+'source_staging_input_retry1_READY.json'
$inputSHA='f3ce0c3919f0318d856c2be857b73f21b9b53e314a3938356b575efc5691e39e'
$outPath=$pkg+'staged_gate_scope_successor/'
function Disk([string]$p){if(!$p.StartsWith('res://') -or $p.Contains('..')){throw 'RESOURCE_PATH'};Join-Path $game $p.Substring(6)}
function SHA([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function Check([string]$p,[string]$h){if($h -cnotmatch '^[0-9a-f]{64}$' -or (SHA (Disk $p)) -cne $h){throw "SOURCE_CHANGED:$p"}}
function J([string]$p){Get-Content -Raw -LiteralPath (Disk $p)|ConvertFrom-Json -AsHashtable}
function Clone($v){$v|ConvertTo-Json -Depth 100 -Compress|ConvertFrom-Json -AsHashtable}
function Canon($v){if($v -is [Collections.IDictionary]){$r=[ordered]@{};foreach($k in @($v.Keys|Sort-Object -CaseSensitive)){$r[$k]=Canon $v[$k]};return $r};if($v -is [array]){return ,@($v|ForEach-Object{Canon $_})};return $v}
function Same($a,$b){((Canon $a)|ConvertTo-Json -Depth 100 -Compress) -ceq ((Canon $b)|ConvertTo-Json -Depth 100 -Compress)}
function W([string]$name,[string]$text){$p=Disk ($outPath+$name);[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($p))|Out-Null;[IO.File]::WriteAllText($p,$text,[Text.UTF8Encoding]::new($false));return $outPath+$name}
function WJ([string]$name,$v){W $name (($v|ConvertTo-Json -Depth 100)+"`n")}
if(Test-Path -LiteralPath (Disk $outPath)){throw 'NEW_SUCCESSOR_ONLY'}
Check $parent $parentSHA;Check $inputPath $inputSHA
$r=J $parent;$a=J $inputPath
if($r.targets.Count -ne 19 -or !$r.all_six_manifest_whole_inverse -or !$r.all18_city_native_artifacts_unchanged){throw 'EXACT_COMPLETED_PARENT_REQUIRED'}
Check $a.publication.path $a.publication.sha256
$pub=J $a.publication.path
if(!$pub.passed -or $pub.mansion_return.current_source_sha256.Count -ne 253){throw 'EXACT_PUBLISHED_ROOM_SOURCE_SET'}
foreach($t in $r.targets){Check $t.candidate_path $t.candidate_sha256;if($t.old_sha256 -ceq 'ABSENT'){if(Test-Path -LiteralPath (Disk $t.target)){throw 'CANONICAL_STILL_UNDEPLOYED'}}else{Check $t.target $t.old_sha256}}
Check $r.temple_binding_path $r.temple_binding_sha256
$gate='ch4_s0_luoyang_gate'
$gateTarget='res://data/maps/luoyang_layout_bundle_20261018t_retry2/'+$gate+'/manifest.json'
$bi='res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd'
$base=@($a.baselines|Where-Object scene_id -CEQ $gate)
if($base.Count -ne 1){throw 'EXACT_GATE_BASELINE'}
Check $base[0].path $base[0].sha256
$baseSources=(J $base[0].path).source_sha256
if($baseSources.Count -ne 709){throw 'GATE_BASELINE_709'}
$keep=@('res://scripts/city/luoyang_estate_family_20261021am.gd',$r.family_manifest_path,'res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/estate_candidate.gd')+@($pub.mansion_return.artifacts.Keys)
if($keep.Count -ne 8){throw 'EXACT_SMALL_HEADER_AND_FIVE_ROOM_DATA'}
$drops=@($pub.mansion_return.current_source_sha256.Keys|Where-Object{!$baseSources.Contains($_) -and $_ -cnotin $keep})
if($drops.Count -ne 231){throw 'EXACT_GATE_UNNEEDED_NEW_ROOM_KEYS_231'}
$gateRow=@($r.targets|Where-Object target -CEQ $gateTarget)[0]
$priorGate=J $gateRow.candidate_path;$newGate=Clone $priorGate
foreach($p in $drops){
 if(!$newGate.legacy_source_sha256.Contains($p) -or $newGate.legacy_source_sha256[$p] -cne $pub.mansion_return.current_source_sha256[$p]){throw "EXACT_GATE_NEW_ROOM_LEAF:$p"}
 $d=@($r.manifest_source_deltas[$gateTarget]|Where-Object { $_.path -ceq $p })
 if($d.Count -ne 1 -or $d[0].kind -cne 'legacy_source_sha256' -or $d[0].old -cne 'ABSENT'){throw 'NEVER_REMOVE_OLD_GATE_SOURCE'}
 $newGate.legacy_source_sha256.Remove($p)
}
$back=Clone $newGate;foreach($p in $drops){$back.legacy_source_sha256[$p]=$priorGate.legacy_source_sha256[$p]}
if(!(Same $back $priorGate)){throw 'GATE_SCOPE_WHOLE_INVERSE'}
$gateFile=WJ 'gate_manifest.json' $newGate;$gateSHA=SHA (Disk $gateFile)
$priorGateSHA=$gateRow.candidate_sha256
$gateRow.candidate_path=$gateFile;$gateRow.candidate_sha256=$gateSHA
$r.manifest_source_deltas[$gateTarget]=@($r.manifest_source_deltas[$gateTarget]|Where-Object { $_.path -cnotin $drops })
# BI changes one hash literal only; other executable candidates and their paths stay exact.
$biRow=@($r.targets|Where-Object target -CEQ $bi)[0]
$oldBI=[IO.File]::ReadAllText((Disk $biRow.candidate_path))
if([regex]::Matches($oldBI,$priorGateSHA).Count -ne 1){throw 'BI_EXACT_ONE_GATE_MANIFEST_LITERAL'}
$newBI=$oldBI.Replace($priorGateSHA,$gateSHA)
if($newBI.Replace($gateSHA,$priorGateSHA) -cne $oldBI){throw 'BI_WHOLE_TEXT_INVERSE'}
$priorBISHA=$biRow.candidate_sha256
$biFile=W 'code/luoyang_precomputed_bundle_index_20261018r.gd' $newBI;$biSHA=SHA (Disk $biFile)
$biRow.candidate_path=$biFile;$biRow.candidate_sha256=$biSHA
$mapProof=[ordered]@{}
foreach($id in @($r.independent_expected_maps.Keys)){
 $m=$r.independent_expected_maps[$id];$priorCount=$m.count
 foreach($phase in @('false','true')){
  Check $m[($phase+'_path')] $m[($phase+'_sha256')]
  $prior=J $m[($phase+'_path')];$next=Clone $prior
  if($next.source_sha256[$bi] -cne $priorBISHA){throw 'MAP_PRIOR_BI'}
  $next.source_sha256[$bi]=$biSHA
  if($id -ceq $gate){
   if($next.source_sha256[$gateTarget] -cne $priorGateSHA){throw 'MAP_PRIOR_GATE_MANIFEST'}
   $next.source_sha256[$gateTarget]=$gateSHA
   foreach($p in $drops){if(!$next.source_sha256.Contains($p) -or $next.source_sha256[$p] -cne $pub.mansion_return.current_source_sha256[$p]){throw 'MAP_EXACT_GATE_DROP'};$next.source_sha256.Remove($p)}
  }
  $inverse=Clone $next;$inverse.source_sha256[$bi]=$priorBISHA
  if($id -ceq $gate){$inverse.source_sha256[$gateTarget]=$priorGateSHA;foreach($p in $drops){$inverse.source_sha256[$p]=$prior.source_sha256[$p]}}
  if(!(Same $inverse $prior)){throw 'MAP_METADATA_SCOPE_WHOLE_INVERSE'}
  $file=WJ ('maps/'+$id+'_'+$phase+'.json') $next
  $m[($phase+'_path')]=$file;$m[($phase+'_sha256')]=SHA (Disk $file)
  if($phase -ceq 'false'){$m.count=$next.source_sha256.Count}
 }
 if($m.count -ne ($priorCount-$(if($id -ceq $gate){231}else{0}))){throw 'EXACT_MAP_COUNT_DELTA'}
 $mapProof[$id]=@{prior_count=$priorCount;next_count=$m.count;only_gate_room_source_removal=($id -ceq $gate);bi_single_leaf_inherited=$true;whole_inverse=$true}
}
# Recheck every six manifest against its independent original, including all artifact/proof fields.
foreach($row in $a.city_manifests){
 $t=@($r.targets|Where-Object target -CEQ $row.path)[0];$candidate=J $t.candidate_path;Check $row.path $row.sha256;$old=J $row.path;$inverse=Clone $candidate
 foreach($d in @($r.manifest_source_deltas[$row.path])){if($d.old -ceq 'ABSENT'){$inverse[$d.kind].Remove($d.path)}else{$inverse[$d.kind][$d.path]=$d.old}}
 if(!(Same $inverse $old) -or !(Same $candidate.artifacts $old.artifacts) -or !(Same $candidate.layout_proof $old.layout_proof)){throw 'SIX_MANIFEST_FULL_INVERSE_AND_18_NATIVE_UNCHANGED'}
}
# Regenerate the same deployment patch using old canonical -> the 12 exact final code candidates.
$patch="*** Begin Patch`n"
foreach($t in @($r.targets|Where-Object {$_.target.EndsWith('.gd')})){
 $diff=@(& git diff --no-index --no-color --text --unified=3 -- (Disk $t.target) (Disk $t.candidate_path) 2>$null)
 if($LASTEXITCODE -gt 1){throw 'READ_ONLY_DIFF_FAILED'}
 $patch+='*** Update File: '+(Disk $t.target).Replace('\','/')+"`n";$active=$false
 foreach($line in $diff){if($line.StartsWith('@@')){$patch+="@@`n";$active=$true;continue};if($active -and !$line.StartsWith('\ No newline')){$patch+=$line+"`n"}}
}
$patch+="*** End Patch`n";$patchFile=W 'canonical_code_deployment.apply_patch' $patch
$r.code_patch_path=$patchFile;$r.code_patch_sha256=SHA (Disk $patchFile)
$r.status='AN_STAGED_GATE_SCOPE_METADATA_SUCCESSOR_NOT_DEPLOYED_NOT_FIELD_PASS'
$r['metadata_scope_successor']=@{parent_receipt=$parent;parent_sha256=$parentSHA;gate_dropped_only_new_room_hash_leaves=$drops;gate_small_shared_count=8;gate_count=718;other_three_room_current_sources_unchanged=$true;estate_runtime327_unchanged=$true;family_manifest_and_index_unchanged=$true;temple_binding_and_helper_unchanged=$true;only_changed_target_paths=@($gateTarget,$bi);four_map_inverse=$mapProof}
$r.shared_header_room_source_count=257
$receipt=WJ 'receipt.json' $r
Write-Output (@{receipt=$receipt;sha256=SHA (Disk $receipt);targets=$r.targets.Count;gate_count=$r.independent_expected_maps[$gate].count;maps=$r.independent_expected_maps;code_patch_sha256=$r.code_patch_sha256}|ConvertTo-Json -Depth 8)
