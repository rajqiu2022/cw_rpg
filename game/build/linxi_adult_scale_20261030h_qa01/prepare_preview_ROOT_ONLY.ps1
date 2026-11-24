$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/linxi_adult_scale_20261030h_qa01"
$authPath="$repo/game/build/linxi_adult_scale_20261030h_system01/closure01_READY/auth_READY.json"
$basePath="$qa/baseline_ROOT_ACTUAL.json";$output="$qa/STATIC_NORMAL_PREVIEW_ROOT_ONLY.json"
if((Get-FileHash -LiteralPath $authPath).Hash.ToLower() -cne 'b0ce6f31d790c6b77a59057a477902ab7ea636e614514d97f4659ec34cf84f22'){throw 'EXACT_FINAL_H_AUTH_REQUIRED'}
$auth=Get-Content -LiteralPath $authPath -Raw|ConvertFrom-Json;$baseline=Get-Content -LiteralPath $basePath -Raw|ConvertFrom-Json
if(!$baseline.passed -or !$baseline.save_capture_stable -or @($baseline.registered_save_paths.PSObject.Properties).Count -ne 171){throw 'ACTUAL_FRESH_H_BASELINE_REQUIRED_NO_G_REBASE'}
function Absolute([string]$p){if($p.StartsWith('res://')){return "$repo/game/"+$p.Substring(6)};if($p.StartsWith('game/')){return "$repo/$p"};throw "SOURCE_OUTSIDE_PROJECT:$p"}
$fixed=[ordered]@{}
foreach($group in @($auth.sources,$auth.new_modules,$auth.runtime_inputs,$auth.immutable_inputs)){
 foreach($p in $group.PSObject.Properties){$sha=(Get-FileHash -LiteralPath (Absolute $p.Name)).Hash.ToLower();if($sha -cne $p.Value.sha256){throw "POSTDEPLOY_AUTH_SOURCE_MISMATCH:$($p.Name)"};$fixed[$p.Name]=$sha}
}
foreach($p in $baseline.protected_sources.PSObject.Properties){$sha=(Get-FileHash -LiteralPath (Absolute $p.Name)).Hash.ToLower();if($sha -cne $p.Value.sha256){throw "H_PROTECTED_SOURCE_CHANGED:$($p.Name)"};$fixed[$p.Name]=$sha}
foreach($p in @('game/build/linxi_adult_scale_20261030h_qa01/STATIC_NORMAL_PREVIEW_ROOT_ONLY.gd','game/build/linxi_adult_scale_20261030h_qa01/preview_facts_READONLY_ROOT_ONLY.ps1','game/build/linxi_adult_scale_20261030h_system01/alpha_bounds_ACTUAL.json','game/build/linxi_adult_scale_20261030h_system01/normalized_projection_ACTUAL.json')){$fixed[$p]=(Get-FileHash -LiteralPath (Absolute $p)).Hash.ToLower()}
$value=[ordered]@{ready=$true;scope='30H_CHANGED_ADULT_HOUSE_SCALE_AND_TWO_NEW_ROAD_VISUALS_ONLY';fixed_sources=$fixed;registered_save_paths=@($baseline.registered_save_paths.PSObject.Properties.Name);auth_sha256=(Get-FileHash -LiteralPath $authPath).Hash.ToLower();baseline_sha256=(Get-FileHash -LiteralPath $basePath).Hash.ToLower();no_real_save_loading=$true;input_events=0;world_entry_or_movement_validation=$false;g_closed_evidence_inherited=$true}
$stream=[IO.File]::Open($output,[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($value|ConvertTo-Json -Depth 18)+"`n");$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
[ordered]@{fixture=$output;sha256=(Get-FileHash -LiteralPath $output).Hash.ToLower();fixed_sources=$fixed.Count;registered_save_paths=171;engine_runs=0;save_contents_read=$false}|ConvertTo-Json
