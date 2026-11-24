param()
$ErrorActionPreference='Stop'
$taskRoot='F:/Code/RPG_GAME'
$out='game/build/jinling_city_20261029_system01/source_closure01_READY'
if(Test-Path -LiteralPath "$taskRoot/$out"){throw 'Immutable outputs already exist.'}
$utf8=[Text.UTF8Encoding]::new($false,$true)
function ReadUtf8([string]$p){return $utf8.GetString([IO.File]::ReadAllBytes("$taskRoot/$p"))}
function SHA([string]$t){return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($utf8.GetBytes($t))).ToLowerInvariant()}
function Once([string]$t,[string]$b,[string]$a){if(($t.Split([string[]]@($b),[StringSplitOptions]::None).Length-1)-ne1){throw ('Nonunique source hunk '+$b.Substring(0,[Math]::Min(80,$b.Length)))};return $t.Replace($b,$a)}
# Bulk mechanical succession: immutable candidates only. Never write canonical targets.
function Put([string]$name,[string]$t){$p="$taskRoot/$out/$name";[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($p))|Out-Null;$b=$utf8.GetBytes($t);$f=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$f.Write($b,0,$b.Length)}finally{$f.Dispose()}}
$prior=Get-Content -Raw -LiteralPath "$taskRoot/game/build/bianzhou_city_20261028_system01/source_closure04_READY/receipt.json"|ConvertFrom-Json -AsHashtable
foreach($row in $prior.targets){if((SHA (ReadUtf8 $row.target))-cne$row.new_sha256){throw ('Canonical baseline moved '+$row.target)}}
$rp='res://scripts/autoload/scene_router.gd'
$ep='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
$eip='res://scripts/city/luoyang_execution_index_20261022ap.gd'
$oldSnapshot='res://build/luoyang_bianzhou_router_20261028_source01/Router_READY.gd'
$newSnapshot='res://build/jinling_city_20261029_system01/source_closure01_READY/Router_READY.gd'
$h=Get-Content -Raw -LiteralPath "$taskRoot/game/build/jinling_city_20261029_system01/router_hunk_FINAL.json"|ConvertFrom-Json
$rb=ReadUtf8 'game/scripts/autoload/scene_router.gd';$ra=Once $rb $h.before $h.after
if((Once $ra $h.after $h.before)-cne$rb){throw 'Router whole inverse differs.'}
if((SHA (ReadUtf8 ('game/'+$oldSnapshot.Substring(6))))-cne(SHA $rb)){throw 'Old immutable Router snapshot differs.'}
$eb=ReadUtf8 'game/data/maps/luoyang_full_city_20261022ap/execution_successor.json'
$ex=ConvertFrom-Json -AsHashtable -InputObject $eb
$start=$eb.IndexOf('    "'+$rp+'": {');$end=$eb.IndexOf("`n    },",$start)+6
if($start-lt0-or$end-le$start){throw 'EX owned Router row not bounded.'}
$rowBefore=$eb.Substring($start,$end-$start)
$rowAfter=Once $rowBefore ('"current_sha256": "'+(SHA $rb)+'"') ('"current_sha256": "'+(SHA $ra)+'"')
$edge=[ordered]@{path=$rp;old_sha256=(SHA $rb);new_sha256=(SHA $ra);old_snapshot=$oldSnapshot;new_snapshot=$newSnapshot;whole_inverse=$true;replacements=@([ordered]@{old=$h.before;new=$h.after})}
$edgeText=$edge|ConvertTo-Json -Depth 10
$indented=($edgeText.Split("`n")|ForEach-Object{'        '+$_})-join"`n"
$close=$rowAfter.LastIndexOf("`n      ]");if($close-lt0){throw 'EX edge closure not bounded.'}
$rowAfter=$rowAfter.Insert($close,","+"`n"+$indented)
$ea=Once $eb $rowBefore $rowAfter
function AddSnapshot([string]$text,[string]$mapName){
 $s=$text.IndexOf('  "'+$mapName+'": {');$e=$text.IndexOf("`n  }",$s)
 if($s-lt0-or$e-le$s){throw ('Full map not bounded '+$mapName)}
 return $text.Insert($e,","+"`n"+'    "'+$newSnapshot+'": "'+(SHA $ra)+'"')
}
$ea=AddSnapshot $ea 'source_sha256'
$snapshotInsert=","+"`n"+'    "'+$newSnapshot+'": "'+(SHA $ra)+'"'
$exInverse=Once (Once $ea $snapshotInsert '') $rowAfter $rowBefore
if($exInverse-cne$eb){throw 'EX whole inverse differs.'}
$exNew=ConvertFrom-Json -AsHashtable -InputObject $ea
if($exNew.owned[$rp].edges.Count-ne($ex.owned[$rp].edges.Count+1)-or$exNew.source_sha256.Count-ne($ex.source_sha256.Count+1)){throw 'EX old edges/source keyset not preserved.'}
$eib=ReadUtf8 'game/scripts/city/luoyang_execution_index_20261022ap.gd';$eia=Once $eib (SHA $eb) (SHA $ea)
function LegacyAfter([string]$text){
 $r=Once $text ('"'+$rp+'": "'+(SHA $rb)+'"') ('"'+$rp+'": "'+(SHA $ra)+'"')
 $r=Once $r ('"'+$ep+'": "'+(SHA $eb)+'"') ('"'+$ep+'": "'+(SHA $ea)+'"')
 $r=AddSnapshot $r 'legacy_source_sha256'
 $inv=Once $r $snapshotInsert ''
 $inv=Once $inv ('"'+$rp+'": "'+(SHA $ra)+'"') ('"'+$rp+'": "'+(SHA $rb)+'"')
 $inv=Once $inv ('"'+$ep+'": "'+(SHA $ea)+'"') ('"'+$ep+'": "'+(SHA $eb)+'"')
 if($inv-cne$text){throw 'Legacy manifest whole inverse differs.'}
 return $r
}
$gp='game/data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json'
$gb=ReadUtf8 $gp;$ga=LegacyAfter $gb
$dp='game/data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/manifest.json'
$db=ReadUtf8 $dp;$da=LegacyAfter $db
$qp='game/data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json'
$qb=ReadUtf8 $qp
$qa=Once $qb ('"'+$ep+'": "'+(SHA $eb)+'"') ('"'+$ep+'": "'+(SHA $ea)+'"')
$qa=Once $qa ('"'+$eip+'": "'+(SHA $eib)+'"') ('"'+$eip+'": "'+(SHA $eia)+'"')
$qa=AddSnapshot $qa 'source_sha256'
$qi=Once $qa $snapshotInsert ''
$qi=Once $qi ('"'+$ep+'": "'+(SHA $ea)+'"') ('"'+$ep+'": "'+(SHA $eb)+'"')
$qi=Once $qi ('"'+$eip+'": "'+(SHA $eia)+'"') ('"'+$eip+'": "'+(SHA $eib)+'"')
if($qi-cne$qb){throw 'Quarters whole inverse differs.'}
$qip='game/scripts/city/luoyang_quarters_index_20261022ap.gd';$qib=ReadUtf8 $qip;$qia=Once $qib (SHA $qb) (SHA $qa)
$dip='game/scripts/city/luoyang_docks_workyard_index_20261019ac.gd';$dib=ReadUtf8 $dip;$dia=Once $dib (SHA $db) (SHA $da)
$bip='game/scripts/city/luoyang_precomputed_bundle_index_20261018r.gd';$bib=ReadUtf8 $bip;$bia=Once $bib (SHA $gb) (SHA $ga)
$pairs=@(
 @('game/scripts/autoload/scene_router.gd','Router_READY.gd',$rb,$ra),
 @('game/data/maps/luoyang_full_city_20261022ap/execution_successor.json','execution_successor_READY.json',$eb,$ea),
 @('game/scripts/city/luoyang_execution_index_20261022ap.gd','execution_index_READY.gd',$eib,$eia),
 @($gp,'gate_bundle_manifest_READY.json',$gb,$ga),@($bip,'bundle_index_READY.gd',$bib,$bia),
 @($qp,'quarters_manifest_READY.json',$qb,$qa),@($qip,'quarters_index_READY.gd',$qib,$qia),
 @($dp,'docks_ac_manifest_READY.json',$db,$da),@($dip,'docks_ac_index_READY.gd',$dib,$dia)
)
$rows=@()
foreach($pair in $pairs){Put $pair[1] $pair[3];$rows+=,[ordered]@{target=$pair[0];candidate="$out/$($pair[1])";old_sha256=(SHA $pair[2]);new_sha256=(SHA $pair[3]);bytes=$utf8.GetByteCount($pair[3]);whole_byte_inverse=$true}}
$r=[ordered]@{status='NINE_EXECUTED_TARGETS_READY_NOT_DEPLOYED';targets=$rows;new_snapshot=$newSnapshot;new_snapshot_sha256=(SHA $ra);old_router_edges=$ex.owned[$rp].edges.Count;new_router_edges=$exNew.owned[$rp].edges.Count;old_source_keys=$ex.source_sha256.Count;new_source_keys=$exNew.source_sha256.Count;router_CRLF_before=([regex]::Matches($rb,"`r`n")).Count;router_CRLF_after=([regex]::Matches($ra,"`r`n")).Count;gate_docks_quarters_preserve_old_keys=$true;canonical_writes=0;engine_runs=0}
Put 'receipt.json' (($r|ConvertTo-Json -Depth 8)+"`n")
$r|ConvertTo-Json -Depth 8
