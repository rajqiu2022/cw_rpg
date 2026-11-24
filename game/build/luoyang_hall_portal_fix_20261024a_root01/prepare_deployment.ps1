$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$project='F:/Code/RPG_GAME/game';$dir=Join-Path $project 'build/luoyang_hall_portal_fix_20261024a_root01'
$receipt=Join-Path $project 'build/luoyang_hall_portal_fix_20261024a_source01/outputs/root_hall_portal_exact27_stage01/receipt.json'
function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
if((Sha $receipt) -cne 'f085977a59f3a31de20bf1910e1822ff1ad20154f75d97c4c141a3826523a235'){throw 'FIXED_ACTUAL_STAGE_REQUIRED'}
$r=Get-Content -LiteralPath $receipt -Raw|ConvertFrom-Json -AsHashtable
$back=Get-Content -LiteralPath (Join-Path $dir 'backups27.json') -Raw|ConvertFrom-Json -AsHashtable
$before=Get-Content -LiteralPath (Join-Path $dir 'before.json') -Raw|ConvertFrom-Json -AsHashtable
if($r.targets.Count -ne 27 -or $back.rows.Count -ne 27 -or $r.target_partition.patch_count -ne 13 -or $r.target_partition.copy_count -ne 14){throw 'EXACT27_PARTITION'}
$rows=@();foreach($t in $r.targets){$path=Join-Path $project $t.target.Substring(6);$candidate=Join-Path $project $t.candidate_path.Substring(6);$b=@($back.rows|Where-Object target -eq $t.target);$f=@($before.facts|Where-Object path -eq $path)
 if($b.Count -ne 1 -or $f.Count -ne 1 -or (Sha $path) -cne $t.old_sha256 -or (Sha $b[0].backup) -cne $t.old_sha256 -or (Sha $candidate) -cne $t.candidate_sha256 -or [string](Get-Item -LiteralPath $path).LastWriteTimeUtc.Ticks -cne $f[0].ticks){throw ('STALE_TARGET_OR_CANDIDATE '+$t.target)}
 $rows+=@{target=$t.target;old_sha256=$t.old_sha256;new_sha256=$t.candidate_sha256;candidate=$t.candidate_path;backup=$b[0].backup;bytes=(Get-Item -LiteralPath $candidate).Length}
}
$plan=@{status='ROOT_APPROVED_EXACT27_DEPLOYMENT';approved_by_root=$true;stage_receipt_sha256=(Sha $receipt);before_sha256=(Sha (Join-Path $dir 'before.json'));backups_sha256=(Sha (Join-Path $dir 'backups27.json'));targets=$rows;patch13_sha256=$r.patch_sha256;copy14=$r.byte_copy_plan;shared_shader_unchanged=$true;source_guards_not_disabled=$true;native_registry_author_unchanged=$true;actual_Field_ART_pending=$true;scope='Mainhall two fixed columns plus portal-only shader';non_goals=@('dock_world_exit','other_rooms','whole_city_completion','loading_performance')}
$p=Join-Path $dir 'deployment_plan.json';$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew);$w=[IO.StreamWriter]::new($s,[Text.UTF8Encoding]::new($false));try{$w.Write(($plan|ConvertTo-Json -Depth 12)+"`n")}finally{$w.Dispose()}
@{path=$p;sha256=(Sha $p);count=27}|ConvertTo-Json -Compress
