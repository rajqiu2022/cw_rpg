$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/three_settlements_20261030e_qa01"
$parentPath="$qa/freeze04_ROOT_ACTUAL.json";$parent=Get-Content -LiteralPath $parentPath -Raw|ConvertFrom-Json
$failurePath="$qa/actual/112804/result.json";$failure=Get-Content -LiteralPath $failurePath -Raw|ConvertFrom-Json
if($failure.passed -or $failure.checks -ne 172 -or $failure.input_ticks -ne 2 -or (($failure.errors)-join "`n") -cne 'GUARD_DIALOG_CLOSED_AFTER_REAL_HERO_ADVANCE_AND_CHOICE2'){throw 'EXACT04_FAIL_PLUS_NIL_UI_ACCESS_LOG_RETAINED_REQUIRED'}
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
function Same($a,$b){return $a.exists -eq $b.exists -and (!$a.exists -or ($a.sha256 -eq $b.sha256 -and $a.bytes -eq $b.bytes -and $a.utc_ticks -eq $b.utc_ticks))}
function NewJson([string]$p,$v){$stream=[IO.File]::Open($p,[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($v|ConvertTo-Json -Depth 28)+"`n");$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}}
if(Test-Path -LiteralPath "$qa/actual05_READY.gd"){throw 'IMMUTABLE05_ALREADY_EXISTS'}
if(!(Same (Fact $parent.script_path) $parent.script) -or !(Same (Fact $parent.fixture_path) $parent.fixture)){throw 'PARENT04_READY_CHANGED'}
$before=@'
		var box: Node=dialog.get("_box") as Node
		var choices_visible: bool=box!=null and (box.get("choices_container") as Control).visible
'@
$after=@'
		var layer: Node=dialog.get("_box") as Node
		var choices: Control=null
		if layer!=null:choices=layer.get_node_or_null("DialogBox/Frame/ChoicesContainer") as Control
		var choices_visible: bool=choices!=null and choices.is_visible_in_tree()
'@
$before=$before.Replace("`r`n","`n").TrimEnd([char[]]"`r`n")+"`n";$after=$after.Replace("`r`n","`n").TrimEnd([char[]]"`r`n")+"`n"
$text=[IO.File]::ReadAllText("$qa/actual05_dialog_path_DRAFT.gd")
if(($text.Split([string[]]@($after),[StringSplitOptions]::None).Count-1) -ne 1 -or ($text.Split([string[]]@('actual05_READY.json'),[StringSplitOptions]::None).Count-1) -ne 1){throw 'EXACT_UI_PATH_PLUS_FIXTURE_CONTEXT_REQUIRED'}
$reverse=$text.Replace($after,$before).Replace('actual05_READY.json','actual04_READY.json')
$hash=[Security.Cryptography.SHA256]::Create();try{$inverse=([BitConverter]::ToString($hash.ComputeHash([Text.UTF8Encoding]::new($false).GetBytes($reverse)))).Replace('-','').ToLower()}finally{$hash.Dispose()}
if($inverse -ne $parent.script.sha256){throw 'WHOLE_BYTE_INVERSE_TO_FROZEN04_REQUIRED'}
$all=[ordered]@{};$fixed=[ordered]@{}
foreach($p in $parent.sources.PSObject.Properties){$all[$p.Name]=$p.Value}
foreach($p in @($parentPath,$parent.script_path,$parent.fixture_path,$failurePath,"$qa/formal04_residual_actual_stderr.log")){$relative=$p.Substring($repo.Length+1);$all[$relative]=Fact $p}
foreach($path in $all.Keys){$fixed['res://'+$path.Substring(5)]=$all[$path].sha256}
$fixture=Get-Content -LiteralPath $parent.fixture_path -Raw|ConvertFrom-Json;$fixture.fixed_sources=$fixed
$fixture.scope=$fixture.scope+'; 05 only DialogLayer child DialogBox/Frame/ChoicesContainer read; 04 Nil UI access SCRIPT ERROR retained; no production changes'
NewJson "$qa/actual05_READY.json" $fixture
$stream=[IO.File]::Open("$qa/actual05_READY.gd",[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes($text);$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
NewJson "$qa/freeze05_ROOT_ACTUAL.json" ([ordered]@{status='05_ONLY_QA_DIALOG_CONTROL_PATH_04_SCRIPTERROR_RETAINED';sources=$all;exact_backups=$parent.exact_backups;saves=$parent.saves;external_run_before=$parent.external_run_before;external_policy=$parent.external_policy;script_path="$qa/actual05_READY.gd";script=(Fact "$qa/actual05_READY.gd");fixture_path="$qa/actual05_READY.json";fixture=(Fact "$qa/actual05_READY.json");geometry_path=$parent.geometry_path;geometry=$parent.geometry;geometry_residual_path=$parent.geometry_residual_path;geometry_residual=$parent.geometry_residual;original_actual_result=$parent.original_actual_result;parent_freeze=(Fact $parentPath);original04_failed_result=(Fact $failurePath);whole_inverse_to_04_sha256=$inverse;semantic_change='Only QA reads actual child Control under DialogLayer, with null guard';inherited_actual_scope=$parent.inherited_actual_scope;inherited_geometry_successes=1200;fresh_source_capture_performed=$false;geometry_replayed=$false;engine_calls=0;production_writes=0;save_contents_read=$false;save_writes=0})
Get-FileHash -LiteralPath "$qa/actual05_READY.gd","$qa/actual05_READY.json","$qa/freeze05_ROOT_ACTUAL.json"|ForEach-Object{[ordered]@{path=$_.Path;sha256=$_.Hash.ToLower()}}|ConvertTo-Json
