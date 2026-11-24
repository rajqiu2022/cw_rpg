param([string]$ProjectRoot='F:\Code\RPG_GAME')
# READ ONLY actual private-function regression. No builder top-level, Field,
# signing, writes, playback or complete-six promotion. Actual six incremental
# Docks cases are immutable evidence; mutation fixtures are NOT new actual cases.
$ErrorActionPreference='Stop'
$project=[IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
$game=Join-Path $project 'game'
$builder=Join-Path $project 'scripts/qa/prepare_luoyang_city_only_actual_six_approval_draft_retry9_20261010.ps1'
$builderSHA='09B0C6D31D0AB57784F1326F3B54C865A894D039E082764497AD5F895E5CF55C'
$original=Join-Path $project 'scripts/qa/prepare_luoyang_city_only_actual_six_approval_draft_retry6_20261010.ps1'
$originalSHA='A4A35BB57B63D7172D3E3527D1E81DFBE1CEFFFFA8DA14155B5DBFEF2F6FBA64'
$selfSHA=(Get-FileHash -LiteralPath $PSCommandPath).Hash
if ((Get-FileHash -LiteralPath $builder).Hash -cne $builderSHA -or (Get-FileHash -LiteralPath $original).Hash -cne $originalSHA) {throw 'Pinned new/original consumer changed'}
$tokens=$null; $errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($builder,[ref]$tokens,[ref]$errors)
if ($errors.Count -ne 0) {throw 'Actual consumer must parse'}
$functions=@($ast.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst]},$true))
foreach ($f in $functions) {Invoke-Expression $f.Extent.Text}
# Exact top-level assignments ONLY, never local similarly-named fields.
foreach ($name in @('$warningPins','$fixed','$sparSpecs','$readingSpecs','$readingPins')) {
 $found=@($ast.EndBlock.Statements|Where-Object {$_ -is [Management.Automation.Language.AssignmentStatementAst] -and $_.Left.Extent.Text -ceq $name})
 if ($found.Count -ne 1) {throw "Missing/duplicate exact top-level table $name"}
 Invoke-Expression $found[0].Extent.Text
}
$stackSourceCache=@{}
$checks=0
function Test([bool]$ok,[string]$label) {$script:checks++; if (-not $ok) {throw "DOCKS UNIT FAIL: $label"}}
function Reject([scriptblock]$call,[string]$label) {$rejected=$false;try {& $call|Out-Null} catch {$rejected=$true};Test $rejected $label}
$old=@(
 @('luoyang_gate_sergeant','ch4_s0_luoyang_gate',''),
 @('ch8_luoyang_final_clerk','ch4_s1_luoyang_yamen',''),
 @('spar_yamen_patrol','ch4_s1_luoyang_yamen','spar:yamen_patrol:luoyang_patrol:府衙巡捕:30:7'),
 @('spar_yamen_captain','ch4_s1_luoyang_yamen','spar:yamen_captain:boss_luoyang_captain:府衙都头:42:10'),
 @('spar_luoyang_shen_guard','ch4_s3_luoyang_market','spar:luoyang_shen_guard:ch2_tournament_guard:沈家护院总管:18:4'),
 @('spar_luoyang_examiner','ch4_s3_luoyang_market','spar:luoyang_examiner:wulin_examiner:大会考校官:24:6'),
 @('spar_luoyang_blademaster','ch4_s3_luoyang_market','spar:luoyang_blademaster:wandering_blademaster:流浪刀客:60:15'),
 @('spar_luoyang_patrol','ch4_s3_luoyang_market','spar:luoyang_patrol:luoyang_patrol:洛阳巡捕:32:8')
)
foreach ($spec in $old) {
 $line="WARNING: [NPCNode] $($spec[0]) has no authored 'right' conversation facing; using mirror fallback"
 Test (Match-NPCWarningHeader $line).Success ('original header '+$spec[0])
 $bound=Resolve-NPCWarningBinding $spec[0]
 Test ($bound.scene -ceq $spec[1] -and $bound.action -ceq $spec[2]) ('original exact binding '+$spec[0])
}
$docks=@(
 @('canal_endangered_porter','ch4_canal_battle','ch4_s2_canal_docks'),
 @('canal_saved_porter','ch4_canal_result','ch4_s4_ancient_temple'),
 @('canal_old_soldier','ch4_hanjia_blade_offer','ch4_s2_canal_docks')
)
$head=@('begin_conversation|res://scripts/field/npc_node.gd|184','_on_npc_interacted|res://scripts/field/field_walkable_controller.gd|2750','try_interact|res://scripts/field/npc_node.gd|438')
$tail=@('move_to|res://tests/helpers/joint_v15_wall_v5_city_physical_alpha_probe.gd|133','follow|res://tests/helpers/v15_input_driver.gd|91','drive|res://tests/helpers/v15_input_driver.gd|80','completed_actor_stage|res://tests/helpers/v15_input_driver.gd|18')
$expectedStacks=@{
 space=@($head)+@('_on_player_interacted|res://scripts/field/field_walkable_controller.gd|2550','_unhandled_input|res://scripts/field/player.gd|367','key|res://tests/helpers/v15_input_driver.gd|27','_normal_action_case|res://tests/helpers/joint_v15_v8_city_authored_transition_lifecycle_phase.gd|35')+@($tail)
 mouse=@($head)+@('_dispatch_pointer_interaction|res://scripts/field/field_walkable_controller.gd|3690','_unhandled_input|res://scripts/field/field_walkable_controller.gd|3730','pointer|res://tests/helpers/v15_input_driver.gd|40','click_entity|res://tests/helpers/joint_v15_wall_v5_city_physical_alpha_probe.gd|879','_normal_action_case|res://tests/helpers/joint_v15_v8_city_authored_transition_lifecycle_phase.gd|36')+@($tail)
}
foreach ($spec in $docks) {
 $line="WARNING: [NPCNode] $($spec[0]) has no authored 'right' conversation facing; using mirror fallback"
 Test (Match-NPCWarningHeader $line).Success ('exact Docks header '+$spec[0])
 $bound=Resolve-NPCWarningBinding $spec[0]
 Test ($bound.scene -ceq 'ch4_s2_canal_docks' -and $bound.action -ceq '' -and $bound.dialog -ceq $spec[1] -and $bound.target -ceq $spec[2]) ('exact Docks source and target '+$spec[0])
 foreach ($mode in @('space','mouse')) {
  $actual=@(Warning-Stack $spec[0] $mode); Exact-Stack $actual $expectedStacks[$mode]
  Test ($actual.Count -eq $(if ($mode -ceq 'space') {11} else {12})) ('original complete stack '+$spec[0]+'/'+$mode)
  for ($n=0;$n -lt $actual.Count;$n++) {$bad=@($actual);$bad[$n]+='0';Reject {Exact-Stack $bad $expectedStacks[$mode]} ('mutated stack '+$spec[0]+'/'+$mode+'/'+$n)}
  Reject {Exact-Stack @($actual|Select-Object -SkipLast 1) $expectedStacks[$mode]} 'missing stack'
  Reject {Exact-Stack (@($actual)+@($actual[-1])) $expectedStacks[$mode]} 'extra stack'
 }
 $wrongHeaders=@(($line.Replace("'right'","'left'")),($line+' extra'),($line.Replace('[NPCNode]','[Unknown]')))
 Test ($wrongHeaders.Count -eq 3) 'three isolated wrong header fixtures'
 foreach ($bad in $wrongHeaders) {
  Test ($bad -is [string] -and $bad -cne $line) 'wrong fixture is not unchanged valid header'
  Test (-not (Match-NPCWarningHeader $bad).Success) 'wrong exact header'
 }
}
foreach ($id in @('unknown','luoyang_armory_keeper','canal_doctor','luoyang_market_citizen','canal_porter')) {
 Reject {Resolve-NPCWarningBinding $id} ('unknown remains refused '+$id)
 Test (-not (Match-NPCWarningHeader "WARNING: [NPCNode] $id has no authored 'right' conversation facing; using mirror fallback").Success) 'no generic header'
}
Reject {Resolve-DocksWarningBinding 1} 'numeric id'
Reject {Resolve-DocksWarningBinding $null} 'null id'
# External executable guards are explicitly NOT project-source rows. Actual
# engine first/last identity remains an independent inner/outer contract.
Test ((Source-Path 'res://scripts/field/player.gd') -ceq (Join-Path $game 'scripts/field/player.gd')) 'project source domain'
Reject {Source-Path 'C:\Windows\System32\cmd.exe'} 'external executable row refused'
Reject {Source-Path '..\outside.exe'} 'relative escape refused'
$beforePath=Join-Path $project 'game/build/joint_world_luoyang_20261003_qa/446_luoyang_original_candidate_gameplay_headless_20261010/before.json'
$beforeSHA='9358DB6A0696E4B94657D530C235C4C8749EF147EDC692EE24446F437976D95F'
Test ((Hash $beforePath) -ceq $beforeSHA) 'actual 446 firstguard'
$before=Get-Content -LiteralPath $beforePath -Raw|ConvertFrom-Json -AsHashtable -Depth 100
$map=@{}
foreach ($row in $before.sources) {$path=Source-Path $row.path;if ($map.ContainsKey($path)) {throw 'Actual firstguard duplicate'};$map[$path]=$row}
foreach ($res in $warningPins.Keys) {Bound-Leaf $res $map;Test ($warningPins[$res] -is [string] -and $warningPins[$res] -cmatch '^[0-9A-F]{64}$') ('64hex/source first/current '+$res)}
foreach ($mode in @('space','mouse')) {foreach ($frame in $expectedStacks[$mode]) {$p=$frame.Split('|');Check-ConcreteStack $p[0] $p[1] ([int]$p[2]) $map}}
$caseRoot=Join-Path $project 'game/build/joint_world_luoyang_20261003_qa/luoyang_enclosure_v11_city_only_1791566856_1550257_48284'
$casePins=@{
 canal_endangered_porter=@{space='513869E6A078099805E5CFECE9C6D6152FB5617A54BB164D88151CFDBDAE824C';mouse='2D56137DAA462292A0EE273B8B45EAAA5E51EC81D504D123BAFE9068B33844D6'}
 canal_saved_porter=@{space='2E61CAAB8B4C1E04645E95A5822638A8496C0E8669BEC80F4E9D938623E2A2EF';mouse='52866C1879ECEA19B5FD7A568FCB6E2AE49E9F415F1325CC4E77B1A69F754874'}
 canal_old_soldier=@{space='ADA534D6D72C50CFCACD58B81A84B7C1C70B4BD4EB9CBFDF8168B706949CF843';mouse='5BD2393E02B295BC93352B0E2248B9ABC5272E65149ED7E523C5F6DB786C2EA4'}
}
$transitionPins=@{
 canal_endangered_porter=@{space='F7999EFAC7F0711B2C7E4BCCD4329D1F76DDC263D9E014B978EE0CD481BC2B45';mouse='6252D73E6BD46BAA5463B816118825E793F5EC731C83E84B39522ECFD6160204'}
 canal_saved_porter=@{space='7DB0808A690E96ECB9816153AB7346DDD8DF9C25D97DA2EA803A10FCC80A7680';mouse='F498FD91E92F2554651F3AB690E432A301A0AD0581DB7A66BE82D921E835D94D'}
 canal_old_soldier=@{space='9ACD7CB6BD1EBADB23ED03302EC4228F0CFA0ADF030E5365978C45FA46DFBB61';mouse='65D558D8A6F3E26F3F424993081BAA3CBF4D6358AF5D4E0052859A2F076EF9AD'}
}
$rows=@{};$authors=@{};$evidence=@{}
$legacyText=[IO.File]::ReadAllText((Source-Path 'res://data/maps/luoyang_v3_legacy/ch4_s2_canal_docks_scene.tres'))
foreach ($spec in $docks) {
 $id=$spec[0];$found=@([regex]::Matches($legacyText,'\{[^\r\n{}]*"npc_id"\s*:\s*"'+[regex]::Escape($id)+'"[^\r\n{}]*\}'));Test ($found.Count -eq 1) 'unique actual author';$authors[$id]=$found[0].Value
 foreach ($mode in @('space','mouse')) {
  $path=Join-Path $caseRoot ('npcs_ch4_s2_canal_docks_'+$id+'_'+$mode+'.json')
  $transition=Join-Path $caseRoot ('normal_transition_ch4_s2_canal_docks_'+$id+'_'+$mode+'.json')
  Test ((Hash $path) -ceq $casePins[$id][$mode] -and (Hash $transition) -ceq $transitionPins[$id][$mode]) ('fixed actual case pair '+$id+'/'+$mode)
  $row=Get-Content -LiteralPath $path -Raw|ConvertFrom-Json -AsHashtable -Depth 100
  $receipt=Get-Content -LiteralPath $transition -Raw|ConvertFrom-Json -AsHashtable -Depth 100
  Test (Equal $receipt $row.normal_transition_receipt) 'original separate transition receipt exact'
  Check-DocksEvidence $row $authors[$id] $map
  Test ($row.mode -ceq $mode) ('actual private core '+$id+'/'+$mode)
  $rows[$id+'/'+$mode]=$row;$evidence[$path]=$casePins[$id][$mode];$evidence[$transition]=$transitionPins[$id][$mode]
 }
}
function Copy-Case([string]$id='canal_endangered_porter',[string]$mode='space') {return ($rows[$id+'/'+$mode]|ConvertTo-Json -Depth 100|ConvertFrom-Json -AsHashtable -Depth 100)}
function Sync-Receipt($r) {$r.normal_transition_receipt.battle_entry=$r.battle_lifecycle;$r.normal_transition_receipt.battle_effects=$r.effects}
foreach ($spec in $docks) {
 $id=$spec[0]
 foreach ($key in @('source_scene_id','source_id','mode','action','dialog_id')) {$r=Copy-Case $id;$r[$key]=1;Reject {Check-DocksEvidence $r $authors[$id] $map} ('wrongtyped '+$id+'/'+$key)}
 $r=Copy-Case $id;$r.source_scene_id='ch4_s1_luoyang_yamen';Reject {Check-DocksEvidence $r $authors[$id] $map} 'wrong scene'
 $r=Copy-Case $id;$r.dialog_id='unapproved';Reject {Check-DocksEvidence $r $authors[$id] $map} 'wrong dialogue'
 $r=Copy-Case $id;$r.dialog_nodes=@($r.dialog_nodes|Select-Object -SkipLast 1);Reject {Check-DocksEvidence $r $authors[$id] $map} 'missing node'
 $r=Copy-Case $id;$r.dialog_nodes[0].source_sha256=('0'*64);Reject {Check-DocksEvidence $r $authors[$id] $map} 'node source changed'
 $r=Copy-Case $id;$r.battle_lifecycle.terminal_on_end='unapproved';Sync-Receipt $r;Reject {Check-DocksEvidence $r $authors[$id] $map} 'wrong terminal'
 foreach ($key in @('complete','live_field','live_player','bound_field_is_current')) {$r=Copy-Case $id;$r.normal_transition_receipt[$key]=$false;Reject {Check-DocksEvidence $r $authors[$id] $map} ('partial receipt '+$key)}
 foreach ($key in @('reputation','bounty','sparring')) {$r=Copy-Case $id;if ($key -ceq 'reputation') {$r.after[$key]++} else {$r.after[$key]['invented']=$true};Reject {Check-DocksEvidence $r $authors[$id] $map} ('unauthorized state '+$key)}
 $r=Copy-Case $id;$r.after.flags['invented']=$true;Reject {Check-DocksEvidence $r $authors[$id] $map} 'unauthorized flag'
 Reject {Check-DocksEvidence $rows[$id+'/space'] $authors[$id] @{} } 'missing firstguard'
 Reject {Check-DocksEvidence $rows[$id+'/space'] ($authors[$id]+' ') $map} 'author not exact source'
}
# Isolated shared-state guards: both absent or equal wrongtypes must NEVER
# acquire no-extra-state credit through Equal(null,null) or scalar equality.
foreach ($spec in $docks) {
 $id=$spec[0]
 foreach ($key in @('quests','investigation')) {
  $r=Copy-Case $id;[void]$r.before.Remove($key);[void]$r.after.Remove($key)
  Reject {Check-DocksEvidence $r $authors[$id] $map} ('both required states deleted '+$id+'/'+$key)
  foreach ($value in @($null,1,'same',$true,@())) {
   $r=Copy-Case $id;$r.before[$key]=$value;$r.after[$key]=$value
   Reject {Check-DocksEvidence $r $authors[$id] $map} ('same wrongtyped state '+$id+'/'+$key)
  }
  foreach ($side in @('before','after')) {
   $r=Copy-Case $id;[void]$r[$side].Remove($key)
   Reject {Check-DocksEvidence $r $authors[$id] $map} ('one required state deleted '+$id+'/'+$side+'/'+$key)
  }
 }
}
$r=Copy-Case;$r.effects.outcomes[0].fled=$true;Sync-Receipt $r;Reject {Check-DocksEvidence $r $authors.canal_endangered_porter $map} 'battle fled'
$r=Copy-Case;$r.effects.commands=@();Sync-Receipt $r;Reject {Check-DocksEvidence $r $authors.canal_endangered_porter $map} 'no normal battle commands'
foreach ($key in @('logical','physical','final_transform')) {
 $r=Copy-Case;$r.effects.commands[0].pointer[$key]='1 2';Sync-Receipt $r
 Reject {Check-DocksEvidence $r $authors.canal_endangered_porter $map} ('numeric array replaced by string '+$key)
 $r=Copy-Case;$r.effects.commands[0].pointer[$key]=@($r.effects.commands[0].pointer[$key]|Select-Object -SkipLast 1);Sync-Receipt $r
 Reject {Check-DocksEvidence $r $authors.canal_endangered_porter $map} ('wrong pointer length '+$key)
 foreach ($bad in @('1',$true,$null,[double]::NaN,[double]::PositiveInfinity,[double]::NegativeInfinity)) {
  $r=Copy-Case;$r.effects.commands[0].pointer[$key][0]=$bad;Sync-Receipt $r
  Reject {Check-DocksEvidence $r $authors.canal_endangered_porter $map} ('wrong pointer element type/nonfinite '+$key)
 }
}
$r=Copy-Case;$r.effects.original_payload.enemy_ids=@('luoyang_thug');Sync-Receipt $r;Reject {Check-DocksEvidence $r $authors.canal_endangered_porter $map} 'wrong authored enemy count'
$r=Copy-Case;$r.after.gold++;Reject {Check-DocksEvidence $r $authors.canal_endangered_porter $map} 'actual reward mismatch'
$r=Copy-Case;$r.after.inventory.weapon_id='unapproved';Reject {Check-DocksEvidence $r $authors.canal_endangered_porter $map} 'unapproved battle equipment'
$r=Copy-Case;$r.after.inventory.slots[0]['count']++;Reject {Check-DocksEvidence $r $authors.canal_endangered_porter $map} 'original item changed'
# Synthetic source-model reward fixtures, not newly observed RNG drops.
foreach ($count in @([long]1,[long]2)) {
 $r=Copy-Case;$r.after.inventory.slots+=@(@{item_id='blood_activator';instance_id='';count=$count})
 Check-DocksEvidence $r $authors.canal_endangered_porter $map;Test $true ('source-model bounded drop '+$count)
}
foreach ($count in @([long]0,[long]3,'1',$true)) {
 $r=Copy-Case;$r.after.inventory.slots+=@(@{item_id='blood_activator';instance_id='';count=$count})
 Reject {Check-DocksEvidence $r $authors.canal_endangered_porter $map} 'invalid reward count/type'
}
$r=Copy-Case 'canal_saved_porter';$r.normal_transition_receipt.source_scene_id='ch4_s4_ancient_temple';Reject {Check-DocksEvidence $r $authors.canal_saved_porter $map} 'approved origin is not target'
$r=Copy-Case 'canal_saved_porter';$r.normal_transition_receipt.actual_scene_id='ch4_s2_canal_docks';Reject {Check-DocksEvidence $r $authors.canal_saved_porter $map} 'wrong terminal target'
$r=Copy-Case 'canal_saved_porter';$r.scene_lifecycle.go_field_called_by_observer=$true;$r.effects.scene_transition=$r.scene_lifecycle;$r.normal_transition_receipt.scene_arrival=$r.scene_lifecycle;Sync-Receipt $r;Reject {Check-DocksEvidence $r $authors.canal_saved_porter $map} 'observer cannot inject arrival'
$r=Copy-Case 'canal_saved_porter';$r.normal_transition_receipt.actual_player_feet_px[0]+=1;Reject {Check-DocksEvidence $r $authors.canal_saved_porter $map} 'wrong actual approved arrival feet'
$r=Copy-Case 'canal_saved_porter';$r.after.quests['unearned_completion']=[long]2;Reject {Check-DocksEvidence $r $authors.canal_saved_porter $map} 'unearned quest completion'
$r=Copy-Case 'canal_old_soldier';$r.after.quests.q_ch4_side_07_hanjia_blade=[long]2;Reject {Check-DocksEvidence $r $authors.canal_old_soldier $map} 'accepted is not completed quest'
$r=Copy-Case 'canal_old_soldier';$r.effects['unapproved']=$true;Sync-Receipt $r;Reject {Check-DocksEvidence $r $authors.canal_old_soldier $map} 'nonbattle effects'
$badMap=@{};foreach ($key in $map.Keys) {$badMap[$key]=$map[$key]};$leaf=Source-Path 'res://data/dialogs/ch4_canal_battle.tres'
$badMap[$leaf]=@{path=$leaf;sha256=('0'*64);bytes=$map[$leaf].bytes}
Reject {Check-DocksEvidence $rows['canal_endangered_porter/space'] $authors.canal_endangered_porter $badMap} 'mutated bound source'
# Whole predicates must refuse incremental evidence even though private core
# accepts the six real cases. No fabricated successful whole-stage positive.
Reject {Known-Case @{complete=$false;failures=0;records=@{npcs=@($rows.Values)}} 'ch4_s2_canal_docks' 'canal_saved_porter' 'space' '' $map} 'private positives not whole Known-Case'
foreach ($line in @('WARNING: unknown','ERROR: actual','SCRIPT ERROR: actual','bare unknown')) {Reject {Check-FullStderr $line $map @{mode=@{phase='gameplay'};stage=@{complete=$true;failures=0}}} 'unknown/error/script stderr closed'}
$header="WARNING: [NPCNode] canal_saved_porter has no authored 'right' conversation facing; using mirror fallback"
foreach ($stage in @(@{complete=$false;failures=0},@{complete=$true;failures=1})) {Reject {Check-FullStderr $header $map @{mode=@{phase='gameplay'};stage=$stage}} 'partial/failed whole warning refused'}
foreach ($path in $evidence.Keys) {Test ((Hash $path) -ceq $evidence[$path]) 'original actual evidence unchanged'}
foreach ($res in $warningPins.Keys) {Bound-Leaf $res $map}
Test ((Hash $beforePath) -ceq $beforeSHA -and (Hash $builder) -ceq $builderSHA -and (Hash $original) -ceq $originalSHA -and (Hash $PSCommandPath) -ceq $selfSHA) 'all consumed evidence/consumer sources unchanged'
[ordered]@{scope='READ_ONLY_EXACT_THREE_DOCKS_WARNING_AND_SIX_ACTUAL_PRIVATE_CORE_CASES_NOT_WHOLE_OR_UI_APPROVAL';checks=$checks;failures=0;builder_sha256=$builderSHA;actual_incremental_private_core_cases=6;old_npc_bindings_retained=8;new_npc_bindings=3;ordinary_stack_counts=@(11,12);confirm_required=12;reading_stack_counts=@(14,15);source_model_drop_fixtures_not_actual=$true;full_known_case_positive_executed=$false;actual_six_runs_executed=$false;direct_reader_or_confirm_pointer_receipt_available=$false;field_credit=$false;four_direction_or_keyboard_focus_credit=$false;quest_completion_or_battle_music_credit=$false;approval_credit=$false}|ConvertTo-Json -Depth 5




