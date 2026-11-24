param([Parameter(Mandatory=$true)][string]$OutputName,[string]$ClosurePath='')
$ErrorActionPreference='Stop'
$root='F:/Code/RPG_GAME/game/build/luoyang_culture_integration_20261019x_root01'
$prior=Get-Content -Raw -LiteralPath "$root/guard_before.json" | ConvertFrom-Json
$allowed=@(
 'F:/Code/RPG_GAME/game/scripts/field/field_walkable_controller.gd',
 'F:/Code/RPG_GAME/game/scripts/city/luoyang_temple_assembly_20261016.gd',
 'F:/Code/RPG_GAME/game/scripts/city/luoyang_precomputed_bundle_index_20261018r.gd'
)
foreach($id in @('ch4_s0_luoyang_gate','ch4_s1_luoyang_yamen','ch4_s2_canal_docks','ch4_s3_luoyang_market')) {
 $allowed+="F:/Code/RPG_GAME/game/data/maps/luoyang_layout_bundle_20261018t_retry2/$id/manifest.json"
}
$facts=@();$changed=@();$unexpected=@();$saveChanges=@()
foreach($old in $prior.facts){
 $path=([string]$old.path).Replace('\','/')
 if(Test-Path -LiteralPath $path){
  $item=Get-Item -LiteralPath $path
  $now=[ordered]@{path=$path;sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash;ticks=[string]$item.LastWriteTimeUtc.Ticks;bytes=$item.Length}
 }else{$now=[ordered]@{path=$path;sha256='';ticks='0';bytes=0}}
 $facts+=$now
 if($old.sha256 -cne $now.sha256 -or [string]$old.ticks -cne $now.ticks -or [long]$old.bytes -ne $now.bytes){
  $delta=[ordered]@{path=$path;before=$old;after=$now}
  $changed+=$delta
  if($path -notin $allowed){$unexpected+=$delta}
  if($path -like '*/app_userdata/*/save_*'){$saveChanges+=$delta}
 }
}
$closureBad=@();$closureCount=0
if($ClosurePath){
 $closure=Get-Content -Raw -LiteralPath $ClosurePath | ConvertFrom-Json -AsHashtable
 foreach($path in $closure.source_sha256.Keys){
  $closureCount++
  if(-not $path.StartsWith('res://') -or $path.Contains('..')){throw "Unsafe frozen leaf $path"}
  $actual=(Get-FileHash -LiteralPath ('F:/Code/RPG_GAME/game/'+$path.Substring(6)) -Algorithm SHA256).Hash
  if($actual.ToLowerInvariant() -cne $closure.source_sha256[$path].ToLowerInvariant()){$closureBad+=$path}
 }
}
$result=[ordered]@{scope='EXACT_923_OLD_PATHS_AND_15_SAVES_NO_RESTORE';count=$facts.Count;allowed_old_change_paths=$allowed;changes=$changed;unexpected=$unexpected;save_changes=$saveChanges;closure_count=$closureCount;closure_bad=$closureBad;facts=$facts}
$out="$root/$OutputName"
if(Test-Path -LiteralPath $out){throw "Preserve existing evidence $out"}
[System.IO.File]::WriteAllText($out,(ConvertTo-Json -InputObject $result -Depth 100)+"`n",[System.Text.UTF8Encoding]::new($false))
Write-Output (ConvertTo-Json -Compress -InputObject ([ordered]@{count=$facts.Count;changed=$changed.Count;unexpected=$unexpected.Count;save_changes=$saveChanges.Count;closure_count=$closureCount;closure_bad=$closureBad.Count;output=$out}))
if($unexpected.Count -or $saveChanges.Count -or $closureBad.Count){exit 1}
