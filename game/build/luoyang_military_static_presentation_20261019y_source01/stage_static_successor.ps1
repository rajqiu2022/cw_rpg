param([string]$Workspace = 'F:\Code\RPG_GAME')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
# This generator writes NEW source01/staged only. It never deploys canonical files.
$gameRoot = Join-Path $Workspace 'game'
$sourceRoot = Join-Path $gameRoot 'build/luoyang_military_static_presentation_20261019y_source01'
$stageRoot = [IO.Path]::GetFullPath((Join-Path $sourceRoot 'staged'))
if (Test-Path -LiteralPath $stageRoot) { throw 'STAGED_ALREADY_EXISTS: preserve evidence; use a reviewed NEW successor script/directory' }
function Disk([string]$p) {
    if (!$p.StartsWith('res://') -or $p.Contains('..')) { throw "BAD_RESOURCE_PATH:$p" }
    return Join-Path $gameRoot $p.Substring(6)
}
function Sha([string]$p) { return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant() }
function Assert-Sha([string]$p, [string]$expected) {
    if ($expected -notmatch '^[0-9a-f]{64}$' -or (Sha (Disk $p)) -cne $expected) { throw "SOURCE_CHANGED:$p" }
}
function Read-J([string]$p) { return Get-Content -Raw -LiteralPath $p | ConvertFrom-Json -AsHashtable }
function Clone($obj) { return $obj | ConvertTo-Json -Depth 100 -Compress | ConvertFrom-Json -AsHashtable }
function Canonical($obj) {
    if ($obj -is [System.Collections.IDictionary]) {
        $out = [ordered]@{}; foreach ($k in @($obj.Keys | Sort-Object -CaseSensitive)) { $out[$k] = Canonical $obj[$k] }; return $out
    }
    if ($obj -is [array]) { return ,@($obj | ForEach-Object { Canonical $_ }) }
    return $obj
}
function Same($a,$b) {
    $x=Canonical $a; $y=Canonical $b
    return ($x | ConvertTo-Json -Depth 100 -Compress) -ceq ($y | ConvertTo-Json -Depth 100 -Compress)
}
function Write-Text([string]$relative,[string]$text) {
    $p = [IO.Path]::GetFullPath((Join-Path $stageRoot $relative))
    if (!$p.StartsWith($stageRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'WRITE_OUTSIDE_STAGED' }
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($p)) | Out-Null
    [IO.File]::WriteAllText($p,$text,[Text.UTF8Encoding]::new($false))
    return $p
}
function Write-J([string]$relative,$obj) { return Write-Text $relative (($obj | ConvertTo-Json -Depth 100) + "`n") }
$plan = Read-J (Join-Path $sourceRoot 'metadata_successor_plan_draft.json')
$falseClosurePath = Join-Path $sourceRoot 'frozen_static_closure_false.json'
if ((Sha $falseClosurePath) -cne 'dd7584267117f3cfa692d3f549ac049a92049fc726da08aa4a8798a7ed42174d') { throw 'FALSE_CLOSURE_CHANGED' }
$falseClosure = Read-J $falseClosurePath
foreach ($p in $falseClosure.source_sha256.Keys) { Assert-Sha $p $falseClosure.source_sha256[$p] }
foreach ($t in $plan.candidate_targets) { Assert-Sha $t.target $t.old_sha256; Assert-Sha $t.candidate_path $t.candidate_sha256 }
foreach ($c in $plan.per_city) { Assert-Sha $c.manifest_path $c.manifest_sha256; foreach($p in $c.artifacts_to_preserve.Keys) { Assert-Sha $p $c.artifacts_to_preserve[$p] } }
$protectedPaths = @{
 'Field'='res://scripts/field/field_walkable_controller.gd';'NPCNode'='res://scripts/field/npc_node.gd';
 'xCoordinator'='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';
 'xRuntimeContract'='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';'GameState'='res://scripts/autoload/game_state.gd'
}
foreach($key in $protectedPaths.Keys) { Assert-Sha $protectedPaths[$key] $plan.protected[$key] }
$baselinePath = $plan.independent_baseline.path
Assert-Sha $baselinePath $plan.independent_baseline.sha256
$baseline = Read-J (Disk $baselinePath)
$records = @($baseline.records | Where-Object kind -eq 'METADATA_ONLY_FULL_COLLECTOR')
if ($records.Count -ne 4 -or $baseline.complete -ne $false -or $baseline.failures -ne 1 -or $baseline.elapsed_ms -ne 91679) { throw 'INDEPENDENT_BASELINE_SCOPE_CHANGED' }
$bundleIndex = 'res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd'
Assert-Sha $bundleIndex 'f834214c5ced741e73c2fbb7f9bac98ea35cce256c96bb40adf807bb9071e7ac'
$temple = $plan.temple_successor
Assert-Sha $temple.old_helper_path $temple.old_helper_sha256
Assert-Sha $temple.old_binding_path $temple.old_binding_sha256
Assert-Sha $temple.preserve_parent_binding_path $temple.preserve_parent_binding_sha256
$parent = Read-J (Disk $temple.preserve_parent_binding_path)
if ($parent.status -cne 'READY_IMPORTED_TEMPLE_CANDIDATE') { throw 'TEMPLE_IMPORTED_PARENT_CHANGED' }
$oldTempleBinding = Read-J (Disk $temple.old_binding_path)
$oldTempleText = [IO.File]::ReadAllText((Disk $temple.old_helper_path))
$oldIndexText = [IO.File]::ReadAllText((Disk $bundleIndex))
$indexPath = 'res://scripts/city/luoyang_military_static_presentation_index_20261019y.gd'
$oldStaticText = [IO.File]::ReadAllText((Disk $indexPath))
if ([regex]::Matches($oldStaticText,'const FORMAL_ENABLED := false').Count -ne 1) { throw 'STATIC_FALSE_AUTHORITY_CHANGED' }
$trueStaticText = $oldStaticText.Replace('const FORMAL_ENABLED := false','const FORMAL_ENABLED := true')
$trueIndexFile = Write-Text 'static_index_true_candidate.gd' $trueStaticText
if ($trueStaticText.Replace('const FORMAL_ENABLED := true','const FORMAL_ENABLED := false') -cne $oldStaticText) { throw 'STATIC_INDEX_INVERSE_FAILED' }
$trueClosure = Clone $falseClosure
$trueClosure.status = 'PROPOSED_TRUE_SOURCE_SUCCESSOR_NOT_DEPLOYED'
$trueClosure.source_sha256[$indexPath] = Sha $trueIndexFile
$trueClosure['prior_false_closure_sha256'] = Sha $falseClosurePath
$trueClosureFile = Write-J 'frozen_static_closure_true_proposed.json' $trueClosure
$replacements = @{}; foreach($t in $plan.candidate_targets) { $replacements[$t.target]=$t.candidate_sha256 }
# Keep the immutable imported v14 parent. Override only finite authored leaves.
$newTempleBinding = Clone $oldTempleBinding
$templeChanges = [ordered]@{}
foreach($p in @('res://scripts/city/luoyang_harbour_life_runtime_20261016.gd','res://scripts/city/luoyang_city_tasks_20261016.gd')) {
    $old = if($newTempleBinding.source_delta.Contains($p)) { $newTempleBinding.source_delta[$p] } else { $null }
    $basis = if($null -ne $old) { $old } else { $parent.source_sha256[$p] }
    $t = @($plan.candidate_targets | Where-Object target -eq $p)[0]
    if($basis -cne $t.old_sha256) { throw "TEMPLE_PREDECESSOR_CHANGED:$p" }
    $templeChanges[$p]=[ordered]@{existed=($null -ne $old);old_sha256=$old;new_sha256=$replacements[$p]}
    $newTempleBinding.source_delta[$p]=$replacements[$p]
}
foreach($p in $trueClosure.source_sha256.Keys) {
    if($newTempleBinding.source_delta.Contains($p)) { throw "NEW_STATIC_TEMPLE_SOURCE_COLLISION:$p" }
    $templeChanges[$p]=[ordered]@{existed=$false;old_sha256=$null;new_sha256=$trueClosure.source_sha256[$p]}
    $newTempleBinding.source_delta[$p]=$trueClosure.source_sha256[$p]
}
$newTempleBinding['military_static_source_successor']=[ordered]@{schema=1;prior_path=$temple.old_binding_path;prior_sha256=$temple.old_binding_sha256;source_changes=$templeChanges;scope='Four static identities, five stationary NPCs; geometry unchanged'}
$inverseTemple = Clone $newTempleBinding; $inverseTemple.Remove('military_static_source_successor') | Out-Null
foreach($p in $templeChanges.Keys) { $d=$templeChanges[$p]; if($d.existed) { $inverseTemple.source_delta[$p]=$d.old_sha256 } else { $inverseTemple.source_delta.Remove($p) | Out-Null } }
if (!(Same $inverseTemple $oldTempleBinding)) { throw 'TEMPLE_WHOLE_SEMANTIC_INVERSE_FAILED' }
$newTempleBindingFile = Write-J 'temple_binding.json' $newTempleBinding
$newTempleBindingPath = 'res://build/luoyang_military_static_presentation_20261019y_source01/staged/temple_binding.json'
$newTempleBindingSha = Sha $newTempleBindingFile
$newTempleText = $oldTempleText.Replace($temple.old_binding_path,$newTempleBindingPath).Replace($temple.old_binding_sha256,$newTempleBindingSha)
if ($newTempleText -ceq $oldTempleText -or $newTempleText.Replace($newTempleBindingPath,$temple.old_binding_path).Replace($newTempleBindingSha,$temple.old_binding_sha256) -cne $oldTempleText) { throw 'TEMPLE_HELPER_TWO_LITERAL_INVERSE_FAILED' }
$newTempleHelperFile=Write-Text 'Temple_helper_candidate.gd' $newTempleText
$newTempleHelperSha=Sha $newTempleHelperFile
$targets = @(); foreach($t in $plan.candidate_targets) { $targets += Clone $t }
$targets += [ordered]@{target=$indexPath;old_sha256=$falseClosure.source_sha256[$indexPath];candidate_path='res://build/luoyang_military_static_presentation_20261019y_source01/staged/static_index_true_candidate.gd';candidate_sha256=(Sha $trueIndexFile)}
$targets += [ordered]@{target=$temple.old_helper_path;old_sha256=$temple.old_helper_sha256;candidate_path='res://build/luoyang_military_static_presentation_20261019y_source01/staged/Temple_helper_candidate.gd';candidate_sha256=$newTempleHelperSha}
$inverseRecords=@(); $expectedPerCity=@{}; $newIndexText=$oldIndexText
foreach($city in $plan.per_city) {
    $oldManifest=Read-J (Disk $city.manifest_path);$newManifest=Clone $oldManifest
    $changes=[ordered]@{}; $delta=[ordered]@{}
    foreach($p in $city.replace_source_leaves.Keys) { $d=$city.replace_source_leaves[$p]; if($newManifest.legacy_source_sha256[$p] -cne $d.old_sha256){throw "LEGACY_PREDECESSOR_CHANGED:$p"};$delta[$p]=$d.new_sha256 }
    foreach($p in $city.explicit_add_existing_dependency_leaves.Keys) { if($newManifest.legacy_source_sha256.Contains($p)){throw "EXPLICIT_ADD_ALREADY_PRESENT:$p"}; $delta[$p]=$city.explicit_add_existing_dependency_leaves[$p] }
    foreach($p in $trueClosure.source_sha256.Keys) { if($newManifest.legacy_source_sha256.Contains($p)){throw "NEW_STATIC_LEGACY_COLLISION:$p"};$delta[$p]=$trueClosure.source_sha256[$p] }
    if($city.replace_temple_helper_if_owned) {
        if($newManifest.legacy_source_sha256[$temple.old_helper_path] -cne $temple.old_helper_sha256){throw 'LEGACY_TEMPLE_PREDECESSOR_CHANGED'}
        $delta[$temple.old_helper_path]=$newTempleHelperSha;$delta[$newTempleBindingPath]=$newTempleBindingSha
    }
    foreach($p in $delta.Keys) { $exists=$newManifest.legacy_source_sha256.Contains($p);$changes[$p]=[ordered]@{existed=$exists;old_sha256=$(if($exists){$newManifest.legacy_source_sha256[$p]}else{$null});new_sha256=$delta[$p]};$newManifest.legacy_source_sha256[$p]=$delta[$p] }
    $newManifest['military_static_successor']=[ordered]@{schema=1;prior_sha256=$city.manifest_sha256;source_changes=$changes;original_geometry_artifacts_and_publication_unchanged=$true;independent_source_baseline_path=$baselinePath;independent_source_baseline_sha256=$plan.independent_baseline.sha256}
    $inverse=Clone $newManifest;$inverse.Remove('military_static_successor')|Out-Null
    foreach($p in $changes.Keys){$d=$changes[$p];if($d.existed){$inverse.legacy_source_sha256[$p]=$d.old_sha256}else{$inverse.legacy_source_sha256.Remove($p)|Out-Null}}
    if(!(Same $inverse $oldManifest)){throw "MANIFEST_WHOLE_SEMANTIC_INVERSE_FAILED:$($city.id)"}
    $file=Write-J ($city.id+'/manifest.json') $newManifest;$hash=Sha $file
    $targets += [ordered]@{target=$city.manifest_path;old_sha256=$city.manifest_sha256;candidate_path=('res://build/luoyang_military_static_presentation_20261019y_source01/staged/'+$city.id+'/manifest.json');candidate_sha256=$hash}
    if([regex]::Matches($newIndexText,[regex]::Escape($city.manifest_sha256)).Count -ne 1){throw 'BUNDLE_INDEX_OLD_PIN_NOT_UNIQUE'}
    $newIndexText=$newIndexText.Replace($city.manifest_sha256,$hash)
    $record=@($records|Where-Object id -eq $city.id)[0]
    if($record.source_count -ne $city.count -or $record.actual_source_sha256.Count -ne $city.count){throw 'BASELINE_COUNT_CHANGED'}
    $expected=Clone $record.actual_source_sha256
    foreach($p in $delta.Keys){$expected[$p]=$delta[$p]}
    $expected[$city.manifest_path]=$hash
    $expectedPerCity[$city.id]=$expected
    $inverseRecords += [ordered]@{id=$city.id;whole_semantic_inverse=$true;old_source_count=$city.count;old_manifest_sha256=$city.manifest_sha256;new_manifest_sha256=$hash;finite_source_changes=$changes.Count}
}
$newIndexFile=Write-Text 'Bundle_index_candidate.gd' $newIndexText;$newIndexSha=Sha $newIndexFile
$inverseIndex=$newIndexText;foreach($t in $targets|Where-Object target -like '*/manifest.json'){$inverseIndex=$inverseIndex.Replace($t.candidate_sha256,$t.old_sha256)}
if($inverseIndex -cne $oldIndexText){throw 'BUNDLE_INDEX_FOUR_LITERAL_INVERSE_FAILED'}
$targets += [ordered]@{target=$bundleIndex;old_sha256='f834214c5ced741e73c2fbb7f9bac98ea35cce256c96bb40adf807bb9071e7ac';candidate_path='res://build/luoyang_military_static_presentation_20261019y_source01/staged/Bundle_index_candidate.gd';candidate_sha256=$newIndexSha}
foreach($id in $expectedPerCity.Keys){$expectedPerCity[$id][$bundleIndex]=$newIndexSha;Write-J ($id+'/expected_sources.json') ([ordered]@{status='INDEPENDENT_BASELINE_PLUS_FINITE_AUTHORED_DELTA';source_sha256=$expectedPerCity[$id];baseline_path=$baselinePath;baseline_sha256=$plan.independent_baseline.sha256})|Out-Null}
$deploySources=Clone $trueClosure.source_sha256
foreach($t in $targets){$deploySources[$t.target]=$t.candidate_sha256};$deploySources[$newTempleBindingPath]=$newTempleBindingSha
Write-J 'proposed_deployment_closure_true.json' ([ordered]@{status='PROPOSED_TRUE_DEPLOYMENT_NOT_DEPLOYED';source_sha256=$deploySources;targets=$targets;new_source_paths=@($newTempleBindingPath);prior_false_closure_sha256=(Sha $falseClosurePath)})|Out-Null
# Authored code is deployed by Root through apply_patch, never shell copies.
# Full-line patches retain the current LF/trailing-newline convention; exact
# old/new hashes above remain the independent byte-level post-apply authority.
$patch = "*** Begin Patch`n"
foreach($t in $targets | Where-Object target -like '*.gd') {
    $oldText=[IO.File]::ReadAllText((Disk $t.target));$candidateText=[IO.File]::ReadAllText((Disk $t.candidate_path))
    if($oldText.Contains("`r") -or $candidateText.Contains("`r") -or !$oldText.EndsWith("`n") -or !$candidateText.EndsWith("`n")){throw "CODE_NEWLINE_DOMAIN_CHANGED:$($t.target)"}
    $patch += '*** Update File: ' + (Disk $t.target).Replace('\','/') + "`n@@`n"
    foreach($line in $oldText.Substring(0,$oldText.Length-1).Split("`n")){$patch += '-' + $line + "`n"}
    foreach($line in $candidateText.Substring(0,$candidateText.Length-1).Split("`n")){$patch += '+' + $line + "`n"}
}
$patch += "*** End Patch`n"
Write-Text 'authored_code_deployment.apply_patch' $patch | Out-Null
$receipt=[ordered]@{status='STAGED_ONLY_NOT_DEPLOYED';stage_directory=$stageRoot;targets=$targets;inverse_records=$inverseRecords;temple_whole_semantic_inverse=$true;temple_two_literal_inverse=$true;bundle_four_literal_inverse=$true;static_index_sole_bool_inverse=$true;geometry_artifact_sources_preserved=$true;independent_expected_source_counts=[ordered]@{};scope='Four static identities / five NPCs, seven unchanged. CPU and one Gate only; no new actual collectors.'}
foreach($id in @($expectedPerCity.Keys|Sort-Object)){$receipt.independent_expected_source_counts[$id]=$expectedPerCity[$id].Count}
Write-J 'stage_receipt.json' $receipt | Out-Null
$receipt | ConvertTo-Json -Depth 8
