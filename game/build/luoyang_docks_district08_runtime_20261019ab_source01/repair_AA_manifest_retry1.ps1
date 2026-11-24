param([string]$Workspace = 'F:\Code\RPG_GAME')
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
# Exact two-top-level-value repair. Never parse/print the old 302MB self object.
# Only NEW retry1 output is written; canonical and all first-failure files stay.
$repairGameRoot=Join-Path $Workspace 'game'
$repairPackage='res://build/luoyang_docks_district08_runtime_20261019ab_source01/'
$repairOutRoot=Join-Path $repairGameRoot ($repairPackage.Substring(6)+'retry1')
if(Test-Path -LiteralPath $repairOutRoot){throw 'RETRY1_EXISTS_PRESERVE_EVIDENCE'}
function RepairDisk([string]$path){if(!$path.StartsWith('res://') -or $path.Contains('..')){throw 'BAD_PATH'};return Join-Path $repairGameRoot $path.Substring(6)}
function RepairSha([string]$path){return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()}
function RepairJ([string]$path){return Get-Content -Raw -LiteralPath (RepairDisk $path)|ConvertFrom-Json -AsHashtable}
function RepairClone($value){return $value|ConvertTo-Json -Depth 100 -Compress|ConvertFrom-Json -AsHashtable}
function RepairCanon($value){if($value -is [Collections.IDictionary]){$out=[ordered]@{};foreach($key in @($value.Keys|Sort-Object -CaseSensitive)){$out[$key]=RepairCanon $value[$key]};return $out};if($value -is [array]){return ,@($value|ForEach-Object{RepairCanon $_})};return $value}
function RepairSame($left,$right){return ((RepairCanon $left)|ConvertTo-Json -Depth 100 -Compress) -ceq ((RepairCanon $right)|ConvertTo-Json -Depth 100 -Compress)}
function RepairWrite([string]$relative,[string]$text){$path=[IO.Path]::GetFullPath((Join-Path $repairOutRoot $relative));if(!$path.StartsWith($repairOutRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'OUTSIDE_NEW_RETRY1'};[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path))|Out-Null;[IO.File]::WriteAllText($path,$text,[Text.UTF8Encoding]::new($false));return $path}
function RepairWriteJ([string]$relative,$value){return RepairWrite $relative (($value|ConvertTo-Json -Depth 100)+"`n")}
$repairManifestPath='res://data/maps/luoyang_docks_district08_20261019aa/runtime/ch4_s2_canal_docks/manifest.json'
$repairIndexPath='res://scripts/city/luoyang_docks_district08_index_20261019aa.gd'
$repairOldManifestSHA='8ef444540e1eef6dba5672d126a00695e76e02e5608ba8e7ef8fafbb4028f4d1'
$repairOldFalseIndexSHA='ac101ac7d4591d11ac2b41f2cb0908d922e3663422247a3a2db3e61729609b12'
$repairOldTrueIndexSHA='6dd7d1ab4d71051f94a13a1ac7f72af31a62b6474bf5f4cf1d3f7b4f1b346108'
$repairAuthorPathConst='res://data/maps/luoyang_docks_district08_20261019aa/author.json'
$repairAuthorSHAConst='c3ba8c0a6a00738419a5733bbaa1faf34eef6add10fa89de3d6d7ba08a459c47'
if((RepairSha (RepairDisk $repairManifestPath)) -cne $repairOldManifestSHA -or (RepairSha (RepairDisk $repairIndexPath)) -cne $repairOldFalseIndexSHA){throw 'TWO_CURRENT_PREDECESSORS_CHANGED'}
if((Get-Item -LiteralPath (RepairDisk $repairManifestPath)).Length -ne 302210858){throw 'OLD_MANIFEST_LENGTH_CHANGED'}
if((RepairSha (RepairDisk $repairAuthorPathConst)) -cne $repairAuthorSHAConst){throw 'FROZEN_AUTHOR_CHANGED'}
if((RepairSha (RepairDisk ($repairPackage+'staged/stage_receipt.json'))) -cne '4845711a42076bc54adcedb41fb1e29e6c16404e4ca0a935afbe1d83246ee91b'){throw 'ORIGINAL_RECEIPT_CHANGED'}
$repairOriginalReceipt=RepairJ ($repairPackage+'staged/stage_receipt.json')
foreach($target in $repairOriginalReceipt.targets){if($target.target -eq $repairIndexPath){continue};if((RepairSha (RepairDisk $target.target)) -cne $target.candidate_sha256){throw "OTHER_DEPLOYED_TARGET_CHANGED:$($target.target)"}}
foreach($newPath in $repairOriginalReceipt.new_files.Keys){if($newPath -eq $repairManifestPath){continue};if((RepairSha (RepairDisk $newPath)) -cne $repairOriginalReceipt.new_files[$newPath].sha256){throw 'OTHER_NEW_BINDING_CHANGED'}}
Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Text;
using System.Collections.Generic;
using System.Security.Cryptography;
public static class AaManifestTwoFieldRepairAbRetry1 {
 public sealed class Span { public int Start; public int Length; public Span(int s,int n){Start=s;Length=n;} }
 public sealed class Result { public byte[] Bytes; public int OldLength; public int NewLength; public string InverseSha; public string PathOldValueSha; public string ShaOldValueSha; public Span OldPath; public Span OldSha; public Span NewPath; public Span NewSha; }
 static int Ws(byte[] b,int p){while(p<b.Length&&(b[p]==32||b[p]==9||b[p]==10||b[p]==13))p++;return p;}
 static int StringEnd(byte[] b,int p){if(b[p]!=34)throw new Exception("Expected string");for(int i=p+1;i<b.Length;i++){if(b[i]==92){i++;continue;}if(b[i]==34)return i+1;}throw new Exception("Unclosed string");}
 static int End(byte[] b,int p){if(b[p]==34)return StringEnd(b,p);if(b[p]==123||b[p]==91){int depth=0;for(int i=p;i<b.Length;i++){if(b[i]==34){i=StringEnd(b,i)-1;continue;}if(b[i]==123||b[i]==91)depth++;else if(b[i]==125||b[i]==93){depth--;if(depth==0)return i+1;}}throw new Exception("Unclosed value");}int q=p;while(q<b.Length&&b[q]!=44&&b[q]!=125&&b[q]!=93&&b[q]!=32&&b[q]!=9&&b[q]!=10&&b[q]!=13)q++;return q;}
 static Dictionary<string,Span> Fields(byte[] b){var r=new Dictionary<string,Span>();int p=Ws(b,0);if(b[p++]!=123)throw new Exception("Root not object");while(true){p=Ws(b,p);if(b[p]==125)break;int kEnd=StringEnd(b,p);string key=Encoding.UTF8.GetString(b,p+1,kEnd-p-2);p=Ws(b,kEnd);if(b[p++]!=58)throw new Exception("Missing colon");p=Ws(b,p);int end=End(b,p);r.Add(key,new Span(p,end-p));p=Ws(b,end);if(b[p]==125)break;if(b[p++]!=44)throw new Exception("Missing comma");}return r;}
 static string Hash(byte[] b,int start,int length){using(var h=SHA256.Create()){return BitConverter.ToString(h.ComputeHash(b,start,length)).Replace("-","").ToLowerInvariant();}}
 public static Result Repair(byte[] original,string authorPath,string authorSha){var old=Fields(original);Span a=old["author_path"],s=old["author_sha256"];if(original[a.Start]!=123||Encoding.UTF8.GetString(original,s.Start,s.Length)!="null")throw new Exception("Old precise Dictionary/null domain differs");var edits=new List<KeyValuePair<Span,byte[]>>{new KeyValuePair<Span,byte[]>(a,Encoding.UTF8.GetBytes("\""+authorPath+"\"")),new KeyValuePair<Span,byte[]>(s,Encoding.UTF8.GetBytes("\""+authorSha+"\""))};edits.Sort((x,y)=>x.Key.Start.CompareTo(y.Key.Start));byte[] result;using(var m=new MemoryStream()){int p=0;foreach(var e in edits){m.Write(original,p,e.Key.Start-p);m.Write(e.Value,0,e.Value.Length);p=e.Key.Start+e.Key.Length;}m.Write(original,p,original.Length-p);result=m.ToArray();}var n=Fields(result);if(n.Count!=old.Count)throw new Exception("Other root fields changed");var backwards=new List<KeyValuePair<Span,Span>>{new KeyValuePair<Span,Span>(n["author_path"],a),new KeyValuePair<Span,Span>(n["author_sha256"],s)};backwards.Sort((x,y)=>x.Key.Start.CompareTo(y.Key.Start));string inverse;using(var h=IncrementalHash.CreateHash(HashAlgorithmName.SHA256)){int p=0;foreach(var e in backwards){h.AppendData(result,p,e.Key.Start-p);h.AppendData(original,e.Value.Start,e.Value.Length);p=e.Key.Start+e.Key.Length;}h.AppendData(result,p,result.Length-p);inverse=BitConverter.ToString(h.GetHashAndReset()).Replace("-","").ToLowerInvariant();}return new Result{Bytes=result,OldLength=original.Length,NewLength=result.Length,InverseSha=inverse,PathOldValueSha=Hash(original,a.Start,a.Length),ShaOldValueSha=Hash(original,s.Start,s.Length),OldPath=a,OldSha=s,NewPath=n["author_path"],NewSha=n["author_sha256"]};}
}
'@
$repairBytes=[IO.File]::ReadAllBytes((RepairDisk $repairManifestPath))
$repairResult=[AaManifestTwoFieldRepairAbRetry1]::Repair($repairBytes,$repairAuthorPathConst,$repairAuthorSHAConst)
if($repairResult.InverseSha -cne $repairOldManifestSHA){throw 'WHOLE_BYTE_INVERSE_FAILED'}
$repairNewText=[Text.Encoding]::UTF8.GetString($repairResult.Bytes)
$repairNewObject=$repairNewText|ConvertFrom-Json -AsHashtable
if($repairNewObject.author_path -isnot [string] -or $repairNewObject.author_path -cne $repairAuthorPathConst -or $repairNewObject.author_sha256 -isnot [string] -or $repairNewObject.author_sha256 -cne $repairAuthorSHAConst){throw 'NEW_PRECISE_STRING_DOMAIN_FAILED'}
$repairNewFile=RepairWrite 'AA_manifest.json' $repairNewText
$repairNewManifestSHA=RepairSha $repairNewFile
$repairOldIndexText=[IO.File]::ReadAllText((RepairDisk $repairIndexPath))
if([regex]::Matches($repairOldIndexText,[regex]::Escape($repairOldManifestSHA)).Count -ne 1){throw 'ONE_INDEX_PIN_REQUIRED'}
$repairFalseIndexText=$repairOldIndexText.Replace($repairOldManifestSHA,$repairNewManifestSHA)
if($repairFalseIndexText.Replace($repairNewManifestSHA,$repairOldManifestSHA) -cne $repairOldIndexText){throw 'INDEX_LITERAL_INVERSE_FAILED'}
$repairTrueIndexText=$repairFalseIndexText.Replace('const FORMAL_ENABLED=false','const FORMAL_ENABLED=true')
if($repairTrueIndexText.Replace('const FORMAL_ENABLED=true','const FORMAL_ENABLED=false') -cne $repairFalseIndexText){throw 'INDEX_SOLE_BOOL_INVERSE_FAILED'}
$repairFalseFile=RepairWrite 'AA_index_false_candidate.gd' $repairFalseIndexText
$repairTrueFile=RepairWrite 'AA_index_true_candidate.gd' $repairTrueIndexText
$repairFalseSHA=RepairSha $repairFalseFile;$repairTrueSHA=RepairSha $repairTrueFile
$repairMapFacts=@{}
$repairMapPins=@{false='f011d4d89003ca0132553cc4d1f999c68ed1de4bf4f939f0e7af8b5a52e8ce8c';candidate='204725e230ccf63d00c468fe1c8ecd4dc73380e57df052d1ca91b625af7f5d0f';true='9aed5ab364c824d7aca01705f094e6845a67e7af0cae1edef8c88f3ec5c44f19'}
foreach($phase in @('false','candidate','true')){
 $mapPath=$repairPackage+'staged/ch4_s2_canal_docks/expected_sources_'+$phase+'.json'
 if((RepairSha (RepairDisk $mapPath)) -cne $repairMapPins[$phase]){throw 'ORIGINAL_PHASE_MAP_CHANGED'}
 $oldMap=RepairJ $mapPath;$newMap=RepairClone $oldMap
 $expectedIndex=if($phase -eq 'true'){$repairOldTrueIndexSHA}else{$repairOldFalseIndexSHA}
 if($oldMap.source_sha256[$repairIndexPath] -cne $expectedIndex){throw 'OLD_PHASE_INDEX_CHANGED'}
 $newMap.source_sha256[$repairIndexPath]=if($phase -eq 'true'){$repairTrueSHA}else{$repairFalseSHA}
 if($phase -ne 'false'){
  if($oldMap.source_sha256[$repairManifestPath] -cne $repairOldManifestSHA){throw 'OLD_PHASE_MANIFEST_CHANGED'}
  $newMap.source_sha256[$repairManifestPath]=$repairNewManifestSHA
 }elseif($oldMap.source_sha256.Contains($repairManifestPath)){throw 'FALSE_MAP_UNEXPECTED_ACTIVE_AA_MANIFEST'}
 $inverseMap=RepairClone $newMap;$inverseMap.source_sha256[$repairIndexPath]=$expectedIndex
 if($phase -ne 'false'){$inverseMap.source_sha256[$repairManifestPath]=$repairOldManifestSHA}
 if(!(RepairSame $inverseMap $oldMap)){throw 'WHOLE_PHASE_MAP_INVERSE_FAILED'}
 $newMapFile=RepairWriteJ ('expected_sources_'+$phase+'.json') $newMap
 $repairMapFacts[$phase]=@{prior_path=$mapPath;prior_sha256=(RepairSha (RepairDisk $mapPath));new_path=$repairPackage+'retry1/expected_sources_'+$phase+'.json';new_sha256=(RepairSha $newMapFile);count=$newMap.source_sha256.Count;changed_leaves=$(if($phase -eq 'false'){1}else{2});whole_semantic_inverse=$true}
}
$repairPatch="*** Begin Patch`n*** Update File: "+(RepairDisk $repairIndexPath).Replace('\','/')+"`n@@`n-const MANIFEST_SHA=`""+$repairOldManifestSHA+"`"`n+const MANIFEST_SHA=`""+$repairNewManifestSHA+"`"`n*** End Patch`n"
$repairPatchFile=RepairWrite 'index_false_deployment.apply_patch' $repairPatch
$repairFlipFile=RepairWrite 'sole_bool_true_after_candidate.apply_patch' ("*** Begin Patch`n*** Update File: "+(RepairDisk $repairIndexPath).Replace('\','/')+"`n@@`n-const FORMAL_ENABLED=false`n+const FORMAL_ENABLED=true`n*** End Patch`n")
$repairTargets=@(
 @{target=$repairManifestPath;old_sha256=$repairOldManifestSHA;candidate_path=$repairPackage+'retry1/AA_manifest.json';candidate_sha256=$repairNewManifestSHA;operation='Exact two-top-level-value mechanical metadata replacement; no original field or proof changes'},
 @{target=$repairIndexPath;old_sha256=$repairOldFalseIndexSHA;candidate_path=$repairPackage+'retry1/AA_index_false_candidate.gd';candidate_sha256=$repairFalseSHA;operation='apply_patch one MANIFEST_SHA literal only; formal false retained'}
)
$repairReceipt=@{status='NEW_RETRY1_NOT_DEPLOYED';cause='PowerShell case-insensitive AA author-path/aa object variable collision';old_manifest_bytes=$repairResult.OldLength;new_manifest_bytes=$repairResult.NewLength;whole_byte_inverse_sha256=$repairResult.InverseSha;only_changed_top_level_fields=@('author_path','author_sha256');author_path=$repairAuthorPathConst;author_sha256=$repairAuthorSHAConst;targets=$repairTargets;index_false_sha256=$repairFalseSHA;index_true_sha256=$repairTrueSHA;index_sole_bool_inverse=$true;maps=$repairMapFacts;other_six_code_and_four_fallback_targets_unchanged=$true;old_stager_and_119984_failure_preserved=$true;main_files_written=$false;old_value_spans=@{author_path=@{start=$repairResult.OldPath.Start;length=$repairResult.OldPath.Length;sha256=$repairResult.PathOldValueSha};author_sha256=@{start=$repairResult.OldSha.Start;length=$repairResult.OldSha.Length;sha256=$repairResult.ShaOldValueSha}};index_patch_sha256=(RepairSha $repairPatchFile);true_flip_patch_sha256=(RepairSha $repairFlipFile)}
RepairWriteJ 'repair_receipt.json' $repairReceipt|Out-Null
# No old self-dictionary output; this bounded receipt contains just facts/hashes.
$repairReceipt|ConvertTo-Json -Depth 12
