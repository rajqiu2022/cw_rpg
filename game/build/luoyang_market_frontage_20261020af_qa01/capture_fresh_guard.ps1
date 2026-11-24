param([string]$Workspace='F:\Code\RPG_GAME')
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
# Root-executed fresh CURRENT baseline only. Does not compare current values with
# AE's pre-deployment values, run an engine, import, or touch a save.
$taskWorkspace=[IO.Path]::GetFullPath($Workspace).TrimEnd([char[]]@('\','/'))
$taskGame=[IO.Path]::GetFullPath((Join-Path $taskWorkspace 'game'))
$taskRoot=[IO.Path]::GetFullPath((Join-Path $taskGame 'build/luoyang_market_frontage_20261020af_root01'))
$taskOutput=Join-Path $taskRoot 'guard_before.json'
if(Test-Path -LiteralPath $taskOutput){throw 'PRESERVE_EXISTING_AF_FRESH_GUARD'}
function ResourceDisk([string]$path){
 if(!$path.StartsWith('res://',[StringComparison]::Ordinal) -or $path.Substring(6).Split('/') -contains '..'){throw "INVALID_RESOURCE_PATH:$path"}
 $result=[IO.Path]::GetFullPath((Join-Path $taskGame $path.Substring(6)))
 if(!$result.StartsWith($taskGame+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw "RESOURCE_OUTSIDE_GAME:$path"}
 return $result
}
function Sha([string]$path){return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()}
function ReadPinned([string]$path,[string]$sha){
 if((Sha $path) -cne $sha){throw "FIXED_INPUT_CHANGED:$path"}
 return Get-Content -LiteralPath $path -Raw|ConvertFrom-Json -AsHashtable
}
$oldResource='res://build/luoyang_shore_market_20261020ae_root01/guard_before.json'
$oldSha='e4742ef8a46fd78c1363aca734edbabc6a3c5f7d19a9ccc6928f1c474031eaba'
$old=ReadPinned (ResourceDisk $oldResource) $oldSha
if($old.facts.Count -ne 1782 -or $old.count -ne 1782){throw 'AE_OLD_PATH_SET_NOT_1782'}
$paths=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
function AddPath([string]$path,[string]$origin){
 if(![IO.Path]::IsPathFullyQualified($path)){throw "BASELINE_PATH_NOT_ABSOLUTE:$path"}
 $absolute=[IO.Path]::GetFullPath($path)
 if(!$paths.ContainsKey($absolute)){$paths.Add($absolute,$origin)}
}
foreach($row in $old.facts){AddPath ([string]$row.path) 'AE1782_PATH_ONLY_NOT_OLD_FACT_VALUE'}
$savePattern='(?:^|[\\/])save_[0-4]\.json(?:\.(?:bak|tmp))?$'
$saveRows=@($old.facts|Where-Object{[string]$_.path -match $savePattern -and !([IO.Path]::GetFullPath([string]$_.path)).StartsWith($taskWorkspace+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)})
$saveDirectories=@($saveRows|ForEach-Object{[IO.Path]::GetDirectoryName([IO.Path]::GetFullPath([string]$_.path))}|Sort-Object -Unique)
if($saveRows.Count -ne 15 -or $saveDirectories.Count -ne 1){throw 'ORIGINAL_EXACT_FIFTEEN_SAVE_PATH_DOMAIN'}
$saveDirectory=[string]$saveDirectories[0]
$savePaths=@()
foreach($slot in 0..4){foreach($suffix in @('.json','.json.bak','.json.tmp')){
 $savePath=Join-Path $saveDirectory ('save_'+$slot+$suffix)
 if(!$paths.ContainsKey([IO.Path]::GetFullPath($savePath))){throw "ORIGINAL_SAVE_PATH_ABSENT:$savePath"}
 AddPath $savePath 'EXACT15_SAVE_CURRENT_FACT';$savePaths+=,[IO.Path]::GetFullPath($savePath)
}}
$reports=@(
 @{path='res://build/luoyang_shore_market_20261020ae_qa01/field_65540/result.json';sha256='e0a683b2e6db03aeb768d62e21a68cca0cee603bf4b86d47448c8cd8ceb05e5d';count=1529;scope='AE_ONE_ORDINARY_DOCKS_VISUAL_LAYER_SHORT_INPUT_NOT_NPC_OR_NEW_GEOMETRY'},
 @{path='res://build/luoyang_shore_market_20261020ae_qa01/market_114244/result.json';sha256='d0e9b08c22e91e939dd8cff711e2ad461aad40438f71ed0d70dc723736cb6bb6';count=1261;scope='AE_MARKET_FIRST_GROUND_CLUSTER_EXACT36_PREFIX_SHORT_INPUT_NOT_ROOMS_NPC'}
)
foreach($row in $reports){
 $actual=ReadPinned (ResourceDisk $row.path) $row.sha256
 if($actual.complete -isnot [bool] -or !$actual.complete -or $actual.failures -ne 0 -or $actual.scope -cne $row.scope -or $actual.source_before -isnot [Collections.IDictionary] -or $actual.source_before.Count -ne $row.count){throw "ACTUAL_REPORT_COMPONENT_DOMAIN:$($row.path)"}
 # Only consume fixed source PATHS. All values below are freshly read, so an
 # authorized change since AE is a new baseline value, not a comparison FAIL.
 foreach($source in $actual.source_before.Keys){
  if(([string]$source).StartsWith('res://',[StringComparison]::Ordinal)){AddPath (ResourceDisk ([string]$source)) $row.path}
  elseif(([string]$source).StartsWith('user://',[StringComparison]::Ordinal)){
   $name=([string]$source).Substring(7)
   if($name -cnotmatch '^save_[0-4]\.json(?:\.(?:bak|tmp))?$'){throw "NON_SAVE_USER_SOURCE:$source"}
   AddPath (Join-Path $saveDirectory $name) $row.path
  }else{throw "UNKNOWN_SOURCE_NAMESPACE:$source"}
 }
}
AddPath (Join-Path $taskGame 'project.godot') 'PROJECT_GODOT_EXPLICIT_CURRENT_FACT'
$facts=@()
foreach($path in @($paths.Keys|Sort-Object)){
 if(Test-Path -LiteralPath $path){
  $item=Get-Item -LiteralPath $path
  if($item.PSIsContainer){throw "SOURCE_IS_DIRECTORY:$path"}
  $facts+=,@{path=$path;sha256=(Sha $path);bytes=[long]$item.Length;ticks=[string]$item.LastWriteTimeUtc.Ticks}
 }else{$facts+=,@{path=$path;sha256='ABSENT';bytes=0;ticks='0'}}
}
if(@($facts|Where-Object{$_.ticks -isnot [string]}).Count -ne 0){throw 'EXACT_TICKS_MUST_REMAIN_STRINGS'}
$result=@{
 status='AF_FRESH_CURRENT_BASELINE_NOT_COMPARISON_WITH_AE_OLD_VALUES'
 collection='UNION_AE1782_PATHS_TWO_ACTUAL_SOURCE_PATHSETS_EXACT15SAVE_PROJECT'
 count=$facts.Count
 inputs=@{ae1782=@{path=$oldResource;sha256=$oldSha};actual_reports=$reports}
 facts=$facts
 save_paths=$savePaths
 saves_count=15
 old_fact_values_copied=$false
 engine_import_save_or_canonical_writes=$false
}
[IO.Directory]::CreateDirectory($taskRoot)|Out-Null
$stream=[IO.File]::Open($taskOutput,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
$writer=[IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($false))
try{$writer.Write(($result|ConvertTo-Json -Depth 12)+"`n")}finally{$writer.Dispose()}
@{report=$taskOutput;sha256=(Sha $taskOutput);count=$facts.Count;save_count=15;fresh_current=$true;engine_executed=$false}|ConvertTo-Json -Depth 5

