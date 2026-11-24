param([string]$Workspace='F:\Code\RPG_GAME')
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
# NEW-only mechanical source succession. No engine, collector or deployment.
$gameRoot=Join-Path $Workspace 'game'
$package='res://build/luoyang_docks_workyard_20261019ac_source01/'
$stageRoot=Join-Path $gameRoot ($package.Substring(6)+'staged')
if(Test-Path -LiteralPath $stageRoot){throw 'STAGED_EXISTS_PRESERVE_EVIDENCE'}
function Disk([string]$p){if(!$p.StartsWith('res://') -or $p.Contains('..')){throw 'BAD_RESOURCE_PATH'};return Join-Path $gameRoot $p.Substring(6)}
function Sha([string]$p){return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function AssertSha([string]$p,[string]$s){if($s -notmatch '^[0-9a-f]{64}$' -or (Sha (Disk $p)) -cne $s){throw "SOURCE_CHANGED:$p"}}
function J([string]$p){return Get-Content -Raw -LiteralPath (Disk $p)|ConvertFrom-Json -AsHashtable}
function Clone($v){return $v|ConvertTo-Json -Depth 100 -Compress|ConvertFrom-Json -AsHashtable}
function Canon($v){if($v -is [Collections.IDictionary]){$o=[ordered]@{};foreach($k in @($v.Keys|Sort-Object -CaseSensitive)){$o[$k]=Canon $v[$k]};return $o};if($v -is [array]){return ,@($v|ForEach-Object{Canon $_})};return $v}
function Same($a,$b){return ((Canon $a)|ConvertTo-Json -Depth 100 -Compress) -ceq ((Canon $b)|ConvertTo-Json -Depth 100 -Compress)}
function W([string]$rel,[string]$text){$p=[IO.Path]::GetFullPath((Join-Path $stageRoot $rel));if(!$p.StartsWith($stageRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'OUTSIDE_NEW_STAGE'};[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($p))|Out-Null;[IO.File]::WriteAllText($p,$text,[Text.UTF8Encoding]::new($false));return $p}
function WJ([string]$rel,$v){return W $rel (($v|ConvertTo-Json -Depth 100)+"`n")}
function AddExact($map,[string]$p,[string]$s){if($map.Contains($p) -and $map[$p] -cne $s){throw "SOURCE_COLLISION:$p"};$map[$p]=$s}
function ImportClosure($map){
 # Same fixed file rule as C._transition_sources, independently from source files.
 # Snapshot keys: C adds one existing .import and every path* remap, not arbitrary files.
 foreach($p in @($map.Keys)){
  $ip=$p+'.import';if(!(Test-Path -LiteralPath (Disk $ip))){continue}
  AddExact $map $ip (Sha (Disk $ip))
  $text=[IO.File]::ReadAllText((Disk $ip));$remap=[regex]::Match($text,'(?ms)^\[remap\]\r?\n(.*?)(?=^\[|\z)').Groups[1].Value
  foreach($m in [regex]::Matches($remap,'(?m)^path[^=\r\n]*="([^"]+)"\r?$')){$rp=$m.Groups[1].Value;AddExact $map $rp (Sha (Disk $rp))}
 }
 return $map
}
$bundle='res://scripts/city/luoyang_precomputed_bundle_20261018r.gd'
$bundleIndex='res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd'
$aaIndex='res://scripts/city/luoyang_docks_district08_index_20261019aa.gd'
$acIndex='res://scripts/city/luoyang_docks_workyard_index_20261019ac.gd'
$acModule='res://scripts/city/luoyang_docks_workyard_20261019ac.gd'
$acAuthorPath='res://data/maps/luoyang_docks_workyard_20261019ac/author.json'
$oldRoot='res://data/maps/luoyang_layout_bundle_20261018t_retry2/'
$aaRoot='res://data/maps/luoyang_docks_district08_20261019aa/runtime/'
$acRoot='res://data/maps/luoyang_docks_workyard_20261019ac/runtime/'
$docks='ch4_s2_canal_docks'
$aaManifestPath=$aaRoot+$docks+'/manifest.json'
$acManifestPath=$acRoot+$docks+'/manifest.json'
$cpuPath='res://build/luoyang_docks_workyard_20261019ac_cpu/114284/result.json'
$importProofPath='res://build/luoyang_docks_workyard_20261019ac_qa01/isolate/ac_mask_import_result_118860.json'
$abPackage='res://build/luoyang_docks_district08_runtime_20261019ab_source01/retry2/'
$baselinePath=$abPackage+'expected_sources_true.json'
$pins=@{
 $bundle='c5195580454a09b5db0270e0841bd5bba2ccf53dc57e351803456e7c04e4e8b5'
 $bundleIndex='97345a2c393808a3e16303eebc8d1b4d69277a51820f485db5fc96a067180c1c'
 $aaIndex='cb716ee5dd1dae3d0d1146448d04b91847508f5c297b36d922be208944e43b1d'
 $aaManifestPath='04444504ef888a80f25ac8a6349887bd20f0f0f7d2157efd403edc26670b61eb'
 $acIndex='b219d1da67b37bcc812467261c56a8c40f49381df78b00addef8674ea0576cff'
 $acModule='71f57304c3da2a78b5ca16ff10f2b4dae89485f358015f16477cabc178a3b0c5'
 $acAuthorPath='85dff749b846c5f49992f4a1ae137771af4fa78faf0cca98af69c97a870e8194'
 ($package+'Bundle_candidate.gd')='62f2166a39857a911c5e2b07abfaa6de057a6f5d03ddc5b3eb897e0430bfd631'
 ($package+'publish_add_four_cpu.gd')='291b8bef4c25ab1a52630414768dae6d768e5cda11e3c4598213007f4cdb4b31'
 $cpuPath='bb6aeef4a5faf77f2376671e6942946276af33374bedf9566c2fb67ad670fd34'
 $importProofPath='b5ce9ce5154db24fb590f39afb417c0eae600087ab1c60f2904342024b79a30b'
 $baselinePath='ed1ac3c71685cd76aba4fb941cc85337ea26c84a4c7eac8cad52564ba6bf1ddf'
 'res://scripts/city/luoyang_harbour_life_runtime_20261016.gd'='f20e9acb1fe4030af3de929b1c9390f243855d9e20ed20c877a5e68dd9201b6a'
 'res://scripts/city/luoyang_district_life_20261016f.gd'='0137393f3715558887f0c69598c4346e5a2e9cd9b1b9c1091f85ea12a0f6afea'
 'res://scripts/city/luoyang_temple_assembly_20261016.gd'='54e99f7731129451f06a6ba8e722c79e7d1e46181775d646f0c28f524ae5514c'
 'res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd'='c68272dd8bb2fd989a7776a1ee970a0d082290927d1fd30734c72d59b1d0fe50'
 'res://scripts/field/field_walkable_controller.gd'='f4be15c219c7873ae37d918c3b989bbbfabf4b782b4ee5711bbf9d6b2c0900ee'
 'res://scripts/field/npc_node.gd'='67c0f3deafef65445918b5815f4acdcb4cc577206248f20cd67a998930d00bea'
 'res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd'='fc9339579a0091936cf1bb747e84667e017d0eb57ffd025918023601afc51da9'
 'res://data/luoyang_culture_integration_20261019x/runtime_contract.json'='da49fe454e9ab975485e75e96772834f2a8c312463cf96bff8aceb6c0d050c1f'
 'res://scripts/autoload/game_state.gd'='9120f2c11c78eed304896bb6c9aa365b9db525711a7e1b17a43d13205bf94c4e'
}
foreach($p in $pins.Keys){AssertSha $p $pins[$p]}
if(Test-Path -LiteralPath (Disk $acManifestPath)){throw 'AC_NEW_MANIFEST_ALREADY_EXISTS'}
$bundleNewSHA=$pins[$package+'Bundle_candidate.gd']
$cpu=J $cpuPath;$importProof=J $importProofPath;$acAuthorDoc=J $acAuthorPath
if(!$cpu.passed -or !(Same $cpu.source_first $cpu.source_final) -or $cpu.parent_count -ne 25 -or $cpu.child_count -ne 29 -or !$cpu.geometry.full87517 -or $cpu.geometry.mask_delta.blocked_pixels -ne 19594 -or !$cpu.geometry.combined.full87517){throw 'FROZEN_CPU_FACTS_CHANGED'}
if(!$importProof.passed -or $importProof.checks -ne 60 -or $importProof.failures.Count -ne 0 -or !$importProof.row.full_rgba_exact -or !$importProof.row.params23 -or !$importProof.row.zero_mipmaps -or !$importProof.row.cpu_evidence_exact -or !(Same $importProof.source_first $importProof.source_last)){throw 'FROZEN_IMPORT_FACTS_CHANGED'}
foreach($p in $acAuthorDoc.source_sha256.Keys){AssertSha $p $acAuthorDoc.source_sha256[$p]}
foreach($p in $cpu.artifacts.Keys){AssertSha $p $cpu.artifacts[$p]}
AssertSha $cpu.walk_path $cpu.walk_sha256
AssertSha $importProof.row.import_path '26924ebb6aee9f9de227734fddf99687ce65ec76bad0ba8b5923e7beb43292ca'
AssertSha $importProof.row.compiled_path '2275144d270da698670cc5dc4dd7ad9676dea2962825c818b7ad5dcddee5ec92'
$acDeps=Clone $acAuthorDoc.source_sha256
AddExact $acDeps $acModule $pins[$acModule];AddExact $acDeps $acAuthorPath $pins[$acAuthorPath]
$acDeps=ImportClosure $acDeps
foreach($p in @($bundleIndex,$aaIndex,$acIndex,$aaManifestPath,$acManifestPath)){
 if($acDeps.Contains($p)){throw "IMMUTABLE_AUTHOR_DEPENDENCY_WOULD_CREATE_INDEX_OR_MANIFEST_CYCLE:$p"}
}
function ChangeManifest($old,$additions,[string]$priorSHA,[bool]$docksSource){
 $next=Clone $old;$changes=[ordered]@{}
 $updates=@{$bundle=$bundleNewSHA};if($docksSource){foreach($p in $additions.Keys){AddExact $updates $p $additions[$p]}}
 foreach($p in $updates.Keys){
  $category=if($next.legacy_source_sha256.Contains($p)){'legacy_source_sha256'}elseif($next.runtime_authority_sha256.Contains($p)){'runtime_authority_sha256'}elseif($p.StartsWith($oldRoot)){'runtime_authority_sha256'}else{'legacy_source_sha256'}
  $exists=$next[$category].Contains($p);$prior=if($exists){$next[$category][$p]}else{$null}
  if($p -ceq $bundle -and $prior -cne $pins[$bundle]){throw 'OWNED_BUNDLE_PREDECESSOR_CHANGED'}
  if($exists -and $prior -ceq $updates[$p]){continue}
  $changes[$p]=@{category=$category;existed=$exists;old_sha256=$prior;new_sha256=$updates[$p]};$next[$category][$p]=$updates[$p]
 }
 $next['workyard_ac_source_successor']=@{prior_sha256=$priorSHA;source_changes=$changes;independent_baseline_path=$baselinePath;independent_baseline_sha256=$pins[$baselinePath];geometry_artifacts_and_original_publication_unchanged=$true}
 $inverse=Clone $next;$inverse.Remove('workyard_ac_source_successor')|Out-Null
 foreach($p in $changes.Keys){$d=$changes[$p];if($d.existed){$inverse[$d.category][$p]=$d.old_sha256}else{$inverse[$d.category].Remove($p)|Out-Null}}
 if(!(Same $inverse $old)){throw 'WHOLE_MANIFEST_SOURCE_INVERSE_FAILED'}
 return @{manifest=$next;changes=$changes;whole_inverse=$true}
}
$cityPins=@{
 ch4_s0_luoyang_gate='9d7160d878ea2441c5d765d5e9b4e99140592129608cdb1f1f1260377a527065'
 ch4_s1_luoyang_yamen='5428674069217be2d44712dd82bc19698a9579f6655a53c2d0b3430a404a03ef'
 ch4_s2_canal_docks='986521035fe38be0d652c2dd5bea11ae4e3360e45527d225a80d415b57e7fe06'
 ch4_s3_luoyang_market='bb1d04cf1cb3be5df2e9d5031d8ebb9f2805555da747ffde5e3b9f032d382254'
}
$cityFacts=@{};$bundleIndexOld=[IO.File]::ReadAllText((Disk $bundleIndex));$bundleIndexNew=$bundleIndexOld
foreach($id in @($cityPins.Keys|Sort-Object)){
 $path=$oldRoot+$id+'/manifest.json';AssertSha $path $cityPins[$id];$old=J $path
 foreach($p in $old.artifacts.Keys){AssertSha $p $old.artifacts[$p]}
 $fact=ChangeManifest $old $acDeps $cityPins[$id] ($id -ceq $docks)
 $file=WJ ($id+'/manifest.json') $fact.manifest;$fact['sha256']=Sha $file;$fact['target']=$path;$fact['candidate_path']=$package+'staged/'+$id+'/manifest.json'
 if([regex]::Matches($bundleIndexNew,[regex]::Escape($cityPins[$id])).Count -ne 1){throw 'UNIQUE_BI_PIN_REQUIRED'}
 $bundleIndexNew=$bundleIndexNew.Replace($cityPins[$id],$fact.sha256);$cityFacts[$id]=$fact
}
$biInverse=$bundleIndexNew;foreach($id in $cityPins.Keys){$biInverse=$biInverse.Replace($cityFacts[$id].sha256,$cityPins[$id])}
if($biInverse -cne $bundleIndexOld){throw 'BUNDLE_FOUR_LITERAL_INVERSE_FAILED'}
$biFile=W 'Bundle_index_candidate.gd' $bundleIndexNew;$biSHA=Sha $biFile
$aaPrior=J $aaManifestPath
if($aaPrior.author_path -isnot [string] -or $aaPrior.author_sha256 -isnot [string]){throw 'AA_TYPED_AUTHOR_INVALID'}
$aaFact=ChangeManifest $aaPrior $acDeps $pins[$aaManifestPath] $true
$aaFile=WJ 'AA_manifest_source_successor.json' $aaFact.manifest;$aaSHA=Sha $aaFile
$aaIndexOld=[IO.File]::ReadAllText((Disk $aaIndex))
if([regex]::Matches($aaIndexOld,[regex]::Escape($pins[$aaManifestPath])).Count -ne 1 -or [regex]::Matches($aaIndexOld,'const FORMAL_ENABLED=true').Count -ne 1){throw 'AA_CURRENT_TRUE_AUTHORITY_CHANGED'}
$aaIndexNew=$aaIndexOld.Replace($pins[$aaManifestPath],$aaSHA)
if($aaIndexNew.Replace($aaSHA,$pins[$aaManifestPath]) -cne $aaIndexOld){throw 'AA_ONLY_MANIFEST_LITERAL_INVERSE_FAILED'}
$aiFile=W 'AA_index_candidate.gd' $aaIndexNew;$aiSHA=Sha $aiFile
# New geometry manifest retains immutable historical publication fields explicitly.
# Its current source domain is independent of the mutable AA fallback manifest.
$acManifestDoc=Clone $aaFact.manifest
$acManifestDoc.Remove('workyard_ac_source_successor')|Out-Null
$acManifestDoc.geometry_proof_basis=$cpu.geometry_basis
$acManifestDoc.author_path=$acAuthorPath;$acManifestDoc.author_sha256=$pins[$acAuthorPath]
$acManifestDoc.mask_sha256=$cpu.mask_sha256;$acManifestDoc.artifacts=Clone $cpu.artifacts
$acManifestDoc.layout_proof=Clone $cpu.geometry
$acManifestDoc['ac_exact_add_four']=$true
$acManifestDoc['ac_publication']=@{cpu_path=$cpuPath;cpu_sha256=$pins[$cpuPath];import_path=$importProofPath;import_sha256=$pins[$importProofPath];immutable_parent_manifest_path=$acAuthorDoc.parent_manifest_path;immutable_parent_manifest_sha256=$acAuthorDoc.source_sha256[$acAuthorDoc.parent_manifest_path];parent_count=25;child_count=29;ground_raw_water_and_existing_25_exact=$true;npcs_routes_portals_returns_tasks_exact=$true;scope='Only four workyard low props and their native solid/NAV; inherited AA/t publication/source-first/final remain historical facts, not fresh AC claims'}
foreach($p in @($bundleIndex,$aaIndex,$acIndex,$aaManifestPath,$acManifestPath)){$acManifestDoc.legacy_source_sha256.Remove($p)|Out-Null;$acManifestDoc.runtime_authority_sha256.Remove($p)|Out-Null}
$activeExtra=@{$cpuPath=$pins[$cpuPath];$importProofPath=$pins[$importProofPath];$cpu.walk_path=$cpu.walk_sha256;$importProof.row.import_path=$importProof.row.import_sha256;$importProof.row.compiled_path=$importProof.row.compiled_sha256}
$activeExtra=ImportClosure $activeExtra
foreach($p in $activeExtra.Keys){$category=if($p.StartsWith($acRoot)){'runtime_authority_sha256'}else{'legacy_source_sha256'};AddExact $acManifestDoc[$category] $p $activeExtra[$p]}
# AA parent three native inputs now remain independently pinned inputs, not active artifacts.
foreach($p in $aaPrior.artifacts.Keys){AddExact $acManifestDoc.runtime_authority_sha256 $p $aaPrior.artifacts[$p]}
foreach($p in @($bundleIndex,$aaIndex,$acIndex,$aaManifestPath,$acManifestPath)){if($acManifestDoc.legacy_source_sha256.Contains($p) -or $acManifestDoc.runtime_authority_sha256.Contains($p)){throw 'ACTIVE_HASH_CYCLE'}}
if($acManifestDoc.author_path -isnot [string] -or $acManifestDoc.author_path -cne $acAuthorPath -or $acManifestDoc.author_sha256 -cne $pins[$acAuthorPath]){throw 'ACTIVE_TYPED_AUTHOR_NOT_FIXED'}
$acFile=WJ 'AC_manifest.json' $acManifestDoc;$acSHA=Sha $acFile
$acIndexOld=[IO.File]::ReadAllText((Disk $acIndex))
if([regex]::Matches($acIndexOld,'PENDING_AC_CPU_IMPORT_SOURCE_PUBLICATION').Count -ne 1 -or [regex]::Matches($acIndexOld,'const FORMAL_ENABLED=false').Count -ne 1){throw 'AC_FALSE_AUTHORITY_CHANGED'}
$acFalseText=$acIndexOld.Replace('PENDING_AC_CPU_IMPORT_SOURCE_PUBLICATION',$acSHA)
$acTrueText=$acFalseText.Replace('const FORMAL_ENABLED=false','const FORMAL_ENABLED=true')
if($acTrueText.Replace('const FORMAL_ENABLED=true','const FORMAL_ENABLED=false') -cne $acFalseText){throw 'AC_TRUE_SOLE_BOOL_INVERSE_FAILED'}
$acFalseFile=W 'AC_index_false_candidate.gd' $acFalseText;$acTrueFile=W 'AC_index_true_candidate.gd' $acTrueText
$acFalseSHA=Sha $acFalseFile;$acTrueSHA=Sha $acTrueFile
function ManifestSet($manifest,[string]$mp,[string]$ms,[bool]$isDocks,[string]$acs){
 $set=Clone $manifest.legacy_source_sha256
 foreach($category in @('runtime_authority_sha256','artifacts')){foreach($p in $manifest[$category].Keys){AddExact $set $p $manifest[$category][$p]}}
 AddExact $set $bundleIndex $biSHA;AddExact $set $mp $ms
 if($isDocks){AddExact $set $aaIndex $aiSHA;AddExact $set $acIndex $acs}
 $closed=ImportClosure (Clone $set);if(!(Same $closed $set)){throw 'DECLARED_MANIFEST_MISSED_EXISTING_IMPORT_REMAP'}
 return $set
}
$base=J $baselinePath
if($base.source_sha256.Count -ne 1466 -or $base.source_sha256[$bundle] -cne $pins[$bundle] -or $base.source_sha256[$aaManifestPath] -cne $pins[$aaManifestPath] -or $base.source_sha256[$aaIndex] -cne $pins[$aaIndex]){throw 'INDEPENDENT_AB1466_PREDECESSOR_CHANGED'}
$disabled=Clone $base.source_sha256
foreach($p in $aaFact.changes.Keys){$disabled[$p]=$aaFact.changes[$p].new_sha256}
$disabled[$bundleIndex]=$biSHA;$disabled[$aaIndex]=$aiSHA;$disabled[$aaManifestPath]=$aaSHA
AddExact $disabled $acIndex $acFalseSHA
$candidate=Clone $disabled;$candidate.Remove($aaManifestPath)|Out-Null
foreach($p in $activeExtra.Keys){AddExact $candidate $p $activeExtra[$p]}
foreach($p in $cpu.artifacts.Keys){AddExact $candidate $p $cpu.artifacts[$p]}
AddExact $candidate $acManifestPath $acSHA
$formal=Clone $candidate;$formal[$acIndex]=$acTrueSHA
if(!(Same (ManifestSet $aaFact.manifest $aaManifestPath $aaSHA $true $acFalseSHA) $disabled)){throw 'AA25_DISABLED_EXPECTED_SET_EQUATION_FAILED'}
if(!(Same (ManifestSet $acManifestDoc $acManifestPath $acSHA $true $acFalseSHA) $candidate)){throw 'AC29_CANDIDATE_EXPECTED_SET_EQUATION_FAILED'}
if(!(Same (ManifestSet $acManifestDoc $acManifestPath $acSHA $true $acTrueSHA) $formal)){throw 'AC29_FORMAL_EXPECTED_SET_EQUATION_FAILED'}
# Finite map inverse is independent of manifest-set construction.
$inverse=Clone $disabled;$inverse.Remove($acIndex)|Out-Null
foreach($p in $aaFact.changes.Keys){$delta=$aaFact.changes[$p];if($delta.existed){$inverse[$p]=$delta.old_sha256}else{$inverse.Remove($p)|Out-Null}}
foreach($p in @($bundleIndex,$aaIndex,$aaManifestPath)){$inverse[$p]=$base.source_sha256[$p]}
if(!(Same $inverse $base.source_sha256)){throw 'DISABLED_AB1466_WHOLE_MAP_INVERSE_FAILED'}
$candidateInverse=Clone $candidate;$candidateInverse.Remove($acManifestPath)|Out-Null
foreach($p in @($activeExtra.Keys)+@($cpu.artifacts.Keys)){if(!$disabled.Contains($p)){$candidateInverse.Remove($p)|Out-Null}}
$candidateInverse[$aaManifestPath]=$aaSHA
if(!(Same $candidateInverse $disabled)){throw 'CANDIDATE_WHOLE_PHASE_INVERSE_FAILED'}
$formalInverse=Clone $formal;$formalInverse[$acIndex]=$acFalseSHA
if(!(Same $formalInverse $candidate)){throw 'FORMAL_ONLY_INDEX_HASH_INVERSE_FAILED'}
$maps=@{}
foreach($phase in @('false','candidate','true')){
 $map=switch($phase){'false'{$disabled};'candidate'{$candidate};'true'{$formal}}
 $file=WJ ('expected_sources_'+$phase+'.json') @{status='INDEPENDENT_AB1466_PLUS_FINITE_AC_DELTA';phase=$phase;baseline_path=$baselinePath;baseline_sha256=$pins[$baselinePath];source_sha256=$map}
 $maps[$phase]=@{path=$package+'staged/expected_sources_'+$phase+'.json';sha256=(Sha $file);count=$map.Count;whole_inverse=$true}
}
$otherMapPins=@{ch4_s0_luoyang_gate='41577f903126ae132ec8575ae59e4411ce22a29f678847bb66ab524e053f4f56';ch4_s1_luoyang_yamen='511ffc37e164ee248efffc567ad7960264e2de1bd411cc0684aa1c3b1e662e99';ch4_s3_luoyang_market='a8eb6c4ce5bbba5a1b40c64080e52754dee0f13d63ffddb29db85c2ba7f32ce1'}
foreach($id in $otherMapPins.Keys){
 $path=$abPackage+$id+'/expected_sources.json';AssertSha $path $otherMapPins[$id];$oldMap=J $path;$nextMap=Clone $oldMap.source_sha256
 if($nextMap[$bundle] -cne $pins[$bundle] -or $nextMap[$bundleIndex] -cne $pins[$bundleIndex] -or $nextMap[$cityFacts[$id].target] -cne $cityPins[$id]){throw 'OTHER_CITY_INDEPENDENT_PREDECESSOR_CHANGED'}
 $nextMap[$bundle]=$bundleNewSHA;$nextMap[$bundleIndex]=$biSHA;$nextMap[$cityFacts[$id].target]=$cityFacts[$id].sha256
 if(!(Same (ManifestSet $cityFacts[$id].manifest $cityFacts[$id].target $cityFacts[$id].sha256 $false '') $nextMap)){throw 'OTHER_CITY_EXPECTED_SET_EQUATION_FAILED'}
 foreach($p in $nextMap.Keys){if($p -match 'workyard_20261019ac|workyard_index_20261019ac'){throw 'OTHER_CITY_AC_SOURCE_LEAK'}}
 $back=Clone $nextMap;foreach($p in @($bundle,$bundleIndex,$cityFacts[$id].target)){$back[$p]=$oldMap.source_sha256[$p]}
 if(!(Same $back $oldMap.source_sha256)){throw 'OTHER_CITY_ONLY_THREE_SOURCE_LEAVES_INVERSE_FAILED'}
 $file=WJ ($id+'/expected_sources.json') @{status='INDEPENDENT_AB_BASELINE_ONLY_OWNED_B_AND_BI_AND_MANIFEST_SUCCESSOR';baseline_path=$path;baseline_sha256=$otherMapPins[$id];source_sha256=$nextMap}
 $maps[$id]=@{path=$package+'staged/'+$id+'/expected_sources.json';sha256=(Sha $file);count=$nextMap.Count;whole_inverse=$true}
}
$targets=@(@{target=$bundle;old_sha256=$pins[$bundle];candidate_path=$package+'Bundle_candidate.gd';candidate_sha256=$bundleNewSHA},@{target=$bundleIndex;old_sha256=$pins[$bundleIndex];candidate_path=$package+'staged/Bundle_index_candidate.gd';candidate_sha256=$biSHA},@{target=$aaIndex;old_sha256=$pins[$aaIndex];candidate_path=$package+'staged/AA_index_candidate.gd';candidate_sha256=$aiSHA},@{target=$acIndex;old_sha256=$pins[$acIndex];candidate_path=$package+'staged/AC_index_false_candidate.gd';candidate_sha256=$acFalseSHA},@{target=$aaManifestPath;old_sha256=$pins[$aaManifestPath];candidate_path=$package+'staged/AA_manifest_source_successor.json';candidate_sha256=$aaSHA})
foreach($id in $cityPins.Keys){$f=$cityFacts[$id];$targets+=@{target=$f.target;old_sha256=$cityPins[$id];candidate_path=$f.candidate_path;candidate_sha256=$f.sha256}}
$patch="*** Begin Patch`n"
foreach($t in $targets|Where-Object target -like '*.gd'){
 $lines=@(& git -c core.autocrlf=false diff --no-index --unified=3 -- (Disk $t.target) (Disk $t.candidate_path));if($LASTEXITCODE -ne 1){throw 'EXPECTED_CODE_DIFF_MISSING'}
 $patch+='*** Update File: '+(Disk $t.target).Replace('\','/')+"`n";$hunk=$false
 foreach($line in $lines){if($line.StartsWith('@@')){$hunk=$true;$patch+="@@`n"}elseif($hunk){if($line.StartsWith('\ No newline')){throw 'CODE_NEWLINE_DOMAIN_CHANGED'};$patch+=$line+"`n"}}
}
$patchFile=W 'minimal_authored_code_false_deployment.apply_patch' ($patch+"*** End Patch`n")
$flipFile=W 'sole_bool_true_after_candidate.apply_patch' ("*** Begin Patch`n*** Update File: "+(Disk $acIndex).Replace('\','/')+"`n@@`n-const FORMAL_ENABLED=false`n+const FORMAL_ENABLED=true`n*** End Patch`n")
$receipt=@{status='STAGED_ONLY_NOT_DEPLOYED';targets=$targets;new_files=@{$acManifestPath=@{candidate_path=$package+'staged/AC_manifest.json';sha256=$acSHA}};maps=$maps;AC_index_false_sha256=$acFalseSHA;AC_index_true_sha256=$acTrueSHA;AA_manifest_sha256=$aaSHA;AC_manifest_sha256=$acSHA;all_five_source_manifest_whole_inverses=$true;old_twelve_and_AA_three_native_artifacts_unchanged=$true;three_phase_independent_source_set_equations=$true;finite_phase_map_whole_inverses=$true;other_three_cities_only_owned_B_BI_manifest=$true;other_three_cities_no_AC_compile_leaves=$true;all_index_authorities_external_no_hash_cycles=$true;existing_import_remap_closure_complete=$true;H_District_Temple_C_Field_NPC_x_GS_unchanged=$true;immutable_CPU57_source_and_four_artifacts_unchanged=$true;cpu_path=$cpuPath;cpu_sha256=$pins[$cpuPath];import_proof_path=$importProofPath;import_proof_sha256=$pins[$importProofPath];new_ac_dependency_count=$acDeps.Count;code_patch_sha256=(Sha $patchFile);sole_bool_patch_sha256=(Sha $flipFile);no_engine_collector_canonical_or_save_writes=$true}
WJ 'stage_receipt.json' $receipt|Out-Null
$receipt|ConvertTo-Json -Depth 12
