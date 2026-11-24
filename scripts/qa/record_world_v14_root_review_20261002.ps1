# Mechanical recording of root's ALREADY executed exits and ALREADY viewed pages.
# No engine, approvals, manifest edits, or activation. No automatic visual review.
[CmdletBinding()]
param([Parameter(Mandatory)][switch]$RootReviewedPass)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if (-not $RootReviewedPass) { throw 'Root must explicitly supply actual completed visual review.' }
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
function Local([string]$key) { if ($key.StartsWith('res://')) { return Join-Path $repo ('game/'+$key.Substring(6)) }; if ($key.StartsWith('repo://')) { return Join-Path $repo $key.Substring(7) }; throw 'Canonical key required' }
function Sha([string]$key) { return (Get-FileHash -LiteralPath (Local $key) -Algorithm SHA256).Hash.ToLowerInvariant() }
function Write-New($object,[string]$key) {
 $path=Local $key
 $bytes=[Text.UTF8Encoding]::new($false).GetBytes(($object | ConvertTo-Json -Depth 30))
 $stream=[IO.File]::Open($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try { $stream.Write($bytes,0,$bytes.Length); $stream.Flush($true) } finally { $stream.Dispose() }
}
$sources=[ordered]@{
 'res://scripts/dev/build_world_map_native_full_v14.gd'='76e4a8ffbd326260eb3b0b4125b426b6bb92daf63677236ed3338de6ddde3654'
 'res://scripts/dev/build_world_map_native_full_v14_ninth_draft.gd'='76e4a8ffbd326260eb3b0b4125b426b6bb92daf63677236ed3338de6ddde3654'
 'res://scripts/dev/world_map_v14_ninth_native_surface.gd'='01d231ca4ff6ccc8d93a8d0d3fcde8ce6b03e12943f87e5f23d9cba7a9d39c62'
 'res://scripts/field/field_walkable_controller.gd'='ef00b668356416a12307859236a0ee3006ab469abe0ed8a0905cadb5b660b8e0'
 'res://scripts/world/v14_modular_overlap.gd'='92f80ed076d90be292c848cb9743130b465b71e06250e8867d24e01f02090dab'
 'res://tests/test_world_map_v14_production_20261002.gd'='068dc74f3c5025056b14b5cddccf8693fc94f739537e7ac165a351fd5528e55c'
 'res://tests/helpers/v14_alpha_domain_interval_proof.gd'='b6de881a4600a3cfd3411521b0eb0ed32813b5e92c6073e8c989e159157d2989'
}
foreach ($key in $sources.Keys) { if ((Sha $key) -cne $sources[$key]) { throw "Executed source changed: $key" } }
$base='res://build/world_map_v14_qa/'
$runResults=@{headless=$base+'candidate_headless_1790950478/result.json';gpu=$base+'candidate_gpu_1790952075/result.json'}
$runs=[ordered]@{}
foreach ($mode in @('headless','gpu')) {
 $log='res://build/world_v14_068D_full_'+$mode+'.stdout.log'
 $err='res://build/world_v14_068D_full_'+$mode+'.stderr.log'
 # Explicit facts witnessed by root tools: sessions 61017 and 82412 finished exit0.
 $runs[$mode]=[ordered]@{completed=$true;exit_code=0;actual_sources=$sources;result_path=$runResults[$mode];result_sha256=(Sha $runResults[$mode]);log_path=$log;log_sha256=(Sha $log);stderr_path=$err;stderr_sha256=(Sha $err)}
}
$executionKey=$base+'root_completed_068D_execution_record.json'
Write-New ([ordered]@{schema_version=1;scope='FULL';capture_iteration=9;runs=$runs;root_witnessed_completed_session_ids=@(61017,82412)}) $executionKey
$npcDir=$base+'supplemental_normal_npc_gpu_2257343/'
$caseKey=$npcDir+'supplemental_normal_npc_cases.json'
$caseObject=Get-Content -Raw -LiteralPath (Local $caseKey) | ConvertFrom-Json
$npcImages=@()
foreach ($id in @('patrol_front','patrol_behind')) {
 $case=$caseObject.cases.PSObject.Properties[$id].Value
 if ((Sha $case.image_path) -cne $case.image_sha256) { throw 'Actual root-viewed NPC image changed' }
 $npcImages+=@([ordered]@{path=$case.image_path;sha256=$case.image_sha256;relation=$case.relation;verdict='PASS';evidence_case_id=$id})
}
$npcReview=$base+'root_reviewed_normal_npc_attachment.json'
$regression=$base+'candidate_gpu_1790952075/normal_patrol_same_band.json'
Write-New ([ordered]@{schema_version=1;scope='SUPPLEMENTAL_NPC_VISUAL_REVIEW';capture_iteration=9;producer_review_complete=$true;verdict='PASS';reviewer='/root';regression=[ordered]@{path=$regression;sha256=(Sha $regression);full_read=$true};evidence=[ordered]@{path=$caseKey;sha256=(Sha $caseKey);full_read=$true};images=$npcImages;actual_supplement_os_exit_code=0;supplement_result_sha256=(Sha ($npcDir+'result.json'));supplement_executed_source_sha256=(Sha 'res://tests/test_world_v14_normal_npc_visual_supplement.gd')}) $npcReview
$indexes=@(($base+'root_visual_partial_1790952075_batch1/index.json'),($base+'root_visual_partial_1790952075_batch2/index.json'),($base+'root_visual_complete_1790952075_batch3/index.json'))
$pageCounts=@(15,25,13) # EXACT root-viewed page sets, NOT computed approval.
$passed=@(); for ($i=0;$i -lt 3;$i++) { foreach ($page in 1..$pageCounts[$i]) { $passed+=($indexes[$i]+'#'+$page) } }
$fullNames=@('region_r0c0.png','region_r0c1.png','region_r0c2.png','region_r1c0.png','region_r1c1.png','region_r1c2.png','region_r2c0.png','region_r2c1.png','region_r2c2.png','depth_bianzhou_landmark_front.png','depth_original_grove_21_behind.png','depth_original_grove_21_front.png','ghost_transparent_rectangle.png','mature_canopy_performance_station.png','overview_M.png')
$fullFiles=@($fullNames | ForEach-Object {$base+'candidate_gpu_1790952075/'+$_})
$auth='repo://docs/world-map-v14-producer-visual-approval-20261002.md'
$argsRecord=@{HeadlessResult=$runResults.headless;HeadlessStdout=$runs.headless.log_path;HeadlessStderr=$runs.headless.stderr_path;GpuResult=$runResults.gpu;GpuStdout=$runs.gpu.log_path;GpuStderr=$runs.gpu.stderr_path;ExecutedSourcesRecord=$executionKey;ReviewedContactIndexes=$indexes;PassedPageIds=$passed;ReviewedFullResolutionFiles=$fullFiles;SupplementalNpcReview=$npcReview;ProducerVisualPass=$true;Reviewer='/root';AuthorizationDocument=$auth;AuthorizationSha256=(Sha $auth);RunEvidenceOutput=$base+'root_068D_full_run_evidence.json';ReviewedImageIndexOutput=$base+'root_068D_full_reviewed_image_index.json'}
if ((Sha 'repo://scripts/qa/record_world_v14_producer_inputs.ps1') -cne 'cf6efe482a9c89b684c9759cf025a352f2e4488414dc5a38acf8a360b8a9abcf') { throw 'Recorder source changed after root full read' }
& (Join-Path $PSScriptRoot 'record_world_v14_producer_inputs.ps1') @argsRecord
