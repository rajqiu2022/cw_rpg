param([string]$Workspace='F:\Code\RPG_GAME')
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
# Root runs this once. It only reads protected facts and creates a NEW report;
# it never starts an engine, restores a file, or modifies a save/canonical asset.
$taskWorkspace=[IO.Path]::GetFullPath($Workspace).TrimEnd([char[]]@('\','/'))
$taskRoot=Join-Path $taskWorkspace 'game/build/luoyang_market_frontage_20261020af_root01'
$taskBefore=Join-Path $taskRoot 'guard_before.json'
$taskOutput=Join-Path $taskRoot 'final_guard.json'
$taskBeforeSHA='fffd9f165478d51410af2bfcf0a91499ce04c4f12208a3ea834f005d813bbf82'
$taskAllowed=[IO.Path]::GetFullPath((Join-Path $taskWorkspace 'prompts/tasks.yaml'))
if(Test-Path -LiteralPath $taskOutput){throw 'PRESERVE_EXISTING_AF_FINAL_GUARD'}
function Sha([string]$path){return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()}
if((Sha $taskBefore) -cne $taskBeforeSHA){throw 'AF_FRESH2094_BASELINE_CHANGED'}
$before=Get-Content -LiteralPath $taskBefore -Raw|ConvertFrom-Json -AsHashtable
if($before.status -cne 'AF_FRESH_CURRENT_BASELINE_NOT_COMPARISON_WITH_AE_OLD_VALUES' -or $before.count -ne 2094 -or $before.facts.Count -ne 2094 -or $before.saves_count -ne 15 -or $before.save_paths.Count -ne 15){throw 'AF_FRESH2094_OR_EXACT15_DOMAIN'}
$known=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($row in $before.facts){
 if($row.path -isnot [string] -or ![IO.Path]::IsPathFullyQualified($row.path) -or $row.ticks -isnot [string] -or !$known.Add([IO.Path]::GetFullPath($row.path))){throw 'ORIGINAL_UNIQUE_ABSOLUTE_PATH_STRING_TICKS'}
}
if(!$known.Contains($taskAllowed)){throw 'ONLY_AUTHORIZED_TASK_REGISTRATION_PATH_NOT_IN_BASELINE'}
$saveSet=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($path in $before.save_paths){if(!$known.Contains([string]$path) -or !$saveSet.Add([string]$path)){throw 'EXACT_FIFTEEN_SAVE_PATHS_MISSING_OR_DUPLICATE'}}
$facts=@();$changes=@();$allowed=@();$unexpected=@();$saveChanges=@()
foreach($old in $before.facts){
 $path=[IO.Path]::GetFullPath([string]$old.path)
 if(Test-Path -LiteralPath $path){
  $item=Get-Item -LiteralPath $path
  if($item.PSIsContainer){throw "PROTECTED_FILE_IS_DIRECTORY:$path"}
  $current=@{path=$path;sha256=(Sha $path);bytes=[long]$item.Length;ticks=[string]$item.LastWriteTimeUtc.Ticks}
 }else{$current=@{path=$path;sha256='ABSENT';bytes=0;ticks='0'}}
 $facts+=,$current
 $shaChanged=([string]$current.sha256).ToLowerInvariant() -cne ([string]$old.sha256).ToLowerInvariant()
 $bytesChanged=$current.bytes -ne $old.bytes
 $ticksChanged=$current.ticks -cne [string]$old.ticks
 if($shaChanged -or $bytesChanged -or $ticksChanged){
  $entry=@{path=$path;before=$old;after=$current;sha_changed=$shaChanged;bytes_changed=$bytesChanged;ticks_changed=$ticksChanged}
  $changes+=,$entry
  if([StringComparer]::OrdinalIgnoreCase.Equals($path,$taskAllowed)){$allowed+=,$entry}else{$unexpected+=,$entry}
  if($saveSet.Contains($path)){$saveChanges+=,$entry}
 }
}
$passed=$unexpected.Count -eq 0 -and $saveChanges.Count -eq 0 -and $facts.Count -eq 2094 -and $saveSet.Count -eq 15
$result=@{
 scope='AF_FRESH2094_EXACT_SHA_BYTES_STRING_TICKS_ONLY_TASKS_YAML_AUTHORIZED'
 passed=$passed
 before_path=$taskBefore
 before_sha256=$taskBeforeSHA
 checked=$facts.Count
 exact_unchanged=$facts.Count-$changes.Count
 authorized_path=$taskAllowed
 authorized_change_count=$allowed.Count
 authorized_changes=$allowed
 unexpected_change_count=$unexpected.Count
 unexpected_changes=$unexpected
 all_changes=$changes
 save_paths=@($before.save_paths)
 save_count=$saveSet.Count
 save_change_count=$saveChanges.Count
 save_changes=$saveChanges
 all15save_exactticks_unchanged=($saveChanges.Count -eq 0)
 facts=$facts
 engine_started=$false
 production_save_or_restore_writes=$false
}
$stream=[IO.File]::Open($taskOutput,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
$writer=[IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($false))
try{$writer.Write(($result|ConvertTo-Json -Depth 15)+"`n")}finally{$writer.Dispose()}
@{report=$taskOutput;sha256=(Sha $taskOutput);passed=$passed;checked=$facts.Count;authorized_changes=$allowed.Count;unexpected_changes=$unexpected.Count;save_changes=$saveChanges.Count}|ConvertTo-Json -Depth 5
if(!$passed){exit 1}

