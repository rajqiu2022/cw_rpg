param([Parameter(Mandatory=$true)][string]$VerifiedPath)
$ErrorActionPreference='Stop'
$taskRoot='F:/Code/RPG_GAME';$artRoot=Join-Path $taskRoot 'game/build/jinling_city_20261029_art01'
function Fact([string]$p){if(-not [IO.File]::Exists($p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;[ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant();bytes=$i.Length;utc_ticks=$i.LastWriteTimeUtc.Ticks.ToString()}}
function WriteNew([string]$p,$data){$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew);$w=[IO.StreamWriter]::new($s,[Text.UTF8Encoding]::new($false));try{$w.Write(($data|ConvertTo-Json -Depth 12)+"`n")}finally{$w.Dispose()}}
$resolved=[IO.Path]::GetFullPath($VerifiedPath)
$isolate=[IO.Path]::GetFullPath((Join-Path $artRoot 'water_import01'))+[IO.Path]::DirectorySeparatorChar
if(-not $resolved.StartsWith($isolate,[StringComparison]::OrdinalIgnoreCase)){throw 'Only this water isolate verification allowed.'}
$verified=Get-Content -Raw -LiteralPath $resolved|ConvertFrom-Json
if($verified.status -ne 'PASS' -or $verified.checks -ne 18 -or $verified.failures.Count -ne 0 -or $verified.textures.Count -ne 1 -or -not $verified.textures[0].whole_RGBA_exact){throw 'Single whole-RGBA verify required.'}
$plan=Get-Content -Raw -LiteralPath (Join-Path $artRoot 'three_leaf_plan_NOT_EXECUTED.json')|ConvertFrom-Json
if($plan.leaves.Count -ne 3){throw 'Exactly three leaves only.'}
$row=$verified.textures[0]
if($row.png -cne 'res://art/maps/jinling_city_20261029/river_water_v1.png' -or $row.png_sha256 -cne '54718c63a29a7492e78f637acdeb3237b6ddcc43e9dbca07b5b77a373f8081fc'){throw 'Frozen water mismatch.'}
$expected=@{};$expected[$row.png]=$row.png_sha256;$expected[$row.png+'.import']=$row.sidecar_sha256;$expected[$row.ctex]=$row.ctex_sha256
$receipt=Join-Path $artRoot 'water_promotion_ROOT_ACTUAL.json';if(Test-Path -LiteralPath $receipt){throw 'CreateNew receipt only.'}
foreach($leaf in $plan.leaves){
 $expectedMain=[IO.Path]::GetFullPath((Join-Path (Join-Path $taskRoot 'game') $leaf.target_res.Substring(6)))
 $expectedSource=[IO.Path]::GetFullPath((Join-Path $isolate $leaf.target_res.Substring(6)))
 if([IO.Path]::GetFullPath($leaf.target_main) -cne $expectedMain -or [IO.Path]::GetFullPath($leaf.source_isolate) -cne $expectedSource -or -not $expected.ContainsKey($leaf.target_res)){throw 'Exact leaf mapping mismatch.'}
 if(Test-Path -LiteralPath $leaf.target_main){throw 'Never overwrite an existing formal media leaf.'}
 if((Fact $leaf.source_isolate).sha256 -cne $expected[$leaf.target_res]){throw 'Isolate source drifted.'}
}
$facts=[ordered]@{}
foreach($kind in @('ctex','sidecar','png')){foreach($leaf in $plan.leaves|Where-Object kind -eq $kind){
 [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($leaf.target_main))|Out-Null
 [IO.File]::Copy($leaf.source_isolate,$leaf.target_main,$false)
 $facts[$leaf.target_res]=Fact $leaf.target_main
 if($facts[$leaf.target_res].sha256 -cne $expected[$leaf.target_res]){throw 'Promoted byte mismatch.'}
}}
WriteNew $receipt ([ordered]@{status='PASS_THREE_NEW_WATER_LEAVES';verify_result=$resolved;verify_sha256=(Fact $resolved).sha256;new_leaf_count=3;facts=$facts;old_media_writes=0;formal_code_writes=0;save_writes=0;raw_preserved=$true})
[ordered]@{receipt=$receipt;sha256=(Fact $receipt).sha256;new_media=3}|ConvertTo-Json -Compress
