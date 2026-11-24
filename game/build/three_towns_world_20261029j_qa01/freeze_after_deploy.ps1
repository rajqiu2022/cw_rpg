param([Parameter(Mandatory=$true)][string]$AuthorizationJson,[Parameter(Mandatory=$true)][string]$LegsJson,[string]$Suffix='',[string]$OutputStem='trips',[string]$DraftName='trips_DRAFT.gd')
$ErrorActionPreference='Stop'
$taskRoot='F:/Code/RPG_GAME';$qaRoot=Join-Path $taskRoot 'game/build/three_towns_world_20261029j_qa01'
function ResolvePath([string]$p){if($p.StartsWith('res://')){return Join-Path $taskRoot ('game/'+$p.Substring(6))};if([IO.Path]::IsPathRooted($p)){return $p};return Join-Path $taskRoot $p}
function Fact([string]$p){$p=ResolvePath $p;if(-not [IO.File]::Exists($p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant();bytes=$i.Length;utc_ticks=$i.LastWriteTimeUtc.Ticks.ToString()}}
function Same($a,$b){return $a.exists -eq $b.exists -and (-not $a.exists -or ($a.sha256 -ceq $b.sha256 -and $a.bytes -eq $b.bytes -and $a.utc_ticks -ceq $b.utc_ticks))}
function NewBytes([string]$p,[byte[]]$b){$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$s.Write($b,0,$b.Length)}finally{$s.Dispose()}}
if($Suffix -cnotmatch '^[a-z0-9_]*$'){throw 'Exact simple suffix only.'}
if($OutputStem -cnotmatch '^[a-z0-9_]+$' -or $DraftName -cnotmatch '^[a-z0-9_]+_DRAFT\.gd$'){throw 'Exact local QA draft/stem only.'}
$scriptName=$OutputStem+$Suffix+'_READY.gd';$fixtureName=$OutputStem+$Suffix+'_READY.json'
$scriptPath=Join-Path $qaRoot $scriptName;$fixturePath=Join-Path $qaRoot $fixtureName
if((Test-Path -LiteralPath $scriptPath) -or (Test-Path -LiteralPath $fixturePath)){throw 'Keep prior attempts; CreateNew only.'}
$baseline=Get-Content -Raw -LiteralPath (Join-Path $qaRoot 'baseline_before_ACTUAL.json')|ConvertFrom-Json
$auth=Get-Content -Raw -LiteralPath (ResolvePath $AuthorizationJson)|ConvertFrom-Json
$plan=Get-Content -Raw -LiteralPath (ResolvePath $LegsJson)|ConvertFrom-Json
$sources=[ordered]@{};$hashes=[ordered]@{}
foreach($entry in $baseline.sources.PSObject.Properties){
 $now=Fact $entry.Name;$permit=$auth.sources.PSObject.Properties[$entry.Name]
 if($null -eq $permit){if(-not (Same $now $entry.Value)){throw "Unauthorized original source changed: $($entry.Name)"}}
 elseif(-not $now.exists -or $now.sha256 -cne $permit.Value.sha256 -or $now.bytes -ne $permit.Value.bytes){throw "Expected successor not formally deployed: $($entry.Name)"}
 $sources[$entry.Name]=$now;$hashes[(ResolvePath $entry.Name)]=$now.sha256
}
foreach($entry in $auth.sources.PSObject.Properties){if($null -eq $baseline.sources.PSObject.Properties[$entry.Name]){throw "Authorization outside registered baseline: $($entry.Name)"}}
foreach($entry in $auth.new_modules.PSObject.Properties){$now=Fact $entry.Name;if(-not $now.exists -or $now.sha256 -cne $entry.Value.sha256 -or $now.bytes -ne $entry.Value.bytes){throw "New source not frozen/deployed: $($entry.Name)"};$sources[$entry.Name]=$now;$hashes[(ResolvePath $entry.Name)]=$now.sha256}
$saves=[ordered]@{};foreach($entry in $baseline.registered_save_paths.PSObject.Properties){$saves[$entry.Name]=Fact $entry.Name}
if(@($saves.Keys).Count -ne 171 -or @($plan.legs).Count -lt 1 -or @($plan.legs).Count -gt 3){throw 'Only registered 171 saves and one-to-three new trip legs.'}
$spec=[ordered]@{ready=$true;whole_seconds=120;entry_seconds=20;world_id='world_map_jianghu';world_size=@(12288,8192);process_only_stats_sentinel=$true;overlay_script=$plan.overlay_script;portal_rows_method=$plan.portal_rows_method;legs=$plan.legs;fixed_sources=$hashes;source_facts=$sources;registered_save_paths=@($saves.Keys);registered_save_facts=$saves;authorization_sha256=(Fact $AuthorizationJson).sha256;qa_actor_or_camera_writes=0;save_writes=0}
$draft=[IO.File]::ReadAllText((Join-Path $qaRoot $DraftName))
$draft=$draft.Replace('res://build/three_towns_world_20261029j_qa01/'+$OutputStem+'_READY.json','res://build/three_towns_world_20261029j_qa01/'+$fixtureName)
NewBytes $scriptPath ([Text.UTF8Encoding]::new($false).GetBytes($draft))
NewBytes $fixturePath ([Text.UTF8Encoding]::new($false).GetBytes(($spec|ConvertTo-Json -Depth 30)+"`n"))
[ordered]@{script=$scriptPath;script_sha256=(Fact $scriptPath).sha256;fixture=$fixturePath;fixture_sha256=(Fact $fixturePath).sha256;frozen_sources=$sources.Count;registered_saves=$saves.Count;legs=@($plan.legs).Count;engine_calls=0}|ConvertTo-Json -Compress
