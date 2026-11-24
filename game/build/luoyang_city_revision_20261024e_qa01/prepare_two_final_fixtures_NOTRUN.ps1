param(
  [Parameter(Mandatory=$true)][string]$StageReceipt,
  [Parameter(Mandatory=$true)][string]$StageSha256,
  [Parameter(Mandatory=$true)][string]$ExpectedFinalRouterSha256,
  [Parameter(Mandatory=$true)][string]$SourceSeed,
  [Parameter(Mandatory=$true)][string]$SourceSeedSha256,
  [Parameter(Mandatory=$true)][ValidatePattern('^[a-z][a-z0-9_]{2,63}$')][string]$NewKey
)
$ErrorActionPreference='Stop'
# Artifact-only CPU freezer. Root runs after Source's final Stage02+, NEVER Stage01.
# No Godot/import/collector/canonical/save/process/model operations. Does not flip READY.
$qaGameRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$qaOut=Join-Path $PSScriptRoot ('frozen_'+$NewKey+'_NOTREADY')
if(Test-Path -LiteralPath $qaOut){throw 'NEW output only; never overwrite previous fixtures'}
function Resolve-QaInput([string]$Path){
  $absolute=if($Path.StartsWith('res://')){[IO.Path]::GetFullPath((Join-Path $qaGameRoot $Path.Substring(6)))}else{[IO.Path]::GetFullPath($Path)}
  if(-not $absolute.StartsWith($qaGameRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Input outside exact game workspace'}
  return $absolute
}
function Read-QaPinned([string]$Path,[string]$Sha){
  if($Sha -notmatch '^[a-fA-F0-9]{64}$'){throw 'Missing exact externally reviewed SHA'}
  $absolute=Resolve-QaInput $Path
  if((Get-FileHash -LiteralPath $absolute -Algorithm SHA256).Hash.ToLowerInvariant() -cne $Sha.ToLowerInvariant()){throw ('Input SHA differs: '+$Path)}
  return Get-Content -Raw -LiteralPath $absolute | ConvertFrom-Json -AsHashtable
}
function Read-QaMap($Stage,[string]$NodeName){
  $node=$Stage.nodes[$NodeName]
  if($null -eq $node -or $null -eq $node.value.source_sha256){throw ('No independent final map node '+$NodeName)}
  $map=Read-QaPinned $node.path $node.sha256
  $left=@($map.source_sha256.Keys | Sort-Object);$right=@($node.value.source_sha256.Keys | Sort-Object)
  if(($left -join "`n") -cne ($right -join "`n")){throw 'Map key sets differ despite any count'}
  foreach($path in $left){if($map.source_sha256[$path] -cne $node.value.source_sha256[$path]){throw ('Map expected value differs '+$path)}}
  return @{path=$node.path;sha256=$node.sha256;sources=$map.source_sha256}
}
function Write-QaNew([string]$Name,[string]$Text){
  $path=Join-Path $qaOut $Name
  if(Test-Path -LiteralPath $path){throw 'Exclusive new artifact only'}
  [IO.File]::WriteAllText($path,$Text,[Text.UTF8Encoding]::new($false))
  return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
}
$qaStage=Read-QaPinned $StageReceipt $StageSha256
if($qaStage.status -ne 'MARKET_BLOCKS_PREWARM_EXACT33_STAGED_NOT_DEPLOYED' -or $qaStage.targets.Count -ne 33){throw 'Final exact33 Source Stage receipt required'}
if($ExpectedFinalRouterSha256 -notmatch '^[a-fA-F0-9]{64}$' -or $ExpectedFinalRouterSha256.ToLowerInvariant() -eq '045f7b72100c08dee470b8146e9d6cfbb5dae8c058cc3e83cd4070c77229c181'){throw 'Reject known Router parse-failed Stage01; Root must supply final successor SHA'}
$qaMarket=Read-QaMap $qaStage 'expected_ch4_s3_luoyang_market_true'
$qaGate=Read-QaMap $qaStage 'expected_ch4_s0_luoyang_gate_true'
$qaRouter='res://scripts/autoload/scene_router.gd'
$qaHelper='res://build/luoyang_loading_20261024e_perf01/candidate03/gate_source_prewarm02.gd'
foreach($map in @($qaMarket,$qaGate)){
  if($map.sources[$qaRouter] -cne $ExpectedFinalRouterSha256.ToLowerInvariant() -or $map.sources[$qaHelper] -cne '03dec03dbfdd572042e566848d3231de56c1c45583fac4644cfccd99b3a81ed8'){throw 'Wrong Router/helper source identity in final map'}
}
$qaSeed=Read-QaPinned $SourceSeed $SourceSeedSha256
if($qaSeed.status -ne 'ROOT_REVIEWED_SOURCE_DERIVED_MARKET_FIELD_SEED_NOT_RUNTIME_OBSERVATIONS' -or $qaSeed.expected_new_render.Count -ne 6 -or $qaSeed.expected_npc_positions.Count -ne 8 -or $qaSeed.expected_exit_count -le 0 -or $qaSeed.expected_exit_targets.Count -ne $qaSeed.expected_exit_count){throw 'Need source-derived six transforms/eight actors/exact target multiset, not observations'}
if($qaSeed.author_sha256 -cne 'de1911cceb5fb10e6b3b1aba1fa6d9d34057358841febdd285d25a1a1eb65e95' -or $qaMarket.sources[$qaSeed.author_path] -cne $qaSeed.author_sha256){throw 'Final approved author07 must belong to map'}
$qaPaper=@($qaSeed.expected_npc_positions | Where-Object npc_id -eq 'luoyang_paper_artisan_20261016')
if($qaPaper.Count -ne 1 -or $qaPaper[0].origin[0] -ne 888 -or $qaPaper[0].origin[1] -ne 1340){throw 'Require exact source-approved final task consumer, not old880 or approach800'}
$qaCore=@('res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','res://scripts/field/field_walkable_controller.gd','res://scripts/city/luoyang_assembled_interiors_20261016g.gd',$qaRouter,$qaHelper,'res://scripts/city/luoyang_environment_layer_20261022ap.gd')
$qaTemplate=Read-QaPinned (Join-Path $PSScriptRoot 'market_finite01_NOTREADY/fixture_NOTREADY.json') '4d2e41bf1400a460842a18b6a6e4a6170fb67d324c2a56469607e2689ad287c2'
$qaTemplate.expected_city_count=$qaMarket.sources.Count;$qaTemplate.expected_city_sources=$qaMarket.sources
foreach($key in @('author_path','author_sha256','broker','expected_new_render','expected_exit_count','expected_exit_targets','expected_npc_positions')){$qaTemplate[$key]=$qaSeed[$key]}
$qaTemplate.source_sha256=@{}
foreach($path in $qaCore){if(-not $qaMarket.sources.ContainsKey($path)){throw ('Missing Market core source '+$path)};$qaTemplate.source_sha256[$path]=$qaMarket.sources[$path]}
$qaTemplate.expected_source_stage_receipt=@{path=$StageReceipt;sha256=$StageSha256;map_path=$qaMarket.path;map_sha256=$qaMarket.sha256}
$qaTemplate.status='FINAL_STAGE_FROZEN_BUT_NOT_DEPLOYED_OR_ROOT_READY';$qaTemplate.ready=$false;$qaTemplate.formal_deployed=$false
$qaBench=Read-QaPinned 'res://build/luoyang_loading_20261024e_perf01/benchmark04_NOTREADY/benchmark_fixture_NOTREADY.json' '40928759b45acf2f1703a14ba3d199e402985e65c907f907a47ee1a8f6ffde6e'
$qaBench.expected_gate_sources=$qaGate.sources;$qaBench.source_sha256=@{}
foreach($path in $qaCore){if(-not $qaGate.sources.ContainsKey($path)){throw ('Missing Gate core source '+$path)};$qaBench.source_sha256[$path]=$qaGate.sources[$path]}
$qaBench.expected_source_stage_receipt=@{path=$StageReceipt;sha256=$StageSha256;map_path=$qaGate.path;map_sha256=$qaGate.sha256}
$qaBench.status='FINAL_STAGE_FROZEN_BUT_NOT_DEPLOYED_OR_ROOT_READY';$qaBench.ready=$false;$qaBench.formal_deployed=$false
# No artifacts are emitted until every read-only preflight above succeeds.
$null=New-Item -ItemType Directory -Path $qaOut
$qaMarketSha=Write-QaNew 'market_fixture_FROZEN_NOTREADY.json' ($qaTemplate | ConvertTo-Json -Depth 100)
$qaGateSha=Write-QaNew 'world_gate_fixture_FROZEN_NOTREADY.json' ($qaBench | ConvertTo-Json -Depth 100)
$qaSummary=@{status='FINAL_STAGE_TWO_FIXTURES_FROZEN_NOT_READY_NOT_DEPLOYED';stage=@{path=$StageReceipt;sha256=$StageSha256};source_seed=@{path=$SourceSeed;sha256=$SourceSeedSha256};Market=@{fixture_sha256=$qaMarketSha;count=$qaMarket.sources.Count;map_path=$qaMarket.path;map_sha256=$qaMarket.sha256};Gate=@{fixture_sha256=$qaGateSha;count=$qaGate.sources.Count;map_path=$qaGate.path;map_sha256=$qaGate.sha256};Root_must_freeze_NEW_ready_script_and_fixture_after_deploy=$true;whole_ms=60000;entry_ms=20000;engine_runs=0;formal_writes=0}
$qaSummarySha=Write-QaNew 'freeze_summary_NOTREADY.json' ($qaSummary | ConvertTo-Json -Depth 30)
Write-Output (@{output=$qaOut;summary_sha256=$qaSummarySha;Market_fixture_sha256=$qaMarketSha;Gate_fixture_sha256=$qaGateSha} | ConvertTo-Json -Compress)
