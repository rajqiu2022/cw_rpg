param([string]$ProjectRoot='F:\Code\RPG_GAME')
# Read-only actual-function regression. No six builder top-level, Field, writes,
# new UI observation, final approval or signature. Two fixed incremental cases
# exercise the private core only; a complete gameplay stage is still mandatory.
$ErrorActionPreference='Stop'
$project=[IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
$game=Join-Path $project 'game'
$builder=Join-Path $project 'scripts/qa/prepare_luoyang_city_only_actual_six_approval_draft_retry6_20261010.ps1'
$expected='A4A35BB57B63D7172D3E3527D1E81DFBE1CEFFFFA8DA14155B5DBFEF2F6FBA64'
$first=(Get-FileHash -LiteralPath $builder -Algorithm SHA256).Hash
if ($first -cne $expected) { throw 'Actual retry6 builder source differs' }
$selfFirst=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
$tokens=$null; $errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($builder,[ref]$tokens,[ref]$errors)
if ($errors.Count -ne 0) { throw 'Actual retry6 must parse before function extraction' }
$functions=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst]},$true))
foreach ($function in $functions) { Invoke-Expression $function.Extent.Text }
foreach ($variable in @('$warningPins','$fixed','$readingSpecs','$readingPins','$sparSpecs')) {
 $assignments=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.AssignmentStatementAst] -and $node.Left.Extent.Text -ceq $variable},$true))
 if ($assignments.Count -ne 1) { throw "Missing/duplicate actual table $variable" }
 Invoke-Expression $assignments[0].Extent.Text
}
$stackSourceCache=@{}
$checks=0
function Test([bool]$ok,[string]$label) { $script:checks++; if (-not $ok) { throw "READING UNIT FAIL: $label" } }
function Reject([scriptblock]$call,[string]$label) { $rejected=$false; try { & $call|Out-Null } catch { $rejected=$true }; Test $rejected $label }
# Independent four original tuples, not values derived from the consumer table.
$expectedSpecs=@(
 @('ch4_s1_luoyang_yamen','hanjia_rubbing','discover_readable:hanjia_water_rule_rubbing:found_hanjia_water_rule_rubbing','hanjia_water_rule_rubbing','found_hanjia_water_rule_rubbing'),
 @('ch4_s3_luoyang_market','armory_old_record','discover_readable:luoyang_quench_record:found_luoyang_quench_record','luoyang_quench_record','found_luoyang_quench_record'),
 @('ch4_s3_luoyang_market','paper_birdseal','discover_readable:zhouju_birdseal_copy:found_zhouju_birdseal_copy','zhouju_birdseal_copy','found_zhouju_birdseal_copy'),
 @('ch4_s3_luoyang_market','xuantong_note','discover_readable:xuantong_scale_weave_note:found_xuantong_scale_weave_note','xuantong_scale_weave_note','found_xuantong_scale_weave_note')
)
foreach ($spec in $expectedSpecs) { Test (Equal (Resolve-ReadingBinding $spec[0] $spec[1]) $spec) ('exact reading binding '+$spec[1]) }
foreach ($pair in @(@('ch4_s1_luoyang_yamen','hanjia_water_rule'),@('ch4_s3_luoyang_market','unknown'),@('ch4_s0_luoyang_gate','hanjia_rubbing'))) { Reject { Resolve-ReadingBinding $pair[0] $pair[1] } 'unknown/cross-scene readable rejected' }
Reject { Resolve-ReadingBinding 1 'hanjia_rubbing' } 'numeric scene'
Reject { Resolve-ReadingBinding 'ch4_s1_luoyang_yamen' $null } 'null source id'
$originalSpecs=$readingSpecs
$readingSpecs=@($originalSpecs|ForEach-Object {,@($_)}); $readingSpecs[1]=@($readingSpecs[0])
Reject { Resolve-ReadingBinding 'ch4_s1_luoyang_yamen' 'hanjia_rubbing' } 'duplicate fixed specification'
$readingSpecs=$originalSpecs
# Exact independent original 14/15 frame order and source/function/line.
$head=@('open_item|res://scripts/ui/reading_panel.gd|42','_open_reading|res://scripts/ui/inventory_panel.gd|704','_on_item_read_requested|res://scripts/ui/inventory_panel.gd|694','resolve_action|res://scripts/autoload/scene_router.gd|1267','_resolve_field_action|res://scripts/field/field_walkable_controller.gd|2692','_on_trigger_zone_entered|res://scripts/field/field_walkable_controller.gd|2531')
$tail=@('move_to|res://tests/helpers/joint_v15_wall_v5_city_physical_alpha_probe.gd|133','follow|res://tests/helpers/v15_input_driver.gd|91','drive|res://tests/helpers/v15_input_driver.gd|80','completed_actor_stage|res://tests/helpers/v15_input_driver.gd|18')
$expectedStacks=@{
 space=@($head)+@('_on_player_interacted|res://scripts/field/field_walkable_controller.gd|2563','_unhandled_input|res://scripts/field/player.gd|367','key|res://tests/helpers/v15_input_driver.gd|27','_normal_action_case|res://tests/helpers/joint_v15_v8_city_authored_transition_lifecycle_phase.gd|35')+@($tail)
 mouse=@($head)+@('_dispatch_pointer_interaction|res://scripts/field/field_walkable_controller.gd|3703','_unhandled_input|res://scripts/field/field_walkable_controller.gd|3730','pointer|res://tests/helpers/v15_input_driver.gd|40','click_entity|res://tests/helpers/joint_v15_wall_v5_city_physical_alpha_probe.gd|879','_normal_action_case|res://tests/helpers/joint_v15_v8_city_authored_transition_lifecycle_phase.gd|41')+@($tail)
}
foreach ($mode in @('space','mouse')) {
 $stack=@(Reading-Stack $mode); Exact-Stack $stack $expectedStacks[$mode]
 Test ($stack.Count -eq $(if ($mode -ceq 'space') {14} else {15})) ('complete Reading stack '+$mode)
 for ($n=0;$n -lt $stack.Count;$n++) {
  $mutated=@($stack); $mutated[$n]=$mutated[$n]+'0'
  Reject { Exact-Stack $mutated $expectedStacks[$mode] } ('wrong fullstack frame '+$mode+'/'+$n)
 }
 Reject { Exact-Stack @($stack|Select-Object -SkipLast 1) $expectedStacks[$mode] } ('missing fullstack '+$mode)
 Reject { Exact-Stack (@($stack)+@($stack[-1])) $expectedStacks[$mode] } ('extra fullstack '+$mode)
}
Reject { Reading-Stack 'unknown' } 'unknown mode'
$beforePath=Join-Path $project 'game/build/joint_world_luoyang_20261003_qa/446_luoyang_original_candidate_gameplay_headless_20261010/before.json'
$beforeSHA='9358DB6A0696E4B94657D530C235C4C8749EF147EDC692EE24446F437976D95F'
Test ((Hash $beforePath) -ceq $beforeSHA) 'fixed 446 fresh firstguard'
$before=Get-Content -LiteralPath $beforePath -Raw|ConvertFrom-Json -AsHashtable -Depth 100
$map=@{}; foreach ($row in $before.sources) { $map[(Source-Path $row.path)]=$row }
foreach ($res in $readingPins.Keys) { Bound-ReadingLeaf $res $map; Test ($map[(Source-Path $res)].sha256 -ieq $readingPins[$res]) ('actual bound reading source '+$res) }
foreach ($mode in @('space','mouse')) { foreach ($frame in $expectedStacks[$mode]) { $parts=$frame.Split('|'); Check-ConcreteStack $parts[0] $parts[1] ([int]$parts[2]) $map } }
$caseRoot=Join-Path $project 'game/build/joint_world_luoyang_20261003_qa/luoyang_enclosure_v11_city_only_1791566856_1550257_48284'
$casePins=@{space='F8D603D7211F59927DCC8503175DE807C5A51EBF746B9B23920D351F76CA8632';mouse='811BC0206841B6D29D0327C0DD727948146245881662972540F5AAF3D629A5B7'}
$caseRows=@{}; $paths=@{}
foreach ($mode in @('space','mouse')) {
 $path=Join-Path $caseRoot ('interactions_ch4_s1_luoyang_yamen_hanjia_rubbing_'+$mode+'.json')
 Test ((Hash $path) -ceq $casePins[$mode]) ('fixed incremental actual Reading '+$mode)
 $row=Get-Content -LiteralPath $path -Raw|ConvertFrom-Json -AsHashtable -Depth 100
 Check-ReadingEvidence $row $map
 Test ($row.mode -ceq $mode) ('actual core predicate '+$mode)
 $caseRows[$mode]=$row; $paths[$mode]=$path
}
function Copy-ActualReading([string]$mode='space') { return ($caseRows[$mode]|ConvertTo-Json -Depth 100|ConvertFrom-Json -AsHashtable -Depth 100) }
foreach ($key in @('source_scene_id','source_id','mode','action','dialog_id')) {
 $row=Copy-ActualReading; $row[$key]=1
 Reject { Check-ReadingEvidence $row $map } ('wrongtyped '+$key)
}
$row=Copy-ActualReading; $row.source_scene_id='ch4_s3_luoyang_market'
Reject { Check-ReadingEvidence $row $map } 'cross-scene'
$row=Copy-ActualReading; $row.action='dialog:huilan_openworld_water_rule'
Reject { Check-ReadingEvidence $row $map } 'wrong action not water-rule attribution'
$row=Copy-ActualReading; $row.after.inventory.slots[-1].item_id='luoyang_quench_record'
Reject { Check-ReadingEvidence $row $map } 'wrong actual item'
foreach ($count in @(0,2,'1',$true)) {
 $row=Copy-ActualReading; $row.after.inventory.slots[-1]['count']=$count
 Reject { Check-ReadingEvidence $row $map } 'wrong singleton count/type'
}
$row=Copy-ActualReading; $row.after.inventory.slots[-1].instance_id=''
Reject { Check-ReadingEvidence $row $map } 'missing actual singleton instance'
$row=Copy-ActualReading; $row.after.inventory.slots=@($row.after.inventory.slots)+@($row.after.inventory.slots[-1])
Reject { Check-ReadingEvidence $row $map } 'extra item'
$row=Copy-ActualReading; $row.after.flags.found_hanjia_water_rule_rubbing=$false
Reject { Check-ReadingEvidence $row $map } 'missing actual discovery flag'
$row=Copy-ActualReading; $row.before.flags.found_hanjia_water_rule_rubbing=$true
Reject { Check-ReadingEvidence $row $map } 'already discovered original before'
$row=Copy-ActualReading; $row.after.flags['invented']=$true
Reject { Check-ReadingEvidence $row $map } 'extra flag'
foreach ($key in @('training','gold','reputation')) {
 $row=Copy-ActualReading; $row.after[$key]++
 Reject { Check-ReadingEvidence $row $map } ('extra scalar state '+$key)
}
foreach ($key in @('quests','investigation','bounty','sparring')) {
 $row=Copy-ActualReading; $row.after[$key]['invented']=$true
 Reject { Check-ReadingEvidence $row $map } ('extra state '+$key)
}
$row=Copy-ActualReading; $row.effects['invented']=$true
Reject { Check-ReadingEvidence $row $map } 'effects nonempty'
$row=Copy-ActualReading; $row.effects=@()
Reject { Check-ReadingEvidence $row $map } 'effects wrongtype'
$row=Copy-ActualReading; $row.dialog_nodes=@(@{id='invented'})
Reject { Check-ReadingEvidence $row $map } 'unexpected dialogue node'
foreach ($key in @('complete','live_field','live_player','bound_field_is_current')) {
 $row=Copy-ActualReading; $row.normal_transition_receipt[$key]=$false
 Reject { Check-ReadingEvidence $row $map } ('missing actual receipt '+$key)
}
$row=Copy-ActualReading; $row.normal_transition_receipt.original_action='invented'
Reject { Check-ReadingEvidence $row $map } 'wrong normal action receipt'
$row=Copy-ActualReading 'mouse'; $row.actual_input.source_sprite_alive_after_input=$true
Reject { Check-ReadingEvidence $row $map } 'hide-source inference not NPC alive assertion'
$row=Copy-ActualReading 'mouse'; $row.actual_input.source_identity_before_input.texture_source_sha256=('0'*64)
Reject { Check-ReadingEvidence $row $map } 'wrong actual PNG SHA'
$row=Copy-ActualReading 'mouse'; $row.actual_input.source_identity_before_input.sprite_path='/root/FieldWalkable/WorldContainer/ActorLayer/SceneObject_unknown'
Reject { Check-ReadingEvidence $row $map } 'wrong actual source object identity'
Reject { Check-ReadingEvidence $caseRows.space @{} } 'missing fresh firstguard'
$badMap=@{}; foreach ($key in $map.Keys) {$badMap[$key]=$map[$key]}; $leaf=Source-Path 'res://scripts/ui/reading_panel.gd'
$badMap[$leaf]=@{path=$leaf;sha256=('0'*64);bytes=$map[$leaf].bytes}
Reject { Check-ReadingEvidence $caseRows.space $badMap } 'changed source firstguard'
# Full entry refuses incremental/failed/wrong stage and unknown focus. No fake
# complete stage or fabricated direct reader/modal/pointer receipts are installed.
$focus="WARNING: This control can't grab focus. Use set_focus_mode() and set_focus_behavior_recursive() to allow a control to get focus."
foreach ($stage in @(@{complete=$false;failures=0},@{complete=$true;failures=1})) {
 Reject { Check-FullStderr $focus $map @{mode=@{phase='gameplay'};stage=$stage} } 'partial/failed stage cannot classify Reading'
}
Reject { Known-ReadingCase @{complete=$false;failures=0;records=@{interactions=@($caseRows.space,$caseRows.mouse)}} $expectedSpecs[0] 'space' $map } 'private core positives not full Known-ReadingCase'
Reject { Check-FullStderr $focus $map @{mode=@{phase='geometry'};stage=@{complete=$true;failures=0}} } 'focus wrong phase'
foreach ($line in @('WARNING: unknown focus','ERROR: actual','SCRIPT ERROR: actual','bare unknown')) {
 Reject { Check-FullStderr $line $map @{mode=@{phase='gameplay'};stage=@{complete=$true;failures=0}} } 'unknown stderr refused'
}
# These synthetic malformed blocks exercise real full parser refusal, not actual
# whole case approval. They cannot fill a six endpoint or acquire UI credit.
$block=@($focus,'   at: grab_focus (scene/gui/control.cpp:2373)','   GDScript backtrace (most recent call first):')
for ($n=0;$n -lt $expectedStacks.space.Count;$n++) { $p=$expectedStacks.space[$n].Split('|'); $block+=('       [{0}] {1} ({2}:{3})' -f $n,$p[0],$p[1],$p[2]) }
Reject { Check-FullStderr ($block -join "`n") $map @{mode=@{phase='gameplay'};stage=@{complete=$true;failures=0;records=@{interactions=@($caseRows.space,$caseRows.mouse)}}} } 'only two actual Reading rows cannot fill eight'
$badBlock=@($block); $badBlock[3]=$badBlock[3].Replace('open_item','unknown_focus')
Reject { Check-FullStderr ($badBlock -join "`n") $map @{mode=@{phase='gameplay'};stage=@{complete=$true;failures=0}} } 'unknown focus fullstack'
foreach ($mode in @('space','mouse')) { Test ((Hash $paths[$mode]) -ceq $casePins[$mode]) ('original actual row unchanged '+$mode) }
foreach ($res in $readingPins.Keys) { Bound-ReadingLeaf $res $map }
Test ((Hash $beforePath) -ceq $beforeSHA) 'firstguard evidence unchanged'
Test ((Hash $builder) -ceq $first -and (Hash $PSCommandPath) -ceq $selfFirst) 'both executing source files unchanged'
[ordered]@{scope='READ_ONLY_READING_CLASSIFICATION_AND_TWO_INCREMENTAL_ACTUAL_CORE_CASES_NOT_WHOLE_OR_UI_APPROVAL';checks=$checks;failures=0;builder_path=$builder;builder_sha256=$first;actual_core_cases=2;original_fixed_discoveries=4;ordered_complete_reading_required=8;reading_stack_counts=@(14,15);direct_reader_visible_or_close_pointer_receipt_available=$false;full_known_reading_case_positive_executed=$false;actual_six_runs_executed=$false;field_credit=$false;reader_focus_cancel_or_full_ui_credit=$false;approval_credit=$false}|ConvertTo-Json -Depth 5

