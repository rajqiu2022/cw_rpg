param(
 [Parameter(Mandatory=$true)][string]$ReadyFixture,
 [Parameter(Mandatory=$true)][string]$AuthorizationJson,
 [string]$OutputName='final_guard_ROOT_ACTUAL.json',
 [int[]]$OwnedProcessIds=@()
)
$ErrorActionPreference='Stop'
$taskRoot='F:\Code\RPG_GAME';$qaRoot=Join-Path $taskRoot 'game/build/jinling_city_20261029_qa01'
function ResolveFactPath([string]$p){if($p.StartsWith('res://')){return Join-Path $taskRoot ('game/'+$p.Substring(6))};if([IO.Path]::IsPathRooted($p)){return $p};return Join-Path $taskRoot $p}
function Fact([string]$p){$p=ResolveFactPath $p;if(-not [IO.File]::Exists($p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant();bytes=$i.Length;utc_ticks=$i.LastWriteTimeUtc.Ticks.ToString()}}
function Same($a,$b){return $a.exists -eq $b.exists -and (-not $a.exists -or ($a.sha256 -ceq $b.sha256 -and $a.bytes -eq $b.bytes -and $a.utc_ticks -ceq $b.utc_ticks))}
function WriteNew([string]$p,[byte[]]$bytes){$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()}}
$output=Join-Path $qaRoot $OutputName
if([IO.File]::Exists($output)){throw 'CreateNew guard receipt already exists; preserve it.'}
$baseline=Get-Content -LiteralPath (Join-Path $qaRoot 'baseline_before_ACTUAL.json') -Raw|ConvertFrom-Json
$ready=Get-Content -LiteralPath (ResolveFactPath $ReadyFixture) -Raw|ConvertFrom-Json
$auth=Get-Content -LiteralPath (ResolveFactPath $AuthorizationJson) -Raw|ConvertFrom-Json
if(-not $ready.ready -or @($baseline.sources.PSObject.Properties).Count -ne 28 -or @($ready.save15.PSObject.Properties).Count -ne 15){throw 'Only the bounded Jinling baseline/READY contract is accepted.'}
$errors=@();$sources=[ordered]@{};$authorizedDiff=@()
foreach($entry in $baseline.sources.PSObject.Properties){
 $path=$entry.Name;$now=Fact $path;$sources[$path]=$now;$permit=$auth.sources.PSObject.Properties[$path]
 if($null -eq $permit){if(-not (Same $now $entry.Value)){$errors+="UNAUTHORIZED_SOURCE_CHANGE:$path"}}
 else {if($now.sha256 -cne $permit.Value.sha256 -or $now.bytes -ne $permit.Value.bytes){$errors+="AUTHORIZED_SOURCE_NOT_EXACT_SUCCESSOR:$path"};if(-not (Same $now $entry.Value)){$authorizedDiff+=$path}}
}
foreach($entry in $ready.source_facts.PSObject.Properties){$now=Fact $entry.Name;$sources[$entry.Name]=$now;if(-not (Same $now $entry.Value)){$errors+="FROZEN_SOURCE_CHANGED:$($entry.Name)"}}
foreach($entry in $auth.new_modules.PSObject.Properties){$now=Fact $entry.Name;if(-not $now.exists -or $now.sha256 -cne $entry.Value.sha256 -or $now.bytes -ne $entry.Value.bytes){$errors+="NEW_MODULE_NOT_EXACT_AUTHORIZED:$($entry.Name)"}}
$backups=@();foreach($entry in $baseline.exact_backups){$now=Fact $entry.path;$backups+=@{source=$entry.source;path=$entry.path;fact=$now};if(-not (Same $now $entry.fact)){$errors+="FULL_BACKUP_CHANGED:$($entry.source)"}}
$saves=[ordered]@{};$externalSaveDiff=@()
foreach($entry in $ready.save15.PSObject.Properties){$now=Fact $entry.Name;$saves[$entry.Name]=$now;if(-not (Same $now $entry.Value)){$errors+="SAVE_CHANGED_AFTER_FREEZE:$($entry.Name)"}}
foreach($entry in $baseline.save15.PSObject.Properties){if(-not (Same $ready.save15.($entry.Name) $entry.Value)){$externalSaveDiff+=@{path=$entry.Name;original=$entry.Value;preserved_pre_actual=$ready.save15.($entry.Name)}}}
$media=[ordered]@{};foreach($entry in $baseline.related_original_media.PSObject.Properties){$now=Fact $entry.Name;$media[$entry.Name]=$now;if(-not (Same $now $entry.Value)){$errors+="ORIGINAL_RELATED_MEDIA_CHANGED:$($entry.Name)"}}
foreach($entry in $ready.new_water_facts.PSObject.Properties){$now=Fact $entry.Name;$media[$entry.Name]=$now;if(-not (Same $now $entry.Value)){$errors+="NEW_WATER_LEAF_CHANGED:$($entry.Name)"}}
$processes=@(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'"|Select-Object ProcessId,Name)
$editorPresent=@($processes|Where-Object ProcessId -eq 51856).Count -eq 1
if(-not $editorPresent){$errors+='EDITOR_51856_NOT_PRESENT'}
$ownAlive=@($processes|Where-Object {$OwnedProcessIds -contains [int]$_.ProcessId})
if($ownAlive.Count -gt 0){$errors+='ROOT_OWNED_PROCESSES_STILL_RUNNING'}
$result=[ordered]@{status=$(if($errors.Count -eq 0){'PASS'}else{'FAIL'});utc=[DateTime]::UtcNow.ToString('o');errors=$errors;sources=$sources;authorized_source_diffs=$authorizedDiff;new_modules=$auth.new_modules;exact_backups=$backups;save15=$saves;external_save_diffs_preserved_before_freeze=$externalSaveDiff;related_media=$media;godot_processes=$processes;editor51856_present=$editorPresent;root_owned_alive=$ownAlive;other_user_processes_not_stopped=$true;baseline_sha256=(Fact (Join-Path $qaRoot 'baseline_before_ACTUAL.json')).sha256;ready_fixture_sha256=(Fact $ReadyFixture).sha256;authorization_sha256=(Fact $AuthorizationJson).sha256;engine_calls=0;save_writes=0;canonical_writes=0;media_writes=0;processes_stopped=0}
WriteNew $output ([Text.UTF8Encoding]::new($false).GetBytes(($result|ConvertTo-Json -Depth 30)+"`n"))
[ordered]@{path=$output;sha256=(Fact $output).sha256;status=$result.status;errors=$errors.Count;baseline_sources=28;frozen_sources=@($ready.source_facts.PSObject.Properties).Count;saves=15;original_media=12;new_water_leaf_count=@($ready.new_water_facts.PSObject.Properties).Count;engine_calls=0}|ConvertTo-Json -Compress
