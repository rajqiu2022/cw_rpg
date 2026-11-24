param([Parameter(Mandatory=$true)][ValidateSet('before','after')][string]$Phase,[string]$Plan='')
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$project='F:/Code/RPG_GAME/game'
$taskDir=Join-Path $project 'build/luoyang_hall_portal_fix_20261024a_root01'
$prior=Join-Path $project 'build/luoyang_city_full_rollout_20261022ap_root01/integration66/final_guard.json'
$scope=Join-Path $project 'build/luoyang_hall_portal_fix_20261024a_source01/exact27_scope_PROPOSAL_NOT_APPROVED.json'
function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function Abs([string]$p){if(!$p.StartsWith('res://') -or $p.Contains('..')){throw 'EXACT_RES_PATH_REQUIRED'};Join-Path $project $p.Substring(6)}
if((Sha $prior) -cne 'a2321bcbb93b885f3f33aa98bf2663af853e0c056ebdf90dc34156e01a5d39e7'){throw 'PRIOR_GUARD_CHANGED'}
if((Sha $scope) -cne '0e9e78169feca9dd5385fa3c7e0898cc0815f3d47acf1c22ea1d9904fdb3cc7a'){throw 'FIXED_SCOPE_CHANGED'}
$old=Get-Content -LiteralPath $prior -Raw|ConvertFrom-Json -AsHashtable
$spec=Get-Content -LiteralPath $scope -Raw|ConvertFrom-Json -AsHashtable
if($spec.targets.Count -ne 27 -or $old.facts.Count -ne 2119 -or $old.save_paths.Count -ne 15){throw 'EXPECTED_PROTECTION_DOMAIN_REQUIRED'}
$paths=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($r in $old.facts){[void]$paths.Add($r.path)}
foreach($r in $spec.targets){[void]$paths.Add((Abs $r.target))}
$facts=@();foreach($p in ($paths|Sort-Object)){if(Test-Path -LiteralPath $p){$i=Get-Item -LiteralPath $p;$facts+=@{path=$p;exists=$true;sha256=(Sha $p);bytes=$i.Length;ticks=[string]$i.LastWriteTimeUtc.Ticks}}else{$facts+=@{path=$p;exists=$false;sha256=$null;bytes=$null;ticks=$null}}}
$result=@{phase=$Phase;prior_path=$prior;prior_sha256=(Sha $prior);scope_sha256=(Sha $scope);checked=$facts.Count;facts=$facts;save_paths=$old.save_paths;save_count=15;source_expectations_not_rebased=$true}
if($Phase -eq 'before'){
 foreach($r in $spec.targets){if((Sha (Abs $r.target)) -cne $r.old_sha256){throw ('PROTECTED_SCOPE_OLD_MISMATCH '+$r.target)}}
 $result.status='FRESH_EXACT_FACTS_BEFORE_ISOLATED_CHECKS_AND_DEPLOYMENT'
}else{
 $beforePath=Join-Path $taskDir 'before.json';$b=Get-Content -LiteralPath $beforePath -Raw|ConvertFrom-Json -AsHashtable
 $allowed=@{};if($Plan -ne ''){$planData=Get-Content -LiteralPath $Plan -Raw|ConvertFrom-Json -AsHashtable;foreach($r in $planData.targets){$allowed[(Abs $r.target)]=$r}}
 $changes=@();$unexpected=@();$saves=@();$map=@{};foreach($r in $b.facts){$map[$r.path]=$r}
 foreach($r in $facts){$prev=$map[$r.path];if(!$prev){throw 'DOMAIN_CHANGED'};if($r.exists -ne $prev.exists -or $r.sha256 -cne $prev.sha256 -or $r.bytes -ne $prev.bytes -or $r.ticks -cne $prev.ticks){$changes+=$r;if($r.path -in $b.save_paths){$saves+=$r};if(!$allowed.ContainsKey($r.path) -or $r.sha256 -cne $allowed[$r.path].new_sha256){$unexpected+=$r}}}
 $result.before_sha256=Sha $beforePath;$result.change_count=$changes.Count;$result.save_changes=$saves;$result.unexpected_changes=$unexpected;$result.passed=($unexpected.Count -eq 0 -and $saves.Count -eq 0);$result.status='EXACT_FACTS_AFTER_REQUESTED_SCOPE'
 if(!$result.passed){throw ('GUARD_FAILED '+($unexpected|ConvertTo-Json -Compress))}
}
$out=Join-Path $taskDir ($Phase+'.json');$stream=[IO.File]::Open($out,[IO.FileMode]::CreateNew);$writer=[IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($false));try{$writer.Write(($result|ConvertTo-Json -Depth 12)+"`n")}finally{$writer.Dispose()}
@{path=$out;sha256=(Sha $out);checked=$facts.Count;save_count=15}|ConvertTo-Json -Compress
