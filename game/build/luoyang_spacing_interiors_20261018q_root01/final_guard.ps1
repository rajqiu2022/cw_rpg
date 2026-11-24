$ErrorActionPreference='Stop'
$qBase='F:/Code/RPG_GAME/game/build/luoyang_spacing_interiors_20261018q_root01'
$qBefore=Get-Content -LiteralPath "$qBase/guard_before.json" -Raw|ConvertFrom-Json
$qAuthorized=@{
 'F:/Code/RPG_GAME/game/scripts/city/luoyang_assembled_interiors_20261016g.gd'='9468279B65EFC80D160C4C3C5DDFAA3743715B723A18133A34E8ACACEFE05DCB'
 'F:/Code/RPG_GAME/game/scripts/autoload/scene_router.gd'='15665B17FDE4AAD37A9609FC46F441DAD3893CE1B3BA3F02F530F44E916D6759'
 'F:/Code/RPG_GAME/game/scripts/city/luoyang_temple_assembly_20261016.gd'='3B59122C4186E3E8266D027ED127D697008D7040019B3FFFEA94E56D9AFB0E96'
 'F:/Code/RPG_GAME/game/scripts/city/luoyang_harbour_life_runtime_20261016.gd'='1A269BC65DF4AA70EDD59A67EE5415768BEE039EA52188939905746A99EF61AD'
 'F:/Code/RPG_GAME/game/scripts/city/luoyang_district_life_20261016f.gd'='6921FA796C419202FC9707559ADDABDB013EA0B37EC51E6303E9F4923A79FC17'
 'F:/Code/RPG_GAME/game/scripts/city/luoyang_building_spacing_20261017p.gd'='1C94F23AD8E69022712AEFFDF7EBD125D201CEDE2838E4E45D38FADBACB35B16'
}
$qFacts=@();$qChanges=@();$qUnexpected=@()
foreach($qOld in $qBefore.facts){
 $qPath=$qOld.path.Replace('\','/')
 $qExists=Test-Path -LiteralPath $qPath -PathType Leaf
 $qRow=[ordered]@{path=$qPath;exists=$qExists;bytes=0;ticks='0';sha256=''}
 if($qExists){$qFile=Get-Item -LiteralPath $qPath;$qRow.bytes=$qFile.Length;$qRow.ticks=$qFile.LastWriteTimeUtc.Ticks.ToString();$qRow.sha256=(Get-FileHash -LiteralPath $qPath -Algorithm SHA256).Hash}
 $qFacts+=[pscustomobject]$qRow
 if($qOld.exists-ne$qRow.exists -or $qOld.bytes-ne$qRow.bytes -or $qOld.ticks-ne$qRow.ticks -or $qOld.sha256-ne$qRow.sha256){
  $qApproved=$qAuthorized.ContainsKey($qPath) -and $qAuthorized[$qPath]-eq$qRow.sha256
  $qDelta=[pscustomobject]@{path=$qPath;approved=$qApproved;before=$qOld;after=$qRow}
  $qChanges+=$qDelta
  if(-not$qApproved){$qUnexpected+=$qDelta}
 }
}
$qResult=[ordered]@{scope='Original fresh815 only; NEW helper/imports/bindings tested separately';count=$qFacts.Count;changes=$qChanges;unexpected=$qUnexpected;save_count=@($qFacts|Where-Object {$_.path-like'*/app_userdata/*/save_*'}).Count;save_changes=@($qChanges|Where-Object {$_.path-like'*/app_userdata/*/save_*'}).Count;facts=$qFacts;godot_processes=@(Get-Process -Name '*Godot*' -ErrorAction SilentlyContinue|Select-Object Id,ProcessName)}
$qTarget="$qBase/final_guard.json"
if(Test-Path -LiteralPath $qTarget){throw 'Guard output already exists'}
[IO.File]::WriteAllText($qTarget,($qResult|ConvertTo-Json -Depth 12),[Text.UTF8Encoding]::new($false))
[pscustomobject]@{count=$qFacts.Count;changes=$qChanges.Count;unexpected=$qUnexpected.Count;save_changes=$qResult.save_changes;processes=$qResult.godot_processes.Count}
if($qUnexpected.Count-ne0){$qUnexpected|Select-Object path;exit 1}
