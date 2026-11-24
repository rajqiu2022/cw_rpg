$ErrorActionPreference='Stop'
$taskRoot='F:\Code\RPG_GAME';$qaRoot=Join-Path $taskRoot 'game/build/jinling_city_20261029_qa01'
function Fact([string]$p){if(-not [IO.File]::Exists($p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;[ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant();bytes=$i.Length;utc_ticks=$i.LastWriteTimeUtc.Ticks.ToString()}}
function WriteNew([string]$p,[byte[]]$bytes){[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($p))|Out-Null;$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()}}
$output=Join-Path $qaRoot 'baseline_before_ACTUAL.json';if([IO.File]::Exists($output)){throw 'Preserve original baseline; CreateNew only.'}
# Copies are preservation, not permission to edit the shared closure.
$closure=@(
 'game/scripts/autoload/scene_router.gd',
 'game/data/maps/luoyang_full_city_20261022ap/execution_successor.json',
 'game/scripts/city/luoyang_execution_index_20261022ap.gd',
 'game/data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json',
 'game/scripts/city/luoyang_precomputed_bundle_index_20261018r.gd',
 'game/data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json',
 'game/scripts/city/luoyang_quarters_index_20261022ap.gd',
 'game/data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/manifest.json',
 'game/scripts/city/luoyang_docks_workyard_index_20261019ac.gd'
)
$readonly=@(
 'game/data/scenes/openworld_jinling_city.tres','game/data/maps/openworld_jinling_city_layout_v2.tres',
 'game/data/dialogs/openworld_jinling_guide.tres','game/data/shops/lingyue_pavilion.tres',
 'game/data/scenes/openworld_jinling_reed_marsh.tres','game/data/maps/openworld_jinling_reed_marsh_layout_v1.tres',
 'game/data/scenes/world_map_jianghu.tres','game/data/scenes/world_map_jianghu_v15.tres','game/data/maps/world_map_jianghu_layout_v15.tres',
 'game/scripts/field/field_walkable_controller.gd','game/scripts/field/npc_node.gd',
 'game/build/bianzhou_city_20261028_system01/city_author.gd','game/build/bianzhou_city_20261028_system01/bianzhou_field.gd','game/build/bianzhou_city_20261028_system01/router_entry.gd',
 'game/build/bianzhou_city_20261028_system04/gate_binding_BUILD.json','game/build/bianzhou_city_20261028_system04/completion_binding_BUILD.json','game/build/bianzhou_city_20261028_system05/completion_binding_BUILD.json',
 'game/build/major_cities_20261028_qa01/bianzhou_bounded_DRAFT.gd','game/build/luoyang_city_full_rollout_20261022ap_root01/run_frozen_godot_once.ps1'
)
$sources=[ordered]@{};$backups=@()
foreach($relative in ($closure+$readonly)){
 $p=Join-Path $taskRoot $relative;$fact=Fact $p;if(-not $fact.exists){throw "Required current source missing: $relative"};$sources[$relative]=$fact
 if($closure -contains $relative){$copy=Join-Path $qaRoot ('source_before/'+$relative);WriteNew $copy ([IO.File]::ReadAllBytes($p));[IO.File]::SetLastWriteTimeUtc($copy,[DateTime]::new([long]$fact.utc_ticks,[DateTimeKind]::Utc));$copied=Fact $copy;if($copied.sha256 -cne $fact.sha256 -or $copied.bytes -ne $fact.bytes -or $copied.utc_ticks -cne $fact.utc_ticks){throw 'Exact backup mismatch.'};$backups+=@{source=$relative;path=$copy;fact=$copied}}
}
$prior=Get-Content -LiteralPath (Join-Path $taskRoot 'game/build/major_cities_20261028_qa04/final06_ROOT_ACTUAL.json') -Raw|ConvertFrom-Json
$saves=[ordered]@{};foreach($p in $prior.save15.PSObject.Properties){$saves[$p.Name]=Fact $p.Name};if($saves.Count -ne 15){throw 'Only the original registered fifteen save paths may be captured.'}
$media=[ordered]@{}
foreach($png in @('game/art/backgrounds/openworld_cities_v2/bg_jinling_bridge_market_gameplay_v2_3072.png','game/art/navigation_masks/openworld_city_v3/jinling_walk_v3.png','game/art/characters/npc_zhuwei_gate_guard_idle_down_25d_4f_v2_runtime.png','game/art/characters/street_expansion_v1/npc_street_merchant_idle_down_4f_v3_runtime.png')){
 $import=$png+'.import';$text=Get-Content -LiteralPath (Join-Path $taskRoot $import) -Raw;$match=[regex]::Match($text,'(?m)^path="(res://[^"]+)"');if(-not $match.Success){throw "Exact media import remap absent: $import"};$ctex='game/'+$match.Groups[1].Value.Substring(6)
 foreach($relative in @($png,$import,$ctex)){$fact=Fact (Join-Path $taskRoot $relative);if(-not $fact.exists){throw "Original related media missing: $relative"};$media[$relative]=$fact}
}
foreach($relative in $sources.Keys){$now=Fact (Join-Path $taskRoot $relative);if($now.sha256 -cne $sources[$relative].sha256 -or $now.utc_ticks -cne $sources[$relative].utc_ticks){throw "Source changed while capturing: $relative"}}
$processes=@(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'"|Select-Object ProcessId,Name)
$result=[ordered]@{status='JINLING_SMALL_READONLY_BEFORE';utc=[DateTime]::UtcNow.ToString('o');sources=$sources;source_closure_backup_candidates_not_write_authority=$closure;exact_backups=$backups;save15=$saves;related_original_media=$media;godot_processes=$processes;editor51856_present=(@($processes|Where-Object ProcessId -eq 51856).Count -eq 1);save_content_parsed=$false;canonical_writes=0;save_writes=0;media_writes=0;engine_calls=0;processes_stopped=0}
WriteNew $output ([Text.UTF8Encoding]::new($false).GetBytes(($result|ConvertTo-Json -Depth 20)+"`n"))
[ordered]@{path=$output;sha256=(Fact $output).sha256;sources=$sources.Count;exact_backups=$backups.Count;save_paths=$saves.Count;related_media=$media.Count;editor51856=$result.editor51856_present;engine_calls=0}|ConvertTo-Json -Compress
