$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/city_minimap_simple_frame_20261030d_qa01"
$previous=Get-Content "$repo/game/build/luoyang_city_visual_minimap_20261030c_qa01/visual03_freeze_ROOT_ACTUAL.json" -Raw | ConvertFrom-Json
$receipt=Get-Content "$repo/game/build/luoyang_city_visual_minimap_20261030c_system01/ready02/receipt_READY.json" -Raw | ConvertFrom-Json
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
$rows=@($receipt.targets)+@($receipt.module_targets);if($rows.Count -ne 24){throw 'EXACT24_REQUIRED'}
$sources=[ordered]@{};$backups=@();$protected=[ordered]@{};$saves=[ordered]@{};$external=[ordered]@{}
foreach($row in $rows){$path=$row.target;$f=Fact "$repo/$path";$sources[$path]=$f;$target="$qa/source_before/$path";[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null;$stream=[IO.File]::Open($target,[IO.FileMode]::CreateNew);try{$bytes=[IO.File]::ReadAllBytes("$repo/$path");$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()};[IO.File]::SetLastWriteTimeUtc($target,[DateTime]::new([long]$f.utc_ticks,[DateTimeKind]::Utc));$bf=Fact $target;if($bf.sha256 -ne $f.sha256 -or $bf.bytes -ne $f.bytes -or $bf.utc_ticks -ne $f.utc_ticks){throw "COPY_RACE:$path"};$backups+=@{source=$path;path=$target;fact=$bf}}
foreach($p in $previous.sources.PSObject.Properties){if(!$sources.Contains($p.Name)){$protected[$p.Name]=Fact "$repo/$($p.Name)"}}
foreach($p in $previous.saves.PSObject.Properties){$saves[$p.Name]=Fact $p.Name}
foreach($p in $previous.external_run_before.PSObject.Properties){$external[$p.Name]=Fact "$repo/$($p.Name)"}
$result=[ordered]@{status='SIMPLE_FRAME_ONLY_FRESH24_BEFORE';sources=$sources;exact_backups=$backups;protected_sources=$protected;registered_save_paths=$saves;external_parallel_sources=$external;external_policy='Four parallel paths record-only from start, no restore';engine_calls=0;production_writes=0;save_contents_read=$false;save_writes=0}
$out="$qa/baseline_before_ACTUAL.json";$stream=[IO.File]::Open($out,[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($result | ConvertTo-Json -Depth 22)+"`n");$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
[ordered]@{path=$out;sha256=(Fact $out).sha256;targets=$sources.Count;backups=$backups.Count;protected=$protected.Count;saves=$saves.Count;external_record_only=$external.Count} | ConvertTo-Json
