param(
 [Parameter(Mandatory=$true)][string[]]$WrapperRunDirectories,
 [Parameter(Mandatory=$true)][string]$OutputDirectory,
 [string]$ProjectRoot='F:\Code\RPG_GAME',
 [string]$PlayerDirectory='C:\Users\rajqiu\AppData\Roaming\Godot\app_userdata\云影侠传'
)
# READ ONLY evidence consumer. Writes only a NEW unique BUILD draft, never the
# activator APPROVAL_PATH, signatures, formal scenes, imports, player files or OS.
# Six actually complete candidate runs are mandatory. No source-only/limited/
# aborted evidence can fill a slot. ROOT visual/actual approval remains pending.
$ErrorActionPreference='Stop'
$project=[IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
$game=Join-Path $project 'game'
$domain=Join-Path $game 'build\joint_world_luoyang_20261003_qa'
$target=[IO.Path]::GetFullPath($OutputDirectory)
$players=[IO.Path]::GetFullPath($PlayerDirectory).TrimEnd('\')
if ($WrapperRunDirectories.Count -ne 6 -or -not $target.StartsWith($domain+'\',[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $target)) { throw 'Exactly six wrappers and a NEW unique QA BUILD output are required' }
$entry='res://tests/test_luoyang_enclosure_v11_city_only_fresh_20261009.gd'
$engineSHA='975BF1D254B989EE12B64DF4D07DA692A31175F72424BAA180F1078BFC0D71B0'
$ids=@('ch4_s0_luoyang_gate','ch4_s1_luoyang_yamen','ch4_s2_canal_docks','ch4_s3_luoyang_market')
$required=@(
 'scripts/city/luoyang_enclosure_v11_candidate_contract.gd','scripts/city/luoyang_layered_v3_contract.gd',
 'scripts/field/field_walkable_controller.gd','scripts/city/luoyang_city3_motion_guard_20261009.gd',
 'scripts/field/player.gd','scripts/autoload/scene_router.gd','scripts/autoload/save_manager.gd',
 'scripts/autoload/platform_bridge.gd','scripts/autoload/audio_manager.gd',
 'tests/test_luoyang_enclosure_v11_city_only_fresh_20261009.gd',
 'tests/helpers/luoyang_enclosure_v11_city_only_phase.gd','tests/helpers/luoyang_enclosure_v11_city_only_raw.gd',
 'tests/helpers/luoyang_enclosure_v11_city_only_target_raw.gd','tests/helpers/luoyang_enclosure_v11_city_only_current_save.gd',
 'tests/helpers/joint_v15_wall_v5_fine_alpha_probe.gd','tests/helpers/joint_v15_wall_v5_city_physical_alpha_probe.gd',
 'tests/helpers/joint_v15_wall_street_city_physical_alpha_probe.gd',
 'tests/helpers/luoyang_enclosure_v11_roof_front_actual_probe_20261009.gd','tests/helpers/luoyang_enclosure_v11_roof_front_proof_20261009.gd',
 'tests/helpers/v15_input_driver.gd','tests/helpers/joint_v15_wasapi_operational_bgm_continuity_20261007.gd',
 'tests/helpers/joint_v15_wasapi_operational_city_phase_20261007.gd','tests/helpers/v15_isolated_save_manager.gd'
)
$fixed=@{
 'res://scripts/field/field_walkable_controller.gd'='93A34013D42A773F0FE82C77B82ED6A2477DBEDF25D771137EB1EB455CDCFB93'
 'res://scripts/city/luoyang_city3_motion_guard_20261009.gd'='AACD53E5020BC5A40353D9CF7537662C44139FA7F861E3A54C6FAF59E8BA3A93'
 'res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd'='D112F9E7867D612596AB1EAD2428000749EA44F62A26433A73E170480AF6EC51'
 'res://scripts/field/player.gd'='9F283BEAA3F8C3C3B5EB36547627E5414D91722078DFC00D08BF2F07F2910419'
}
# Bind actual literal script dependencies of these critical roots as well, so
# changing an inherited consumer cannot evade the post-draft source predicate.
# This is .gd source closure only, never JSON/catalog/whole-world traversal.
$closure=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$scriptQueue=[Collections.Generic.Queue[string]]::new()
foreach ($key in $required) { $scriptQueue.Enqueue($key) }
while ($scriptQueue.Count -gt 0) {
 $key=$scriptQueue.Dequeue()
 if (-not $closure.Add($key)) { continue }
 $path=[IO.Path]::GetFullPath((Join-Path $game $key))
 if (-not $path.StartsWith($game+'\',[StringComparison]::OrdinalIgnoreCase)) { throw "Critical script outside game domain: $key" }
 if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Critical source closure absent: $key" }
 foreach ($dependency in [regex]::Matches([IO.File]::ReadAllText($path),'res://([^"''\r\n]+\.gd)(?=["''\r\n])')) {
  $child=$dependency.Groups[1].Value
  if ($child -ceq 'scripts/dev/activate_luoyang_enclosure_v11_city_only.gd') { continue }
  $scriptQueue.Enqueue($child)
 }
}
$required=@($closure | Sort-Object)
$allSources=@{}; $evidence=@{}; $sourceSHAs=[ordered]@{}
$seenRuns=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$seenSlots=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$seenResults=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$rows=[Collections.Generic.List[object]]::new(); $provenance=[Collections.Generic.List[object]]::new(); $playerChecks=[Collections.Generic.List[object]]::new()
function Require([bool]$ok,[string]$why) { if (-not $ok) { throw $why } }
function Hash([string]$path) { Require (Test-Path -LiteralPath $path -PathType Leaf) "Missing evidence/source: $path"; return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash }
function Read-Record([string]$path) {
 $record=Get-Content -LiteralPath $path -Raw | ConvertFrom-Json -AsHashtable -Depth 100
 Require ($record -is [Collections.IDictionary]) "Expected dictionary: $path"
 $evidence[$path]=Hash $path
 return $record
}
function Equal($a,$b) {
 if ($null -eq $a -or $null -eq $b) { return $null -eq $a -and $null -eq $b }
 if ($a -is [Collections.IDictionary]) {
  if ($b -isnot [Collections.IDictionary] -or $a.Count -ne $b.Count) { return $false }
  foreach ($key in $a.Keys) { if (-not $b.Contains($key) -or -not (Equal $a[$key] $b[$key])) { return $false } }
  return $true
 }
 if ($a -is [array]) {
  if ($b -isnot [array] -or $a.Count -ne $b.Count) { return $false }
  for ($i=0;$i -lt $a.Count;$i++) { if (-not (Equal $a[$i] $b[$i])) { return $false } }
  return $true
 }
 return $a.GetType() -eq $b.GetType() -and $a -ceq $b
}
function Source-Path([string]$path) {
 if ($path.StartsWith('res://')) { $path=Join-Path $game $path.Substring(6) }
 elseif (-not [IO.Path]::IsPathRooted($path)) { $path=Join-Path $project $path }
 $resolved=[IO.Path]::GetFullPath($path)
 Require ($resolved.StartsWith($project+'\',[StringComparison]::OrdinalIgnoreCase)) "Outside project source: $path"
 return $resolved
}
function Evidence-Path([string]$path) {
 $resolved=Source-Path $path
 Require ($resolved.StartsWith($domain+'\',[StringComparison]::OrdinalIgnoreCase)) "Outside fixed QA evidence domain: $path"
 return $resolved
}
function Add-Source($row,$map) {
 Require ($row -is [Collections.IDictionary] -and $row.path -is [string] -and $row.sha256 -is [string] -and $row.sha256 -cmatch '^[A-Fa-f0-9]{64}$' -and $row.bytes -is [long] -and $row.bytes -ge 0) 'Malformed outer source row'
 $path=Source-Path $row.path
 if ($map.ContainsKey($path)) {
  Require ($map[$path].sha256 -ieq $row.sha256 -and $map[$path].bytes -eq $row.bytes) "Conflicting duplicate wrapper source: $path"
  return $true
 }
 $map[$path]=$row
 if ($allSources.ContainsKey($path)) { Require ($allSources[$path].sha256 -ieq $row.sha256 -and $allSources[$path].bytes -eq $row.bytes) "Sources changed between the six runs: $path" }
 else { $allSources[$path]=$row }
 return $false
}
function Check-Players($before,$result) {
 Require ($before -is [array] -and $before.Count -eq 15 -and $result.players_before -is [Collections.IDictionary] -and $result.players_before.Count -eq 15 -and (Equal $result.players_before $result.players_after)) 'Fifteen player endpoints missing/differ'
 Require ($result.active_slot_before -is [long] -and $result.active_slot_before -ge 0 -and $result.active_slot_before -le 4 -and (Equal $result.active_slot_before $result.active_slot_after)) 'Active slot changed/invalid'
 $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 foreach ($row in $before) {
  Require ($row -is [Collections.IDictionary] -and $row.path -is [string] -and $row.exists -is [bool]) 'Malformed outer player row'
  $path=[IO.Path]::GetFullPath($row.path); $leaf=[IO.Path]::GetFileName($path)
  Require ([IO.Path]::GetDirectoryName($path) -ieq $players -and $leaf -cmatch '^save_[0-4]\.json(?:\.bak|\.tmp)?$' -and $seen.Add($path)) 'Wrong/duplicate player protection domain'
  $present=Test-Path -LiteralPath $path -PathType Leaf
  Require ($present -eq $row.exists) "Current player existence differs: $leaf"
  $inner=$result.players_before['user://'+$leaf]
  Require ($inner -is [Collections.IDictionary] -and $inner.exists -is [bool] -and $inner.exists -eq $present) "Internal player domain mismatch: $leaf"
  if ($present) {
   $item=Get-Item -LiteralPath $path
   Require ($row.utc_ticks -is [string] -and $row.utc_ticks -cmatch '^[0-9]{18}$' -and $item.LastWriteTimeUtc.Ticks.ToString() -ceq $row.utc_ticks -and $row.bytes -eq $item.Length -and (Hash $path) -ieq $row.sha256) "Current player bytes/SHA/exact ticks differ: $leaf"
   Require ($inner.bytes -eq $row.bytes -and $inner.sha256 -ieq $row.sha256) "Internal/outer player bytes differ: $leaf"
  } else { Require ($inner.bytes -eq 0 -and $inner.sha256 -ceq 'ABSENT') "Absent player representation invalid: $leaf" }
 }
}
function Read-FixedInventory([string]$relative,[string]$sha,[int]$count) {
 $path=Evidence-Path (Join-Path $domain $relative)
 Require ((Hash $path) -ceq $sha) 'Fixed finite source inventory SHA differs'
 $record=Read-Record $path
 Require ($record.scope -ceq 'FRESH_CURRENT_LUOYANG_FOUR_DISTRICTS_SOURCE_INVENTORY_ONLY' -and $record.mode -ceq 'candidate' -and $record.stage -ceq 'all' -and $record.sources -is [array] -and $record.sources.Count -eq $count) 'Fixed source inventory schema/count differs'
 $map=@{}
 foreach ($row in $record.sources) { Require (-not (Add-Source $row $map)) 'Fixed inventory contains duplicate source' }
 return @{path=$path;sha256=$sha;map=$map}
}
function Check-FirstInventory($map,$reference,[bool]$geometry) {
 foreach ($path in $reference.map.Keys) {
  $row=$reference.map[$path]
  Require ($map.ContainsKey($path) -and $map[$path].sha256 -ieq $row.sha256 -and $map[$path].bytes -eq $row.bytes) "Fixed finite inventory leaf absent/different in this actual first guard: $path"
 }
 if ($geometry) {
  foreach ($id in $ids) { foreach ($suffix in @('scene','layout')) {
   $path=Source-Path ('res://data/maps/luoyang_v3_legacy/'+$id+'_'+$suffix+'.tres')
   Require ($map.ContainsKey($path) -and (Hash $path) -ieq $map[$path].sha256 -and (Get-Item -LiteralPath $path).Length -eq $map[$path].bytes) 'Exact eight geometry legacy leaves absent/different in first guard'
  } }
 }
}
function Check-UnknownVersions($records) {
 Require ($records -is [array] -and $records.Count -eq 20) 'Unknown local version matrix missing'
 $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
 foreach ($row in $records) {
  Require ($row -is [Collections.IDictionary] -and $row.scene_id -is [string] -and $row.scene_id -cin $ids -and $row.version_domain -is [string] -and $row.version_domain -ceq 'local') 'Wrong unknown local version case'
  $v=$row.version; $tag=''
  if ($v -is [bool]) { if ($v) { $tag='BOOL:true' } }
  elseif ($v -is [string]) { if ($v -ceq '3') { $tag='STRING:3' } }
  elseif ($v -is [long] -or $v -is [double]) {
   if ($v -eq 2) { $tag='NUMBER:2' }
   elseif ($v -eq 99) { $tag='NUMBER:99' }
   elseif ($v -eq 1.5) { $tag='NUMBER:1.5' }
  }
  Require ($tag.Length -gt 0 -and $seen.Add($row.scene_id+'/'+$tag)) 'Unknown/missing/duplicate typed unsupported version'
  Require ($row.loaded -is [bool] -and -not $row.loaded -and $row.zero_mutation -is [bool] -and $row.zero_mutation -and $row.before -is [Collections.IDictionary] -and $row.before.Count -gt 0 -and (Equal $row.before $row.after)) 'Unsupported version loaded or mutated live state'
 }
 Require ($seen.Count -eq 20) 'Four by five typed local version matrix incomplete'
}
$stackSourceCache=@{}
function Check-ConcreteStack([string]$method,[string]$res,[int]$line,$map) {
 $path=Source-Path $res
 Require ($map.ContainsKey($path) -and $res.EndsWith('.gd',[StringComparison]::Ordinal) -and $line -gt 0) 'Image backtrace source lacks this first guard'
 if (-not $stackSourceCache.ContainsKey($path)) {
  Require ((Hash $path) -ieq $map[$path].sha256) 'Concrete backtrace source changed'
  $stackSourceCache[$path]=[IO.File]::ReadAllLines($path)
 }
 $code=$stackSourceCache[$path]
 Require ($line -le $code.Count) 'Image backtrace line outside actual source'
 # Bind the concrete frame to its nearest actual function declaration, not an
 # arbitrary bare line or a method name appearing elsewhere in a file.
 $owner=''
 for ($i=$line-1;$i -ge 0;$i--) {
  $decl=[regex]::Match($code[$i],'^\s*(?:static\s+)?func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(')
  if ($decl.Success) { $owner=$decl.Groups[1].Value; break }
 }
 Require ($owner -ceq $method) 'Concrete Image backtrace method/line differs from actual source'
}
function Check-FullStderr([string]$stderr,$map) {
 $lines=@($stderr -split '\r?\n')
 # Only the terminal newline is a separator, not an accepted unknown bare line.
 if ($lines.Count -gt 0 -and $lines[-1] -ceq '') { $lines=@($lines|Select-Object -SkipLast 1) }
 $i=0; $warningCount=0; $frameCount=0
 while ($i -lt $lines.Count) {
  $header=[regex]::Match($lines[$i],"^WARNING: Loaded resource as image file, this will not work on export: '(res://[^']+)'\. Instead, import the image file as an Image resource and load it normally as a resource\.$")
  Require $header.Success "Unknown stderr line at $($i+1); pending draft refused"
  $image=Source-Path $header.Groups[1].Value
  Require ($map.ContainsKey($image)) 'Known Image warning resource absent from actual first guard'
  Require ($i+2 -lt $lines.Count -and $lines[$i+1] -ceq '   at: load_from_file (core/io/image.cpp:2766)' -and $lines[$i+2] -ceq '   GDScript backtrace (most recent call first):') 'Unknown/malformed Image warning native/backtrace lines'
  $i+=3; $index=0
  while ($i -lt $lines.Count) {
   $frame=[regex]::Match($lines[$i],'^       \[([0-9]+)\] ([A-Za-z_][A-Za-z0-9_]*) \((res://[^():]+\.gd):([0-9]+)\)$')
   if (-not $frame.Success) { break }
   Require ([int]$frame.Groups[1].Value -eq $index) 'Nonconsecutive Image backtrace frames'
   Check-ConcreteStack $frame.Groups[2].Value $frame.Groups[3].Value ([int]$frame.Groups[4].Value) $map
   $index+=1; $frameCount+=1; $i+=1
  }
  Require ($index -gt 0) 'Known Image warning requires concrete validated backtrace'
  $warningCount+=1
 }
 return @{warnings=$warningCount;concrete_frames=$frameCount;unknown_lines=0}
}
# Explicit bounded inventory facts, not an independent declaration that every
# dynamic runtime dependency is complete. ROOT must review each slot first guard.
$geometryInventory=Read-FixedInventory '424_luoyang_full_source_inventory_20261009/source_inventory.json' '29E9F1B12D984134BED7E8AE292D0D4F68BA4706E053A56997A9A978BAAD99A6' 4381
$currentInventory=Read-FixedInventory '428_luoyang_finite_source_inventory_retry3_20261009/source_inventory.json' '7CC2EF19AE0329DBEA384EE8084ED75FCFF75B0EB9C0CBA3CA1D6AB455ED0C23' 4614


foreach ($value in $WrapperRunDirectories) {
 $directory=Evidence-Path $value
 Require ((Test-Path -LiteralPath $directory -PathType Container) -and $seenRuns.Add($directory)) 'Missing/duplicate wrapper directory'
 Require (-not (Test-Path -LiteralPath (Join-Path $directory 'known_failure_abort.json'))) 'Aborted run cannot satisfy any approval endpoint'
 $beforePath=Join-Path $directory 'before.json'; $afterPath=Join-Path $directory 'after.json'
 $stdoutPath=Join-Path $directory 'stdout.log'; $stderrPath=Join-Path $directory 'stderr.log'
 $before=Read-Record $beforePath; $after=Read-Record $afterPath
 Require ($after.actual_os_exit -is [long] -and $after.actual_os_exit -eq 0 -and $after.source_changes -is [array] -and $after.source_changes.Count -eq 0 -and $after.player_file_changes -is [array] -and $after.player_file_changes.Count -eq 0) 'Actual OS/source/player comparison did not pass'
 Require ([DateTimeOffset]::Parse($after.after_utc) -gt [DateTimeOffset]::Parse($before.started_utc)) 'Invalid completed actual process timestamps'
 Require ($before.entry -ceq $entry -and $before.gpu -is [bool] -and $before.requested_audio_driver -ceq 'WASAPI' -and $before.user_arguments -is [array] -and $before.actual_engine_arguments -is [array]) 'Wrong actual entry/driver/argument evidence'
 $userArgs=$before.user_arguments; $phases=@($userArgs | Where-Object {$_ -is [string] -and $_.StartsWith('--city-qa-phase=')})
 Require ($phases.Count -eq 1) 'Exactly one actual phase flag required'
 $phase=$phases[0].Substring('--city-qa-phase='.Length)
 Require ($phase -cin @('geometry','gameplay','save')) 'Source/unknown phase cannot fill an endpoint'
 $backend=if ($before.gpu) {'gpu'} else {'headless'}
 Require ($seenSlots.Add($phase+'/'+$backend)) 'Duplicate phase/backend'
 $allowed=@('--luoyang-city-only-fresh','--fresh-start-only',('--city-qa-phase='+$phase),'--luoyang-v3-candidate','--luoyang-enclosure-v11-candidate')
 if ($before.gpu) { $allowed+='--qa-gpu-approved' }
 Require ($userArgs.Count -eq $allowed.Count -and @($userArgs | Where-Object {$_ -isnot [string] -or $_ -cnotin $allowed}).Count -eq 0 -and @($userArgs|Select-Object -Unique).Count -eq $userArgs.Count) 'Missing/mixed/historical/world/outskirts flags'
 $engineArgs=$before.actual_engine_arguments
 $separator=[array]::IndexOf($engineArgs,'--')
 Require ($separator -ge 0 -and (Equal @($engineArgs[($separator+1)..($engineArgs.Count-1)]) $userArgs)) 'Actual process user flags differ from wrapper declaration'
 Require ('--headless' -cnotin $engineArgs) 'Headless shorthand may force Dummy'
 Require ([array]::IndexOf($engineArgs,'--audio-driver') -ge 0 -and $engineArgs[[array]::IndexOf($engineArgs,'--audio-driver')+1] -ceq 'WASAPI') 'Actual process did not request WASAPI'
 if ($before.gpu) { Require ('--display-driver' -cnotin $engineArgs -and '--rendering-method' -cin $engineArgs -and $engineArgs[[array]::IndexOf($engineArgs,'--rendering-method')+1] -ceq 'gl_compatibility') 'Actual GPU process invocation missing' }
 else { Require ('--display-driver' -cin $engineArgs -and $engineArgs[[array]::IndexOf($engineArgs,'--display-driver')+1] -ceq 'headless') 'Actual headless display invocation missing' }
 $map=@{}; $identicalDuplicates=0
 Require ($before.sources -is [array] -and $before.sources.Count -gt 0) 'Actual wrapper source first guard missing'
 foreach ($source in $before.sources) { if (Add-Source $source $map) { $identicalDuplicates+=1 } }
 $inventory=if ($phase -ceq 'geometry') { $geometryInventory } else { $currentInventory }
 Check-FirstInventory $map $inventory ($phase -ceq 'geometry')
 $stdout=[IO.File]::ReadAllText($stdoutPath); $stderr=[IO.File]::ReadAllText($stderrPath)
 $evidence[$stdoutPath]=Hash $stdoutPath; $evidence[$stderrPath]=Hash $stderrPath
 $graphics=@([regex]::Matches($stdout,'(?m)^OpenGL API [^\r\n]+ - Compatibility - Using Device: [^\r\n]+'))
 if ($before.gpu) { Require ($graphics.Count -eq 1 -and $graphics[0].Value -notmatch '(?i)llvmpipe|softpipe|software|basic render') 'Actual hardware OpenGL device stdout evidence missing/unknown' }
 Require ($stdout -notmatch '(?m)^(?:ERROR:|SCRIPT ERROR:)' -and $stderr -notmatch '(?m)^(?:ERROR:|SCRIPT ERROR:)') 'Complete logs contain an actual error'
 $stderrReview=Check-FullStderr $stderr $map
 $marker=[regex]::Matches($stdout,'(?m)^CITY_ONLY_RESULT (res://build/joint_world_luoyang_20261003_qa/luoyang_enclosure_v11_city_only_[0-9_]+/result\.json) checks=([0-9]+) failures=0\s*$')
 Require ($marker.Count -eq 1) 'Exactly one actual completed CITY_ONLY_RESULT required'
 $resultRes=$marker[0].Groups[1].Value; $resultPath=Evidence-Path $resultRes
 Require ($seenResults.Add($resultPath)) 'Same result reused for multiple endpoints'
 $result=Read-Record $resultPath
 Require ($result.scope -ceq 'LUOYANG_ENCLOSURE_V11_CITY_ONLY_FRESH_ACTUAL' -and $result.complete -is [bool] -and $result.complete -and $result.failures -eq 0 -and $result.checks -eq [long]$marker[0].Groups[2].Value -and $result.mode.phase -ceq $phase -and $result.mode.candidate -is [bool] -and $result.mode.candidate -and $result.world_subject_version -eq 14 -and $result.historical_compatibility_tested -is [bool] -and -not $result.historical_compatibility_tested -and $result.actual_audio_driver -ceq 'WASAPI' -and $result.engine_sha256 -ieq $engineSHA) 'Not a complete actual current candidate city stage'
 Require ($result.checkpoint_suspension.before_any_await -eq $true -and $result.checkpoint_suspension.restored_before_exit -eq $false) 'Checkpoint protection evidence missing'
 Require ($result.source_before -is [Collections.IDictionary] -and $result.source_before.Count -gt 0 -and $result.source_after -is [Collections.IDictionary] -and $result.source_after.Count -gt 0 -and (Equal $result.source_before $result.source_after) -and $result.stage.complete -eq $true -and $result.stage.failures -eq 0) 'Internal sources/stage did not pass'
 Check-Players $before.player_files $result
 $playerChecks.Add(@{before=$before.player_files;result=@{players_before=$result.players_before;players_after=$result.players_after;active_slot_before=$result.active_slot_before;active_slot_after=$result.active_slot_after}})
 foreach ($key in $required) {
  $res='res://'+$key; $path=Source-Path $res
  Require ($map.ContainsKey($path)) "Critical source was not protected before this run: $res"
  if ($sourceSHAs.Contains($res)) { Require ($sourceSHAs[$res] -ieq $map[$path].sha256) "Critical source differs across runs: $res" }
  else { $sourceSHAs[$res]=$map[$path].sha256.ToLowerInvariant() }
  if ($fixed.ContainsKey($res)) { Require ($map[$path].sha256 -ieq $fixed[$res]) "Frozen motion/runtime source differs: $res" }
 }
 foreach ($key in $result.source_before.Keys) {
  $inner=$result.source_before[$key]
  if ($inner.exists -eq $true) {
   $path=Source-Path $key
   Require ($map.ContainsKey($path) -and $map[$path].sha256 -ieq $inner.sha256 -and $map[$path].bytes -eq $inner.bytes) "Actually consumed input lacked outer first guard: $key"
  }
 }
 $stage=$result.stage
 if ($phase -eq 'geometry') {
  Require ($stage.records.regions -is [array] -and $stage.records.regions.Count -eq 4) 'Geometry four regions missing'
  $regionIDs=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal); $routeCount=0; $objectCount=0
  foreach ($region in $stage.records.regions) { Require ($region.id -cin $ids -and $regionIDs.Add($region.id)) 'Duplicate/wrong geometry region'; $routeCount+=$region.physical_and_current_alpha.routes.Count; $objectCount+=$region.physical_and_current_alpha.objects.Count }
  Require ($routeCount -eq 20 -and $objectCount -eq 79) 'Full20 route/79 current object geometry coverage missing'
 } elseif ($phase -eq 'gameplay') {
  Require ($stage.records.npcs.Count -eq 30 -and $stage.records.interactions.Count -eq 22 -and $stage.records.portals.Count -eq 24 -and $stage.records.bounties.Count -eq 2 -and $stage.records.interaction_negatives.complete -eq $true) 'Full52 inputs/24 portals/2 rewards/negative coverage missing'
 } else {
  Require ($stage.scope -ceq 'LUOYANG_ENCLOSURE_V11_FOUR_CURRENT_SAVE_LOAD_FIELD_BIRTH' -and $stage.records.Count -eq 4 -and $stage.unknown_records.Count -eq 20 -and $stage.new_game.complete -eq $true -and $stage.world_coordinate_version -eq 14 -and $stage.city_layout_version -eq 3) 'Actual NewGame/four current city cases/20 unknown cases missing'
  Check-UnknownVersions $stage.unknown_records
  $saveIDs=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  foreach ($case in $stage.records) { Require ($case.scene_id -cin $ids -and $saveIDs.Add($case.scene_id) -and $case.passed -eq $true -and $case.births.Count -eq 2) 'Missing/duplicate/failed current save case'; foreach ($birth in $case.births) { Require ($birth.raw_full_feet_clear -eq $true -and $birth.actual_Physics_clear -eq $true -and $birth.position_matches_saved -eq $true) 'Actual save Field birth failed' } }
 }
 $row=[ordered]@{path=$resultRes;sha256=$evidence[$resultPath].ToLowerInvariant();phase=$phase;backend=$backend;actual_os_exit=0;complete_stderr_reviewed=$true;source_changes=@();player_changes=@();exact_utc_ticks_reviewed=$true;root_independent_actual_review_pending=$true}
 $rows.Add($row)
 $provenance.Add([ordered]@{wrapper_directory=$directory;before_path=$beforePath;before_sha256=$evidence[$beforePath];after_path=$afterPath;after_sha256=$evidence[$afterPath];stdout_path=$stdoutPath;stdout_sha256=$evidence[$stdoutPath];stderr_path=$stderrPath;stderr_sha256=$evidence[$stderrPath];result_path=$resultRes;result_sha256=$evidence[$resultPath];actual_graphics_stdout=@($graphics|ForEach-Object {$_.Value});known_image_warning_count=$stderrReview.warnings;concrete_backtrace_frame_count=$stderrReview.concrete_frames;unknown_stderr_lines=$stderrReview.unknown_lines;first_guard_inventory_path=$inventory.path;first_guard_inventory_sha256=$inventory.sha256;required_inventory_leaf_count=$inventory.map.Count;required_inventory_leaves_matched=$true;geometry_exact_eight_legacy_matched=($phase -ceq 'geometry');errors=0;scripts=0;unknown_warnings=0;player_exact_ticks_evidence='WRAPPER_BEFORE_15_PLUS_ACTUAL_AFTER_EMPTY_COMPARISON_AND_CURRENT_15';wrapper_after_raw_player_snapshot_available=$false;active_slot_before=$result.active_slot_before;active_slot_after=$result.active_slot_after;actual_engine_arguments=$engineArgs;user_arguments=$userArgs;source_count=$map.Count;raw_record_count=$before.sources.Count;unique_source_count=$map.Count;identical_duplicate_count=$identicalDuplicates;phase=$phase;backend=$backend})
}
Require ($seenSlots.Count -eq 6) 'All three phases on both actual backends required'
$candidateSHAs=[ordered]@{}; $layoutSHAs=[ordered]@{}
foreach ($id in $ids) {
 foreach ($kind in @('candidate','layout')) {
  $res=if ($kind -eq 'candidate') {"res://data/scenes/luoyang_enclosure_v11_candidates/$id.tres"} else {"res://data/maps/luoyang_enclosure_v11_candidates/${id}_layout.tres"}
  $path=Source-Path $res; $sha=Hash $path
  Require ($allSources.ContainsKey($path) -and $allSources[$path].sha256 -ieq $sha) 'Candidate/layout no longer bound to actual process evidence'
  if ($kind -eq 'candidate') { $candidateSHAs[$res]=$sha.ToLowerInvariant() } else { $layoutSHAs[$res]=$sha.ToLowerInvariant() }
 }
}
# Final current-source verification once per unique path, not six repeated reads
# of the same multi-GB catalog. Every run still independently supplied its map.
foreach ($path in $allSources.Keys) { $item=Get-Item -LiteralPath $path; Require ($item.Length -eq $allSources[$path].bytes -and (Hash $path) -ieq $allSources[$path].sha256) "Current source differs from actual six-run evidence: $path" }
foreach ($path in $evidence.Keys) { Require ((Hash $path) -ceq $evidence[$path]) "Completed evidence changed during draft preparation: $path" }
foreach ($check in $playerChecks) { Check-Players $check.before $check.result }
$draft=[ordered]@{schema=1;status='PENDING_ROOT_ACTUAL_SIX_AND_VISUAL_APPROVAL';art_current_images_approved=$false;root_actual_review_approved=$false;formal_approved=$false;world_subject_version=14;historical_compatibility_tested=$false;scope='LUOYANG_FOUR_CITY_ONLY_FRESH_APPROVAL_DRAFT_NOT_SIGNATURE';source_sha256=$sourceSHAs;candidate_sha256=$candidateSHAs;layout_sha256=$layoutSHAs;results=$rows.ToArray();wrapper_provenance=$provenance.ToArray();created_utc=[DateTime]::UtcNow.ToString('o');builder_path=$PSCommandPath;builder_sha256=(Hash $PSCommandPath);source_file_count=$allSources.Count;activator_in_source_sha256=$false;limitations=@('Builder does not independently approve the complete dynamic dependency closure; ROOT must independently review every slot first guard','Gameplay/save require every fixed428 finite inventory leaf; geometry requires fixed424 plus exact eight legacy leaves; no past first guard is supplemented','ROOT must independently inspect actual six complete runs and current images before manually approving','This PENDING draft cannot satisfy activator approval status or visual predicate','Wrapper after stores comparison deltas, not raw after player rows; no raw past-after snapshot is fabricated','Only current four city scope; no world15/old-save/whole-world/audio-listening approval','Activator excluded to avoid approval-SHA self-reference')}
New-Item -ItemType Directory -Path $target | Out-Null
$output=Join-Path $target 'city_only_actual_six_approval_DRAFT.json'
[IO.File]::WriteAllText($output,($draft|ConvertTo-Json -Depth 32),[Text.UTF8Encoding]::new($false))
$readback=Get-Content -LiteralPath $output -Raw|ConvertFrom-Json -AsHashtable -Depth 32
Require ($readback.status -ceq 'PENDING_ROOT_ACTUAL_SIX_AND_VISUAL_APPROVAL' -and $readback.art_current_images_approved -eq $false -and $readback.results.Count -eq 6) 'Draft readback failed'
[pscustomobject]@{path=$output;sha256=(Hash $output);status=$readback.status;art_current_images_approved=$false;formal_approved=$false}


