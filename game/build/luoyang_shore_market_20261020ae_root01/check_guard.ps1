param([Parameter(Mandatory=$true)][string]$ReportPath)
$ErrorActionPreference='Stop'
$guardPath='F:/Code/RPG_GAME/game/build/luoyang_shore_market_20261020ae_root01/guard_before.json'
if(Test-Path -LiteralPath $ReportPath){throw 'PRESERVE_EXISTING_GUARD_REPORT'}
$before=Get-Content -Raw -LiteralPath $guardPath|ConvertFrom-Json -AsHashtable
$after=@();$changes=@()
foreach($entry in $before.facts){
 $path=[string]$entry.path
 if(Test-Path -LiteralPath $path){
  $item=Get-Item -LiteralPath $path
  $fact=@{path=$path;sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash;bytes=$item.Length;ticks=[string]$item.LastWriteTimeUtc.Ticks}
 }else{$fact=@{path=$path;sha256='ABSENT';bytes=0;ticks='0'}}
 $after+=,$fact
 if($fact.sha256 -ne $entry.sha256 -or $fact.bytes -ne $entry.bytes -or $fact.ticks -cne [string]$entry.ticks){
  $changes+=,@{path=$path;before=$entry;after=$fact;sha_changed=($fact.sha256 -ne $entry.sha256);bytes_changed=($fact.bytes -ne $entry.bytes);ticks_changed=($fact.ticks -cne [string]$entry.ticks)}
 }
}
$result=@{scope='EXACT_AE1782_PREEXISTING_FACTS_NO_AUTHORITY_INFERRED';before_sha256=(Get-FileHash -LiteralPath $guardPath).Hash;checked=$after.Count;changes=$changes;facts=$after}
[IO.File]::WriteAllText([IO.Path]::GetFullPath($ReportPath),($result|ConvertTo-Json -Depth 12)+"`n",[Text.UTF8Encoding]::new($false))
@{checked=$after.Count;changed_count=$changes.Count;changed_paths=@($changes|ForEach-Object{$_.path});report=$ReportPath;report_sha256=(Get-FileHash -LiteralPath $ReportPath).Hash}|ConvertTo-Json -Depth 4
