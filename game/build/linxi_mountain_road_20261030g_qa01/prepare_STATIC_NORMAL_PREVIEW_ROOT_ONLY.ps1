$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/linxi_mountain_road_20261030g_qa01"
$authPath="$repo/game/build/linxi_road_portrait_20261030g_source01/closure01_READY/auth_READY.json"
$basePath="$qa/baseline_joint_preserve_user_STATIC_ONLY.json";$output="$qa/STATIC_NORMAL_PREVIEW_ROOT_ONLY.json"
if((Get-FileHash -LiteralPath $authPath).Hash.ToLower() -cne 'f1d72b5e51ff69b67b881f6400bcd10b6e2bdab790028f6918814dd4d928835e'){throw 'EXACT_FINAL_JOINT_AUTH_REQUIRED'}
$auth=Get-Content -LiteralPath $authPath -Raw|ConvertFrom-Json;$baseline=Get-Content -LiteralPath $basePath -Raw|ConvertFrom-Json
if($baseline.status -cne 'USER_GAME_PRESERVED_STATIC_ONLY' -or !$baseline.save_capture_stable -or @($baseline.registered_save_paths.PSObject.Properties).Count -ne 171){throw 'ROOT_FRESH_STABLE171_PRESERVED_GAME_STATIC_BASELINE_REQUIRED'}
function Absolute([string]$p){if($p.StartsWith('res://')){return "$repo/game/"+$p.Substring(6)};if($p.StartsWith('game/')){return "$repo/$p"};throw "SOURCE_OUTSIDE_PROJECT:$p"}
$fixed=[ordered]@{}
foreach($group in @($auth.sources,$auth.new_modules,$auth.runtime_inputs)){
 foreach($p in $group.PSObject.Properties){$sha=(Get-FileHash -LiteralPath (Absolute $p.Name)).Hash.ToLower();if($sha -cne $p.Value.sha256){throw "POSTDEPLOY_AUTH_SOURCE_MISMATCH:$($p.Name)"};$fixed[$p.Name]=$sha}
}
foreach($p in $baseline.protected_sources.PSObject.Properties){$sha=(Get-FileHash -LiteralPath (Absolute $p.Name)).Hash.ToLower();if($sha -cne $p.Value.sha256){throw "PROTECTED_SOURCE_CHANGED_REQUIRE_SEPARATE_REVIEW:$($p.Name)"};$fixed[$p.Name]=$sha}
foreach($p in @('game/scripts/autoload/platform_bridge.gd','game/scripts/autoload/game_state.gd','game/scripts/autoload/dialog_player.gd','game/scripts/autoload/save_manager.gd','game/scripts/autoload/quest_manager.gd','game/scripts/autoload/inventory.gd','game/data/dialogs/ch1_road_intro.tres','game/data/quests/q_ch1_main_road.tres','game/build/linxi_mountain_road_20261030g_qa01/STATIC_NORMAL_PREVIEW_ROOT_ONLY.gd','game/build/linxi_mountain_road_20261030g_qa01/preview_facts_READONLY_ROOT_ONLY.ps1')){$fixed[$p]=(Get-FileHash -LiteralPath (Absolute $p)).Hash.ToLower()}
$value=[ordered]@{ready=$true;scope='OPTIONAL_LIVE_FIELD_STATIC_NORMAL_RENDER_ONLY';fixed_sources=$fixed;registered_save_paths=@($baseline.registered_save_paths.PSObject.Properties.Name);joint_auth_sha256=(Get-FileHash -LiteralPath $authPath).Hash.ToLower();baseline_sha256=(Get-FileHash -LiteralPath $basePath).Hash.ToLower();no_real_save_loading=$true;input_events=0;world_entry_or_movement_validation=$false;user_processes_preserved=$true}
$stream=[IO.File]::Open($output,[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($value|ConvertTo-Json -Depth 18)+"`n");$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
[ordered]@{fixture=$output;sha256=(Get-FileHash -LiteralPath $output).Hash.ToLower();fixed_sources=$fixed.Count;registered_save_paths=171;engine_runs=0;save_contents_read=$false}|ConvertTo-Json
