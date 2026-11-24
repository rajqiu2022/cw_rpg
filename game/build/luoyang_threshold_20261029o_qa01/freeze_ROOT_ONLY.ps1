param([Parameter(Mandatory=$true)][string]$Auth)
$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/luoyang_threshold_20261029o_qa01"
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
function Same($x,$y){return $x.exists -eq $y.exists -and (!$x.exists -or ($x.sha256 -eq $y.sha256 -and $x.bytes -eq $y.bytes -and $x.utc_ticks -eq $y.utc_ticks))}
function NewJson([string]$p,$v){$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($v | ConvertTo-Json -Depth 25)+"`n");$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()}}
$b=Get-Content "$qa/baseline_before_ACTUAL.json" -Raw | ConvertFrom-Json
$entry=Get-Content "$qa/entry_before_SUPPLEMENT.json" -Raw | ConvertFrom-Json
$a=Get-Content -LiteralPath $Auth -Raw | ConvertFrom-Json
$authorized=@{};foreach($section in @($a.sources,$a.new_modules)){foreach($p in $section.PSObject.Properties){$authorized[$p.Name]=$p.Value}}
$facts=[ordered]@{};$fixed=[ordered]@{};$saves=[ordered]@{}
foreach($section in @($b.sources,$b.protected_sources)){
 foreach($p in $section.PSObject.Properties){$f=Fact "$repo/$($p.Name)";if(!$authorized.ContainsKey($p.Name) -and !(Same $f $p.Value)){throw "UNAUTHORIZED:$($p.Name)"};$facts[$p.Name]=$f}
}
foreach($path in $authorized.Keys){$f=Fact "$repo/$path";if($f.sha256 -ne $authorized[$path].sha256 -or $f.bytes -ne $authorized[$path].bytes){throw "AUTH:$path"};$facts[$path]=$f}
$backups=@($b.exact_backups)+@($entry)
foreach($p in $backups){if(!(Same (Fact $p.path) $p.fact)){throw "BACKUP:$($p.path)"}}
foreach($p in $b.registered_save_paths.PSObject.Properties){$f=Fact $p.Name;if(!(Same $f $p.Value)){throw "USER_SAVE_CHANGED_PRESERVE_AND_REVIEW:$($p.Name)"};$saves[$p.Name]=$f}
foreach($path in $facts.Keys){$fixed['res://'+$path.Substring(5)]=$facts[$path].sha256}
$fixture=[ordered]@{ready=$true;scope='ONLY_ESTATE_MAIN_HALL_THRESHOLD; not World or prior city replay';source_region='luoyang_estate_region_27d';source_logical='luoyang_estate_riverside_20261021ai';legacy_uv=@(.5,.947265625);front_foot=@(1536,2060);barrier_front_y=1971;entrance_id='estate27d_hall_door';target_region='estate27d_living_hall';target_spawn=@(960,1260);exit_id='estate27d_living_hall_exit';return_foot=@(1536,2060);fixed_sources=$fixed;registered_save_paths=@($saves.Keys)}
NewJson "$qa/door_READY.json" $fixture
$bytes=[IO.File]::ReadAllBytes("$qa/door_DRAFT.gd");$s=[IO.File]::Open("$qa/door_READY.gd",[IO.FileMode]::CreateNew);try{$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()}
NewJson "$qa/freeze_ROOT_ACTUAL.json" ([ordered]@{status='FROZEN_ONE_THRESHOLD_ONLY';sources=$facts;exact_backups=$backups;saves=$saves;script=(Fact "$qa/door_READY.gd");fixture=(Fact "$qa/door_READY.json");auth=(Fact $Auth);engine_calls=0;production_writes=0;save_writes=0;processes_stopped=0})
Get-FileHash -LiteralPath "$qa/door_READY.gd","$qa/door_READY.json","$qa/freeze_ROOT_ACTUAL.json" | Select-Object Path,Hash | ConvertTo-Json
