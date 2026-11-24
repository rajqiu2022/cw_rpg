$ErrorActionPreference='Stop'
$taskRoot='F:/Code/RPG_GAME';$artRoot=Join-Path $taskRoot 'game/build/major_cities_20261028_art04'
function Fact([string]$p){if(-not [IO.File]::Exists($p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;[ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant();bytes=$i.Length;utc_ticks=$i.LastWriteTimeUtc.Ticks.ToString()}}
function WriteNew([string]$p,$data){$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew);$w=[IO.StreamWriter]::new($s,[Text.UTF8Encoding]::new($false));try{$w.Write(($data|ConvertTo-Json -Depth 15)+"`n")}finally{$w.Dispose()}}
$verifiedPath=Join-Path $artRoot 'import05/verify_result_61624.json'
$verified=Get-Content -Raw -LiteralPath $verifiedPath|ConvertFrom-Json
if($verified.status -ne 'PASS' -or $verified.checks -ne 86 -or $verified.failures.Count -ne 0 -or $verified.textures.Count -ne 5){throw 'Five frozen images must pass whole-RGBA verification.'}
$plan=Get-Content -Raw -LiteralPath (Join-Path $artRoot 'fifteen_leaf_promotion_plan_NOT_EXECUTED.json')|ConvertFrom-Json
if($plan.leaves.Count -ne 15){throw 'Exactly fifteen new media leaves only.'}
$expected=@{}
foreach($row in $verified.textures){$expected[$row.png]=$row.png_sha256;$expected[$row.png+'.import']=$row.sidecar_sha256;$expected[$row.ctex]=$row.ctex_sha256}
$receipt=Join-Path $artRoot 'promotion_fifteen_ROOT_ACTUAL.json';$factsPath=Join-Path $artRoot 'new_media_facts_ROOT_ACTUAL.json';$modulePath=Join-Path $artRoot 'new_modules_before_ROOT_ACTUAL.json'
foreach($p in @($receipt,$factsPath,$modulePath)){if(Test-Path -LiteralPath $p){throw 'CreateNew receipts only.'}}
foreach($leaf in $plan.leaves){
 $dest=[IO.Path]::GetFullPath($leaf.target_main)
 if(-not $dest.StartsWith([IO.Path]::GetFullPath((Join-Path $taskRoot 'game'))+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Target escaped main project.'}
 if(Test-Path -LiteralPath $dest){throw "Target already exists: $dest"}
 if((Fact $leaf.source_isolate).sha256 -cne $expected[$leaf.target_res]){throw 'Frozen import source differs.'}
}
$modules=[ordered]@{}
foreach($relative in @('game/build/bianzhou_city_20261028_system04/completion_binding_BUILD.json','game/build/bianzhou_city_20261028_system04/gate_binding_BUILD.json')){$modules[$relative]=Fact (Join-Path $taskRoot $relative)}
WriteNew $modulePath $modules
$facts=[ordered]@{}
foreach($kind in @('ctex','sidecar','png')){
 foreach($leaf in $plan.leaves|Where-Object kind -eq $kind){
  [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($leaf.target_main))|Out-Null
  [IO.File]::Copy($leaf.source_isolate,$leaf.target_main,$false)
  $fact=Fact $leaf.target_main
  if($fact.sha256 -cne $expected[$leaf.target_res]){throw 'Promoted bytes mismatch.'}
  $facts['game/'+$leaf.target_res.Substring(6)]=$fact
 }
}
WriteNew $factsPath $facts
WriteNew $receipt ([ordered]@{status='PASS_FIFTEEN_NEW_LEAVES';verify_result=$verifiedPath;verify_sha256=(Fact $verifiedPath).sha256;processing_sha256=(Fact (Join-Path $artRoot 'processing_actual.json')).sha256;new_leaf_count=15;facts_path=$factsPath;new_modules_before_path=$modulePath;formal_code_writes=0;old_media_writes=0;save_writes=0;editor51856=[bool](Get-Process -Id 51856 -ErrorAction SilentlyContinue)})
[ordered]@{receipt=$receipt;sha256=(Fact $receipt).sha256;new_media=$facts.Count;new_modules_before=$modules.Count}|ConvertTo-Json -Compress
