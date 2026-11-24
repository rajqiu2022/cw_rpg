$ErrorActionPreference='Stop'
$taskRoot='F:/Code/RPG_GAME';$qaRoot=Join-Path $taskRoot 'game/build/luoyang_gate_lowwalls_20261029m_qa01'
function Fact([string]$p){$i=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant();bytes=$i.Length;utc_ticks=$i.LastWriteTimeUtc.Ticks.ToString()}}
function NewBytes([string]$p,[byte[]]$b){[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($p))|Out-Null;$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$s.Write($b,0,$b.Length)}finally{$s.Dispose()}}
$before=Get-Content -LiteralPath "$qaRoot/baseline_before_ACTUAL.json" -Raw|ConvertFrom-Json
$scopePath="$taskRoot/game/build/luoyang_city_finish_20261025i_source01/seven_fields_layout_repair01/current_DFCF_exact31_scope_PREPARATION.json"
$scope=Get-Content -LiteralPath $scopePath -Raw|ConvertFrom-Json
if($scope.count-ne31 -or @($scope.targets).Count-ne31){throw 'Only the existing exact31 target registry.'}
$sources=[ordered]@{};$backups=@()
foreach($entry in $scope.targets){$relative='game/'+$entry.target.Substring(6);if($null-ne$before.sources.PSObject.Properties[$relative]){continue};$p=Join-Path $taskRoot $relative;$f=Fact $p;$sources[$relative]=$f;$copy=Join-Path $qaRoot ('source_before/'+$relative);NewBytes $copy ([IO.File]::ReadAllBytes($p));[IO.File]::SetLastWriteTimeUtc($copy,[DateTime]::new([long]$f.utc_ticks,[DateTimeKind]::Utc));$copied=Fact $copy;if($copied.sha256-cne$f.sha256-or$copied.bytes-ne$f.bytes-or$copied.utc_ticks-cne$f.utc_ticks){throw 'Supplement backup differs'};$backups+=@{source=$relative;path=$copy;fact=$copied}}
$output=Join-Path $qaRoot 'baseline_supplement01_ACTUAL.json';$result=[ordered]@{status='ONLY_MISSING_CURRENT_TARGETS_FROM_EXISTING_EXACT31';utc=[DateTime]::UtcNow.ToString('o');sources=$sources;exact_backups=$backups;registry_sha256=(Fact $scopePath).sha256;initial_baseline_sha256=(Fact "$qaRoot/baseline_before_ACTUAL.json").sha256;production_writes=0;engine_calls=0}
NewBytes $output ([Text.UTF8Encoding]::new($false).GetBytes(($result|ConvertTo-Json -Depth 20)+"`n"))
[ordered]@{path=$output;sha256=(Fact $output).sha256;additional_current_sources=$sources.Count;additional_exact_backups=$backups.Count;engine_calls=0}|ConvertTo-Json -Compress
