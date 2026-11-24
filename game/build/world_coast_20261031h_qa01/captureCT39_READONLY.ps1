$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'USE_PWSH7'}
$qa='F:/Code/RPG_GAME/game/build/world_coast_20261031h_qa01';$ct='F:/Code/RPG_GAME/game/data/luoyang_culture_integration_20261019x/runtime_contract.json';$output=$qa+'/protectedCT39_supplement_ACTUAL.json';$backup=$qa+'/CT39_original_68ea5e81.source'
if((Test-Path -LiteralPath $output) -or (Test-Path -LiteralPath $backup)){throw 'PRESERVE_EXISTING_CT_SUPPLEMENT'}
function Hash-Only([string]$p){$s=[IO.File]::OpenRead($p);try{return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($s)).ToLowerInvariant()}finally{$s.Dispose()}}
function Metadata([string]$p){$i=Get-Item -LiteralPath $p;$length=[long]$i.Length;$ticks=[string]$i.LastWriteTimeUtc.Ticks;$sha=Hash-Only $p;$j=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;bytes=$length;utc_ticks=$ticks;sha256=$sha;stable_during_hash=($length -eq $j.Length -and $ticks -ceq [string]$j.LastWriteTimeUtc.Ticks)}}
function Same($a,$b){foreach($k in @('exists','bytes','utc_ticks','sha256')){if($a[$k] -cne $b[$k]){return $false}};return $true}
$basePath=$qa+'/baseline_NOW_ACTUAL.json';$suppPath=$qa+'/protected37_supplement_ACTUAL.json'
if((Hash-Only $basePath) -cne '268843b011520163f8ce34e72473826b1071e22b703d2d8bdab868c25c261ea5' -or (Hash-Only $suppPath) -cne '00e20df22fa10c8714d46f56cc101349fd5ab533dbb6ca11e08c269e2e05df48'){throw 'EXACT_PRIOR_BASELINE_PINS_REQUIRED'}
$base=[IO.File]::ReadAllText($basePath,[Text.Encoding]::UTF8)|ConvertFrom-Json -AsHashtable;$supp=[IO.File]::ReadAllText($suppPath,[Text.Encoding]::UTF8)|ConvertFrom-Json -AsHashtable
if($base.facts.ContainsKey($ct) -or $supp.facts.ContainsKey($ct)){throw 'CT_ALREADY_COVERED_USE_ORIGINAL_FACT_NOT_NEW_FREEZE'}
$first=Metadata $ct;$second=Metadata $ct
if(-not $first.stable_during_hash -or -not $second.stable_during_hash -or -not(Same $first $second) -or $first.sha256 -cne '68ea5e81652f46e1ec162e8081aa302cd113836e6c5fb6ea95cfbf6d4bb5258d' -or $first.bytes -ne 5422){throw 'EXACT_UNAPPLIED_ORIGINAL_CT_REQUIRED'}
[IO.File]::Copy($ct,$backup,$false);$copy=Metadata $backup;$after=Metadata $ct
if(-not(Same $first $after) -or $copy.sha256 -cne $first.sha256 -or $copy.bytes -ne $first.bytes){throw 'CT_BACKUP_OR_ORIGINAL_DRIFT'}
$facts=[ordered]@{};$facts[$ct]=$first;$seconds=[ordered]@{};$seconds[$ct]=$after;$backups=[ordered]@{};$backups[$ct]=[ordered]@{backup=$backup;backup_fact=$copy}
$result=[ordered]@{passed=$true;status='FRESH_ORIGINAL_CT_ONLY_NOT_IN3221_OR37';target_count=1;finished_utc=[DateTime]::UtcNow.ToString('o');first_baseline_sha256='268843b011520163f8ce34e72473826b1071e22b703d2d8bdab868c25c261ea5';prior37_supplement_sha256='00e20df22fa10c8714d46f56cc101349fd5ab533dbb6ca11e08c269e2e05df48';facts=$facts;second_facts=$seconds;new_backups=$backups;engine_runs=0;production_writes=0;save_APIs=0;whole3221_rehash=0;automatic_restore=$false}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($result|ConvertTo-Json -Depth 12)+[Environment]::NewLine);$f=[IO.File]::Open($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);try{$f.Write($bytes,0,$bytes.Length)}finally{$f.Dispose()}
[ordered]@{passed=$true;report=$output;sha256=(Hash-Only $output);original_ct=$first;source_count_added=1}|ConvertTo-Json -Depth 4
