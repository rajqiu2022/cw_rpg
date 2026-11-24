param([Parameter(Mandatory=$true)][string]$InputPath)
$ErrorActionPreference='Stop'
$projectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
function ResolveRes([string]$p) {
 if(!$p.StartsWith('res://') -or $p.Contains('..')){throw "RES_DOMAIN:$p"}
 $q=[IO.Path]::GetFullPath((Join-Path $projectRoot $p.Substring(6)))
 if(!$q.StartsWith($projectRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'WORKSPACE_DOMAIN'}
 return $q
}
function Sha([string]$p){return (Get-FileHash -LiteralPath (ResolveRes $p) -Algorithm SHA256).Hash.ToLowerInvariant()}
function Need([bool]$ok,[string]$why){if(!$ok){throw $why}}
function WriteNewJson([string]$path,$value){
 $dest=ResolveRes $path;Need (!(Test-Path -LiteralPath $dest)) "NEW_ONLY:$path"
 [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($dest))|Out-Null
 [IO.File]::WriteAllText($dest,($value|ConvertTo-Json -Depth 100),[Text.UTF8Encoding]::new($false))
}
$spec=Get-Content -LiteralPath $InputPath -Raw -Encoding utf8|ConvertFrom-Json -AsHashtable
Need ($spec.schema_version -eq 1 -and $spec.status -ceq 'ROOT_LOCKED_AP_EXECUTABLE_TARGETS' -and $spec.owned.Count -gt 0) 'ROOT_LOCKED_EXACT_INPUT_REQUIRED'
$out=[string]$spec.output_root
Need ($out.StartsWith('res://build/luoyang_city_full_rollout_20261022ap_system01/') -and $out.EndsWith('/')) 'NEW_AP_BUILD_OUTPUT_ONLY'
Need (!(Test-Path -LiteralPath (ResolveRes $out))) 'NO_OVERWRITE_EXISTING_EXECUTION_STAGE'
$self='res://scripts/city/luoyang_execution_authority_20261022ap.gd'
$helper='res://build/luoyang_city_full_rollout_20261022ap_system01/execution_authority.gd'
Need ((Sha $helper) -ceq $spec.authority_helper_sha256) 'AUTHORITY_HELPER_PIN'
$allowed=@('res://scripts/city/luoyang_precomputed_bundle_20261018r.gd','res://scripts/city/luoyang_assembled_interiors_20261016g.gd','res://scripts/city/luoyang_estate_family_20261021am.gd','res://scripts/autoload/scene_router.gd','res://scripts/city/luoyang_harbour_life_runtime_20261016.gd','res://scripts/city/luoyang_district_life_20261016f.gd','res://scripts/city/luoyang_docks_workyard_20261019ac.gd','res://scripts/city/luoyang_city_tasks_20261016.gd','res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd','res://scripts/field/field_walkable_controller.gd','res://scripts/city/luoyang_temple_assembly_20261016.gd')
$pins=[ordered]@{};$owned=[ordered]@{};$pins[$self]=$spec.authority_helper_sha256
$pythonScript=Join-Path $PSScriptRoot 'exact_execution_inverse.py'
$rows=@();$sourceFirst=[ordered]@{}
# Preflight ALL locked old and candidate bytes before creating any output.
foreach($entry in $spec.owned){
 $target=[string]$entry.path
 Need (($allowed -ccontains $target) -and !$owned.Contains($target)) "CLOSED_OWNED:$target"
 Need ($entry.history -is [Array]) "EXPLICIT_HISTORY_ARRAY:$target"
 Need ((Sha $target) -ceq $entry.old_sha256 -and (Sha $entry.candidate_path) -ceq $entry.new_sha256) "EXACT_LOCKED_OLD_CANDIDATE:$target"
 $sourceFirst[$target]=$entry.old_sha256;$sourceFirst[[string]$entry.candidate_path]=$entry.new_sha256
 $owned[$target]=[ordered]@{current_sha256=$entry.new_sha256;edges=@()}
 $rows+=,$entry
 foreach($history in @($entry.history)){
  Need ($history.old_snapshot -and $history.new_snapshot -and (Sha $history.old_snapshot) -ceq $history.old_sha256 -and (Sha $history.new_snapshot) -ceq $history.new_sha256) "EXACT_HISTORICAL_SNAPSHOTS:$target"
  $sourceFirst[[string]$history.old_snapshot]=$history.old_sha256;$sourceFirst[[string]$history.new_snapshot]=$history.new_sha256
 }
}
[IO.Directory]::CreateDirectory((ResolveRes $out))|Out-Null
$n=0
foreach($entry in $rows){
 $target=[string]$entry.path;$oldSnapshot=$out+'before/'+$n+'.source';$newSnapshot=[string]$entry.candidate_path
 [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName((ResolveRes $oldSnapshot)))|Out-Null
 [IO.File]::Copy((ResolveRes $target),(ResolveRes $oldSnapshot),$false)
 $edges=@([ordered]@{old_snapshot=$oldSnapshot;new_snapshot=$newSnapshot;old_sha256=$entry.old_sha256;new_sha256=$entry.new_sha256})+@($entry.history)
 foreach($edgeInput in $edges){
  $request=[ordered]@{path=$target;old_snapshot=$edgeInput.old_snapshot;new_snapshot=$edgeInput.new_snapshot;old_sha256=$edgeInput.old_sha256;new_sha256=$edgeInput.new_sha256;old_base64=[Convert]::ToBase64String([IO.File]::ReadAllBytes((ResolveRes $edgeInput.old_snapshot)));new_base64=[Convert]::ToBase64String([IO.File]::ReadAllBytes((ResolveRes $edgeInput.new_snapshot)))}
  if($entry.navigation_source){$request.navigation_source=$entry.navigation_source}
  $wire=$request|ConvertTo-Json -Depth 100 -Compress
  $built=$wire|& python -X utf8 $pythonScript
  Need ($LASTEXITCODE -eq 0) "EXACT_WHOLE_INVERSE_BUILDER:$target"
  $edge=$built|ConvertFrom-Json -AsHashtable
  Need ($edge.whole_inverse -eq $true -and $edge.path -ceq $target) "EDGE_INVERSE:$target"
  $owned[$target].edges+=,$edge
  $pins[[string]$edge.old_snapshot]=$edge.old_sha256;$pins[[string]$edge.new_snapshot]=$edge.new_sha256
 }
 $n++
}
$approval=[ordered]@{schema_version=1;status='ROOT_APPROVED_AP_EXACT_EXECUTABLE_SUCCESSION';scope='Closed canonical scripts only; no art/data/geometry authority and no current-disk fallback';owned=$owned;source_sha256=$pins}
$approvalPath=$out+'execution_successor.json';WriteNewJson $approvalPath $approval
$final=[ordered]@{}
foreach($p in $sourceFirst.Keys){$final[$p]=Sha $p;Need ($final[$p] -ceq $sourceFirst[$p]) "SOURCE_FINAL:$p"}
$receipt=[ordered]@{passed=$true;approval_path=$approvalPath;approval_sha256=Sha $approvalPath;owned_count=$owned.Count;proof_source_count=$pins.Count;source_first=$sourceFirst;source_final=$final;canonical_written=$false;data_art_geometry_granted=$false;index_self_hash_cycle=$false}
WriteNewJson ($out+'receipt.json') $receipt
$receipt|ConvertTo-Json -Depth 5
