$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/luoyang_private_garden_20261029q_qa01"
$b=Get-Content "$qa/baseline_before_ACTUAL.json" -Raw | ConvertFrom-Json
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
function Same($a,$v){return $a.exists -eq $v.exists -and (!$a.exists -or ($a.sha256 -eq $v.sha256 -and $a.bytes -eq $v.bytes -and $a.utc_ticks -eq $v.utc_ticks))}
$paths=@($b.sources.PSObject.Properties.Name | Where-Object {$_ -notlike 'game/build/luoyang_regions_*'})
if($paths.Count -ne 9){throw 'EXACT_NINE_SHARED_PARENT_SOURCES'}
$current=[ordered]@{};$prior=[ordered]@{};$backups=@();$saves=[ordered]@{};$saveChanges=@()
foreach($path in $paths){
 $fact=Fact "$repo/$path";if(!$fact.exists){throw "PARENT_MISSING:$path"};$current[$path]=$fact;$prior[$path]=$b.sources.$path
 $target="$qa/source_before_linxi_parent/$path";[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
 $s=[IO.File]::Open($target,[IO.FileMode]::CreateNew);try{$bytes=[IO.File]::ReadAllBytes("$repo/$path");$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()}
 [IO.File]::SetLastWriteTimeUtc($target,[DateTime]::new([long]$fact.utc_ticks,[DateTimeKind]::Utc));$after=Fact $target
 if(!(Same $after $fact)){throw "PARENT_EXACT_BACKUP_FAILED:$path"};$backups+=@{source=$path;path=$target;fact=$after}
}
if(!$current['game/scripts/autoload/scene_router.gd'].sha256.StartsWith('c0edab77') -or !$current['game/data/maps/luoyang_full_city_20261022ap/execution_successor.json'].sha256.StartsWith('e959a8f9')){throw 'ROOT_APPROVED_LINXI_PARENT_PREFIX_NOT_CURRENT'}
foreach($p in $b.registered_save_paths.PSObject.Properties){$f=Fact $p.Name;$saves[$p.Name]=$f;if(!(Same $f $p.Value)){$saveChanges+=@{path=$p.Name;historical=$p.Value;current=$f}}}
$result=[ordered]@{status='ROOT_APPROVED_PARALLEL_LINXI_PARENT_AND_CURRENT_SAVES';original_baseline_unchanged=(Fact "$qa/baseline_before_ACTUAL.json");historical_nine=$prior;current_nine=$current;exact_backups=$backups;registered_save_paths=$saves;external_save_changes=$saveChanges;scope='Only current9 parent-source snapshots and current171 save metadata; preserve parallel Linxi, never roll back';save_contents_read=$false;save_writes=0;source_restore=0;production_writes=0;engine_calls=0}
$path="$qa/parallel_parent_before_SUPPLEMENT.json";$s=[IO.File]::Open($path,[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($result | ConvertTo-Json -Depth 20)+"`n");$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()}
[ordered]@{path=$path;sha256=(Fact $path).sha256;parent_sources=$current.Count;new_exact_backups=$backups.Count;save_count=$saves.Count;external_save_changes=$saveChanges.Count;changed_save_paths=@($saveChanges.path)} | ConvertTo-Json -Depth 4
