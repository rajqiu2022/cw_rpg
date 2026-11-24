$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME'
$rel='game/scripts/adventure/adventure_minimap.gd'
$target=Join-Path $repo $rel
$folder=Join-Path $repo 'game/build/riverside_visual_20261101a_source01'
$receipt=Join-Path $folder 'minimap_before_ACTUAL.json'
$backup=Join-Path $folder ('before/'+$rel)
if((Test-Path -LiteralPath $receipt) -or (Test-Path -LiteralPath $backup)){throw 'NEW_SUPPLEMENT_ONLY'}
$a=Get-Item -LiteralPath $target
$ticks=$a.LastWriteTimeUtc.Ticks.ToString();$bytes=$a.Length
$sha=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant()
$b=Get-Item -LiteralPath $target
if($bytes -ne $b.Length -or $ticks -ne $b.LastWriteTimeUtc.Ticks.ToString()){throw 'UNSTABLE_SOURCE'}
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $backup) | Out-Null
Copy-Item -LiteralPath $target -Destination $backup
if((Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash.ToLowerInvariant() -ne $sha){throw 'BACKUP_MISMATCH'}
$data=[ordered]@{captured_utc=[DateTime]::UtcNow.ToString('o');authorized_third_old_target=$target.Replace('\','/');before=[ordered]@{exists=$true;bytes=$bytes;utc_ticks=$ticks;sha256=$sha;stable_during_hash=$true};backup=$backup.Replace('\','/');scope='NEW_MINIMAP_SUPPLEMENT_BEFORE_ROOT_HOOK_ONLY';production_writes=0;engine_runs=0;save_writes=0}
[IO.File]::WriteAllText($receipt,($data|ConvertTo-Json -Depth 6),[Text.UTF8Encoding]::new($false))
$data|ConvertTo-Json -Depth 6
