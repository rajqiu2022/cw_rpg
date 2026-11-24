$ErrorActionPreference='Stop'
$game='F:/Code/RPG_GAME/game';$base=Join-Path $game 'build/luoyang_city_revision_20261025h_qa01'
function Sha($p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function P($r){if(-not $r.StartsWith('res://')-or $r.Contains('..')){throw 'Fixed res only'};Join-Path $game $r.Substring(6)}
function J($r,$sha){$p=P $r;if((Sha $p)-ne $sha){throw "Fixed artifact drift $r"};Get-Content -LiteralPath $p -Raw|ConvertFrom-Json -AsHashtable}
function Eq($a,$b){
 if($null-eq $a -or $null-eq $b){return $null-eq $a -and $null-eq $b}
 if($a-is [Collections.IDictionary]){if(-not($b-is [Collections.IDictionary])-or $a.Count-ne $b.Count){return $false};foreach($k in $a.Keys){if(-not $b.Contains($k)-or -not(Eq $a[$k] $b[$k])){return $false}};return $true}
 if($a-is [Collections.IList]){if(-not($b-is [Collections.IList])-or $a.Count-ne $b.Count){return $false};for($i=0;$i-lt $a.Count;$i++){if(-not(Eq $a[$i] $b[$i])){return $false}};return $true}
 return $a.GetType()-eq $b.GetType()-and $a-eq $b
}
$stagePath='res://build/luoyang_city_revision_20261025h_source01/outputs/root_services_garden_exact28_stage05/receipt.json'
$r=J $stagePath 'ebe06a49d65b93102b746688168202efed227ab90a0834fe7bdbc76443bcfef5'
$d=J 'res://build/luoyang_city_revision_20261025h_source01/unified28_candidates01/unified28_all_candidates_and_inverse_NOT_STAGE.json' 'db48da89a35c3763748be77b3b71f2a591ed6aff1cda40908090cfaed06e54a9'
$fresh=J 'res://build/luoyang_city_revision_20261025h_source01/fresh_current25h_READONLY.json' '7b26d75eaad7d95b7d7ab33e572d0ab10c52d02e6b5e07f4ecb8609fa6ed1dcb'
$parent=J $d.parent_stage.path 'c972f71442cc6573d8e55a92bf0ce875039879be651dd30e3fd32df585d97396'
$checks=0;$fail=@();function Need($v,$label){$script:checks++;if(-not $v){$script:fail+=,$label}}
Need ($r.status-eq 'SERVICE_GARDEN_EXACT28_STAGED_NOT_DEPLOYED') 'Stage05 status only, deployment separate'
Need ($r.targets.Count-eq 28 -and $d.targets.Count-eq 28 -and $r.target_partition.patch_count-eq 14 -and $r.target_partition.copy_count-eq 14) 'Exact28 partition14/14'
$expected=@{};foreach($t in $d.targets){Need (-not $expected.ContainsKey($t.target)) 'Unique immutable approved target';$expected[$t.target]=$t}
$targetHash=@{};$noops=0
foreach($t in $r.targets){Need ($expected.ContainsKey($t.target)) 'No unapproved target';$e=$expected[$t.target];Need ($t.old_sha256-eq $e.parent.sha256 -and $t.candidate_path-eq $e.candidate.path -and $t.candidate_sha256-eq $e.candidate.sha256) 'Approved exact old and candidate bytes';Need ((Sha (P $t.candidate_path))-eq $t.candidate_sha256) 'Candidate file remains exact';if($t.old_sha256-eq $t.candidate_sha256){$noops++};$targetHash[$t.target]=$t.candidate_sha256}
Need ($noops-eq 0 -and $targetHash.Count-eq 28) 'Zero noop, duplicate or omitted target'
$oldExec=J $d.execution.parent.path $d.execution.parent.sha256;$newExec=J $d.execution.candidate.path $d.execution.candidate.sha256
Need ($oldExec.owned.Count-eq 10 -and $newExec.owned.Count-eq 10 -and @($newExec.owned.Keys|Where-Object{-not $oldExec.owned.Contains($_)}).Count-eq 0) 'Owned domain exact10, no new owner'
Need ($oldExec.source_sha256.Count-eq 170 -and $newExec.source_sha256.Count-eq 176) 'Historical proof170 to176 only'
foreach($p in $oldExec.source_sha256.Keys){Need ($newExec.source_sha256.Contains($p)-and $newExec.source_sha256[$p]-eq $oldExec.source_sha256[$p]) 'All old170 proof values retained'}
$proofAdded=@($newExec.source_sha256.Keys|Where-Object{-not $oldExec.source_sha256.Contains($_)})
Need ($proofAdded.Count-eq 6 -and @($proofAdded|Where-Object{-not $d.execution.extra.Contains($_)-or $d.execution.extra[$_]-ne $newExec.source_sha256[$_]}).Count-eq 0) 'Only approved six ordinary historical proof leaves'
$changedOwners=@();foreach($p in $oldExec.owned.Keys){$a=$oldExec.owned[$p];$b=$newExec.owned[$p];if(-not(Eq $a $b)){$changedOwners+=,$p;Need ($targetHash.ContainsKey($p)-and $b.current_sha256-eq $targetHash[$p]-and $b.edges.Count-eq $a.edges.Count+1) 'Changed existing owner gets exactly one edge';for($i=0;$i-lt $a.edges.Count;$i++){Need (Eq $a.edges[$i] $b.edges[$i]) 'All old owned edges whole retained'}}}
Need ($changedOwners.Count-eq 4) 'Only G Field Coordinator Temple existing owners changed'
$allowedAdd=@{};foreach($group in $d.source_additions.Values){foreach($p in $group.Keys){$allowedAdd[$p]=$group[$p]}}
$maps=@();foreach($key in $d.maps.Keys){$def=$d.maps[$key];$old=J $def.parent.path $def.parent.sha256;$node=$r.nodes[$key];$new=J $node.path $node.sha256;Need (Eq $new $node.value) 'Stage map bytes equal embedded model';Need (Eq $new.source_sha256 $def.value.source_sha256) 'Stage source dictionary equals independently authored fixed25g plus original formula';Need ($old.source_sha256.Count-eq $parent.nodes[$key].value.source_sha256.Count -and (Eq $old.source_sha256 $parent.nodes[$key].value.source_sha256)) 'Exact fixed25g independent parent source domain';$removed=@($old.source_sha256.Keys|Where-Object{-not $new.source_sha256.Contains($_)});$added=@($new.source_sha256.Keys|Where-Object{-not $old.source_sha256.Contains($_)});$bad=@($added|Where-Object{-not $allowedAdd.ContainsKey($_)-or $allowedAdd[$_]-ne $new.source_sha256[$_]});$updates=@($old.source_sha256.Keys|Where-Object{$new.source_sha256[$_]-ne $old.source_sha256[$_]});$badUpdates=@($updates|Where-Object{-not $targetHash.ContainsKey($_)-or $targetHash[$_]-ne $new.source_sha256[$_]});Need ($removed.Count-eq 0 -and $bad.Count-eq 0 -and $badUpdates.Count-eq 0) 'No source deletions, unauthorized additions or foreign value updates';$maps+=@{id=$key;old_count=$old.source_sha256.Count;new_count=$new.source_sha256.Count;added_count=$added.Count;updated_count=$updates.Count;removed_count=$removed.Count;sha256=$node.sha256}}
$family=$r.nodes.expected_Family_sources;Need ($family.value.source_sha256.Count-eq 458 -and (Eq $family.value.source_sha256 $d.expected_Family_sources.value.source_sha256)) 'Exact independently authored Family458 source map'
Need (Eq $r.source_first $r.source_final) 'Actual Stage own source first/final exact, no collector replay'
Need ($fresh.backups_current148.Count-eq 148) 'Fresh old148 full backup domain'
$backup=J $d.root_backup.path $d.root_backup.sha256;Need ($backup.passed-eq $true -and $backup.rows.Count-eq 28 -and $backup.old148_backups_untouched-eq $true) 'Root exact28 new backup artifact plus old148 domain preserved'
$report=@{status='STAGE05_FINITE_INDEPENDENT_REVIEW_READONLY';passed=$fail.Count-eq 0;checks=$checks;errors=$fail;stage=@{path=$stagePath;sha256='ebe06a49d65b93102b746688168202efed227ab90a0834fe7bdbc76443bcfef5'};approved_preStage_candidate_sha256='db48da89a35c3763748be77b3b71f2a591ed6aff1cda40908090cfaed06e54a9';targets=28;GD=14;JSON=14;noops=$noops;owned=10;proof_count_old=170;proof_count_new=176;changed_existing_owners=$changedOwners;maps=$maps;Family_sources=458;old_backups=148;new_backups=28;backup_total=176;engine_calls=0;Stage_calls=0;collectors=0;geometry_or_pixel_replay=0;canonical_writes=0;scope='Only fixed Stage/candidate/25g source models and new backup receipt. Does not replace Source full2121 guard, runtime, ART or load timing.'}
$out=Join-Path $base 'stage28_finite_audit_READONLY.json';if(Test-Path -LiteralPath $out){throw 'Preserve existing audit'};[IO.File]::WriteAllText($out,(($report|ConvertTo-Json -Depth 9)+"`n"),[Text.UTF8Encoding]::new($false))
@{passed=$report.passed;checks=$checks;errors=$fail;maps=$maps;report_sha256=Sha $out}|ConvertTo-Json -Depth 5
if(-not $report.passed){exit 1}
