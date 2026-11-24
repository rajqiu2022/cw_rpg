$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME'
$out="$repo/game/build/player_portrait_minimap_20261030f_system01"
$prior=Get-Content "$repo/game/build/city_minimap_simple_frame_20261030d_system01/ready02/receipt_READY.json" -Raw | ConvertFrom-Json
$paths=@($prior.targets.target)+@('game/build/luoyang_garden_city_minimap_20261030b_system01/city_minimap.gd','game/build/three_settlements_20261030e_system01/city_minimap.gd','game/build/four_settlements_20261030e_system01/minimap.gd','game/build/three_towns_world_20261029j_system01/native_sources.json','game/build/three_towns_world_20261029j_system01/town_registry.gd')
if(Test-Path -LiteralPath "$out/baseline_sources_before.json"){throw 'IMMUTABLE_BASELINE_EXISTS'}
function Fact([string]$p){$i=Get-Item -LiteralPath $p;return [ordered]@{sha256=(Get-FileHash -LiteralPath $p).Hash.ToLowerInvariant();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
$sources=[ordered]@{};$backups=@()
foreach($p in $paths|Select-Object -Unique){
 $before=Fact "$repo/$p";$target="$out/source_before/$p"
 [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))|Out-Null
 $stream=[IO.File]::Open($target,[IO.FileMode]::CreateNew);try{$bytes=[IO.File]::ReadAllBytes("$repo/$p");$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
 [IO.File]::SetLastWriteTimeUtc($target,[DateTime]::new([long]$before.utc_ticks,[DateTimeKind]::Utc));$copy=Fact $target
 if($copy.sha256-ne$before.sha256-or$copy.bytes-ne$before.bytes-or$copy.utc_ticks-ne$before.utc_ticks){throw "SOURCE_COPY_RACE:$p"}
 $sources[$p]=$before;$backups+=@{source=$p;backup=$target;fact=$copy}
}
$native=Get-Content "$repo/game/build/three_towns_world_20261029j_system01/native_sources.json" -Raw | ConvertFrom-Json -AsHashtable
if($native.sources.Count-ne125){throw 'LATEST_NATIVE125_REQUIRED'}
$record=[ordered]@{status='SOURCE_ONLY_WHILE_USER_GAME_MAY_STILL_RUN';sources=$sources;exact_backups=$backups;native_sources_count=125;old_native_sources=$native.sources;save_protection='Root QA will capture fresh171 after user game stops; this source receipt makes no save equality claim';save_contents_read=$false;save_writes=0;engine_runs=0;production_writes=0;processes_stopped=0}
$data=[Text.UTF8Encoding]::new($false).GetBytes(($record|ConvertTo-Json -Depth 18)+"`n");$s=[IO.File]::Open("$out/baseline_sources_before.json",[IO.FileMode]::CreateNew);try{$s.Write($data,0,$data.Length)}finally{$s.Dispose()}
[ordered]@{sources=$sources.Count;backups=$backups.Count;native_sources=125;sha256=(Fact "$out/baseline_sources_before.json").sha256;save_reads=0;production_writes=0}|ConvertTo-Json
