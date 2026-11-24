param([Parameter(Mandatory=$true)][string]$Suffix)
$ErrorActionPreference='Stop'
if($Suffix -notmatch '^[A-Za-z0-9_-]+$'){throw 'SUFFIX'}
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/luoyang_garden_city_minimap_20261030b_qa01"
$frozen=Get-Content "$qa/freeze_ROOT_ACTUAL.json" -Raw | ConvertFrom-Json
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
function Same($x,$y){return $x.exists -eq $y.exists -and (!$x.exists -or ($x.sha256 -eq $y.sha256 -and $x.bytes -eq $y.bytes -and $x.utc_ticks -eq $y.utc_ticks))}
$errors=@();$sources=[ordered]@{};$saves=[ordered]@{}
foreach($p in $frozen.sources.PSObject.Properties){$f=Fact "$repo/$($p.Name)";$sources[$p.Name]=$f;if(!(Same $f $p.Value)){$errors+="SOURCE:$($p.Name)"}}
foreach($p in $frozen.exact_backups){if(!(Same (Fact $p.path) $p.fact)){$errors+="BACKUP:$($p.path)"}}
foreach($p in $frozen.saves.PSObject.Properties){$f=Fact $p.Name;$saves[$p.Name]=$f;if(!(Same $f $p.Value)){$errors+="SAVE:$($p.Name)"}}
foreach($name in @('script','fixture')){$path=if($name -eq 'script'){"$qa/minimap_READY.gd"}else{"$qa/minimap_READY.json"};if(!(Same (Fact $path) $frozen.$name)){$errors+="FROZEN:$name"}}
$external=[ordered]@{};$externalDeltas=@()
foreach($p in $frozen.external_run_before.PSObject.Properties){$f=Fact "$repo/$($p.Name)";$external[$p.Name]=@{before=$p.Value;current=$f};if(!(Same $f $p.Value)){$externalDeltas+=$p.Name}}
$result=[ordered]@{scope='LOCAL_ROAD_MINIMAP30B_ONLY; four parallel paths record-only from start, no rollback';external_parallel=$external;external_deltas_record_only=$externalDeltas;passed=($errors.Count -eq 0);errors=$errors;sources=$sources;source_count=$sources.Count;backup_count=@($frozen.exact_backups).Count;saves=$saves;save_count=$saves.Count;godot_processes=@(Get-CimInstance Win32_Process -Filter "name like 'Godot%'" | Select-Object ProcessId,CommandLine);engine_calls=0;production_writes=0;save_writes=0;processes_stopped=0}
$path="$qa/final_guard_$Suffix.json";$stream=[IO.File]::Open($path,[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($result | ConvertTo-Json -Depth 20)+"`n");$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
Get-FileHash -LiteralPath $path | Select-Object Path,Hash | ConvertTo-Json
if($errors.Count -ne 0){throw ($errors -join ';')}






