$ErrorActionPreference='Stop'
$root='F:/Code/RPG_GAME/game'
$out=$root+'/build/luoyang_shore_market_20261020ae_root01/final_admission.json'
if(Test-Path -LiteralPath $out){throw 'PRESERVE_FINAL_RECEIPT'}
function Disk([string]$p){if(!$p.StartsWith('res://') -or $p.Contains('..')){throw 'RESOURCE_PATH'};Join-Path $root $p.Substring(6)}
function ReadJ([string]$p){Get-Content -Raw -LiteralPath $p|ConvertFrom-Json -AsHashtable}
$cache=@{}
function Current([string]$p){
 if(!$cache.Contains($p)){$f=Get-Item -LiteralPath $p;$cache[$p]=@{sha256=(Get-FileHash -LiteralPath $p).Hash.ToLowerInvariant();bytes=$f.Length;ticks=[string]$f.LastWriteTimeUtc.Ticks}}
 return $cache[$p]
}
function Pin([string]$p,[string]$h){if((Current $p).sha256 -cne $h.ToLowerInvariant()){throw "CURRENT_SHA:$p"}}
$original=ReadJ ($root+'/build/luoyang_shore_market_20261020ae_system01/staged/stage_receipt.json')
$retry=ReadJ ($root+'/build/luoyang_shore_market_20261020ae_system01/runtime_dependency_retry1/staged/receipt.json')
$targets=@{}
foreach($plan in @($original,$retry)){foreach($t in $plan.targets){$targets[$t.target]=$t.candidate_sha256}}
foreach($id in @('ch4_s2_canal_docks','ch4_s3_luoyang_market')){$area=$original.areas[$id];$targets[$area.index]=$area.true_sha}
foreach($p in $targets.Keys){Pin (Disk $p) $targets[$p]}
$backupCount=0
foreach($pair in @(@($original,'predeploy_backup'),@($retry,'predependency_backup'))){foreach($t in $pair[0].targets){if($t.old_sha256 -ceq 'ABSENT'){continue};Pin ($root+'/build/luoyang_shore_market_20261020ae_root01/'+$pair[1]+'/'+$t.target.Substring(6)) $t.old_sha256;$backupCount++}}
$reportPaths=@('res://build/luoyang_shore_market_20261020ae_qa01/field_65540/result.json','res://build/luoyang_shore_market_20261020ae_qa01/market_114244/result.json')
$reports=@();$sources=@{};$pictures=@()
foreach($p in $reportPaths){
 $r=ReadJ (Disk $p)
 if(!$r.complete -or $r.failures -ne 0 -or $r.players_before.Count -ne 15 -or ($r.players_before|ConvertTo-Json -Depth 8 -Compress) -cne ($r.players_after|ConvertTo-Json -Depth 8 -Compress)){throw 'ACTUAL_SCOPE_OR_SAVE_FAILURE'}
 foreach($path in $r.source_before.Keys){
  $a=$r.source_before[$path];$b=$r.source_after[$path]
  if(($a|ConvertTo-Json -Compress) -cne ($b|ConvertTo-Json -Compress)){throw "ACTUAL_FIRST_FINAL:$path"}
  if($sources.Contains($path) -and (($sources[$path]|ConvertTo-Json -Compress) -cne ($a|ConvertTo-Json -Compress))){throw "TWO_ACTUAL_SOURCE_COLLISION:$path"}
  $sources[$path]=$a
  $disk=Disk $path;Pin $disk $a.sha256
  if((Current $disk).bytes -ne $a.bytes){throw "CURRENT_BYTES:$path"}
 }
 foreach($pic in $r.pictures){Pin (Disk $pic.path) $pic.sha256;$pictures+=,$pic}
 $reports+=,@{path=$p;sha256=(Current (Disk $p)).sha256;checks=$r.checks;elapsed_ms=$r.elapsed_ms;native_queries=$r.native_queries;source_count=$r.source_before.Count;players_count=$r.players_before.Count}
}
$media=@()
foreach($p in @('res://build/luoyang_shore_market_20261020ae_system01/isolate/ae_ground_import_result_24464.json','res://build/luoyang_shore_market_20261020ae_system01/isolate_wet_only/ae_wet_only_import_result_22180.json')){
 $r=ReadJ (Disk $p);if(!$r.passed -or $r.failures.Count -ne 0){throw 'IMPORT_FAILURE'}
 foreach($row in $r.rows){foreach($pair in @(@($row.texture,$row.source_sha256),@($row.import_path,$row.import_sha256),@($row.compiled_path,$row.compiled_sha256))){Pin (Disk $pair[0]) $pair[1]};$media+=,$row}
}
$before=ReadJ ($root+'/build/luoyang_shore_market_20261020ae_root01/guard_before.json')
$guard=ReadJ ($root+'/build/luoyang_shore_market_20261020ae_root01/guard_after_fields.json')
if($guard.checked -ne 1782){throw 'GUARD_COUNT'}
foreach($change in $guard.changes){$res='res://'+$change.path.Substring(($root+'/').Length);if($change.path -ne 'F:/Code/RPG_GAME/prompts/tasks.yaml' -and (!$targets.Contains($res) -or $targets[$res] -cne $change.after.sha256.ToLowerInvariant())){throw ('UNAUTHORIZED_PROTECTED_CHANGE:'+ $change.path)}}
$saveCount=0
foreach($entry in $before.facts){if(!$entry.path.Contains('/app_userdata/')){continue};$saveCount++;if($entry.sha256 -ceq 'ABSENT'){if(Test-Path -LiteralPath $entry.path){throw 'NEW_PLAYER_SAVE'}}else{$f=Current $entry.path;if($f.sha256 -cne $entry.sha256.ToLowerInvariant() -or $f.bytes -ne $entry.bytes -or $f.ticks -cne $entry.ticks){throw 'PLAYER_SAVE_CHANGED'}}}
if($saveCount -ne 15 -or $media.Count -ne 4 -or $pictures.Count -ne 3){throw 'FINITE_ACCEPTANCE_SCOPE'}
Pin (Disk 'res://build/luoyang_shore_market_20261020ae_qa01/cpu_118004/result.json') 'b0c4593bc18480c4b2b926dcae9ec7ee1a97fb723da398ff3e99dab4fb178ad9'
$processes=@(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'"|Select-Object ProcessId,Name,CommandLine)
if(@($processes|Where-Object ProcessId -ne 51856).Count -ne 0){throw 'OWN_ENGINE_NOT_EXITED'}
$result=@{status='AE_FOUR_ASSETS_LIMITED_FORMAL_FIELD_ADMISSION_NOT_WHOLE_DISTRICT_OR_LOADING_PROMISE';canonical_target_count=$targets.Count;canonical_sha256=$targets;backup_snapshot_count=$backupCount;unique_actual_source_count=$sources.Count;all_actual_current_sources_sha_bytes_match=$true;all_15_player_paths_sha_bytes_exactticks_unchanged=$true;protected_count=$guard.checked;authorized_protected_changes=$guard.changes.Count;other_protected_facts_unchanged=$guard.checked-$guard.changes.Count;media=$media;actual_reports=$reports;pictures=$pictures;original_cpu118004_whole_FAIL_preserved=$true;exit_diagnostics_clean=$false;docks_exit_errors=8;market_exit_errors=7;script_errors=0;processes=$processes;editor_preserved=$true;no_engine_rerun_requested=$true;remaining='South Market building blocks/facades/independent doors not rearranged; only first ground cluster. One localized wet band and one mooring cable, not complete dock art.'}
[IO.File]::WriteAllText($out,($result|ConvertTo-Json -Depth 14)+"`n",[Text.UTF8Encoding]::new($false))
@{passed=$true;targets=$targets.Count;backup_snapshots=$backupCount;source_count=$sources.Count;protected_count=$guard.checked;authorized_changes=$guard.changes.Count;unchanged=$guard.checked-$guard.changes.Count;save_paths=$saveCount;final_sha256=(Get-FileHash -LiteralPath $out).Hash}|ConvertTo-Json
