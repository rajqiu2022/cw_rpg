$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'USE_BUNDLED_PWSH7'}
$repo='F:/Code/RPG_GAME';$dir=$repo+'/game/build/world_coast_20261031h_qa01';$output=$dir+'/source_scope_READY03.json'
if(Test-Path -LiteralPath $output){throw 'PRESERVE_EXISTING_SCOPE03'}
function Hash-Only([string]$p){$s=[IO.File]::OpenRead($p);try{return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($s)).ToLowerInvariant()}finally{$s.Dispose()}}
function Canonical([string]$p){if($p.StartsWith('res://')){$p=$repo+'/game/'+$p.Substring(6)}elseif(-not [IO.Path]::IsPathRooted($p)){$p=$repo+'/'+$p};return [IO.Path]::GetFullPath($p).Replace('\','/')}
$scope=[IO.File]::ReadAllText($dir+'/source_scope_READY02.json',[Text.Encoding]::UTF8)|ConvertFrom-Json -AsHashtable
foreach($p in @('game/build/sect_repair_20261031c_system01/adoption_contract.gd','game/build/sect_repair_20261031c_system01/router_entry.gd')){
 $item=Get-Item -LiteralPath ($repo+'/'+$p);$scope.backup_targets+=@($p);$scope.current_source_pins[$p]=[ordered]@{sha256=(Hash-Only $item.FullName);bytes=[long]$item.Length}
}
$planPath=$repo+'/game/build/world_coast_20261031h_system01/source_plan.json';$plan=[IO.File]::ReadAllText($planPath,[Text.Encoding]::UTF8)|ConvertFrom-Json -AsHashtable
if($plan.source_sha256.Count -ne 9){throw 'EXACT9_CURRENT_SOURCE_PLAN_INPUTS'}
$all=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($p in $plan.source_sha256.Keys){$q=Canonical $p;if((Hash-Only $q) -cne $plan.source_sha256[$p]){throw ('SOURCE_PLAN_INPUT_DIFFERS:'+ $p)};[void]$all.Add($q)}
function Exact-Paths([string]$path,[string]$field){
 $raw=[IO.File]::ReadAllText($path,[Text.Encoding]::UTF8)
 $block=[regex]::Match($raw,'(?ms)^'+[regex]::Escape($field)+' = Array\[Dictionary\]\(\[(.*?)\]\)')
 if(-not $block.Success){throw ('DIRECT_FIELD_MISSING:'+ $field)}
 $paths=@([regex]::Matches($block.Groups[1].Value,'"path":\s*"([^"]+)"')|ForEach-Object{$_.Groups[1].Value})
 if($paths.Count -ne 64 -or @($paths|Sort-Object -Unique).Count -ne 64){throw ('EXACT64_DIRECT_PATHS:'+ $field)}
 return $paths
}
$visual=@(Exact-Paths ($repo+'/game/data/background_sets/world_map_jianghu_v15_streamed.tres') 'mobile_chunks')
$nav=@(Exact-Paths ($repo+'/game/data/maps/world_map_jianghu_layout_v15.tres') 'walkable_mask_tiles')
$approvalPath=$repo+'/game/art/maps/world_farmland_patch_v2_20261015/approved_manifest.json'
if((Hash-Only $approvalPath) -cne '2fc156a01dba1bc5c887e4aabd45fb65e5614ab54d29101da72e217cec0fa897'){throw 'CURRENT_VISUAL_APPROVAL_PIN'}
$approval=[IO.File]::ReadAllText($approvalPath,[Text.Encoding]::UTF8)|ConvertFrom-Json -AsHashtable
foreach($row in $approval.entries){$index=[Array]::IndexOf($visual,[string]$row.old_path);if($index -lt 0){throw 'PATCH_NOT_CURRENT_DIRECT_CHUNK'};$visual[$index]=[string]$row.path}
foreach($p in ($visual+$nav+@([string]$approval.overview.path))){[void]$all.Add((Canonical $p))}
[void]$all.Add($approvalPath);[void]$all.Add($planPath)
$original=@($all)
foreach($p in $original){
 if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw ('EXPLICIT_CURRENT_INPUT_MISSING:'+ $p)}
 $sidecar=$p+'.import'
 if(Test-Path -LiteralPath $sidecar -PathType Leaf){
  [void]$all.Add($sidecar);$raw=[IO.File]::ReadAllText($sidecar,[Text.Encoding]::UTF8)
  $compiled=[regex]::Matches($raw,'(?m)^path(?:\.[^=\r\n]+)?="(res://[^"]+\.ctex)"')
  foreach($m in $compiled){$q=Canonical $m.Groups[1].Value;if(-not(Test-Path -LiteralPath $q -PathType Leaf)){throw 'EXPLICIT_COMPILED_INPUT_MISSING'};[void]$all.Add($q)}
 }
}
$scope.explicit_paths=@($all|Sort-Object);$scope.explicit_path_count=$all.Count
$scope.direct_visual_paths=$visual;$scope.direct_nav_paths=$nav;$scope.effective_overview_path=$approval.overview.path
$scope.source_plan_path=$planPath;$scope.source_plan_sha256=Hash-Only $planPath
$scope.notes='31f finite closure +33 current pins +20 backups +9 actual source-plan inputs +64 effective visual/64NAV/overview with direct sidecars/ctex only; no resource_graph/provenance traversal'
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($scope|ConvertTo-Json -Depth 12)+[Environment]::NewLine);$f=[IO.File]::Open($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);try{$f.Write($bytes,0,$bytes.Length)}finally{$f.Dispose()}
$classes=[ordered]@{};foreach($p in $scope.explicit_paths){$ext=[IO.Path]::GetExtension($p);if(-not $classes.Contains($ext)){$classes[$ext]=0};$classes[$ext]++}
[ordered]@{scope=$output;sha256=(Hash-Only $output);current_pins=$scope.current_source_pins.Count;backups=$scope.backup_targets.Count;explicit_count=$scope.explicit_paths.Count;class_counts=$classes;missing=0;traversal=0}|ConvertTo-Json -Depth 4
