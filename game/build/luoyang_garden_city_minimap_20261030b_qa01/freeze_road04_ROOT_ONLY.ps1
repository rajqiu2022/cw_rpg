$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/luoyang_garden_city_minimap_20261030b_qa01"
$old=Get-Content "$qa/freeze_ROOT_ACTUAL.json" -Raw | ConvertFrom-Json
$before=Get-Content "$qa/residual04_before_ACTUAL.json" -Raw | ConvertFrom-Json
$a=Get-Content "$repo/game/build/luoyang_garden_city_minimap_20261030b_system01/residual04/closure_READY/auth_READY.json" -Raw | ConvertFrom-Json
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
function Same($x,$y){return $x.exists -eq $y.exists -and (!$x.exists -or ($x.sha256 -eq $y.sha256 -and $x.bytes -eq $y.bytes -and $x.utc_ticks -eq $y.utc_ticks))}
function NewJson([string]$p,$v){$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew);try{$z=[Text.UTF8Encoding]::new($false).GetBytes(($v | ConvertTo-Json -Depth 24)+"`n");$s.Write($z,0,$z.Length)}finally{$s.Dispose()}}
$authorized=@{};foreach($section in @($a.sources,$a.new_modules)){foreach($p in $section.PSObject.Properties){$authorized[$p.Name]=$p.Value}}
$all=[ordered]@{};$fixed=[ordered]@{};$saves=[ordered]@{};$external=[ordered]@{}
foreach($p in $old.sources.PSObject.Properties){$f=Fact "$repo/$($p.Name)";if(!$authorized.ContainsKey($p.Name) -and !(Same $f $p.Value)){throw "UNCHANGED_PROTECTION:$($p.Name)"};$all[$p.Name]=$f}
foreach($path in $authorized.Keys){$f=Fact "$repo/$path";if($f.sha256 -ne $authorized[$path].sha256 -or $f.bytes -ne $authorized[$path].bytes){throw "AUTH:$path"};$all[$path]=$f}
$backups=@($old.exact_backups)+@($before.exact_backups)
foreach($p in $backups){if(!(Same (Fact $p.path) $p.fact)){throw "BACKUP:$($p.path)"}}
foreach($p in $before.registered_save_paths.PSObject.Properties){$f=Fact $p.Name;if(!(Same $f $p.Value)){throw "SAVE_CHANGE_PRESERVE_REPORT:$($p.Name)"};$saves[$p.Name]=$f}
foreach($p in $old.external_run_before.PSObject.Properties){$external[$p.Name]=Fact "$repo/$($p.Name)"}
foreach($path in $all.Keys){$fixed['res://'+$path.Substring(5)]=$all[$path].sha256}
$fixture=[ordered]@{ready=$true;scope='Only road trunk/taper union residual, same normal Estate foot1568434, one image, no UI revalidation/input';fixed_sources=$fixed;registered_save_paths=@($saves.Keys);inherited_success='115984:110/0 mini UI and D4; original road ART rejected, only visual residual remains'}
NewJson "$qa/road04_READY.json" $fixture
$text=[IO.File]::ReadAllText("$qa/road04_DRAFT.gd").Replace("`r`n","`n").TrimEnd([char[]]"`r`n")+"`n";$z=[Text.UTF8Encoding]::new($false).GetBytes($text);$s=[IO.File]::Open("$qa/road04_READY.gd",[IO.FileMode]::CreateNew);try{$s.Write($z,0,$z.Length)}finally{$s.Dispose()}
NewJson "$qa/road04_freeze_ROOT_ACTUAL.json" ([ordered]@{status='ROAD_VISUAL_RESIDUAL04_ONLY';sources=$all;exact_backups=$backups;saves=$saves;external_run_before=$external;external_policy='four parallel record-only, never restore';script=(Fact "$qa/road04_READY.gd");fixture=(Fact "$qa/road04_READY.json");engine_calls=0;production_writes=0;save_writes=0})
Get-FileHash -LiteralPath "$qa/road04_READY.gd","$qa/road04_READY.json","$qa/road04_freeze_ROOT_ACTUAL.json" | Select-Object Path,Hash | ConvertTo-Json
