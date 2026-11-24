$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$game='F:/Code/RPG_GAME/game'
$isolate='F:/Code/RPG_GAME/assets/staging/luoyang_market_walk_20261024b_import'
$report="$isolate/single_market_walk_import_result_28080.json"
$out="$game/build/luoyang_city_revision_20261024b_root01/walk_two_leaf_actual.json"
function Hash([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
if((Hash $report) -cne 'c714eb6553a89f7b952e32c040700775d9fac3119605c52ce9b166537ceac100'){throw 'REPORT_CHANGED'}
$r=Get-Content -Raw -LiteralPath $report|ConvertFrom-Json
if(!$r.passed -or $r.checks -ne 74 -or $r.rows.Count -ne 1){throw 'NOT_ADMITTED'}
$row=$r.rows[0]
$leaves=@(@{res=$row.compiled;sha=$row.compiled_sha256},@{res=$row.sidecar;sha=$row.sidecar_sha256})
if(Test-Path -LiteralPath $out){throw 'PRESERVE_RECEIPT'}
foreach($leaf in $leaves){$src=Join-Path $isolate $leaf.res.Substring(6);$dst=Join-Path $game $leaf.res.Substring(6);if((Hash $src) -cne $leaf.sha -or (Test-Path -LiteralPath $dst)){throw 'SOURCE_CHANGED_OR_TARGET_PRESENT'}}
foreach($leaf in $leaves){$src=Join-Path $isolate $leaf.res.Substring(6);$dst=Join-Path $game $leaf.res.Substring(6);[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($dst))|Out-Null;Copy-Item -LiteralPath $src -Destination $dst;if((Hash $dst) -cne $leaf.sha){throw 'COPY_MISMATCH'}}
$actual=@{scope='EXACT_TWO_NEW_WALK_IMPORT_LEAVES_ONLY';png_rewritten=$false;report=$report;report_sha256=(Hash $report);leaves=$leaves;full_RGBA=$row.decoded_RGBA_sha256;runtime_binding_enabled=$false}
[IO.File]::WriteAllText($out,($actual|ConvertTo-Json -Depth 6)+"`n",[Text.UTF8Encoding]::new($false))
@{path=$out;sha256=(Hash $out);count=2}|ConvertTo-Json
