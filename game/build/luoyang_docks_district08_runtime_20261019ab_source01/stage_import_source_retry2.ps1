param([string]$Workspace='F:\Code\RPG_GAME')
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
# NEW-only two explicit import dependencies. No collector, import or engine.
$r2Game=Join-Path $Workspace 'game'
$r2Package='res://build/luoyang_docks_district08_runtime_20261019ab_source01/'
$r2Out=Join-Path $r2Game ($r2Package.Substring(6)+'retry2')
if(Test-Path -LiteralPath $r2Out){throw 'RETRY2_EXISTS_PRESERVE_EVIDENCE'}
function R2Disk([string]$p){if(!$p.StartsWith('res://') -or $p.Contains('..')){throw 'BAD_PATH'};return Join-Path $r2Game $p.Substring(6)}
function R2Sha([string]$p){return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function R2Assert([string]$p,[string]$s){if((R2Sha (R2Disk $p)) -cne $s){throw "PREDECESSOR_CHANGED:$p"}}
function R2J([string]$p){return Get-Content -Raw -LiteralPath (R2Disk $p)|ConvertFrom-Json -AsHashtable}
function R2Clone($v){return $v|ConvertTo-Json -Depth 100 -Compress|ConvertFrom-Json -AsHashtable}
function R2Canon($v){if($v -is [Collections.IDictionary]){$o=[ordered]@{};foreach($k in @($v.Keys|Sort-Object -CaseSensitive)){$o[$k]=R2Canon $v[$k]};return $o};if($v -is [array]){return ,@($v|ForEach-Object{R2Canon $_})};return $v}
function R2Same($a,$b){return ((R2Canon $a)|ConvertTo-Json -Depth 100 -Compress) -ceq ((R2Canon $b)|ConvertTo-Json -Depth 100 -Compress)}
function R2W([string]$rel,[string]$text){$p=[IO.Path]::GetFullPath((Join-Path $r2Out $rel));if(!$p.StartsWith($r2Out+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'OUTSIDE_NEW_RETRY2'};[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($p))|Out-Null;[IO.File]::WriteAllText($p,$text,[Text.UTF8Encoding]::new($false));return $p}
function R2WJ([string]$rel,$v){return R2W $rel (($v|ConvertTo-Json -Depth 100)+"`n")}
$r2Id='ch4_s2_canal_docks'
$r2ActivePath='res://data/maps/luoyang_docks_district08_20261019aa/runtime/'+$r2Id+'/manifest.json'
$r2FallbackPath='res://data/maps/luoyang_layout_bundle_20261018t_retry2/'+$r2Id+'/manifest.json'
$r2BundleIndexPath='res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd'
$r2AAIndexPath='res://scripts/city/luoyang_docks_district08_index_20261019aa.gd'
$r2ActiveOldSHA='6523fe118f5a35e189b725328f3bf5a085156b894dbc4925ebe7c162d3e963df'
$r2FallbackOldSHA='14a47ed98481f74942e1c9254b4be7795d92e4050d65f48612fff6cb11d11bcb'
$r2BundleOldSHA='85e8a331ee1be8c4034cfeb1187630608f8b0dea2a044563e717e6d89c3cbc00'
$r2AAFalseOldSHA='be381de578c04b7caace800eae653ff40000c48eda1e91b2cfa08b228bb058f5'
$r2AATrueOldSHA='7b03f100feddb191ab53308aaab2c3e39d3b2cb1fbd398eb2c447a2927097ca3'
$r2AuthorPath='res://data/maps/luoyang_docks_district08_20261019aa/author.json'
$r2PNG='res://build/luoyang_docks_spacing_ordinary_20261018q/105980_2617/ordinary_docks_spacing_32px.png'
$r2Import=$r2PNG+'.import'
$r2Compiled='res://.godot/imported/ordinary_docks_spacing_32px.png-4ea5aa226b5a0e3027a9d1f59051966b.ctex'
$r2Leaves=@{
 $r2Import='b1d41b5ca7cec4bbdb23f888948892f4af1d18c0b1815158064e88b9948eb49b'
 $r2Compiled='542ea429015aec222ece743d072144a4371572cc56ed94ec1d54d7c808478608'
}
R2Assert $r2ActivePath $r2ActiveOldSHA;R2Assert $r2FallbackPath $r2FallbackOldSHA
R2Assert $r2BundleIndexPath $r2BundleOldSHA;R2Assert $r2AAIndexPath $r2AAFalseOldSHA
R2Assert $r2AuthorPath 'c3ba8c0a6a00738419a5733bbaa1faf34eef6add10fa89de3d6d7ba08a459c47'
R2Assert $r2PNG 'acf9ab620c65111f040d4d69cea3e061ac2f7cfe363c86d42eb13c9244ee93fb'
foreach($p in $r2Leaves.Keys){R2Assert $p $r2Leaves[$p]}
R2Assert ($r2Package+'staged/stage_receipt.json') '4845711a42076bc54adcedb41fb1e29e6c16404e4ca0a935afbe1d83246ee91b'
R2Assert ($r2Package+'retry1/repair_receipt.json') '1001b6b2d8e06f3caeaca786a89fb72d806dda63d82f4b348e2f0b1e253b7bee'
$r2OriginalReceipt=R2J ($r2Package+'staged/stage_receipt.json')
foreach($t in $r2OriginalReceipt.targets){if($t.target -in @($r2AAIndexPath,$r2BundleIndexPath,$r2FallbackPath)){continue};R2Assert $t.target $t.candidate_sha256}
foreach($p in $r2OriginalReceipt.new_files.Keys){if($p -ne $r2ActivePath){R2Assert $p $r2OriginalReceipt.new_files[$p].sha256}}
# Dependency causality is the frozen author's PNG plus its exact existing remap.
# It is not copied from an actual collector result or a mutable current keyset.
$r2AuthorDoc=R2J $r2AuthorPath
if($r2AuthorDoc.source_sha256[$r2PNG] -cne 'acf9ab620c65111f040d4d69cea3e061ac2f7cfe363c86d42eb13c9244ee93fb'){throw 'AUTHOR_PNG_NOT_EXACT'}
$r2ImportText=[IO.File]::ReadAllText((R2Disk $r2Import))
$r2Remap=[regex]::Match($r2ImportText,'(?ms)^\[remap\]\r?\n(.*?)(?=^\[|\z)').Groups[1].Value
$r2RemapPaths=@([regex]::Matches($r2Remap,'(?m)^path[^=\r\n]*="([^"]+)"\r?$')|ForEach-Object{$_.Groups[1].Value})
if($r2RemapPaths.Count -ne 1 -or $r2RemapPaths[0] -cne $r2Compiled){throw 'EXACT_EXISTING_REMAP_CHANGED'}
$r2ManifestFiles=@{}
foreach($kind in @('fallback','active')){
 $path=if($kind -eq 'fallback'){$r2FallbackPath}else{$r2ActivePath}
 $prior=R2J $path;$next=R2Clone $prior
 if($prior.author_path -isnot [string] -or $prior.author_sha256 -isnot [string]){throw 'TYPED_AUTHOR_DOMAIN_NOT_STRING'}
 foreach($p in $r2Leaves.Keys){if($prior.legacy_source_sha256.Contains($p) -or $prior.runtime_authority_sha256.Contains($p) -or $prior.artifacts.Contains($p)){throw 'TWO_LEAVES_NOT_ABSENT'};$next.legacy_source_sha256[$p]=$r2Leaves[$p]}
 $inverse=R2Clone $next;foreach($p in $r2Leaves.Keys){$inverse.legacy_source_sha256.Remove($p)|Out-Null}
 if(!(R2Same $inverse $prior)){throw 'WHOLE_MANIFEST_TWO_LEAF_INVERSE_FAILED'}
 $file=R2WJ ($kind+'_manifest.json') $next
 $r2ManifestFiles[$kind]=@{target=$path;file=$file;sha256=(R2Sha $file);old_sha256=$(if($kind -eq 'fallback'){$r2FallbackOldSHA}else{$r2ActiveOldSHA});whole_inverse=$true}
}
$r2OldBIText=[IO.File]::ReadAllText((R2Disk $r2BundleIndexPath))
$r2OldAIText=[IO.File]::ReadAllText((R2Disk $r2AAIndexPath))
if([regex]::Matches($r2OldBIText,[regex]::Escape($r2FallbackOldSHA)).Count -ne 1 -or [regex]::Matches($r2OldAIText,[regex]::Escape($r2ActiveOldSHA)).Count -ne 1){throw 'ONE_LITERAL_PIN_REQUIRED'}
$r2NewBIText=$r2OldBIText.Replace($r2FallbackOldSHA,$r2ManifestFiles.fallback.sha256)
$r2NewAIText=$r2OldAIText.Replace($r2ActiveOldSHA,$r2ManifestFiles.active.sha256)
$r2TrueAIText=$r2NewAIText.Replace('const FORMAL_ENABLED=false','const FORMAL_ENABLED=true')
if($r2NewBIText.Replace($r2ManifestFiles.fallback.sha256,$r2FallbackOldSHA) -cne $r2OldBIText -or $r2NewAIText.Replace($r2ManifestFiles.active.sha256,$r2ActiveOldSHA) -cne $r2OldAIText -or $r2TrueAIText.Replace('const FORMAL_ENABLED=true','const FORMAL_ENABLED=false') -cne $r2NewAIText){throw 'INDEX_ONE_LITERAL_OR_SOLE_BOOL_INVERSE_FAILED'}
$r2BIFile=R2W 'Bundle_index_candidate.gd' $r2NewBIText;$r2BIHash=R2Sha $r2BIFile
$r2AIFile=R2W 'AA_index_false_candidate.gd' $r2NewAIText;$r2AIHash=R2Sha $r2AIFile
$r2TrueFile=R2W 'AA_index_true_candidate.gd' $r2TrueAIText;$r2TrueHash=R2Sha $r2TrueFile
$r2MapPins=@{false='32112d67847f131c6909138372022ccbea4986e35b47d4ef70de49a2d1336e4b';candidate='2efe7781a3e59c0160a2299a9232865bc9507ec955bcc10ae566aa729b161336';true='b5774a6ea99b6e44b37283ec257b023091ba7eb73c522bf7c36c3f7e0faccff8'}
$r2MapFacts=@{}
foreach($phase in @('false','candidate','true')){
 $mapPath=$r2Package+'retry1/expected_sources_'+$phase+'.json';R2Assert $mapPath $r2MapPins[$phase]
 $prior=R2J $mapPath;$next=R2Clone $prior
 $oldIndex=if($phase -eq 'true'){$r2AATrueOldSHA}else{$r2AAFalseOldSHA}
 if($prior.source_sha256[$r2BundleIndexPath] -cne $r2BundleOldSHA -or $prior.source_sha256[$r2AAIndexPath] -cne $oldIndex){throw 'OLD_MAP_INDEX_IDENTITY_CHANGED'}
 foreach($p in $r2Leaves.Keys){if($prior.source_sha256.Contains($p)){throw 'MAP_NEW_LEAF_ALREADY_PRESENT'};$next.source_sha256[$p]=$r2Leaves[$p]}
 $next.source_sha256[$r2BundleIndexPath]=$r2BIHash;$next.source_sha256[$r2AAIndexPath]=if($phase -eq 'true'){$r2TrueHash}else{$r2AIHash}
 $phaseManifest=if($phase -eq 'false'){$r2FallbackPath}else{$r2ActivePath}
 $phaseKind=if($phase -eq 'false'){'fallback'}else{'active'}
 if($prior.source_sha256[$phaseManifest] -cne $r2ManifestFiles[$phaseKind].old_sha256){throw 'OLD_MAP_MANIFEST_IDENTITY_CHANGED'}
 $next.source_sha256[$phaseManifest]=$r2ManifestFiles[$phaseKind].sha256
 $inverse=R2Clone $next;foreach($p in $r2Leaves.Keys){$inverse.source_sha256.Remove($p)|Out-Null}
 foreach($p in @($r2BundleIndexPath,$r2AAIndexPath,$phaseManifest)){$inverse.source_sha256[$p]=$prior.source_sha256[$p]}
 if(!(R2Same $inverse $prior) -or $next.source_sha256.Count -ne $(if($phase -eq 'false'){1458}else{1466})){throw 'WHOLE_DOCKS_MAP_INVERSE_OR_COUNT_FAILED'}
 $file=R2WJ ('expected_sources_'+$phase+'.json') $next
 $r2MapFacts[$phase]=@{prior_path=$mapPath;prior_sha256=$r2MapPins[$phase];new_path=$r2Package+'retry2/expected_sources_'+$phase+'.json';new_sha256=(R2Sha $file);count=$next.source_sha256.Count;added_leaves=2;replaced_leaves=3;whole_inverse=$true}
}
$r2OtherMapPins=@{ch4_s0_luoyang_gate='e556d759fc9496f1ab9758ccfdd9b7f70d11012637f29c4c0907d7830cf7481e';ch4_s1_luoyang_yamen='1e21f7e68ae907868ababa8a8325667511fa238b2eb0ea13f54ff80ba2adba33';ch4_s3_luoyang_market='65425dc004f79f4612dde8924749a558a5c2020a07f1aa30d806b79eeca6f64f'}
foreach($id in $r2OtherMapPins.Keys){
 $mapPath=$r2Package+'staged/'+$id+'/expected_sources_false.json';R2Assert $mapPath $r2OtherMapPins[$id]
 $prior=R2J $mapPath;$next=R2Clone $prior
 if($prior.source_sha256[$r2BundleIndexPath] -cne $r2BundleOldSHA){throw 'OTHER_MAP_OLD_BI_CHANGED'}
 $next.source_sha256[$r2BundleIndexPath]=$r2BIHash
 $inverse=R2Clone $next;$inverse.source_sha256[$r2BundleIndexPath]=$r2BundleOldSHA
 if(!(R2Same $inverse $prior)){throw 'OTHER_MAP_ONE_LEAF_INVERSE_FAILED'}
 $file=R2WJ ($id+'/expected_sources.json') $next
 $r2MapFacts[$id]=@{prior_path=$mapPath;prior_sha256=$r2OtherMapPins[$id];new_path=$r2Package+'retry2/'+$id+'/expected_sources.json';new_sha256=(R2Sha $file);count=$next.source_sha256.Count;added_leaves=0;replaced_leaves=1;whole_inverse=$true}
}
$r2CodePatch="*** Begin Patch`n*** Update File: "+(R2Disk $r2BundleIndexPath).Replace('\','/')+"`n@@`n-`"manifest_sha256`": `""+$r2FallbackOldSHA+"`"`n+`"manifest_sha256`": `""+$r2ManifestFiles.fallback.sha256+"`"`n*** Update File: "+(R2Disk $r2AAIndexPath).Replace('\','/')+"`n@@`n-const MANIFEST_SHA=`""+$r2ActiveOldSHA+"`"`n+const MANIFEST_SHA=`""+$r2ManifestFiles.active.sha256+"`"`n*** End Patch`n"
$r2PatchFile=R2W 'two_index_deployment.apply_patch' $r2CodePatch
$r2FlipFile=R2W 'sole_bool_true_after_candidate.apply_patch' ("*** Begin Patch`n*** Update File: "+(R2Disk $r2AAIndexPath).Replace('\','/')+"`n@@`n-const FORMAL_ENABLED=false`n+const FORMAL_ENABLED=true`n*** End Patch`n")
$r2Targets=@();foreach($kind in @('fallback','active')){$m=$r2ManifestFiles[$kind];$r2Targets+=@{target=$m.target;old_sha256=$m.old_sha256;candidate_path=$r2Package+'retry2/'+$kind+'_manifest.json';candidate_sha256=$m.sha256;operation='Only add two exact existing import legacy leaves'}}
$r2Targets+=@{target=$r2BundleIndexPath;old_sha256=$r2BundleOldSHA;candidate_path=$r2Package+'retry2/Bundle_index_candidate.gd';candidate_sha256=$r2BIHash;operation='Only Docks fallback pin'}
$r2Targets+=@{target=$r2AAIndexPath;old_sha256=$r2AAFalseOldSHA;candidate_path=$r2Package+'retry2/AA_index_false_candidate.gd';candidate_sha256=$r2AIHash;operation='Only AA manifest pin; false retained'}
$r2Receipt=@{status='NEW_RETRY2_NOT_DEPLOYED';derivation='Frozen author ACF9 PNG -> exact existing .import remap path -> existing ctex; C line814-829 one-layer import closure, no actual-source result read';source_png=$r2PNG;new_existing_dependency_leaves=$r2Leaves;targets=$r2Targets;AA_index_false_sha256=$r2AIHash;AA_index_true_sha256=$r2TrueHash;maps=$r2MapFacts;two_manifest_whole_inverses=$true;two_index_one_literal_inverses=$true;sole_bool_true_inverse=$true;other_three_manifests_and_runtime_temple_unchanged=$true;author_C_and_original_proofs_unchanged=$true;all_failures_preserved=$true;no_import_or_engine_or_canonical_writes=$true;code_patch_sha256=(R2Sha $r2PatchFile);sole_bool_patch_sha256=(R2Sha $r2FlipFile)}
R2WJ 'source_successor_receipt.json' $r2Receipt|Out-Null
$r2Receipt|ConvertTo-Json -Depth 12
