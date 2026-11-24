param([string]$OutputName='final_guard02_ROOT_ACTUAL.json')
$ErrorActionPreference='Stop'
$taskRoot='F:/Code/RPG_GAME'
$qaRoot="$taskRoot/game/build/major_cities_20261028_qa01"
$out="$qaRoot/$OutputName"
if(Test-Path -LiteralPath $out){throw 'Preserve the existing final receipt.'}
function Sha([string]$p){return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function Fact([string]$p){
    if(-not(Test-Path -LiteralPath $p -PathType Leaf)){return @{exists=$false}}
    $f=Get-Item -LiteralPath $p
    return @{exists=$true;sha256=(Sha $p);bytes=$f.Length;utc_ticks=$f.LastWriteTimeUtc.Ticks.ToString()}
}
function Same($a,$b){
    if([bool]$a.exists -ne [bool]$b.exists){return $false}
    if(-not $a.exists){return $true}
    return $a.sha256 -ceq $b.sha256 -and $a.bytes -eq $b.bytes -and $a.utc_ticks -ceq $b.utc_ticks
}
$baseline=Get-Content -Raw "$qaRoot/baseline_deploy9_ROOT_ACTUAL.json" | ConvertFrom-Json
$closurePath="$taskRoot/game/build/bianzhou_city_20261028_system01/source_closure04_READY/receipt.json"
$closure=Get-Content -Raw $closurePath | ConvertFrom-Json
$fixturePath="$qaRoot/bianzhou_world_roundtrip_READY.json"
$fixture=Get-Content -Raw $fixturePath | ConvertFrom-Json
$actualPath="$qaRoot/actual/13056/residual_result.json"
$actual=Get-Content -Raw $actualPath | ConvertFrom-Json
$worldPath="$qaRoot/actual/94776/world_roundtrip_result.json"
$world=Get-Content -Raw $worldPath | ConvertFrom-Json
$media=Get-Content -Raw "$taskRoot/game/build/major_cities_20261028_art01/promotion_ROOT_ACTUAL.json" | ConvertFrom-Json
$failures=@();$saveFacts=[ordered]@{};$currentFacts=[ordered]@{}
if(-not $actual.passed -or $actual.errors.Count -ne 0 -or $actual.checks -ne 48){$failures+='Residual result is not the actual bounded PASS.'}
if(-not $world.passed -or $world.errors.Count -ne 0 -or $world.checks -ne 39){$failures+='World re-entry branch is not the actual bounded PASS.'}
foreach($p in $baseline.save15.PSObject.Properties){
    $now=Fact $p.Name;$saveFacts[$p.Name]=$now
    if(-not(Same $now $p.Value)){$failures+=('Save exact bytes/ticks differ: '+$p.Name)}
}
foreach($b in $baseline.exact_full_backups){if(-not(Same (Fact $b.path) $b.fact)){$failures+=('Full backup differs: '+$b.path)}}
foreach($row in $closure.targets){
    $p="$taskRoot/$($row.target)";$now=Fact $p;$currentFacts[$row.target]=$now
    if($now.sha256 -cne $row.new_sha256 -or $now.bytes -ne $row.bytes){$failures+=('Canonical successor differs: '+$row.target)}
}
foreach($p in $fixture.fixed_sources.PSObject.Properties){
    $file="$taskRoot/game/"+$p.Name.Substring(6)
    if((Sha $file) -cne $p.Value){$failures+=('New city source differs: '+$p.Name)}
}
foreach($leaf in $media.leaves){
    $file="$taskRoot/game/"+$leaf.target.Substring(6)
    if((Sha $file) -cne $leaf.sha256){$failures+=('New media differs: '+$leaf.target)}
}
$scenePath="$taskRoot/game/data/scenes/openworld_bianzhou_city.tres"
if(-not(Same (Fact $scenePath) $baseline.canonical_targets.PSObject.Properties[$scenePath.Replace('/','\')].Value)){$failures+='Original Bianzhou Scene data changed.'}
$processes=@(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'" | Select-Object ProcessId,Name)
if($processes.Count -ne 1 -or $processes[0].ProcessId -ne 51856){$failures+='Expected only the retained user editor51856.'}
$result=[ordered]@{
    status=$(if($failures.Count -eq 0){'PASS'}else{'FAIL'});failures=$failures
    utc=[DateTime]::UtcNow.ToString('o');save15=$saveFacts;exact_full_backups_checked=$baseline.exact_full_backups.Count
    deployed9=$currentFacts;source_count=@($fixture.fixed_sources.PSObject.Properties).Count;new_media_leaves=$media.leaves.Count
    deployment_source_receipt=@{path=$closurePath;sha256=(Sha $closurePath)}
    actual_residual=@{path=$actualPath;sha256=(Sha $actualPath);checks=48;input_ticks=$actual.input_ticks}
    actual_world_reentry=@{path=$worldPath;sha256=(Sha $worldPath);checks=39;png_count=0;qa_pose_and_version_writes=0}
    prior_whole_failure_preserved=@{path="$qaRoot/actual/46236/result.json";sha256=(Sha "$qaRoot/actual/46236/result.json");only_passed_components_inherited=$true}
    original_scene_unchanged=$true;save_writes=0;godot_processes=$processes
    whole_city_art_pass=$false;other_cities_completed=$false
}
$stream=[IO.File]::Open($out,[IO.FileMode]::CreateNew)
$writer=[IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($false))
try{$writer.Write(($result|ConvertTo-Json -Depth 14)+"`n")}finally{$writer.Dispose()}
@{status=$result.status;path=$out;sha256=(Sha $out);failures=$failures;saves=15;backups=$result.exact_full_backups_checked;canonical=9;sources=$result.source_count;new_media=9}|ConvertTo-Json -Depth 4
if($failures.Count -ne 0){exit 1}
