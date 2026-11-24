$ErrorActionPreference='Stop'
$dir='F:/Code/RPG_GAME/game/build/gather_actions_20261030l_root01'
$baseline=Get-Content -LiteralPath ($dir+'/baseline02_ACTUAL.json') -Raw | ConvertFrom-Json -AsHashtable
$authorized=@('F:/Code/RPG_GAME/game/scripts/life_skills/life_skills.gd','F:/Code/RPG_GAME/game/data/maps/adventure_20261030k/gathering_additions.json')
$facts=@{};$failures=@();$saves=0
foreach($path in $baseline.facts.Keys) {
 $item=Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
 $actual=@{exists=($null -ne $item)}
 if($item){$actual.bytes=$item.Length;$actual.utc_ticks=[string]$item.LastWriteTimeUtc.Ticks;$actual.sha256=(Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant()}
 $facts[$path]=$actual
 if($path.Contains('/app_userdata/')){$saves+=1}
 if($authorized -contains $path){continue}
 foreach($key in @('exists','bytes','utc_ticks','sha256')) {
  if($baseline.facts[$path][$key] -cne $actual[$key]){$failures+=($path+':'+$key)}
 }
}
$receipt=Get-Content -LiteralPath 'F:/Code/RPG_GAME/game/build/gather_actions_20261030l_system01/source_receipt_READY03.json' -Raw | ConvertFrom-Json -AsHashtable
$life=Get-Content -LiteralPath 'F:/Code/RPG_GAME/game/scripts/life_skills/life_skills.gd' -Raw
$inverse=$life
for($i=$receipt.replacements.Count-1;$i -ge 0;$i--) {
 $row=$receipt.replacements[$i]
 if(!$inverse.Contains($row.new)){throw ('Inverse hunk absent '+$i)}
 $inverse=$inverse.Replace($row.new,$row.old)
}
$lifeExact=$inverse -ceq (Get-Content -LiteralPath ($dir+'/life_skills_BEFORE.gd') -Raw)
if(!$lifeExact){$failures+='LIFE_ONLY_REGISTERED_HUNKS_INVERSE'}
$points=Get-Content -LiteralPath 'F:/Code/RPG_GAME/game/data/maps/adventure_20261030k/gathering_additions.json' -Raw
$inverse=$points.Replace('        925,','        1040,')
$pointExact=$inverse -ceq (Get-Content -LiteralPath ($dir+'/gathering_additions_BEFORE.json') -Raw)
if(!$pointExact){$failures+='ONLY_ONE_MINING_FOOT_X_INVERSE'}
$new=@{}
foreach($folder in @('F:/Code/RPG_GAME/game/art/sprites/life_skills_20261030l','F:/Code/RPG_GAME/game/art/audio/life_skills_20261030l','F:/Code/RPG_GAME/assets/raw/gather_actions_20261030l','F:/Code/RPG_GAME/game/build/gather_actions_20261030l_system01')) {
 foreach($item in (Get-ChildItem -LiteralPath $folder -File)){$new[$item.FullName.Replace('\','/')]=@{sha256=(Get-FileHash -LiteralPath $item.FullName).Hash.ToLowerInvariant();bytes=$item.Length}}
}
$path='F:/Code/RPG_GAME/game/scripts/life_skills/gathering_actions_20261030l.json';$new[$path]=@{sha256=(Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant();bytes=(Get-Item -LiteralPath $path).Length}
$imports=Get-Content -LiteralPath ($dir+'/asset_promote01_ACTUAL.json') -Raw | ConvertFrom-Json -AsHashtable
foreach($leaf in $imports.facts){if((Get-FileHash -LiteralPath $leaf.path).Hash -cne $leaf.sha256){$failures+=('IMPORT_CHANGED:'+ $leaf.path)}}
$processes=@(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'" | Select-Object ProcessId,Name)
$result=@{passed=($failures.Count -eq 0);errors=$failures;fact_count=$facts.Count;save_fact_count=$saves;facts=$facts;authorized_existing_targets=$authorized;life_hunks_reverse_exact=$lifeExact;single_resource_x_reverse_exact=$pointExact;new_resources=$new;imports=$imports.facts;godot_processes=$processes;save_deserializations=0;save_writes=0}
$result | ConvertTo-Json -Depth 9 | Out-File -LiteralPath ($dir+'/final_guard_ACTUAL.json') -Encoding utf8
@{passed=$result.passed;protected=$facts.Count;saves=$saves;errors=$failures;godot=$processes;guard_sha256=(Get-FileHash -LiteralPath ($dir+'/final_guard_ACTUAL.json')).Hash} | ConvertTo-Json -Depth 5
if($failures.Count -gt 0){exit 1}
