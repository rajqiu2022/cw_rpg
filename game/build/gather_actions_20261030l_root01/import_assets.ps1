$ErrorActionPreference='Stop'
$base='F:/Code/RPG_GAME/game'
$dir=$base+'/build/gather_actions_20261030l_root01'
$iso=$dir+'/import_isolated'
$sources=@('art/sprites/life_skills_20261030l/gather_herb_right_4f_padded.png','art/sprites/life_skills_20261030l/mine_ore_right_4f_padded.png','art/audio/life_skills_20261030l/herb_rustle_pluck.wav','art/audio/life_skills_20261030l/pickaxe_stone_hit.wav')
foreach($relative in $sources) {
 $folder=Split-Path -Parent ($iso+'/'+$relative)
 New-Item -ItemType Directory -Path $folder -Force | Out-Null
 Copy-Item -LiteralPath ($base+'/'+$relative) -Destination ($iso+'/'+$relative)
}
$stem=$dir+'/asset_import01_ACTUAL'
if(Test-Path -LiteralPath ($stem+'_stdout.log')){throw 'Preserve existing run'}
$p=Start-Process -FilePath 'F:/文件下载/编程工具/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe' -ArgumentList @('--headless','--editor','--import','--path',$iso) -WindowStyle Hidden -RedirectStandardOutput ($stem+'_stdout.log') -RedirectStandardError ($stem+'_stderr.log') -PassThru
Write-Output ('OWN_IMPORT_PID='+$p.Id);$p.WaitForExit()
if($p.ExitCode -ne 0){throw ('Import failed '+$p.ExitCode)}
$facts=@()
foreach($relative in $sources) {
 $meta=$relative+'.import'
 $raw=Get-Content -LiteralPath ($iso+'/'+$meta) -Raw
 $compiled=[regex]::Match($raw,'path="res://([^"\r\n]+\.(?:ctex|sample))"').Groups[1].Value
 if(!$compiled){throw 'Exact imported resource missing'}
 $leaves=@($meta,$compiled,($compiled -replace '\.(?:ctex|sample)$','.md5'))
 foreach($leaf in $leaves) {
  $source=$iso+'/'+$leaf;$target=$base+'/'+$leaf
  if(Test-Path -LiteralPath $target) {
   if((Get-FileHash -LiteralPath $source).Hash -cne (Get-FileHash -LiteralPath $target).Hash){throw ('Existing leaf differs '+$target)}
  } else {Copy-Item -LiteralPath $source -Destination $target}
  $facts+=@{path=$target;sha256=(Get-FileHash -LiteralPath $target).Hash;bytes=(Get-Item -LiteralPath $target).Length}
 }
}
@{natural_import_exit=0;sources=$sources;facts=$facts;full_project_import=$false} | ConvertTo-Json -Depth 5 | Out-File -LiteralPath ($dir+'/asset_promote01_ACTUAL.json') -Encoding utf8
Write-Output ('EXACT_IMPORT_LEAVES='+$facts.Count)
