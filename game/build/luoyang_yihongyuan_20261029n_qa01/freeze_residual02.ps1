$ErrorActionPreference='Stop'
$qa='F:/Code/RPG_GAME/game/build/luoyang_yihongyuan_20261029n_qa01'
function Fact([string]$p){$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
function NewJson([string]$p,$v){$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew);try{$u=[Text.UTF8Encoding]::new($false);$z=$u.GetBytes(($v | ConvertTo-Json -Depth 30)+"`n");$s.Write($z,0,$z.Length)}finally{$s.Dispose()}}
$fixture=Get-Content "$qa/trip_READY.json" -Raw | ConvertFrom-Json
$fixture | Add-Member inherited_actual 'trip01:two outside key legs + three full-body checks passed before QA API abort; no result, whole FAIL retained'
NewJson "$qa/trip02_READY.json" $fixture
$bytes=[IO.File]::ReadAllBytes("$qa/trip_DRAFT.gd");$s=[IO.File]::Open("$qa/trip02_READY.gd",[IO.FileMode]::CreateNew);try{$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()}
$f=Get-Content "$qa/trip_freeze_ROOT_ACTUAL.json" -Raw | ConvertFrom-Json
$f.script=Fact "$qa/trip02_READY.gd";$f.fixture=Fact "$qa/trip02_READY.json";$f.status='FROZEN_RESIDUAL02_ONLY; source baseline inherited unchanged; independent90s watchdog'
NewJson "$qa/trip02_freeze_ROOT_ACTUAL.json" $f
Get-FileHash -LiteralPath "$qa/trip02_READY.gd","$qa/trip02_READY.json","$qa/trip02_freeze_ROOT_ACTUAL.json" | Select-Object Path,Hash | ConvertTo-Json
