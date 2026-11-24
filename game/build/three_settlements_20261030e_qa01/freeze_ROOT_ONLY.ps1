param([Parameter(Mandatory=$true)][string]$AuthPath,[string]$GeometryPath='F:/Code/RPG_GAME/game/build/three_settlements_20261030e_qa01/geometry_ROOT_ACTUAL.json',[string]$ResidualGeometryPath='')
$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/three_settlements_20261030e_qa01"
$authResolved=[IO.Path]::GetFullPath($AuthPath).Replace('\','/');if(!$authResolved.StartsWith("$repo/",[StringComparison]::OrdinalIgnoreCase)){throw 'AUTH_MUST_BE_IN_REPO'}
$baseline=Get-Content "$qa/baseline_before_ACTUAL.json" -Raw | ConvertFrom-Json
$auth=Get-Content -LiteralPath $authResolved -Raw | ConvertFrom-Json
$contractPath=[IO.Path]::GetDirectoryName($authResolved).Replace('\','/')+'/source_contract_READY.json'
if(!(Test-Path -LiteralPath $contractPath)){throw 'EXACT_NEW_CONTENT_CONTRACT_REQUIRED'}
$contract=Get-Content -LiteralPath $contractPath -Raw|ConvertFrom-Json
$geometryResolved=[IO.Path]::GetFullPath($GeometryPath).Replace('\','/');if(!$geometryResolved.StartsWith("$qa/",[StringComparison]::OrdinalIgnoreCase)){throw 'GEOMETRY_MUST_BE_IN_THIS_QA_DIR'}
$geometry=Get-Content -LiteralPath $geometryResolved -Raw | ConvertFrom-Json
$residualResolved='';$residual=$null
if(!$geometry.passed){
 if([string]::IsNullOrWhiteSpace($ResidualGeometryPath)){throw 'ROOT_FOUR_FEET_RESIDUAL_REQUIRED_ORIGINAL_FAIL_RETAINED'}
 $residualResolved=[IO.Path]::GetFullPath($ResidualGeometryPath).Replace('\','/');if(!$residualResolved.StartsWith("$qa/",[StringComparison]::OrdinalIgnoreCase)){throw 'RESIDUAL_MUST_BE_IN_THIS_QA_DIR'}
 $residual=Get-Content -LiteralPath $residualResolved -Raw|ConvertFrom-Json
 $expectedErrors=@('NPC_COMPLETE_BODY_CLEAR:openworld_xiangzhou_city:xiangzhou_life_01','NPC_COMPLETE_BODY_CLEAR:openworld_xiangzhou_city:xiangzhou_life_02','NPC_COMPLETE_BODY_CLEAR:openworld_xiangzhou_city:xiangzhou_life_09','NPC_COMPLETE_BODY_CLEAR:openworld_xiangzhou_city:xiangzhou_life_14')
 if(!$residual.passed -or $geometry.checks -ne 1204 -or (($geometry.errors)-join "`n") -cne ($expectedErrors-join "`n") -or $residual.original_report_sha256 -ne (Get-FileHash -LiteralPath $geometryResolved).Hash.ToLower() -or $residual.original_whole_run_status -ne 'FAIL_RETAINED' -or $residual.inherited_successes -ne 1200 -or $residual.new_body_tests -ne 4){throw 'EXACT1200_SUCCESS_PLUS_FOUR_RESIDUAL_PROOF_REQUIRED'}
 $authorPath="$repo/game/"+$residual.author_path.Substring(6)
 if((Get-FileHash -LiteralPath $authorPath).Hash.ToLower() -ne $residual.new_author_sha256){throw 'FOUR_FEET_AUTHOR_CHANGED_AFTER_RESIDUAL'}
}
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
function Same($a,$b){return $a.exists -eq $b.exists -and (!$a.exists -or ($a.sha256 -eq $b.sha256 -and $a.bytes -eq $b.bytes -and $a.utc_ticks -eq $b.utc_ticks))}
function NewJson([string]$p,$v){$stream=[IO.File]::Open($p,[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($v | ConvertTo-Json -Depth 24)+"`n");$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}}
if(Test-Path -LiteralPath "$qa/actual_READY.json"){throw 'IMMUTABLE_FIXTURE_ALREADY_EXISTS'}
$expected=@($baseline.sources.PSObject.Properties.Name);$actual=@($auth.sources.PSObject.Properties.Name)
if((($expected|Sort-Object) -join "`n") -cne (($actual|Sort-Object) -join "`n")){throw 'TARGET_SET_CHANGED_SUPPLEMENT_BASELINE_DONT_OVERWRITE'}
$all=[ordered]@{};$fixed=[ordered]@{};$saves=[ordered]@{};$external=[ordered]@{}
foreach($p in $baseline.protected_sources.PSObject.Properties){$f=Fact "$repo/$($p.Name)";if(!(Same $f $p.Value)){throw "PROTECTED_CHANGED_PRESERVE_AND_REPORT:$($p.Name)"};$all[$p.Name]=$f}
foreach($section in @($auth.sources,$auth.new_modules,$auth.new_content_sources,$contract.modules,$contract.immutable_inputs)){foreach($p in $section.PSObject.Properties){$path=if($p.Name.StartsWith('res://')){'game/'+$p.Name.Substring(6)}else{$p.Name};$f=Fact "$repo/$path";if(!$f.exists -or $f.sha256 -ne $p.Value.sha256 -or $f.bytes -ne $p.Value.bytes){throw "AUTH_MISMATCH:$path"};$all[$path]=$f}}
foreach($path in @($authResolved,$contractPath)){$relative=$path.Substring($repo.Length+1);$all[$relative]=Fact $path}
foreach($path in @('game/data/bounties/xiangzhou_mine_jackal.tres','game/data/bounties/xiangzhou_white_deer.tres')){$f=Fact "$repo/$path";if(!$f.exists){throw "KNOWN_ORIGINAL_BOUNTY_ID_MISSING:$path"};$all[$path]=$f}
foreach($p in $geometry.referenced_assets.PSObject.Properties){$path='game/'+$p.Name.Substring(6);$f=Fact "$repo/$path";if(!$f.exists -or $f.sha256 -ne $p.Value.sha256 -or $f.bytes -ne $p.Value.bytes){throw "REFERENCED_ASSET_CHANGED:$path"};$all[$path]=$f}
foreach($backup in $baseline.exact_backups){if(!(Same (Fact $backup.path) $backup.fact)){throw "BACKUP_CHANGED:$($backup.path)"}}
foreach($p in $baseline.registered_save_paths.PSObject.Properties){$f=Fact $p.Name;if(!(Same $f $p.Value)){throw "USER_SAVE_CHANGED_PRESERVE_REPORT_NO_RESTORE:$($p.Name)"};$saves[$p.Name]=$f}
foreach($p in $baseline.external_parallel_sources.PSObject.Properties){$external[$p.Name]=Fact "$repo/$($p.Name)"}
foreach($path in $all.Keys){$fixed['res://'+$path.Substring(5)]=$all[$path].sha256}
$fixture=Get-Content "$qa/cases_DRAFT.json" -Raw | ConvertFrom-Json
$fixture.ready=$true;$fixture|Add-Member -NotePropertyName fixed_sources -NotePropertyValue $fixed
$fixture|Add-Member -NotePropertyName registered_save_paths -NotePropertyValue @($saves.Keys)
NewJson "$qa/actual_READY.json" $fixture
$text=[IO.File]::ReadAllText("$qa/actual_DRAFT.gd").Replace("`r`n","`n").TrimEnd([char[]]"`r`n")+"`n"
$stream=[IO.File]::Open("$qa/actual_READY.gd",[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes($text);$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
NewJson "$qa/freeze_ROOT_ACTUAL.json" ([ordered]@{status='FROZEN_NEW_THREE_SETTLEMENTS_ONLY_ORIGINAL_FAIL_RETAINED_IF_RESIDUAL';sources=$all;exact_backups=$baseline.exact_backups;saves=$saves;external_run_before=$external;external_policy=$baseline.external_policy;script=(Fact "$qa/actual_READY.gd");fixture=(Fact "$qa/actual_READY.json");auth=(Fact $authResolved);geometry_path=$geometryResolved;geometry=(Fact $geometryResolved);geometry_original_passed=$geometry.passed;geometry_residual_path=$residualResolved;geometry_residual=if($residualResolved){Fact $residualResolved}else{$null};inherited_successes=if($residual){1200}else{$null};engine_calls=0;production_writes=0;save_contents_read=$false;save_writes=0})
Get-FileHash -LiteralPath "$qa/actual_READY.gd","$qa/actual_READY.json","$qa/freeze_ROOT_ACTUAL.json"|Select-Object Path,Hash|ConvertTo-Json
