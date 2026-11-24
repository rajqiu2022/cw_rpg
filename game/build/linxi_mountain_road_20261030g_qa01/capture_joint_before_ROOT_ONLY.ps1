param([Parameter(Mandatory=$true)][string]$AuthPath,[Parameter(Mandatory=$true)][string]$RoadManifestPath)
$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/linxi_mountain_road_20261030g_qa01"
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
function Same($a,$b){return $a.exists -eq $b.exists -and (!$a.exists -or ($a.sha256 -eq $b.sha256 -and $a.bytes -eq $b.bytes -and $a.utc_ticks -eq $b.utc_ticks))}
function NewJson([string]$p,$v){$stream=[IO.File]::Open($p,[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($v|ConvertTo-Json -Depth 28)+"`n");$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}}
function RepoFile([string]$relative){$full=[IO.Path]::GetFullPath("$repo/$relative").Replace('\','/');if(!$relative.StartsWith('game/') -or !$full.StartsWith("$repo/game/",[StringComparison]::OrdinalIgnoreCase)){throw "OUT_OF_EXACT_GAME_SCOPE:$relative"};return $full}
if(Test-Path -LiteralPath "$qa/baseline_joint_before_ACTUAL.json"){throw 'IMMUTABLE_JOINT_BASELINE_EXISTS_SUPPLEMENT_DO_NOT_OVERWRITE'}
if(Test-Path -LiteralPath "$repo/game/build/linxi_minimap_fix_20261030f_qa01/baseline_before_ACTUAL.json"){throw 'F_BASELINE_NOW_EXISTS_ROOT_MUST_CHOOSE_PARENT_NOT_SILENT_REBASE'}
$processes=@(Get-CimInstance Win32_Process -Filter "name like 'Godot%'"|Select-Object ProcessId,Name)
$games=@($processes|Where-Object {$_.ProcessId -ne 51856});if($games.Count -gt 0){throw ('WAIT_FOR_HUMAN_PROCESS_PERMISSION_DO_NOT_STOP:'+(@($games.ProcessId)-join ','))}
$authResolved=[IO.Path]::GetFullPath($AuthPath).Replace('\','/');$roadResolved=[IO.Path]::GetFullPath($RoadManifestPath).Replace('\','/')
if(!$authResolved.StartsWith("$repo/game/build/player_portrait_minimap_20261030f_system01/",[StringComparison]::OrdinalIgnoreCase) -or !$roadResolved.StartsWith("$repo/game/build/linxi_mountain_road_20261030g_system01/",[StringComparison]::OrdinalIgnoreCase)){throw 'EXACT_TWO_AUTHOR_NAMESPACES_REQUIRED'}
$auth=Get-Content -LiteralPath $authResolved -Raw|ConvertFrom-Json;$road=Get-Content -LiteralPath $roadResolved -Raw|ConvertFrom-Json
$fScopePath="$repo/game/build/linxi_minimap_fix_20261030f_qa01/baseline_scope_DRAFT.json"
if((Fact $fScopePath).sha256 -ne '639171ac658a92c4ccec93defb6190e02ece3bc04bb3167002269609e0714dfe'){throw 'OLD_F_SCOPE_CHANGED_NO_OVERWRITE_ALLOWED'}
$fScope=Get-Content -LiteralPath $fScopePath -Raw|ConvertFrom-Json
$mini=Get-Content "$repo/$($fScope.mini_source_before)" -Raw|ConvertFrom-Json
$business=Get-Content "$qa/original_business_inputs_DRAFT.json" -Raw|ConvertFrom-Json
$allowed=@($mini.sources.PSObject.Properties.Name)+@('game/build/four_settlements_20261030e_system01/locations.gd','game/build/four_settlements_20261030e_system01/locations.json')+@($road.targets.target)|Select-Object -Unique
$targets=@($auth.sources.PSObject.Properties.Name)
foreach($path in $targets){if($path -notin $allowed){throw "TARGET_OUTSIDE_F_PLUS_EXACT_G_MANIFEST:$path"}}
foreach($path in @($mini.sources.PSObject.Properties.Name)+@('game/build/four_settlements_20261030e_system01/locations.gd','game/build/four_settlements_20261030e_system01/locations.json')){if($path -notin $targets){throw "F_TARGET_MISSING_FROM_JOINT_AUTH:$path"}}
$sources=[ordered]@{};$protected=[ordered]@{};$backups=@();$saves=[ordered]@{}
foreach($path in $targets){$f=Fact (RepoFile $path);if(!$f.exists){throw "MISSING_EXISTING_TARGET:$path"};$sources[$path]=$f}
$protectedPaths=@($fScope.protected_sources)+@($fScope.additional_backup_targets)+@($business.protected_inputs)|Select-Object -Unique
foreach($path in $protectedPaths){if($sources.Contains($path)){continue};$f=Fact (RepoFile $path);if(!$f.exists){throw "MISSING_PROTECTED_INPUT:$path"};$protected[$path]=$f}
# Exactly the current combined targets are copied; old F scripts/receipts are read-only.
foreach($path in $targets){$before=$sources[$path];$target="$qa/source_before/$path";[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))|Out-Null;$stream=[IO.File]::Open($target,[IO.FileMode]::CreateNew);try{$bytes=[IO.File]::ReadAllBytes((RepoFile $path));$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()};[IO.File]::SetLastWriteTimeUtc($target,[DateTime]::new([long]$before.utc_ticks,[DateTimeKind]::Utc));$copy=Fact $target;if(!(Same $copy $before) -or !(Same (Fact (RepoFile $path)) $before)){throw "COPY_RACE_PRESERVE_AND_REPORT:$path"};$backups+=@{source=$path;path=$target;fact=$copy}}
$prior=Get-Content "$repo/game/build/three_settlements_20261030e_qa01/freeze05_ROOT_ACTUAL.json" -Raw|ConvertFrom-Json
foreach($p in $prior.saves.PSObject.Properties){$saves[$p.Name]=Fact $p.Name};if($saves.Count -ne 171){throw 'EXACT171_REGISTERED_SAVE_PATHS_REQUIRED'}
$native=Get-Content "$repo/game/build/three_towns_world_20261029j_system01/native_sources.json" -Raw|ConvertFrom-Json
$locations=Get-Content "$repo/game/build/four_settlements_20261030e_system01/locations.json" -Raw|ConvertFrom-Json
NewJson "$qa/baseline_joint_before_ACTUAL.json" ([ordered]@{status='FRESH_JOINT30F30G_AFTER_HUMAN_GAME_EXIT_PERMISSION';sources=$sources;exact_backups=$backups;protected_sources=$protected;registered_save_paths=$saves;old_native_source_entries=$native.sources;old_location_rows=$locations;f_scope_read_only=(Fact $fScopePath);road_original_business=(Fact "$qa/original_business_inputs_DRAFT.json");candidate_auth=(Fact $authResolved);candidate_road_manifest=(Fact $roadResolved);godot_processes_observed=$processes;prior_receipt_used_for_save_path_names_only=$true;f_baseline_previously_not_captured=$true;engine_calls=0;production_writes=0;save_contents_read=$false;save_writes=0;processes_stopped=0})
[ordered]@{path="$qa/baseline_joint_before_ACTUAL.json";sha256=(Fact "$qa/baseline_joint_before_ACTUAL.json").sha256;targets=$sources.Count;backups=$backups.Count;protected=$protected.Count;saves=$saves.Count;old_native_entries=@($native.sources.PSObject.Properties).Count}|ConvertTo-Json
