param()
$ErrorActionPreference='Stop'
$taskRoot='F:/Code/RPG_GAME'
$prior='game/build/bianzhou_city_20261028_system01/source_closure03_READY'
$out='game/build/bianzhou_city_20261028_system01/source_closure04_READY'
if(Test-Path -LiteralPath "$taskRoot/$out"){throw 'Immutable output exists.'}
$utf8=[Text.UTF8Encoding]::new($false,$true)
function ReadUtf8([string]$p){return $utf8.GetString([IO.File]::ReadAllBytes("$taskRoot/$p"))}
function SHA([string]$t){return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($utf8.GetBytes($t))).ToLowerInvariant()}
function Put([string]$name,[string]$text){$p="$taskRoot/$out/$name";[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($p))|Out-Null;$b=$utf8.GetBytes($text);$f=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$f.Write($b,0,$b.Length)}finally{$f.Dispose()}}
$r=Get-Content -Raw -LiteralPath "$taskRoot/$prior/receipt.json"|ConvertFrom-Json -AsHashtable
$qBefore=ReadUtf8 "$prior/quarters_manifest_READY.json"
$snapshotRow='    "res://build/luoyang_bianzhou_router_20261028_source01/Router_READY.gd": "6c15489751490ef96c030f5d8655c7bf8355d51ceb5293cf9000cbf5817613fc"'
$start=$qBefore.IndexOf('  "source_sha256": {');$end=$qBefore.IndexOf("`n  }",$start)
if($start-lt0-or$end-le$start){throw 'Quarters source header object not bounded.'}
$insertion=",`n"+$snapshotRow
$qAfter=$qBefore.Insert($end,$insertion)
if($qAfter.Replace($insertion,'')-cne$qBefore){throw 'New snapshot whole byte inverse failed.'}
$qiBefore=ReadUtf8 "$prior/quarters_index_READY.gd"
$oldQSHA=SHA $qBefore;$newQSHA=SHA $qAfter
if(($qiBefore.Split([string[]]@($oldQSHA),[StringSplitOptions]::None).Length-1)-ne1){throw 'Quarters pointer not unique.'}
$qiAfter=$qiBefore.Replace($oldQSHA,$newQSHA)
foreach($row in $r.targets){
    if((SHA (ReadUtf8 $row.target))-ne$row.old_sha256){throw ('Canonical baseline moved: '+$row.target)}
    $name=[IO.Path]::GetFileName([string]$row.candidate)
    $text=if($name-eq'quarters_manifest_READY.json'){$qAfter}elseif($name-eq'quarters_index_READY.gd'){$qiAfter}else{ReadUtf8 $row.candidate}
    Put $name $text
    $row.candidate="$out/$name";$row.new_sha256=SHA $text;$row.bytes=$utf8.GetByteCount($text)
}
$r.status='NINE_EXECUTED_TARGETS_FULL_SOURCE_LEASE_READY_NOT_DEPLOYED'
$r.quarters_only_EX_and_EXindex_keys=$false
$r.quarters_delta='Two EX/EXindex hash keys plus the same one immutable Router snapshot that EX.source_paths actually consumes; all old source entries preserved.'
$r.rejected_preparation_drafts=@('source_closure01_READY','source_closure02_READY','source_closure03_READY')
Put 'receipt.json' (($r|ConvertTo-Json -Depth 8)+"`n")
$r|ConvertTo-Json -Depth 8
