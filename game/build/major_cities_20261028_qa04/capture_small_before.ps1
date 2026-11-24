$ErrorActionPreference='Stop'
$taskRoot='F:\Code\RPG_GAME';$qaRoot=Join-Path $taskRoot 'game\build\major_cities_20261028_qa04'
$priorGuardPath=Join-Path $taskRoot 'game\build\major_cities_20261028_qa02\final_guard_visual_ROOT_ACTUAL.json'
$prior=Get-Content -LiteralPath $priorGuardPath -Raw|ConvertFrom-Json
$oldBefore=Get-Content -LiteralPath (Join-Path $taskRoot 'game\build\major_cities_20261028_qa02\baseline_before_ACTUAL.json') -Raw|ConvertFrom-Json
$goods=Get-Content -LiteralPath (Join-Path $taskRoot 'game\build\major_cities_20261028_qa02\goods_media_pre_now_ACTUAL.json') -Raw|ConvertFrom-Json
$visual=Get-Content -LiteralPath (Join-Path $taskRoot 'game\build\major_cities_20261028_qa03\protected_visual_pre_ACTUAL.json') -Raw|ConvertFrom-Json
function Fact([string]$p){if(-not [IO.File]::Exists($p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant();bytes=$i.Length;utc_ticks=$i.LastWriteTimeUtc.Ticks.ToString()}}
function WriteNew([string]$p,[byte[]]$bytes){[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($p))|Out-Null;$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$s.Write($bytes,0,$bytes.Length)}finally{$s.Dispose()}}
$output=Join-Path $qaRoot 'baseline_before_ACTUAL.json';if([IO.File]::Exists($output)){throw 'CreateNew only; preserve original baseline.'}
$mutable=@('game/build/bianzhou_city_20261028_system01/city_author.gd','game/build/bianzhou_city_20261028_system01/bianzhou_field.gd','game/build/bianzhou_city_20261028_system01/gate_binding_BUILD.json')
$sources=@($prior.sources12.PSObject.Properties|ForEach-Object{$_.Name})+@($mutable[2],'game/build/bianzhou_city_20261028_system01/router_entry.gd','game/build/luoyang_bianzhou_router_20261028_source01/Router_READY.gd')
if($sources.Count -ne 15){throw 'Expected three mutable and twelve readonly sources only.'}
$facts=[ordered]@{};$backups=@()
foreach($relative in $sources){
 $path=Join-Path $taskRoot $relative;$fact=Fact $path;if(-not $fact.exists){throw "Required current source missing: $relative"};$facts[$relative]=$fact
 if($mutable -contains $relative){$copy=Join-Path $qaRoot ('source_before\'+$relative.Replace('/','\'));WriteNew $copy ([IO.File]::ReadAllBytes($path));[IO.File]::SetLastWriteTimeUtc($copy,[DateTime]::new([long]$fact.utc_ticks,[DateTimeKind]::Utc));$copied=Fact $copy;if($copied.sha256 -ne $fact.sha256 -or $copied.bytes -ne $fact.bytes -or $copied.utc_ticks -ne $fact.utc_ticks){throw 'Exact mutable-source backup mismatch.'};$backups+=[ordered]@{source=$relative;path=$copy;fact=$copied}}
}
$mediaPaths=@()
foreach($group in @($oldBefore.related_current_art,$goods.facts,$visual.facts)){foreach($p in $group.PSObject.Properties){if($p.Name.StartsWith('game/art/') -or $p.Name.StartsWith('game/.godot/')){$mediaPaths+=$p.Name}}}
$wall='game/art/modules/luoyang_gate_fortification_v3_a_refined/luoyang_gate_wall_refined_ashlar_v3_a.png'
$mediaPaths+=@($wall,$wall+'.import')
$wallImport=[IO.File]::ReadAllText((Join-Path $taskRoot ($wall+'.import')));$match=[regex]::Match($wallImport,'(?m)^path="(res://[^\r\n"]+)"');if(-not $match.Success){throw 'Current wall import remap unavailable.'};$mediaPaths+='game/'+$match.Groups[1].Value.Substring(6)
$mediaFacts=[ordered]@{};foreach($relative in ($mediaPaths|Select-Object -Unique)){$mediaFacts[$relative]=Fact (Join-Path $taskRoot $relative)}
$saves=[ordered]@{};foreach($p in $prior.save15.PSObject.Properties){$saves[$p.Name]=Fact $p.Name};if($saves.Count -ne 15){throw 'Only the previously registered fifteen save paths are permitted.'}
foreach($relative in $sources){$after=Fact (Join-Path $taskRoot $relative);if($after.sha256 -ne $facts[$relative].sha256 -or $after.utc_ticks -ne $facts[$relative].utc_ticks){throw "Source changed during capture: $relative"}}
$processes=@(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'"|Select-Object ProcessId,Name)
$result=[ordered]@{status='BIANZHOU_EIGHT_DISTRICTS_SMALL_BEFORE_ONLY';utc=[DateTime]::UtcNow.ToString('o');prior_guard_path=$priorGuardPath;prior_guard_sha256=(Fact $priorGuardPath).sha256;sources15=$facts;mutable_targets=$mutable;exact_full_backups=$backups;save15=$saves;related_media=$mediaFacts;media_scope='Previous66 facts plus the currently bound ashlar wall PNG/import/ctex; no old alpha/import execution.';godot_processes=$processes;editor51856_present=(@($processes|Where-Object ProcessId -eq 51856).Count -eq 1);save_content_parsed=$false;canonical_writes=0;save_writes=0;media_writes=0;engine_calls=0;processes_stopped=0}
WriteNew $output ([Text.UTF8Encoding]::new($false).GetBytes(($result|ConvertTo-Json -Depth 16)+"`n"))
[ordered]@{path=$output;sha256=(Fact $output).sha256;sources=$facts.Count;mutable_backups=$backups.Count;save_paths=$saves.Count;media_facts=$mediaFacts.Count;editor51856=$result.editor51856_present}|ConvertTo-Json -Compress
