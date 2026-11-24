$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/luoyang_garden_city_minimap_20261030b_qa01"
$b=Get-Content "$qa/closure_before_SUPPLEMENT.json" -Raw | ConvertFrom-Json
$a=Get-Content "$repo/game/build/luoyang_garden_city_minimap_20261030b_system01/ready03/auth_READY.json" -Raw | ConvertFrom-Json
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
function Same($x,$y){return $x.exists -eq $y.exists -and (!$x.exists -or ($x.sha256 -eq $y.sha256 -and $x.bytes -eq $y.bytes -and $x.utc_ticks -eq $y.utc_ticks))}
function NewJson([string]$p,$v){$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew);try{$z=[Text.UTF8Encoding]::new($false).GetBytes(($v | ConvertTo-Json -Depth 24)+"`n");$s.Write($z,0,$z.Length)}finally{$s.Dispose()}}
$all=[ordered]@{};$fixed=[ordered]@{};$saves=[ordered]@{};$external=[ordered]@{}
foreach($p in $b.protected_sources.PSObject.Properties){$f=Fact "$repo/$($p.Name)";if(!(Same $f $p.Value)){throw "PROTECTED:$($p.Name)"};$all[$p.Name]=$f}
foreach($section in @($a.sources,$a.new_modules)){foreach($p in $section.PSObject.Properties){$f=Fact "$repo/$($p.Name)";if($f.sha256 -ne $p.Value.sha256 -or $f.bytes -ne $p.Value.bytes){throw "AUTH:$($p.Name)"};$all[$p.Name]=$f}}
foreach($p in $b.exact_backups){if(!(Same (Fact $p.path) $p.fact)){throw "BACKUP:$($p.path)"}}
foreach($p in $b.registered_save_paths.PSObject.Properties){$f=Fact $p.Name;if(!(Same $f $p.Value)){throw "EXTERNAL_SAVE_CHANGE_PRESERVE_REPORT:$($p.Name)"};$saves[$p.Name]=$f}
foreach($p in $b.external_parallel_sources.PSObject.Properties){$external[$p.Name]=Fact "$repo/$($p.Name)"}
$world='game/scripts/ui/world_travel_minimap.gd';$all[$world]=Fact "$repo/$world"
foreach($path in $all.Keys){$fixed['res://'+$path.Substring(5)]=$all[$path].sha256}
$fixture=[ordered]@{ready=$true;scope='Only new Garden road view/current scene minimap/real32px marker update; no old room/world travel/zoom interaction';mini_script='res://build/luoyang_garden_city_minimap_20261030b_system01/city_minimap.gd';fixed_sources=$fixed;registered_save_paths=@($saves.Keys);world_helper_preserved_fresh=$all[$world]}
NewJson "$qa/minimap_READY.json" $fixture
$text=[IO.File]::ReadAllText("$qa/minimap_DRAFT.gd").Replace("`r`n","`n").TrimEnd([char[]]"`r`n")+"`n";$z=[Text.UTF8Encoding]::new($false).GetBytes($text);$s=[IO.File]::Open("$qa/minimap_READY.gd",[IO.FileMode]::CreateNew);try{$s.Write($z,0,$z.Length)}finally{$s.Dispose()}
NewJson "$qa/freeze_ROOT_ACTUAL.json" ([ordered]@{status='LOCAL_ROAD_MINIMAP_ONE_VIEW_ONLY';sources=$all;exact_backups=$b.exact_backups;saves=$saves;external_run_before=$external;external_policy='four parallel sources record-only from beginning';script=(Fact "$qa/minimap_READY.gd");fixture=(Fact "$qa/minimap_READY.json");engine_calls=0;production_writes=0;save_writes=0})
Get-FileHash -LiteralPath "$qa/minimap_READY.gd","$qa/minimap_READY.json","$qa/freeze_ROOT_ACTUAL.json" | Select-Object Path,Hash | ConvertTo-Json
