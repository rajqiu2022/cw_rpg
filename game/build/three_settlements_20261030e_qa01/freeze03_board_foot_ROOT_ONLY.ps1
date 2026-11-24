$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/three_settlements_20261030e_qa01"
$parentPath="$qa/freeze02_ROOT_ACTUAL.json";$parent=Get-Content -LiteralPath $parentPath -Raw|ConvertFrom-Json
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
function Same($a,$b){return $a.exists -eq $b.exists -and (!$a.exists -or ($a.sha256 -eq $b.sha256 -and $a.bytes -eq $b.bytes -and $a.utc_ticks -eq $b.utc_ticks))}
function NewJson([string]$p,$v){$stream=[IO.File]::Open($p,[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($v|ConvertTo-Json -Depth 26)+"`n");$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}}
if(Test-Path -LiteralPath "$qa/actual03_READY.gd"){throw 'IMMUTABLE03_ALREADY_EXISTS'}
if(!(Same (Fact $parent.script_path) $parent.script) -or !(Same (Fact $parent.fixture_path) $parent.fixture)){throw 'PARENT02_READY_CHANGED'}
$text=[IO.File]::ReadAllText("$qa/actual03_board_foot_DRAFT.gd")
if(($text.Split([string[]]@('actual03_READY.json'),[StringSplitOptions]::None).Count-1) -ne 1 -or ($text.Split([string[]]@('Vector2(3170,1740)'),[StringSplitOptions]::None).Count-1) -ne 1){throw 'EXACT_ONE_CONTEXT_AND_ONE_FOOT_HUNK_REQUIRED'}
$reverse=$text.Replace('actual03_READY.json','actual02_READY.json').Replace('Vector2(3170,1740)','Vector2(3170,1760)')
$hash=[Security.Cryptography.SHA256]::Create();try{$inverse=([BitConverter]::ToString($hash.ComputeHash([Text.UTF8Encoding]::new($false).GetBytes($reverse)))).Replace('-','').ToLower()}finally{$hash.Dispose()}
if($inverse -ne $parent.script.sha256){throw 'WHOLE_BYTE_INVERSE_TO_FROZEN02_REQUIRED'}
$all=[ordered]@{};$fixed=[ordered]@{}
# Inherit the exact 02 parent facts, not a source rebase or geometry replay.
foreach($p in $parent.sources.PSObject.Properties){$all[$p.Name]=$p.Value}
foreach($p in @($parentPath,$parent.script_path,$parent.fixture_path)){$relative=$p.Substring($repo.Length+1);$all[$relative]=Fact $p}
foreach($path in $all.Keys){$fixed['res://'+$path.Substring(5)]=$all[$path].sha256}
$fixture=Get-Content -LiteralPath $parent.fixture_path -Raw|ConvertFrom-Json
$fixture.fixed_sources=$fixed
$fixture.scope=$fixture.scope+'; 03 only public board nearfoot1760->1740; 02 engine never launched; all other route and presentation code exact inverse'
NewJson "$qa/actual03_READY.json" $fixture
$stream=[IO.File]::Open("$qa/actual03_READY.gd",[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes($text);$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
NewJson "$qa/freeze03_ROOT_ACTUAL.json" ([ordered]@{status='03_ONLY_BOARD_FOOT_SUCCESSOR_02_ENGINE_NOT_STARTED';sources=$all;exact_backups=$parent.exact_backups;saves=$parent.saves;external_run_before=$parent.external_run_before;external_policy=$parent.external_policy;script_path="$qa/actual03_READY.gd";script=(Fact "$qa/actual03_READY.gd");fixture_path="$qa/actual03_READY.json";fixture=(Fact "$qa/actual03_READY.json");geometry_path=$parent.geometry_path;geometry=$parent.geometry;geometry_residual_path=$parent.geometry_residual_path;geometry_residual=$parent.geometry_residual;original_actual_result=$parent.original_actual_result;parent_freeze=(Fact $parentPath);whole_inverse_to_02_sha256=$inverse;semantic_change='Only public near board foot (3170,1760)->(3170,1740); fixture path context successor only';inherited_actual_scope=$parent.inherited_actual_scope;inherited_geometry_successes=1200;fresh_source_capture_performed=$false;geometry_replayed=$false;engine_calls=0;production_writes=0;save_contents_read=$false;save_writes=0})
Get-FileHash -LiteralPath "$qa/actual03_READY.gd","$qa/actual03_READY.json","$qa/freeze03_ROOT_ACTUAL.json"|ForEach-Object{[ordered]@{path=$_.Path;sha256=$_.Hash.ToLower()}}|ConvertTo-Json
