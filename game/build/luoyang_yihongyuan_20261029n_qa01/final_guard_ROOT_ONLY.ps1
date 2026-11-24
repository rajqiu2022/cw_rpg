param([Parameter(Mandatory=$true)][string]$Suffix,[string]$Trip='trip03')
$ErrorActionPreference='Stop'
if($Suffix -notmatch '^[A-Za-z0-9_-]+$' -or $Trip -notin @('trip','trip02','trip03')){throw 'SUFFIX'}
$qa='F:/Code/RPG_GAME/game/build/luoyang_yihongyuan_20261029n_qa01';$repo='F:/Code/RPG_GAME'
$frozen=Get-Content "$qa/${Trip}_freeze_ROOT_ACTUAL.json" -Raw | ConvertFrom-Json
function Fact([string]$p){
 if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}}
 $i=Get-Item -LiteralPath $p
 return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}
}
function EqualFact($x,$y){return $x.exists -eq $y.exists -and (!$x.exists -or ($x.sha256 -eq $y.sha256 -and $x.bytes -eq $y.bytes -and $x.utc_ticks -eq $y.utc_ticks))}
$errors=[Collections.Generic.List[string]]::new();$sources=[ordered]@{};$saves=[ordered]@{}
foreach($p in $frozen.sources.PSObject.Properties){$f=Fact "$repo/$($p.Name)";$sources[$p.Name]=$f;if(!(EqualFact $f $p.Value)){$errors.Add("SOURCE:$($p.Name)")}}
foreach($p in $frozen.exact_backups){if(!(EqualFact (Fact $p.path) $p.fact)){$errors.Add("BACKUP:$($p.path)")}}
foreach($p in $frozen.saves.PSObject.Properties){$f=Fact $p.Name;$saves[$p.Name]=$f;if(!(EqualFact $f $p.Value)){$errors.Add("SAVE:$($p.Name)")}}
foreach($n in @('script','fixture')){$path=if($n -eq 'script'){"$qa/${Trip}_READY.gd"}else{"$qa/${Trip}_READY.json"};if(!(EqualFact (Fact $path) $frozen.$n)){$errors.Add("FROZEN_TOOL:$n")}}
$processes=@(Get-CimInstance Win32_Process -Filter "name like 'Godot%'" | Select-Object ProcessId,Name,CommandLine)
$result=[ordered]@{status='FINAL_LOCAL_YIHONGYUAN_GUARD';passed=($errors.Count -eq 0);errors=@($errors);sources=$sources;source_count=$sources.Count;backup_count=@($frozen.exact_backups).Count;saves=$saves;save_count=$saves.Count;godot_processes=$processes;engine_calls=0;production_writes=0;save_writes=0;processes_stopped=0}
$path="$qa/final_guard_$Suffix.json";$stream=[IO.File]::Open($path,[IO.FileMode]::CreateNew)
try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($result | ConvertTo-Json -Depth 20)+"`n");$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
Get-FileHash -LiteralPath $path -Algorithm SHA256 | Select-Object Path,Hash | ConvertTo-Json
if($errors.Count -ne 0){throw ($errors -join ';')}
