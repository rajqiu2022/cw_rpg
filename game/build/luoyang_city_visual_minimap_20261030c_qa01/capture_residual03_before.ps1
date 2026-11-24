$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/luoyang_city_visual_minimap_20261030c_qa01"
$receipt=Get-Content "$repo/game/build/luoyang_city_visual_minimap_20261030c_system01/residual03/closure_READY/receipt_READY.json" -Raw | ConvertFrom-Json
$old=Get-Content "$qa/freeze_ROOT_ACTUAL.json" -Raw | ConvertFrom-Json
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
$rows=@($receipt.targets)+@($receipt.module_targets);if($rows.Count -ne 11){throw 'EXACT23_PLUS1_REQUIRED'}
$sources=[ordered]@{};$backups=@();$saves=[ordered]@{}
foreach($row in $rows){$path=$row.target;$f=Fact "$repo/$path";if($f.sha256 -ne $row.old_sha256){throw "PARENT_CHANGED:$path"};$sources[$path]=$f;$backup="$qa/source_before_residual03/$path";[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($backup)) | Out-Null;$stream=[IO.File]::Open($backup,[IO.FileMode]::CreateNew);try{$bytes=[IO.File]::ReadAllBytes("$repo/$path");$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()};[IO.File]::SetLastWriteTimeUtc($backup,[DateTime]::new([long]$f.utc_ticks,[DateTimeKind]::Utc));$bf=Fact $backup;if($bf.sha256 -ne $f.sha256 -or $bf.bytes -ne $f.bytes -or $bf.utc_ticks -ne $f.utc_ticks){throw "BACKUP_RACE:$path"};$backups+=@{source=$path;path=$backup;fact=$bf}}
foreach($p in $old.saves.PSObject.Properties){$saves[$p.Name]=Fact $p.Name}
$result=[ordered]@{status='RESIDUAL04_ONLY10SOURCE_PLUS1MODULE_BEFORE';sources=$sources;exact_backups=$backups;registered_save_paths=$saves;previous_freeze_sha256=(Fact "$qa/freeze_ROOT_ACTUAL.json").sha256;ui110_success_inherited='15988 346/0 and ART inherited; no rerun';engine_calls=0;production_writes=0;save_contents_read=$false;save_writes=0}
$path="$qa/residual03_before_ACTUAL.json";$stream=[IO.File]::Open($path,[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($result | ConvertTo-Json -Depth 22)+"`n");$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
[ordered]@{path=$path;sha256=(Fact $path).sha256;source_count=$sources.Count;backups=$backups.Count;saves=$saves.Count} | ConvertTo-Json


