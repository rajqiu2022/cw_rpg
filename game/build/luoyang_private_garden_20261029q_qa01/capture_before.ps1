$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/luoyang_private_garden_20261029q_qa01"
$prior=Get-Content "$repo/game/build/luoyang_hall_boundary_20261029p_qa01/freeze_ROOT_ACTUAL.json" -Raw | ConvertFrom-Json
$auth=Get-Content "$repo/game/build/luoyang_hall_boundary_20261029p_system01/closure_READY01/auth_READY.json" -Raw | ConvertFrom-Json
$original=Get-Content "$repo/game/build/luoyang_yihongyuan_20261029n_qa01/baseline_before_ACTUAL.json" -Raw | ConvertFrom-Json
$manifest=Get-Content "$repo/game/build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json" -Raw | ConvertFrom-Json
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
function Same($x,$y){return $x.exists -eq $y.exists -and (!$x.exists -or ($x.sha256 -eq $y.sha256 -and $x.bytes -eq $y.bytes -and $x.utc_ticks -eq $y.utc_ticks))}
$targetPaths=@($auth.sources.PSObject.Properties.Name | Where-Object {$_ -ne 'game/build/luoyang_regions_20261027d_source01/region_field.gd'})+@('game/build/luoyang_regions_20261027d_source01/region_entry.gd')
$targets=[ordered]@{};$protected=[ordered]@{};$backups=@();$saves=[ordered]@{}
foreach($path in $targetPaths){
 $source="$repo/$path";$fact=Fact $source
 if(!$fact.exists -or !(Same $fact $prior.sources.$path)){throw "BEFORE_CHANGED:$path"}
 $targets[$path]=$fact;$backup="$qa/source_before/$path";[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($backup)) | Out-Null
 $s=[IO.File]::Open($backup,[IO.FileMode]::CreateNew);try{$bytes=[IO.File]::ReadAllBytes($source);$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()}
 [IO.File]::SetLastWriteTimeUtc($backup,[DateTime]::new([long]$fact.utc_ticks,[DateTimeKind]::Utc));$backups+=@{source=$path;path=$backup;fact=(Fact $backup)}
}
$externalPaths=@('game/build/three_towns_world_20261029j_system01/town_registry.gd','game/build/three_towns_world_20261029j_system01/native_sources.json','game/scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn','game/scenes/drafts/desert_town_20261029d/desert_town.tscn')
$external=[ordered]@{};foreach($path in $externalPaths){$external[$path]=Fact "$repo/$path"}
$protectPaths=@($original.protected_sources.PSObject.Properties.Name | Where-Object {$_ -notin $externalPaths})+@('game/build/luoyang_regions_20261027d_source01/region_field.gd','game/build/luoyang_hall_boundary_20261029p_system01/hall_boundary.gd','game/build/luoyang_hall_boundary_20261029p_system01/room_patch.gdshader','game/build/luoyang_threshold_20261029o_system01/threshold_restore.gd')
foreach($p in $manifest.compiled_bindings.PSObject.Properties){$protectPaths+='game/'+$p.Value.path.Substring(6)}
foreach($path in $protectPaths | Select-Object -Unique){if($targets.Contains($path)){continue};$f=Fact "$repo/$path";if(!$f.exists){throw "MISSING:$path"};$protected[$path]=$f}
foreach($p in $prior.saves.PSObject.Properties){$saves[$p.Name]=Fact $p.Name}
$result=[ordered]@{status='ONLY_PRIVATE_GARDEN_CONNECTION_AND_LANDSCAPE_BEFORE';sources=$targets;protected_sources=$protected;exact_backups=$backups;registered_save_paths=$saves;all_ten_predecessor_bins=$manifest.compiled_bindings;external_parallel_sources=$external;external_policy='Root-approved record-only; never restore or silently upgrade prior29p FAIL';engine_calls=0;production_writes=0;save_contents_read=$false;save_writes=0;processes_stopped=0}
$path="$qa/baseline_before_ACTUAL.json";$s=[IO.File]::Open($path,[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($result | ConvertTo-Json -Depth 22)+"`n");$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()}
[ordered]@{path=$path;sha256=(Fact $path).sha256;targets=$targets.Count;protected=$protected.Count;backups=$backups.Count;saves=$saves.Count;bins=@($manifest.compiled_bindings.PSObject.Properties).Count} | ConvertTo-Json


