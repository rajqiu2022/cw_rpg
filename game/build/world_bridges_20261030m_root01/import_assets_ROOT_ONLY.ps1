$ErrorActionPreference='Stop'
$base='F:/Code/RPG_GAME/game'
$dir=$base+'/build/world_bridges_20261030m_root01'
$iso=$dir+'/import_isolated'
$sources=@(0..4 | ForEach-Object {'art/modules/world_bridges_20261030m/bridge_{0:00}.png' -f $_})
$before=@()
foreach($relative in $sources) {
 $folder=Split-Path -Parent ($iso+'/'+$relative)
 New-Item -ItemType Directory -Path $folder -Force | Out-Null
 Copy-Item -LiteralPath ($base+'/'+$relative) -Destination ($iso+'/'+$relative)
 $before+=@{path=$relative;sha256=(Get-FileHash -LiteralPath ($base+'/'+$relative)).Hash}
}
$stem=$dir+'/asset_import01_ACTUAL'
if(Test-Path -LiteralPath ($stem+'_stdout.log')){throw 'Preserve existing run'}
$other=@(Get-CimInstance Win32_Process | Where-Object {$_.Name -like '*Godot*' -and $_.ProcessId -ne 51856})
if($other.Count){throw 'Other Godot processes present; do not control user processes'}
$p=Start-Process -FilePath 'F:/文件下载/编程工具/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe' -ArgumentList @('--headless','--editor','--import','--path',$iso) -WindowStyle Hidden -RedirectStandardOutput ($stem+'_stdout.log') -RedirectStandardError ($stem+'_stderr.log') -PassThru
Write-Output ('OWN_IMPORT_PID='+$p.Id)
$p.WaitForExit()
if($p.ExitCode -ne 0){throw ('Import failed '+$p.ExitCode)}
$facts=@()
foreach($row in $before) {
 $relative=$row.path
 if((Get-FileHash -LiteralPath ($base+'/'+$relative)).Hash -cne $row.sha256){throw 'PNG changed during import'}
 $meta=$relative+'.import'
 $raw=Get-Content -LiteralPath ($iso+'/'+$meta) -Raw
 $compiled=[regex]::Match($raw,'path="res://([^"\r\n]+\.ctex)"').Groups[1].Value
 if(!$compiled){throw 'Exact imported resource missing'}
 foreach($leaf in @($meta,$compiled,($compiled -replace '\.ctex$','.md5'))) {
  $source=$iso+'/'+$leaf
  $target=$base+'/'+$leaf
  if(Test-Path -LiteralPath $target) {
   if((Get-FileHash -LiteralPath $source).Hash -cne (Get-FileHash -LiteralPath $target).Hash){throw ('Existing leaf differs '+$target)}
  } else {Copy-Item -LiteralPath $source -Destination $target}
  $facts+=@{path=$target;sha256=(Get-FileHash -LiteralPath $target).Hash;bytes=(Get-Item -LiteralPath $target).Length}
 }
}
@{natural_import_exit=0;source_facts=$before;facts=$facts;full_project_import=$false} | ConvertTo-Json -Depth 5 | Out-File -LiteralPath ($dir+'/asset_promote01_ACTUAL.json') -Encoding utf8
Write-Output ('EXACT_IMPORT_LEAVES='+$facts.Count)
