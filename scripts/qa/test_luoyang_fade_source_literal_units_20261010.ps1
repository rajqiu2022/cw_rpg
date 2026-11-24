param([string]$ProjectRoot='F:\Code\RPG_GAME')
# Only actual lexical/path functions, never collector top-level or engine.
$ErrorActionPreference='Stop'
$project=[IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
$game=Join-Path $project 'game'
$core=Join-Path $project 'scripts/qa/collect_luoyang_fade_current_source_paths_retry1_20261010.ps1'
$coreSHA='883CDC8DA22FE39DD1F03C230F76FD0DCF8E9DFFAC7B3483D223F2BDFCFD3257'
if ((Get-FileHash -LiteralPath $core).Hash -cne $coreSHA) {throw 'Bound NEW collector SHA differs'}
$tokens=$null;$parseErrors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($core,[ref]$tokens,[ref]$parseErrors)
if ($parseErrors.Count -ne 0) {throw 'Collector parse failed'}
foreach ($name in @('Remove-ResourceComments','Resolve-Source','Add-Leaf')) {
 $nodes=@($ast.EndBlock.Statements|Where-Object {$_ -is [Management.Automation.Language.FunctionDefinitionAst] -and $_.Name -ceq $name})
 if ($nodes.Count -ne 1) {throw 'Unique top-level actual function required'}
 Invoke-Expression $nodes[0].Extent.Text
}
$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$queue=[Collections.Generic.Queue[string]]::new()
$checks=0
function Check([bool]$ok,[string]$label) {$script:checks++;if (-not $ok) {throw ('COLLECTOR_LITERAL_UNIT_FAIL: '+$label)}}
# Literal expected bytes are independent fixtures, not a second lexer model.
$untouched=@(
 'var p = "res://scripts/field/player.gd"',
 'var s = "# inside double"; var p = "res://scripts/field/player.gd"',
 'var s = ''# inside single''; var p = "res://scripts/field/player.gd"',
 'var s = "escaped \" # inside"; var p = "res://scripts/field/player.gd"',
 'var s = "escaped \\"; var p = "res://scripts/field/player.gd"',
 'var p = "res://actual#name.png"',
 'var p = "res://missing_actual_resource.png"',
 'var p = "res://scripts/field/player.gd"; var q = "res://another_actual.png"'
)
foreach ($text in $untouched) {Check ((Remove-ResourceComments $text '.gd') -ceq $text) ('code/quote bytes untouched: '+$text)}
$comment='##   "path": "res://art/background_chunks/.../tile_00_00.png",'
$filtered=Remove-ResourceComments $comment '.gd'
Check ($filtered -ceq (' '*$comment.Length)) 'full documentation comment replaced only by equal-length spaces'
$real='const P = "res://scripts/field/player.gd" '
$tail='# example "res://missing_comment.png"'
Check ((Remove-ResourceComments ($real+$tail) '.gd') -ceq ($real+(' '*$tail.Length))) 'inline comment only removed; real literal remains'
$multiline=$comment+[char]13+[char]10+$real+$tail+[char]10+$untouched[2]
$clean=Remove-ResourceComments $multiline '.gd'
Check ($clean.Length -eq $multiline.Length -and @([regex]::Matches($clean,'\r?\n')).Count -eq 2) 'line/byte positions preserved'
Check ($clean.Contains($real,[StringComparison]::Ordinal) -and $clean.Contains($untouched[2],[StringComparison]::Ordinal)) 'double/single quote state preserved'
foreach ($extension in @('.tres','.tscn','.godot')) {
 $text='path="res://scripts/field/player.gd"; "res://missing_comment.png"'
 $prefix='path="res://scripts/field/player.gd"'
 Check ((Remove-ResourceComments $text $extension) -ceq ($prefix+(' '*($text.Length-$prefix.Length)))) ('outside-quote semicolon comment '+$extension)
 $quoted='path="res://semi;inside.png"'
 Check ((Remove-ResourceComments $quoted $extension) -ceq $quoted) ('semicolon inside literal preserved '+$extension)
}
$document=Join-Path $game 'scripts/domain/streamed_background_set.gd'
$documentBefore=(Get-FileHash -LiteralPath $document).Hash
$actual=[IO.File]::ReadAllText($document)
Check ($actual.Contains($comment,[StringComparison]::Ordinal)) 'actual ROOT468 comment is present unchanged'
$actualClean=Remove-ResourceComments $actual '.gd'
Check (-not $actualClean.Contains('res://art/background_chunks/.../tile_00_00.png',[StringComparison]::Ordinal)) 'actual comment no longer creates a false required leaf'
# Real missing file still reaches the ORIGINAL Add-Leaf fail-closed path.
$missing='game/build/joint_world_luoyang_20261003_qa/__collector_literal_missing_owned_control__.png'
Check (-not (Test-Path -LiteralPath (Join-Path $project $missing))) 'missing control absent; unit creates/writes nothing'
$refText='var p = "res://build/joint_world_luoyang_20261003_qa/__collector_literal_missing_owned_control__.png"'
$refClean=Remove-ResourceComments $refText '.gd'
Check ($refClean -ceq $refText) 'real missing reference retained exactly'
$refs=[regex]::Matches($refClean,'"(res://[^"\r\n]+)"')
Check ($refs.Count -eq 1) 'original quoted scanner retains real missing leaf'
$rejected=$false
try {Add-Leaf $refs[0].Groups[1].Value} catch {$rejected=$_.Exception.Message.StartsWith('Missing required leaf:',[StringComparison]::Ordinal)}
Check $rejected 'actual required missing leaf rejected, not generically ignored'
Add-Leaf 'res://scripts/field/player.gd'
Check ($seen.Contains((Resolve-Source 'res://scripts/field/player.gd'))) 'actual real existing resource still tracked'
Check ((Get-FileHash -LiteralPath $document).Hash -ceq $documentBefore -and (Get-FileHash -LiteralPath $core).Hash -ceq $coreSHA) 'source documents unchanged'
[ordered]@{scope='ACTUAL_COLLECTOR_LEXICAL_COMMENT_AND_MISSING_LEAF_PURE_NOT_FIELD_OR_GUARD_APPROVAL';checks=$checks;failures=0;collector_top_level_executed=$false;engine_executed=$false;inventory_written=$false;old_468_failure_preserved=$true}|ConvertTo-Json -Depth 3

