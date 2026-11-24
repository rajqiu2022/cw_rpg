param([string]$ExpectedFormalIndexSha='')
$ErrorActionPreference='Stop'
$root='F:/Code/RPG_GAME/game/'
$out=$root+'build/luoyang_layout_quest_20261018u_root01/'
$baseline=Get-Content -Raw ($out+'guard_predeploy.json')|ConvertFrom-Json
$approved=@{}
$first=Get-Content -Raw ($root+'build/luoyang_layout_quest_20261018t_layout_source01/runtime_v2/deployment.json')|ConvertFrom-Json
foreach($row in $first.replace_existing){$approved[$row.target.Replace('res://',$root)]=$row.after_sha256}
foreach($table in @('runtime_source_successor02/final/deployment.json','official_hall_return_successor03/deployment.json')){
 $d=Get-Content -Raw ($root+'build/luoyang_layout_quest_20261018t_layout_source01/'+$table)|ConvertFrom-Json
 foreach($row in $d.targets){$approved[$row.target.Replace('res://',$root)]=$row.new_sha256}
}
if($ExpectedFormalIndexSha){$approved[$root+'scripts/city/luoyang_precomputed_bundle_index_20261018r.gd']=$ExpectedFormalIndexSha}
$changes=@();$unexpected=@()
foreach($row in $baseline.facts){
 $exists=Test-Path -LiteralPath $row.path -PathType Leaf
 $sha=if($exists){(Get-FileHash -LiteralPath $row.path).Hash}else{''}
 $ticks=if($exists){(Get-Item -LiteralPath $row.path).LastWriteTimeUtc.Ticks.ToString()}else{'0'}
 if($sha -ne $row.sha256 -or $ticks -ne $row.ticks){
  $fact=[ordered]@{path=$row.path;old_sha=$row.sha256;new_sha=$sha;old_ticks=$row.ticks;new_ticks=$ticks;authorized=($approved.ContainsKey($row.path) -and $approved[$row.path] -eq $sha)}
  $changes+=$fact;if(-not $fact.authorized){$unexpected+=$fact}
 }
}
foreach($path in $approved.Keys){if((Get-FileHash -LiteralPath $path).Hash -ne $approved[$path]){$unexpected+=[ordered]@{path=$path;reason='Approved latest target hash differs'}}}
$result=[ordered]@{observed_at=[DateTimeOffset]::Now.ToString('o');baseline_count=$baseline.facts.Count;approved_current_targets=$approved.Count;changes=$changes;unexpected=$unexpected}
$result|ConvertTo-Json -Depth 9|Out-File -LiteralPath ($out+'final_guard_result.json') -Encoding utf8
[ordered]@{baseline_count=$baseline.facts.Count;changed=$changes.Count;unexpected=$unexpected}|ConvertTo-Json -Depth 6
if($unexpected.Count){exit 1}
