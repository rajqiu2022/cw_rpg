param([string]$DeltaName='auth_UI03.json',[string]$OutputName='auth_FINAL_UI03.json',[string]$ExpectedWrapper='ee82a6fb8753dde08039d7501288ef0dc203e41f065906a5b92134b52df9bc50')
$ErrorActionPreference='Stop'
$taskRoot='F:/Code/RPG_GAME'
$fullPath=Join-Path $taskRoot 'game/build/three_towns_world_20261029j_system01/auth_FINAL.json'
if($DeltaName -cnotmatch '^auth_[A-Z0-9]+\.json$' -or $OutputName -cnotmatch '^auth_FINAL_[A-Z0-9]+\.json$' -or $ExpectedWrapper -cnotmatch '^[a-f0-9]{64}$'){throw 'Exact local delta/output names and SHA only.'}
$deltaPath=Join-Path $taskRoot ('game/build/three_towns_world_20261029j_system01/'+$DeltaName)
$outputPath=Join-Path $taskRoot ('game/build/three_towns_world_20261029j_qa01/'+$OutputName)
if((Get-FileHash -LiteralPath $fullPath -Algorithm SHA256).Hash -cne 'A08AB3195514DCF98FA97BA6055AFF996787D78290CE6B430D4FC9A584FD84B5'){throw 'Original full authorization changed.'}
$full=Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
$delta=Get-Content -LiteralPath $deltaPath -Raw | ConvertFrom-Json
$key='game/build/three_towns_world_20261029j_system01/town_field.gd'
if(@($delta.sources.PSObject.Properties).Count -ne 0 -or @($delta.new_modules.PSObject.Properties).Count -ne 1 -or $null -eq $delta.new_modules.PSObject.Properties[$key]){throw 'Only the exact one-wrapper UI delta is permitted.'}
$change=$delta.new_modules.PSObject.Properties[$key].Value
if($change.sha256 -cne $ExpectedWrapper){throw 'Unexpected wrapper UI successor.'}
$full.new_modules.PSObject.Properties[$key].Value=$change
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($full|ConvertTo-Json -Depth 30)+"`n")
$stream=[IO.File]::Open($outputPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
[ordered]@{path=$outputPath;sha256=(Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash;original_full_unchanged=$true;original_sources=@($full.sources.PSObject.Properties).Count;delta_modules=1;production_writes=0;engine_calls=0}|ConvertTo-Json -Compress
