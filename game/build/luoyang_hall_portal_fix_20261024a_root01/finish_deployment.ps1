$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$project='F:/Code/RPG_GAME/game';$dir=Join-Path $project 'build/luoyang_hall_portal_fix_20261024a_root01'
function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
$planPath=Join-Path $dir 'deployment_plan.json';if((Sha $planPath) -cne '36202a1e43905bd92d4b569706ace30092a222c5624d6ed40c9008dc23d9e0d4'){throw 'APPROVED_PLAN_CHANGED'}
$plan=Get-Content -LiteralPath $planPath -Raw|ConvertFrom-Json -AsHashtable
foreach($r in $plan.targets){$p=Join-Path $project $r.target.Substring(6);$want=if($r.target.EndsWith('.gd')){$r.new_sha256}else{$r.old_sha256};if((Sha $p) -cne $want){throw ('EXACT_PATCH13_OR_JSON14_PARENT_REQUIRED '+$r.target)};if((Sha (Join-Path $project $r.candidate.Substring(6))) -cne $r.new_sha256){throw 'CANDIDATE_CHANGED'}}
$copied=0;foreach($r in $plan.targets){if(!$r.target.EndsWith('.json')){continue};$p=Join-Path $project $r.target.Substring(6);$c=Join-Path $project $r.candidate.Substring(6);Copy-Item -LiteralPath $c -Destination $p;$copied++}
$facts=@();foreach($r in $plan.targets){$p=Join-Path $project $r.target.Substring(6);if((Sha $p) -cne $r.new_sha256 -or (Get-Item -LiteralPath $p).Length -ne $r.bytes){throw ('FORMAL_EXACT_CANDIDATE_REQUIRED '+$r.target)};$facts+=@{target=$r.target;sha256=(Sha $p);bytes=$r.bytes}}
if($copied -ne 14 -or $facts.Count -ne 27){throw 'EXACT27_REQUIRED'}
$data=@{status='EXACT27_FORMAL_DEPLOYED_FIELD_ART_PENDING';plan_sha256=(Sha $planPath);patch_method='apply_patch';patched_GD=13;mechanical_JSON_copies=14;targets=$facts;no_native_author_registry_media_save_write=$true;no_whole_city_or_performance_credit=$true}
$out=Join-Path $dir 'deployment_actual.json';$s=[IO.File]::Open($out,[IO.FileMode]::CreateNew);$w=[IO.StreamWriter]::new($s,[Text.UTF8Encoding]::new($false));try{$w.Write(($data|ConvertTo-Json -Depth 8)+"`n")}finally{$w.Dispose()}
@{path=$out;sha256=(Sha $out);count=27}|ConvertTo-Json -Compress
