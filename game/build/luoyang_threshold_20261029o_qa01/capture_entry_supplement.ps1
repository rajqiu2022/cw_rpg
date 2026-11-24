$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/luoyang_threshold_20261029o_qa01"
$b=Get-Content "$qa/baseline_before_ACTUAL.json" -Raw | ConvertFrom-Json
$relative='game/build/luoyang_regions_20261027d_source01/region_entry.gd';$source="$repo/$relative";$expected=$b.protected_sources.$relative
$i=Get-Item -LiteralPath $source;$sha=(Get-FileHash -LiteralPath $source).Hash.ToLower()
if($sha -ne $expected.sha256 -or $i.Length -ne $expected.bytes -or [string]$i.LastWriteTimeUtc.Ticks -ne $expected.utc_ticks){throw 'ENTRY_BEFORE_NOT_BASELINE'}
$path="$qa/source_before/$relative";[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path)) | Out-Null
$stream=[IO.File]::Open($path,[IO.FileMode]::CreateNew);try{$bytes=[IO.File]::ReadAllBytes($source);$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
[IO.File]::SetLastWriteTimeUtc($path,[DateTime]::new([long]$expected.utc_ticks,[DateTimeKind]::Utc))
$result=[ordered]@{status='ONLY_ENTRY_ADDITIONAL_TARGET_BEFORE';source=$relative;path=$path;fact=$expected;baseline_sha256=(Get-FileHash -LiteralPath "$qa/baseline_before_ACTUAL.json").Hash.ToLower();engine_calls=0;production_writes=0}
$out="$qa/entry_before_SUPPLEMENT.json";$stream=[IO.File]::Open($out,[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($result | ConvertTo-Json -Depth 8)+"`n");$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
Get-FileHash -LiteralPath $out | Select-Object Path,Hash | ConvertTo-Json
