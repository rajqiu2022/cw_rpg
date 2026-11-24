$ErrorActionPreference='Stop'
$taskRoot='F:/Code/RPG_GAME';$artRoot=Join-Path $taskRoot 'game/build/major_cities_20261028_art04'
$catalog=Join-Path $taskRoot 'docs/equipment-skill-catalog.html'
$before=[IO.File]::ReadAllText($catalog)
$pattern='<script id="catalogData" type="application/json">(.*?)</script>'
$match=[regex]::Match($before,$pattern,[Text.RegularExpressions.RegexOptions]::Singleline)
if(-not $match.Success){throw 'Existing catalog payload required.'}
$prior=$match.Groups[1].Value|ConvertFrom-Json
$prior.PSObject.Properties.Remove('resources')
$preserved=$prior|ConvertTo-Json -Depth 100 -Compress
$backup=Join-Path $artRoot 'catalog_before_resources_sync.html'
if(Test-Path -LiteralPath $backup){throw 'CreateNew backup only.'}
[IO.File]::Copy($catalog,$backup,$false)
& python (Join-Path $taskRoot 'scripts/build_arsenal_catalog.py') --sync-resources-only
if($LASTEXITCODE -ne 0){throw 'Resources-only build failed; original backup retained.'}
$after=[IO.File]::ReadAllText($catalog)
$payload=([regex]::Match($after,$pattern,[Text.RegularExpressions.RegexOptions]::Singleline).Groups[1].Value)|ConvertFrom-Json
$resources=$payload.resources
$payload.PSObject.Properties.Remove('resources')
if(($payload|ConvertTo-Json -Depth 100 -Compress) -cne $preserved){throw 'Nonresources payload changed; stop and preserve failure.'}
$rows=@($resources.records|Where-Object {$_.diskPath -like '*/bianzhou_enclosure_20261028d/*'})
if($rows.Count -ne 16 -or @($rows|Where-Object status -eq rejected).Count -ne 2){throw 'Exact sixteen source/derived/game rows and two rejected drafts required.'}
foreach($row in $rows){if(-not [IO.File]::Exists((Join-Path $taskRoot $row.diskPath)) -or -not [IO.File]::Exists((Join-Path $taskRoot ('docs/'+$row.thumbnail)))){throw 'New original or thumbnail path missing.'}}
$result=[ordered]@{status='PASS';summary=$resources.summary;bianzhou_rows=16;rejected_old_sidewalls=2;nonresources_payload_exact=$true;backup=$backup;catalog_sha256=(Get-FileHash $catalog -Algorithm SHA256).Hash.ToLowerInvariant();browser_interaction_tested=$false;audio_playback_tested=$false}
$output=Join-Path $artRoot 'gallery_sync_ROOT_ACTUAL.json';$s=[IO.File]::Open($output,[IO.FileMode]::CreateNew);$w=[IO.StreamWriter]::new($s,[Text.UTF8Encoding]::new($false));try{$w.Write(($result|ConvertTo-Json -Depth 10)+"`n")}finally{$w.Dispose()}
$result|ConvertTo-Json -Depth 10 -Compress
