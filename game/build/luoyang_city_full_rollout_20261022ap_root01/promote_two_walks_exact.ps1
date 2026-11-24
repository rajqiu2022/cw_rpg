param([switch]$Promote)
$ErrorActionPreference='Stop'
$GameRoot='F:\Code\RPG_GAME\game'
$IsolateRoot=Join-Path $GameRoot 'build\luoyang_city_full_rollout_20261022ap_qa01\isolate_two_masks_ready01'
$ReportPath=Join-Path $IsolateRoot 'ap_two_walk_import_result_58808.json'
$ReportSha='c32eab4a841d708b7ca540bc371df77a0efcde5fde8b46a1813b39efbf65ebfe'
$RootFolder=Join-Path $GameRoot 'build\luoyang_city_full_rollout_20261022ap_root01'
$Authorization=Join-Path $RootFolder 'two_walks_six_leaf_preadd_authorization.json'
$Receipt=Join-Path $RootFolder 'two_walks_six_leaf_promotion_actual.json'
if((Get-FileHash -LiteralPath $ReportPath).Hash.ToLowerInvariant() -cne $ReportSha){throw 'Frozen actual two-mask import report'}
$Report=Get-Content -LiteralPath $ReportPath -Raw | ConvertFrom-Json
if(-not $Report.passed -or $Report.checks -ne 106 -or @($Report.rows).Count -ne 2){throw 'Actual106 checks passed required'}
$Targets=@{artisan_walk='res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/luoyang_artisan_residential_20261022ap/walk.png';garden_walk='res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/luoyang_riverside_garden_20261022ap/walk.png'}
$Leaves=@()
foreach($Row in $Report.rows){
 if(-not $Targets.ContainsKey($Row.visual_kind) -or $Targets[$Row.visual_kind] -cne $Row.texture){throw 'Exact two identities'}
 foreach($Pair in @(@($Row.compiled_path,$Row.compiled_sha256),@($Row.import_path,$Row.import_sha256),@($Row.texture,$Row.source_sha256))){
  $Relative=$Pair[0].Substring(6);$Source=[IO.Path]::GetFullPath((Join-Path $IsolateRoot $Relative));$Target=[IO.Path]::GetFullPath((Join-Path $GameRoot $Relative))
  if($Relative.Contains('..') -or -not $Source.StartsWith($IsolateRoot+'\',[StringComparison]::OrdinalIgnoreCase) -or -not $Target.StartsWith($GameRoot+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Exact path domains'}
  if(Test-Path -LiteralPath $Target){throw 'All six destinations must be ABSENT'}
  if((Get-FileHash -LiteralPath $Source).Hash.ToLowerInvariant() -cne $Pair[1]){throw 'Source changed'}
  $Leaves += [pscustomobject]@{source=$Source;target=$Target;before='ABSENT';sha256=$Pair[1];bytes=(Get-Item -LiteralPath $Source).Length}
 }
}
if($Leaves.Count -ne 6 -or @($Leaves.target|Select-Object -Unique).Count -ne 6){throw 'Exactly six unique leaves'}
if(-not $Promote){$Leaves|ConvertTo-Json -Depth 5;exit 0}
if((Test-Path -LiteralPath $Authorization) -or (Test-Path -LiteralPath $Receipt)){throw 'Preserve authorization/receipt'}
[ordered]@{approved_by_root=$true;status='ROOT_EXACT_SIX_NEW_WALK_MEDIA_LEAVES_PREAUTHORIZED';actual_report=$ReportPath;actual_report_sha256=$ReportSha;leaves=$Leaves;no_geometry_replay=$true;formal_AP_enabled=$false;old_sources_or_saves_modified=$false}|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $Authorization -Encoding utf8NoBOM
foreach($Leaf in @($Leaves|Where-Object{-not $_.target.EndsWith('.png')})+@($Leaves|Where-Object{$_.target.EndsWith('.png')})){
 if(Test-Path -LiteralPath $Leaf.target){throw 'Destination changed after authorization'}
 $Parent=Split-Path -Parent $Leaf.target
 if(-not(Test-Path -LiteralPath $Parent)){New-Item -ItemType Directory -Path $Parent|Out-Null}
 Copy-Item -LiteralPath $Leaf.source -Destination $Leaf.target
 if((Get-FileHash -LiteralPath $Leaf.target).Hash.ToLowerInvariant() -cne $Leaf.sha256){throw 'Exact promoted SHA'}
}
[ordered]@{passed=$true;status='SIX_WALK_LEAVES_EXACT_PROMOTION_NO_AP_INDEX';authorization_sha256=(Get-FileHash -LiteralPath $Authorization).Hash.ToLowerInvariant();leaves=$Leaves;old_sources_or_saves_modified=$false}|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $Receipt -Encoding utf8NoBOM
Get-FileHash -LiteralPath $Authorization,$Receipt
