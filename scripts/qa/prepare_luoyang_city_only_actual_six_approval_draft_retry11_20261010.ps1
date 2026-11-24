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
 'scripts/city/luoyang_enclosure_native_depth_overlap_20261009.gd',
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
 'res://scripts/city/luoyang_enclosure_native_depth_overlap_20261009.gd'='F926CF876DA1AFE746411FF5A007A49894B191040E57E709BDBC486021B3E535'
 'res://scripts/field/field_walkable_controller.gd'='1EB104FA0E321F7D4C361996639AE882340EC029CE5AED14E17B2D6A711DD740'
 'res://scripts/city/luoyang_city3_motion_guard_20261009.gd'='AACD53E5020BC5A40353D9CF7537662C44139FA7F861E3A54C6FAF59E8BA3A93'
 'res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd'='558A3EDFAA368FF52B67FF0EAADE7505191011928C2A724897EFC727E43887F6'
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
 $inventoryPath=Evidence-Path (Join-Path $domain $relative)
 Require ((Hash $inventoryPath) -ceq $sha) 'Fixed finite source inventory SHA differs'
 $record=Read-Record $inventoryPath
 Require ($record.scope -ceq 'FRESH_CURRENT_LUOYANG_FOUR_DISTRICTS_SOURCE_INVENTORY_ONLY' -and $record.mode -ceq 'candidate' -and $record.stage -ceq 'all' -and $record.sources -is [array] -and $record.sources.Count -eq $count) 'Fixed source inventory schema/count differs'
 $map=@{}
 # Historical row digests never enter allSources. Only bounded paths are seeds.
 foreach ($row in $record.sources) {
  Require ($row -is [Collections.IDictionary] -and $row.path -is [string]) 'Invalid inventory path seed'
  $sourcePath=Source-Path $row.path
  Require (-not $map.ContainsKey($sourcePath)) 'Duplicate inventory path seed'
  $map[$sourcePath]=$true
 }
 return @{path=$inventoryPath;sha256=$sha;map=$map}
}
function Check-FirstInventory($map,$reference,[bool]$geometry) {
 foreach ($path in $reference.map.Keys) {
  Require ($map.ContainsKey($path) -and (Hash $path) -ieq $map[$path].sha256 -and (Get-Item -LiteralPath $path).Length -eq $map[$path].bytes) "Path seed missing/currently differs from this run's fresh first guard: $path"
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

# This is code-bound assertion + actual-result INFERENCE, not captured Confirm UI.
$warningPins=@{
 'res://data/maps/luoyang_v3_legacy/ch4_s2_canal_docks_scene.tres'='81850AFD0877BBA70E2ED0786FE4E81570FAEE8E06E827561349988F9C4D41A5'
 'res://data/dialogs/ch4_canal_battle.tres'='E36B0EFDA52A7E2A62B85916006F981321F37F4C0A207C0E36B399A826014DDA'
 'res://data/dialogs/ch4_canal_result.tres'='ADFB61204A2AE3A4B21FF3BF4C3B553E6BE762F3F9D66B522E32B8D499D0BD93'
 'res://data/dialogs/ch4_hanjia_blade_offer.tres'='30EBA1843F543E152E9269203A66B4507087D4045D745A30F0C186A88C51B5FA'
 'res://data/scenes/ch4_s4_ancient_temple.tres'='1570A4D9CFCB0508A12BFA639052DB8AEC11AB25634A3F5C606D19CBE2223730'
 'res://scripts/battle/battle_controller.gd'='FFD86F420BB0E6E9B8A3C11210B06F42D760AD3C253720472605616DCD591667'
 'res://data/enemies/luoyang_thug.tres'='B9DCF55F1DE37F928755163CBDF1F93BED12D1487913819E434F518E99DA2F2B'
 'res://data/items/blood_activator.tres'='C62DEC51709E695E98EA512236C924FF5DE6DDA4C103B106B0DF117D81D7CDD1'
 'res://scripts/autoload/inventory.gd'='727A2742AFF63569F2A4D91FF5B69AC28191D5E146F600084E29E1F9DD76F276'
 'res://scripts/autoload/quest_manager.gd'='C6EBD067F9B2E0660AA105E90C6EC7C777DA895C19FCD701E438A2811405A03C'
 'res://scripts/autoload/investigation_state.gd'='99E2C0ADFE71929232374A132FEC6A8FF4CA088225C1FB8BA86FA9A3F7604E3D'
 'res://data/quests/q_ch4_side_07_hanjia_blade.tres'='4FC77C40CA955BDD68C1BFC1CE10302F440273880304CA1B340DD60A27615935'
 'res://data/dialogs/ch8_aftermath_luoyang.tres'='D616E9C633B95B796474C8D5C1997132E73F34ED3698EB8586BF5BCBD86784D2'
 'res://data/npcs/npc_catalog.tres'='9AEE67DB9C9A4AA7F7FE5242C6C65EE80B6F092998974602BAF9100DD1D4DF34'
 'res://scripts/field/npc_node.gd'='9DA0E3D61185C45568071F40A4F2DE4F1F1287A105FD66F4C5A9E162C3AF3B72'
 'res://scripts/ui/formal_confirm_dialog.gd'='EC2037B90A384139E09FFCCCAC91AD9A5AFBE2D9C078ACF1BFFF6B1F58C98202'
 'res://scripts/autoload/dialog_player.gd'='F09A6BBB35B1456110B02D300E09D2D4DD7237C02121A35375AB536300D80C49'
 'res://scripts/ui/dialog_box.gd'='02C46CBF1519D6A2B8A95F1FFC8F0193E197A6F710611A89B86EEE975F635C7C'
 'res://tests/helpers/joint_v15_v8_city_authored_two_choice_phase.gd'='97A8D255A7148074FF5A2FBB334A675C92697B992B12565B0D14FB52D859B126'
 'res://tests/helpers/joint_v15_v8_city_authored_transition_lifecycle_phase.gd'='542483133D1DFD79422AC99DFF5C79EE4CD3BAEA6A62001439F016C6055AAF72'
 'res://tests/helpers/v15_input_driver.gd'='A3C59FDE8D9F55D71919276286DC720E177EF3DC046D224204868A24881DE5D7'
 'res://tests/helpers/joint_v15_wall_v5_city_physical_alpha_probe.gd'='40B42C901EF05AC1971CCAAE9BA049B60CFE439BAEA8778F796F978C4BD54450'
}
$sparSpecs=@(
 @('ch4_s1_luoyang_yamen','spar_yamen_patrol','spar:yamen_patrol:luoyang_patrol:府衙巡捕:30:7'),
 @('ch4_s1_luoyang_yamen','spar_yamen_captain','spar:yamen_captain:boss_luoyang_captain:府衙都头:42:10'),
 @('ch4_s3_luoyang_market','spar_luoyang_shen_guard','spar:luoyang_shen_guard:ch2_tournament_guard:沈家护院总管:18:4'),
 @('ch4_s3_luoyang_market','spar_luoyang_examiner','spar:luoyang_examiner:wulin_examiner:大会考校官:24:6'),
 @('ch4_s3_luoyang_market','spar_luoyang_blademaster','spar:luoyang_blademaster:wandering_blademaster:流浪刀客:60:15'),
 @('ch4_s3_luoyang_market','spar_luoyang_patrol','spar:luoyang_patrol:luoyang_patrol:洛阳巡捕:32:8')
)

function Resolve-DocksWarningBinding($actor) {
 Require ($actor -is [string]) 'Typed Docks actor required'
 if ($actor -ceq 'canal_endangered_porter') { return @{scene='ch4_s2_canal_docks';action='';dialog='ch4_canal_battle';target='ch4_s2_canal_docks';nodes=@('start','b');terminal='battle_group:luoyang_thug,luoyang_thug'} }
 if ($actor -ceq 'canal_saved_porter') { return @{scene='ch4_s2_canal_docks';action='';dialog='ch4_canal_result';target='ch4_s4_ancient_temple';nodes=@('start','b','rescue_first','finish');terminal='scene:ch4_s4_ancient_temple'} }
 if ($actor -ceq 'canal_old_soldier') { return @{scene='ch4_s2_canal_docks';action='';dialog='ch4_hanjia_blade_offer';target='ch4_s2_canal_docks';nodes=@('start','accept');terminal='end'} }
 throw 'Unknown Docks warning actor'
}
function Check-DocksArrival($arrival,$map) {
 Check-Bools $arrival @('complete','live_field','live_player','bound_field_is_current') @('loading_active','outcome_injected','route_injected')
 $path='res://data/scenes/ch4_s4_ancient_temple.tres'; Bound-Leaf $path $map
 Require ($arrival.actual_scene_id -is [string] -and $arrival.actual_scene_id -ceq 'ch4_s4_ancient_temple' -and $arrival.expected_scene_id -is [string] -and $arrival.expected_scene_id -ceq 'ch4_s4_ancient_temple' -and $arrival.actual_definition_path -is [string] -and $arrival.actual_definition_path -ceq $path -and $arrival.actual_definition_sha256 -is [string] -and $arrival.actual_definition_sha256 -ieq $warningPins[$path] -and $arrival.current_scene_path -is [string] -and $arrival.current_scene_path -ceq 'res://scenes/field_walkable.tscn' -and $arrival.player_script -is [string] -and $arrival.player_script -ceq 'res://scripts/field/player.gd' -and $arrival.current_scene_instance_id -is [long] -and $arrival.current_scene_instance_id -ne 0 -and $arrival.player_instance_id -is [long] -and $arrival.player_instance_id -ne 0) 'Exact original Temple actual arrival identity/source differs'
 Require (Equal $arrival.actual_player_feet_px @(1168.75,743.75)) 'Original approved Temple arrival feet differ'
}
function Check-DocksEvidence($r,[string]$author,$map) {
 Require ($r -is [Collections.IDictionary] -and $r.source_id -is [string]) 'Actual typed Docks case required'
 $spec=Resolve-DocksWarningBinding $r.source_id
 Require ($r.source_scene_id -is [string] -and $r.source_scene_id -ceq $spec.scene -and $r.mode -is [string] -and $r.mode -cin @('space','mouse') -and $r.action -is [string] -and $r.action -ceq '' -and $r.dialog_id -is [string] -and $r.dialog_id -ceq $spec.dialog) 'Wrong Docks scene/action/dialog/mode'
 Require ($author.Contains('"npc_id":"'+$r.source_id+'"') -and $author.Contains('"dialog_id":"'+$spec.dialog+'"') -and -not $author.Contains('"conversation_base_facing"') -and -not $author.Contains('"interaction_action"') -and -not $author.Contains('"action"')) 'Exact ordinary Docks original author/default right differs'
 $legacy='res://data/maps/luoyang_v3_legacy/ch4_s2_canal_docks_scene.tres'; Bound-Leaf $legacy $map
 $authors=@([regex]::Matches([IO.File]::ReadAllText((Source-Path $legacy)),'\{[^\r\n{}]*"npc_id"\s*:\s*"'+[regex]::Escape($r.source_id)+'"[^\r\n{}]*\}'))
 Require ($authors.Count -eq 1 -and $authors[0].Value -ceq $author) 'Docks author is not exact current source'
 $path='res://data/dialogs/'+$spec.dialog+'.tres'; Bound-Leaf $path $map
 Require ($warningPins.ContainsKey($path) -and $map[(Source-Path $path)].sha256 -ieq $warningPins[$path] -and $r.dialog_nodes -is [array] -and $r.dialog_nodes.Count -eq $spec.nodes.Count) 'Docks exact original dialogue/source/node count differs'
 for ($n=0;$n -lt $spec.nodes.Count;$n++) {
  $node=$r.dialog_nodes[$n]
  Require ($node -is [Collections.IDictionary] -and $node.id -is [string] -and $node.id -ceq ($spec.dialog+'/'+$spec.nodes[$n]) -and $node.source_path -is [string] -and $node.source_path -ceq $path -and $node.source_sha256 -is [string] -and $node.source_sha256 -ieq $warningPins[$path]) 'Docks dialogue node order/type/source differs'
 }
 $terminal=$r.battle_lifecycle
 Check-Bools $terminal @('terminal_source_valid','normal_ui_only','current_scene_live') @('outcome_injected')
 Require ($terminal.terminal_source_path -is [string] -and $terminal.terminal_source_path -ceq $path -and $terminal.terminal_source_sha256 -is [string] -and $terminal.terminal_source_sha256 -ieq $warningPins[$path] -and $terminal.terminal_identity -is [string] -and $terminal.terminal_identity -ceq ($spec.dialog+'/'+$spec.nodes[-1]) -and $terminal.terminal_on_end -is [string] -and $terminal.terminal_on_end -ceq $spec.terminal -and $terminal.battle_wait_budget_msec -is [long] -and $terminal.battle_wait_budget_msec -eq 30000 -and $terminal.battle_ui_budget_msec -is [long] -and $terminal.battle_ui_budget_msec -eq 180000) 'Docks exact authored terminal/budgets differ'
 $receipt=$r.normal_transition_receipt
 Check-Bools $r @() @('dry_run'); Check-Bools $r.approach @('ok') @()
 Check-Bools $receipt @('complete','live_field','live_player','bound_field_is_current') @('loading_active','outcome_injected','route_injected')
 foreach ($key in @('source_scene_id','source_id','mode','original_action')) {
  $expected=if ($key -ceq 'source_scene_id') {$spec.scene} elseif ($key -ceq 'source_id') {$r.source_id} elseif ($key -ceq 'mode') {$r.mode} else {''}
  Require ($receipt[$key] -is [string] -and $receipt[$key] -ceq $expected) 'Docks receipt exact source/original input identity differs'
 }
 Require ($receipt.actual_scene_id -is [string] -and $receipt.actual_scene_id -ceq $spec.target -and $receipt.expected_scene_id -is [string] -and $receipt.expected_scene_id -ceq $spec.target -and (Equal $receipt.battle_entry $terminal) -and (Equal $receipt.battle_effects $r.effects)) 'Docks exact approved terminal target/effects receipt differs'
 Require ($r.before -is [Collections.IDictionary] -and $r.after -is [Collections.IDictionary] -and $r.before.flags -is [Collections.IDictionary] -and $r.after.flags -is [Collections.IDictionary] -and $r.effects -is [Collections.IDictionary]) 'Docks actual state/effects missing'
 foreach ($side in @('before','after')) {
  foreach ($key in @('quests','investigation')) {Require ($r[$side].Contains($key) -and $r[$side][$key] -is [Collections.IDictionary]) ('Docks required typed state '+$side+'/'+$key)}
 }
 $flags=[ordered]@{}; foreach ($key in $r.before.flags.Keys) {$flags[$key]=$r.before.flags[$key]}
 $changedFlags=if ($r.source_id -ceq 'canal_endangered_porter') {@('defeated_luoyang_thug')} elseif ($r.source_id -ceq 'canal_saved_porter') {@('ch4_canal_witness_saved','ch4_canal_investigation_complete')} else {@('hanjia_blade_search_started')}
 foreach ($flag in $changedFlags) {
  Require (-not $flags.Contains($flag) -or ($flags[$flag] -is [bool] -and -not $flags[$flag])) 'Docks completion flag already true or wrongtyped'
  Check-Bools $r.after.flags @($flag) @(); $flags[$flag]=$true
 }
 Require (Equal $flags $r.after.flags) 'Unapproved Docks flag mutation'
 foreach ($key in @('reputation','bounty','sparring')) { Require ($r.before.Contains($key) -and $r.after.Contains($key) -and (Equal $r.before[$key] $r.after[$key])) ('Unapproved Docks state '+$key) }
 if ($r.source_id -ceq 'canal_endangered_porter') {
  foreach ($source in @('res://scripts/battle/battle_controller.gd','res://data/enemies/luoyang_thug.tres','res://scripts/autoload/inventory.gd')) {Bound-Leaf $source $map}
  Check-Bools $terminal @('authored_terminal_requires_battle') @()
  $e=$r.effects; Check-Bools $e @('entered','returned','won') @()
  Require ($e.scope -is [string] -and $e.scope -ceq 'EXISTING_NORMAL_ACTION_BATTLE_UI' -and $e.outcomes -is [array] -and $e.outcomes.Count -eq 1 -and $e.commands -is [array] -and $e.commands.Count -gt 0) 'Docks normal actual battle incomplete'
  Check-Bools $e.outcomes[0] @('won') @('fled')
  $attacks=0
  foreach ($command in $e.commands) {
   Require ($command -is [Collections.IDictionary] -and $command.kind -is [string] -and $command.kind -cin @('normal_attack','normal_target')) 'Unknown Docks battle command'
   Check-Bools $command @('pressed') @()
   # Read the original JSON fields at full depth: the driver records numeric
   # Arrays (Vector2 2/2, Transform2D 6), never formatted display strings.
   Require ($command.pointer -is [Collections.IDictionary]) 'Docks normal battle pointer missing'
   foreach ($key in @('logical','physical','final_transform')) {
    $value=$command.pointer[$key]
    Require ($value -is [array] -and $value.Count -eq $(if ($key -ceq 'final_transform') {6} else {2})) 'Docks original numeric pointer array/type/count invalid'
    foreach ($number in $value) {Require (($number -is [long] -or $number -is [double]) -and [double]::IsFinite([double]$number)) 'Docks pointer component type/nonfinite'}
   }
   if ($command.kind -ceq 'normal_attack') {Check-Bools $command @('accepted') @(); $attacks++}
  }
  Require ($attacks -gt 0) 'No normal actual battle attack'
  $payload=$e.original_payload; $result=$e.actual_result_payload
  Require ($payload -is [Collections.IDictionary] -and $payload.enemy_id -is [string] -and $payload.enemy_id -ceq 'luoyang_thug' -and (Equal $payload.enemy_ids @('luoyang_thug','luoyang_thug')) -and $payload.return_scene -is [string] -and $payload.return_scene -ceq $spec.scene -and $payload.return_world_map_version -is [long] -and $payload.return_world_map_version -eq 14 -and $payload.return_local_layout_version -is [long] -and $payload.return_local_layout_version -eq 3) 'Exact original two-thug battle/current return payload differs'
  Require ($result -is [Collections.IDictionary] -and $result.return_scene -is [string] -and $result.return_scene -ceq $spec.scene -and $result.return_world_map_version -is [long] -and $result.return_world_map_version -eq 14 -and $result.return_local_layout_version -is [long] -and $result.return_local_layout_version -eq 3 -and $result.exp -is [long] -and $result.exp -eq 124 -and $result.gold -is [long] -and $result.gold -ge 23 -and $result.gold -le 62 -and $r.before.gold -is [long] -and $r.after.gold -is [long] -and $r.after.gold-$r.before.gold -eq $result.gold -and $r.before.training -is [long] -and $r.after.training -is [long] -and $r.after.training-$r.before.training -eq 124) 'Bound two-thug reward model/actual reward delta differs'
  Require ((Equal $e.actual_return_foot_px $r.pre_action_feet_px) -and (Equal $receipt.actual_player_feet_px $e.actual_return_foot_px)) 'Exact original normal battle return feet differ'
  # The original two enemies can each award one stackable blood_activator. The
  # fixture has none beforehand; preserve all original slots/equipment and allow
  # only this bounded source-declared RNG result, not arbitrary inventory change.
  Bound-Leaf 'res://data/items/blood_activator.tres' $map
  $ib=$r.before.inventory; $ia=$r.after.inventory
  Require ($ib -is [Collections.IDictionary] -and $ia -is [Collections.IDictionary] -and $ib.slots -is [array] -and $ia.slots -is [array] -and $ib.equipped_by_character -is [Collections.IDictionary]) 'Actual two-thug inventory missing'
  foreach ($slot in $ib.slots) {Require ($slot -is [Collections.IDictionary] -and $slot.item_id -is [string] -and $slot.item_id -cne 'blood_activator') 'Original reward fixture already has blood_activator or invalid slot'}
  Require ($ia.slots.Count -eq $ib.slots.Count -or $ia.slots.Count -eq $ib.slots.Count+1) 'Unexpected battle inventory slot count'
  $expectedInventory=[ordered]@{}; foreach ($key in $ib.Keys) {$expectedInventory[$key]=$ib[$key]}
  $equipment=[ordered]@{}; foreach ($key in $ib.equipped_by_character.Keys) {$equipment[$key]=$ib.equipped_by_character[$key]}
  Require (-not $equipment.Contains('luoyang_thug') -or ($equipment['luoyang_thug'] -is [Collections.IDictionary] -and $equipment['luoyang_thug'].Count -eq 0)) 'Original thug equipment is not empty'
  $equipment['luoyang_thug']=@{}; $expectedInventory['equipped_by_character']=$equipment
  $slots=@($ib.slots)
  if ($ia.slots.Count -eq $ib.slots.Count+1) {
   $drop=$ia.slots[-1]
   Require ($drop -is [Collections.IDictionary] -and $drop['count'] -is [long] -and $drop['count'] -ge 1 -and $drop['count'] -le 2 -and (Equal $drop @{item_id='blood_activator';instance_id='';count=$drop['count']})) 'Unexpected source-declared random battle item/type/count'
   $slots+=@($drop)
  }
  $expectedInventory['slots']=$slots
  Require (Equal $expectedInventory $ia) 'Unapproved battle inventory/equipment mutation'
  foreach ($key in @('quests','investigation')) {Require (Equal $r.before[$key] $r.after[$key]) ('Unapproved battle state '+$key)}
 } else {
  Check-Bools $terminal @() @('authored_terminal_requires_battle','actual_battle_ui','actual_battle_loading')
  foreach ($key in @('gold','training','inventory')) {Require ($r.before.Contains($key) -and $r.after.Contains($key) -and (Equal $r.before[$key] $r.after[$key])) ('Unapproved nonbattle state '+$key)}
  if ($r.source_id -ceq 'canal_saved_porter') {
   Bound-Leaf 'res://scripts/autoload/investigation_state.gd' $map
   Require ($r.effects.Count -eq 1 -and $r.effects.Contains('scene_transition') -and (Equal $r.effects.scene_transition $r.scene_lifecycle) -and (Equal $receipt.scene_arrival $r.scene_lifecycle)) 'Saved porter original scene lifecycle/effects differ'
   $life=$r.scene_lifecycle
   Check-Bools $life @('complete','source_bytes_exact_before','source_bytes_exact_after') @('fixture_reset_during_wait','go_field_called_by_observer','production_timer_cancelled')
   Require ($life.scope -is [string] -and $life.scope -ceq 'ACTUAL_SOURCE_AUTHORED_SCENE_ARRIVAL_NOT_ROUTER_SHORTCUT_OR_FULL' -and $life.target_scene_id -is [string] -and $life.target_scene_id -ceq $spec.target -and (Equal $life.authored_terminal $terminal) -and $life.wait_budget_msec -is [long] -and $life.wait_budget_msec -eq 30000 -and $life.on_enter_ui_budget_msec -is [long] -and $life.on_enter_ui_budget_msec -eq 45000 -and $life.on_enter_dialog_nodes -is [array] -and $life.on_enter_dialog_nodes.Count -eq 0) 'Original source-authored Temple lifecycle/budgets differ'
   foreach ($arrival in @($receipt,$life.actual_arrival,$life.actual_arrival_before_on_enter_ui)) {Check-DocksArrival $arrival $map}
   Require (Equal $r.before.quests $r.after.quests) 'No actual source-quest completion in this fixture'
   # Frozen original rescue_first branch, not a claim of all dialogue outcomes.
   $empty=@{bond_events=@{};city_outcomes=@{};companion_trust=@{};evidence=@{};faction_trust=@{};method_flags=@{};testimonies=@{}}
   $expected=@{bond_events=@{zhao_siying=@('ch4_saved_witness_together')};city_outcomes=@{luoyang=@{canal_witness_alive=$true}};companion_trust=@{zhao_siying=[long]8};evidence=@{ev_ch4_canal_original_manifest=@{disclosed=$false;source='start';verified=$true;verifier='失踪脚夫'}};faction_trust=@{};method_flags=@{ch4_rescue_witness_first=$true};testimonies=@{ts_ch4_canal_witness_night_transfer=@{credibility=[long]100;verified=$true;verifier='失踪脚夫'}}}
   Require ((Equal $r.before.investigation $empty) -and (Equal $r.after.investigation $expected)) 'Exact source-authored rescue-first investigation differs'
  } else {
   Bound-Leaf 'res://scripts/autoload/quest_manager.gd' $map; Bound-Leaf 'res://data/quests/q_ch4_side_07_hanjia_blade.tres' $map
   Require ($r.effects.Count -eq 0 -and (Equal $r.before.investigation $r.after.investigation)) 'Old soldier nonbattle effects/investigation differ'
   Require ($r.before.quests -is [Collections.IDictionary] -and $r.after.quests -is [Collections.IDictionary] -and -not $r.before.quests.Contains('q_ch4_side_07_hanjia_blade')) 'Old soldier original quest already accepted'
   $quests=[ordered]@{}; foreach ($key in $r.before.quests.Keys) {$quests[$key]=$r.before.quests[$key]}
   $quests['__tracked_side_quest']='q_ch4_side_07_hanjia_blade'; $quests['q_ch4_side_07_hanjia_blade']=[long]1
   Require (Equal $quests $r.after.quests) 'Old soldier exact accept-and-track quest differs'
   Require (Equal $receipt.actual_player_feet_px $r.pre_action_feet_px) 'Old soldier original local Field feet changed'
  }
 }
}

function Match-NPCWarningHeader($line) {
 Require ($line -is [string]) 'NPC warning line must be a string'
 return [regex]::Match($line,"^WARNING: \[NPCNode\] (luoyang_gate_sergeant|spar_yamen_patrol|spar_yamen_captain|spar_luoyang_shen_guard|spar_luoyang_examiner|spar_luoyang_blademaster|spar_luoyang_patrol|ch8_luoyang_final_clerk|canal_endangered_porter|canal_saved_porter|canal_old_soldier) has no authored 'right' conversation facing; using mirror fallback$")
}
function Resolve-NPCWarningBinding($actor) {
 Require ($actor -is [string]) 'NPC warning actor must be a string'
 if ($actor -ceq 'luoyang_gate_sergeant') { return @{scene='ch4_s0_luoyang_gate';action=''} }
 if ($actor -ceq 'ch8_luoyang_final_clerk') { return @{scene='ch4_s1_luoyang_yamen';action='';dialog='ch8_aftermath_luoyang'} }
 if ($actor -cin @('canal_endangered_porter','canal_saved_porter','canal_old_soldier')) {return (Resolve-DocksWarningBinding $actor)}
 Require ($actor -cin @('spar_yamen_patrol','spar_yamen_captain','spar_luoyang_shen_guard','spar_luoyang_examiner','spar_luoyang_blademaster','spar_luoyang_patrol')) 'Unknown NPC warning actor'
 Require ($sparSpecs -is [array] -and $sparSpecs.Count -eq 6) 'Fixed six spar specifications required'
 foreach ($spec in $sparSpecs) { Require ($spec -is [array] -and $spec.Count -eq 3 -and $spec[0] -is [string] -and $spec[1] -is [string] -and $spec[2] -is [string]) 'Malformed typed spar specification' }
 $matches=@($sparSpecs|Where-Object {$_[1] -ceq $actor})
 Require ($matches.Count -eq 1) 'Missing/duplicate fixed NPC warning binding'
 return @{scene=$matches[0][0];action=$matches[0][2]}
}
function Bound-Leaf([string]$res,$map) {
 $path=Source-Path $res
 Require ($map.ContainsKey($path) -and (Hash $path) -ieq $map[$path].sha256 -and (Get-Item -LiteralPath $path).Length -eq $map[$path].bytes) "Known warning input absent/changed from actual firstguard: $res"
 if ($warningPins.ContainsKey($res)) { Require ($map[$path].sha256 -ieq $warningPins[$res]) "Known warning source pin differs: $res" }
 if ($fixed.ContainsKey($res)) { Require ($map[$path].sha256 -ieq $fixed[$res]) "Known warning runtime pin differs: $res" }
}
function Check-Bools($record,[string[]]$trueKeys,[string[]]$falseKeys) {
 Require ($record -is [Collections.IDictionary]) 'Known receipt must be a dictionary'
 foreach ($key in $trueKeys) { Require ($record[$key] -is [bool] -and $record[$key]) "Required typed true receipt: $key" }
 foreach ($key in $falseKeys) { Require ($record[$key] -is [bool] -and -not $record[$key]) "Required typed false receipt: $key" }
}
function Check-ClerkEvidence($r,[string]$author,$map) {
 Require ($r -is [Collections.IDictionary] -and $r.source_scene_id -is [string] -and $r.source_scene_id -ceq 'ch4_s1_luoyang_yamen' -and $r.source_id -is [string] -and $r.source_id -ceq 'ch8_luoyang_final_clerk' -and $r.mode -is [string] -and $r.mode -cin @('space','mouse') -and $r.action -is [string] -and $r.action -ceq '' -and $r.dialog_id -is [string] -and $r.dialog_id -ceq 'ch8_aftermath_luoyang') 'Wrong typed concrete clerk scene/action/dialog'
 Require ($author.Contains('"npc_id":"ch8_luoyang_final_clerk"') -and $author.Contains('"dialog_id":"ch8_aftermath_luoyang"') -and -not $author.Contains('"interaction_action"') -and -not $author.Contains('"action"') -and -not $author.Contains('"conversation_base_facing"')) 'Clerk original author must use empty action and pinned default right facing'
 # Default right is bound by the already-pinned NPC source, not invented left.
 $path='res://data/dialogs/ch8_aftermath_luoyang.tres'
 $sha='D616E9C633B95B796474C8D5C1997132E73F34ED3698EB8586BF5BCBD86784D2'
 Bound-Leaf $path $map
 Require ($r.dialog_nodes -is [array] -and $r.dialog_nodes.Count -eq 3) 'Exact three actual clerk dialogue nodes required'
 $ids=@('ch8_aftermath_luoyang/start','ch8_aftermath_luoyang/trial','ch8_aftermath_luoyang/end')
 for ($i=0;$i -lt 3;$i++) {
  $node=$r.dialog_nodes[$i]
  Require ($node -is [Collections.IDictionary] -and $node.id -is [string] -and $node.id -ceq $ids[$i] -and $node.source_path -is [string] -and $node.source_path -ceq $path -and $node.source_sha256 -is [string] -and $node.source_sha256 -ieq $sha) 'Clerk actual node identity/order/source bytes differ'
 }
 Check-Bools $r.dialog_nodes[2].node_flags @('ch8_aftermath_luoyang_done') @()
 $terminal=$r.battle_lifecycle
 Check-Bools $terminal @('terminal_source_valid','normal_ui_only','current_scene_live') @('authored_terminal_requires_battle','actual_battle_ui','actual_battle_loading','loading_active','outcome_injected')
 Require ($terminal.terminal_source_path -is [string] -and $terminal.terminal_source_path -ceq $path -and $terminal.terminal_source_sha256 -is [string] -and $terminal.terminal_source_sha256 -ieq $sha -and $terminal.terminal_identity -is [string] -and $terminal.terminal_identity -ceq $ids[2] -and $terminal.terminal_on_end -is [string] -and $terminal.terminal_on_end -ceq 'resolve_ch8_relationship_if_ready') 'Clerk exact nonbattle terminal source differs'
 Require ($r.before -is [Collections.IDictionary] -and $r.after -is [Collections.IDictionary] -and $r.before.flags -is [Collections.IDictionary] -and $r.after.flags -is [Collections.IDictionary]) 'Clerk actual before/after flags missing'
 Check-Bools $r.before.flags @() @('ch8_aftermath_luoyang_done')
 Check-Bools $r.after.flags @('ch8_aftermath_luoyang_done') @()
 $flags=[ordered]@{}; foreach ($key in $r.before.flags.Keys) { $flags[$key]=$r.before.flags[$key] }; $flags['ch8_aftermath_luoyang_done']=$true
 Require (Equal $flags $r.after.flags) 'Unapproved clerk flag mutation'
 foreach ($key in @('training','gold','reputation','inventory','quests','bounty','sparring')) { Require ($r.before.Contains($key) -and $r.after.Contains($key) -and (Equal $r.before[$key] $r.after[$key])) "Unapproved clerk state mutation: $key" }
 Require ($r.effects -is [Collections.IDictionary] -and $r.effects.Count -eq 0) 'Clerk original nonbattle dialogue must have empty typed effects'
 $before=$r.before.investigation; $after=$r.after.investigation
 Require ($before -is [Collections.IDictionary] -and $after -is [Collections.IDictionary] -and $before.city_outcomes -is [Collections.IDictionary] -and $after.city_outcomes -is [Collections.IDictionary]) 'Clerk actual city outcomes missing'
 $expected=[ordered]@{}; foreach ($key in $before.Keys) { $expected[$key]=$before[$key] }
 $cities=[ordered]@{}; foreach ($key in $before.city_outcomes.Keys) { $cities[$key]=$before.city_outcomes[$key] }
 $luoyang=[ordered]@{}
 if ($before.city_outcomes.Contains('luoyang')) { Require ($before.city_outcomes.luoyang -is [Collections.IDictionary]) 'Malformed original Luoyang outcomes'; foreach ($key in $before.city_outcomes.luoyang.Keys) { $luoyang[$key]=$before.city_outcomes.luoyang[$key] } }
 foreach ($key in @('ch8_joint_trial_active','ch8_single_party_custody_forbidden')) {
  Require (-not $luoyang.Contains($key) -or ($luoyang[$key] -is [bool] -and -not $luoyang[$key])) 'Clerk city outcome already true/wrongtyped before original input'
  Require ($after.city_outcomes.luoyang -is [Collections.IDictionary] -and $after.city_outcomes.luoyang[$key] -is [bool] -and $after.city_outcomes.luoyang[$key]) 'Clerk city outcome not actually true after input'
  $luoyang[$key]=$true
 }
 $cities['luoyang']=$luoyang; $expected['city_outcomes']=$cities
 Require (Equal $expected $after) 'Unapproved clerk investigation mutation'
}
function Known-Case($stage,[string]$scene,[string]$id,[string]$mode,[string]$action,$map) {
 $records=$stage.records.npcs
 Require ($records -is [array] -and $mode -cin @('space','mouse')) 'Invalid warning records/mode'
 foreach ($row in $records) { Require ($row -is [Collections.IDictionary] -and $row.source_scene_id -is [string] -and $row.source_id -is [string] -and $row.mode -is [string]) 'Typed NPC case identity required' }
 $matches=@($records|Where-Object {$_.source_scene_id -ceq $scene -and $_.source_id -ceq $id -and $_.mode -ceq $mode})
 Require ($matches.Count -eq 1) 'Missing/duplicate concrete warning case'
 $r=$matches[0]; $receipt=$r.normal_transition_receipt
 $warningTarget=$scene
 if ($id -cin @('canal_endangered_porter','canal_saved_porter','canal_old_soldier')) { $warningTarget=(Resolve-DocksWarningBinding $id).target }
 Check-Bools $r @() @('dry_run'); Check-Bools $r.approach @('ok') @()
 Check-Bools $receipt @('complete','live_field','live_player','bound_field_is_current') @('loading_active','outcome_injected','route_injected')
 Require ($r.dry_run -is [bool] -and -not $r.dry_run -and $r.action -ceq $action -and $r.approach.ok -eq $true) 'Warning case input/action/approach failed'
 Require ($receipt.complete -eq $true -and $receipt.source_scene_id -ceq $scene -and $receipt.source_id -ceq $id -and $receipt.mode -ceq $mode -and $receipt.original_action -ceq $action -and $receipt.actual_scene_id -ceq $warningTarget -and $receipt.expected_scene_id -ceq $warningTarget -and $receipt.live_field -eq $true -and $receipt.live_player -eq $true -and $receipt.bound_field_is_current -eq $true -and $receipt.loading_active -eq $false -and $receipt.outcome_injected -eq $false -and $receipt.route_injected -eq $false -and $receipt.player_script -ceq 'res://scripts/field/player.gd') 'Concrete normal transition receipt failed'
 Require (@($r.events|Where-Object {$_.kind -ceq 'npc_talked_to' -and $_.id -ceq $id}).Count -eq 1 -and $r.dialog_nodes -is [array] -and $r.dialog_nodes.Count -gt 0) 'Actual NPC event/dialogue missing'
 if ($mode -ceq 'space') { Require ($r.actual_input.mode -ceq 'space') 'Not original Space input' }
 else {
  $warningInput=$r.actual_input; $identity=$warningInput.source_identity_before_input
  Check-Bools $warningInput @('ok','source_sprite_alive_after_input') @(); Check-Bools $identity @('alpha_sampled_before_input') @()
  Require ($warningInput.ok -eq $true -and $warningInput.source_sprite_alive_after_input -eq $true -and $warningInput.logical -is [array] -and $warningInput.logical.Count -eq 2 -and $warningInput.physical -is [array] -and $warningInput.physical.Count -eq 2 -and $identity.alpha_sampled_before_input -eq $true) 'Original NPC normal pointer/source identity missing'
  Bound-Leaf $identity.texture_path $map
  Require ($identity.texture_source_sha256 -ieq $map[(Source-Path $identity.texture_path)].sha256) 'NPC pointer texture SHA differs'
 }
 foreach ($dialog in $r.dialog_nodes) {
  $ui=$dialog.actual_dialog_ui_identity
  Check-Bools $ui @('exact_root_and_control_identity','control_visible_in_tree') @()
  Require ($ui.exact_root_and_control_identity -eq $true -and $ui.control_visible_in_tree -eq $true -and $ui.control_path -ceq '/root/DialogPlayer/DialogLayer/DialogBox' -and $ui.control_script -ceq 'res://scripts/ui/dialog_box.gd' -and $ui.dialog_player_path -ceq '/root/DialogPlayer' -and $ui.root_scene_path -ceq 'res://scenes/ui/dialog_box.tscn') 'Actual dialogue UI missing'
  Bound-Leaf $ui.control_script $map; Bound-Leaf $ui.root_scene_path $map
 }
 $legacy='res://data/maps/luoyang_v3_legacy/'+$scene+'_scene.tres'; Bound-Leaf $legacy $map
 $text=[IO.File]::ReadAllText((Source-Path $legacy))
 $author=@([regex]::Matches($text,'\{[^\r\n{}]*"npc_id"\s*:\s*"'+[regex]::Escape($id)+'"[^\r\n{}]*\}'))
 Require ($author.Count -eq 1) 'Original warning actor missing/nonunique'
 $sprite=[regex]::Match($author[0].Value,'"sprite_path"\s*:\s*"(res://[^"]+\.png)"'); Require $sprite.Success 'Original NPC PNG absent'
 Bound-Leaf $sprite.Groups[1].Value $map
 $binding=$stage.current_author_bindings[$scene]
 Require ($binding -is [Collections.IDictionary] -and $binding.path -is [string] -and $binding.base_path -is [string]) 'Actual current author/base binding missing'
 Bound-Leaf $binding.path $map; Bound-Leaf $binding.base_path $map
 Require ($binding.sha256 -ieq $map[(Source-Path $binding.path)].sha256 -and $binding.base_sha256 -ieq $map[(Source-Path $binding.base_path)].sha256) 'Actual author/catalog binding differs'
 # NPC profiles live in NPC_CATALOG, not the city's native object asset catalog.
 # This exact frozen catalog has no override for these concrete source IDs.
 Bound-Leaf 'res://data/npcs/npc_catalog.tres' $map
 Bound-Leaf 'res://scenes/npc_node.tscn' $map
 $catalogText=[IO.File]::ReadAllText((Source-Path 'res://data/npcs/npc_catalog.tres'))
 Require (-not [regex]::IsMatch($catalogText,'(?m)^npc_id\s*=\s*&?"'+[regex]::Escape($id)+'"\s*$')) 'NPC catalog override invalidates original PNG warning inference'

 $import=$sprite.Groups[1].Value+'.import'; Bound-Leaf $import $map
 $compiled=@([regex]::Matches([IO.File]::ReadAllText((Source-Path $import)),'res://\.godot/imported/[^"]+\.ctex')|ForEach-Object {$_.Value}|Select-Object -Unique)
 Require ($compiled.Count -gt 0) 'NPC compiled import identity missing'
 foreach ($path in $compiled) { Bound-Leaf $path $map }
 if ($action.StartsWith('spar:',[StringComparison]::Ordinal)) {
  Require ($author[0].Value.Contains('"interaction_action":"'+$action+'"')) 'Spar does not match original author'
  $parts=$action.Split(':'); $e=$r.effects; $spar=$parts[1]
  Check-Bools $e @('entered','returned','won') @(); Check-Bools $e.outcomes[0] @('won') @('fled')
  Check-Bools $e.actual_result_payload @('victory','first_victory') @(); Check-Bools $r.after.sparring[$spar] @('won') @()
  Require ($e.scope -ceq 'EXISTING_NORMAL_ACTION_BATTLE_UI' -and $e.entered -eq $true -and $e.returned -eq $true -and $e.won -eq $true -and $e.outcomes -is [array] -and $e.outcomes.Count -eq 1 -and $e.outcomes[0].fled -eq $false -and $e.outcomes[0].won -eq $true -and $e.commands -is [array] -and $e.commands.Count -gt 0) 'Actual nonfled spar win absent'
  foreach ($command in $e.commands) { Check-Bools $command @('accepted','pressed') @(); Require ($command.kind -ceq 'normal_attack' -and $command.accepted -eq $true -and $command.pressed -eq $true -and $command.pointer.logical -is [array] -and $command.pointer.physical -is [array]) 'Normal Battle UI command absent' }
  Require ($e.original_payload.spar_id -ceq $spar -and $e.original_payload.enemy_id -ceq $parts[2] -and $e.original_payload.return_scene -ceq $scene -and $e.original_payload.return_world_map_version -eq 14 -and $e.original_payload.return_local_layout_version -eq 3 -and $e.actual_result_payload.victory -eq $true -and $e.actual_result_payload.first_victory -eq $true -and $e.actual_result_payload.training -eq [int]$parts[4] -and $r.after.training-$r.before.training -eq [int]$parts[4] -and $r.after.sparring[$spar].won -eq $true -and $r.after.sparring[$spar].attempts -eq 1 -and (Equal $e.actual_return_foot_px $r.pre_action_feet_px) -and (Equal $receipt.battle_effects $e)) 'Actual spar reward/return differs'
 } elseif ($id -ceq 'ch8_luoyang_final_clerk') { Check-ClerkEvidence $r $author[0].Value $map }
 elseif ($id -cin @('canal_endangered_porter','canal_saved_porter','canal_old_soldier')) {Check-DocksEvidence $r $author[0].Value $map}
 else { Require ($id -ceq 'luoyang_gate_sergeant' -and $r.dialog_id -ceq 'openworld_luoyang_gate_sergeant' -and $author[0].Value.Contains('"conversation_base_facing":"left"')) 'Unknown non-spar actor/original facing' }
 return @{scene_id=$scene;actor_id=$id;mode=$mode;action=$action;proof_kind='ORIGINAL_SOURCE_BOUND_ASSERTIONS_PLUS_ACTUAL_CASE_RESULT_INFERENCE';direct_confirm_pointer_receipt_available=$false;four_direction_or_keyboard_focus_credit=$false}
}
function Exact-Stack($actual,[string[]]$expected) {
 Require ($actual.Count -eq $expected.Count) 'Known nonImage full stack length differs'
 for ($n=0;$n -lt $expected.Count;$n++) { Require ($actual[$n] -ceq $expected[$n]) 'Known nonImage full stack source/function/line differs' }
}
function Warning-Stack([string]$actor,[string]$mode) {
 $npc='res://scripts/field/npc_node.gd'; $field='res://scripts/field/field_walkable_controller.gd'
 $warningInput='res://tests/helpers/v15_input_driver.gd'; $phase='res://tests/helpers/joint_v15_v8_city_authored_transition_lifecycle_phase.gd'; $physical='res://tests/helpers/joint_v15_wall_v5_city_physical_alpha_probe.gd'
 $head=if ($actor -cin @('luoyang_gate_sergeant','ch8_luoyang_final_clerk','canal_endangered_porter','canal_saved_porter','canal_old_soldier')) {@("begin_conversation|$npc|184","_on_npc_interacted|$field|2750","try_interact|$npc|438")} else {@("begin_conversation|$npc|184","_play_sparring_preface|$field|2820","_on_npc_action_requested|$field|2804","try_interact|$npc|434")}
 $middle=if ($mode -ceq 'space') {@("_on_player_interacted|$field|2550","_unhandled_input|res://scripts/field/player.gd|367","key|$warningInput|27","_normal_action_case|$phase|35")} else {@("_dispatch_pointer_interaction|$field|3690","_unhandled_input|$field|3730","pointer|$warningInput|40","click_entity|$physical|879","_normal_action_case|$phase|36")}
 return @($head)+@($middle)+@("move_to|$physical|133","follow|$warningInput|91","drive|$warningInput|80","completed_actor_stage|$warningInput|18")
}


# Fixed original four readable discoveries, in the authored interaction loop order.
# This is not a generic focus/readable whitelist or direct captured reader UI.
$readingSpecs=@(
 @('ch4_s1_luoyang_yamen','hanjia_rubbing','discover_readable:hanjia_water_rule_rubbing:found_hanjia_water_rule_rubbing','hanjia_water_rule_rubbing','found_hanjia_water_rule_rubbing'),
 @('ch4_s3_luoyang_market','armory_old_record','discover_readable:luoyang_quench_record:found_luoyang_quench_record','luoyang_quench_record','found_luoyang_quench_record'),
 @('ch4_s3_luoyang_market','paper_birdseal','discover_readable:zhouju_birdseal_copy:found_zhouju_birdseal_copy','zhouju_birdseal_copy','found_zhouju_birdseal_copy'),
 @('ch4_s3_luoyang_market','xuantong_note','discover_readable:xuantong_scale_weave_note:found_xuantong_scale_weave_note','xuantong_scale_weave_note','found_xuantong_scale_weave_note')
)
$readingPins=@{
 'res://scripts/ui/reading_panel.gd'='3B428B99A7B8BFF20F0979188A6B4AAF8CAFD6BD07EDC7772A6C54B4551C5320'
 'res://scripts/ui/inventory_panel.gd'='434F0FBA79F444A753987484F627331928092E3F2550247226EEB4F7BD2170BE'
 'res://scripts/autoload/scene_router.gd'='F3EAD7459632188350E1E3383EE915C83B71C1B86D36DADF718BD338A4324ECA'
 'res://data/maps/ch4_s1_luoyang_yamen_layout_v1.tres'='658D7038A28F63AA84C701F604BD04405DCFF3A8DF6BACC7C533557E2E73AB63'
 'res://data/maps/ch4_s3_luoyang_market_layout_v1.tres'='D99C58DC2AD2E8B1BFBCBC1AC69E7A9AA08E2AC7CFFFC773D4B5708F6825B60C'
 'res://data/items/hanjia_water_rule_rubbing.tres'='0796E140362882413F59BBFF4D513891DFE5692EFF70BB38F44E3403F6BE54EB'
 'res://data/items/luoyang_quench_record.tres'='474604026EF1EF6BC797672BF67F4C8F88C39EE0E50EDABC5C5192D606413859'
 'res://data/items/zhouju_birdseal_copy.tres'='954D7B0696C54D88C0704C04A7962908CF1D266AC3AA5C22417AD0AB0877BE75'
 'res://data/items/xuantong_scale_weave_note.tres'='B406C79CA2BBE192C7C498AFF8B6216457FF5860D8754D6E614DDB5423F705C8'
}
function Resolve-ReadingBinding($scene,$id) {
 Require ($scene -is [string] -and $id -is [string] -and $readingSpecs -is [array] -and $readingSpecs.Count -eq 4) 'Typed fixed readable identity/table required'
 foreach ($spec in $readingSpecs) { Require ($spec -is [array] -and $spec.Count -eq 5 -and @($spec|Where-Object {$_ -isnot [string]}).Count -eq 0) 'Malformed fixed readable specification' }
 $matches=@($readingSpecs|Where-Object {$_[0] -ceq $scene -and $_[1] -ceq $id})
 Require ($matches.Count -eq 1) 'Missing/duplicate/unknown fixed readable binding'
 return ,$matches[0]
}
function Bound-ReadingLeaf([string]$res,$map) {
 Bound-Leaf $res $map
 if ($readingPins.ContainsKey($res)) { Require ($map[(Source-Path $res)].sha256 -ieq $readingPins[$res]) 'Reading frozen source pin differs' }
 if ($res.EndsWith('.png',[StringComparison]::Ordinal)) {
  $import=$res+'.import'; Bound-Leaf $import $map
  $compiled=@([regex]::Matches([IO.File]::ReadAllText((Source-Path $import)),'res://\.godot/imported/[^"]+\.ctex')|ForEach-Object {$_.Value}|Select-Object -Unique)
  Require ($compiled.Count -gt 0) 'Reading PNG actual compiled import missing'
  foreach ($leaf in $compiled) { Bound-Leaf $leaf $map }
 }
}
function Reading-Stack([string]$mode) {
 Require ($mode -cin @('space','mouse')) 'Unknown reading input mode'
 $field='res://scripts/field/field_walkable_controller.gd'; $input='res://tests/helpers/v15_input_driver.gd'
 $phase='res://tests/helpers/joint_v15_v8_city_authored_transition_lifecycle_phase.gd'; $physical='res://tests/helpers/joint_v15_wall_v5_city_physical_alpha_probe.gd'
 $head=@('open_item|res://scripts/ui/reading_panel.gd|42','_open_reading|res://scripts/ui/inventory_panel.gd|704','_on_item_read_requested|res://scripts/ui/inventory_panel.gd|694','resolve_action|res://scripts/autoload/scene_router.gd|1267',"_resolve_field_action|$field|2692","_on_trigger_zone_entered|$field|2531")
 $middle=if ($mode -ceq 'space') {@("_on_player_interacted|$field|2563","_unhandled_input|res://scripts/field/player.gd|367","key|$input|27","_normal_action_case|$phase|35")} else {@("_dispatch_pointer_interaction|$field|3703","_unhandled_input|$field|3730","pointer|$input|40","click_entity|$physical|879","_normal_action_case|$phase|41")}
 return @($head)+@($middle)+@("move_to|$physical|133","follow|$input|91","drive|$input|80","completed_actor_stage|$input|18")
}
function Check-ReadingEvidence($r,$map) {
 Require ($r -is [Collections.IDictionary]) 'Actual reading record must be a dictionary'
 $spec=Resolve-ReadingBinding $r.source_scene_id $r.source_id
 $scene=$spec[0]; $id=$spec[1]; $action=$spec[2]; $item=$spec[3]; $flag=$spec[4]
 Require ($r.mode -is [string] -and $r.mode -cin @('space','mouse') -and $r.action -is [string] -and $r.action -ceq $action -and $r.dialog_id -is [string] -and $r.dialog_id -ceq '' -and $r.dialog_nodes -is [array] -and $r.dialog_nodes.Count -eq 0 -and $r.effects -is [Collections.IDictionary] -and $r.effects.Count -eq 0) 'Wrong typed reading action/dialog/effects'
 Check-Bools $r @() @('dry_run'); Check-Bools $r.approach @('ok') @()
 $receipt=$r.normal_transition_receipt
 Check-Bools $receipt @('complete','live_field','live_player','bound_field_is_current') @('loading_active','outcome_injected','route_injected')
 foreach ($key in @('source_scene_id','actual_scene_id','expected_scene_id')) { Require ($receipt[$key] -is [string] -and $receipt[$key] -ceq $scene) 'Reading real Field scene differs' }
 Require ($receipt.source_id -is [string] -and $receipt.source_id -ceq $id -and $receipt.mode -is [string] -and $receipt.mode -ceq $r.mode -and $receipt.original_action -is [string] -and $receipt.original_action -ceq $action -and $receipt.player_script -ceq 'res://scripts/field/player.gd' -and $receipt.current_scene_path -ceq 'res://scenes/field_walkable.tscn' -and $receipt.current_scene_instance_id -is [long] -and $receipt.current_scene_instance_id -ne 0 -and $receipt.player_instance_id -is [long] -and $receipt.player_instance_id -ne 0) 'Reading normal input/current lifecycle receipt incomplete'
 # Bind original layout author, item and exact source implementation. No UI
 # visible/current-item/close-pointer event is invented from this inference.
 $layout='res://data/maps/'+$scene+'_layout_v1.tres'; Bound-ReadingLeaf $layout $map
 $authors=@([regex]::Matches([IO.File]::ReadAllText((Source-Path $layout)),'\{[^{}]*"id"\s*:\s*"'+[regex]::Escape($id)+'"[^{}]*\}'))
 Require ($authors.Count -eq 1) 'Original readable author missing/nonunique'
 $author=$authors[0].Value
 Require ($author.Contains('"action":"'+$action+'"') -and $author.Contains('"hide_flag":"'+$flag+'"') -and $author.Contains('"activation":"interact"')) 'Reading original action/hide binding differs'
 $basePath='res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/'+$scene+'/art_contract.json'; Bound-Leaf $basePath $map
 $base=[IO.File]::ReadAllText((Source-Path $basePath))|ConvertFrom-Json -AsHashtable -Depth 100
 $slots=@($base.gameplay_slots.interactions|Where-Object {$_.source_id -ceq $id})
 Require ($slots.Count -eq 1 -and $slots[0].object_id -is [string]) 'Reading original source-to-object association missing/nonunique'
 $objects=@($base.objects|Where-Object {$_.id -ceq $slots[0].object_id})
 Require ($objects.Count -eq 1 -and $objects[0].texture -is [string] -and $objects[0].source_sha256 -is [string]) 'Reading exact original current prop missing'
 $object=$objects[0]; Bound-ReadingLeaf $object.texture $map
 Require ($object.source_sha256 -ieq $map[(Source-Path $object.texture)].sha256) 'Reading original prop PNG source SHA differs'
 $itemPath='res://data/items/'+$item+'.tres'; Bound-ReadingLeaf $itemPath $map
 $itemText=[IO.File]::ReadAllText((Source-Path $itemPath))
 Require ($itemText -match '(?m)^readable = true\r?$' -and $itemText -match '(?m)^max_stack = 1\r?$' -and $itemText -match '(?m)^stackable = false\r?$' -and $itemText -match ('(?m)^item_id = &"'+[regex]::Escape($item)+'"\r?$')) 'Original item is not exact readable singleton'
 foreach ($source in @('res://scripts/ui/reading_panel.gd','res://scripts/ui/inventory_panel.gd','res://scripts/autoload/scene_router.gd','res://scripts/domain/item.gd','res://scenes/ui/reading_panel.tscn')) { Bound-ReadingLeaf $source $map }
 # Every literal UI leaf consumed by these source files is first/current bound.
 foreach ($source in @('res://scripts/ui/reading_panel.gd','res://scripts/ui/inventory_panel.gd',$itemPath)) {
  foreach ($match in [regex]::Matches([IO.File]::ReadAllText((Source-Path $source)),'res://[^"''\r\n]+\.(?:png|gd|tscn)(?=["''\r\n])')) { Bound-ReadingLeaf $match.Value $map }
 }
 if ($r.mode -ceq 'space') { Require ($r.actual_input -is [Collections.IDictionary] -and $r.actual_input.mode -is [string] -and $r.actual_input.mode -ceq 'space') 'Reading not original Space input' }
 else {
  $input=$r.actual_input; $identity=$input.source_identity_before_input
  Check-Bools $input @('ok') @('source_sprite_alive_after_input'); Check-Bools $identity @('alpha_sampled_before_input') @()
  Require ($input.logical -is [array] -and $input.logical.Count -eq 2 -and $input.physical -is [array] -and $input.physical.Count -eq 2 -and $identity.texture_path -is [string] -and $identity.texture_path.EndsWith('.png',[StringComparison]::Ordinal) -and $identity.texture_source_sha256 -is [string]) 'Reading original normal pointer/source identity missing'
  Bound-ReadingLeaf $identity.texture_path $map
  Require ($identity.texture_path -ceq $object.texture -and $identity.sprite_path -is [string] -and $identity.sprite_path -ceq ('/root/FieldWalkable/WorldContainer/ActorLayer/SceneObject_'+$object.id) -and $identity.texture_source_sha256 -ieq $map[(Source-Path $identity.texture_path)].sha256) 'Reading actual pointer exact author prop/source PNG differs'
 }
 Require ($r.before -is [Collections.IDictionary] -and $r.after -is [Collections.IDictionary] -and $r.before.flags -is [Collections.IDictionary] -and $r.after.flags -is [Collections.IDictionary]) 'Reading state endpoints missing'
 Check-Bools $r.before.flags @() @($flag); Check-Bools $r.after.flags @($flag) @()
 $flags=[ordered]@{}; foreach ($key in $r.before.flags.Keys) { $flags[$key]=$r.before.flags[$key] }; $flags[$flag]=$true
 Require (Equal $flags $r.after.flags) 'Unapproved reading flag mutation'
 if ($id -ceq 'hanjia_rubbing') { Check-Bools $r.before.flags @('huilan_water_rule_understood') @(); Check-Bools $r.after.flags @('huilan_water_rule_understood') @() }
 foreach ($key in @('training','gold','reputation','quests','investigation','bounty','sparring')) { Require ($r.before.Contains($key) -and $r.after.Contains($key) -and (Equal $r.before[$key] $r.after[$key])) "Unapproved reading state mutation: $key" }
 $before=$r.before.inventory; $after=$r.after.inventory
 Require ($before -is [Collections.IDictionary] -and $after -is [Collections.IDictionary] -and $before.slots -is [array] -and $after.slots -is [array] -and $after.slots.Count -eq $before.slots.Count+1) 'Reading original item zero-to-one append missing'
 Require (@($before.slots|Where-Object {$_.item_id -ceq $item}).Count -eq 0) 'Reading item already owned before discovery'
 for ($n=0;$n -lt $before.slots.Count;$n++) { Require (Equal $before.slots[$n] $after.slots[$n]) 'Reading changed prior inventory slot' }
 $slot=$after.slots[-1]
 Require ($slot -is [Collections.IDictionary] -and $slot.Count -eq 3 -and $slot.item_id -is [string] -and $slot.item_id -ceq $item -and $slot['count'] -is [long] -and $slot['count'] -eq 1 -and $slot.instance_id -is [string] -and $slot.instance_id -cmatch ('^'+[regex]::Escape($item)+'#[1-9][0-9]*$')) 'Reading exact singleton actual item differs'
 $inventory=[ordered]@{}; foreach ($key in $before.Keys) { $inventory[$key]=$before[$key] }; $inventory['slots']=$after.slots
 Require (Equal $inventory $after) 'Reading changed other inventory state'
}
function Known-ReadingCase($stage,$spec,[string]$mode,$map) {
 Require ($stage.complete -is [bool] -and $stage.complete -and $stage.failures -eq 0 -and $stage.records.interactions -is [array]) 'Reading needs complete original actual gameplay'
 foreach ($row in $stage.records.interactions) { Require ($row -is [Collections.IDictionary] -and $row.source_scene_id -is [string] -and $row.source_id -is [string] -and $row.mode -is [string]) 'Typed interaction identity missing' }
 $matches=@($stage.records.interactions|Where-Object {$_.source_scene_id -ceq $spec[0] -and $_.source_id -ceq $spec[1] -and $_.mode -ceq $mode})
 Require ($matches.Count -eq 1) 'Missing/duplicate actual readable case'
 $r=$matches[0]; Check-ReadingEvidence $r $map
 $binding=$stage.current_author_bindings[$spec[0]]
 Require ($binding -is [Collections.IDictionary] -and $binding.path -is [string] -and $binding.base_path -is [string] -and $binding.sha256 -is [string] -and $binding.base_sha256 -is [string]) 'Reading current author/base binding missing'
 Bound-Leaf $binding.path $map; Bound-Leaf $binding.base_path $map
 Require ($binding.sha256 -ieq $map[(Source-Path $binding.path)].sha256 -and $binding.base_sha256 -ieq $map[(Source-Path $binding.base_path)].sha256) 'Reading actual current author source changed'
 Require ($binding.base_path -ceq ('res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/'+$spec[0]+'/art_contract.json')) 'Reading author base path not original district'
 $base=[IO.File]::ReadAllText((Source-Path $binding.base_path))|ConvertFrom-Json -AsHashtable -Depth 100
 $slot=@($base.gameplay_slots.interactions|Where-Object {$_.source_id -ceq $spec[1]})
 $patch=[IO.File]::ReadAllText((Source-Path $binding.path))|ConvertFrom-Json -AsHashtable -Depth 100
 Require ($slot.Count -eq 1 -and $patch.remove_object_ids -is [array] -and $patch.objects -is [array] -and $slot[0].object_id -cnotin $patch.remove_object_ids -and @($patch.objects|Where-Object {$_.id -ceq $slot[0].object_id}).Count -eq 0) 'Reading original retained prop replaced/removed in current patch'
 $legacy='res://data/maps/luoyang_v3_legacy/'+$spec[0]+'_scene.tres'; Bound-Leaf $legacy $map
 return @{scene_id=$spec[0];source_id=$spec[1];mode=$mode;action=$spec[2];item_id=$spec[3];flag=$spec[4];proof_kind='SOURCE_BOUND_EXECUTED_OPEN_ITEM_PLUS_ACTUAL_DISCOVERY_CASE_INFERENCE';direct_reader_visible_or_close_pointer_receipt_available=$false;reader_focus_cancel_or_full_ui_credit=$false}
}

function Save-NegativeStack {
 return @(
  'navigation_coordinate_version_supported|res://scripts/autoload/scene_router.gd|934',
  'load_from_slot|res://scripts/autoload/save_manager.gd|78',
  '_unsupported|res://tests/helpers/joint_v15_current_save_load_20261008.gd|268',
  '_current_case|res://tests/helpers/luoyang_enclosure_v11_city_only_current_save.gd|124',
  '_birth|res://tests/helpers/joint_v15_current_save_load_20261008.gd|164',
  '_wait_field|res://tests/helpers/joint_v15_v9c_world_prepared_phase.gd|793',
  'completed_actor_stage|res://tests/helpers/v15_input_driver.gd|18'
 )
}
function Check-SaveNegativeEvidence($result,$map) {
 Require ($result -is [Collections.IDictionary] -and $result.mode -is [Collections.IDictionary] -and $result.mode.phase -is [string] -and $result.mode.phase -ceq 'save' -and $result.complete -is [bool] -and $result.complete -and $result.failures -is [long] -and $result.failures -eq 0) 'Save-negative warning requires complete actual save result'
 $stage=$result.stage
 Require ($stage -is [Collections.IDictionary] -and $stage.scope -is [string] -and $stage.scope -ceq 'LUOYANG_ENCLOSURE_V11_FOUR_CURRENT_SAVE_LOAD_FIELD_BIRTH' -and $stage.complete -is [bool] -and $stage.complete -and $stage.failures -is [long] -and $stage.failures -eq 0 -and $stage.records -is [array] -and $stage.records.Count -eq 4 -and $stage.new_game -is [Collections.IDictionary] -and $stage.new_game.complete -is [bool] -and $stage.new_game.complete -and $stage.world_coordinate_version -is [long] -and $stage.world_coordinate_version -eq 14 -and $stage.city_layout_version -is [long] -and $stage.city_layout_version -eq 3) 'Save-negative warning lacks complete original current scope/NewGame/four cases'
 # These eight immutable current sources bind the one exact native warning and
 # the original real isolated loader, sentinels, source order and snapshot.
 $savePins=@{
  'res://scripts/autoload/scene_router.gd'='F3EAD7459632188350E1E3383EE915C83B71C1B86D36DADF718BD338A4324ECA'
  'res://scripts/autoload/save_manager.gd'='67C06CD14D6A7C0BBFD7467BBAAE84F906AAD57B19CABC0902BAF80EB3AFF7D9'
  'res://tests/helpers/luoyang_enclosure_v11_city_only_current_save.gd'='7F1FF120EDE797E1352B4491CCB7B11495596632AC8835F9F79C41AF9EE9DF3A'
  'res://tests/helpers/joint_v15_current_save_load_20261008.gd'='83475BD16ED5D68D4FD2B54FB795D92ECE9EB188352ACE459A4DAF5AC9B65474'
  'res://tests/helpers/joint_v15_v9c_world_prepared_phase.gd'='16A66F74EBA277C9DCF7C1A6801BB5183D0FEDF363A3E6FC3805BC41E7474970'
  'res://tests/helpers/v15_input_driver.gd'='A3C59FDE8D9F55D71919276286DC720E177EF3DC046D224204868A24881DE5D7'
  'res://tests/helpers/v15_isolated_save_manager.gd'='DAB23DD87EE942ED9CD60E97F9CD9441DC8F76AA1F6B310203636A257903E9C6'
  'res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd'='558A3EDFAA368FF52B67FF0EAADE7505191011928C2A724897EFC727E43887F6'
 }
 foreach ($res in $savePins.Keys) {
  $path=Source-Path $res
  Require ($map.ContainsKey($path) -and $map[$path].sha256 -is [string] -and $map[$path].sha256 -ieq $savePins[$res] -and (Hash $path) -ieq $savePins[$res] -and (Get-Item -LiteralPath $path).Length -eq $map[$path].bytes) 'Save-negative exact source/first/current binding differs'
 }
 # Keep the original typed twenty-case rejection and zero-mutation predicate.
 Check-UnknownVersions $stage.unknown_records
 $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
 foreach ($case in $stage.records) {
  Require ($case -is [Collections.IDictionary] -and $case.scene_id -is [string] -and $case.scene_id -cin $ids -and $seen.Add($case.scene_id) -and $case.passed -is [bool] -and $case.passed -and $case.births -is [array] -and $case.births.Count -eq 2) 'Save-negative warning lacks four complete current cases'
  foreach ($birth in $case.births) { Require ($birth -is [Collections.IDictionary] -and $birth.raw_full_feet_clear -is [bool] -and $birth.raw_full_feet_clear -and $birth.actual_Physics_clear -is [bool] -and $birth.actual_Physics_clear -and $birth.position_matches_saved -is [bool] -and $birth.position_matches_saved) 'Save-negative current Field birth not complete' }
 }
 $versions=@([long]2,[long]99,[double]1.5,[string]'3',[bool]$true)
 $receipts=[Collections.Generic.List[object]]::new();$index=0
 foreach ($id in $ids) { foreach ($version in $versions) {
  $row=$stage.unknown_records[$index]
  Require ($row.scene_id -ceq $id -and (Equal $row.version $version)) 'Save-negative actual source-loop case order/type differs'
  $receipts.Add(@{scene_id=$id;version_domain='local';version=$row.version;loaded=$false;zero_mutation=$true;actual_record_index=$index;input_path=$row.input_path;input_sha256=$row.input_sha256})
  $index+=1
 } }
 return ,$receipts.ToArray()
}

function Check-FullStderr([string]$stderr,$map,$result) {
 $lines=@($stderr -split '\r?\n')
 # Only the terminal newline is a separator, not an accepted unknown bare line.
 if ($lines.Count -gt 0 -and $lines[-1] -ceq '') { $lines=@($lines|Select-Object -SkipLast 1) }
 $i=0; $warningCount=0; $frameCount=0; $npcCount=0; $focusCount=0; $readingCount=0
 $readingCases=[Collections.Generic.List[object]]::new(); $saveNegativeCount=0; $saveNegativeReceipts=@()
 $knownReceipts=[Collections.Generic.List[object]]::new(); $sparCases=[Collections.Generic.List[object]]::new(); $seenNPC=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
 while ($i -lt $lines.Count) {
  $header=[regex]::Match($lines[$i],"^WARNING: Loaded resource as image file, this will not work on export: '(res://[^']+)'\. Instead, import the image file as an Image resource and load it normally as a resource\.$")
  $npc=Match-NPCWarningHeader $lines[$i]
  $focus=$lines[$i] -ceq "WARNING: This control can't grab focus. Use set_focus_mode() and set_focus_behavior_recursive() to allow a control to get focus."
  $saveReject=$lines[$i] -ceq 'WARNING: [SceneRouter] 洛阳坐标版本或资源校验失败，存档尚未应用：'
  Require ($header.Success -or $npc.Success -or $focus -or $saveReject) "Unknown stderr line at $($i+1); pending draft refused"
  $native='   at: load_from_file (core/io/image.cpp:2766)'
  if ($header.Success) { $image=Source-Path $header.Groups[1].Value; Require ($map.ContainsKey($image)) 'Known Image warning resource absent from actual first guard' }
  elseif ($saveReject) {
   if ($saveNegativeCount -eq 0) { $saveNegativeReceipts=Check-SaveNegativeEvidence $result $map }
   $native='   at: push_warning (core/variant/variant_utility.cpp:1034)'
  }
  else {
   Require ($result.mode.phase -ceq 'gameplay' -and $result.stage.failures -eq 0 -and $result.stage.complete -eq $true) 'NonImage warning outside complete actual gameplay'
   foreach ($path in $warningPins.Keys) { Bound-Leaf $path $map }
   Bound-Leaf 'res://scripts/field/field_walkable_controller.gd' $map; Bound-Leaf 'res://scripts/field/player.gd' $map
   $native=if ($npc.Success) {'   at: push_warning (core/variant/variant_utility.cpp:1034)'} else {'   at: grab_focus (scene/gui/control.cpp:2373)'}
  }
  Require ($i+2 -lt $lines.Count -and $lines[$i+1] -ceq $native -and $lines[$i+2] -ceq '   GDScript backtrace (most recent call first):') 'Unknown/malformed warning native/backtrace lines'
  $i+=3; $index=0; $actualStack=[Collections.Generic.List[string]]::new()
  while ($i -lt $lines.Count) {
   $frame=[regex]::Match($lines[$i],'^       \[([0-9]+)\] ([A-Za-z_][A-Za-z0-9_]*) \((res://[^():]+\.gd):([0-9]+)\)$')
   if (-not $frame.Success) { break }
   Require ([int]$frame.Groups[1].Value -eq $index) 'Nonconsecutive Image backtrace frames'
   Check-ConcreteStack $frame.Groups[2].Value $frame.Groups[3].Value ([int]$frame.Groups[4].Value) $map
   $actualStack.Add($frame.Groups[2].Value+'|'+$frame.Groups[3].Value+'|'+$frame.Groups[4].Value)
   $index+=1; $frameCount+=1; $i+=1
  }
  Require ($index -gt 0) 'Known Image warning requires concrete validated backtrace'
  if ($header.Success) { $warningCount+=1 }
  elseif ($saveReject) {
   Exact-Stack $actualStack (Save-NegativeStack)
   Require ($saveNegativeCount -lt 20) 'Extra save-negative native warning'
   $saveNegativeCount+=1
  }
  elseif ($npc.Success) {
   $mode=if (@($actualStack|Where-Object {$_ -ceq 'key|res://tests/helpers/v15_input_driver.gd|27'}).Count -eq 1) {'space'} else {'mouse'}
   $actor=$npc.Groups[1].Value; Exact-Stack $actualStack (Warning-Stack $actor $mode)
   Require ($seenNPC.Add($actor+'/'+$mode)) 'Duplicate NPC warning/case'
   $binding=Resolve-NPCWarningBinding $actor
   $scene=$binding.scene; $action=$binding.action
   $knownReceipts.Add((Known-Case $result.stage $scene $actor $mode $action $map)); $npcCount+=1
  } elseif ($actualStack[0] -ceq 'open_item|res://scripts/ui/reading_panel.gd|42') {
   $mode=if (@($actualStack|Where-Object {$_ -ceq 'key|res://tests/helpers/v15_input_driver.gd|27'}).Count -eq 1) {'space'} else {'mouse'}
   Exact-Stack $actualStack (Reading-Stack $mode)
   if ($readingCases.Count -eq 0) { foreach ($spec in $readingSpecs) { foreach ($caseMode in @('space','mouse')) { $readingCases.Add((Known-ReadingCase $result.stage $spec $caseMode $map)) } } }
   Require ($readingCount -lt 8 -and $readingCases[$readingCount].mode -ceq $mode) 'Extra/out-of-order Reading warning'
   $knownReceipts.Add($readingCases[$readingCount]); $readingCount+=1
  } else {
   Exact-Stack $actualStack @(
    '_open|res://scripts/ui/formal_confirm_dialog.gd|76','show_confirm|res://scripts/ui/formal_confirm_dialog.gd|48',
    '_show_sparring_confirmation|res://scripts/field/field_walkable_controller.gd|2886','_on_dialog_spar_requested|res://scripts/field/field_walkable_controller.gd|2854',
    '_resolve_action|res://scripts/autoload/dialog_player.gd|378','advance|res://scripts/autoload/dialog_player.gd|125',
    '_input|res://scripts/ui/dialog_box.gd|112','key|res://tests/helpers/v15_input_driver.gd|27',
    '_finish_dialogs|res://tests/helpers/joint_v15_v8_city_authored_two_choice_phase.gd|93','completed_actor_stage|res://tests/helpers/v15_input_driver.gd|18'
   )
   if ($sparCases.Count -eq 0) { foreach ($spec in $sparSpecs) { foreach ($mode in @('space','mouse')) { $sparCases.Add((Known-Case $result.stage $spec[0] $spec[1] $mode $spec[2] $map)) } } }
   Require ($focusCount -lt $sparCases.Count) 'Extra Confirm warning'
   # Original loop order and complete source-bound cases support inference only.
   # Native block itself contains no actor id/timestamp/ConfirmAction pointer.
   $knownReceipts.Add($sparCases[$focusCount]); $focusCount+=1
  }
 }
 if ($saveNegativeCount -gt 0) { Require ($saveNegativeCount -eq 20 -and $saveNegativeReceipts.Count -eq 20) 'Incomplete original four by five save-negative warning/actual receipt inference' }
 if ($result.mode.phase -ceq 'save') { Require ($saveNegativeCount -eq 20) 'Complete save scope requires all twenty exact original rejection warnings' }
 if ($focusCount -gt 0) { Require ($focusCount -eq 12 -and $sparCases.Count -eq 12) 'Incomplete six spar by two mode Confirm warning/case inference' }
 if ($readingCount -gt 0) { Require ($readingCount -eq 8 -and $readingCases.Count -eq 8) 'Incomplete four discoveries by two ordered Reading warning/case inference' }
 return @{save_expected_rejection_warnings=$saveNegativeCount;save_negative_case_bindings=$saveNegativeReceipts;save_negative_proof_kind='SOURCE_BOUND_EXECUTED_UNSUPPORTED_LOAD_PLUS_ACTUAL_ZERO_MUTATION_CASE_ORDER_INFERENCE';direct_warning_case_id_receipt_available=$false;save_negative_warning_clean_credit=$false;reading_focus_warnings=$readingCount;reading_proof_kind='SOURCE_BOUND_EXECUTED_OPEN_ITEM_PLUS_ACTUAL_DISCOVERY_CASE_INFERENCE';direct_reader_visible_or_close_pointer_receipt_available=$false;reader_focus_cancel_or_full_ui_credit=$false;warnings=$warningCount;concrete_frames=$frameCount;unknown_lines=0;npc_fallback_warnings=$npcCount;confirm_focus_warnings=$focusCount;known_nonimage_case_bindings=$knownReceipts.ToArray();classification_basis='ORIGINAL_SOURCE_BOUND_ASSERTIONS_PLUS_ACTUAL_CASE_RESULT_INFERENCE';direct_confirm_pointer_receipt_available=$false;clean_stderr=($npcCount+$focusCount+$readingCount+$warningCount+$saveNegativeCount -eq 0);keyboard_focus_credit=$false;four_direction_pose_credit=$false}
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
 $stderrReview=Check-FullStderr $stderr $map $result
 $row=[ordered]@{path=$resultRes;sha256=$evidence[$resultPath].ToLowerInvariant();phase=$phase;backend=$backend;actual_os_exit=0;complete_stderr_reviewed=$true;source_changes=@();player_changes=@();exact_utc_ticks_reviewed=$true;root_independent_actual_review_pending=$true}
 $rows.Add($row)
 $provenance.Add([ordered]@{wrapper_directory=$directory;before_path=$beforePath;before_sha256=$evidence[$beforePath];after_path=$afterPath;after_sha256=$evidence[$afterPath];stdout_path=$stdoutPath;stdout_sha256=$evidence[$stdoutPath];stderr_path=$stderrPath;stderr_sha256=$evidence[$stderrPath];result_path=$resultRes;result_sha256=$evidence[$resultPath];actual_graphics_stdout=@($graphics|ForEach-Object {$_.Value});known_warning_review=$stderrReview;known_image_warning_count=$stderrReview.warnings;concrete_backtrace_frame_count=$stderrReview.concrete_frames;unknown_stderr_lines=$stderrReview.unknown_lines;first_guard_inventory_path=$inventory.path;first_guard_inventory_sha256=$inventory.sha256;required_inventory_leaf_count=$inventory.map.Count;required_inventory_leaves_matched=$true;inventory_use='PATH_SEEDS_ONLY_THIS_RUN_FRESH_SHA_BYTES';geometry_exact_eight_legacy_matched=($phase -ceq 'geometry');errors=0;scripts=0;unknown_warnings=0;player_exact_ticks_evidence='WRAPPER_BEFORE_15_PLUS_ACTUAL_AFTER_EMPTY_COMPARISON_AND_CURRENT_15';wrapper_after_raw_player_snapshot_available=$false;active_slot_before=$result.active_slot_before;active_slot_after=$result.active_slot_after;actual_engine_arguments=$engineArgs;user_arguments=$userArgs;source_count=$map.Count;raw_record_count=$before.sources.Count;unique_source_count=$map.Count;identical_duplicate_count=$identicalDuplicates;phase=$phase;backend=$backend})
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
$draft=[ordered]@{schema=1;status='PENDING_ROOT_ACTUAL_SIX_AND_VISUAL_APPROVAL';art_current_images_approved=$false;root_actual_review_approved=$false;formal_approved=$false;world_subject_version=14;historical_compatibility_tested=$false;scope='LUOYANG_FOUR_CITY_ONLY_FRESH_APPROVAL_DRAFT_NOT_SIGNATURE';source_sha256=$sourceSHAs;candidate_sha256=$candidateSHAs;layout_sha256=$layoutSHAs;results=$rows.ToArray();wrapper_provenance=$provenance.ToArray();created_utc=[DateTime]::UtcNow.ToString('o');builder_path=$PSCommandPath;builder_sha256=(Hash $PSCommandPath);source_file_count=$allSources.Count;activator_in_source_sha256=$false;limitations=@('Builder does not independently approve the complete dynamic dependency closure; ROOT must independently review every slot first guard','Fixed428/424 supply only path seeds; each actual firstguard must have fresh current SHA/bytes and agree across six; geometry additionally requires exact8legacy; no historical row digest authorizes current source','ROOT must independently inspect actual six complete runs and current images before manually approving','This PENDING draft cannot satisfy activator approval status or visual predicate','Wrapper after stores comparison deltas, not raw after player rows; no raw past-after snapshot is fabricated','Only current four city scope; no world15/old-save/whole-world/audio-listening approval','Activator excluded to avoid approval-SHA self-reference','Known warnings retained: not clean; no keyboard-focus/navigation/cancel or four-direction NPC pose approval','Confirm category uses ORIGINAL_SOURCE_BOUND_ASSERTIONS_PLUS_ACTUAL_CASE_RESULT_INFERENCE; direct_confirm_pointer_receipt_available=false','Reading is separate: eight ordered original discoveries, source-bound open_item plus actual case inference only; direct_reader_visible_or_close_pointer_receipt_available=false; no readerfocus/cancel/full UI credit','Docks mirror classification is exact three ordinary authored NPCs only; saved porter has exact source-bound ancient-temple arrival, not general source/target equality waiver; no battle music continuity or quest-completion credit inferred','Twelve ordered actual spar cases support inference: native warning contains no case timestamp/id and no direct modal or ConfirmAction raw capture is invented')}
New-Item -ItemType Directory -Path $target | Out-Null
$output=Join-Path $target 'city_only_actual_six_approval_DRAFT.json'
[IO.File]::WriteAllText($output,($draft|ConvertTo-Json -Depth 32),[Text.UTF8Encoding]::new($false))
$readback=Get-Content -LiteralPath $output -Raw|ConvertFrom-Json -AsHashtable -Depth 32
Require ($readback.status -ceq 'PENDING_ROOT_ACTUAL_SIX_AND_VISUAL_APPROVAL' -and $readback.art_current_images_approved -eq $false -and $readback.results.Count -eq 6) 'Draft readback failed'
[pscustomobject]@{path=$output;sha256=(Hash $output);status=$readback.status;art_current_images_approved=$false;formal_approved=$false}






