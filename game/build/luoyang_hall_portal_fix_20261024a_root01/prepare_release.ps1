$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$project='F:/Code/RPG_GAME/game'
$taskDir=Join-Path $project 'build/luoyang_hall_portal_fix_20261024a_root01'
$beforePath=Join-Path $taskDir 'before.json'
$scopePath=Join-Path $project 'build/luoyang_hall_portal_fix_20261024a_source01/exact27_scope_PROPOSAL_NOT_APPROVED.json'
function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function WriteNew([string]$name,$data){$p=Join-Path $taskDir $name;$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew);$w=[IO.StreamWriter]::new($s,[Text.UTF8Encoding]::new($false));try{$w.Write(($data|ConvertTo-Json -Depth 14)+"`n")}finally{$w.Dispose()};@{path=$p;sha256=(Sha $p)}|ConvertTo-Json -Compress}
if((Sha $beforePath) -cne 'f6cb23158284cb6d510ec002d8c9e14062a54b3df609207a8f5fe26de4172f16' -or (Sha $scopePath) -cne '0e9e78169feca9dd5385fa3c7e0898cc0815f3d47acf1c22ea1d9904fdb3cc7a'){throw 'FROZEN_SCOPE_OR_FRESH_GUARD_CHANGED'}
$active=@(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'"|Where-Object ProcessId -ne 51856);if($active.Count -ne 0){throw 'USER_GAME_OR_OTHER_ENGINE_ACTIVE'}
$b=Get-Content -LiteralPath $beforePath -Raw|ConvertFrom-Json -AsHashtable
$scope=Get-Content -LiteralPath $scopePath -Raw|ConvertFrom-Json -AsHashtable
$backupDir=Join-Path $taskDir 'backups27';if(Test-Path -LiteralPath $backupDir){throw 'PRESERVE_OLD_BACKUPS'};[void](New-Item -ItemType Directory -Path $backupDir)
$facts=@();$rows=@();$ordinal=0
foreach($r in $scope.targets){
 $p=Join-Path $project $r.target.Substring(6);$i=Get-Item -LiteralPath $p;$h=Sha $p
 $prior=@($b.facts|Where-Object path -eq $p);if($prior.Count -ne 1 -or $h -cne $r.old_sha256 -or $i.Length -ne $prior[0].bytes -or [string]$i.LastWriteTimeUtc.Ticks -cne $prior[0].ticks){throw ('SCOPE_BEFORE_DRIFT '+$r.target)}
 $ordinal++;$copy=Join-Path $backupDir ('{0:D2}_{1}' -f $ordinal,[IO.Path]::GetFileName($p));Copy-Item -LiteralPath $p -Destination $copy
 if((Sha $copy) -cne $h -or (Get-Item -LiteralPath $copy).Length -ne $i.Length){throw 'BACKUP_BYTES_MISMATCH'}
 $facts+=@{target=$r.target;path=$p;sha256=$h;bytes=$i.Length;ticks=[string]$i.LastWriteTimeUtc.Ticks}
 $rows+=@{target=$r.target;sha256=$h;bytes=$i.Length;backup=$copy}
}
if($rows.Count -ne 27){throw 'EXACT27_REQUIRED'}
WriteNew 'scope_before27.json' @{status='ROOT_FRESH27_FROM_ACTUAL2120_BEFORE';full_guard_path=$beforePath;full_guard_sha256=(Sha $beforePath);scope_sha256=(Sha $scopePath);target_count=27;facts=$facts;only_editor51856_alive=$true}
WriteNew 'backups27.json' @{status='ROOT_EXACT27_FULL_BYTE_BACKUPS';count=27;rows=$rows}
WriteNew 'stage_preparation_approval.json' @{approved_by_root=$true;scope='Only fixed mainhall columns and portal-only shader; exact27 existing sources';scope_sha256=(Sha $scopePath);full_guard_sha256=(Sha $beforePath);geometry_actual='res://build/luoyang_city_full_rollout_20261022ap_qa01/hall_column_portal_tint_execution_READY/geometry_output_READY/79080_1761/result.json';geometry_checks=234;geometry_failures=0;shader_actual='res://build/luoyang_city_full_rollout_20261022ap_qa01/hall_column_portal_tint_execution_READY/portal_isolate/output_READY/78028_983/result.json';shader_checks=70;shader_failures=0;formal_deployment_approved=$false;Field_ART_pending=$true;no_native_registry_save_or_shared_shader_change=$true}
