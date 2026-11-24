$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/luoyang_garden_city_minimap_20261030b_qa01"
$runtime=Get-Content "$qa/runtime_before_ACTUAL.json" -Raw | ConvertFrom-Json
$receipt=Get-Content "$repo/game/build/luoyang_garden_city_minimap_20261030b_system01/ready02/receipt_READY.json" -Raw | ConvertFrom-Json
$previous=Get-Content "$repo/game/build/luoyang_private_garden_20261029q_qa01/freeze_ROOT_ACTUAL.json" -Raw | ConvertFrom-Json
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
function Same($a,$v){return $a.exists -eq $v.exists -and (!$a.exists -or ($a.sha256 -eq $v.sha256 -and $a.bytes -eq $v.bytes -and $a.utc_ticks -eq $v.utc_ticks))}
if(@($receipt.targets).Count -ne 28){throw 'EXACT28_REQUIRED'}
$sources=[ordered]@{};$backups=@($runtime.exact_backups);$newBackups=@();$protected=[ordered]@{};$saves=[ordered]@{}
foreach($row in $receipt.targets){$path=$row.target;$f=Fact "$repo/$path";if($f.sha256 -ne $row.old_sha256){throw "OLD_PARENT_CHANGED:$path"};$sources[$path]=$f
 if($null -ne $runtime.sources.$path){if(!(Same $f $runtime.sources.$path)){throw "ORIGINAL4_CHANGED:$path"};continue}
 $target="$qa/source_before/$path";[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null;$s=[IO.File]::Open($target,[IO.FileMode]::CreateNew);try{$bytes=[IO.File]::ReadAllBytes("$repo/$path");$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()};[IO.File]::SetLastWriteTimeUtc($target,[DateTime]::new([long]$f.utc_ticks,[DateTimeKind]::Utc));$bf=Fact $target;if(!(Same $f $bf)){throw "BACKUP_RACE:$path"};$newBackups+=@{source=$path;path=$target;fact=$bf}
}
$externalNames=@($runtime.external_parallel_sources.PSObject.Properties.Name)
foreach($p in $previous.sources.PSObject.Properties){if($sources.Contains($p.Name) -or $p.Name -in $externalNames){continue};$protected[$p.Name]=Fact "$repo/$($p.Name)"}
foreach($p in $runtime.registered_save_paths.PSObject.Properties){$saves[$p.Name]=Fact $p.Name}
$backups+=@($newBackups)
$result=[ordered]@{status='EXACT28_BEFORE_WITH_ONLY24_ADDITIONAL_FULL_BACKUPS';sources=$sources;protected_sources=$protected;exact_backups=$backups;new_exact_backups=$newBackups;registered_save_paths=$saves;external_parallel_sources=$runtime.external_parallel_sources;external_policy='record-only from start';receipt_sha256=(Fact "$repo/game/build/luoyang_garden_city_minimap_20261030b_system01/ready02/receipt_READY.json").sha256;old_runtime_baseline=(Fact "$qa/runtime_before_ACTUAL.json");engine_calls=0;production_writes=0;save_contents_read=$false;save_writes=0}
$path="$qa/closure_before_SUPPLEMENT.json";$s=[IO.File]::Open($path,[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($result | ConvertTo-Json -Depth 22)+"`n");$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()}
[ordered]@{path=$path;sha256=(Fact $path).sha256;targets=$sources.Count;new_backups=$newBackups.Count;total_backups=$backups.Count;protected=$protected.Count;saves=$saves.Count;external_record_only=$externalNames.Count} | ConvertTo-Json
