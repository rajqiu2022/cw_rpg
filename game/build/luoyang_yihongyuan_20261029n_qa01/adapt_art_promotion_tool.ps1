$ErrorActionPreference='Stop'
$taskRoot='F:/Code/RPG_GAME';$qaRoot="$taskRoot/game/build/luoyang_yihongyuan_20261029n_qa01"
$oldPath="$taskRoot/game/build/luoyang_gate_lowwalls_20261029m_qa01/promote_mask_ROOT_ONLY.ps1"
if((Get-FileHash -LiteralPath $oldPath -Algorithm SHA256).Hash-cne'BBC5F826F48AFE4BD2780CE1A687181EED0302A6D4B7E4678B3930545EBE6316'){throw 'Exact prior reviewed three-leaf tool only'}
$text=[IO.File]::ReadAllText($oldPath).Replace('luoyang_gate_lowwalls_20261029m_qa01','luoyang_yihongyuan_20261029n_qa01')
$text=$text.Replace('$systemRoot="$gameRoot/build/luoyang_gate_short_walls_20261029m_system01";$isolate="$systemRoot/mask_import_ROOT"','$systemRoot=$qaRoot;$isolate="$qaRoot/art_import_ROOT"')
$lines=$text.Split("`n")
for($i=0;$i-lt$lines.Count;$i++){
 if($lines[$i].StartsWith('$png=')){$lines[$i]='$prepared=Get-Content -LiteralPath "$qaRoot/art_import_prepared_READY.json" -Raw|ConvertFrom-Json;$png=$prepared.source_png.Substring(6);$compiled=$prepared.compiled.Substring(6);$md5=$prepared.md5.Substring(6)'}
 if($lines[$i].StartsWith('$expectedPng=')){$lines[$i]='$expectedPng=$prepared.png_sha256;$rgba=$prepared.RGBA_sha256;$verifier=$prepared.verifier_sha256'}
}
$text=($lines-join"`n").Replace('mask_verify01_actual_process_receipt.json','art_verify01_actual_process_receipt.json').Replace('MASK_IMPORT_LOSSLESS_RGBA','ART_IMPORT_LOSSLESS_RGBA').Replace("size=3072x2048 old_art_changes=0","size=1441x1206 old_art_changes=0").Replace('data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/walk.png.import','art/maps/luoyang_city_rebuild_20261027d/spring_house_complete_v1_padded.png.import').Replace('57708a5974aa2e941fa3f4fb9d2368f63ae606c9ab044a9aa7ae64c0313dba15','39618fab9bd5c7007fc2eb0f8442d3bdab09ccb69e2e0d1dc352f3aeee21a284').Replace('62046F3B','published image').Replace('mask_promotion','art_promotion').Replace('NAV_IMPORT_LEAVES','ART_IMPORT_LEAVES')
$tokens=$null;$errors=$null;[System.Management.Automation.Language.Parser]::ParseInput($text,[ref]$tokens,[ref]$errors)|Out-Null;if($errors.Count){throw ($errors|Out-String)}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes($text);$out="$qaRoot/promote_art_ROOT_ONLY.ps1";$stream=[IO.File]::Open($out,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
[ordered]@{path=$out;sha256=(Get-FileHash -LiteralPath $out -Algorithm SHA256).Hash;engine_calls=0;promotions=0}|ConvertTo-Json -Compress
