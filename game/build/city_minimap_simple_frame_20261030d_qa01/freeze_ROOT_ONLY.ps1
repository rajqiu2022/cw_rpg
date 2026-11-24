$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/city_minimap_simple_frame_20261030d_qa01"
$b=Get-Content "$qa/baseline_before_ACTUAL.json" -Raw | ConvertFrom-Json
$a=Get-Content "$repo/game/build/city_minimap_simple_frame_20261030d_system01/ready02/auth_READY.json" -Raw | ConvertFrom-Json
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
function Same($x,$y){return $x.exists -eq $y.exists -and (!$x.exists -or ($x.sha256 -eq $y.sha256 -and $x.bytes -eq $y.bytes -and $x.utc_ticks -eq $y.utc_ticks))}
function NewJson([string]$p,$v){$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew);try{$z=[Text.UTF8Encoding]::new($false).GetBytes(($v | ConvertTo-Json -Depth 24)+"`n");$s.Write($z,0,$z.Length)}finally{$s.Dispose()}}
$all=[ordered]@{};$fixed=[ordered]@{};$saves=[ordered]@{};$external=[ordered]@{}
foreach($p in $b.protected_sources.PSObject.Properties){$f=Fact "$repo/$($p.Name)";if(!(Same $f $p.Value)){throw "PROTECTED:$($p.Name)"};$all[$p.Name]=$f}
foreach($section in @($a.sources,$a.new_modules)){foreach($p in $section.PSObject.Properties){$f=Fact "$repo/$($p.Name)";if($f.sha256 -ne $p.Value.sha256 -or $f.bytes -ne $p.Value.bytes){throw "AUTH:$($p.Name)"};$all[$p.Name]=$f}}
foreach($p in $b.exact_backups){if(!(Same (Fact $p.path) $p.fact)){throw "BACKUP:$($p.path)"}}
foreach($p in $b.registered_save_paths.PSObject.Properties){$f=Fact $p.Name;if(!(Same $f $p.Value)){throw "USER_SAVE_CHANGE_PRESERVE_AND_REPORT:$($p.Name)"};$saves[$p.Name]=$f}
foreach($p in $b.external_parallel_sources.PSObject.Properties){$external[$p.Name]=Fact "$repo/$($p.Name)"}
foreach($path in $all.Keys){$fixed['res://'+$path.Substring(5)]=$all[$path].sha256}
$fixture=[ordered]@{ready=$true;scope='Only simple translucent frame one normal image at Estate1600434/0INPUT; inherit346+94; no old cache matrix';fixed_sources=$fixed;registered_save_paths=@($saves.Keys)}
NewJson "$qa/frame_READY.json" $fixture
$text=[IO.File]::ReadAllText("$qa/frame_DRAFT.gd").Replace("`r`n","`n").TrimEnd([char[]]"`r`n")+"`n";$z=[Text.UTF8Encoding]::new($false).GetBytes($text);$s=[IO.File]::Open("$qa/frame_READY.gd",[IO.FileMode]::CreateNew);try{$s.Write($z,0,$z.Length)}finally{$s.Dispose()}
NewJson "$qa/freeze_ROOT_ACTUAL.json" ([ordered]@{status='SIMPLE_TRANSLUCENT_FRAME_ONLY';sources=$all;exact_backups=$b.exact_backups;saves=$saves;external_run_before=$external;external_policy='Four parallel paths record-only from beginning';script=(Fact "$qa/frame_READY.gd");fixture=(Fact "$qa/frame_READY.json");engine_calls=0;production_writes=0;save_writes=0})
Get-FileHash -LiteralPath "$qa/frame_READY.gd","$qa/frame_READY.json","$qa/freeze_ROOT_ACTUAL.json" | Select-Object Path,Hash | ConvertTo-Json
