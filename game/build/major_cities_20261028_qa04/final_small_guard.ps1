param(
 [Parameter(Mandatory=$true)][string]$AuthorizedSourcesJson,
 [Parameter(Mandatory=$true)][string]$OutputName,
 [string]$NewMediaFactsJson,
 [string]$NewModulesBeforeJson,
 [string]$FreshSaveBeforeJson,
 [int[]]$OwnedProcessIds=@()
)
$ErrorActionPreference='Stop'
$taskRoot='F:\Code\RPG_GAME';$qaRoot=Join-Path $taskRoot 'game/build/major_cities_20261028_qa04'
function Fact([string]$p){if(-not [IO.File]::Exists($p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant();bytes=$i.Length;utc_ticks=$i.LastWriteTimeUtc.Ticks.ToString()}}
function Same($a,$b){if([bool]$a.exists -ne [bool]$b.exists){return $false};if(-not $a.exists){return $true};return $a.sha256 -ceq $b.sha256 -and [long]$a.bytes -eq [long]$b.bytes -and $a.utc_ticks -ceq $b.utc_ticks}
function WriteNew([string]$p,[byte[]]$bytes){$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()}}
if([IO.Path]::GetFileName($OutputName) -cne $OutputName -or -not $OutputName.EndsWith('.json')){throw 'Receipt must be a new basename in qa04.'}
$output=Join-Path $qaRoot $OutputName;if([IO.File]::Exists($output)){throw 'Preserve previous receipt; CreateNew only.'}
$baseline=Get-Content -LiteralPath (Join-Path $qaRoot 'baseline_before_ACTUAL.json') -Raw|ConvertFrom-Json
$plan=Get-Content -LiteralPath $AuthorizedSourcesJson -Raw|ConvertFrom-Json
$auth=@{};foreach($p in $plan.sources.PSObject.Properties){if($baseline.mutable_targets -cnotcontains $p.Name){throw 'Canonical authorization exceeds original three dedicated targets.'};$auth[$p.Name]=$p.Value}
$failures=@();$sources=[ordered]@{};$authorizedChanges=@()
foreach($p in $baseline.sources15.PSObject.Properties){
 $now=Fact (Join-Path $taskRoot $p.Name);$sources[$p.Name]=$now
 if($auth.ContainsKey($p.Name)){
  $expected=$auth[$p.Name]
  if(-not $now.exists -or $now.sha256 -cne $expected.sha256 -or [long]$now.bytes -ne [long]$expected.bytes){$failures+='AUTHORIZED_SOURCE_MISMATCH:'+ $p.Name}
  if(-not (Same $p.Value $now)){$authorizedChanges+=$p.Name}
 }elseif(-not (Same $p.Value $now)){$failures+='READONLY_SOURCE_CHANGED:'+ $p.Name}
}
$backupFacts=@();foreach($b in $baseline.exact_full_backups){$now=Fact $b.path;$backupFacts+=@{path=$b.path;fact=$now};if(-not (Same $b.fact $now)){$failures+='FULL_BACKUP_CHANGED:'+ $b.source}}
$newModules=[ordered]@{};$newModulesBefore=$null
if($NewModulesBeforeJson){$newModulesBefore=Get-Content -LiteralPath $NewModulesBeforeJson -Raw|ConvertFrom-Json}
foreach($p in $plan.new_modules.PSObject.Properties){
 if($p.Name -notmatch '^game/build/bianzhou_city_20261028_system0[14]/[^/]+\.(gd|json)$'){throw 'New module must stay in explicit dedicated Bianzhou directory.'}
 if($null -eq $newModulesBefore -or $null -eq $newModulesBefore.PSObject.Properties[$p.Name]){throw 'Fresh before fact required for each new module.'}
 $now=Fact (Join-Path $taskRoot $p.Name);$newModules[$p.Name]=@{before=$newModulesBefore.PSObject.Properties[$p.Name].Value;after=$now}
 if(-not $now.exists -or $now.sha256 -cne $p.Value.sha256 -or [long]$now.bytes -ne [long]$p.Value.bytes){$failures+='NEW_MODULE_MISMATCH:'+ $p.Name}
}
$expectedSaves=$baseline.save15;$externalSaveChanges=@()
if($FreshSaveBeforeJson){
 $expectedSaves=Get-Content -LiteralPath $FreshSaveBeforeJson -Raw|ConvertFrom-Json
 if(@($expectedSaves.PSObject.Properties).Count -ne 15){throw 'Fresh saves must contain exactly the original fifteen path keys.'}
 foreach($p in $baseline.save15.PSObject.Properties){if($null -eq $expectedSaves.PSObject.Properties[$p.Name]){throw 'Fresh save path set differs.'};if(-not (Same $p.Value $expectedSaves.PSObject.Properties[$p.Name].Value)){$externalSaveChanges+=$p.Name}}
}
$saveFacts=[ordered]@{};foreach($p in $expectedSaves.PSObject.Properties){$now=Fact $p.Name;$saveFacts[$p.Name]=$now;if(-not (Same $p.Value $now)){$failures+='SAVE_CHANGED_DURING_AUTHORIZED_INTERVAL:'+ $p.Name}}
$mediaFacts=[ordered]@{};foreach($p in $baseline.related_media.PSObject.Properties){$now=Fact (Join-Path $taskRoot $p.Name);$mediaFacts[$p.Name]=$now;if(-not (Same $p.Value $now)){$failures+='OLD_RELATED_MEDIA_CHANGED:'+ $p.Name}}
$newMedia=[ordered]@{}
if($NewMediaFactsJson){$expected=Get-Content -LiteralPath $NewMediaFactsJson -Raw|ConvertFrom-Json;foreach($p in $expected.PSObject.Properties){$now=Fact (Join-Path $taskRoot $p.Name);$newMedia[$p.Name]=$now;if(-not (Same $p.Value $now)){$failures+='NEW_FROZEN_MEDIA_CHANGED:'+ $p.Name}}}
$processes=@(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'"|Select-Object ProcessId,Name)
foreach($pidToCheck in $OwnedProcessIds){if(@($processes|Where-Object ProcessId -eq $pidToCheck).Count -gt 0){$failures+='ROOT_OWNED_PROCESS_STILL_ACTIVE:'+ $pidToCheck}}
$editorPresent=@($processes|Where-Object ProcessId -eq 51856).Count -eq 1;if(-not $editorPresent){$failures+='EDITOR51856_NOT_PRESENT'}
$receipt=[ordered]@{passed=($failures.Count -eq 0);errors=$failures;utc=[DateTime]::UtcNow.ToString('o');baseline_sha256=(Fact (Join-Path $qaRoot 'baseline_before_ACTUAL.json')).sha256;authorization_plan_sha256=(Fact $AuthorizedSourcesJson).sha256;sources15=$sources;authorized_source_changes=$authorizedChanges;exact_backups3=$backupFacts;new_modules=$newModules;save15=$saveFacts;external_save_changes_before_interval_preserved=$externalSaveChanges;related_media69=$mediaFacts;new_media=$newMedia;godot_processes=$processes;root_owned_pids_checked=$OwnedProcessIds;editor51856_present=$editorPresent;canonical_writes=0;save_writes=0;media_writes=0;processes_stopped=0;engine_calls=0;save_contents_parsed=$false}
WriteNew $output ([Text.UTF8Encoding]::new($false).GetBytes(($receipt|ConvertTo-Json -Depth 24)+"`n"))
[ordered]@{path=$output;sha256=(Fact $output).sha256;passed=$receipt.passed;errors=$failures.Count;source_count=$sources.Count;save_count=$saveFacts.Count;old_media_count=$mediaFacts.Count;new_media_count=$newMedia.Count}|ConvertTo-Json -Compress
if($failures.Count -gt 0){exit 1}
