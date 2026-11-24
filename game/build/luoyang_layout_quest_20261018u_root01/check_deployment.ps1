$ErrorActionPreference='Stop'
$root='F:/Code/RPG_GAME/game/'
$out=$root+'build/luoyang_layout_quest_20261018u_root01/'
$baseline=Get-Content -Raw ($out+'guard_predeploy.json')|ConvertFrom-Json
$deployment=Get-Content -Raw ($root+'build/luoyang_layout_quest_20261018t_layout_source01/runtime_v2/deployment.json')|ConvertFrom-Json
$allowed=@{}
foreach($row in $deployment.replace_existing){$allowed[$row.target.Replace('res://',$root)]=$row.after_sha256}
$allowed[$root+'scripts/city/luoyang_precomputed_bundle_index_20261018r.gd']=(Get-FileHash -LiteralPath ($root+'data/maps/luoyang_layout_bundle_20261018t_retry2/bundle_index_generated.gd')).Hash
$differences=@();$unexpected=@()
foreach($row in $baseline.facts){
 $exists=Test-Path -LiteralPath $row.path -PathType Leaf
 $sha=if($exists){(Get-FileHash -LiteralPath $row.path).Hash}else{''}
 $ticks=if($exists){(Get-Item -LiteralPath $row.path).LastWriteTimeUtc.Ticks.ToString()}else{'0'}
 if($sha -ne $row.sha256 -or $ticks -ne $row.ticks){
  $fact=[ordered]@{path=$row.path;old_sha=$row.sha256;new_sha=$sha;old_ticks=$row.ticks;new_ticks=$ticks;authorized=($allowed.ContainsKey($row.path) -and $allowed[$row.path] -eq $sha)}
  $differences+=$fact
  if(-not $fact.authorized){$unexpected+=$fact}
 }
}
$result=[ordered]@{observed_at=[DateTimeOffset]::Now.ToString('o');baseline_count=$baseline.facts.Count;differences=$differences;unexpected=$unexpected}
$result|ConvertTo-Json -Depth 8|Out-File -LiteralPath ($out+'guard_after_A.json') -Encoding utf8
[ordered]@{baseline=$baseline.facts.Count;changed=$differences.Count;unexpected=$unexpected}|ConvertTo-Json -Depth 8
if($unexpected.Count){exit 1}
