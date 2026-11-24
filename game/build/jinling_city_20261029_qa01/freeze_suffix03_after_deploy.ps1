param([Parameter(Mandatory=$true)][string]$AuthorizationJson)
$ErrorActionPreference='Stop'
$taskRoot='F:\Code\RPG_GAME';$qaRoot=Join-Path $taskRoot 'game/build/jinling_city_20261029_qa01'
function ResolveFactPath([string]$p){if($p.StartsWith('res://')){return Join-Path $taskRoot ('game/'+$p.Substring(6))};if([IO.Path]::IsPathRooted($p)){return $p};return Join-Path $taskRoot $p}
function Fact([string]$p){$p=ResolveFactPath $p;if(-not [IO.File]::Exists($p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant();bytes=$i.Length;utc_ticks=$i.LastWriteTimeUtc.Ticks.ToString()}}
function Same($a,$b){return $a.exists -eq $b.exists -and (-not $a.exists -or ($a.sha256 -ceq $b.sha256 -and $a.bytes -eq $b.bytes -and $a.utc_ticks -ceq $b.utc_ticks))}
function WriteNew([string]$p,[byte[]]$bytes){$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()}}
$fixturePath=Join-Path $qaRoot 'jinling_suffix03_READY.json';$scriptPath=Join-Path $qaRoot 'jinling_suffix03_READY.gd'
if([IO.File]::Exists($fixturePath) -or [IO.File]::Exists($scriptPath)){throw 'Preserve original suffix READY; CreateNew only.'}
$old=Get-Content -LiteralPath (Join-Path $qaRoot 'jinling_suffix02_READY.json') -Raw|ConvertFrom-Json
$baseline=Get-Content -LiteralPath (Join-Path $qaRoot 'baseline_before_ACTUAL.json') -Raw|ConvertFrom-Json
$auth=Get-Content -LiteralPath (ResolveFactPath $AuthorizationJson) -Raw|ConvertFrom-Json
$sources=[ordered]@{};$hashes=[ordered]@{}
foreach($entry in $baseline.sources.PSObject.Properties){$now=Fact $entry.Name;$permit=$auth.sources.PSObject.Properties[$entry.Name];if($null -eq $permit){if(-not (Same $now $entry.Value)){throw "Unauthorized old source changed: $($entry.Name)"}}elseif($now.sha256 -cne $permit.Value.sha256 -or $now.bytes -ne $permit.Value.bytes){throw "Authorized source not deployed: $($entry.Name)"};$sources[$entry.Name]=$now;$hashes[(ResolveFactPath $entry.Name)]=$now.sha256}
foreach($entry in $auth.sources.PSObject.Properties){if($null -eq $baseline.sources.PSObject.Properties[$entry.Name]){throw "Authorization outside bounded old scope: $($entry.Name)"}}
foreach($entry in $auth.new_modules.PSObject.Properties){$now=Fact $entry.Name;if(-not $now.exists -or $now.sha256 -cne $entry.Value.sha256 -or $now.bytes -ne $entry.Value.bytes){throw "New module not final: $($entry.Name)"};$sources[$entry.Name]=$now;$hashes[(ResolveFactPath $entry.Name)]=$now.sha256}
$baseScript='game/build/jinling_city_20261029_qa01/jinling_bounded_READY.gd';$baseFact=Fact $baseScript
if($baseFact.sha256 -cne 'd8781fe9750612ca5f3e68d9c15c8c727a8dce872f842426ee577c7f63fa52cc'){throw 'Original READY must remain unchanged.'}
$sources[$baseScript]=$baseFact;$hashes[(ResolveFactPath $baseScript)]=$baseFact.sha256
foreach($entry in $baseline.related_original_media.PSObject.Properties){if(-not (Same (Fact $entry.Name) $entry.Value)){throw "Original media changed: $($entry.Name)"}}
foreach($entry in $old.new_water_facts.PSObject.Properties){if(-not (Same (Fact $entry.Name) $entry.Value)){throw "Promoted water changed: $($entry.Name)"}}
$saves=[ordered]@{};foreach($entry in $baseline.save15.PSObject.Properties){$saves[$entry.Name]=Fact $entry.Name}
$spec=[ordered]@{};foreach($entry in $old.PSObject.Properties){$spec[$entry.Name]=$entry.Value}
$spec.whole_seconds=60;$spec.source_facts=$sources;$spec.fixed_sources=$hashes;$spec.save15=$saves
$spec.authorization_sha256=(Fact $AuthorizationJson).sha256
$spec.public_setup_foot=@(2584,1944);$spec.npc_negative_foot=@(2590,1900)
$spec.route_to_capture=@(@(2584,1980),@(1536,1980),@(1536,2300))
$spec.guide.hero_portrait='res://art/characters/protagonist_neutral.png'
$spec.bridge_pose_changed_recheck_eight_points=$false;$spec.bridge_water_guide_prefix_replayed=$false
$spec.prior_two_actual_fails_preserved=$true;$spec.old_hero_portrait_oracle_wrong=$true
WriteNew $scriptPath ([IO.File]::ReadAllBytes((Join-Path $qaRoot 'jinling_suffix03_DRAFT.gd')))
WriteNew $fixturePath ([Text.UTF8Encoding]::new($false).GetBytes(($spec|ConvertTo-Json -Depth 30)+"`n"))
[ordered]@{script=$scriptPath;script_sha256=(Fact $scriptPath).sha256;fixture=$fixturePath;fixture_sha256=(Fact $fixturePath).sha256;source_count=$sources.Count;engine_calls=0;save_writes=0}|ConvertTo-Json -Compress
