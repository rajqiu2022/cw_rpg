param([string]$Workspace = 'F:\Code\RPG_GAME')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
# Mechanical NEW-only staging. This script never deploys canonical files.
$gameRoot = Join-Path $Workspace 'game'
$package = 'res://build/luoyang_docks_district08_runtime_20261019ab_source01/'
$sourceRoot = Join-Path $gameRoot $package.Substring(6)
$stageRoot = [IO.Path]::GetFullPath((Join-Path $sourceRoot 'staged'))
if (Test-Path -LiteralPath $stageRoot) { throw 'STAGED_ALREADY_EXISTS_PRESERVE_EVIDENCE' }
function Disk([string]$p) {
    if (!$p.StartsWith('res://') -or $p.Contains('..')) { throw "BAD_RESOURCE_PATH:$p" }
    return Join-Path $gameRoot $p.Substring(6)
}
function Sha([string]$p) { return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant() }
function Assert-Sha([string]$p,[string]$s) {
    if ($s -notmatch '^[0-9a-f]{64}$' -or (Sha (Disk $p)) -cne $s) { throw "SOURCE_CHANGED:$p" }
}
function J([string]$p) { return Get-Content -Raw -LiteralPath (Disk $p) | ConvertFrom-Json -AsHashtable }
function Clone($v) { return $v | ConvertTo-Json -Depth 100 -Compress | ConvertFrom-Json -AsHashtable }
function Canon($v) {
    if ($v -is [Collections.IDictionary]) {
        $r=[ordered]@{}; foreach($k in @($v.Keys|Sort-Object -CaseSensitive)) { $r[$k]=Canon $v[$k] }; return $r
    }
    if ($v -is [array]) { return ,@($v|ForEach-Object { Canon $_ }) }
    return $v
}
function Same($a,$b) { return ((Canon $a)|ConvertTo-Json -Depth 100 -Compress) -ceq ((Canon $b)|ConvertTo-Json -Depth 100 -Compress) }
function W([string]$rel,[string]$text) {
    $p=[IO.Path]::GetFullPath((Join-Path $stageRoot $rel))
    if (!$p.StartsWith($stageRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'WRITE_OUTSIDE_NEW_STAGED' }
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($p))|Out-Null
    [IO.File]::WriteAllText($p,$text,[Text.UTF8Encoding]::new($false)); return $p
}
function WJ([string]$rel,$v) { return W $rel (($v|ConvertTo-Json -Depth 100)+"`n") }
function AddExact($map,[string]$p,[string]$s) {
    if ($map.Contains($p) -and $map[$p] -cne $s) { throw "SOURCE_COLLISION:$p" }; $map[$p]=$s
}
$B='res://scripts/city/luoyang_precomputed_bundle_20261018r.gd'
$HC='res://scripts/city/luoyang_harbour_life_runtime_20261016.gd'
$DT='res://scripts/city/luoyang_district_life_20261016f.gd'
$BI='res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd'
$AI='res://scripts/city/luoyang_docks_district08_index_20261019aa.gd'
$AM='res://scripts/city/luoyang_docks_district08_20261019aa.gd'
$AA='res://data/maps/luoyang_docks_district08_20261019aa/author.json'
$oldRoot='res://data/maps/luoyang_layout_bundle_20261018t_retry2/'
$aaRoot='res://data/maps/luoyang_docks_district08_20261019aa/runtime/'
$docks='ch4_s2_canal_docks'
$aaManifestPath=$aaRoot+$docks+'/manifest.json'
$cpuPath='res://build/luoyang_docks_district08_20261019aa_cpu/111516/result.json'
$importPath='res://build/luoyang_docks_district08_mask_import_20261019aa_source01/isolate/aa_mask_import_result_114508.json'
$baselinePath='res://build/luoyang_culture_source_admission_20261019x/115872/result.json'
$baselineSHA='fbb3c4754ed8d897fa1edcdf4c8779f7173aad6b39c057179ca1a50e3ab031d4'
$helper='res://scripts/city/luoyang_temple_assembly_20261016.gd'
$oldBindingPath='res://build/luoyang_culture_integration_20261019x_root01/temple_binding_retry1.json'
$oldBindingSHA='4e4272d280997011766f9c2d91d37177bfb32b75c964c774e89721cad33340da'
$helperSHA='ef44e7538690b2206c23836568afe50e51f1f102bbeedf0e4b22cd12b4a09aa9'
$newBindingPath=$package+'staged/temple_binding.json'
$oldSHAs=@{
 $B='833f2f78bb504e83a09c722c7d17c02c4d08c3e91e99cbde7147cf510cf8f931'
 $HC='1a269bc65df4aa70edd59a67ee5415768bee039ea52188939905746a99ef61ad'
 $DT='bcd4e401303e97cd65075c86c9bba6d08c4b3d542a36a1ec546f73c949670118'
}
$candidatePaths=@{$B=$package+'Bundle_candidate.gd';$HC=$package+'Harbour_candidate.gd';$DT=$package+'District_candidate.gd'}
$candidateSHAs=@{
 $B='c5195580454a09b5db0270e0841bd5bba2ccf53dc57e351803456e7c04e4e8b5'
 $HC='f20e9acb1fe4030af3de929b1c9390f243855d9e20ed20c877a5e68dd9201b6a'
 $DT='0137393f3715558887f0c69598c4346e5a2e9cd9b1b9c1091f85ea12a0f6afea'
}
$pins=@{
 $AM='13d90a3eff5dd26a9edb310292914e7c0ad1312229fd4ad6e0e2b5761aabf001'
 $AA='c3ba8c0a6a00738419a5733bbaa1faf34eef6add10fa89de3d6d7ba08a459c47'
 $AI='ff75cf2708a14325cc543b7277ebe29673aeccd56c28a2d4dd06e299f46a5d2f'
 $BI='f834214c5ced741e73c2fbb7f9bac98ea35cce256c96bb40adf807bb9071e7ac'
 $cpuPath='d99ca2d36a4b392ae76e73c6e1747042cb4ca9208497c4bb6434e10e3be9b0ce'
 $importPath='342b38e3c2ec09c0a5478210274e012e28e4362e79422ae0e45635a136988f30'
 $helper=$helperSHA; $oldBindingPath=$oldBindingSHA; $baselinePath=$baselineSHA
 'res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd'='c68272dd8bb2fd989a7776a1ee970a0d082290927d1fd30734c72d59b1d0fe50'
 'res://scripts/field/field_walkable_controller.gd'='f4be15c219c7873ae37d918c3b989bbbfabf4b782b4ee5711bbf9d6b2c0900ee'
 'res://scripts/field/npc_node.gd'='67c0f3deafef65445918b5815f4acdcb4cc577206248f20cd67a998930d00bea'
 'res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd'='fc9339579a0091936cf1bb747e84667e017d0eb57ffd025918023601afc51da9'
 'res://data/luoyang_culture_integration_20261019x/runtime_contract.json'='da49fe454e9ab975485e75e96772834f2a8c312463cf96bff8aceb6c0d050c1f'
 'res://scripts/autoload/game_state.gd'='9120f2c11c78eed304896bb6c9aa365b9db525711a7e1b17a43d13205bf94c4e'
 'res://data/maps/luoyang_temple_assembly_20261016/binding_editor_save_recovery_v14.json'='2a46baf36fc2667d0c62b789914738b72e30b085906dd066bcf55d594a0cd406'
}
foreach($p in $pins.Keys) { Assert-Sha $p $pins[$p] }
foreach($p in $oldSHAs.Keys) { Assert-Sha $p $oldSHAs[$p]; Assert-Sha $candidatePaths[$p] $candidateSHAs[$p] }
$author=J $AA;foreach($p in $author.source_sha256.Keys) { Assert-Sha $p $author.source_sha256[$p] }
$cpu=J $cpuPath; $import=J $importPath; $baseline=J $baselinePath
if(!$cpu.passed -or !(Same $cpu.source_first $cpu.source_final) -or $cpu.parent_count -ne 27 -or $cpu.child_count -ne 25 -or !$cpu.geometry.full87517 -or $cpu.geometry.local_mask.changed_pixels -ne 100622) { throw 'CPU_FACTS_CHANGED' }
if(!$import.passed -or $import.checks -ne 60 -or $import.failures.Count -ne 0 -or !$import.row.full_rgba_exact -or !$import.row.params23 -or !$import.row.zero_mipmaps -or !$import.row.cpu_evidence_exact -or !(Same $import.source_first $import.source_last)) { throw 'ISOLATED_IMPORT_FACTS_CHANGED' }
foreach($p in $cpu.artifacts.Keys) { Assert-Sha $p $cpu.artifacts[$p] }
Assert-Sha $cpu.walk_path $cpu.walk_sha256
Assert-Sha $import.row.import_path $import.row.import_sha256
Assert-Sha $import.row.compiled_path $import.row.compiled_sha256
if($baseline.complete -ne $false -or $baseline.failures -ne 1 -or $baseline.elapsed_ms -ne 91679) { throw 'BASELINE_OVERALL_FAIL_SCOPE_CHANGED' }
$records=@($baseline.records|Where-Object kind -eq 'METADATA_ONLY_FULL_COLLECTOR')
if($records.Count -ne 4) { throw 'FOUR_COMPLETED_SOURCE_ONLY_COMPONENTS_REQUIRED' }
$cityPins=@{
 'ch4_s0_luoyang_gate'='ee43127ae567a3cebd51eff37348eb60f072ae24280e49aaf0c7272ccf58ed69'
 'ch4_s1_luoyang_yamen'='86e9ab0056cfcda913919fff8b8ef7ee64f34344616a7f855a6c03e69ab9f954'
 'ch4_s2_canal_docks'='5ec9416acb7c0a5bcda2fe5c5969afe8254145e8fa6a1e3907469db36561b685'
 'ch4_s3_luoyang_market'='c466a84ebab5f774cea3d1667283ea859612b764a26e4f50ee01721612f882fc'
}
$oldManifests=@{};foreach($id in $cityPins.Keys) {
 $p=$oldRoot+$id+'/manifest.json';Assert-Sha $p $cityPins[$id];$m=J $p
 foreach($a in $m.artifacts.Keys) { Assert-Sha $a $m.artifacts[$a] }
 $oldManifests[$id]=$m
}
# Temple gets exactly the one runtime it already owns, no AA compile/artifact leaves.
$oldBinding=J $oldBindingPath;$temple=Clone $oldBinding
$templeParent=J $temple.parent_binding_path
$oldHC=if($temple.source_delta.Contains($HC)){$temple.source_delta[$HC]}else{$templeParent.source_sha256[$HC]}
if($oldHC -cne $oldSHAs[$HC]) { throw 'TEMPLE_HARBOUR_PREDECESSOR_CHANGED' }
$existed=$temple.source_delta.Contains($HC);$oldDelta=if($existed){$temple.source_delta[$HC]}else{$null}
$temple.source_delta[$HC]=$candidateSHAs[$HC]
$temple['docks08_ab_successor']=[ordered]@{prior_path=$oldBindingPath;prior_sha256=$oldBindingSHA;source_changes=@{$HC=@{existed=$existed;old_sha256=$oldDelta;new_sha256=$candidateSHAs[$HC]}};geometry_imports_and_v14_parent_unchanged=$true}
$inverse=Clone $temple;$inverse.Remove('docks08_ab_successor')|Out-Null
if($existed){$inverse.source_delta[$HC]=$oldDelta}else{$inverse.source_delta.Remove($HC)|Out-Null}
if(!(Same $inverse $oldBinding)){throw 'TEMPLE_WHOLE_INVERSE_FAILED'}
$templeFile=WJ 'temple_binding.json' $temple;$templeSHA=Sha $templeFile
$oldHelper=[IO.File]::ReadAllText((Disk $helper))
$newHelper=$oldHelper.Replace($oldBindingPath,$newBindingPath).Replace($oldBindingSHA,$templeSHA)
if($newHelper.Replace($newBindingPath,$oldBindingPath).Replace($templeSHA,$oldBindingSHA) -cne $oldHelper) {throw 'TEMPLE_TWO_LITERAL_INVERSE_FAILED'}
$helperFile=W 'Temple_helper_candidate.gd' $newHelper;$newHelperSHA=Sha $helperFile
# AA's immutable author source set is tracked even when AA is disabled.
# Both generated index authorities are explicitly excluded from all manifest maps.
$aaDeps=Clone $author.source_sha256;AddExact $aaDeps $AM $pins[$AM];AddExact $aaDeps $AA $pins[$AA]
$fallback=@{};$finite=@{};$indexText=[IO.File]::ReadAllText((Disk $BI))
foreach($id in @($cityPins.Keys|Sort-Object)) {
 $old=$oldManifests[$id];$next=Clone $old;$changes=[ordered]@{}
 $replacements=Clone $candidateSHAs
 if($old.legacy_source_sha256.Contains($helper)) {$replacements[$helper]=$newHelperSHA;$replacements[$newBindingPath]=$templeSHA}
 if($id -eq $docks) {foreach($p in $aaDeps.Keys){$replacements[$p]=$aaDeps[$p]}}
 foreach($p in $replacements.Keys) {
  $category=if($old.legacy_source_sha256.Contains($p)){'legacy_source_sha256'}elseif($old.runtime_authority_sha256.Contains($p)){'runtime_authority_sha256'}elseif($id -eq $docks -and $p.StartsWith($oldRoot)){'runtime_authority_sha256'}else{'legacy_source_sha256'}
  $owned=$next[$category].Contains($p)
  if(!$owned -and $candidateSHAs.Contains($p)) {continue} # Never add unrelated runtime compile leaves to another city.
  $prior=if($owned){$next[$category][$p]}else{$null}
  if($oldSHAs.Contains($p) -and $prior -cne $oldSHAs[$p]) {throw "OWNED_RUNTIME_PREDECESSOR_CHANGED:$id/$p"}
  if($owned -and $prior -ceq $replacements[$p]) {continue}
  $changes[$p]=@{category=$category;existed=$owned;old_sha256=$prior;new_sha256=$replacements[$p]}
  $next[$category][$p]=$replacements[$p]
 }
 $next['docks08_ab_source_successor']=@{prior_sha256=$cityPins[$id];source_changes=$changes;independent_baseline_path=$baselinePath;independent_baseline_sha256=$baselineSHA;geometry_artifacts_publication_unchanged=$true}
 $inverse=Clone $next;$inverse.Remove('docks08_ab_source_successor')|Out-Null
 foreach($p in $changes.Keys){$d=$changes[$p];if($d.existed){$inverse[$d.category][$p]=$d.old_sha256}else{$inverse[$d.category].Remove($p)|Out-Null}}
 if(!(Same $inverse $old)){throw "FOUR_MANIFEST_WHOLE_INVERSE_FAILED:$id"}
 $file=WJ ($id+'/manifest.json') $next;$hash=Sha $file
 if([regex]::Matches($indexText,[regex]::Escape($cityPins[$id])).Count -ne 1){throw 'BUNDLE_PIN_NOT_UNIQUE'}
 $indexText=$indexText.Replace($cityPins[$id],$hash)
 $fallback[$id]=@{manifest=$next;file=$file;sha256=$hash};$finite[$id]=$changes
}
$indexFile=W 'Bundle_index_candidate.gd' $indexText;$indexSHA=Sha $indexFile
$indexInverse=$indexText;foreach($id in $cityPins.Keys){$indexInverse=$indexInverse.Replace($fallback[$id].sha256,$cityPins[$id])}
if($indexInverse -cne [IO.File]::ReadAllText((Disk $BI))){throw 'BUNDLE_FOUR_LITERAL_INVERSE_FAILED'}
# The new AA manifest is independent of the mutable fallback Docks manifest.
$aa=Clone $fallback[$docks].manifest
$aa.Remove('docks08_ab_source_successor')|Out-Null
$aa.geometry_proof_basis=$cpu.geometry_basis;$aa.author_path=$AA;$aa.author_sha256=$pins[$AA]
$aa.mask_sha256=$cpu.mask_sha256;$aa.artifacts=Clone $cpu.artifacts
$aa.layout_proof=Clone $cpu.geometry;$aa['aa_exact_remove_two']=$true
$aa['aa_publication']=@{cpu_path=$cpuPath;cpu_sha256=$pins[$cpuPath];import_path=$importPath;import_sha256=$pins[$importPath];immutable_parent_manifest_path=$author.parent_manifest_path;immutable_parent_manifest_sha256=$author.source_sha256[$author.parent_manifest_path];scope='New single-Docks geometry; original inherited publication source-first/final remain historical facts, not rewritten current-source claims';parent_count=27;child_count=25;ground_image_unchanged=$true;npcs_portals_returns_routes_exact=$true}
foreach($p in @($BI,$AI,$oldRoot+$docks+'/manifest.json')) { $aa.legacy_source_sha256.Remove($p)|Out-Null;$aa.runtime_authority_sha256.Remove($p)|Out-Null }
# Old three native inputs already occur in the baseline; retain them as authority.
foreach($p in $aaDeps.Keys) {
 if($p.StartsWith($oldRoot)) {$aa.legacy_source_sha256.Remove($p)|Out-Null;AddExact $aa.runtime_authority_sha256 $p $aaDeps[$p]}
 else {AddExact $aa.legacy_source_sha256 $p $aaDeps[$p]}
}
$extra=@{$cpuPath=$pins[$cpuPath];$importPath=$pins[$importPath];$cpu.walk_path=$cpu.walk_sha256;$import.row.import_path=$import.row.import_sha256;$import.row.compiled_path=$import.row.compiled_sha256}
foreach($p in $extra.Keys) {
 if($p.StartsWith($aaRoot)) {AddExact $aa.runtime_authority_sha256 $p $extra[$p]}
 else {AddExact $aa.legacy_source_sha256 $p $extra[$p]}
}
if($aa.legacy_source_sha256.Contains($AI) -or $aa.runtime_authority_sha256.Contains($AI) -or $aa.legacy_source_sha256.Contains($oldRoot+$docks+'/manifest.json')) {throw 'AA_MANIFEST_HASH_CYCLE'}
$aaFile=WJ 'AA_manifest.json' $aa;$aaSHA=Sha $aaFile
$oldAI=[IO.File]::ReadAllText((Disk $AI))
if([regex]::Matches($oldAI,'PENDING_CPU_AND_IMPORT_PUBLICATION').Count -ne 1 -or [regex]::Matches($oldAI,'const FORMAL_ENABLED=false').Count -ne 1){throw 'AA_OLD_FALSE_AUTHORITY_CHANGED'}
$falseAI=$oldAI.Replace('PENDING_CPU_AND_IMPORT_PUBLICATION',$aaSHA)
$trueAI=$falseAI.Replace('const FORMAL_ENABLED=false','const FORMAL_ENABLED=true')
$falseFile=W 'AA_index_false_candidate.gd' $falseAI;$trueFile=W 'AA_index_true_candidate.gd' $trueAI
$falseSHA=Sha $falseFile;$trueSHA=Sha $trueFile
if($trueAI.Replace('const FORMAL_ENABLED=true','const FORMAL_ENABLED=false') -cne $falseAI){throw 'AA_TRUE_SOLE_BOOL_INVERSE_FAILED'}
# Independent expected maps: old completed x collector plus only authored finite deltas.
$expectedMaps=@{};foreach($r in $records) {
 $id=$r.id;$expected=Clone $r.actual_source_sha256
 if($expected.Count -ne $r.source_count){throw 'BASELINE_SOURCE_COUNT_CHANGED'}
 foreach($p in $finite[$id].Keys){$expected[$p]=$finite[$id][$p].new_sha256}
 $expected[$oldRoot+$id+'/manifest.json']=$fallback[$id].sha256;$expected[$BI]=$indexSHA
 if($id -eq $docks){$expected[$AI]=$falseSHA}
 $expectedMaps[$id]=$expected
 WJ ($id+'/expected_sources_false.json') @{status='INDEPENDENT_X_BASELINE_PLUS_FINITE_DELTA';phase='AA_DISABLED_FALLBACK';baseline_path=$baselinePath;baseline_sha256=$baselineSHA;source_sha256=$expected}|Out-Null
}
$candidate=Clone $expectedMaps[$docks]
$candidate.Remove($oldRoot+$docks+'/manifest.json')|Out-Null
foreach($p in $extra.Keys){AddExact $candidate $p $extra[$p]}
foreach($p in $cpu.artifacts.Keys){AddExact $candidate $p $cpu.artifacts[$p]}
AddExact $candidate $aaManifestPath $aaSHA
$formal=Clone $candidate;$formal[$AI]=$trueSHA
WJ ($docks+'/expected_sources_candidate.json') @{status='INDEPENDENT_X_BASELINE_PLUS_FINITE_DELTA';phase='AA_FLAG_WITH_FALSE_INDEX';source_sha256=$candidate;baseline_path=$baselinePath;baseline_sha256=$baselineSHA}|Out-Null
WJ ($docks+'/expected_sources_true.json') @{status='INDEPENDENT_X_BASELINE_PLUS_FINITE_DELTA';phase='AA_FORMAL_TRUE_INDEX';source_sha256=$formal;baseline_path=$baselinePath;baseline_sha256=$baselineSHA}|Out-Null
# An independent set equation catches dropped source leaves before any collector.
$set=Clone $aa.legacy_source_sha256;foreach($p in $aa.runtime_authority_sha256.Keys){AddExact $set $p $aa.runtime_authority_sha256[$p]};foreach($p in $aa.artifacts.Keys){AddExact $set $p $aa.artifacts[$p]}
AddExact $set $BI $indexSHA;AddExact $set $AI $trueSHA;AddExact $set $aaManifestPath $aaSHA
if(!(Same $set $formal)){throw 'AA_TRUE_EXPECTED_SET_EQUATION_FAILED'}
foreach($id in $expectedMaps.Keys){
 $m=$fallback[$id].manifest;$set=Clone $m.legacy_source_sha256
 foreach($p in $m.runtime_authority_sha256.Keys){AddExact $set $p $m.runtime_authority_sha256[$p]};foreach($p in $m.artifacts.Keys){AddExact $set $p $m.artifacts[$p]}
 AddExact $set $BI $indexSHA;AddExact $set ($oldRoot+$id+'/manifest.json') $fallback[$id].sha256
 if($id -eq $docks){AddExact $set $AI $falseSHA}
 if(!(Same $set $expectedMaps[$id])){throw "FALLBACK_EXPECTED_SET_EQUATION_FAILED:$id"}
 if($id -ne $docks -and ($set.Contains($AM) -or $set.Contains($AA) -or $set.Contains($AI))){throw "OTHER_CITY_AA_COMPILE_LEAK:$id"}
}
$targets=@();foreach($p in $candidatePaths.Keys){$targets+=@{target=$p;old_sha256=$oldSHAs[$p];candidate_path=$candidatePaths[$p];candidate_sha256=$candidateSHAs[$p]}}
$targets+=@{target=$helper;old_sha256=$helperSHA;candidate_path=$package+'staged/Temple_helper_candidate.gd';candidate_sha256=$newHelperSHA}
$targets+=@{target=$BI;old_sha256=$pins[$BI];candidate_path=$package+'staged/Bundle_index_candidate.gd';candidate_sha256=$indexSHA}
$targets+=@{target=$AI;old_sha256=$pins[$AI];candidate_path=$package+'staged/AA_index_false_candidate.gd';candidate_sha256=$falseSHA}
foreach($id in $cityPins.Keys){$targets+=@{target=$oldRoot+$id+'/manifest.json';old_sha256=$cityPins[$id];candidate_path=$package+'staged/'+$id+'/manifest.json';candidate_sha256=$fallback[$id].sha256}}
$newFiles=@{$aaManifestPath=@{candidate_path=$package+'staged/AA_manifest.json';sha256=$aaSHA};$newBindingPath=@{candidate_path=$newBindingPath;sha256=$templeSHA}}
if(Test-Path -LiteralPath (Disk $aaManifestPath)){throw 'NEW_AA_MANIFEST_TARGET_ALREADY_EXISTS'}
foreach($p in @($newBindingPath)) {if((Sha (Disk $p)) -cne $newFiles[$p].sha256){throw 'NEW_STAGED_BINDING_SHA_CHANGED'}}
function CodePatch($rows) {
 $patch="*** Begin Patch`n"
 foreach($t in $rows|Where-Object target -like '*.gd'){
  $lines=@(& git -c core.autocrlf=false diff --no-index --unified=3 -- (Disk $t.target) (Disk $t.candidate_path))
  if($LASTEXITCODE -ne 1){throw "EXPECTED_CODE_DIFF_MISSING:$($t.target)"}
  $patch+='*** Update File: '+(Disk $t.target).Replace('\','/')+"`n"
  $inHunk=$false;foreach($line in $lines){if($line.StartsWith('@@')){$inHunk=$true;$patch+="@@`n"}elseif($inHunk){if($line.StartsWith('\ No newline')){throw 'NEWLINE_DOMAIN_CHANGED'};$patch+=$line+"`n"}}
 }
 return $patch+"*** End Patch`n"
}
W 'minimal_authored_code_false_deployment.apply_patch' (CodePatch $targets)|Out-Null
$flip="*** Begin Patch`n*** Update File: "+(Disk $AI).Replace('\','/')+"`n@@`n-const FORMAL_ENABLED=false`n+const FORMAL_ENABLED=true`n*** End Patch`n"
W 'sole_bool_true_after_candidate.apply_patch' $flip|Out-Null
$receipt=@{status='STAGED_ONLY_NOT_DEPLOYED';targets=$targets;new_files=$newFiles;source_baseline_path=$baselinePath;source_baseline_sha256=$baselineSHA;AA_manifest_sha256=$aaSHA;AA_index_old_sha256=$pins[$AI];AA_index_false_sha256=$falseSHA;AA_index_true_sha256=$trueSHA;four_manifest_whole_inverses=$true;temple_whole_inverse=$true;temple_two_literal_inverse=$true;bundle_four_literal_inverse=$true;all_twelve_old_native_artifacts_unchanged=$true;false_counts=@{};Docks_candidate_count=$candidate.Count;Docks_true_count=$formal.Count;other_three_cities_AA_compile_leaves_absent=$true;no_engine_or_canonical_deployment=$true}
foreach($id in $expectedMaps.Keys){$receipt.false_counts[$id]=$expectedMaps[$id].Count}
WJ 'stage_receipt.json' $receipt|Out-Null
$receipt|ConvertTo-Json -Depth 12
