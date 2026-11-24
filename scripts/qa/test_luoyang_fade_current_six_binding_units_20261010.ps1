param([string]$ProjectRoot='F:\Code\RPG_GAME')
# Private source-bound classification tests on retained actual ROOT455 evidence.
# Does not run six-builder top-level, create a draft, sign or change game files.
$ErrorActionPreference='Stop'
$project=[IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
$game=Join-Path $project 'game';$domain=Join-Path $game 'build\joint_world_luoyang_20261003_qa'
$core=Join-Path $project 'scripts/qa/prepare_luoyang_city_only_actual_six_approval_draft_retry12_20261010.ps1'
$coreSHA='EB04540285AE4EA60E806FDECA61D544E63F1E372B1F3255E7C75B2C890A4922'
if ((Get-FileHash -LiteralPath $core).Hash -cne $coreSHA) { throw 'Unit bound consumer SHA differs' }
$tokens=$null;$parseErrors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($core,[ref]$tokens,[ref]$parseErrors)
if ($parseErrors.Count -ne 0) { throw 'Unit bound consumer parse failed' }
# Definitions and the eight exact top-level tables only, never an executable
# top-level consumer loop or a nested same-name assignment.
foreach ($function in $ast.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst]},$true)) { Invoke-Expression $function.Extent.Text }
foreach ($name in @('$entry','$engineSHA','$ids','$fixed','$warningPins','$sparSpecs','$readingSpecs','$readingPins')) {
 $assignments=@($ast.EndBlock.Statements|Where-Object {$_ -is [Management.Automation.Language.AssignmentStatementAst] -and $_.Left.Extent.Text -ceq $name})
 if ($assignments.Count -ne 1) { throw 'Missing/duplicate exact top-level source table' }
 Invoke-Expression $assignments[0].Extent.Text
}
$evidence=@{};$allSources=@{};$stackSourceCache=@{}
$wrapper=Join-Path $domain '455_be0_strict4624_candidate_save_headless_20261010'
$beforePath=Join-Path $wrapper 'before.json';$afterPath=Join-Path $wrapper 'after.json';$stderrPath=Join-Path $wrapper 'stderr.log'
$resultPath=Join-Path $domain 'luoyang_enclosure_v11_city_only_1791582728_1556922_33924/result.json'
$actualPins=@{
 $beforePath='A54A387722499B7A617FE2F05D9D74A681821F202A61A64980EA49B695492619'
 $afterPath='93043AD4AC2704740F8F4834C4F58F2B555969F52760E0C4432DF7720472ECED'
 $stderrPath='1554F6378216C6C2AF3F359A9AC0CF96E504D7469CCFA38C9A86CAA7A3492AC7'
 $resultPath='F4B1B83ABF95FA4ABEFA7A167248FE083A400E1433AD9CF00D487F1DAF611507'
}
foreach ($path in $actualPins.Keys) { Require ((Hash $path) -ceq $actualPins[$path]) 'Actual retained455 evidence SHA differs' }
$before=Read-Record $beforePath;$after=Read-Record $afterPath;$result=Read-Record $resultPath
Require ($after.actual_os_exit -eq 0 -and $after.source_changes.Count -eq 0 -and $after.player_file_changes.Count -eq 0 -and $result.checks -eq 24 -and $result.failures -eq 0 -and $result.stage.checks -eq 191 -and $result.stage.failures -eq 0) 'Not the fixed complete actual455 save evidence'
$map=@{};foreach ($row in $before.sources) { [void](Add-Source $row $map) }
$stderr=[IO.File]::ReadAllText($stderrPath)
$header='WARNING: [SceneRouter] 洛阳坐标版本或资源校验失败，存档尚未应用：'
$lines=@($stderr -split '\r?\n');$blocks=[Collections.Generic.List[string]]::new()
for ($i=0;$i -lt $lines.Count;$i++) { if ($lines[$i] -ceq $header) {
 Require ($i+9 -lt $lines.Count) 'Actual native block truncated'
 $blocks.Add(($lines[$i..($i+9)] -join "`n")+"`n")
} }
Require ($blocks.Count -eq 20) 'Actual retained twenty exact warning blocks required'
$actualBlocks=$blocks -join ''
$unitChecks=0
function Unit-Check([bool]$ok,[string]$label) {
 $script:unitChecks+=1
 if (-not $ok) { throw ('SAVE_WARNING_UNIT_FAIL: '+$label) }
}
function Clone-Result($value) { return ($value|ConvertTo-Json -Depth 100|ConvertFrom-Json -AsHashtable -Depth 100) }
function Unit-Reject([string]$label,[scriptblock]$action,[string]$expectedMessage) {
 $rejected=$false
 try { $null=& $action } catch { $rejected=$_.Exception.Message.Contains($expectedMessage,[StringComparison]::Ordinal) }
 Unit-Check $rejected $label
}
$receipt=Check-SaveNegativeEvidence $result $map
Unit-Check ($receipt.Count -eq 20) 'actual original twenty source-bound zero-mutation receipts'
$review=Check-FullStderr $actualBlocks $map $result
Unit-Check ($review.save_expected_rejection_warnings -eq 20 -and $review.save_negative_case_bindings.Count -eq 20 -and $review.unknown_lines -eq 0 -and -not $review.clean_stderr -and -not $review.direct_warning_case_id_receipt_available) 'actual455 twenty retained save-warning blocks only; old full log is NOT current-source whole credit'
# Four scalar fields must remain the actual JSON Int64 protocol. Store array
# aliases inside case Dictionaries so PowerShell cannot flatten fixture values.
$numericCases=@(
 @{container='result';field='failures';expected=[long]0;message='complete actual save result'},
 @{container='stage';field='failures';expected=[long]0;message='complete original current scope'},
 @{container='stage';field='world_coordinate_version';expected=[long]14;message='complete original current scope'},
 @{container='stage';field='city_layout_version';expected=[long]3;message='complete original current scope'}
)
foreach ($numericCase in $numericCases) {
 $actualContainer=if ($numericCase.container -ceq 'result') {$result} else {$result.stage}
 Unit-Check ($actualContainer[$numericCase.field] -is [long] -and $actualContainer[$numericCase.field] -eq $numericCase.expected) ('actual455 Long '+$numericCase.container+'/'+$numericCase.field)
 $aliases=@(
  @{kind='String';value=[string]$numericCase.expected},
  @{kind='Array';value=@([long]$numericCase.expected)},
  @{kind='BoolFalse';value=$false},
  @{kind='BoolTrue';value=$true},
  @{kind='Null';value=$null},
  @{kind='Double';value=[double]$numericCase.expected}
 )
 Unit-Check ($aliases.Count -eq 6 -and $aliases[1].value -is [array] -and $aliases[1].value.Count -eq 1) 'scalar aliases retain an actual one-element Array fixture'
 foreach ($alias in $aliases) {
  $bad=Clone-Result $result
  $target=if ($numericCase.container -ceq 'result') {$bad} else {$bad.stage}
  $target[$numericCase.field]=$alias.value
  Unit-Reject ('strict scalar type '+$numericCase.container+'/'+$numericCase.field+'/'+$alias.kind) { Check-SaveNegativeEvidence $bad $map } $numericCase.message
 }
}

foreach ($phase in @('geometry','gameplay')) {
 $bad=Clone-Result $result;$bad.mode.phase=$phase
 Unit-Reject ('wrong phase '+$phase) { Check-SaveNegativeEvidence $bad $map } 'complete actual save result'
}
foreach ($field in @('complete','failures')) {
 $bad=Clone-Result $result;$bad[$field]=if ($field -ceq 'complete') {$false} else {[long]1}
 Unit-Reject ('partial actual result '+$field) { Check-SaveNegativeEvidence $bad $map } 'complete actual save result'
}
foreach ($field in @('complete','failures','scope')) {
 $bad=Clone-Result $result;$bad.stage[$field]=if ($field -ceq 'complete') {$false} elseif ($field -ceq 'failures') {[long]1} else {'OTHER_SCOPE'}
 Unit-Reject ('partial/wrong stage '+$field) { Check-SaveNegativeEvidence $bad $map } 'complete original current scope'
}
$bad=Clone-Result $result;$bad.stage.new_game.complete=$false
Unit-Reject 'NewGame incomplete' { Check-SaveNegativeEvidence $bad $map } 'complete original current scope'
$bad=Clone-Result $result;$bad.stage.records=@($bad.stage.records|Select-Object -First 3)
Unit-Reject 'four current cases missing' { Check-SaveNegativeEvidence $bad $map } 'complete original current scope'
foreach ($index in 0..3) {
 $bad=Clone-Result $result;$bad.stage.records[$index].passed=$false
 Unit-Reject ('current case failed '+$index) { Check-SaveNegativeEvidence $bad $map } 'four complete current cases'
 foreach ($key in @('raw_full_feet_clear','actual_Physics_clear','position_matches_saved')) {
  $bad=Clone-Result $result;$bad.stage.records[$index].births[1][$key]=$false
  Unit-Reject ('second birth failed '+$index+'/'+$key) { Check-SaveNegativeEvidence $bad $map } 'current Field birth not complete'
 }
}
$bad=Clone-Result $result;$bad.stage.records[1].scene_id=$bad.stage.records[0].scene_id
Unit-Reject 'duplicate current city' { Check-SaveNegativeEvidence $bad $map } 'four complete current cases'
foreach ($count in @(19,21)) {
 $bad=Clone-Result $result
 if ($count -eq 19) { $bad.stage.unknown_records=@($bad.stage.unknown_records|Select-Object -First 19) }
 else { $bad.stage.unknown_records+=@($bad.stage.unknown_records[0]) }
 Unit-Reject ('wrong typed negative count '+$count) { Check-SaveNegativeEvidence $bad $map } 'Unknown local version matrix missing'
}
foreach ($index in 0..19) {
 foreach ($field in @('loaded','zero_mutation')) {
  $bad=Clone-Result $result;$bad.stage.unknown_records[$index][$field]=($field -ceq 'loaded')
  Unit-Reject ('negative load/state '+$index+'/'+$field) { Check-SaveNegativeEvidence $bad $map } 'Unsupported version loaded or mutated'
 }
}
$bad=Clone-Result $result;$bad.stage.unknown_records[1]=$bad.stage.unknown_records[0]
Unit-Reject 'duplicate negative typed case' { Check-SaveNegativeEvidence $bad $map } 'Unknown/missing/duplicate typed unsupported version'
foreach ($value in @([long]3,[double]2.0,'2',$false,$null,@(2))) {
 $bad=Clone-Result $result;$bad.stage.unknown_records[0].version=$value
 Unit-Reject ('wrong/aliased original version '+($value|ConvertTo-Json -Compress)) { Check-SaveNegativeEvidence $bad $map } $(if ($value -is [double] -and $value -eq 2) {'case order/type differs'} else {'Unknown/missing/duplicate typed unsupported version'})
}
$bad=Clone-Result $result;$swap=$bad.stage.unknown_records[0];$bad.stage.unknown_records[0]=$bad.stage.unknown_records[1];$bad.stage.unknown_records[1]=$swap
Unit-Reject 'complete matrix wrong source execution order' { Check-SaveNegativeEvidence $bad $map } 'case order/type differs'
$bad=Clone-Result $result;$bad.stage.unknown_records[0].after.gold=[long]$bad.stage.unknown_records[0].after.gold+1
Unit-Reject 'actual domain mutation' { Check-SaveNegativeEvidence $bad $map } 'Unsupported version loaded or mutated'
$bad=Clone-Result $result;$bad.stage.unknown_records[0].before=$null;$bad.stage.unknown_records[0].after=$null
Unit-Reject 'both snapshots missing cannot pass null equality' { Check-SaveNegativeEvidence $bad $map } 'Unsupported version loaded or mutated'
# Source pins are obtained from the actual frozen private predicate, not a new
# unit mirror of its allowed source list. Only top-level assignment in that func.
$saveFunction=@($ast.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Check-SaveNegativeEvidence'},$true))
Require ($saveFunction.Count -eq 1) 'Save source predicate nonunique'
$pinAssignment=@($saveFunction[0].Body.EndBlock.Statements|Where-Object {$_ -is [Management.Automation.Language.AssignmentStatementAst] -and $_.Left.Extent.Text -ceq '$savePins'})
Require ($pinAssignment.Count -eq 1) 'Save source table nonunique'
Invoke-Expression $pinAssignment[0].Extent.Text
foreach ($res in $savePins.Keys) {
 $path=Source-Path $res;$badMap=$map.Clone();$badMap.Remove($path)
 Unit-Reject ('missing actual first source '+$res) { Check-SaveNegativeEvidence $result $badMap } 'exact source/first/current binding differs'
 $badMap=$map.Clone();$badMap[$path]=$map[$path].Clone();$badMap[$path].sha256='0'*64
 Unit-Reject ('changed source first SHA '+$res) { Check-SaveNegativeEvidence $result $badMap } 'exact source/first/current binding differs'
}
foreach ($count in @(0,19,21)) {
 $badLog=if ($count -eq 0) {''} elseif ($count -eq 19) {(@($blocks|Select-Object -First 19)-join '')} else {$actualBlocks+$blocks[0]}
 Unit-Reject ('native warning count '+$count) { Check-FullStderr $badLog $map $result } $(if ($count -eq 0) {'all twenty exact'} elseif ($count -eq 19) {'Incomplete original four by five'} else {'Extra save-negative'})
}
foreach ($wrong in @(($header+'unexpected suffix'),($header.Replace('洛阳','任意')),('WARNING: unknown save warning'))) {
 Unit-Reject 'wrong exact native header' { Check-FullStderr $actualBlocks.Replace($header,$wrong) $map $result } 'Unknown stderr line'
}
Unit-Reject 'native 1034 mismatch' { Check-FullStderr $actualBlocks.Replace('variant_utility.cpp:1034','variant_utility.cpp:1035') $map $result } 'Unknown/malformed warning'
foreach ($frame in (Save-NegativeStack)) {
 $parts=$frame.Split('|');$old=$parts[0]+' ('+$parts[1]+':'+$parts[2]+')'
 $wrong=$parts[0]+'_other ('+$parts[1]+':'+$parts[2]+')'
 Unit-Reject ('wrong concrete frame '+$frame) { Check-FullStderr $actualBlocks.Replace($old,$wrong) $map $result } 'backtrace method/line differs'
}
foreach ($extra in @('ERROR: unknown','SCRIPT ERROR: unknown','WARNING: unknown','unknown bare line')) {
 Unit-Reject ('unknown appended stderr '+$extra) { Check-FullStderr ($actualBlocks+$extra+"`n") $map $result } 'Unknown stderr line'
}
foreach ($path in $actualPins.Keys) { Unit-Check ((Hash $path) -ceq $actualPins[$path]) 'retained actual455 evidence unchanged through unit' }
Unit-Check ((Hash $core) -ceq $coreSHA) 'NEW consumer unchanged through unit'

# Same real current binding predicate used by candidate and shared formal core.
# These source rows are freshly constructed ONLY for private source tests, not
# inserted into a historical wrapper/actual report or promoted to a six slot.
foreach ($res in $fixed.Keys) {
 $path=Source-Path $res
 $row=@{path=$path;sha256=(Hash $path);bytes=[long](Get-Item -LiteralPath $path).Length}
 Check-FixedSource $res $row;Unit-Check $true ('actual current fixed binding '+$res)
 foreach ($alias in @(@{kind='StringWrong';value=('0'*64)},@{kind='Array';value=@($row.sha256)},@{kind='Bool';value=$true},@{kind='Null';value=$null},@{kind='Int';value=[long]1})) {
  $bad=$row.Clone();$bad.sha256=$alias.value
  Unit-Reject ('wrong typed/SHA current binding '+$res+'/'+$alias.kind) {Check-FixedSource $res $bad} $(if($alias.kind -ceq 'StringWrong'){'Frozen motion/runtime source differs'}else{'Typed frozen'})
 }
}
$oldField=@{sha256='1EB104FA0E321F7D4C361996639AE882340EC029CE5AED14E17B2D6A711DD740'}
Unit-Reject 'old Field rejected by actual current source predicate' {Check-FixedSource 'res://scripts/field/field_walkable_controller.gd' $oldField} 'Frozen motion/runtime source differs'
Unit-Reject 'wrong source identity' {Check-FixedSource 'res://scripts/field/player.gd_other' $oldField} 'Typed frozen'
# Call the actual stack constructors and Exact-Stack. Positive is structural
# source matching, NOT an executed NPC/reading/Confirm receipt or whole run.
$currentField='res://scripts/field/field_walkable_controller.gd'
$currentMap=@{}
$currentMap[(Source-Path $currentField)]=@{sha256=(Hash (Source-Path $currentField));bytes=[long](Get-Item -LiteralPath (Source-Path $currentField)).Length}
$oldLines=@{'2787'='2750';'2857'='2820';'2841'='2804';'2587'='2550';'3727'='3690';'3767'='3730';'2729'='2692';'2568'='2531';'2600'='2563';'3740'='3703';'2923'='2886';'2891'='2854'}
$stacks=[Collections.Generic.List[object]]::new()
foreach ($actor in @('luoyang_gate_sergeant','spar_yamen_patrol','spar_yamen_captain','spar_luoyang_shen_guard','spar_luoyang_examiner','spar_luoyang_blademaster','spar_luoyang_patrol','ch8_luoyang_final_clerk','canal_endangered_porter','canal_saved_porter','canal_old_soldier')) {foreach ($mode in @('space','mouse')) {$stacks.Add(@{label=$actor+'/'+$mode;frames=@(Warning-Stack $actor $mode)})}}
foreach ($mode in @('space','mouse')) {$stacks.Add(@{label='reading/'+$mode;frames=@(Reading-Stack $mode)})}
# Confirm expected comes from the real Check-FullStderr AST, not a unit model.
$stderrFunc=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Check-FullStderr'},$true))
$confirmArray=@($stderrFunc[0].FindAll({param($n)$n -is [Management.Automation.Language.ArrayExpressionAst] -and $n.Extent.Text.Contains('_show_sparring_confirmation|')},$true))
Require ($confirmArray.Count -eq 1) 'Unique actual Confirm stack array required'
$confirm=Invoke-Expression $confirmArray[0].Extent.Text
$stacks.Add(@{label='Confirm';frames=@($confirm)})
foreach ($stack in $stacks) {
 Exact-Stack $stack.frames $stack.frames;Unit-Check $true ('current exact stack '+$stack.label)
 for ($n=0;$n -lt $stack.frames.Count;$n++) {
  $parts=$stack.frames[$n].Split('|')
  if ($parts[1] -ceq $currentField) {
   Check-ConcreteStack $parts[0] $parts[1] ([int]$parts[2]) $currentMap;Unit-Check $true ('current concrete Field call '+$stack.label+'/'+$parts[2])
   $bad=@($stack.frames);$bad[$n]=$parts[0]+'|'+$parts[1]+'|'+$oldLines[$parts[2]]
   Unit-Reject ('old Field stack line '+$stack.label+'/'+$n) {Exact-Stack $bad $stack.frames} 'full stack source/function/line differs'
  }
  foreach ($fixture in @(@{kind='line';value=$parts[0]+'|'+$parts[1]+'|'+([int]$parts[2]+1)},@{kind='null';value=$null},@{kind='bool';value=$true},@{kind='long';value=[long]1},@{kind='array';value=@($stack.frames[$n])})) {
   $bad=@($stack.frames);$bad[$n]=$fixture.value
   Unit-Reject ('wrong full stack '+$stack.label+'/'+$n+'/'+$fixture.kind) {Exact-Stack $bad $stack.frames} 'full stack source/function/line differs'
  }
 }
}
Unit-Check ((Hash $core) -ceq $coreSHA) 'current strict core remains frozen'

[ordered]@{scope='CURRENT_FADE_SOURCE_STACK_PLUS_RETAINED_SAVE_NEGATIVE_UNITS_NOT_SIX_APPROVAL';checks=$unitChecks;failures=0;actual_typed_cases=20;actual_original_warning_blocks=20;known_image_warnings=$review.warnings;direct_warning_case_id_receipt_available=$false;clean_credit=$false;builder_top_level_executed=$false;draft_created=$false;Field_executed=$false;approval_credit=$false}|ConvertTo-Json -Depth 4
