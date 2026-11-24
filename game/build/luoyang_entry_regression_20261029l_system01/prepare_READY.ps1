param()
$ErrorActionPreference='Stop'
$taskRoot='F:/Code/RPG_GAME'
$out='game/build/luoyang_entry_regression_20261029l_system01'
$resRoot='res://build/luoyang_entry_regression_20261029l_system01/'
$utf8=[Text.UTF8Encoding]::new($false,$true)
function ReadUtf8([string]$p){return $utf8.GetString([IO.File]::ReadAllBytes("$taskRoot/$p"))}
function SHA([string]$t){return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($utf8.GetBytes($t))).ToLowerInvariant()}
function Once([string]$t,[string]$b,[string]$a){if(($t.Split([string[]]@($b),[StringSplitOptions]::None).Length-1)-ne1){throw ('Nonunique hunk '+$b.Substring(0,[Math]::Min(100,$b.Length)))};return $t.Replace($b,$a)}
function Put([string]$name,[string]$t){$p="$taskRoot/$out/$name";[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($p))|Out-Null;$b=$utf8.GetBytes($t);$f=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$f.Write($b,0,$b.Length)}finally{$f.Dispose()}}
function Snapshot([string]$path){return ReadUtf8 ('game/'+$path.Substring(6))}
$prior=Get-Content -Raw -LiteralPath "$taskRoot/game/build/three_towns_world_20261029j_system01/source_closure01_READY/receipt.json"|ConvertFrom-Json -AsHashtable
foreach($row in $prior.targets){if((SHA (ReadUtf8 $row.target))-cne$row.new_sha256){throw ('Canonical baseline moved '+$row.target)}}
$rp='res://scripts/autoload/scene_router.gd'
$cp='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd'
$ep='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
$eip='res://scripts/city/luoyang_execution_index_20261022ap.gd'
$cb=ReadUtf8 ('game/'+$cp.Substring(6))
$oldGuard=''+[char]9+[char]9+'if not path.begins_with("res://") or ".." in path or String(raw.source_sha256[path]).length() != 64 or FileAccess.get_sha256(path) != raw.source_sha256[path]: return _fail("CULTURE_X_SOURCE_CHANGED:" + path)'
$guardLine1=''+[char]9+[char]9+'if not path.begins_with("res://") or ".." in path or String(raw.source_sha256[path]).length() != 64: return _fail("CULTURE_X_SOURCE_CHANGED:" + path)'
$guardLine2=''+[char]9+[char]9+'if FileAccess.get_sha256(path) != raw.source_sha256[path]:'
$guardLine3=''+[char]9+[char]9+[char]9+'if path != "res://scripts/autoload/scene_router.gd" or not AP_NPC._source_matches(path, String(raw.source_sha256[path])): return _fail("CULTURE_X_SOURCE_CHANGED:" + path)'
$newGuard=@($guardLine1,$guardLine2,$guardLine3)-join"`n"
$ca=Once $cb $oldGuard $newGuard
if((Once $ca $newGuard $oldGuard)-cne$cb){throw 'Coordinator inverse differs'}
$eb=ReadUtf8 ('game/'+$ep.Substring(6));$ex=ConvertFrom-Json -AsHashtable -InputObject $eb
$routerRow=$ex.owned[$rp]
$jOld='res://build/jinling_city_20261029_system01/source_closure01_READY/Router_READY.gd'
$tOld='res://build/three_towns_world_20261029j_system01/source_closure01_READY/Router_READY.gd'
$jNew=$resRoot+'snapshots/Router_jinling_671B99FC.gd'
$tNew=$resRoot+'snapshots/Router_three_towns_5D6AAA78.gd'
$cNew=$resRoot+'Coordinator_READY.gd'
$jText=Snapshot $jOld;$tText=Snapshot $tOld
if((SHA $jText)-cne$ex.source_sha256[$jOld]-or(SHA $tText)-cne$ex.source_sha256[$tOld]-or(SHA $tText)-cne(SHA (ReadUtf8 ('game/'+$rp.Substring(6))))){throw 'Router snapshot bytes mismatch'}
$coordRow=$ex.owned[$cp]
$cOld=($coordRow.edges|Where-Object{$_.new_sha256-ceq(SHA $cb)}|Select-Object -Last 1).new_snapshot
if((SHA (Snapshot $cOld))-cne(SHA $cb)){throw 'Coordinator immutable predecessor mismatch'}
$start=$eb.IndexOf('    "'+$cp+'": {');$end=$eb.IndexOf("`n    },",$start)+6
if($start-lt0-or$end-le$start){throw 'Coordinator EX row not bounded'}
$rowBefore=$eb.Substring($start,$end-$start)
$rowAfter=Once $rowBefore ('"current_sha256": "'+(SHA $cb)+'"') ('"current_sha256": "'+(SHA $ca)+'"')
$edge=[ordered]@{path=$cp;old_sha256=(SHA $cb);new_sha256=(SHA $ca);old_snapshot=$cOld;new_snapshot=$cNew;whole_inverse=$true;replacements=@([ordered]@{old=$oldGuard;new=$newGuard})}
$edgeText=$edge|ConvertTo-Json -Depth 8
$indented=($edgeText.Split("`n")|ForEach-Object{'        '+$_})-join"`n"
$close=$rowAfter.LastIndexOf("`n      ]");if($close-lt0){throw 'Coordinator edge list not bounded'}
$rowAfter=$rowAfter.Insert($close,","+"`n"+$indented)
$ea=Once $eb $rowBefore $rowAfter
$routerEdits=@(
 @(('"new_snapshot": "'+$jOld+'"'),('"new_snapshot": "'+$jNew+'"')),
 @(('"old_snapshot": "'+$jOld+'"'),('"old_snapshot": "'+$jNew+'"')),
 @(('"new_snapshot": "'+$tOld+'"'),('"new_snapshot": "'+$tNew+'"'))
)
foreach($edit in $routerEdits){$ea=Once $ea $edit[0] $edit[1]}
$newPins=[ordered]@{};$newPins[$jNew]=SHA $jText;$newPins[$tNew]=SHA $tText;$newPins[$cNew]=SHA $ca
function AddPins([string]$text,[string]$mapName){
 $s=$text.IndexOf('  "'+$mapName+'": {');$e=$text.IndexOf("`n  }",$s)
 if($s-lt0-or$e-le$s){throw ('Source map not bounded '+$mapName)}
 $insert='';foreach($p in $newPins.Keys){$insert+=","+"`n"+'    "'+$p+'": "'+$newPins[$p]+'"'}
 return $text.Insert($e,$insert)
}
function RemovePins([string]$text){foreach($p in $newPins.Keys){$text=Once $text (","+"`n"+'    "'+$p+'": "'+$newPins[$p]+'"') ''};return $text}
$ea=AddPins $ea 'source_sha256'
$ei=RemovePins $ea
foreach($edit in $routerEdits){$ei=Once $ei $edit[1] $edit[0]}
$ei=Once $ei $rowAfter $rowBefore
if($ei-cne$eb){throw 'EX full inverse differs'}
$exNew=ConvertFrom-Json -AsHashtable -InputObject $ea
if($exNew.owned[$cp].edges.Count-ne($coordRow.edges.Count+1)-or$exNew.owned[$rp].edges.Count-ne$routerRow.edges.Count-or$exNew.source_sha256.Count-ne($ex.source_sha256.Count+3)){throw 'EX keys/edge counts changed beyond exact successor'}
foreach($p in $ex.source_sha256.Keys){if($exNew.source_sha256[$p]-cne$ex.source_sha256[$p]){throw 'Old source key changed'}}
$eib=ReadUtf8 ('game/'+$eip.Substring(6));$eia=Once $eib (SHA $eb) (SHA $ea)
function LegacyAfter([string]$text){
 $r=Once $text ('"'+$cp+'": "'+(SHA $cb)+'"') ('"'+$cp+'": "'+(SHA $ca)+'"')
 $r=Once $r ('"'+$ep+'": "'+(SHA $eb)+'"') ('"'+$ep+'": "'+(SHA $ea)+'"')
 $r=AddPins $r 'legacy_source_sha256'
 $inv=RemovePins $r
 $inv=Once $inv ('"'+$cp+'": "'+(SHA $ca)+'"') ('"'+$cp+'": "'+(SHA $cb)+'"')
 $inv=Once $inv ('"'+$ep+'": "'+(SHA $ea)+'"') ('"'+$ep+'": "'+(SHA $eb)+'"')
 if($inv-cne$text){throw 'Legacy manifest inverse differs'}
 return $r
}
$gp='game/data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json';$gb=ReadUtf8 $gp;$ga=LegacyAfter $gb
$dp='game/data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/manifest.json';$db=ReadUtf8 $dp;$da=LegacyAfter $db
$qp='game/data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json';$qb=ReadUtf8 $qp
$qa=Once $qb ('"'+$ep+'": "'+(SHA $eb)+'"') ('"'+$ep+'": "'+(SHA $ea)+'"')
$qa=Once $qa ('"'+$eip+'": "'+(SHA $eib)+'"') ('"'+$eip+'": "'+(SHA $eia)+'"')
$qa=AddPins $qa 'source_sha256';$qi=RemovePins $qa
$qi=Once $qi ('"'+$ep+'": "'+(SHA $ea)+'"') ('"'+$ep+'": "'+(SHA $eb)+'"')
$qi=Once $qi ('"'+$eip+'": "'+(SHA $eia)+'"') ('"'+$eip+'": "'+(SHA $eib)+'"')
if($qi-cne$qb){throw 'Quarters inverse differs'}
$qip='game/scripts/city/luoyang_quarters_index_20261022ap.gd';$qib=ReadUtf8 $qip;$qia=Once $qib (SHA $qb) (SHA $qa)
$dip='game/scripts/city/luoyang_docks_workyard_index_20261019ac.gd';$dib=ReadUtf8 $dip;$dia=Once $dib (SHA $db) (SHA $da)
$bip='game/scripts/city/luoyang_precomputed_bundle_index_20261018r.gd';$bib=ReadUtf8 $bip;$bia=Once $bib (SHA $gb) (SHA $ga)
$pairs=@(
 @(('game/'+$cp.Substring(6)),'Coordinator_READY.gd',$cb,$ca),
 @(('game/'+$ep.Substring(6)),'execution_successor_READY.json',$eb,$ea),
 @(('game/'+$eip.Substring(6)),'execution_index_READY.gd',$eib,$eia),
 @($gp,'gate_bundle_manifest_READY.json',$gb,$ga),@($bip,'bundle_index_READY.gd',$bib,$bia),
 @($qp,'quarters_manifest_READY.json',$qb,$qa),@($qip,'quarters_index_READY.gd',$qib,$qia),
 @($dp,'docks_ac_manifest_READY.json',$db,$da),@($dip,'docks_ac_index_READY.gd',$dib,$dia)
)
Put 'snapshots/Router_jinling_671B99FC.gd' $jText
Put 'snapshots/Router_three_towns_5D6AAA78.gd' $tText
$rows=@()
foreach($pair in $pairs){Put $pair[1] $pair[3];$rows+=,[ordered]@{target=$pair[0];candidate="$out/$($pair[1])";old_sha256=(SHA $pair[2]);new_sha256=(SHA $pair[3]);bytes=$utf8.GetByteCount($pair[3]);whole_byte_inverse=$true}}
Put 'coordinator_hunk_READY.json' (([ordered]@{before=$oldGuard;after=$newGuard}|ConvertTo-Json -Depth 6)+"`n")
$receipt=[ordered]@{status='NINE_TARGETS_READY_NOT_DEPLOYED';targets=$rows;router_sha256=(SHA $tText);router_edge_count=$routerRow.edges.Count;coordinator_edges_before=$coordRow.edges.Count;coordinator_edges_after=$exNew.owned[$cp].edges.Count;source_keys_before=$ex.source_sha256.Count;source_keys_after=$exNew.source_sha256.Count;preserved_old_source_keys=$true;equivalent_router_snapshot_aliases=$newPins;canonical_writes=0;engine_runs=0}
Put 'receipt_READY.json' (($receipt|ConvertTo-Json -Depth 8)+"`n")
$receipt|ConvertTo-Json -Depth 8
