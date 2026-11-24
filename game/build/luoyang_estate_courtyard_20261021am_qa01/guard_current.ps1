param(
 [Parameter(Mandatory=$true)][ValidateSet('before','after')][string]$Mode,
 [string]$BeforeSHA='',
 [switch]$AllowTasksRegistration,
 [string]$Workspace='F:\Code\RPG_GAME'
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
# Root executes. Only reads the fixed 2094 protected paths and creates a NEW report.
$taskWorkspace=[IO.Path]::GetFullPath($Workspace).TrimEnd([char[]]@('\','/'))
$taskRoot=Join-Path $taskWorkspace 'game/build/luoyang_estate_courtyard_20261021am_root01'
$parentPath=Join-Path $taskWorkspace 'game/build/luoyang_estate_courtyard_20261021al_root01/final_guard.json'
$parentSHA='6221bef68d5232e7c234d3cefe4a8e621954263313cc27efbf9962740c7ba16e'
$beforePath=Join-Path $taskRoot 'guard_before.json'
$outputPath=if($Mode -ceq 'before'){$beforePath}else{Join-Path $taskRoot 'final_guard.json'}
function Sha([string]$path){return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()}
if(Test-Path -LiteralPath $outputPath){throw 'PRESERVE_EXISTING_AM_GUARD'}
if((Sha $parentPath) -cne $parentSHA){throw 'AL_FINAL2094_PIN_CHANGED'}
$parent=Get-Content -LiteralPath $parentPath -Raw|ConvertFrom-Json -AsHashtable
if($parent.passed -isnot [bool] -or !$parent.passed -or $parent.checked -ne 2094 -or $parent.facts.Count -ne 2094 -or $parent.save_count -ne 15 -or $parent.save_paths.Count -ne 15){throw 'AL_2094_AND15_DOMAIN'}
$paths=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($row in $parent.facts){
 if($row.path -isnot [string] -or ![IO.Path]::IsPathFullyQualified($row.path) -or !$paths.Add([IO.Path]::GetFullPath($row.path))){throw 'AL_UNIQUE_ABSOLUTE_PATHS'}
}
$saveSet=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($path in $parent.save_paths){if(!$paths.Contains([string]$path) -or !$saveSet.Add([string]$path)){throw 'EXACT15_SAVE_PATHS'}}
foreach($relative in @('game/project.godot','prompts/tasks.yaml')){if(!$paths.Contains([IO.Path]::GetFullPath((Join-Path $taskWorkspace $relative)))){throw 'PROJECT_OR_TASKS_PATH_MISSING'}}
$taskAllowed=[IO.Path]::GetFullPath((Join-Path $taskWorkspace 'prompts/tasks.yaml'))
$oldByPath=@{}
if($Mode -ceq 'after'){
 if($BeforeSHA -cnotmatch '^[0-9a-f]{64}$' -or (Sha $beforePath) -cne $BeforeSHA){throw 'EXPLICIT_ROOT_FRESH_BEFORE_SHA_REQUIRED'}
 $before=Get-Content -LiteralPath $beforePath -Raw|ConvertFrom-Json -AsHashtable
 if($before.status -cne 'AM_FRESH_CURRENT2094_FROM_AL_PATHS_NOT_VALUES' -or $before.count -ne 2094 -or $before.facts.Count -ne 2094 -or $before.save_count -ne 15 -or $before.parent_sha256 -cne $parentSHA){throw 'AM_BEFORE_DOMAIN'}
 foreach($row in $before.facts){
  if($row.path -isnot [string] -or !$paths.Contains($row.path) -or $oldByPath.ContainsKey($row.path) -or $row.ticks -isnot [string]){throw 'AM_BEFORE_PATH_OR_STRING_TICKS'}
  $oldByPath[$row.path]=$row
 }
 if($oldByPath.Count -ne 2094){throw 'AM_BEFORE_FULL_PATH_SET'}
 if($before.tasks_registration_authorized -isnot [bool] -or $before.tasks_registration_authorized -ne [bool]$AllowTasksRegistration){throw 'AUTHORIZATION_MUST_MATCH_FRESH_BEFORE'}
}
$facts=@();$changes=@();$saveChanges=@();$authorized=@();$unexpected=@()
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
   if($AllowTasksRegistration -and [StringComparer]::OrdinalIgnoreCase.Equals($path,$taskAllowed)){$authorized+=,$entry}else{$unexpected+=,$entry}
   if($saveSet.Contains($path)){$saveChanges+=,$entry}
  }
 }
}
$passed=$facts.Count -eq 2094 -and $saveSet.Count -eq 15 -and $unexpected.Count -eq 0 -and $saveChanges.Count -eq 0
$result=@{
 status=if($Mode -ceq 'before'){'AM_FRESH_CURRENT2094_FROM_AL_PATHS_NOT_VALUES'}else{'AM_FINAL2094_ONLY_EXPLICIT_TASKS_REGISTRATION_OR_ZERO_CHANGES'}
 mode=$Mode;passed=$passed;count=$facts.Count;checked=$facts.Count
 parent_path=$parentPath;parent_sha256=$parentSHA;parent_fact_values_copied=$false
 facts=$facts;save_paths=@($parent.save_paths);save_count=$saveSet.Count
 tasks_registration_authorized=[bool]$AllowTasksRegistration;authorized_paths=@(if($AllowTasksRegistration){$taskAllowed});authorized_change_count=$authorized.Count;authorized_changes=$authorized
 all_changes=$changes
 unexpected_changes=$unexpected;unexpected_change_count=$unexpected.Count
 save_changes=$saveChanges;save_change_count=$saveChanges.Count
 all15save_exactticks_unchanged=($saveChanges.Count -eq 0)
 coverage_boundary='Only inherited2094 paths; NEW native/artifacts outside this set must have a separate actual inventory. No whole-workspace zero-change claim.'
 engine_import_image_save_or_production_writes=$false
}
if($Mode -ceq 'after'){$result.before_path=$beforePath;$result.before_sha256=$BeforeSHA;$result.exact_unchanged=$facts.Count-$changes.Count}
[IO.Directory]::CreateDirectory($taskRoot)|Out-Null
$stream=[IO.File]::Open($outputPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
$writer=[IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($false))
try{$writer.Write(($result|ConvertTo-Json -Depth 15)+"`n")}finally{$writer.Dispose()}
@{report=$outputPath;sha256=(Sha $outputPath);mode=$Mode;passed=$passed;checked=$facts.Count;save_count=15;authorized_changes=$authorized.Count;unexpected_changes=$unexpected.Count;save_changes=$saveChanges.Count}|ConvertTo-Json -Depth 5
if(!$passed){exit 1}
