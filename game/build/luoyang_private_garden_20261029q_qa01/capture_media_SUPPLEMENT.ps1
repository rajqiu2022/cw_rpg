$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/luoyang_private_garden_20261029q_qa01"
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
function Same($x,$y){return $x.exists -eq $y.exists -and $x.sha256 -eq $y.sha256 -and $x.bytes -eq $y.bytes -and $x.utc_ticks -eq $y.utc_ticks}
$receipt=Get-Content "$qa/art_promotion_ROOT_ACTUAL.json" -Raw | ConvertFrom-Json
$png='game/art/modules/luoyang_estate_garden_20261029q/lotus_pond_v1.png';$facts=[ordered]@{}
$facts[$png]=Fact "$repo/$png"
if($facts[$png].sha256 -ne '96c1e18804c0032a836ac1dce1af934e5a3349cf83d4dd3b159845da2347838b'){throw 'PUBLISHED_PNG_CHANGED'}
foreach($leaf in $receipt.promoted){$f=Fact $leaf.path;if(!(Same $f $leaf.fact)){throw "PROMOTED_LEAF_CHANGED:$($leaf.path)"};$facts[$leaf.path.Substring($repo.Length+1)]=$f}
if($facts.Count -ne 4){throw 'EXACT_ONE_PNG_THREE_LEAVES'}
$result=[ordered]@{status='EXACT_FINAL_POND_FOUR_MEDIA_FACTS';facts=$facts;promotion_receipt=(Fact "$qa/art_promotion_ROOT_ACTUAL.json");verify_receipt=(Fact "$qa/art_verify01_actual_process_receipt.json");verified_RGBA='5a3312ca62e75a01a563bab75540f25a59c5a123feda7aced4f78df99a2f93e1';size=@(1792,1280);max_alpha=254;repeated_engine_calls=0;media_writes=0;production_writes=0}
$path="$qa/media_after_import_SUPPLEMENT.json";$s=[IO.File]::Open($path,[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($result | ConvertTo-Json -Depth 15)+"`n");$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()}
[ordered]@{path=$path;sha256=(Fact $path).sha256;media_facts=$facts.Count} | ConvertTo-Json
