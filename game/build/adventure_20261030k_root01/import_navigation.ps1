$ErrorActionPreference='Stop'
$base='F:/Code/RPG_GAME/game'
$iso=$base+'/build/adventure_20261030k_root01/nav_import01'
$relative='data/maps/adventure_20261030k'
$dest=$iso+'/'+$relative
New-Item -ItemType Directory -Path $dest -Force | Out-Null
foreach($name in @('forest_walk.svg','mine_walk.svg','luoyang_walk.svg')) {
 if(Test-Path -LiteralPath ($base+'/'+$relative+'/'+$name+'.import')){throw 'New main import leaf already exists; inspect first'}
 Copy-Item -LiteralPath ($base+'/'+$relative+'/'+$name) -Destination ($dest+'/'+$name)
}
$stem=$base+'/build/adventure_20261030k_root01/nav_import01_ACTUAL'
if(Test-Path -LiteralPath ($stem+'_stdout.log')){throw 'Retain previous logs'}
$p=Start-Process -FilePath 'F:/文件下载/编程工具/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe' -ArgumentList @('--headless','--editor','--import','--path',$iso) -WindowStyle Hidden -RedirectStandardOutput ($stem+'_stdout.log') -RedirectStandardError ($stem+'_stderr.log') -PassThru
Write-Output ('OWN_IMPORT_PID='+$p.Id)
$p.WaitForExit()
if($p.ExitCode -ne 0){throw ('Import natural exit '+$p.ExitCode)}
$facts=@()
foreach($name in @('forest_walk.svg','mine_walk.svg','luoyang_walk.svg')) {
 $meta=$dest+'/'+$name+'.import'
 $raw=Get-Content -LiteralPath $meta -Raw
 $match=[regex]::Match($raw,'path="res://([^"\r\n]+\.ctex)"')
 if(!$match.Success){throw 'No exact compiled texture'}
 $ctex=$match.Groups[1].Value
 $leaves=@($relative+'/'+$name+'.import',$ctex,($ctex -replace '\.ctex$','.md5'))
 foreach($leaf in $leaves) {
  $source=$iso+'/'+$leaf;$target=$base+'/'+$leaf
  if(Test-Path -LiteralPath $target){throw ('Refuse overwrite '+$target)}
  Copy-Item -LiteralPath $source -Destination $target
  $facts+=@{path=$target;sha256=(Get-FileHash -LiteralPath $target).Hash;bytes=(Get-Item -LiteralPath $target).Length}
 }
}
$facts | ConvertTo-Json -Depth 5 | Out-File -LiteralPath ($stem+'_promoted.json') -Encoding utf8
Write-Output ('PROMOTED_NEW_LEAVES='+$facts.Count)
