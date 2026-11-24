$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/three_settlements_20261030e_qa01"
$parent=Get-Content "$qa/freeze_ROOT_ACTUAL.json" -Raw|ConvertFrom-Json
$firstPath="$qa/actual/77552/result.json";$first=Get-Content -LiteralPath $firstPath -Raw|ConvertFrom-Json
if($first.passed -or $first.checks -ne 170 -or (($first.errors)-join "`n") -cne 'ORIGINAL_SERVICE_NO_TASK_OR_ECONOMY_CHANGE:openworld_xiangzhou_city' -or $first.fixture_sha256 -ne $parent.fixture.sha256){throw 'EXACT_ORIGINAL170_ONEFAIL_REQUIRED_RETAINED'}
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
function Same($a,$b){return $a.exists -eq $b.exists -and (!$a.exists -or ($a.sha256 -eq $b.sha256 -and $a.bytes -eq $b.bytes -and $a.utc_ticks -eq $b.utc_ticks))}
function NewJson([string]$p,$v){$stream=[IO.File]::Open($p,[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($v|ConvertTo-Json -Depth 26)+"`n");$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}}
if(Test-Path -LiteralPath "$qa/actual02_READY.gd"){throw 'IMMUTABLE_RESIDUAL_ALREADY_FROZEN'}
$all=[ordered]@{};$fixed=[ordered]@{};$saves=[ordered]@{};$external=[ordered]@{}
foreach($p in $parent.sources.PSObject.Properties){$f=Fact "$repo/$($p.Name)";if(!(Same $f $p.Value)){throw "SOURCE_CHANGED_NO_REPLAY_NO_ROLLBACK:$($p.Name)"};$all[$p.Name]=$f}
foreach($p in $parent.saves.PSObject.Properties){$f=Fact $p.Name;if(!(Same $f $p.Value)){throw "USER_SAVE_CHANGED_PRESERVE_AND_REPORT:$($p.Name)"};$saves[$p.Name]=$f}
foreach($p in $parent.exact_backups){if(!(Same (Fact $p.path) $p.fact)){throw "BACKUP_CHANGED:$($p.path)"}}
if(!(Same (Fact "$qa/actual_READY.gd") $parent.script) -or !(Same (Fact "$qa/actual_READY.json") $parent.fixture)){throw 'ORIGINAL_READY_CHANGED'}
foreach($p in @("$qa/actual_READY.gd","$qa/actual_READY.json","$qa/freeze_ROOT_ACTUAL.json",$firstPath)){$relative=$p.Substring($repo.Length+1);$all[$relative]=Fact $p}
foreach($row in $first.records){if($row.image){$relative='game/'+$row.image.Substring(6);$f=Fact "$repo/$relative";if($f.sha256 -ne $row.sha256){throw 'ROOT_ACCEPTED_XIANGZHOU_IMAGE_CHANGED'};$all[$relative]=$f}}
foreach($p in $parent.external_run_before.PSObject.Properties){$external[$p.Name]=Fact "$repo/$($p.Name)"}
foreach($path in $all.Keys){$fixed['res://'+$path.Substring(5)]=$all[$path].sha256}
$fixture=Get-Content "$qa/cases02_residual_DRAFT.json" -Raw|ConvertFrom-Json
if(@($fixture.legs).Count -ne 2 -or $fixture.legs[0].id -ne 'openworld_qinghe_town' -or $fixture.legs[1].id -ne 'openworld_yanmen_pass'){throw 'ONLY_TWO_UNATTEMPTED_FULL_LEGS'}
$fixture.ready=$true;$fixture|Add-Member -NotePropertyName fixed_sources -NotePropertyValue $fixed
$fixture|Add-Member -NotePropertyName registered_save_paths -NotePropertyValue @($saves.Keys)
NewJson "$qa/actual02_READY.json" $fixture
$text=[IO.File]::ReadAllText("$qa/actual02_residual_DRAFT.gd").Replace("`r`n","`n").TrimEnd([char[]]"`r`n")+"`n"
$stream=[IO.File]::Open("$qa/actual02_READY.gd",[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes($text);$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
NewJson "$qa/freeze02_ROOT_ACTUAL.json" ([ordered]@{status='RESIDUAL_ORIGINAL170_ONEFAIL_RETAINED';sources=$all;exact_backups=$parent.exact_backups;saves=$saves;external_run_before=$external;external_policy=$parent.external_policy;script_path="$qa/actual02_READY.gd";script=(Fact "$qa/actual02_READY.gd");fixture_path="$qa/actual02_READY.json";fixture=(Fact "$qa/actual02_READY.json");geometry_path=$parent.geometry_path;geometry=$parent.geometry;geometry_residual_path=$parent.geometry_residual_path;geometry_residual=$parent.geometry_residual;original_actual_result=(Fact $firstPath);inherited_geometry_successes=1200;inherited_actual_scope='Xiangzhou World entry/32px/two accepted normal images/Router admission, not replayed';engine_calls=0;production_writes=0;save_contents_read=$false;save_writes=0})
Get-FileHash -LiteralPath "$qa/actual02_READY.gd","$qa/actual02_READY.json","$qa/freeze02_ROOT_ACTUAL.json"|Select-Object Path,Hash|ConvertTo-Json
