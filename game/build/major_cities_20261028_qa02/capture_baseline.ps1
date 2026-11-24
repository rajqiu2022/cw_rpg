$ErrorActionPreference='Stop'
$taskRoot='F:\Code\RPG_GAME'
$qaRoot=Join-Path $taskRoot 'game\build\major_cities_20261028_qa02'
$previousPath=Join-Path $taskRoot 'game\build\major_cities_20261028_qa01\final_guard02_ROOT_ACTUAL.json'
$previous=Get-Content -LiteralPath $previousPath -Raw | ConvertFrom-Json
function TaskFact([string]$Path){
    if(-not [IO.File]::Exists($Path)){return [ordered]@{exists=$false}}
    $item=Get-Item -LiteralPath $Path
    return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant();bytes=$item.Length;utc_ticks=$item.LastWriteTimeUtc.Ticks.ToString()}
}
function WriteTaskNew([string]$Path,[byte[]]$Bytes){
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Path))|Out-Null
    $stream=[IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try{$stream.Write($Bytes,0,$Bytes.Length)}finally{$stream.Dispose()}
}
$output=Join-Path $qaRoot 'baseline_before_ACTUAL.json'
if([IO.File]::Exists($output)){throw 'Preserve prior baseline; do not overwrite.'}
$author='game/build/bianzhou_city_20261028_system01/city_author.gd'
$field='game/build/bianzhou_city_20261028_system01/bianzhou_field.gd'
$sources=@($author,$field,'game/data/scenes/openworld_bianzhou_city.tres')+@($previous.deployed9.PSObject.Properties|ForEach-Object{$_.Name})
if($sources.Count -ne 12){throw 'Expected Author/Field/Scene and exactly nine old closure sources.'}
$sourceFacts=[ordered]@{};$backups=@()
foreach($relative in $sources){
    $path=Join-Path $taskRoot $relative;$fact=TaskFact $path
    if(-not $fact.exists){throw "Required source missing: $relative"}
    $sourceFacts[$relative]=$fact
    if($relative -eq $author -or $relative -eq $field){
        $backup=Join-Path $qaRoot ('source_before\'+$relative.Replace('/','\'))
        WriteTaskNew $backup ([IO.File]::ReadAllBytes($path))
        [IO.File]::SetLastWriteTimeUtc($backup,[DateTime]::new([long]$fact.utc_ticks,[DateTimeKind]::Utc))
        $copy=TaskFact $backup
        if($copy.sha256 -ne $fact.sha256 -or $copy.bytes -ne $fact.bytes -or $copy.utc_ticks -ne $fact.utc_ticks){throw 'Exact mutable-source backup differs.'}
        $backups+=[ordered]@{source=$relative;path=$backup;fact=$copy}
    }
}
$media=@(
    'game/art/maps/luoyang_city_rebuild_20261027d/east_shop_residence_v1_padded.png',
    'game/art/maps/luoyang_city_rebuild_20261027d/west_shop_residence_v1_padded.png',
    'game/art/modules/luoyang_market_space_20261024b/bookshop_complete_v2.png',
    'game/art/maps/luoyang_modular_v3/source/street_row_v3.png',
    'game/art/maps/luoyang_modular_v3/source/inn_v1.png',
    'game/art/maps/luoyang_modular_v3/source/shop_v1.png',
    'game/art/maps/luoyang_modular_v3/source/canal_warehouse_v3.png',
    'game/art/maps/luoyang_modular_v3/source/goods_stall_v2.png',
    'game/art/maps/luoyang_modular_v3/source/notice_pavilion_v2.png',
    'game/art/maps/luoyang_modular_v3/source/chest_common_wood_v1.png',
    'game/art/maps/luoyang_modular_v3/source/street_lamp_v2.png',
    'game/art/maps/bianzhou_southgate_20261028/main_gatehouse_v1_padded.png',
    'game/art/maps/bianzhou_southgate_20261028/checkpoint_shelter_v1_padded.png',
    'game/art/maps/bianzhou_southgate_20261028/connected_barbican_v1_padded.png',
    'game/art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png',
    'game/art/modules/luoyang_moat_v1/cobblestone_floor_08_diff_1k.jpg'
)
$mediaFacts=[ordered]@{}
foreach($relative in $media){
    $path=Join-Path $taskRoot $relative
    $mediaFacts[$relative]=TaskFact $path
    if(-not $mediaFacts[$relative].exists){throw "Required current media missing: $relative"}
    $import=$path+'.import';$mediaFacts[$relative+'.import']=TaskFact $import
    if([IO.File]::Exists($import)){
        $text=[IO.File]::ReadAllText($import)
        $match=[regex]::Match($text,'(?m)^path="(res://[^\r\n"]+)"')
        if($match.Success){
            $compiled='game/'+$match.Groups[1].Value.Substring(6)
            $mediaFacts[$compiled]=TaskFact (Join-Path $taskRoot $compiled)
        }
    }
}
$saves=[ordered]@{}
foreach($property in $previous.save15.PSObject.Properties){$saves[$property.Name]=TaskFact $property.Name}
if($saves.Count -ne 15){throw 'Exactly the previously registered save paths are required.'}
$changedDuringCapture=@()
foreach($relative in $sources){
    $after=TaskFact (Join-Path $taskRoot $relative);$before=$sourceFacts[$relative]
    if($after.sha256 -ne $before.sha256 -or $after.bytes -ne $before.bytes -or $after.utc_ticks -ne $before.utc_ticks){$changedDuringCapture+=$relative}
}
if($changedDuringCapture.Count){throw ('Source changed during capture: '+($changedDuringCapture -join ', '))}
$processes=@(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'"|Select-Object ProcessId,Name)
$result=[ordered]@{
    status='BIANZHOU_TWO_STREETS_SMALL_BEFORE_ONLY';utc=[DateTime]::UtcNow.ToString('o')
    previous_guard_path=$previousPath;previous_guard_sha256=(Get-FileHash -LiteralPath $previousPath -Algorithm SHA256).Hash.ToLowerInvariant()
    sources12=$sourceFacts;mutable_source_exact_backups=$backups;save15=$saves
    related_current_art=$mediaFacts;media_scope='Only 16 currently used city building/prop/ground originals and their declared import/compiled leaves; not all city or NPC assets.'
    godot_processes=$processes;editor51856_present=(@($processes|Where-Object ProcessId -eq 51856).Count -eq 1)
    save_content_parsed=$false;canonical_writes=0;save_writes=0;engine_runs=0;processes_stopped=0
}
WriteTaskNew $output ([Text.UTF8Encoding]::new($false).GetBytes(($result|ConvertTo-Json -Depth 14)+"`n"))
[ordered]@{path=$output;sha256=(Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash.ToLowerInvariant();sources=$sourceFacts.Count;backups=$backups.Count;registered_saves=$saves.Count;media_facts=$mediaFacts.Count;editor51856=$result.editor51856_present}|ConvertTo-Json -Compress
