$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/three_settlements_20261030e_qa01"
$parentPath="$qa/freeze03_ROOT_ACTUAL.json";$parent=Get-Content -LiteralPath $parentPath -Raw|ConvertFrom-Json
$failurePath="$qa/actual/135908/result.json";$failure=Get-Content -LiteralPath $failurePath -Raw|ConvertFrom-Json
if($failure.passed -or $failure.checks -ne 164 -or $failure.input_ticks -ne 0 -or (($failure.errors)-join "`n") -cne 'EXACT_SERVICE_RESIDUAL_SETUP_FOOT'){throw 'EXACT03_ZERO_INPUT_FAIL_RETAINED_REQUIRED'}
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
function Same($a,$b){return $a.exists -eq $b.exists -and (!$a.exists -or ($a.sha256 -eq $b.sha256 -and $a.bytes -eq $b.bytes -and $a.utc_ticks -eq $b.utc_ticks))}
function NewJson([string]$p,$v){$stream=[IO.File]::Open($p,[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($v|ConvertTo-Json -Depth 28)+"`n");$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}}
if(Test-Path -LiteralPath "$qa/actual04_READY.gd"){throw 'IMMUTABLE04_ALREADY_EXISTS'}
if(!(Same (Fact $parent.script_path) $parent.script) -or !(Same (Fact $parent.fixture_path) $parent.fixture)){throw 'PARENT03_READY_CHANGED'}
$block=@'
	# Root default current ID is World: bootstrap through the public default entry,
	# then request the same-town service foot. No World Space/input/image replay.
	if not need(router.call("go_field_smart",id,null,"",-1,-1)==true,"PUBLIC_DEFAULT_FIELD_BOOTSTRAP_NOT_WORLD_ENTRY_REPLAY"):return false
	var bootstrap: Node=await wait_field(String(id))
	if bootstrap==null:return false
	records.append({"phase":"public_default_native_field_bootstrap_before_nearfoot","world_space_replayed":false,"inherited_images_replayed":false,"actor_camera_assignments":0})
'@
$block=$block.Replace("`r`n","`n").TrimEnd([char[]]"`r`n")+"`n"
$text=[IO.File]::ReadAllText("$qa/actual04_bootstrap_DRAFT.gd")
if(($text.Split([string[]]@($block),[StringSplitOptions]::None).Count-1) -ne 1 -or ($text.Split([string[]]@('actual04_READY.json'),[StringSplitOptions]::None).Count-1) -ne 1){throw 'EXACT_BOOTSTRAP_PLUS_FIXTURE_CONTEXT_REQUIRED'}
$reverse=$text.Replace($block,'').Replace('actual04_READY.json','actual03_READY.json')
$hash=[Security.Cryptography.SHA256]::Create();try{$inverse=([BitConverter]::ToString($hash.ComputeHash([Text.UTF8Encoding]::new($false).GetBytes($reverse)))).Replace('-','').ToLower()}finally{$hash.Dispose()}
if($inverse -ne $parent.script.sha256){throw 'WHOLE_BYTE_INVERSE_TO_FROZEN03_REQUIRED'}
$all=[ordered]@{};$fixed=[ordered]@{}
foreach($p in $parent.sources.PSObject.Properties){$all[$p.Name]=$p.Value}
foreach($p in @($parentPath,$parent.script_path,$parent.fixture_path,$failurePath)){$relative=$p.Substring($repo.Length+1);$all[$relative]=Fact $p}
foreach($path in $all.Keys){$fixed['res://'+$path.Substring(5)]=$all[$path].sha256}
$fixture=Get-Content -LiteralPath $parent.fixture_path -Raw|ConvertFrom-Json;$fixture.fixed_sources=$fixed
$fixture.scope=$fixture.scope+'; 04 only public default native bootstrap before same-town service nearfoot; no WorldSpace/old image replay; 03 164/1 zero-input FAIL retained'
NewJson "$qa/actual04_READY.json" $fixture
$stream=[IO.File]::Open("$qa/actual04_READY.gd",[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes($text);$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
NewJson "$qa/freeze04_ROOT_ACTUAL.json" ([ordered]@{status='04_ONLY_PUBLIC_BOOTSTRAP_03_164_ONEFAIL_RETAINED';sources=$all;exact_backups=$parent.exact_backups;saves=$parent.saves;external_run_before=$parent.external_run_before;external_policy=$parent.external_policy;script_path="$qa/actual04_READY.gd";script=(Fact "$qa/actual04_READY.gd");fixture_path="$qa/actual04_READY.json";fixture=(Fact "$qa/actual04_READY.json");geometry_path=$parent.geometry_path;geometry=$parent.geometry;geometry_residual_path=$parent.geometry_residual_path;geometry_residual=$parent.geometry_residual;original_actual_result=$parent.original_actual_result;parent_freeze=(Fact $parentPath);original03_failed_result=(Fact $failurePath);whole_inverse_to_03_sha256=$inverse;semantic_change='Only public default native bootstrap before existing same-town near setup; no direct Router/player/camera writes';inherited_actual_scope=$parent.inherited_actual_scope;inherited_geometry_successes=1200;fresh_source_capture_performed=$false;geometry_replayed=$false;engine_calls=0;production_writes=0;save_contents_read=$false;save_writes=0})
Get-FileHash -LiteralPath "$qa/actual04_READY.gd","$qa/actual04_READY.json","$qa/freeze04_ROOT_ACTUAL.json"|ForEach-Object{[ordered]@{path=$_.Path;sha256=$_.Hash.ToLower()}}|ConvertTo-Json
