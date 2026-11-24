$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/luoyang_hall_boundary_20261029p_qa01"
$freeze=Get-Content "$qa/freeze_ROOT_ACTUAL.json" -Raw | ConvertFrom-Json
$baseline=Get-Content "$qa/baseline_before_ACTUAL.json" -Raw | ConvertFrom-Json
$guard=Get-Content "$qa/final_guard_ROOT_ACTUAL.json" -Raw | ConvertFrom-Json
$run=Get-Content "$qa/actual/98124/result.json" -Raw | ConvertFrom-Json
$foreign=@('game/build/three_towns_world_20261029j_system01/town_registry.gd','game/build/three_towns_world_20261029j_system01/native_sources.json','game/scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn','game/scenes/drafts/desert_town_20261029d/desert_town.tscn')
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
function Fields($a,$b){return [ordered]@{exists=($a.exists -eq $b.exists);sha256=($a.sha256 -eq $b.sha256);bytes=($a.bytes -eq $b.bytes);utc_ticks=($a.utc_ticks -eq $b.utc_ticks)}}
function All($v){return @($v.Values | Where-Object {$_ -ne $true}).Count -eq 0}
$local=[ordered]@{};$external=[ordered]@{};$target=[ordered]@{};$bins=[ordered]@{};$saves=[ordered]@{};$backups=@();$errors=@()
foreach($p in $freeze.sources.PSObject.Properties){
 $now=Fact "$repo/$($p.Name)";$end=$guard.sources.($p.Name)
 $record=[ordered]@{freeze=$p.Value;run_end=$end;current=$now;freeze_to_run_end=(Fields $p.Value $end);freeze_to_current=(Fields $p.Value $now)}
 if($p.Name -in $foreign){$external[$p.Name]=$record;continue}
 $local[$p.Name]=$record
 if(!(All $record.freeze_to_run_end) -or !(All $record.freeze_to_current)){$errors+="LOCAL_SOURCE:$($p.Name)"}
 if($null -ne $baseline.sources.($p.Name)){$target[$p.Name]=$record}
}
foreach($p in $baseline.all_ten_bins.PSObject.Properties){$path='game/'+$p.Value.path.Substring(6);$bins[$p.Name]=$local[$path];if($null -eq $local[$path]){$errors+="BIN_MISSING:$($p.Name)"}}
foreach($p in $freeze.saves.PSObject.Properties){$now=Fact $p.Name;$end=$guard.saves.($p.Name);$record=[ordered]@{freeze_to_run_end=(Fields $p.Value $end);freeze_to_current=(Fields $p.Value $now)};$saves[$p.Name]=$record;if(!(All $record.freeze_to_run_end) -or !(All $record.freeze_to_current)){$errors+="SAVE:$($p.Name)"}}
foreach($p in $freeze.exact_backups){$fields=Fields $p.fact (Fact $p.path);$backups+=@{source=$p.source;fields=$fields};if(!(All $fields)){$errors+="BACKUP:$($p.source)"}}
if($foreign.Count -ne $external.Count -or $target.Count -ne 11 -or $bins.Count -ne 10 -or $saves.Count -ne 171){$errors+='BOUNDED_SCOPE_COUNTS'}
if($run.passed -ne $false -or $run.checks -ne 79 -or $run.input_ticks -ne 340 -or @($run.errors).Count -ne 1 -or $run.errors[0] -ne 'SOURCE_FIRST_FINAL'){$errors+='ORIGINAL_WHOLE_FAIL_NOT_AS_REPORTED'}
foreach($name in @('script','fixture')){$path=if($name -eq 'script'){"$qa/boundary_READY.gd"}else{"$qa/boundary_READY.json"};if(!(All (Fields $freeze.$name (Fact $path)))){$errors+="FROZEN_TOOL:$name"}}
$result=[ordered]@{
 status='READONLY_LOCAL_RESIDUAL_WITH_FOUR_EXTERNAL_DELTAS';original_whole_run_status='FAIL_RETAINED';original_guard_status='FAIL_RETAINED';local_scope_all_fields_equal=($errors.Count -eq 0);errors=$errors
 original_result_sha256=(Fact "$qa/actual/98124/result.json").sha256;original_guard_sha256=(Fact "$qa/final_guard_ROOT_ACTUAL.json").sha256
 local_source_count=$local.Count;local_sources=$local;eleven_authorized_targets=$target;entry_protection=$local['game/build/luoyang_regions_20261027d_source01/region_entry.gd'];all_ten_bins=$bins;eleven_backup_checks=$backups;save_checks=$saves
 excluded_external_paths_exactly=$foreign;external_deltas=$external;runtime_input_ticks=340;runtime_images=@($run.records | Where-Object image);visual_review='Root personally accepted both native images; this receipt does not rerender or upgrade the failed whole run'
 engine_calls=0;production_writes=0;save_contents_read=$false;save_writes=0;source_restore=0;old_result_or_guard_rewrites=0
}
$path="$qa/local_scope_residual_READONLY.json";$s=[IO.File]::Open($path,[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($result | ConvertTo-Json -Depth 24)+"`n");$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()}
[ordered]@{path=$path;sha256=(Fact $path).sha256;whole_status=$result.original_whole_run_status;local_scope_all_fields_equal=$result.local_scope_all_fields_equal;errors=$errors;local_sources=$local.Count;targets=$target.Count;bins=$bins.Count;backups=$backups.Count;saves=$saves.Count;external_paths=@($external.Keys)} | ConvertTo-Json -Depth 4
