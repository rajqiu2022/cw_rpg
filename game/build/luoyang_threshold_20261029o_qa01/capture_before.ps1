$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/luoyang_threshold_20261029o_qa01"
$oldQa="$repo/game/build/luoyang_yihongyuan_20261029n_qa01"
$original=Get-Content "$oldQa/baseline_before_ACTUAL.json" -Raw | ConvertFrom-Json
$old=Get-Content "$oldQa/trip03_freeze_ROOT_ACTUAL.json" -Raw | ConvertFrom-Json
$priorAuth=Get-Content "$repo/game/build/luoyang_yihongyuan_20261029n_system01/visual03/closure_READY01/auth_READY.json" -Raw | ConvertFrom-Json
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
$targets=[ordered]@{};$protected=[ordered]@{};$backups=@();$saves=[ordered]@{}
foreach($p in $priorAuth.sources.PSObject.Properties){
 $source="$repo/$($p.Name)";$fact=Fact $source
 if($fact.sha256 -ne $p.Value.sha256 -or $fact.bytes -ne $p.Value.bytes){throw "BEFORE_TARGET_CHANGED:$($p.Name)"}
 $targets[$p.Name]=$fact;$backup="$qa/source_before/$($p.Name)"
 [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($backup)) | Out-Null
 $s=[IO.File]::Open($backup,[IO.FileMode]::CreateNew);try{$bytes=[IO.File]::ReadAllBytes($source);$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()}
 [IO.File]::SetLastWriteTimeUtc($backup,[DateTime]::new([long]$fact.utc_ticks,[DateTimeKind]::Utc))
 $backups+=@{source=$p.Name;path=$backup;fact=(Fact $backup)}
}
$paths=@($original.protected_sources.PSObject.Properties.Name)+@('game/build/luoyang_regions_20261027d_source01/region_field.gd','game/build/luoyang_regions_20261027d_source01/region_entry.gd','game/build/luoyang_yihongyuan_20261029n_system01/ambient_conversation.gd','game/build/luoyang_yihongyuan_20261029n_system01/native_layers.gd','game/build/luoyang_yihongyuan_20261029n_system01/room_factory.gd','game/build/luoyang_yihongyuan_20261029n_system01/visual03/output/60160/luoyang_civic_market_region_27d.bin','game/build/luoyang_yihongyuan_20261029n_system01/visual03/output/60160/yihongyuan27n_interior.bin')
foreach($path in $paths | Select-Object -Unique){if($targets.Contains($path)){continue};$f=Fact "$repo/$path";if(!$f.exists){throw "MISSING_PROTECTED:$path"};$protected[$path]=$f}
foreach($p in $old.saves.PSObject.Properties){$saves[$p.Name]=Fact $p.Name}
$result=[ordered]@{status='ONLY_ESTATE_MAIN_HALL_THRESHOLD_BEFORE';sources=$targets;protected_sources=$protected;exact_backups=$backups;registered_save_paths=$saves;engine_calls=0;production_writes=0;save_contents_read=$false;save_writes=0;processes_stopped=0}
$path="$qa/baseline_before_ACTUAL.json";$stream=[IO.File]::Open($path,[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($result | ConvertTo-Json -Depth 20)+"`n");$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
[ordered]@{path=$path;sha256=(Fact $path).sha256;targets=$targets.Count;protected=$protected.Count;backups=$backups.Count;saves=$saves.Count} | ConvertTo-Json
