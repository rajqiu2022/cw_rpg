param()
$ErrorActionPreference='Stop'
$taskRoot='F:/Code/RPG_GAME'
$prior='game/build/bianzhou_city_20261028_system01/source_closure02_READY'
$outRel='game/build/bianzhou_city_20261028_system01/source_closure03_READY'
$outDir="$taskRoot/$outRel"
if(Test-Path -LiteralPath $outDir){throw 'Immutable outputs already exist.'}
$utf8=[Text.UTF8Encoding]::new($false,$true)
function ReadUtf8([string]$p){return $utf8.GetString([IO.File]::ReadAllBytes("$taskRoot/$p"))}
function SHA([string]$t){return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($utf8.GetBytes($t))).ToLowerInvariant()}
function Once([string]$t,[string]$b,[string]$a){if(($t.Split([string[]]@($b),[StringSplitOptions]::None).Length-1)-ne1){throw ('Nonunique key: '+$b)};return $t.Replace($b,$a)}
function Put([string]$name,[string]$content){$path="$outDir/$name";[IO.Directory]::CreateDirectory($outDir)|Out-Null;$f=[IO.File]::Open($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$b=$utf8.GetBytes($content);$f.Write($b,0,$b.Length)}finally{$f.Dispose()}}
$router='res://scripts/autoload/scene_router.gd'
$ex='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
$ei='res://scripts/city/luoyang_execution_index_20261022ap.gd'
$snapshot='res://build/luoyang_bianzhou_router_20261028_source01/Router_READY.gd'
$rb=ReadUtf8 'game/scripts/autoload/scene_router.gd';$ra=ReadUtf8 "$prior/Router_READY.gd"
$eb=ReadUtf8 'game/data/maps/luoyang_full_city_20261022ap/execution_successor.json';$ea=ReadUtf8 "$prior/execution_successor_READY.json"
$eib=ReadUtf8 'game/scripts/city/luoyang_execution_index_20261022ap.gd';$eia=ReadUtf8 "$prior/execution_index_READY.gd"
$replacements=@([ordered]@{path=$router;before=(SHA $rb);after=(SHA $ra)},[ordered]@{path=$ex;before=(SHA $eb);after=(SHA $ea)})
$snapshotRow='    "'+$snapshot+'": "'+(SHA $ra)+'"'
function LegacyAfter([string]$text){
    $result=$text
    foreach($r in $replacements){$result=Once $result ('"'+$r.path+'": "'+$r.before+'"') ('"'+$r.path+'": "'+$r.after+'"')}
    $start=$result.IndexOf('  "legacy_source_sha256": {');$end=$result.IndexOf("`n  }",$start)
    if($start-lt0-or$end-le$start){throw 'Legacy complete source map not bounded.'}
    return $result.Insert($end,",`n"+$snapshotRow)
}
$gatePath='game/data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json'
$gb=ReadUtf8 $gatePath;$ga=LegacyAfter $gb
$dockPath='game/data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/manifest.json'
$db=ReadUtf8 $dockPath;$da=LegacyAfter $db
$qPath='game/data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json'
$qb=ReadUtf8 $qPath;$qa=$qb
foreach($r in @([ordered]@{path=$ex;before=(SHA $eb);after=(SHA $ea)},[ordered]@{path=$ei;before=(SHA $eib);after=(SHA $eia)})){$qa=Once $qa ('"'+$r.path+'": "'+$r.before+'"') ('"'+$r.path+'": "'+$r.after+'"')}
$qiPath='game/scripts/city/luoyang_quarters_index_20261022ap.gd';$qib=ReadUtf8 $qiPath;$qia=Once $qib (SHA $qb) (SHA $qa)
$diPath='game/scripts/city/luoyang_docks_workyard_index_20261019ac.gd';$dib=ReadUtf8 $diPath;$dia=Once $dib (SHA $db) (SHA $da)
$biPath='game/scripts/city/luoyang_precomputed_bundle_index_20261018r.gd';$bib=ReadUtf8 $biPath;$bia=Once $bib (SHA $gb) (SHA $ga)
foreach($pair in @(@($gb,$ga),@($db,$da))){
    $inverse=Once $pair[1] (",`n"+$snapshotRow) ''
    foreach($r in $replacements){$inverse=Once $inverse ('"'+$r.path+'": "'+$r.after+'"') ('"'+$r.path+'": "'+$r.before+'"')}
    if($inverse-cne$pair[0]){throw 'Whole legacy manifest bytes inverse failed.'}
    $a=ConvertFrom-Json -AsHashtable -InputObject $pair[1];$b=ConvertFrom-Json -AsHashtable -InputObject $pair[0]
    if($a.legacy_source_sha256.Count-ne($b.legacy_source_sha256.Count+1)){throw 'Snapshot exact source count differs.'}
}
$qInverse=Once (Once $qa ('"'+$ex+'": "'+(SHA $ea)+'"') ('"'+$ex+'": "'+(SHA $eb)+'"')) ('"'+$ei+'": "'+(SHA $eia)+'"') ('"'+$ei+'": "'+(SHA $eib)+'"')
if($qInverse-cne$qb){throw 'Quarter full bytes inverse failed.'}
$pairs=@(
@('game/scripts/autoload/scene_router.gd','Router_READY.gd',$rb,$ra),
@('game/data/maps/luoyang_full_city_20261022ap/execution_successor.json','execution_successor_READY.json',$eb,$ea),
@('game/scripts/city/luoyang_execution_index_20261022ap.gd','execution_index_READY.gd',$eib,$eia),
@($gatePath,'gate_bundle_manifest_READY.json',$gb,$ga),
@($biPath,'bundle_index_READY.gd',$bib,$bia),
@($qPath,'quarters_manifest_READY.json',$qb,$qa),
@($qiPath,'quarters_index_READY.gd',$qib,$qia),
@($dockPath,'docks_ac_manifest_READY.json',$db,$da),
@($diPath,'docks_ac_index_READY.gd',$dib,$dia)
)
$rows=@()
foreach($pair in $pairs){Put $pair[1] $pair[3];$rows+=,[ordered]@{target=$pair[0];candidate="$outRel/$($pair[1])";old_sha256=(SHA $pair[2]);new_sha256=(SHA $pair[3]);bytes=$utf8.GetByteCount($pair[3]);whole_byte_inverse=$true}}
$receipt=[ordered]@{status='NINE_EXECUTED_TARGETS_BYTE_EXACT_READY_NOT_DEPLOYED';targets=$rows;root_approved_targets=9;router_CRLF_before=([regex]::Matches($rb,"`r`n")).Count;router_CRLF_after=([regex]::Matches($ra,"`r`n")).Count;new_snapshot=$snapshot;new_snapshot_sha256=(SHA $ra);gate_and_docks_add_exact_source_snapshot=$true;quarters_only_EX_and_EXindex_keys=$true;no_Region_bin_or_dead_Civic_B_changes=$true;canonical_writes=0;engine_runs=0;rejected_preparation_drafts=@('source_closure01_READY','source_closure02_READY')}
Put 'receipt.json' (($receipt|ConvertTo-Json -Depth 8)+"`n")
$receipt|ConvertTo-Json -Depth 8
