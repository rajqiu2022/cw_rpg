param([Parameter(Mandatory=$true)][string]$DeltaAuth)
$ErrorActionPreference='Stop'
$qa='F:/Code/RPG_GAME/game/build/luoyang_yihongyuan_20261029n_qa01';$repo='F:/Code/RPG_GAME'
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
function EqualFact($x,$y){return $x.exists -eq $y.exists -and (!$x.exists -or ($x.sha256 -eq $y.sha256 -and $x.bytes -eq $y.bytes -and $x.utc_ticks -eq $y.utc_ticks))}
function NewJson([string]$p,$v){$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew);try{$u=[Text.UTF8Encoding]::new($false);$z=$u.GetBytes(($v | ConvertTo-Json -Depth 30)+"`n");$s.Write($z,0,$z.Length)}finally{$s.Dispose()}}
$base=Get-Content "$qa/trip_freeze_ROOT_ACTUAL.json" -Raw | ConvertFrom-Json
$initial=Get-Content "$repo/game/build/luoyang_yihongyuan_20261029n_system01/closure_READY01/auth_READY.json" -Raw | ConvertFrom-Json
$delta=Get-Content -LiteralPath $DeltaAuth -Raw | ConvertFrom-Json
$auth=[ordered]@{sources=[ordered]@{};new_modules=[ordered]@{}}
foreach($inputAuth in @($initial,$delta)){foreach($name in @('sources','new_modules')){foreach($p in $inputAuth.$name.PSObject.Properties){$auth[$name][$p.Name]=$p.Value}}}
$all=[ordered]@{};$fixed=[ordered]@{}
foreach($p in $base.sources.PSObject.Properties){$f=Fact "$repo/$($p.Name)";if(!$auth.sources.Contains($p.Name) -and !$auth.new_modules.Contains($p.Name) -and !(EqualFact $f $p.Value)){throw "UNAUTHORIZED $($p.Name)"};$all[$p.Name]=$f}
foreach($section in @($auth.sources,$auth.new_modules)){foreach($path in $section.Keys){$f=Fact "$repo/$path";if($f.sha256 -ne $section[$path].sha256 -or $f.bytes -ne $section[$path].bytes){throw "AUTH $path"};$all[$path]=$f}}
foreach($path in $all.Keys){$fixed['res://'+$path.Substring(5)]=$all[$path].sha256}
foreach($p in $base.exact_backups){if(!(EqualFact (Fact $p.path) $p.fact)){throw "BACKUP $($p.path)"}}
$saves=[ordered]@{};$saveChanges=@()
foreach($p in $base.saves.PSObject.Properties){$f=Fact $p.Name;$saves[$p.Name]=$f;if(!(EqualFact $f $p.Value)){$saveChanges+=@{path=$p.Name;original=$p.Value;current=$f}}}
NewJson "$qa/user_save_changes_before03.json" ([ordered]@{reason='Root confirms user independently started then exited editor child107880; preserve current, never restore; not original-zero-delta';changes=$saveChanges;metadata_only=$true;save_writes=0})
$fixture=Get-Content "$qa/trip02_READY.json" -Raw | ConvertFrom-Json
$fixture.fixed_sources=$fixed
$fixture | Add-Member residual_only $true
$fixture.inherited_actual='01 outside two legs/three body; 02 actual126584 formal enter/inside approach/Hero-first + keeper exact portrait/no choices + static identity/state passed; original whole FAILs retained'
$fixture.scope='RESIDUAL03: public versioned room resume at counter; inside image; real walk/Space exit exact street return; W12 doorway outside image. No dialogue/old approach/shape retests.'
NewJson "$qa/auth_FINAL_VISUAL03.json" $auth
NewJson "$qa/trip03_READY.json" $fixture
$bytes=[IO.File]::ReadAllBytes("$qa/trip_DRAFT.gd");$s=[IO.File]::Open("$qa/trip03_READY.gd",[IO.FileMode]::CreateNew);try{$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()}
NewJson "$qa/trip03_freeze_ROOT_ACTUAL.json" ([ordered]@{status='FROZEN_RESIDUAL03_ONLY';sources=$all;exact_backups=$base.exact_backups;saves=$saves;user_save_changes_before03=(Fact "$qa/user_save_changes_before03.json");script=(Fact "$qa/trip03_READY.gd");fixture=(Fact "$qa/trip03_READY.json");delta_auth=(Fact $DeltaAuth);engine_calls=0;production_writes=0;save_writes=0;processes_stopped=0})
Get-FileHash -LiteralPath "$qa/trip03_READY.gd","$qa/trip03_READY.json","$qa/trip03_freeze_ROOT_ACTUAL.json","$qa/auth_FINAL_VISUAL03.json" | Select-Object Path,Hash | ConvertTo-Json
