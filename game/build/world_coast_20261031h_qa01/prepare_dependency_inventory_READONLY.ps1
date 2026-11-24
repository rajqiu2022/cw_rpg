$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'USE_BUNDLED_PWSH7'}
$repo='F:/Code/RPG_GAME';$taskDir=$repo+'/game/build/world_coast_20261031h_qa01';$output=$taskDir+'/dependency_inventory_READONLY.json'
if(Test-Path -LiteralPath $output){throw 'PRESERVE_EXISTING_INVENTORY'}
function Hash-Only([string]$p){$s=[IO.File]::OpenRead($p);try{return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($s)).ToLowerInvariant()}finally{$s.Dispose()}}
function Canonical([string]$p){if($p.StartsWith('res://')){$p=$repo+'/game/'+$p.Substring(6)}elseif(-not [IO.Path]::IsPathRooted($p)){$p=$repo+'/'+$p};return [IO.Path]::GetFullPath($p).Replace('\','/')}
$scopePath=$taskDir+'/source_scope_READY02.json';$scope=[IO.File]::ReadAllText($scopePath,[Text.Encoding]::UTF8)|ConvertFrom-Json -AsHashtable
$seedPath=Canonical $scope.seed
if((Hash-Only $seedPath) -cne $scope.seed_sha256){throw 'SEED_PIN'}
$seed=[IO.File]::ReadAllText($seedPath,[Text.Encoding]::UTF8)|ConvertFrom-Json -AsHashtable
$protected=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($field in @('facts','evidence_facts')){foreach($p in $seed[$field].Keys){[void]$protected.Add((Canonical $p))}}
$queue=[Collections.Generic.Queue[string]]::new();$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase);$readers=[ordered]@{};$missing=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($p in $scope.dependency_roots){$queue.Enqueue((Canonical $p))}
while($queue.Count -gt 0){
 $p=$queue.Dequeue();if(-not $seen.Add($p)){continue}
 if(-not(Test-Path -LiteralPath $p -PathType Leaf)){[void]$missing.Add($p);continue}
 $sidecar=$p+'.import';if(Test-Path -LiteralPath $sidecar -PathType Leaf){$queue.Enqueue($sidecar)}
 if([IO.Path]::GetExtension($p) -notin @('.tres','.import')){continue}
 $sha=Hash-Only $p;$content=[IO.File]::ReadAllText($p,[Text.Encoding]::UTF8)
 foreach($m in [regex]::Matches($content,'res://[^"\r\n]+')){
  $ref=Canonical $m.Value
  if(-not $ref.StartsWith($repo+'/game/')){throw 'RESOURCE_REFERENCE_OUTSIDE_GAME'}
  if(Test-Path -LiteralPath $ref -PathType Leaf){$queue.Enqueue($ref)}else{[void]$missing.Add($ref)}
 }
 if((Hash-Only $p) -cne $sha){throw ('READER_CHANGED:'+ $p)}
 $readers[$p]=$sha
}
$classes=[ordered]@{};$newClasses=[ordered]@{};$paths=@($seen|Sort-Object);$new=@()
foreach($p in $paths){
 $class=[IO.Path]::GetExtension($p).ToLowerInvariant();if(-not $classes.Contains($class)){$classes[$class]=0};$classes[$class]++
 if(-not $protected.Contains($p)){$new+=@($p);if(-not $newClasses.Contains($class)){$newClasses[$class]=0};$newClasses[$class]++}
}
$result=[ordered]@{status='EXACT_RESOURCE_REFERENCE_INVENTORY_ONLY_NOT_BASELINE';scope_path=$scopePath;scope_sha256=(Hash-Only $scopePath);seed_sha256=$scope.seed_sha256;unique_count=$paths.Count;class_counts=$classes;not_in31f_count=$new.Count;not_in31f_class_counts=$newClasses;not_in31f_paths=$new;missing_references=@($missing|Sort-Object);reader_pins=$readers;paths=$paths;whole_build_recursion=0;engine_runs=0;save_deserializations=0;save_writes=0;production_writes=0}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($result|ConvertTo-Json -Depth 10)+[Environment]::NewLine);$stream=[IO.File]::Open($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);try{$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
[ordered]@{inventory=$output;sha256=(Hash-Only $output);unique_count=$paths.Count;class_counts=$classes;not_in31f_count=$new.Count;not_in31f_class_counts=$newClasses;missing_references=@($missing|Sort-Object);reader_count=$readers.Count}|ConvertTo-Json -Depth 5
