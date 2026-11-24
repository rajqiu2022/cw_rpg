$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/three_settlements_20261030e_qa01"
$previous=Get-Content "$repo/game/build/city_minimap_simple_frame_20261030d_qa01/freeze_ROOT_ACTUAL.json" -Raw | ConvertFrom-Json
$routerNine=Get-Content "$repo/game/build/three_towns_world_20261029j_system01/auth_FINAL.json" -Raw | ConvertFrom-Json
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
function NewJson([string]$p,$v){$stream=[IO.File]::Open($p,[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($v | ConvertTo-Json -Depth 24)+"`n");$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}}
if(Test-Path -LiteralPath "$qa/baseline_before_ACTUAL.json"){throw 'IMMUTABLE_BASELINE_ALREADY_EXISTS'}
$targets=@($routerNine.sources.PSObject.Properties.Name);if($targets.Count -ne 9){throw 'EXACT_ROUTER_NINE_REQUIRED'}
$sources=[ordered]@{};$protected=[ordered]@{};$backups=@();$saves=[ordered]@{};$external=[ordered]@{};$modules=[ordered]@{}
foreach($path in $targets){
 $f=Fact "$repo/$path";if(!$f.exists){throw "MISSING_TARGET:$path"};$sources[$path]=$f
 $target="$qa/source_before/$path";[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))|Out-Null
 $stream=[IO.File]::Open($target,[IO.FileMode]::CreateNew);try{$bytes=[IO.File]::ReadAllBytes("$repo/$path");$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
 [IO.File]::SetLastWriteTimeUtc($target,[DateTime]::new([long]$f.utc_ticks,[DateTimeKind]::Utc));$copy=Fact $target
 if($copy.sha256 -ne $f.sha256 -or $copy.bytes -ne $f.bytes -or $copy.utc_ticks -ne $f.utc_ticks){throw "COPY_RACE:$path"}
 $backups+=@{source=$path;path=$target;fact=$copy}
}
$extra=@('game/data/scenes/openworld_xiangzhou_city.tres','game/data/maps/openworld_xiangzhou_city_layout_v2.tres','game/data/scenes/openworld_qinghe_town.tres','game/data/maps/openworld_qinghe_town_layout.tres','game/data/scenes/openworld_yanmen_pass.tres','game/data/maps/openworld_yanmen_pass_layout.tres','game/data/dialogs/openworld_xiangzhou_guide.tres','game/data/dialogs/openworld_qinghe_supply.tres','game/data/dialogs/openworld_snow_medicine.tres','game/data/shops/wulin_trade_hall.tres','game/build/jinling_city_20261029_system01/river_binding_BUILD.json','game/build/bianzhou_city_20261028_lore01/ambient_dialogues.json')
foreach($path in (@($previous.sources.PSObject.Properties.Name)+$extra | Select-Object -Unique)){if(!$sources.Contains($path)){$protected[$path]=Fact "$repo/$path"}}
foreach($p in $previous.saves.PSObject.Properties){$saves[$p.Name]=Fact $p.Name};if($saves.Count -ne 171){throw 'REGISTERED_SAVE171_REQUIRED'}
foreach($p in $previous.external_run_before.PSObject.Properties){$external[$p.Name]=Fact "$repo/$($p.Name)"}
foreach($dir in @('three_settlements_20261030e_system01','three_settlements_20261030e_qinghe01','three_settlements_20261030e_yanmen01')){
 foreach($file in Get-ChildItem -LiteralPath "$repo/game/build/$dir" -File){if($file.Extension -notin @('.gd','.tscn')){continue};$path=$file.FullName.Replace('\','/').Substring($repo.Length+1);$modules[$path]=Fact $file.FullName}
}
$result=[ordered]@{status='FRESH_THREE_SETTLEMENTS_BEFORE_ROOT_FORMAL_WRITES';sources=$sources;exact_backups=$backups;protected_sources=$protected;registered_save_paths=$saves;staged_modules_record_only_until_frozen=$modules;external_parallel_sources=$external;external_policy='Inherited four explicitly record-only parallel paths; preserve and report every delta, never restore';scope='New Xiangzhou/Qinghe/Yanmen only; no old city matrix';engine_calls=0;production_writes=0;save_contents_read=$false;save_writes=0;processes_stopped=0}
NewJson "$qa/baseline_before_ACTUAL.json" $result
[ordered]@{path="$qa/baseline_before_ACTUAL.json";sha256=(Fact "$qa/baseline_before_ACTUAL.json").sha256;target_count=$sources.Count;backups=$backups.Count;protected=$protected.Count;saves=$saves.Count;staged_modules=$modules.Count;external_record_only=$external.Count}|ConvertTo-Json
