param([switch]$After)
$ErrorActionPreference='Stop'
$root='F:/Code/RPG_GAME/game/'
$source=$root+'build/luoyang_layout_quest_20261018t_layout_source01/runtime_source_successor02/final/deployment.json'
$deployment=Get-Content -Raw $source|ConvertFrom-Json
$facts=@(foreach($row in $deployment.targets){
 $path=$row.target.Replace('res://',$root)
 $expected=if($After){$row.new_sha256}else{$row.old_sha256}
 $sha=(Get-FileHash -LiteralPath $path).Hash
 if($sha -ne $expected){throw "Exact deployment mismatch: $path"}
 $candidate=$row.candidate.Replace('res://',$root)
 if((Get-FileHash -LiteralPath $candidate).Hash -ne $row.new_sha256){throw "Candidate drift: $candidate"}
 $file=Get-Item -LiteralPath $path
 [ordered]@{path=$path;sha256=$sha;bytes=$file.Length;ticks=$file.LastWriteTimeUtc.Ticks.ToString()}
})
$out=$root+'build/luoyang_layout_quest_20261018u_root01/successor02_'+$(if($After){'after'}else{'before'})+'.json'
[ordered]@{observed_at=[DateTimeOffset]::Now.ToString('o');deployment_sha=(Get-FileHash -LiteralPath $source).Hash;facts=$facts}|ConvertTo-Json -Depth 7|Out-File -LiteralPath $out -Encoding utf8
"Eight exact targets verified; after=$After"
