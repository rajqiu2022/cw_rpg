param(
 [string]$OutputName='final_guard_ROOT_ACTUAL.json',
 [string]$ExpectedAuthorSHA='e73afc79a79d085bf387faa59eecb6d0e80037310ca18d40edd08189421076c1',
 [string]$ExpectedFieldSHA='',
 [string]$AdditionalMediaFacts='',
 [string]$RunBeforeSaveFacts='',
 [int[]]$OwnedProcessIds=@()
)
$ErrorActionPreference='Stop';$taskRoot='F:\Code\RPG_GAME';$qaRoot=Join-Path $taskRoot 'game\build\major_cities_20261028_qa02'
$out=Join-Path $qaRoot $OutputName;if($OutputName -ne [IO.Path]::GetFileName($OutputName) -or [IO.File]::Exists($out)){throw 'CreateNew output only.'}
function Fact([string]$p){if(-not [IO.File]::Exists($p)){return [ordered]@{exists=$false}};$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant();bytes=$i.Length;utc_ticks=$i.LastWriteTimeUtc.Ticks.ToString()}}
function Same($a,$b){if([bool]$a.exists -ne [bool]$b.exists){return $false};if(-not $a.exists){return $true};return $a.sha256 -ceq $b.sha256 -and $a.bytes -eq $b.bytes -and $a.utc_ticks -ceq $b.utc_ticks}
$before=Get-Content -LiteralPath (Join-Path $qaRoot 'baseline_before_ACTUAL.json') -Raw|ConvertFrom-Json
$goods=Get-Content -LiteralPath (Join-Path $qaRoot 'goods_media_pre_now_ACTUAL.json') -Raw|ConvertFrom-Json
$fail=@();$current=[ordered]@{};$saveNow=[ordered]@{};$externalSaveChanges=@()
foreach($p in $before.sources12.PSObject.Properties){$now=Fact (Join-Path $taskRoot $p.Name);$current[$p.Name]=$now;if($p.Name -eq 'game/build/bianzhou_city_20261028_system01/city_author.gd'){if($now.sha256 -cne $ExpectedAuthorSHA){$fail+='Author differs from the exact declared successor.'}}elseif($ExpectedFieldSHA -ne '' -and $p.Name -eq 'game/build/bianzhou_city_20261028_system01/bianzhou_field.gd'){if($now.sha256 -cne $ExpectedFieldSHA){$fail+='Field differs from the exact declared successor.'}}elseif(-not(Same $now $p.Value)){$fail+=('Protected source exact facts differ: '+$p.Name)}}
foreach($copy in $before.mutable_source_exact_backups){if(-not(Same (Fact $copy.path) $copy.fact)){$fail+=('Backup differs: '+$copy.path)}}
foreach($group in @($before.related_current_art,$goods.facts)){foreach($p in $group.PSObject.Properties){if(-not(Same (Fact (Join-Path $taskRoot $p.Name)) $p.Value)){$fail+=('Media exact facts differ: '+$p.Name)}}}
$additionalCount=0
if($AdditionalMediaFacts -ne ''){$additional=Get-Content -LiteralPath $AdditionalMediaFacts -Raw|ConvertFrom-Json;foreach($p in $additional.facts.PSObject.Properties){$additionalCount++;if(-not(Same (Fact (Join-Path $taskRoot $p.Name)) $p.Value)){$fail+=('Additional explicit Entry or media exact facts differ: '+$p.Name)}}}
$saveExpected=$before.save15
if($RunBeforeSaveFacts -ne ''){$runBefore=Get-Content -LiteralPath $RunBeforeSaveFacts -Raw|ConvertFrom-Json;if(@($runBefore.save15.PSObject.Properties).Count -ne 15){throw 'Run-before save snapshot must declare the same15 paths.'};$saveExpected=$runBefore.save15}
foreach($p in $before.save15.PSObject.Properties){$now=Fact $p.Name;$saveNow[$p.Name]=$now;if(-not(Same $now $p.Value)){$externalSaveChanges+=[ordered]@{path=$p.Name;original_before=$p.Value;preserved_current=$now}};$expected=$saveExpected.PSObject.Properties[$p.Name].Value;if($null -eq $expected -or -not(Same $now $expected)){$fail+=('Save changed relative to declared run-before: '+$p.Name)}}
$processes=@(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'"|Select-Object ProcessId,Name)
if(@($processes|Where-Object ProcessId -eq 51856).Count -ne 1){$fail+='Retained editor51856 missing.'}
$ownedStill=@($processes|Where-Object{$OwnedProcessIds -contains $_.ProcessId});if($ownedStill.Count){$fail+='A declared Root-owned actual process remains running.'}
$result=[ordered]@{status=$(if($fail.Count){'FAIL'}else{'PASS'});failures=$fail;sources12=$current;authorized_successor_targets=$(if($ExpectedFieldSHA -ne ''){2}else{1});additional_entry_and_media_checked=$additionalCount;save15=$saveNow;external_save_changes_preserved=$externalSaveChanges;run_before_save_snapshot=$RunBeforeSaveFacts;backups_checked=2;old_media_checked=48;new_goods_media_checked=12;godot_processes=$processes;declared_root_owned_pids=$OwnedProcessIds;root_owned_exit_checked=($OwnedProcessIds.Count -gt 0);user_game_processes_not_stopped=$true;engine_calls=0;canonical_writes=0;save_writes=0;whole_new_actual_or_ART_pass_claim=$false;utc=[DateTime]::UtcNow.ToString('o')}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($result|ConvertTo-Json -Depth 16)+"`n");$stream=[IO.File]::Open($out,[IO.FileMode]::CreateNew);try{$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
[ordered]@{status=$result.status;path=$out;sha256=(Get-FileHash -LiteralPath $out -Algorithm SHA256).Hash.ToLowerInvariant();failures=$fail;external_save_changes_preserved=$externalSaveChanges.Count}|ConvertTo-Json -Depth 4
if($fail.Count){exit 1}
