param([Parameter(Mandatory=$true)][string]$AuthorizationJson,[string]$Suffix='')
$ErrorActionPreference='Stop'
$taskRoot='F:/Code/RPG_GAME';$qaRoot=Join-Path $taskRoot 'game/build/luoyang_entry_20261029l_qa01'
function ResolvePath([string]$p){if($p.StartsWith('res://')){return Join-Path $taskRoot ('game/'+$p.Substring(6))};if([IO.Path]::IsPathRooted($p)){return $p};return Join-Path $taskRoot $p}
function Fact([string]$p){$p=ResolvePath $p;if(-not [IO.File]::Exists($p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant();bytes=$i.Length;utc_ticks=$i.LastWriteTimeUtc.Ticks.ToString()}}
function Same($a,$b){return $a.exists-eq$b.exists -and (-not $a.exists -or ($a.sha256-ceq$b.sha256 -and $a.bytes-eq$b.bytes -and $a.utc_ticks-ceq$b.utc_ticks))}
function NewBytes([string]$p,[byte[]]$b){$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$s.Write($b,0,$b.Length)}finally{$s.Dispose()}}
if($Suffix -cnotmatch '^[a-z0-9_]*$'){throw 'Exact simple suffix only.'}
$baseline=Get-Content -LiteralPath (Join-Path $qaRoot 'baseline_before_ACTUAL.json') -Raw|ConvertFrom-Json
$auth=Get-Content -LiteralPath (ResolvePath $AuthorizationJson) -Raw|ConvertFrom-Json
$sourceFacts=[ordered]@{};$hashes=[ordered]@{};$saves=[ordered]@{}
foreach($entry in $baseline.sources.PSObject.Properties){$now=Fact $entry.Name;$allow=$auth.sources.PSObject.Properties[$entry.Name];if($null-eq$allow){if(-not(Same $now $entry.Value)){throw "Unauthorized source changed: $($entry.Name)"}}elseif(-not$now.exists -or $now.sha256-cne$allow.Value.sha256 -or $now.bytes-ne$allow.Value.bytes){throw "Approved successor not deployed: $($entry.Name)"};$sourceFacts[$entry.Name]=$now;$hashes[(ResolvePath $entry.Name)]=$now.sha256}
foreach($entry in $auth.sources.PSObject.Properties){if($null-eq$baseline.sources.PSObject.Properties[$entry.Name]){throw "Authorization outside captured source set: $($entry.Name)"}}
foreach($entry in $auth.new_modules.PSObject.Properties){$now=Fact $entry.Name;if(-not$now.exists -or $now.sha256-cne$entry.Value.sha256 -or $now.bytes-ne$entry.Value.bytes){throw "New immutable module differs: $($entry.Name)"};$sourceFacts[$entry.Name]=$now;$hashes[(ResolvePath $entry.Name)]=$now.sha256}
foreach($entry in $baseline.registered_save_paths.PSObject.Properties){$saves[$entry.Name]=Fact $entry.Name}
if($saves.Count-ne171){throw 'Only the existing registered 171 save paths.'}
$fixtureName='entry'+$Suffix+'_READY.json';$scriptName='entry'+$Suffix+'_READY.gd'
$fixture=[ordered]@{ready=$true;entry_seconds=30;world_setup_seconds=20;fixed_sources=$hashes;source_facts=$sourceFacts;registered_save_paths=@($saves.Keys);registered_save_facts=$saves;authorization_sha256=(Fact $AuthorizationJson).sha256;old_user_log_failure_is_preserved_not_reproduced=$true;save_writes=0}
$draft=[IO.File]::ReadAllText((Join-Path $qaRoot 'entry_DRAFT.gd')).Replace('res://build/luoyang_entry_20261029l_qa01/entry_READY.json','res://build/luoyang_entry_20261029l_qa01/'+$fixtureName)
NewBytes (Join-Path $qaRoot $scriptName) ([Text.UTF8Encoding]::new($false).GetBytes($draft))
NewBytes (Join-Path $qaRoot $fixtureName) ([Text.UTF8Encoding]::new($false).GetBytes(($fixture|ConvertTo-Json -Depth 30)+"`n"))
[ordered]@{script=(Join-Path $qaRoot $scriptName);script_sha256=(Fact (Join-Path $qaRoot $scriptName)).sha256;fixture=(Join-Path $qaRoot $fixtureName);fixture_sha256=(Fact (Join-Path $qaRoot $fixtureName)).sha256;frozen_sources=$sourceFacts.Count;registered_saves=$saves.Count;engine_calls=0}|ConvertTo-Json -Compress
