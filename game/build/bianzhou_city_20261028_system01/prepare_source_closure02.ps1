param()
$ErrorActionPreference='Stop'
$taskRoot='F:/Code/RPG_GAME'
$taskDir="$taskRoot/game/build/bianzhou_city_20261028_system01/source_closure02_READY"
if(Test-Path -LiteralPath $taskDir){throw 'Immutable output exists.'}
$utf8=[Text.UTF8Encoding]::new($false,$true)
function ReadUtf8([string]$p){return $utf8.GetString([IO.File]::ReadAllBytes("$taskRoot/$p"))}
function SHA([byte[]]$b){return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($b)).ToLowerInvariant()}
function PutArtifact([string]$p,[byte[]]$b){[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($p))|Out-Null;$f=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$f.Write($b,0,$b.Length)}finally{$f.Dispose()}}
function ReplaceOne([string]$text,[string]$before,[string]$after){if(($text.Split([string[]]@($before),[StringSplitOptions]::None).Length-1)-ne 1){throw 'Replacement not unique.'};return $text.Replace($before,$after)}
$routerTarget='game/scripts/autoload/scene_router.gd'
$exTarget='game/data/maps/luoyang_full_city_20261022ap/execution_successor.json'
$eiTarget='game/scripts/city/luoyang_execution_index_20261022ap.gd'
$gateTarget='game/data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json'
$biTarget='game/scripts/city/luoyang_precomputed_bundle_index_20261018r.gd'
$p='res://scripts/autoload/scene_router.gd'
$snapshot='res://build/luoyang_bianzhou_router_20261028_source01/Router_READY.gd'
$originalSnapshot='res://build/luoyang_regions_20261027d_source01/visual_finish04_BUILD/closure27/Router_READY.gd'
$h=(Get-Content -Raw -LiteralPath "$taskRoot/game/build/bianzhou_city_20261028_system01/router_hunks_CANDIDATE.json"|ConvertFrom-Json).hunks[0]
$rb=ReadUtf8 $routerTarget;$ra=ReplaceOne $rb $h.before $h.after
$oldRouterSHA=SHA $utf8.GetBytes($rb);$newRouterSHA=SHA $utf8.GetBytes($ra)
if($oldRouterSHA-ne'd25da6fe7f5dd4ec47a7d6821163acc8c51862c40207facd3e7fa6ebe2d586bc'){throw 'Router moved.'}
if((SHA ([IO.File]::ReadAllBytes("$taskRoot/game/"+$snapshot.Substring(6))))-ne$newRouterSHA){throw 'Independent immutable snapshot differs.'}
$eb=ReadUtf8 $exTarget;$oldExSHA=SHA $utf8.GetBytes($eb)
$ex=ConvertFrom-Json -AsHashtable -InputObject $eb
$start=$eb.IndexOf(('    "'+$p+'": {'))
$end=$eb.IndexOf("`n    },",$start)+6
if($start-lt0-or$end-le$start){throw 'Router owned row not bounded.'}
$rowBefore=$eb.Substring($start,$end-$start)
$rowAfter=ReplaceOne $rowBefore ('"current_sha256": "'+$oldRouterSHA+'"') ('"current_sha256": "'+$newRouterSHA+'"')
$edge=[ordered]@{path=$p;old_sha256=$oldRouterSHA;new_sha256=$newRouterSHA;old_snapshot=$originalSnapshot;new_snapshot=$snapshot;whole_inverse=$true;replacements=@([ordered]@{old=$h.before;new=$h.after})}
$edgeText=($edge|ConvertTo-Json -Depth 10)
$indented=($edgeText.Split("`n")|ForEach-Object{'        '+$_})-join"`n"
$close=$rowAfter.LastIndexOf("`n      ]")
if($close-lt0){throw 'Router edge close not bounded.'}
$rowAfter=$rowAfter.Insert($close,",`n"+$indented)
$pinsStart=$eb.IndexOf('  "source_sha256": {')
$pinsEnd=$eb.IndexOf("`n  }",$pinsStart)+4
if($pinsStart-lt0-or$pinsEnd-le$pinsStart){throw 'EX pins object not bounded.'}
$pinsBefore=$eb.Substring($pinsStart,$pinsEnd-$pinsStart)
$pinsAfter=$pinsBefore.Insert($pinsBefore.LastIndexOf("`n  }"),(",`n    `""+$snapshot+'": "'+$newRouterSHA+'"'))
$ea=ReplaceOne (ReplaceOne $eb $rowBefore $rowAfter) $pinsBefore $pinsAfter
if((ReplaceOne (ReplaceOne $ea $rowAfter $rowBefore) $pinsAfter $pinsBefore)-cne$eb){throw 'EX byte inverse failed.'}
$exNew=ConvertFrom-Json -AsHashtable -InputObject $ea
if($exNew.owned[$p].edges.Count-ne($ex.owned[$p].edges.Count+1)-or$exNew.source_sha256.Count-ne($ex.source_sha256.Count+1)){throw 'EX delta shape invalid.'}
$exSHA=SHA $utf8.GetBytes($ea)
$eib=ReadUtf8 $eiTarget;$eia=ReplaceOne $eib $oldExSHA $exSHA
$gb=ReadUtf8 $gateTarget
$gRouterBefore='"'+$p+'": "'+$oldRouterSHA+'"';$gRouterAfter='"'+$p+'": "'+$newRouterSHA+'"'
$gExBefore='"res://data/maps/luoyang_full_city_20261022ap/execution_successor.json": "'+$oldExSHA+'"'
$gExAfter='"res://data/maps/luoyang_full_city_20261022ap/execution_successor.json": "'+$exSHA+'"'
$ga=ReplaceOne (ReplaceOne $gb $gRouterBefore $gRouterAfter) $gExBefore $gExAfter
if((ReplaceOne (ReplaceOne $ga $gRouterAfter $gRouterBefore) $gExAfter $gExBefore)-cne$gb){throw 'Gate complete byte inverse failed.'}
$oldGateSHA=SHA $utf8.GetBytes($gb);$gateSHA=SHA $utf8.GetBytes($ga)
$bib=ReadUtf8 $biTarget;$bia=ReplaceOne $bib $oldGateSHA $gateSHA
$pairs=@(@($routerTarget,'Router_READY.gd',$rb,$ra),@($exTarget,'execution_successor_READY.json',$eb,$ea),@($eiTarget,'execution_index_READY.gd',$eib,$eia),@($gateTarget,'gate_bundle_manifest_READY.json',$gb,$ga),@($biTarget,'bundle_index_READY.gd',$bib,$bia))
$rows=@()
foreach($pair in $pairs){$b=$utf8.GetBytes([string]$pair[3]);PutArtifact "$taskDir/$($pair[1])" $b;$rows+=,[ordered]@{target=$pair[0];candidate="game/build/bianzhou_city_20261028_system01/source_closure02_READY/$($pair[1])";old_sha256=(SHA $utf8.GetBytes([string]$pair[2]));new_sha256=(SHA $b);bytes=$b.Length;byte_inverse=$true}}
$r=[ordered]@{status='FIVE_TARGET_BYTE_EXACT_READY_NOT_DEPLOYED';targets=$rows;router_crlf_before=([regex]::Matches($rb,"`r`n")).Count;router_crlf_after=([regex]::Matches($ra,"`r`n")).Count;router_single_final_lf=($ra.EndsWith("`n")-and-not$ra.EndsWith("`n`n"));old_router_edges=$ex.owned[$p].edges.Count;new_router_edges=$exNew.owned[$p].edges.Count;immutable_new_snapshot=$snapshot;old_owned_and_source_entries_preserved=$true;gate_delta_keys=@($p,'res://data/maps/luoyang_full_city_20261022ap/execution_successor.json');canonical_writes=0;engine_runs=0;previous_formatting_draft_not_for_adoption='source_closure01_READY'}
PutArtifact "$taskDir/receipt.json" $utf8.GetBytes(($r|ConvertTo-Json -Depth 8)+"`n")
$r|ConvertTo-Json -Depth 8
