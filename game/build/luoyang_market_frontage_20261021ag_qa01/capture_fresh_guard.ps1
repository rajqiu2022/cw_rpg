param([string]$Workspace='F:\Code\RPG_GAME')
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
# NEW current-facts capture only. Root executes; no engine/import/save writes.
$taskWorkspace=[IO.Path]::GetFullPath($Workspace).TrimEnd([char[]]@('\','/'))
$taskRoot=Join-Path $taskWorkspace 'game/build/luoyang_market_frontage_20261021ag_root01'
$taskOutput=Join-Path $taskRoot 'guard_before.json'
$priorPath=Join-Path $taskWorkspace 'game/build/luoyang_market_frontage_20261020af_root01/final_guard.json'
$priorSHA='9f6bcca3daa78e6092e41b8a803581ce57345fd8568e318516713a90906ed833'
if(Test-Path -LiteralPath $taskOutput){throw 'PRESERVE_EXISTING_AG_FRESH_GUARD'}
function Sha([string]$path){return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()}
if((Sha $priorPath) -cne $priorSHA){throw 'PINNED_AF_FINAL_GUARD_CHANGED'}
$prior=Get-Content -LiteralPath $priorPath -Raw|ConvertFrom-Json -AsHashtable
if($prior.passed -isnot [bool] -or !$prior.passed -or $prior.checked -ne 2094 -or $prior.facts.Count -ne 2094 -or $prior.save_count -ne 15 -or $prior.save_paths.Count -ne 15){throw 'AF_FINAL2094_AND15_PATH_DOMAIN'}
$paths=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($row in $prior.facts){
 if($row.path -isnot [string] -or ![IO.Path]::IsPathFullyQualified($row.path) -or !$paths.Add([IO.Path]::GetFullPath($row.path))){throw 'AF_UNIQUE_ABSOLUTE_PATH_SET'}
}
$saveSet=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($path in $prior.save_paths){if(!$paths.Contains([string]$path) -or !$saveSet.Add([string]$path)){throw 'EXACT15_SAVE_PATHS'}}
$project=[IO.Path]::GetFullPath((Join-Path $taskWorkspace 'game/project.godot'))
$tasks=[IO.Path]::GetFullPath((Join-Path $taskWorkspace 'prompts/tasks.yaml'))
if(!$paths.Contains($project) -or !$paths.Contains($tasks)){throw 'PROJECT_OR_TASK_REGISTRATION_PATH_ABSENT'}
$facts=@()
foreach($path in @($paths|Sort-Object)){
 if(Test-Path -LiteralPath $path){
  $item=Get-Item -LiteralPath $path
  if($item.PSIsContainer){throw "PROTECTED_FILE_IS_DIRECTORY:$path"}
  $facts+=,@{path=$path;sha256=(Sha $path);bytes=[long]$item.Length;ticks=[string]$item.LastWriteTimeUtc.Ticks}
 }else{$facts+=,@{path=$path;sha256='ABSENT';bytes=0;ticks='0'}}
}
$result=@{
 status='AG_FRESH_CURRENT2094_FROM_AF_FINAL_PATHS_NOT_COPIED_VALUES'
 count=$facts.Count
 parent_path=$priorPath
 parent_sha256=$priorSHA
 parent_fact_values_copied=$false
 facts=$facts
 save_paths=@($prior.save_paths)
 save_count=15
 source_values='NEW_CURRENT_SHA_BYTES_STRING_EXACT_UTC_TICKS'
 engine_import_save_or_production_writes=$false
}
[IO.Directory]::CreateDirectory($taskRoot)|Out-Null
$stream=[IO.File]::Open($taskOutput,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
$writer=[IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($false))
try{$writer.Write(($result|ConvertTo-Json -Depth 12)+"`n")}finally{$writer.Dispose()}
@{report=$taskOutput;sha256=(Sha $taskOutput);count=$facts.Count;save_count=15;fresh_current=$true;engine_executed=$false}|ConvertTo-Json -Depth 5

