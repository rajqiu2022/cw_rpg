param([Parameter(Mandatory=$true)][string]$ReadyFixture,[Parameter(Mandatory=$true)][string]$AuthorizationJson,[string]$OutputName='final_guard_ROOT_ACTUAL.json',[int[]]$OwnedProcessIds=@())
$ErrorActionPreference='Stop'
$taskRoot='F:/Code/RPG_GAME';$qaRoot=Join-Path $taskRoot 'game/build/luoyang_entry_20261029l_qa01'
function ResolvePath([string]$p){if($p.StartsWith('res://')){return Join-Path $taskRoot ('game/'+$p.Substring(6))};if([IO.Path]::IsPathRooted($p)){return $p};return Join-Path $taskRoot $p}
function Fact([string]$p){$p=ResolvePath $p;if(-not [IO.File]::Exists($p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant();bytes=$i.Length;utc_ticks=$i.LastWriteTimeUtc.Ticks.ToString()}}
function Same($a,$b){return $a.exists -eq $b.exists -and (-not $a.exists -or ($a.sha256 -ceq $b.sha256 -and $a.bytes -eq $b.bytes -and $a.utc_ticks -ceq $b.utc_ticks))}
$before=Get-Content -LiteralPath (Join-Path $qaRoot 'baseline_before_ACTUAL.json') -Raw|ConvertFrom-Json
$ready=Get-Content -LiteralPath (ResolvePath $ReadyFixture) -Raw|ConvertFrom-Json
$auth=Get-Content -LiteralPath (ResolvePath $AuthorizationJson) -Raw|ConvertFrom-Json
if(-not $ready.ready -or @($ready.registered_save_facts.PSObject.Properties).Count -ne 171){throw 'Only frozen one-entry fixture with existing 171 registered saves.'}
$errors=@();$sources=[ordered]@{};$authorized=@();$backups=@();$saves=[ordered]@{};$external=@()
foreach($entry in $before.sources.PSObject.Properties){
 $now=Fact $entry.Name;$sources[$entry.Name]=$now;$permit=$auth.sources.PSObject.Properties[$entry.Name]
 if($null-eq$permit){if(-not(Same $now $entry.Value)){$errors+="UNAUTHORIZED_SOURCE_CHANGE:$($entry.Name)"}}
 else{if($now.sha256-cne$permit.Value.sha256 -or $now.bytes-ne$permit.Value.bytes){$errors+="APPROVED_SOURCE_NOT_EXACT:$($entry.Name)"};if(-not(Same $now $entry.Value)){$authorized+=$entry.Name}}
}
foreach($entry in $ready.source_facts.PSObject.Properties){$now=Fact $entry.Name;$sources[$entry.Name]=$now;if(-not(Same $now $entry.Value)){$errors+="FROZEN_SOURCE_CHANGED:$($entry.Name)"}}
foreach($entry in $auth.new_modules.PSObject.Properties){$now=Fact $entry.Name;if(-not$now.exists -or $now.sha256-cne$entry.Value.sha256 -or $now.bytes-ne$entry.Value.bytes){$errors+="IMMUTABLE_MODULE_CHANGED:$($entry.Name)"}}
foreach($entry in $before.exact_backups){$now=Fact $entry.path;$backups+=@{source=$entry.source;path=$entry.path;fact=$now};if(-not(Same $now $entry.fact)){$errors+="BACKUP_CHANGED:$($entry.source)"}}
foreach($entry in $ready.registered_save_facts.PSObject.Properties){$now=Fact $entry.Name;$saves[$entry.Name]=$now;if(-not(Same $now $entry.Value)){$errors+="SAVE_CHANGED_DURING_ACTUAL:$($entry.Name)"}}
foreach($entry in $before.registered_save_paths.PSObject.Properties){$frozen=$ready.registered_save_facts.PSObject.Properties[$entry.Name].Value;if(-not(Same $entry.Value $frozen)){$external+=@{path=$entry.Name;before=$entry.Value;preserved_before_actual=$frozen}}}
$procs=@(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'"|Select-Object ProcessId,Name)
$ownAlive=@($procs|Where-Object {$OwnedProcessIds -contains [int]$_.ProcessId});$editor=(@($procs|Where-Object ProcessId -eq 51856).Count-eq1)
if(-not$editor){$errors+='EDITOR_51856_MISSING'};if($ownAlive.Count){$errors+='ROOT_OWNED_PROCESSES_STILL_ALIVE'}
$output=Join-Path $qaRoot $OutputName
$result=[ordered]@{status=$(if($errors.Count-eq0){'PASS'}else{'FAIL'});utc=[DateTime]::UtcNow.ToString('o');errors=$errors;sources=$sources;authorized_source_differences=$authorized;new_modules=$auth.new_modules;exact_backups=$backups;registered_save_paths=$saves;external_save_diffs_preserved_before_actual=$external;godot_processes=$procs;editor51856_present=$editor;root_owned_alive=$ownAlive;baseline_sha256=(Fact (Join-Path $qaRoot 'baseline_before_ACTUAL.json')).sha256;ready_fixture_sha256=(Fact $ReadyFixture).sha256;authorization_sha256=(Fact $AuthorizationJson).sha256;save_contents_read=$false;save_writes=0;production_writes=0;engine_calls=0;processes_stopped=0}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($result|ConvertTo-Json -Depth 30)+"`n")
$stream=[IO.File]::Open($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
[ordered]@{path=$output;sha256=(Fact $output).sha256;status=$result.status;errors=$errors.Count;frozen_sources=$sources.Count;backups=$backups.Count;registered_saves=$saves.Count;authorized_source_differences=$authorized.Count;engine_calls=0}|ConvertTo-Json -Compress
