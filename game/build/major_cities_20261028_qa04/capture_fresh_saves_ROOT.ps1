$ErrorActionPreference='Stop'
$taskRoot='F:/Code/RPG_GAME';$qaRoot=Join-Path $taskRoot 'game/build/major_cities_20261028_qa04'
$baseline=Get-Content -Raw -LiteralPath (Join-Path $qaRoot 'baseline_before_ACTUAL.json')|ConvertFrom-Json
$output=Join-Path $qaRoot 'save15_before_authorized_resume_ROOT_ACTUAL.json'
if(Test-Path -LiteralPath $output){throw 'CreateNew only.'}
$facts=[ordered]@{}
foreach($p in $baseline.save15.PSObject.Properties){if([IO.File]::Exists($p.Name)){$i=Get-Item -LiteralPath $p.Name;$facts[$p.Name]=[ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p.Name -Algorithm SHA256).Hash.ToLowerInvariant();bytes=$i.Length;utc_ticks=$i.LastWriteTimeUtc.Ticks.ToString()}}else{$facts[$p.Name]=[ordered]@{exists=$false}}}
if($facts.Count -ne 15){throw 'Original fifteen paths only.'}
$s=[IO.File]::Open($output,[IO.FileMode]::CreateNew);$w=[IO.StreamWriter]::new($s,[Text.UTF8Encoding]::new($false));try{$w.Write(($facts|ConvertTo-Json -Depth 8)+"`n")}finally{$w.Dispose()}
[ordered]@{path=$output;sha256=(Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash.ToLowerInvariant();save_paths=$facts.Count;save_contents_parsed=$false;save_writes=0}|ConvertTo-Json -Compress
