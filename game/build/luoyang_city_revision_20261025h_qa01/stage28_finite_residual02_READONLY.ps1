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
$old=J 'res://build/luoyang_city_revision_20261025h_qa01/stage28_finite_audit_READONLY.json' '61b3f1743274b0a086172060ebfe86592ba7ae1340c175455114380555318940'
$d=J 'res://build/luoyang_city_revision_20261025h_source01/unified28_candidates01/unified28_all_candidates_and_inverse_NOT_STAGE.json' 'db48da89a35c3763748be77b3b71f2a591ed6aff1cda40908090cfaed06e54a9'
$r=J 'res://build/luoyang_city_revision_20261025h_source01/outputs/root_services_garden_exact28_stage05/receipt.json' 'ebe06a49d65b93102b746688168202efed227ab90a0834fe7bdbc76443bcfef5'
$fix=J 'res://build/luoyang_city_revision_20261025h_source01/external_projection_residual05b/exact_external_filter_restoration_NOT_STAGE.json' 'f20a0b853242e1bb2147bb78973f262ec5e1df7571b249c68377568f14e5262e'
$checks=0;$fail=@();function Need($v,$s){$script:checks++;if(-not $v){$script:fail+=,$s}}
Need ($old.passed-eq $false -and $old.checks-eq 377 -and $old.errors.Count-eq 8) 'Original audit01 whole FAIL retained,369 passed components inherited not replayed'
Need ($fix.changed_existing_candidate_targets.Count-eq 3 -and $fix.status-eq 'ROOT_APPROVED_TWO_B_MANIFESTS_RESTORE_OLD_EXTERNAL_FILTER') 'Fixed Root-approved05b only three candidate successors'
$overlay=@{}
foreach($change in $fix.changed_existing_candidate_targets){
 $a=@($d.targets|Where-Object{$_.target-eq $change.target});$b=@($r.targets|Where-Object{$_.target-eq $change.target})
 Need ($a.Count-eq 1 -and $b.Count-eq 1 -and $a[0].candidate.path-eq $change.old.path -and $a[0].candidate.sha256-eq $change.old.sha256 -and $b[0].old_sha256-eq $a[0].parent.sha256 -and $b[0].candidate_path-eq $change.new.path -and $b[0].candidate_sha256-eq $change.new.sha256 -and (Sha (P $change.new.path))-eq $change.new.sha256) ('Only approved candidate successor: '+$change.target)
 $overlay[$change.target]=$change.new.sha256
}
$mapDelta=@()
foreach($key in $d.maps.Keys){
 $expected=$d.maps[$key].value.source_sha256.Clone();$changed=@()
 foreach($target in $overlay.Keys){if($expected.Contains($target)){$expected[$target]=$overlay[$target];$changed+=,$target}}
 $node=$r.nodes[$key];$actual=J $node.path $node.sha256
 Need ((Eq $actual.source_sha256 $expected)-and (Eq $node.value.source_sha256 $expected)) ('Independent original map plus only approved three scalar successor hashes: '+$key)
 $mapDelta+=@{id=$key;scalar_updates=$changed;count=$expected.Count;sha256=$node.sha256}
}
$family=J $d.expected_Family_sources.path $d.expected_Family_sources.sha256
$actualFamily=J $r.nodes.expected_Family_sources.path $r.nodes.expected_Family_sources.sha256
Need ($family.source_sha256.Count-eq 458 -and (Eq $actualFamily.source_sha256 $family.source_sha256)-and (Eq $r.nodes.expected_Family_sources.value.source_sha256 $family.source_sha256)) 'Family458 from fixed file descriptor,not absent descriptor.value'
$out=Join-Path $base 'stage28_finite_residual02_READONLY.json';if(Test-Path -LiteralPath $out){throw 'Preserve existing residual'}
$report=@{status='STAGE05_ONLY_EIGHT_REMAINING_SOURCE_EXPECTATIONS_RECONCILED';passed=$fail.Count-eq 0;checks=$checks;errors=$fail;original_audit_whole_FAIL_preserved=$true;original_audit_sha256='61b3f1743274b0a086172060ebfe86592ba7ae1340c175455114380555318940';inherited_passed_components=369;old_failures_reconciled=8;approved05b_sha256='f20a0b853242e1bb2147bb78973f262ec5e1df7571b249c68377568f14e5262e';maps=$mapDelta;Family_sources=458;engine_calls=0;collectors=0;Stage_calls=0;production_writes=0;old_geometry_or_behavior_replay=0;scope='Only stale preStage3 candidate/map hashes and Family file-descriptor schema; no new production or performance credit.'}
[IO.File]::WriteAllText($out,(($report|ConvertTo-Json -Depth 7)+"`n"),[Text.UTF8Encoding]::new($false))
@{passed=$report.passed;checks=$checks;errors=$fail;report_sha256=Sha $out}|ConvertTo-Json -Depth 3
if(-not $report.passed){exit 1}
