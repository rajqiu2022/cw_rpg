param(
 [Parameter(Mandatory=$true)][string]$OutputDirectory,
 [string]$ProjectRoot='F:\Code\RPG_GAME'
)
# READ ONLY LIMITED CONSUMER UNIT. No Godot, no six-slot fill, no approval.
$ErrorActionPreference='Stop'; $project=[IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\'); $game=Join-Path $project 'game'
$domain=Join-Path $game 'build\joint_world_luoyang_20261003_qa'; $target=[IO.Path]::GetFullPath($OutputDirectory)
if (-not $target.StartsWith($domain+'\',[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $target)) {throw 'NEW unique BUILD unit output required'}
$core=Join-Path $project 'scripts\qa\prepare_luoyang_city_only_actual_six_approval_draft_retry13_20261011.ps1'
$coreSHA='CAEE0A8ABC2FAC3AEC11EE1FDAF0BCC9D0B86F92748D72AEFBD3CDFA8C8F4065'
$old=Join-Path $project 'scripts\qa\prepare_luoyang_city_only_actual_six_approval_draft_retry12_20261010.ps1'
$oldSHA='EB04540285AE4EA60E806FDECA61D544E63F1E372B1F3255E7C75B2C890A4922'
$fixture=Join-Path $domain 'roof_source_display_actual_1791695878_1957039_98064\result.json'
$fixtureSHA='1DE9C865A1714EF5D66BE21FD4E658FA852003A38F6F2B185913ACFD5AD74C59'
$beforePath=Join-Path $domain '485_roof_source_display_retry2_actual_headless_wasapi_20261011\before.json'
$beforeSHA='28682057045E3B856825CE9A556A180A24F09B776E12E3F915611901B486C384'
foreach ($pair in @(@($core,$coreSHA),@($old,$oldSHA),@($fixture,$fixtureSHA),@($beforePath,$beforeSHA))) {
 if ($pair[1] -cnotmatch '^[A-Fa-f0-9]{64}$' -or (Get-FileHash -LiteralPath $pair[0]).Hash -ine $pair[1]) {throw 'Frozen literal path/SHA binding differs'}
}
function Parse-Source([string]$path) {$t=$null;$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$t,[ref]$e);if($e.Count){throw 'Source must parse'};return $a}
$ast=Parse-Source $core; $oldAst=Parse-Source $old
$newFunctions=@($ast.EndBlock.Statements|Where-Object {$_ -is [Management.Automation.Language.FunctionDefinitionAst]})
$oldFunctions=@($oldAst.EndBlock.Statements|Where-Object {$_ -is [Management.Automation.Language.FunctionDefinitionAst]})
foreach ($fn in $oldFunctions) {
 $match=@($newFunctions|Where-Object {$_.Name -ceq $fn.Name})
 if($match.Count -ne 1 -or $match[0].Extent.Text -cne $fn.Extent.Text){throw 'Old consumer function changed'}
}
foreach ($fn in $newFunctions) {Invoke-Expression $fn.Extent.Text}
foreach ($name in @('$ids','$fixed','$warningPins')) {
 $matches=@($ast.EndBlock.Statements|Where-Object {$_ -is [Management.Automation.Language.AssignmentStatementAst] -and $_.Left.Extent.Text -ceq $name})
 if($matches.Count -ne 1){throw 'Unique fixed core table required'};Invoke-Expression $matches[0].Extent.Text
}
$before=Get-Content -LiteralPath $beforePath -Raw|ConvertFrom-Json -AsHashtable -Depth 100
$r=Get-Content -LiteralPath $fixture -Raw|ConvertFrom-Json -AsHashtable -Depth 100
$map=@{};foreach($row in $before.sources){$path=Source-Path $row.path;if($map.ContainsKey($path)){if(-not(Equal $map[$path] $row)){throw 'Conflicting fixture first guard'}}else{$map[$path]=$row}}
$checks=0;$positive=0;$negative=0
function Accept([scriptblock]$call,[string]$name){$null=& $call;$script:checks++;$script:positive++}
function Reject([scriptblock]$call,[string]$name){$rejected=$false;try{$null=& $call}catch{$rejected=$true};if(-not$rejected){throw ('CONSUMER UNIT FAIL: '+$name)};$script:checks++;$script:negative++}
function Clone($value){return ConvertFrom-Json -InputObject ($value|ConvertTo-Json -Depth 50 -Compress) -AsHashtable -Depth 50}
$roofIDs=@('v11_yamen_west_south_1520','v11_yamen_west_south_1360','v11_yamen_west_north_780','v11_yamen_east_south_1520','v11_yamen_east_south_1360','v11_yamen_east_north_780')
Accept {Check-RoofRegionProof $r.actual $map} 'actual limited485 six-roof18receipt sequence, not full four-city slot'
$bad=Clone $r.actual;$bad.source_display_bindings=$bad.source_display_bindings[0..16];Reject {Check-RoofRegionProof $bad $map} 'missing eighteenth display receipt'
$bad=Clone $r.actual;$bad.source_display_bindings[1].factor=.75;Reject {Check-RoofRegionProof $bad $map} 'display receipt differs from actual per-proof sequence'
$bad=Clone $r.actual;$bad.objects[0].alpha.records[0].continuous_front_proof.full_RGBA_sha256='0'*64;Reject {Check-RoofRegionProof $bad $map} 'sourceRGBA changes between first and actual behind proof'
foreach($id in $roofIDs){
 $object=@($r.actual.objects|Where-Object {$_.id -ceq $id});if($object.Count-ne 1){throw 'Real fixture six roof identities required'}
 Accept {Check-RoofProof $object[0].alpha.front_proof $id $map} ('actual initial '+$id)
 foreach($trial in $object[0].alpha.records){Accept {Check-RoofProof $trial.continuous_front_proof $id $map} ('actual '+$trial.relation+' '+$id)}
}
foreach($npc in $r.actual.npcs){foreach($row in $npc.rows){Accept {Check-NativeNPCReceipt $row 'ch4_s1_luoyang_yamen' $npc.id $map} 'actual native NPC'}}
$proof=$r.actual.objects[0].alpha.front_proof; $id=$proof.id; $binding=$proof.current_display_binding
foreach($key in @('runtime_script','direct_base','native_base')){$v=Clone $binding;$v[$key]='res://wrong.gd';Reject {Check-DisplayBinding $v $id $map} ('wrong chain '+$key)}
foreach($path in $binding.source_pins.Keys){$v=Clone $binding;$v.source_pins[$path]='0'*64;Reject {Check-DisplayBinding $v $id $map} ('changed SHA '+$path)}
foreach($key in @('complete','alpha_interval_alone_is_NOT_proof','hit','eligible')){
 foreach($alias in @('true',[long]1,$null)){ $v=Clone $binding;$v[$key]=$alias;Reject {Check-DisplayBinding $v $id $map} ('typed display '+$key)}
 $v=Clone $binding;$v[$key]=@($binding[$key]);Reject {Check-DisplayBinding $v $id $map} ('Array display '+$key)
}
foreach($key in @('factor','target','field_instance_id','prop_instance_id','player_instance_id','physics_frame','process_frame')) {
 $v=Clone $binding;$v[$key]=[string]$binding[$key];Reject {Check-DisplayBinding $v $id $map} ('numeric String '+$key)
}
$v=Clone $binding;$v.error='FIELD_UNBOUND';Reject {Check-DisplayBinding $v $id $map} 'original merge failure'
$v=Clone $binding;$v.base_color_bytes='0'*40;Reject {Check-DisplayBinding $v $id $map} 'unbound base Color'
$v=Clone $binding;$v.factor=.75;Reject {Check-DisplayBinding $v $id $map} 'within range forged alpha'
$v=Clone $binding;$v.display_color_bytes='140000000000803f0000803f0000803fcdcc0c3f';Reject {Check-DisplayBinding $v $id $map} 'opaque factor with faded native color'
foreach($key in @('frame_count','strip_count')){$v=Clone $proof;$v.actor[$key]=[long]1;Reject {Check-RoofProof $v $id $map} ('full actor domain '+$key)}
foreach($key in @('proved','source_import_all_RGBA_exact','source_unchanged','strict_six_roof_identity','author_source_display_separated')){$v=Clone $proof;$v[$key]=$false;Reject {Check-RoofProof $v $id $map} ('missing proof '+$key)}
foreach($key in @('metadata_used','search_miss_used','actual_Field_credit','collision_or_input_approval')){$v=Clone $proof;$v[$key]=$true;Reject {Check-RoofProof $v $id $map} ('false credit '+$key)}
$v=Clone $proof;$v.gap_world_px=0.0;Reject {Check-RoofProof $v $id $map} 'zero support gap'
$v=Clone $proof;$v.source_sha256='0'*64;Reject {Check-RoofProof $v $id $map} 'changed source PNG'
$v=Clone $proof;$v.actor.domain='CURRENT_FRAME_ONLY';Reject {Check-RoofProof $v $id $map} 'current frame cannot replace ALL240'
$npc=$r.actual.npcs[0];$row=$npc.rows[0]
foreach($key in @('raw_float64_hex','helper_raw_float64_hex','native_float32_hex')){$v=Clone $row;$v[$key]='0'*$row[$key].Length;Reject {Check-NativeNPCReceipt $v 'ch4_s1_luoyang_yamen' $npc.id $map} ('wrong native bytes '+$key)}
$v=Clone $row;$v.band=$v.legacy_raw_band;Reject {Check-NativeNPCReceipt $v 'ch4_s1_luoyang_yamen' $npc.id $map} 'old rawDouble band cannot replace nativeFloat32'
foreach($key in @('kind_rank','stable_ordinal','sibling_index','band')){$v=Clone $row;$v.helper_state[$key]=[string]$v.helper_state[$key];Reject {Check-NativeNPCReceipt $v 'ch4_s1_luoyang_yamen' $npc.id $map} ('typed native tuple '+$key)}
$v=Clone $row;$v.sprite.frame=$v.sprite.hframes*$v.sprite.vframes;Reject {Check-NativeNPCReceipt $v 'ch4_s1_luoyang_yamen' $npc.id $map} 'outside NPC frame'
Reject {Check-CurrentGeometryProof @() $map} 'limited fixture cannot fill full four geometry'
foreach($pair in @(@($core,$coreSHA),@($old,$oldSHA),@($fixture,$fixtureSHA),@($beforePath,$beforeSHA))){if((Get-FileHash -LiteralPath $pair[0]).Hash -ine $pair[1]){throw 'Source/evidence changed during read-only unit'}}
New-Item -ItemType Directory -Path $target|Out-Null
$output=Join-Path $target 'strict_geometry_consumer_units.json'
$report=@{scope='LIMITED_REAL485_SOURCE_DISPLAY_NATIVE_RECEIPT_CONSUMER_UNIT_NOT_SIX';checks=$checks;positive=$positive;negative=$negative;failures=0;actual_Field_tested=$false;new_actual_six_tested=$false;approval_credit=$false;fixture_path=$fixture;fixture_sha256=$fixtureSHA;core_path=$core;core_sha256=$coreSHA;old_consumer_functions_exact=$oldFunctions.Count}
[IO.File]::WriteAllText($output,($report|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
$readback=Get-Content -LiteralPath $output -Raw|ConvertFrom-Json -AsHashtable
if($readback.checks -ne $checks -or $readback.failures -ne 0 -or $readback.approval_credit){throw 'Unit readback differs'}
[pscustomobject]@{checks=$checks;failures=0;path=$output;sha256=(Get-FileHash -LiteralPath $output).Hash;scope=$report.scope}
