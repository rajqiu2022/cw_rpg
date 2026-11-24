param([string]$ProjectRoot='F:\Code\RPG_GAME')
# Direct actual domain/catalog/path functions only. No collector top level,
# engine, output inventory, canonical changes or historical credit.
$ErrorActionPreference='Stop'
$project=[IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
$game=Join-Path $project 'game'
$core=Join-Path $project 'scripts/qa/collect_luoyang_fade_current_source_paths_retry2_20261010.ps1'
$coreSHA='C90B86864CC515045FD07BA1DB3145C7541482A229541BA9834128193D2D15A2'
if ((Get-FileHash -LiteralPath $core).Hash -cne $coreSHA) {throw 'Exact NEW collector SHA differs'}
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($core,[ref]$tokens,[ref]$errors)
if ($errors.Count -ne 0) {throw 'Bound collector parse failed'}
foreach ($name in @('Resource-InDomain','Fixed-AssetTable','Read-FixedAssetCatalog','Resolve-Source','Add-Leaf')) {
 $functions=@($ast.EndBlock.Statements|Where-Object {$_ -is [Management.Automation.Language.FunctionDefinitionAst] -and $_.Name -ceq $name})
 if ($functions.Count -ne 1) {throw 'Unique top-level actual function required'}
 Invoke-Expression $functions[0].Extent.Text
}
$table=@($ast.EndBlock.Statements|Where-Object {$_ -is [Management.Automation.Language.AssignmentStatementAst] -and $_.Left.Extent.Text -ceq '$fixedCatalogs'})
if ($table.Count -ne 1) {throw 'Unique exact fixed catalog table required'}
Invoke-Expression $table[0].Extent.Text
$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$queue=[Collections.Generic.Queue[string]]::new()
$assetPaths=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$checks=0
function Check([bool]$ok,[string]$label) {$script:checks++;if (-not $ok) {throw ('COLLECTOR_DOMAIN_UNIT_FAIL: '+$label)}}
function Reject([scriptblock]$action,[string]$message,[string]$label) {
 $rejected=$false
 try {$null=&$action} catch {$rejected=$_.Exception.Message.Contains($message,[StringComparison]::Ordinal)}
 Check $rejected $label
}
Check (Resource-InDomain '.gd' 'res://scripts/field/player.gd') 'script closure retained'
Check (-not (Resource-InDomain '.gd' 'res://data/maps/world_map_v15_complete_v7_visual_review.json')) 'historical inherited data constant outside script-only expansion, not found/file credit'
foreach ($extension in @('.tres','.tscn','.godot')) {
 foreach ($literal in @('res://actual.png','res://actual.gd','res://actual.json','res://actual.wav')) {Check (Resource-InDomain $extension $literal) ('data domain retains full resource leaf '+$extension+'/'+$literal)}
}
foreach ($bad in @(@{value=$null},@{value=$true},@{value=[long]1},@{value=@('.gd')})) {
 Check (-not (Resource-InDomain $bad.value 'res://actual.gd')) 'source domain wrong type rejected'
 Check (-not (Resource-InDomain '.gd' $bad.value)) 'resource literal wrong type rejected'
}
Check (-not (Resource-InDomain '.json' 'res://historical.gd')) 'JSON graph never recursively expanded'
foreach ($case in @(@{extension='.gd';path='res://build/joint_world_luoyang_20261003_qa/__domain_missing_owned_control__.gd'},@{extension='.tres';path='res://build/joint_world_luoyang_20261003_qa/__domain_missing_owned_control__.png'},@{extension='.godot';path='res://build/joint_world_luoyang_20261003_qa/__domain_missing_owned_control__.json'})) {
 Check (-not (Test-Path -LiteralPath (Resolve-Source $case.path))) 'missing test control absent; no files created'
 Check (Resource-InDomain $case.extension $case.path) 'actual required missing resource remains in domain'
 Reject {Add-Leaf $case.path} 'Missing required leaf:' 'actual missing script/data rejects in original Add-Leaf'
}
Check ($fixedCatalogs.Count -eq 12) 'exact twelve current catalogs'
$pinBefore=@{}
foreach ($binding in $fixedCatalogs) {
 $path=Resolve-Source $binding.path;$pinBefore[$path]=(Get-FileHash -LiteralPath $path).Hash
 $assets=Read-FixedAssetCatalog $binding
 Check ($assets -is [Collections.IDictionary] -and $assets.Count -gt 0) 'real fixed typed catalog SHA/read'
 Add-Leaf $binding.path
 foreach ($asset in $assets.Keys) {Add-Leaf $asset;[void]$assetPaths.Add((Resolve-Source $asset))}
 $bad=$binding.Clone();$bad.sha256='0'*64
 Reject {Read-FixedAssetCatalog $bad} 'Unknown/changed fixed catalog identity' 'wrong exact catalog pin rejected'
 $bad=$binding.Clone();$bad.path='res://art/maps/unknown_catalog.json'
 Reject {Read-FixedAssetCatalog $bad} 'Unknown/changed fixed catalog identity' 'unknown catalog rejected'
 foreach ($alias in @(@{value=$null},@{value=$true},@{value=[long]1},@{value=@($binding.sha256)})) {
  $bad=$binding.Clone();$bad.sha256=$alias.value
  Reject {Read-FixedAssetCatalog $bad} 'Typed fixed catalog binding required' 'typed catalog SHA aliases reject'
 }
}
Check ($assetPaths.Count -eq 318 -and @($assetPaths|Where-Object {-not $seen.Contains($_)}).Count -eq 0) 'all 318 unique real catalog leaves required/tracked'
$valid=@{asset_sha256=@{'res://actual.png'=('a'*64)}}
Check ((Fixed-AssetTable $valid).Count -eq 1) 'actual typed asset-table core positive'
foreach ($fixture in @(@{value=@{asset_sha256=$null};message='Nonempty typed'},@{value=@{asset_sha256=@{}};message='Nonempty typed'},@{value=@{asset_sha256=@{'res://actual.png'=@('a'*64)}};message='Typed exact'},@{value=@{asset_sha256=@{'res://actual.png'=$true}};message='Typed exact'},@{value=@{asset_sha256=@{1=('a'*64)}};message='Typed exact'},@{value=@{asset_sha256=@{'outside.png'=('a'*64)}};message='Typed exact'})) {
 Reject {Fixed-AssetTable $fixture.value} $fixture.message 'missing/wrong typed asset table/path/SHA rejected'
}
foreach ($path in $pinBefore.Keys) {Check ((Get-FileHash -LiteralPath $path).Hash -ceq $pinBefore[$path]) 'fixed catalog unchanged'}
Check ((Get-FileHash -LiteralPath $core).Hash -ceq $coreSHA) 'bound consumer unchanged'
[ordered]@{scope='ACTUAL_COLLECTOR_RESOURCE_DOMAIN_AND_12_CATALOG_PURE_NOT_FIELD_OR_SIX';checks=$checks;failures=0;catalogs=12;unique_catalog_assets=$assetPaths.Count;collector_top_level_executed=$false;engine_executed=$false;inventory_written=$false;historical_missing_json_found_claimed=$false;approval_credit=$false}|ConvertTo-Json -Depth 3

