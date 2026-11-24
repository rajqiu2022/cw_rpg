param([Parameter(Mandatory=$true)][string]$Label)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$taskDir='F:/Code/RPG_GAME/game/build/luoyang_city_revision_20261024b_root01'
$base='F:/Code/RPG_GAME/game/build/luoyang_hall_portal_fix_20261024a_root01/parent02/current_after_suffix.json'
function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
if((Sha $base) -cne '263997d29121ac8c683e8833f49746c539292c679ad0516faa4835297b2fa7b1'){throw 'FIXED_PRIOR_CHANGED'}
if($Label -notmatch '^[a-z0-9_]+$'){throw 'UNIQUE_SAFE_LABEL_REQUIRED'}
$prior=Get-Content -LiteralPath $base -Raw|ConvertFrom-Json -AsHashtable
if($prior.facts.Count -ne 2120 -or $prior.save_paths.Count -ne 15){throw 'PROTECTION_DOMAIN_CHANGED'}
$facts=@();$differences=@()
foreach($old in $prior.facts){
 $p=$old.path
 if(Test-Path -LiteralPath $p){$i=Get-Item -LiteralPath $p;$r=@{path=$p;exists=$true;sha256=(Sha $p);bytes=$i.Length;ticks=[string]$i.LastWriteTimeUtc.Ticks}}
 else{$r=@{path=$p;exists=$false;sha256=$null;bytes=$null;ticks=$null}}
 $facts+=$r
 if($r.exists -ne $old.exists -or $r.sha256 -cne $old.sha256 -or $r.bytes -ne $old.bytes -or $r.ticks -cne $old.ticks){$differences+=$r}
}
$result=@{status='FRESH_OBSERVATION_NOT_SOURCE_EXPECTATION_REBASE';prior_path=$base;prior_sha256=(Sha $base);checked=$facts.Count;facts=$facts;save_paths=$prior.save_paths;differences_from_prior=$differences;user_changes_preserved=$true}
$out=Join-Path $taskDir ($Label+'.json')
$stream=[IO.File]::Open($out,[IO.FileMode]::CreateNew)
$writer=[IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($false))
try{$writer.Write(($result|ConvertTo-Json -Depth 12)+"`n")}finally{$writer.Dispose()}
@{path=$out;sha256=(Sha $out);checked=$facts.Count;prior_changes=$differences.Count;save_changes=@($differences|Where-Object {$_.path -in $prior.save_paths}).Count}|ConvertTo-Json -Compress
