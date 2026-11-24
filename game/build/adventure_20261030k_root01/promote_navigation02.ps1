$ErrorActionPreference='Stop'
$base='F:/Code/RPG_GAME/game'
$iso=$base+'/build/adventure_20261030k_root01/nav_import01'
$relative='data/maps/adventure_20261030k'
$facts=@()
foreach($name in @('forest_walk.svg','mine_walk.svg','luoyang_walk.svg')) {
 $meta=$iso+'/'+$relative+'/'+$name+'.import'
 $raw=Get-Content -LiteralPath $meta -Raw
 $ctex=[regex]::Match($raw,'path="res://([^"\r\n]+\.ctex)"').Groups[1].Value
 if(!$ctex){throw 'No texture'}
 $leaves=@();$leaves+=($relative+'/'+$name+'.import');$leaves+=$ctex;$leaves+=($ctex -replace '\.ctex$','.md5')
 foreach($leaf in $leaves) {
  $source=$iso+'/'+$leaf;$target=$base+'/'+$leaf
  if(Test-Path -LiteralPath $target){throw ('Refuse overwrite '+$target)}
  Copy-Item -LiteralPath $source -Destination $target
  $facts+=@{path=$target;sha256=(Get-FileHash -LiteralPath $target).Hash;bytes=(Get-Item -LiteralPath $target).Length}
 }
}
$facts | ConvertTo-Json -Depth 5 | Out-File -LiteralPath ($base+'/build/adventure_20261030k_root01/nav_promote02_ACTUAL.json') -Encoding utf8
Write-Output ('PROMOTED_NEW_LEAVES='+$facts.Count)
