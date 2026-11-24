$ErrorActionPreference='Stop'
$taskRoot='F:/Code/RPG_GAME';$qaRoot=Join-Path $taskRoot 'game/build/luoyang_entry_20261029l_qa01'
function Fact([string]$p){if(-not [IO.File]::Exists($p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant();bytes=$i.Length;utc_ticks=$i.LastWriteTimeUtc.Ticks.ToString()}}
function NewBytes([string]$p,[byte[]]$b){[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($p))|Out-Null;$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$s.Write($b,0,$b.Length)}finally{$s.Dispose()}}
$old=Get-Content -LiteralPath "$taskRoot/game/build/three_towns_world_20261029j_qa01/final_guard_CAMERA04_ROOT_ACTUAL.json" -Raw|ConvertFrom-Json
$oldBase=Get-Content -LiteralPath "$taskRoot/game/build/three_towns_world_20261029j_qa01/baseline_before_ACTUAL.json" -Raw|ConvertFrom-Json
$paths=@($oldBase.sources.PSObject.Properties|ForEach-Object Name)+@(
 'game/scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd',
 'game/scripts/city/luoyang_culture_integration_index_20261019x.gd',
 'game/data/luoyang_culture_integration_20261019x/runtime_contract.json',
 'game/scripts/city/luoyang_execution_authority_20261022ap.gd',
 'game/build/luoyang_city_full_rollout_20261022ap_npc01/presentation_execution.gd',
 'game/data/scenes/ch4_s0_luoyang_gate.tres',
 'game/scripts/field/world_v15_exit_zone.gd',
 'game/scripts/field/exit_zone.gd'
)
$sources=[ordered]@{};$backups=@();$oldDiff=@()
foreach($relative in ($paths|Select-Object -Unique)){
 $p=Join-Path $taskRoot $relative;$f=Fact $p;if(-not $f.exists){throw "Missing registered source: $relative"};$sources[$relative]=$f
 $copy=Join-Path $qaRoot ('source_before/'+$relative);NewBytes $copy ([IO.File]::ReadAllBytes($p));[IO.File]::SetLastWriteTimeUtc($copy,[DateTime]::new([long]$f.utc_ticks,[DateTimeKind]::Utc));$copied=Fact $copy
 if($copied.sha256 -cne $f.sha256 -or $copied.bytes -ne $f.bytes -or $copied.utc_ticks -cne $f.utc_ticks){throw 'Exact source backup differs.'};$backups+=@{source=$relative;path=$copy;fact=$copied}
}
foreach($entry in @($old.sources.PSObject.Properties)+@($old.new_modules.PSObject.Properties)){$now=Fact (Join-Path $taskRoot $entry.Name);if($now.sha256 -cne $entry.Value.sha256 -or $now.bytes -ne $entry.Value.bytes){$oldDiff+=@{path=$entry.Name;previous=$entry.Value;now=$now}}}
$saves=[ordered]@{};foreach($entry in $old.registered_save_paths.PSObject.Properties){$saves[$entry.Name]=Fact $entry.Name}
$procs=@(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'"|Select-Object ProcessId,Name)
$output=Join-Path $qaRoot 'baseline_before_ACTUAL.json'
$result=[ordered]@{status='LUOYANG_ONE_ENTRY_READONLY_BEFORE';utc=[DateTime]::UtcNow.ToString('o');sources=$sources;exact_backups=$backups;registered_save_paths=$saves;previous_guard_sha256=(Fact "$taskRoot/game/build/three_towns_world_20261029j_qa01/final_guard_CAMERA04_ROOT_ACTUAL.json").sha256;previous_guard_source_or_module_differences=$oldDiff;godot_processes=$procs;editor51856_present=(@($procs|Where-Object ProcessId -eq 51856).Count-eq1);save_contents_read=$false;save_writes=0;production_writes=0;engine_calls=0;processes_stopped=0}
NewBytes $output ([Text.UTF8Encoding]::new($false).GetBytes(($result|ConvertTo-Json -Depth 30)+"`n"))
[ordered]@{path=$output;sha256=(Fact $output).sha256;sources=$sources.Count;exact_backups=$backups.Count;registered_saves=$saves.Count;previous_guard_differences=$oldDiff.Count;engine_calls=0}|ConvertTo-Json -Compress
