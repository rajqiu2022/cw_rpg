param([Parameter(Mandatory=$true)][string]$FixturePath,[Parameter(Mandatory=$true)][string]$OutputPath)
$ErrorActionPreference='Stop'
$repo='F:/Code/RPG_GAME';$qa="$repo/game/build/linxi_adult_scale_20261030h_qa01"
$fixture=[IO.Path]::GetFullPath($FixturePath).Replace('\','/');$out=[IO.Path]::GetFullPath($OutputPath).Replace('\','/')
if($fixture -cne "$qa/STATIC_NORMAL_PREVIEW_ROOT_ONLY.json" -or !$out.StartsWith("$qa/static_normal_preview/",[StringComparison]::OrdinalIgnoreCase)){throw 'EXACT_QA_FIXTURE_AND_NEW_RESULT_SCOPE_REQUIRED'}
$spec=Get-Content -LiteralPath $fixture -Raw|ConvertFrom-Json
if(!$spec.ready -or @($spec.registered_save_paths).Count -ne 171){throw 'ROOT_READY_AND_EXACT171_REGISTERED_PATHS_REQUIRED'}
function Fact([string]$p){if(!(Test-Path -LiteralPath $p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p).Hash.ToLower();bytes=$i.Length;utc_ticks=[string]$i.LastWriteTimeUtc.Ticks}}
function Absolute([string]$p){if($p.StartsWith('res://')){return "$repo/game/"+$p.Substring(6)};if($p.StartsWith('game/')){return "$repo/$p"};throw "SOURCE_OUTSIDE_PROJECT:$p"}
$sources=[ordered]@{};foreach($p in $spec.fixed_sources.PSObject.Properties){$sources[$p.Name]=Fact (Absolute $p.Name)}
$saves=[ordered]@{};$again=[ordered]@{};$changed=@()
foreach($p in $spec.registered_save_paths){$saves[$p]=Fact $p}
foreach($p in $spec.registered_save_paths){$again[$p]=Fact $p;if(($saves[$p]|ConvertTo-Json -Compress)-cne($again[$p]|ConvertTo-Json -Compress)){$changed+=$p}}
$result=[ordered]@{sources=$sources;saves=$saves;save_double_read_second=$again;save_double_read_changes=$changed;save_stable=($changed.Count -eq 0);save_contents_deserialized=$false;save_writes=0;process_controls=0}
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($out))|Out-Null
$stream=[IO.File]::Open($out,[IO.FileMode]::CreateNew);try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($result|ConvertTo-Json -Depth 20)+"`n");$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
if($changed.Count -gt 0){throw 'LIVE_SAVE_CHANGED_RECORDED_NO_ROLLBACK'}
