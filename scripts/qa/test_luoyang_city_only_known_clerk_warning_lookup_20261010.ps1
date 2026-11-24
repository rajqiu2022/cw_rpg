param([string]$ProjectRoot='F:\Code\RPG_GAME')
# PURE classification/lookup regression only. Never executes the six-run builder,
# loads Field, signs approval, writes files, or grants actual warning-case credit.
$ErrorActionPreference='Stop'
$project=[IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
$game=Join-Path $project 'game'
$builder=Join-Path $ProjectRoot 'scripts/qa/prepare_luoyang_city_only_actual_six_approval_draft_retry5_20261010.ps1'
$expected='29DDFD5CB0BFDCDAC7E0E241CF828233F7C7069BEF7DD1EEFF71AD673C9D99CF'
$first=(Get-FileHash -LiteralPath $builder -Algorithm SHA256).Hash
if ($first -cne $expected) { throw 'Actual builder source SHA differs' }
$selfFirst=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
$tokens=$null; $errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($builder,[ref]$tokens,[ref]$errors)
if ($errors.Count -ne 0) { throw 'Builder must parse before pure function extraction' }
# Load exact function text from the pinned builder AST, never its top-level body.
$names=@('Require','Hash','Source-Path','Equal','Check-Bools','Check-ClerkEvidence','Bound-Leaf','Match-NPCWarningHeader','Resolve-NPCWarningBinding','Exact-Stack','Warning-Stack','Check-FullStderr')
foreach ($name in $names) {
 $found=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name},$true))
 if ($found.Count -ne 1) { throw "Missing/duplicate actual function: $name" }
 Invoke-Expression $found[0].Extent.Text
}
$specAssignment=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.AssignmentStatementAst] -and $node.Left.Extent.Text -ceq '$sparSpecs'},$true))
if ($specAssignment.Count -ne 1) { throw 'Fixed actual spar table absent/nonunique' }
Invoke-Expression $specAssignment[0].Extent.Text
foreach ($variable in @('$warningPins','$fixed')) {
 $assignment=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.AssignmentStatementAst] -and $node.Left.Extent.Text -ceq $variable},$true))
 if ($assignment.Count -ne 1) { throw "Missing/duplicate actual source-pin table: $variable" }
 Invoke-Expression $assignment[0].Extent.Text
}
$originalSpecs=$sparSpecs
$checks=0
function Test([bool]$ok,[string]$label) { $script:checks++; if (-not $ok) { throw "PURE FAIL: $label" } }
function Reject([scriptblock]$call,[string]$label) {
 $rejected=$false
 try { & $call | Out-Null } catch { $rejected=$true }
 Test $rejected $label
}
# Independent expected tuples. Production table supplies actual lookup, not oracle.
$cases=@(
 @('luoyang_gate_sergeant','ch4_s0_luoyang_gate',''),
 @('ch8_luoyang_final_clerk','ch4_s1_luoyang_yamen',''),
 @('spar_yamen_patrol','ch4_s1_luoyang_yamen','spar:yamen_patrol:luoyang_patrol:府衙巡捕:30:7'),
 @('spar_yamen_captain','ch4_s1_luoyang_yamen','spar:yamen_captain:boss_luoyang_captain:府衙都头:42:10'),
 @('spar_luoyang_shen_guard','ch4_s3_luoyang_market','spar:luoyang_shen_guard:ch2_tournament_guard:沈家护院总管:18:4'),
 @('spar_luoyang_examiner','ch4_s3_luoyang_market','spar:luoyang_examiner:wulin_examiner:大会考校官:24:6'),
 @('spar_luoyang_blademaster','ch4_s3_luoyang_market','spar:luoyang_blademaster:wandering_blademaster:流浪刀客:60:15'),
 @('spar_luoyang_patrol','ch4_s3_luoyang_market','spar:luoyang_patrol:luoyang_patrol:洛阳巡捕:32:8')
)
foreach ($case in $cases) {
 $line="WARNING: [NPCNode] $($case[0]) has no authored 'right' conversation facing; using mirror fallback"
 $m=Match-NPCWarningHeader $line
 Test ($m.Success -and $m.Groups[1].Value -ceq $case[0]) ('exact header '+$case[0])
 $bound=Resolve-NPCWarningBinding $m.Groups[1].Value
 Test ($bound.scene -ceq $case[1] -and $bound.action -ceq $case[2]) ('exact scene/action '+$case[0])
 if ($case[0] -ceq 'ch8_luoyang_final_clerk') { Test ($bound.dialog -ceq 'ch8_aftermath_luoyang') 'exact clerk dialog binding' }
 foreach ($mode in @('space','mouse')) {
  $stack=@(Warning-Stack $case[0] $mode)
  Exact-Stack $stack $stack
  Test ($stack[0] -ceq 'begin_conversation|res://scripts/field/npc_node.gd|184') ('stack bound header '+$case[0]+'/'+$mode)
  if ($case[0] -ceq 'ch8_luoyang_final_clerk') { Test ($stack[1] -ceq '_on_npc_interacted|res://scripts/field/field_walkable_controller.gd|2750' -and $stack[2] -ceq 'try_interact|res://scripts/field/npc_node.gd|438') ('clerk ordinary not spar fullstack '+$mode) }
  $mutated=@($stack); $mutated[0]='begin_conversation|res://scripts/field/npc_node.gd|185'
  Reject { Exact-Stack $mutated $stack } ('wrong concrete line '+$case[0]+'/'+$mode)
  Reject { Exact-Stack @($stack|Select-Object -SkipLast 1) $stack } ('missing stack frame '+$case[0]+'/'+$mode)
 }
 Test (-not (Match-NPCWarningHeader ($line+' extra')).Success) ('trailing bare text '+$case[0])
 Test (-not (Match-NPCWarningHeader ($line.Replace("'right'","'left'"))).Success) ('different warning literal '+$case[0])
}
foreach ($actor in @('unknown_actor','spar_yamen_patrol_extra','SPAR_YAMEN_CAPTAIN','','canal_endangered_porter','canal_saved_porter','canal_old_soldier','feng_yanqiu_ch4','luoyang_paper_scholar','luoyang_poetry_host','luoyang_armorer')) {
 Test (-not (Match-NPCWarningHeader "WARNING: [NPCNode] $actor has no authored 'right' conversation facing; using mirror fallback").Success) ('unknown header '+$actor)
 Reject { Resolve-NPCWarningBinding $actor } ('unknown binding '+$actor)
}
Reject { Resolve-NPCWarningBinding $null } 'null actor'
Reject { Resolve-NPCWarningBinding 1 } 'numeric actor'
Reject { Match-NPCWarningHeader $null } 'null header'
Reject { Match-NPCWarningHeader @('WARNING:') } 'array header'
# Warm successful lookup cannot mask a malformed/missing/duplicate fixed table.
[void](Resolve-NPCWarningBinding 'spar_yamen_captain')
$sparSpecs=@($originalSpecs|ForEach-Object { ,@($_) })
$sparSpecs[1]=@($sparSpecs[0])
Reject { Resolve-NPCWarningBinding 'spar_yamen_patrol' } 'duplicate actor fixed specs'
Reject { Resolve-NPCWarningBinding 'spar_yamen_captain' } 'missing actor fixed specs'
$sparSpecs=@($originalSpecs|ForEach-Object { ,@($_) })
$sparSpecs[1]=@($sparSpecs[1][0],$sparSpecs[1][1],1)
Reject { Resolve-NPCWarningBinding 'spar_yamen_captain' } 'wrong typed action'
$sparSpecs=@($originalSpecs|Select-Object -SkipLast 1)
Reject { Resolve-NPCWarningBinding 'spar_yamen_captain' } 'missing fixed table row'
$sparSpecs=$originalSpecs
Test ((Resolve-NPCWarningBinding 'spar_yamen_captain').scene -ceq 'ch4_s1_luoyang_yamen') 'restored owned fixture table'
# Real full-stderr entry rejects unknown/error/script and partial gameplay before
# any source or case inference. No mocks of Known-Case/Bound-Leaf are installed.
foreach ($line in @('WARNING: unknown','ERROR: actual error','SCRIPT ERROR: actual script error','bare unknown line')) {
 Reject { Check-FullStderr $line @{} @{mode=@{phase='gameplay'};stage=@{complete=$true;failures=0}} } ('full entry unknown '+$line)
}
$captainLine="WARNING: [NPCNode] spar_yamen_captain has no authored 'right' conversation facing; using mirror fallback"
Reject { Check-FullStderr $captainLine @{} @{mode=@{phase='gameplay'};stage=@{complete=$false;failures=0}} } 'incremental actual captain not whole stage'
Reject { Check-FullStderr $captainLine @{} @{mode=@{phase='geometry'};stage=@{complete=$true;failures=0}} } 'wrong stage refuses known header'
Reject { Check-FullStderr $captainLine @{} @{mode=@{phase='gameplay'};stage=@{complete=$true;failures=1}} } 'failed gameplay refuses known header'
Reject { Check-FullStderr $captainLine @{} @{mode=@{phase='gameplay'};stage=@{complete=$true;failures=0}} } 'missing actual firstguard refuses known header'
# Incremental ORIGINAL actual clerk evidence, not a fabricated Known-Case/stage.
# This only exercises Check-ClerkEvidence, which the real full Known-Case calls
# AFTER its unchanged actual input/UI/current Field/source checks.
$beforePath=Join-Path $ProjectRoot 'game/build/joint_world_luoyang_20261003_qa/446_luoyang_original_candidate_gameplay_headless_20261010/before.json'
$beforeSHA='9358DB6A0696E4B94657D530C235C4C8749EF147EDC692EE24446F437976D95F'
Test ((Hash $beforePath) -ceq $beforeSHA) 'fixed actual 446 firstguard evidence'
$before=Get-Content -LiteralPath $beforePath -Raw|ConvertFrom-Json -AsHashtable -Depth 100
$map=@{}; foreach ($row in $before.sources) { $map[(Source-Path $row.path)]=$row }
$legacy='res://data/maps/luoyang_v3_legacy/ch4_s1_luoyang_yamen_scene.tres'
Bound-Leaf $legacy $map
Test ((Hash (Source-Path $legacy)) -ceq '7BED5D322D583C9C7BF4E392F3F4C75FFB0577DB24BB9E6237A4AE3AA0808B01') 'exact original clerk source'
Bound-Leaf 'res://scripts/field/npc_node.gd' $map
$text=[IO.File]::ReadAllText((Source-Path $legacy))
$authors=@([regex]::Matches($text,'\{[^\r\n{}]*"npc_id"\s*:\s*"ch8_luoyang_final_clerk"[^\r\n{}]*\}'))
Test ($authors.Count -eq 1) 'one original author'
$author=$authors[0].Value
$caseRoot=Join-Path $ProjectRoot 'game/build/joint_world_luoyang_20261003_qa/luoyang_enclosure_v11_city_only_1791566856_1550257_48284'
$casePins=@{space='FF4AE08A3C48E4D2B76BFC900A79C2EB7FD843083E0083ACB224215C18BE0899';mouse='31132686CD387F61126E002F2CC016B1D61753C56B05116CA031F05BCCEEA03E'}
$caseRows=@{}; $paths=@{}
foreach ($mode in @('space','mouse')) {
 $path=Join-Path $caseRoot ('npcs_ch4_s1_luoyang_yamen_ch8_luoyang_final_clerk_'+$mode+'.json')
 Test ((Hash $path) -ceq $casePins[$mode]) ('fixed actual incremental clerk '+$mode)
 $row=Get-Content -LiteralPath $path -Raw|ConvertFrom-Json -AsHashtable -Depth 100
 Check-ClerkEvidence $row $author $map
 Test ($row.mode -ceq $mode) ('actual incremental clerk predicate '+$mode)
 $caseRows[$mode]=$row; $paths[$mode]=$path
}
function Copy-ActualClerk { return ($caseRows.space|ConvertTo-Json -Depth 100|ConvertFrom-Json -AsHashtable -Depth 100) }
foreach ($field in @('source_scene_id','action','dialog_id')) {
 $row=Copy-ActualClerk; $row[$field]=1
 Reject { Check-ClerkEvidence $row $author $map } ('typed clerk '+$field)
}
$row=Copy-ActualClerk; $row.dialog_id='wrong_dialog'
Reject { Check-ClerkEvidence $row $author $map } 'wrong clerk dialog'
$row=Copy-ActualClerk; $row.source_scene_id='ch4_s3_luoyang_market'
Reject { Check-ClerkEvidence $row $author $map } 'wrong clerk scene'
$row=Copy-ActualClerk; $row.mode='keyboard_unknown'
Reject { Check-ClerkEvidence $row $author $map } 'unknown clerk mode'
$row=Copy-ActualClerk; $row.action='spar:invented'
Reject { Check-ClerkEvidence $row $author $map } 'nonempty clerk action'
Reject { Check-ClerkEvidence $caseRows.space ($author.Replace('"dialog_id":"ch8_aftermath_luoyang"','"dialog_id":"wrong"')) $map } 'wrong original author dialog'
Reject { Check-ClerkEvidence $caseRows.space ($author.TrimEnd('}')+',"conversation_base_facing":"left"}') $map } 'wrong explicit author facing'
Reject { Check-ClerkEvidence $caseRows.space ($author.TrimEnd('}')+',"interaction_action":""}') $map } 'explicit action field forbidden'
$row=Copy-ActualClerk; $row.dialog_nodes=@($row.dialog_nodes|Select-Object -SkipLast 1)
Reject { Check-ClerkEvidence $row $author $map } 'missing actual node'
$row=Copy-ActualClerk; $row.dialog_nodes[1].id='ch8_aftermath_luoyang/start'
Reject { Check-ClerkEvidence $row $author $map } 'duplicate/out-of-order actual node'
$row=Copy-ActualClerk; $row.dialog_nodes[0].Remove('source_path')
Reject { Check-ClerkEvidence $row $author $map } 'missing actual node source'
$row=Copy-ActualClerk; $row.dialog_nodes[0].source_sha256=('0'*64)
Reject { Check-ClerkEvidence $row $author $map } 'wrong actual node source SHA'
$row=Copy-ActualClerk; $row.battle_lifecycle.terminal_on_end='battle:invented'
Reject { Check-ClerkEvidence $row $author $map } 'wrong original nonbattle terminal'
$row=Copy-ActualClerk; $row.battle_lifecycle.actual_battle_ui=$true
Reject { Check-ClerkEvidence $row $author $map } 'actual battle not original clerk path'
$row=Copy-ActualClerk; $row.after.flags.ch8_aftermath_luoyang_done=$false
Reject { Check-ClerkEvidence $row $author $map } 'completion flag absent'
$row=Copy-ActualClerk; $row.before.flags.ch8_aftermath_luoyang_done=$true
Reject { Check-ClerkEvidence $row $author $map } 'original before already done'
foreach ($field in @('ch8_joint_trial_active','ch8_single_party_custody_forbidden')) {
 $row=Copy-ActualClerk; $row.after.investigation.city_outcomes.luoyang[$field]=$false
 Reject { Check-ClerkEvidence $row $author $map } ('missing actual city outcome '+$field)
}
foreach ($field in @('training','gold','reputation')) {
 $row=Copy-ActualClerk; $row.after[$field]=$row.before[$field]+1
 Reject { Check-ClerkEvidence $row $author $map } ('unapproved state '+$field)
}
$row=Copy-ActualClerk; $row.after.inventory['invented']=$true
Reject { Check-ClerkEvidence $row $author $map } 'unapproved inventory change'
foreach ($field in @('quests','bounty','sparring')) {
 $row=Copy-ActualClerk; $row.after[$field]['invented']=$true
 Reject { Check-ClerkEvidence $row $author $map } ('unapproved state '+$field)
}
$row=Copy-ActualClerk; $row.effects['invented']=$true
Reject { Check-ClerkEvidence $row $author $map } 'unapproved nonempty effects'
$row=Copy-ActualClerk; $row.effects=@()
Reject { Check-ClerkEvidence $row $author $map } 'wrong typed effects array'
$row=Copy-ActualClerk; $row.after.flags['invented']=$true
Reject { Check-ClerkEvidence $row $author $map } 'unapproved flag change'
$row=Copy-ActualClerk; $row.after.investigation['invented']=$true
Reject { Check-ClerkEvidence $row $author $map } 'unapproved investigation change'
Reject { Check-ClerkEvidence $caseRows.space $author @{} } 'missing actual source firstguard'
$clerkLine="WARNING: [NPCNode] ch8_luoyang_final_clerk has no authored 'right' conversation facing; using mirror fallback"
Reject { Check-FullStderr $clerkLine $map @{mode=@{phase='gameplay'};stage=@{complete=$false;failures=0}} } 'clerk incremental case cannot substitute whole stage'
foreach ($mode in @('space','mouse')) { Test ((Hash $paths[$mode]) -ceq $casePins[$mode]) ('original actual clerk record unchanged '+$mode) }
Test ((Hash $beforePath) -ceq $beforeSHA) 'actual firstguard file unchanged'

Test ((Get-FileHash -LiteralPath $builder -Algorithm SHA256).Hash -ceq $first) 'builder source unchanged'
Test ((Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash -ceq $selfFirst) 'pure test source unchanged'
[ordered]@{scope='PURE_CLASSIFICATION_PLUS_INCREMENTAL_CLERK_EVIDENCE_NOT_FIELD_WHOLE_OR_APPROVAL';checks=$checks;failures=0;builder_path=$builder;builder_sha256=$first;actual_eight_ids_tested=$true;incremental_actual_clerk_predicate_cases=2;actual_six_spar_binding_table_tested=$true;full_known_case_positive_executed=$false;actual_six_runs_executed=$false;field_credit=$false;approval_credit=$false}|ConvertTo-Json -Depth 4
