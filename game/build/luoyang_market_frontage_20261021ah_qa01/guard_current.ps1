param(
 [Parameter(Mandatory=$true)][ValidateSet('before','after')][string]$Mode,
 [string]$BeforeSHA='',
 [string]$Workspace='F:\Code\RPG_GAME'
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
# Root executes. Only reads the fixed 2094 protected paths and creates a NEW report.
$taskWorkspace=[IO.Path]::GetFullPath($Workspace).TrimEnd([char[]]@('\','/'))
$taskRoot=Join-Path $taskWorkspace 'game/build/luoyang_market_frontage_20261021ah_root01'
$parentPath=Join-Path $taskWorkspace 'game/build/luoyang_market_frontage_20261021ag_root01/final_guard.json'
$parentSHA='aaa42c63cc444a752518ff50423af95f063cc202c2fa156c9215638cae57d919'
$beforePath=Join-Path $taskRoot 'guard_before.json'
$outputPath=if($Mode -ceq 'before'){$beforePath}else{Join-Path $taskRoot 'final_guard.json'}
function Sha([string]$path){return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()}
if(Test-Path -LiteralPath $outputPath){throw 'PRESERVE_EXISTING_AH_GUARD'}
if((Sha $parentPath) -cne $parentSHA){throw 'AG_FINAL2094_PIN_CHANGED'}
$parent=Get-Content -LiteralPath $parentPath -Raw|ConvertFrom-Json -AsHashtable
if($parent.passed -isnot [bool] -or !$parent.passed -or $parent.checked -ne 2094 -or $parent.facts.Count -ne 2094 -or $parent.save_count -ne 15 -or $parent.save_paths.Count -ne 15){throw 'AG_2094_AND15_DOMAIN'}
$paths=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($row in $parent.facts){
 if($row.path -isnot [string] -or ![IO.Path]::IsPathFullyQualified($row.path) -or !$paths.Add([IO.Path]::GetFullPath($row.path))){throw 'AG_UNIQUE_ABSOLUTE_PATHS'}
}
$saveSet=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($path in $parent.save_paths){if(!$paths.Contains([string]$path) -or !$saveSet.Add([string]$path)){throw 'EXACT15_SAVE_PATHS'}}
foreach($relative in @('game/project.godot','prompts/tasks.yaml')){if(!$paths.Contains([IO.Path]::GetFullPath((Join-Path $taskWorkspace $relative)))){throw 'PROJECT_OR_TASKS_PATH_MISSING'}}
$oldByPath=@{}
if($Mode -ceq 'after'){
 if($BeforeSHA -cnotmatch '^[0-9a-f]{64}$' -or (Sha $beforePath) -cne $BeforeSHA){throw 'EXPLICIT_ROOT_FRESH_BEFORE_SHA_REQUIRED'}
 $before=Get-Content -LiteralPath $beforePath -Raw|ConvertFrom-Json -AsHashtable
 if($before.status -cne 'AH_FRESH_CURRENT2094_FROM_AG_PATHS_NOT_VALUES' -or $before.count -ne 2094 -or $before.facts.Count -ne 2094 -or $before.save_count -ne 15 -or $before.parent_sha256 -cne $parentSHA){throw 'AH_BEFORE_DOMAIN'}
 foreach($row in $before.facts){
  if($row.path -isnot [string] -or !$paths.Contains($row.path) -or $oldByPath.ContainsKey($row.path) -or $row.ticks -isnot [string]){throw 'AH_BEFORE_PATH_OR_STRING_TICKS'}
  $oldByPath[$row.path]=$row
 }
 if($oldByPath.Count -ne 2094){throw 'AH_BEFORE_FULL_PATH_SET'}
}
$facts=@();$changes=@();$saveChanges=@()
foreach($path in @($paths|Sort-Object)){
 if(Test-Path -LiteralPath $path){
  $item=Get-Item -LiteralPath $path
  if($item.PSIsContainer){throw "PROTECTED_FILE_IS_DIRECTORY:$path"}
  $current=@{path=$path;sha256=(Sha $path);bytes=[long]$item.Length;ticks=[string]$item.LastWriteTimeUtc.Ticks}
 }else{$current=@{path=$path;sha256='ABSENT';bytes=0;ticks='0'}}
 $facts+=,$current
 if($Mode -ceq 'after'){
  $old=$oldByPath[$path]
  $shaChanged=([string]$current.sha256).ToLowerInvariant() -cne ([string]$old.sha256).ToLowerInvariant()
  $bytesChanged=$current.bytes -ne $old.bytes
  $ticksChanged=$current.ticks -cne $old.ticks
  if($shaChanged -or $bytesChanged -or $ticksChanged){
   $entry=@{path=$path;before=$old;after=$current;sha_changed=$shaChanged;bytes_changed=$bytesChanged;ticks_changed=$ticksChanged}
   $changes+=,$entry
   if($saveSet.Contains($path)){$saveChanges+=,$entry}
  }
 }
}
$passed=$facts.Count -eq 2094 -and $saveSet.Count -eq 15 -and $changes.Count -eq 0
$result=@{
 status=if($Mode -ceq 'before'){'AH_FRESH_CURRENT2094_FROM_AG_PATHS_NOT_VALUES'}else{'AH_FINAL2094_ZERO_AUTHORIZED_DIFFERENCES'}
 mode=$Mode;passed=$passed;count=$facts.Count;checked=$facts.Count
 parent_path=$parentPath;parent_sha256=$parentSHA;parent_fact_values_copied=$false
 facts=$facts;save_paths=@($parent.save_paths);save_count=$saveSet.Count
 authorized_paths=@();authorized_change_count=0
 unexpected_changes=$changes;unexpected_change_count=$changes.Count
 save_changes=$saveChanges;save_change_count=$saveChanges.Count
 all15save_exactticks_unchanged=($saveChanges.Count -eq 0)
 engine_import_image_save_or_production_writes=$false
}
if($Mode -ceq 'after'){$result.before_path=$beforePath;$result.before_sha256=$BeforeSHA;$result.exact_unchanged=$facts.Count-$changes.Count}
[IO.Directory]::CreateDirectory($taskRoot)|Out-Null
$stream=[IO.File]::Open($outputPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
$writer=[IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($false))
try{$writer.Write(($result|ConvertTo-Json -Depth 15)+"`n")}finally{$writer.Dispose()}
@{report=$outputPath;sha256=(Sha $outputPath);mode=$Mode;passed=$passed;checked=$facts.Count;save_count=15;unexpected_changes=$changes.Count;save_changes=$saveChanges.Count}|ConvertTo-Json -Depth 5
if(!$passed){exit 1}
