$ErrorActionPreference='Stop'
$dir='F:/Code/RPG_GAME/game/build/adventure_20261030k_root01'
$baseline=Get-Content -LiteralPath ($dir+'/baseline_ACTUAL.json') -Raw | ConvertFrom-Json -AsHashtable
$failures=@();$now=@{};$saveCount=0
foreach($path in $baseline.facts.Keys) {
 $item=Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
 $fact=@{exists=($null -ne $item)}
 if($item) {$fact.bytes=$item.Length;$fact.utc_ticks=[string]$item.LastWriteTimeUtc.Ticks;$fact.sha256=(Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant()}
 $now[$path]=$fact
 if($baseline.authorized_existing_targets -contains $path){continue}
 $old=$baseline.facts[$path]
 foreach($key in @('exists','bytes','utc_ticks','sha256')){if($old[$key] -cne $fact[$key]){$failures+=($path+':'+$key)}}
 if($path.Contains('/app_userdata/')){$saveCount+=1}
}
$project=Get-Content -LiteralPath 'F:/Code/RPG_GAME/game/project.godot' -Raw
$inverse=[regex]::Replace($project,'(?m)^AdventureRuntime="\*res://scripts/adventure/adventure_runtime.gd"\r?\n','')
$projectExact=$inverse -ceq (Get-Content -LiteralPath ($dir+'/project_BEFORE.godot') -Raw)
if(!$projectExact){$failures+='PROJECT_SINGLE_AUTOLOAD_INVERSE'}
$gather=Get-Content -LiteralPath 'F:/Code/RPG_GAME/game/scripts/life_skills/gathering_service.gd' -Raw
$inverse=[regex]::Replace($gather,'(?ms)^\t\t# Additive surveyed adventure sites;.*?(?=^\treturn _sites)','')
$gatherExact=$inverse -ceq (Get-Content -LiteralPath ($dir+'/gathering_service_BEFORE.gd') -Raw)
if(!$gatherExact){$failures+='GATHER_CATALOG_ADDITIVE_BLOCK_INVERSE'}
$modules=@{}
foreach($base in @('F:/Code/RPG_GAME/game/scripts/adventure','F:/Code/RPG_GAME/game/data/maps/adventure_20261030k')) {
 foreach($item in (Get-ChildItem -LiteralPath $base -File)){$modules[$item.FullName.Replace('\','/')]=@{sha256=(Get-FileHash -LiteralPath $item.FullName).Hash.ToLowerInvariant();bytes=$item.Length}}
}
foreach($name in @('adventure_zhuwei_hunting_ground','adventure_xiangzhou_deep_mine','adventure_luoyang_riverside_route')) {
 $path='F:/Code/RPG_GAME/game/data/scenes/'+$name+'.tres';$modules[$path]=@{sha256=(Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant();bytes=(Get-Item -LiteralPath $path).Length}
}
$godot=@(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'" | Select-Object ProcessId,Name)
$result=@{passed=($failures.Count -eq 0);errors=$failures;protected_fact_count=$now.Count;protected_save_count=$saveCount;facts=$now;project_only_autoload_inverse=$projectExact;gather_only_additive_catalog_inverse=$gatherExact;new_modules=$modules;godot_processes=$godot;save_deserializations=0;save_writes=0}
$result | ConvertTo-Json -Depth 9 | Out-File -LiteralPath ($dir+'/final_guard_ACTUAL.json') -Encoding utf8
@{passed=$result.passed;protected=$now.Count;saves=$saveCount;errors=$failures;godot=$godot;guard_sha256=(Get-FileHash -LiteralPath ($dir+'/final_guard_ACTUAL.json')).Hash} | ConvertTo-Json -Depth 5
if($failures.Count -gt 0){exit 1}
