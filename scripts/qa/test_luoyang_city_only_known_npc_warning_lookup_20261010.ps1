param([string]$ProjectRoot='F:\Code\RPG_GAME')
# PURE classification/lookup regression only. Never executes the six-run builder,
# loads Field, signs approval, writes files, or grants actual warning-case credit.
$ErrorActionPreference='Stop'
$project=[IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
$game=Join-Path $project 'game'
$builder=Join-Path $ProjectRoot 'scripts/qa/prepare_luoyang_city_only_actual_six_approval_draft_retry4_20261010.ps1'
$expected='6F52116F533F37C1D785FE7B90336BBC09D423D76F0061A0B3C62FF291E4C861'
$first=(Get-FileHash -LiteralPath $builder -Algorithm SHA256).Hash
if ($first -cne $expected) { throw 'Actual builder source SHA differs' }
$selfFirst=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
$tokens=$null; $errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($builder,[ref]$tokens,[ref]$errors)
if ($errors.Count -ne 0) { throw 'Builder must parse before pure function extraction' }
# Load exact function text from the pinned builder AST, never its top-level body.
$names=@('Require','Hash','Source-Path','Bound-Leaf','Match-NPCWarningHeader','Resolve-NPCWarningBinding','Exact-Stack','Warning-Stack','Check-FullStderr')
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
 foreach ($mode in @('space','mouse')) {
  $stack=@(Warning-Stack $case[0] $mode)
  Exact-Stack $stack $stack
  Test ($stack[0] -ceq 'begin_conversation|res://scripts/field/npc_node.gd|184') ('stack bound header '+$case[0]+'/'+$mode)
  $mutated=@($stack); $mutated[0]='begin_conversation|res://scripts/field/npc_node.gd|185'
  Reject { Exact-Stack $mutated $stack } ('wrong concrete line '+$case[0]+'/'+$mode)
  Reject { Exact-Stack @($stack|Select-Object -SkipLast 1) $stack } ('missing stack frame '+$case[0]+'/'+$mode)
 }
 Test (-not (Match-NPCWarningHeader ($line+' extra')).Success) ('trailing bare text '+$case[0])
 Test (-not (Match-NPCWarningHeader ($line.Replace("'right'","'left'"))).Success) ('different warning literal '+$case[0])
}
foreach ($actor in @('unknown_actor','spar_yamen_patrol_extra','SPAR_YAMEN_CAPTAIN','')) {
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
Test ((Get-FileHash -LiteralPath $builder -Algorithm SHA256).Hash -ceq $first) 'builder source unchanged'
Test ((Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash -ceq $selfFirst) 'pure test source unchanged'
[ordered]@{scope='PURE_KNOWN_NPC_WARNING_CLASSIFICATION_LOOKUP_NOT_FIELD_OR_APPROVAL';checks=$checks;failures=0;builder_path=$builder;builder_sha256=$first;actual_seven_ids_tested=$true;actual_six_spar_binding_table_tested=$true;full_known_case_positive_executed=$false;actual_six_runs_executed=$false;field_credit=$false;approval_credit=$false}|ConvertTo-Json -Depth 4

