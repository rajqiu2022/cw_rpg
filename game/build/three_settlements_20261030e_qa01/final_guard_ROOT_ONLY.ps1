param([Parameter(Mandatory=$true)][string]$Suffix,[string]$FreezePath='F:/Code/RPG_GAME/game/build/three_settlements_20261030e_qa01/freeze_ROOT_ACTUAL.json')
$ErrorActionPreference='Stop'
if($Suffix -notmatch '^[A-Za-z0-9_-]+$'){throw 'SUFFIX'}
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/three_settlements_20261030e_qa01"
$resolvedFreeze=[IO.Path]::GetFullPath($FreezePath).Replace('\','/');if(!$resolvedFreeze.StartsWith("$qa/",[StringComparison]::OrdinalIgnoreCase)){throw 'FREEZE_MUST_BE_IN_QA'}
$frozen=Get-Content -LiteralPath $resolvedFreeze -Raw | ConvertFrom-Json
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
function Same($a,$b){return $a.exists -eq $b.exists -and (!$a.exists -or ($a.sha256 -eq $b.sha256 -and $a.bytes -eq $b.bytes -and $a.utc_ticks -eq $b.utc_ticks))}
$errors=@();$sources=[ordered]@{};$saves=[ordered]@{};$external=[ordered]@{};$deltas=@()
foreach($p in $frozen.sources.PSObject.Properties){$f=Fact "$repo/$($p.Name)";$sources[$p.Name]=$f;if(!(Same $f $p.Value)){$errors+="SOURCE:$($p.Name)"}}
foreach($p in $frozen.exact_backups){if(!(Same (Fact $p.path) $p.fact)){$errors+="BACKUP:$($p.path)"}}
foreach($p in $frozen.saves.PSObject.Properties){$f=Fact $p.Name;$saves[$p.Name]=$f;if(!(Same $f $p.Value)){$errors+="SAVE_PRESERVE_NO_RESTORE:$($p.Name)"}}
foreach($name in @('script','fixture')){$path=if($name -eq 'script'){if($frozen.script_path){$frozen.script_path}else{"$qa/actual_READY.gd"}}else{if($frozen.fixture_path){$frozen.fixture_path}else{"$qa/actual_READY.json"}};if(!(Same (Fact $path) $frozen.$name)){$errors+="FROZEN:$name"}}
if(!(Same (Fact $frozen.geometry_path) $frozen.geometry)){$errors+='FROZEN:geometry'}
if($frozen.geometry_residual_path -and !(Same (Fact $frozen.geometry_residual_path) $frozen.geometry_residual)){$errors+='FROZEN:four_feet_residual'}
foreach($p in $frozen.external_run_before.PSObject.Properties){$f=Fact "$repo/$($p.Name)";$external[$p.Name]=@{before=$p.Value;current=$f};if(!(Same $f $p.Value)){$deltas+=$p.Name}}
$result=[ordered]@{scope='THREE_NEW_SETTLEMENTS_ONLY';passed=($errors.Count -eq 0);errors=$errors;sources=$sources;source_count=$sources.Count;backup_count=@($frozen.exact_backups).Count;saves=$saves;save_count=$saves.Count;external_parallel_record_only=$external;external_deltas_record_only=$deltas;godot_processes=@(Get-CimInstance Win32_Process -Filter "name like 'Godot%'"|Select-Object ProcessId,CommandLine);engine_calls=0;production_writes=0;save_writes=0;processes_stopped=0}
$output="$qa/final_guard_$Suffix.json";$stream=[IO.File]::Open($output,[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($result|ConvertTo-Json -Depth 24)+"`n");$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
Get-FileHash -LiteralPath $output|Select-Object Path,Hash|ConvertTo-Json
if($errors.Count -ne 0){throw ($errors -join ';')}
