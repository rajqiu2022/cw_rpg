$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/linxi_minimap_fix_20261030f_qa01"
$scopePath="$qa/baseline_scope_DRAFT.json";$scope=Get-Content -LiteralPath $scopePath -Raw|ConvertFrom-Json
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
function Same($a,$b){return $a.exists -eq $b.exists -and (!$a.exists -or ($a.sha256 -eq $b.sha256 -and $a.bytes -eq $b.bytes -and $a.utc_ticks -eq $b.utc_ticks))}
function NewJson([string]$p,$v){$stream=[IO.File]::Open($p,[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($v|ConvertTo-Json -Depth 28)+"`n");$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}}
if(Test-Path -LiteralPath "$qa/baseline_before_ACTUAL.json"){throw 'IMMUTABLE_BASELINE_EXISTS_SUPPLEMENT_DO_NOT_OVERWRITE'}
$processes=@(Get-CimInstance Win32_Process -Filter "name like 'Godot%'"|Select-Object ProcessId,Name)
$games=@($processes|Where-Object {$_.ProcessId -ne 51856})
if($games.Count -gt 0){throw ('WAIT_FOR_USER_GAME_EXIT_DO_NOT_STOP:'+(@($games.ProcessId)-join ','))}
$miniPath="$repo/$($scope.mini_source_before)";$mf=Fact $miniPath
if(!$mf.exists -or $mf.sha256 -ne $scope.mini_source_before_sha256){throw 'AUTHOR_BEFORE_RECEIPT_CHANGED'}
$mini=Get-Content -LiteralPath $miniPath -Raw|ConvertFrom-Json
if(@($mini.sources.PSObject.Properties).Count -ne 28){throw 'EXACT28_MINI_SOURCE_BEFORE_REQUIRED'}
$paths=@($mini.sources.PSObject.Properties.Name)+@($scope.additional_backup_targets)|Select-Object -Unique
$sources=[ordered]@{};$protected=[ordered]@{};$backups=@();$saves=[ordered]@{}
# Read-only preflight all explicit paths before creating any backup.
foreach($path in $paths){$f=Fact "$repo/$path";if(!$f.exists){throw "MISSING_EXPLICIT_SOURCE:$path"};$sources[$path]=$f}
foreach($p in $mini.sources.PSObject.Properties){$f=$sources[$p.Name];if($f.sha256 -ne $p.Value.sha256 -or $f.bytes -ne $p.Value.bytes -or $f.utc_ticks -ne $p.Value.utc_ticks){throw "SOURCE_CHANGED_SINCE_AUTHOR_BEFORE_REPORT_NO_RESTORE:$($p.Name)"}}
foreach($path in $scope.protected_sources){if($sources.Contains($path)){continue};$f=Fact "$repo/$path";if(!$f.exists){throw "MISSING_EXPLICIT_PROTECTED:$path"};$protected[$path]=$f}
foreach($path in $paths){
 $before=$sources[$path];$target="$qa/source_before/$path";[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))|Out-Null
 $stream=[IO.File]::Open($target,[IO.FileMode]::CreateNew);try{$bytes=[IO.File]::ReadAllBytes("$repo/$path");$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
 [IO.File]::SetLastWriteTimeUtc($target,[DateTime]::new([long]$before.utc_ticks,[DateTimeKind]::Utc));$copy=Fact $target
 if(!(Same $copy $before) -or !(Same (Fact "$repo/$path") $before)){throw "COPY_RACE_PRESERVE_REPORT:$path"}
 $backups+=@{source=$path;path=$target;fact=$copy}
}
$prior=Get-Content "$repo/game/build/three_settlements_20261030e_qa01/freeze05_ROOT_ACTUAL.json" -Raw|ConvertFrom-Json
foreach($p in $prior.saves.PSObject.Properties){$saves[$p.Name]=Fact $p.Name};if($saves.Count -ne 171){throw 'REGISTERED171_SAVE_PATHS_REQUIRED'}
$locations=Get-Content "$repo/game/build/four_settlements_20261030e_system01/locations.json" -Raw|ConvertFrom-Json
$otherLocations=[ordered]@{};foreach($p in $locations.PSObject.Properties){if(!$p.Name.StartsWith('linxi_')){$otherLocations[$p.Name]=$p.Value}}
$native=Get-Content "$repo/game/build/three_towns_world_20261029j_system01/native_sources.json" -Raw|ConvertFrom-Json
NewJson "$qa/baseline_before_ACTUAL.json" ([ordered]@{status='FRESH30F_AFTER_USER_GAME_EXIT_ROOT_ONLY';sources=$sources;exact_backups=$backups;protected_sources=$protected;registered_save_paths=$saves;old_native_source_entries=$native.sources;other_location_rows=$otherLocations;scope=(Fact $scopePath);source_author_before=(Fact $miniPath);godot_processes_observed=$processes;required_user_game139344_absent=$true;prior_save_receipt_used_for_path_names_only=$true;save_history_not_rebased_or_restored=$true;engine_calls=0;production_writes=0;save_contents_read=$false;save_writes=0;processes_stopped=0})
[ordered]@{path="$qa/baseline_before_ACTUAL.json";sha256=(Fact "$qa/baseline_before_ACTUAL.json").sha256;sources=$sources.Count;backups=$backups.Count;protected=$protected.Count;saves=$saves.Count;old_native_entries=@($native.sources.PSObject.Properties).Count}|ConvertTo-Json
